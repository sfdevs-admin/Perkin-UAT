/*
 *  Apex Class for Integration Error [SMAX_PS_IntegrationError__c] Business Logic.
 *  2017-09-28      Veerendra Moodbidri       Initial creation, for Work Order Outbound Integration.
 *  1. Update Integration Status in the associated Work Detail
 *  2. Fill in the Lookup fields based on the Related Element Identifier & Type fields
 */

public with sharing class SMAX_PS_IntegrationErrorManager {

	private SMAX_PS_IntegrationErrorManager() {
	}

	public static void updateIntegrationStatusInWorkDetail(List<SMAX_PS_IntegrationError__c> ieNewList)
	{
		Set<Id> wdIds = new Set<Id>();
		List<SVMXC__Service_Order_Line__c> wDetailUpdateList = new List<SVMXC__Service_Order_Line__c>();

		// Collect qualified Work Detail Ids
		if (!ieNewList.isEmpty()) {
			for (SMAX_PS_IntegrationError__c ie : ieNewList)
			{
				if ( ie.SMAX_PS_WorkDetail__c != null )
					wdIds.add(ie.SMAX_PS_WorkDetail__c);
			}
		}
		if (wdIds.isEmpty())
			return;

		// Select the Work Detail lines which qualify for updation
		List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>([SELECT Id, Name FROM SVMXC__Service_Order_Line__c WHERE Id in :wdIds]);

		// Update Work Detail Integration Error field
		if (!wdList.isEmpty()) {
			for ( SVMXC__Service_Order_Line__c wd : wdList ) {
				SVMXC__Service_Order_Line__c wdUpdate = new SVMXC__Service_Order_Line__c(Id=wd.Id);
				wdUpdate.SMAX_PS_IntegrationStatus__c='Error';
				wDetailUpdateList.add(wdUpdate);
			}
			if (!wDetailUpdateList.isEmpty())
				update wDetailUpdateList;
		}
	}

	public static void updateWorkOrderLastError(List<SMAX_PS_IntegrationError__c> ieNewList)
	{
		Map<Id, String> woErrorMap = new Map<Id, String>();
		for (SMAX_PS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.SMAX_PS_WorkOrder__c != null && ie.SMAX_PS_ErrorMessage__c != null )
			{
				Id woId = ie.SMAX_PS_WorkOrder__c;
				String msg = '[' + System.now() + '] ' + ie.SMAX_PS_ErrorMessage__c;
				if (msg.length() > 255)
					msg = msg.substring(0, 252) + '...';

				woErrorMap.put(woId, msg);
			}
		}

		if (woErrorMap.isEmpty())
			return;

		List<SVMXC__Service_Order__c> woList = [SELECT Id, Name, SVMXC__Order_Status__c, 
			SMAX_PS_Completion_Errors__c, SMAX_PS_Last_Integration_Error__c
			FROM SVMXC__Service_Order__c WHERE Id IN :woErrorMap.keySet()];
		for (SVMXC__Service_Order__c wo : woList)
		{
			String msg = woErrorMap.get(wo.Id);
			wo.SMAX_PS_Last_Integration_Error__c = msg;
			if (wo.SVMXC__Order_Status__c == SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_PENDING
					|| wo.SVMXC__Order_Status__c == SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE)
			{
				wo.SMAX_PS_Completion_Errors__c = 'Integration Error Received: ' + msg;
				wo.SVMXC__Order_Status__c = SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
			}
		}

		// SVMXCFG-1020 WO Integration Error when in CreditHold - Catch Errors...
		List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(woList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			SVMXC__Service_Order__c wo = woList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Work Order with Integration Error: ' + wo.Name + ' - ' + result.getErrors();
				System.debug('INT_ERROR_WO: ' + errorMsg);
				logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, wo.Id));
			}
			else
			{
				System.debug('INT_ERROR_WO: Success updating Work Order: ' + wo.Id);
			}
		}

		if (!logs.isEmpty())
			insert logs;
	}

	/**
	 * SVMXCFG-1006 Re-opening parts orders with integration errors
	 */
	public static void updatePartsOrderErrorStatus(List<SMAX_PS_IntegrationError__c> ieNewList)
	{
		Set<Id> poIds = new Set<Id>();
		for (SMAX_PS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.SMAX_PS_PartsOrder__c != null && ie.SMAX_PS_ErrorMessage__c != null )
			{
				Id poId = ie.SMAX_PS_PartsOrder__c;
				poIds.add(poId);
			}
		}

		if (poIds.isEmpty())
			return;

		List<SVMXC__RMA_Shipment_Order__c> poList = [SELECT Id, Name, SVMXC__Order_Status__c
			FROM SVMXC__RMA_Shipment_Order__c WHERE Id IN :poIds];
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SVMXC__Order_Status__c == 'Submitted to ERP')
			{
				po.SVMXC__Order_Status__c = 'Error';
			}
		}

		List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(poList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			SVMXC__RMA_Shipment_Order__c po = poList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Parts Order with Integration Error: ' + po.Name + ' - ' + result.getErrors();
				System.debug('INT_ERROR_PO: ' + errorMsg);
				logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, po.Id));
			}
			else
			{
				System.debug('INT_ERROR_PO: Success updating Parts Order: ' + po.Id);
			}
		}

		if (!logs.isEmpty())
			insert logs;
	}

	/**
	 * SVMXCFG-1056 Updating stock transfers with integration errors
	 */
//	public static void updateStockTransferErrorStatus(List<SMAX_PS_IntegrationError__c> ieNewList)
//	{
//		Set<Id> stIds = new Set<Id>();
//		for (SMAX_PS_IntegrationError__c ie : ieNewList)
//		{
//			if ( ie.SMAX_PS_StockTransfer__c != null && ie.SMAX_PS_StockTransfer__c != null )
//			{
//				Id stId = ie.SMAX_PS_StockTransfer__c;
//				stIds.add(stId);
//			}
//		}
//
//		if (stIds.isEmpty())
//			return;
//
//		List<SVMXC__Stock_Transfer__c> stList = [SELECT Id, Name, SMAX_PS_Status__c
//		FROM SVMXC__Stock_Transfer__c WHERE Id IN :stIds];
//		for (SVMXC__Stock_Transfer__c st : stList)
//		{
//			if (st.SMAX_PS_Status__c == 'Submitted')
//			{
//				st.SMAX_PS_Status__c = 'Error';
//			}
//		}
//
//		List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
//		Database.SaveResult[] results = Database.update(stList, false);
//		for (Integer i = 0; i < results.size(); i++)
//		{
//			Database.SaveResult result = results[i];
//			SVMXC__Stock_Transfer__c st = stList[i];
//			if (!result.isSuccess())
//			{
//				String errorMsg = 'Error updating Stock Transfer with Integration Error: ' + st.Name + ' - ' + result.getErrors();
//				System.debug('INT_ERROR_PO: ' + errorMsg);
//				logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, st.Id));
//			}
//			else
//			{
//				System.debug('INT_ERROR_PO: Success updating Stock Transfer: ' + st.Id);
//			}
//		}
//
//		if (!logs.isEmpty())
//			insert logs;
//	}

	/**
	 *  SVMXINT-572 DMR - No changes "Error"
	 *  Should be called from AFTER INSERT
	 */
	public static void unlockDMR(List<SMAX_PS_IntegrationError__c> ieNewList)
	{
		Set<Id> invoiceIds = new Set<Id>();
		for (SMAX_PS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.SMAX_PS_Invoice__c != null && ie.SMAX_PS_ErrorMessage__c != null )
			{
				Id invoiceId = ie.SMAX_PS_Invoice__c;
				if (ie.SMAX_PS_ErrorMessage__c.contains('No New values found to update DMR'))
				{
					// This is really a warning.. should still "Unlock" DMR
					invoiceIds.add(invoiceId);
				}
			}
		}

		if (invoiceIds.isEmpty())
			return;

		List<SVMXC__Proforma_Invoice__c> invoiceToUpdate = new List<SVMXC__Proforma_Invoice__c>();
		List<SVMXC__Proforma_Invoice__c> invoices = [SELECT Id, Name, SVMXC__Status__c
			FROM SVMXC__Proforma_Invoice__c WHERE Id IN :invoiceIds];
		for (SVMXC__Proforma_Invoice__c inv : invoices) 
		{
			if ( inv.SVMXC__Status__c == 'Locked' ) 
			{
				inv.SVMXC__Status__c = 'Open';
				invoiceToUpdate.add(inv);
			}
		}

		if (!invoiceToUpdate.isEmpty())
			update invoiceToUpdate;
	}

	/**
	 *  SHOULD BE CALLED FROM BEFORE INSERT
	 */
	public static void updateRelatedElement(List<SMAX_PS_IntegrationError__c> ieNewList)
	{
		Map<String, List<SMAX_PS_IntegrationError__c>> ieMap = new Map<String, List<SMAX_PS_IntegrationError__c>>();
		for (SMAX_PS_IntegrationError__c ie : ieNewList)
		{
			String ieType = ie.SMAX_PS_RelatedElementType__c;
			if (String.isNotBlank(ieType))
			{
				if (!ieMap.containsKey(ieType))
					ieMap.put(ieType, new List<SMAX_PS_IntegrationError__c>());
				ieMap.get(ieType).add(ie);
			}
		}

		for (String ieType : ieMap.keySet())
		{
			List<SMAX_PS_IntegrationError__c> ieList = ieMap.get(ieType);
			Set<String> identifiers = new Set<String>();
			for (SMAX_PS_IntegrationError__c ie : ieList)
			{
				identifiers.add(ie.SMAX_PS_RelatedElementIdentifier__c);
			}

			if (ieType == 'WorkOrderId')
			{
				Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
					[SELECT Id, Name FROM SVMXC__Service_Order__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Service_Order__c wo = woMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (wo != null)
						ie.SMAX_PS_WorkOrder__c = wo.Id;
				}
			}
			else if (ieType == 'ServiceOrderNumber')
			{
				Map<String, SVMXC__Service_Order__c> woMap = new Map<String, SVMXC__Service_Order__c>();
				for (SVMXC__Service_Order__c wo : [SELECT Id, SVMX_PS_External_ID__c 
					FROM SVMXC__Service_Order__c WHERE SVMX_PS_External_ID__c IN :identifiers])
				{
					woMap.put(wo.SVMX_PS_External_ID__c, wo);
				}

				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Service_Order__c wo = woMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (wo != null)
						ie.SMAX_PS_WorkOrder__c = wo.Id;
				}
			}
			else if (ieType == 'WorkDetailId')
			{
				Map<Id, SVMXC__Service_Order_Line__c> wdMap = new Map<Id, SVMXC__Service_Order_Line__c>(
					[SELECT Id, Name, SVMXC__Service_Order__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Service_Order_Line__c wd = wdMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (wd != null)
					{
						ie.SMAX_PS_WorkDetail__c = wd.Id;
						ie.SMAX_PS_WorkOrder__c = wd.SVMXC__Service_Order__c;
					}
				}
			}
			else if (ieType == 'InvoiceId')
			{
				Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>(
					[SELECT Id, Name FROM SVMXC__Proforma_Invoice__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Proforma_Invoice__c inv = invMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (inv != null)
						ie.SMAX_PS_Invoice__c = inv.Id;
				}
			}
			else if (ieType == 'InvoiceNumber')
			{
				Map<String, SVMXC__Proforma_Invoice__c> invMap = new Map<String, SVMXC__Proforma_Invoice__c>();
				for (SVMXC__Proforma_Invoice__c inv : [SELECT Id, SMAX_PS_SAP_DMR_Number__c, SMAX_PS_SAP_InvoiceNumber__c 
					FROM SVMXC__Proforma_Invoice__c WHERE SMAX_PS_SAP_DMR_Number__c IN :identifiers OR SMAX_PS_SAP_InvoiceNumber__c IN :identifiers])
				{
					if (String.isNotBlank(inv.SMAX_PS_SAP_DMR_Number__c))
						invMap.put(inv.SMAX_PS_SAP_DMR_Number__c, inv);
					if (String.isNotBlank(inv.SMAX_PS_SAP_InvoiceNumber__c))
						invMap.put(inv.SMAX_PS_SAP_InvoiceNumber__c, inv);
				}

				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Proforma_Invoice__c inv = invMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (inv != null)
						ie.SMAX_PS_Invoice__c = inv.Id;
				}
			}
			else if (ieType == 'PartsOrderId')
			{
				Map<Id, SVMXC__RMA_Shipment_Order__c> poMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>(
					[SELECT Id, Name FROM SVMXC__RMA_Shipment_Order__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__RMA_Shipment_Order__c po = poMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (po != null)
						ie.SMAX_PS_PartsOrder__c = po.Id;
				}
			}
			else if (ieType == 'PartsOrderNumber')
			{
				Map<String, SVMXC__RMA_Shipment_Order__c> poMap = new Map<String, SVMXC__RMA_Shipment_Order__c>();
				for (SVMXC__RMA_Shipment_Order__c po : [SELECT Id, SMAX_PS_ExternalId__c 
					FROM SVMXC__RMA_Shipment_Order__c WHERE SMAX_PS_ExternalId__c IN :identifiers])
				{
					poMap.put(po.SMAX_PS_ExternalId__c, po);
				}

				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__RMA_Shipment_Order__c po = poMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (po != null)
						ie.SMAX_PS_PartsOrder__c = po.Id;
				}
			}
			else if (ieType == 'StockTransferId')
			{
				Map<Id, SVMXC__Stock_Transfer__c> stMap = new Map<Id, SVMXC__Stock_Transfer__c>(
					[SELECT Id, Name FROM SVMXC__Stock_Transfer__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Stock_Transfer__c st = stMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (st != null)
						ie.SMAX_PS_StockTransfer__c = st.Id;
				}
			}
			else if (ieType == 'ContactId')
			{
				Map<Id, Contact> cMap = new Map<Id, Contact>(
					[SELECT Id, Name FROM Contact WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					Contact c = cMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (c != null)
						ie.SMAX_PS_Contact__c = c.Id;
				}
			}
			else if (ieType == 'ContactNumber')
			{
				Map<String, Contact> cMap = new Map<String, Contact>();
				for (Contact c : [SELECT Id, PKI_SAP_Contact_ID__c 
					FROM Contact WHERE PKI_SAP_Contact_ID__c IN :identifiers])
				{
					cMap.put(c.PKI_SAP_Contact_ID__c, c);
				}

				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					Contact c = cMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (c != null)
						ie.SMAX_PS_Contact__c = c.Id;
				}
			}
			else if (ieType == 'InventoryCountId')
			{
				Map<Id, SMAX_PS_InventoryCount__c> icMap = new Map<Id, SMAX_PS_InventoryCount__c>(
					[SELECT Id, Name FROM SMAX_PS_InventoryCount__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SMAX_PS_InventoryCount__c ic = icMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (ic != null)
						ie.SMAX_PS_InventoryCount__c = ic.Id;
				}
			}
			else if (ieType == 'CaseId')
			{
				Map<Id, Case> caseMap = new Map<Id, Case>(
					[SELECT Id, CaseNumber FROM Case WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					Case c = caseMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (c != null)
						ie.SMAX_PS_Case__c = c.Id;
				}
			}
			else if (ieType == 'ServiceContractId')
			{
				Map<Id, SVMXC__Service_Contract__c> contractMap = new Map<Id, SVMXC__Service_Contract__c>(
					[SELECT Id, Name FROM SVMXC__Service_Contract__c WHERE Id IN :identifiers]);
				for (SMAX_PS_IntegrationError__c ie : ieList)
				{
					SVMXC__Service_Contract__c c = contractMap.get(ie.SMAX_PS_RelatedElementIdentifier__c);
					if (c != null)
						ie.SMAX_PS_ServiceContract__c = c.Id;
				}
			}
		}

	}

}
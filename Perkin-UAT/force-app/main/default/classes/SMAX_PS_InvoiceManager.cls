/*
 *  Apex Class for Proforma Invoice [SVMXC__Proforma_Invoice__c] Business Logic.
 *  2017-10-30      Veerendra Moodbidri       Initial creation, for Proforma Invoice Outbound Integration.
 *  1. Create Work Order Event when the Invoice is Released
 *  2. Update the Invoice Line Status to 'Open' when the Completed Transaction Number changed and if the Line Status is 'Locked'
 */

public with sharing class SMAX_PS_InvoiceManager {

	private SMAX_PS_InvoiceManager() {
	}

	public static Id invoiceRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'Invoice' ).Id;
	public static Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR' ).Id;
	public static Id cancelationRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'Cancelation' ).Id;
	public static Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;

	public static void defaultFields(List<SVMXC__Proforma_Invoice__c> invNewList)
	{
		if (!SMAX_PS_Utility.isActive('Default Fields', 'Update Status Field in Invoice.'))
			return;

		for (SVMXC__Proforma_Invoice__c inv : invNewList)
		{
			if (inv.SVMXC__Status__c == null)
				inv.SVMXC__Status__c = 'New';
		}
	}

	// JIRA #389 - Populate Account on Proforma Invoice, from WO
	public static void updateDetailFields(List<SVMXC__Proforma_Invoice_Detail__c> invDetList, Map<Id, SVMXC__Proforma_Invoice_Detail__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Detail Fields', 'Update Account in Proforma Invoice.'))
			return;

		Set<Id> woIds = new Set<Id>();
		for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
		{
			SVMXC__Proforma_Invoice_Detail__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
			if (detail.SVMXC__Work_Order__c != null)
			{
				woIds.add(detail.SVMXC__Work_Order__c);
			}
		}

		if (woIds.isEmpty())
			return;

		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>();
		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
		[SELECT Id, Name, SVMXC__Company__c FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
		for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
		{
			SVMXC__Proforma_Invoice_Detail__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
			if (detail.SVMXC__Work_Order__c != null)
			{
				SVMXC__Service_Order__c wo = woMap.get(detail.SVMXC__Work_Order__c);
				if (wo != null && wo.SVMXC__Company__c != null)
				{
					SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c();
					inv.Id = detail.SVMXC__Proforma_Invoice__c;
					inv.SVMXC__Account__c = wo.SVMXC__Company__c;
					inv.SMAX_PS_Work_Order__c = wo.Id;
					invMap.put(inv.Id, inv);
				}
			}
		}

		if (!invMap.isEmpty())
			update invMap.values();
	}

	// JIRA #221 - Update WO status to "Invoiced" when Proforma Invoice Detail is created
	public static void updateWOstatusToInvoiced(List<SVMXC__Proforma_Invoice_Detail__c> invDetList)
	{
		if (!SMAX_PS_Utility.isActive('Update WO Status To Invoiced', 'Update WO status to Invoiced when Proforma Invoice Detail is created.'))
			return;

		Set<Id> woIds = new Set<Id>();
		Set<Id> invIds = new Set<Id>();
		List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();

		if (!invDetList.isEmpty()) {
			for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
			{
				if (detail.SVMXC__Work_Order__c != null)
				{
					invIds.add(detail.SVMXC__Proforma_Invoice__c);
				}
			}
		}

		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>([Select Id, Name From SVMXC__Proforma_Invoice__c Where Id IN :invIds And RecordTypeId = :invoiceRecordTypeId]);
		if (!invDetList.isEmpty()) {
			for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
			{
				if (detail.SVMXC__Work_Order__c != null && invMap.ContainsKey(detail.SVMXC__Proforma_Invoice__c))
				{
					woIds.add(detail.SVMXC__Work_Order__c);
				}
			}
		}
		if (woIds.isEmpty())
			return;

		List<SVMXC__Service_Order__c> woListToUpdate = new List<SVMXC__Service_Order__c>(
		[SELECT Id, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);

		if (!woListToUpdate.isEmpty()) {
			for (SVMXC__Service_Order__c wo : woListToUpdate)
			{
				wo.SVMXC__Order_Status__c = 'Invoiced';
			}
		}

		if (!woListToUpdate.isEmpty())
			update woListToUpdate;
	}

	// Get Record Type Id for DMR Invoices
	public static void releaseInvoice(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is released.'))
			return;

		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();

		if (!invNewList.isEmpty()){

			for (SVMXC__Proforma_Invoice__c inv : invNewList)
			{
				SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				if ( old != null && old.SVMXC__Status__c != inv.SVMXC__Status__c && inv.SVMXC__Status__c == 'Released' && inv.RecordTypeId == invDMRRecordTypeId ) {
					iEvent.SMAX_PS_Action__c = 'RELEASE INVOICE';
					iEvent.SMAX_PS_InvoiceId__c = inv.Id;
					iEvent.SMAX_PS_SAP_DMR_Number__c = inv.SMAX_PS_SAP_DMR_Number__c;
					events.add(iEvent);
				}
			}
			system.debug('Events->'+events);
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}

	public static void rejectDMR(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is Rejected.'))
			return;

		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		Set<String> invoiceNumbersToCancel = new Set<String>();
		Set<Id> invoiceIds = new Set<Id>();
		for (SVMXC__Proforma_Invoice__c inv : invNewList)
		{
			SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			if ( old != null && old.SVMXC__Status__c != inv.SVMXC__Status__c && inv.SVMXC__Status__c == 'Rejected' && inv.RecordTypeId == invDMRRecordTypeId ) {
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				iEvent.SMAX_PS_Action__c = 'CANCEL BILLING';
				iEvent.SMAX_PS_InvoiceId__c = inv.Id;
				iEvent.SMAX_PS_SAP_DMR_Number__c = inv.SMAX_PS_SAP_DMR_Number__c;
				if (String.isNotBlank(inv.SMAX_PS_SAP_DMR_InvoiceNumber__c))
				{
					// If Invoice Number has already been generated, Need to Cancel Invoice also..
					iEvent.SMAX_PS_SAP_InvoiceNumber__c  = inv.SMAX_PS_SAP_DMR_InvoiceNumber__c;
					invoiceNumbersToCancel.add(inv.SMAX_PS_SAP_DMR_InvoiceNumber__c);
				}
				events.add(iEvent);
				invoiceIds.add(inv.Id);
			}
		}
		system.debug('Events->'+events);

		if (!invoiceNumbersToCancel.isEmpty())
		{
			// Update the Invoice to "Canceled" Status if it exists
			List<SVMXC__Proforma_Invoice__c> invoicesToCancel = [SELECT Id, Name, SVMXC__Status__c, SMAX_PS_SAP_InvoiceNumber__c
			FROM SVMXC__Proforma_Invoice__c
			WHERE SMAX_PS_SAP_InvoiceNumber__c IN :invoiceNumbersToCancel];
			for (SVMXC__Proforma_Invoice__c inv : invoicesToCancel)
			{
				inv.SVMXC__Status__c = 'Canceled';
			}
			// The following flag makes sure we do not send 2 WO 'CANCEL BILLING' events
			PREVENT_CANCEL_INVOICE_EVENT = true;
			if (!invoicesToCancel.isEmpty())
				update invoicesToCancel;
		}

		if (!invoiceIds.isEmpty())
		{
			List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
			List<SVMXC__Proforma_Invoice_Detail__c> details = [SELECT Id, SVMXC__Work_Order__c, SVMXC__Work_Order__r.SVMXC__Order_Status__c
			FROM SVMXC__Proforma_Invoice_Detail__c WHERE SVMXC__Proforma_Invoice__c IN :invoiceIds];
			for (SVMXC__Proforma_Invoice_Detail__c detail : details)
			{
				if (detail.SVMXC__Work_Order__c != null)
				{
					SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
					wo.Id = detail.SVMXC__Work_Order__c;
					wo.SVMXC__Order_Status__c = 'DMR Rejected';
					wosToUpdate.add(wo);
				}
			}

			if (!wosToUpdate.isEmpty())
				update wosToUpdate;
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}

	private static Boolean PREVENT_CANCEL_INVOICE_EVENT = false;

	public static void cancelInvoice(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is Canceled.'))
			return;

		if (PREVENT_CANCEL_INVOICE_EVENT)
		{
			System.debug('Skipping cancelInvoice Event Logic.');
			return;
		}

		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		Set<Id> invoiceIds = new Set<Id>();
		Set<String> dmrNums = new Set<String>();
		for (SVMXC__Proforma_Invoice__c inv : invNewList)
		{
			SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
			if ( old != null && old.SVMXC__Status__c != inv.SVMXC__Status__c && inv.SVMXC__Status__c == 'Canceled' && inv.RecordTypeId == invoiceRecordTypeId ) {
				iEvent.SMAX_PS_Action__c = 'CANCEL BILLING';
				iEvent.SMAX_PS_InvoiceId__c = inv.Id;
				iEvent.SMAX_PS_SAP_InvoiceNumber__c  = inv.SMAX_PS_SAP_InvoiceNumber__c;
				events.add(iEvent);
				invoiceIds.add(inv.Id);
				if (inv.SMAX_PS_SAP_Invoice_DMR_Number__c != null)
					dmrNums.add(inv.SMAX_PS_SAP_Invoice_DMR_Number__c);
			}
		}
		system.debug('Events->'+events);

		if (!invoiceIds.isEmpty())
		{
			List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
			List<SVMXC__Proforma_Invoice_Detail__c> details = [SELECT Id, SVMXC__Work_Order__c, SVMXC__Work_Order__r.SVMXC__Order_Status__c
			FROM SVMXC__Proforma_Invoice_Detail__c WHERE SVMXC__Proforma_Invoice__c IN :invoiceIds];
			for (SVMXC__Proforma_Invoice_Detail__c detail : details)
			{
				if (detail.SVMXC__Work_Order__c != null)
				{
					SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
					wo.Id = detail.SVMXC__Work_Order__c;
					wo.SVMXC__Order_Status__c = 'Ready for Review';
					wosToUpdate.add(wo);
				}
			}
			if (!wosToUpdate.isEmpty())
				update wosToUpdate;
		}

		// JIRA #388 - Change DMR to "Open" when Invoice Cancelled
		if (!dmrNums.isEmpty())
		{
			List<SVMXC__Proforma_Invoice__c> dmrInvoices = [SELECT Id, SVMXC__Status__c FROM SVMXC__Proforma_Invoice__c WHERE SMAX_PS_SAP_DMR_Number__c IN :dmrNums];
			for (SVMXC__Proforma_Invoice__c dmr : dmrInvoices)
			{
				dmr.SVMXC__Status__c = 'Open';
			}

			if (!dmrInvoices.isEmpty())
				update dmrInvoices;
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}

	public static void unlockDMR(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Unlock DMR', 'Update the Status Field in Proforma Invoice.'))
			return;

		if (!invNewList.isEmpty()) {
			for (SVMXC__Proforma_Invoice__c inv : invNewList)
			{
				SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
				if ( old != null && old.SMAX_PS_CompletedTxnNumber__c  != inv.SMAX_PS_CompletedTxnNumber__c && inv.SVMXC__Status__c == 'Locked' && inv.RecordTypeId == invDMRRecordTypeId ) {
					inv.SVMXC__Status__c = 'Open';
				}
			}
		}
	}

	public static void reviewDMRAdjustments(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Review Adjustments', 'Review and Release DMR Adjustments.'))
			return;

		Map<Id, SVMXC__Proforma_Invoice__c> invUpdateMap = new Map<Id, SVMXC__Proforma_Invoice__c>();
		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>();
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		for (SVMXC__Proforma_Invoice__c invoice : invNewList)
		{
			SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(invoice.id);
			if ( old != null && old.SMAX_PS_Adjustments_Reviewed__c != invoice.SMAX_PS_Adjustments_Reviewed__c && invoice.RecordTypeId == invDMRRecordTypeId )
			{
				invMap.put(invoice.Id, invoice);

				// SVMXCFG-795 Make sure a DMR is sent for E-Invoice DMR header values..
				if (invoice.SMAX_PS_EInvoice_Platform_Id__c != null || invoice.SMAX_PS_EInvoice_Customer_Id__c != null
						|| invoice.SMAX_PS_EInvoice_Code_1__c != null || invoice.SMAX_PS_EInvoice_Code_2__c != null
						|| invoice.SMAX_PS_EInvoice_Code_3__c != null)
				{
					SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(Id=invoice.Id);
					// Update Invoice Status
					inv.SVMXC__Status__c = 'Locked';
					invUpdateMap.put(inv.Id, inv);
					// Create Work Order Event
					SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
					iEvent.SMAX_PS_Action__c = 'ADJUST DMR';
					iEvent.SMAX_PS_InvoiceId__c = invoice.Id;
					events.add(iEvent);
				}
			}
		}

		// Select the Invoice Lines that qualify for adjustments related to the passed DMR Invoices
		List<SVMXC__Proforma_Invoice_Line__c> invLineList = new List<SVMXC__Proforma_Invoice_Line__c>([SELECT Id, Name,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServicePercentAdjustment__c, SVMXC__Proforma_Invoice__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE SVMXC__Proforma_Invoice__c IN :invMap.keySet()
		AND (SMAX_PS_ServiceAmountAdjustment__c > 0.0 OR SMAX_PS_ServicePercentAdjustment__c > 0.0
		OR SMAX_PS_ReplacementBasePrice__c > 0.0 OR SMAX_PS_ContractPercentDiscount__c > 0.0
		OR SMAX_PS_EInvoice_Code_1__c != null OR SMAX_PS_EInvoice_Code_2__c != null
		OR SMAX_PS_EInvoice_Code_3__c != null OR SMAX_PS_Material_Part_Description__c != null)]);
		if (!invLineList.isEmpty())
		{
			for (SVMXC__Proforma_Invoice_Line__c invLine : invLineList)
			{
				if (invUpdateMap.containsKey(invLine.SVMXC__Proforma_Invoice__c)) {
					continue; // Already processed this Invoice
				}

				SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(Id = invLine.SVMXC__Proforma_Invoice__c);
				// Update Invoice Status
				inv.SVMXC__Status__c = 'Locked';
				invUpdateMap.put(inv.Id, inv);
				// Create Work Order Event
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				iEvent.SMAX_PS_Action__c = 'ADJUST DMR';
				iEvent.SMAX_PS_InvoiceId__c = invLine.SVMXC__Proforma_Invoice__c;
				events.add(iEvent);
			}
		}

		if (!invUpdateMap.isEmpty())
			update invUpdateMap.values();

		if (!SMAX_PS_Utility.isActive('Create WO Invoice Events', 'Create Work Order Platform Event when Proforma Invoice is Adjusted.'))
			return;

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}

	public static void adjustDMR(List<SVMXC__Proforma_Invoice_Line__c> invLineNewList, Map<Id, SVMXC__Proforma_Invoice_Line__c> invLineOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Adjust DMR', 'Create WO Event and Update the Status Field to Locked in Proforma Invoice.'))
			return;

		Set<Id> invSet = new Set<Id>();
		Map<Id, SVMXC__Proforma_Invoice__c> invUpdateMap = new Map<Id, SVMXC__Proforma_Invoice__c>();
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();

		for (SVMXC__Proforma_Invoice_Line__c il : invLineNewList) {
			invSet.add(il.SVMXC__Proforma_Invoice__c);
		}

		Map<Id, SVMXC__Proforma_Invoice__c> invRecordTypeMap = new Map<Id, SVMXC__Proforma_Invoice__c>(
		[Select Id, RecordTypeId, SVMXC__Status__c from SVMXC__Proforma_Invoice__c Where Id in :invSet]);

		for (SVMXC__Proforma_Invoice_Line__c invLine : invLineNewList)
		{
			SVMXC__Proforma_Invoice__c invoice = invRecordTypeMap.get(invLine.SVMXC__Proforma_Invoice__c);
			SVMXC__Proforma_Invoice_Line__c old = (invLineOldMap == null) ? null : invLineOldMap.get(invLine.id);
			if ( old != null &&
					(old.SMAX_PS_ServiceAmountAdjustment__c != invLine.SMAX_PS_ServiceAmountAdjustment__c
							|| old.SMAX_PS_ServiceAmountAdjustmentType__c != invLine.SMAX_PS_ServiceAmountAdjustmentType__c
							|| old.SMAX_PS_ServicePercentAdjustment__c != invLine.SMAX_PS_ServicePercentAdjustment__c
							|| old.SMAX_PS_ServicePercentAdjustmentType__c != invLine.SMAX_PS_ServicePercentAdjustmentType__c
							|| old.SMAX_PS_ReplacementBasePrice__c != invLine.SMAX_PS_ReplacementBasePrice__c
							|| old.SMAX_PS_ContractPercentDiscount__c != invLine.SMAX_PS_ContractPercentDiscount__c
							|| old.SMAX_PS_EInvoice_Code_1__c != invLine.SMAX_PS_EInvoice_Code_1__c
							|| old.SMAX_PS_EInvoice_Code_2__c != invLine.SMAX_PS_EInvoice_Code_2__c
							|| old.SMAX_PS_EInvoice_Code_3__c != invLine.SMAX_PS_EInvoice_Code_3__c
							|| old.SMAX_PS_Material_Part_Description__c != invLine.SMAX_PS_Material_Part_Description__c)
					&& invoice != null && invoice.RecordTypeId == invDMRRecordTypeId && invoice.SVMXC__Status__c == 'Open')
			{
				if (invLine.SMAX_PS_AutoAdjust_InvoiceNotReq__c == TRUE)
				{
					// SVMXINT-566 DMR - Invoice Not Required - Event already sent in invoiceNotRequired(...) method
					continue;
				}

				if (invUpdateMap.containsKey(invLine.SVMXC__Proforma_Invoice__c))
				{
					continue; // Already processed this Invoice
				}

				SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(Id=invLine.SVMXC__Proforma_Invoice__c);
				// Update Invoice Status
				inv.SVMXC__Status__c = 'Locked';
				invUpdateMap.put(inv.Id, inv);
				// Create Work Order Event
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				iEvent.SMAX_PS_Action__c = 'ADJUST DMR';
				iEvent.SMAX_PS_InvoiceId__c = invLine.SVMXC__Proforma_Invoice__c;
				events.add(iEvent);
			}
		}
		if (!invUpdateMap.isEmpty())
			update invUpdateMap.values();

		if (!SMAX_PS_Utility.isActive('Create WO Invoice Events', 'Create Work Order Platform Event when Proforma Invoice is Adjusted.'))
			return;

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}

	public static void copyPriceAdjustments(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Copy Price Adjustments', 'Copy Adjustments to Invoice Lines from Work Detail Lines.'))
			return;

		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>();
		Set<Id> invLineSet = new Set<Id>();
		Set<Id> woIdSet = new Set<Id>();
		Set<Id> wdetailIdSet = new Set<Id>();
		List<SVMXC__Proforma_Invoice_Line__c> invLineUpdateList = new List<SVMXC__Proforma_Invoice_Line__c>();

		for (SVMXC__Proforma_Invoice__c inv : invNewList)
		{
			SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			if (old != null
					&& old.SMAX_PS_CompletedTxnNumber__c != inv.SMAX_PS_CompletedTxnNumber__c
					&& inv.SVMXC__Status__c == 'New'
					&& inv.RecordTypeId == invDMRRecordTypeId )
			{
				invMap.put(inv.Id, inv);
			}
		}

		if (invMap.isEmpty())
			return;

		System.debug('~~ Trying to Copy Adjustments for Invoices: ' + invMap.keySet());

		// Lookup Invoice Details & Lines..
		List<SVMXC__Proforma_Invoice_Detail__c> invoiceDetails = [Select Id, Name, SVMXC__Work_Order__c, SVMXC__Proforma_Invoice__c,
		(SELECT Id, Name, SVMXC__Product__c, SVMXC__Quantity__c FROM SVMXC__Proforma_Invoice_Line__r)
		From SVMXC__Proforma_Invoice_Detail__c Where SVMXC__Proforma_Invoice__c in :invMap.keySet()];
		for (SVMXC__Proforma_Invoice_Detail__c invd : invoiceDetails) {
			// Find WO Ids..
			woIdSet.add(invd.SVMXC__Work_Order__c);
		}

		// Lookup WO & Work Details..
		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		// SVMXCFG-950 Only copy from Usage lines (filter by record type)
		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name,
				SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_ContractEntitlement__c,
				SMAX_PS_EInvoice_Platform_Id__c, SMAX_PS_EInvoice_Customer_Id__c,
				SMAX_PS_EInvoice_Code_1__c, SMAX_PS_EInvoice_Code_2__c, SMAX_PS_EInvoice_Code_3__c,
		(SELECT Id, Name, SVMXC__Line_Status__c, SVMXC__Line_Type__c, SVMXC__Product__c, SVMXC__Actual_Quantity2__c,
				SMAX_PS_ReplacementBasePrice__c, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServiceAmountAdjustment__c,
				SMAX_PS_ServiceAmountAdjustmentType__c, SMAX_PS_ServicePercentAdjustmentType__c,
				SMAX_PS_EInvoice_Code_1__c, SMAX_PS_EInvoice_Code_2__c, SMAX_PS_EInvoice_Code_3__c,
				SMAX_PS_Material_Part_Description__c, SVMXC__Product__r.Name
			FROM SVMXC__Service_Order_Line__r WHERE RecordTypeId = :usageRecTypeId)
		FROM SVMXC__Service_Order__c WHERE Id IN :woIdSet]);
		for (SVMXC__Proforma_Invoice_Detail__c invoiceDetail : invoiceDetails)
		{
			SVMXC__Service_Order__c wo = woMap.get(invoiceDetail.SVMXC__Work_Order__c);
			if (wo == null)
			{
				System.debug('~~ Could not find WO: ' + invoiceDetail.SVMXC__Work_Order__c + ' for DMR Detail: ' + invoiceDetail.Id);
				continue;
			}

			SVMXC__Proforma_Invoice__c inv = invMap.get(invoiceDetail.SVMXC__Proforma_Invoice__c);
			// SVMXCFG-476 - Populate Contract Item and Contract Entitlement onto the Proforma Invoice
			inv.SMAX_PS_Contract_Item__c = wo.SMAX_PS_ContractItem__c;
			inv.SMAX_PS_Contract_Entitlement__c = wo.SMAX_PS_ContractEntitlement__c;

			// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
			inv.SMAX_PS_EInvoice_Platform_Id__c = wo.SMAX_PS_EInvoice_Platform_Id__c;
			inv.SMAX_PS_EInvoice_Customer_Id__c = wo.SMAX_PS_EInvoice_Customer_Id__c;
			inv.SMAX_PS_EInvoice_Code_1__c = wo.SMAX_PS_EInvoice_Code_1__c;
			inv.SMAX_PS_EInvoice_Code_2__c = wo.SMAX_PS_EInvoice_Code_2__c;
			inv.SMAX_PS_EInvoice_Code_3__c = wo.SMAX_PS_EInvoice_Code_3__c;

			Boolean anyUnmatchedLines = false;
			for (SVMXC__Proforma_Invoice_Line__c invLine : invoiceDetail.SVMXC__Proforma_Invoice_Line__r)
			{
				String lineNotes = null;
				SVMXC__Service_Order_Line__c match = null;
				// SVMXCFG-499: DMR Price Adjustments Improvements
				List<SVMXC__Service_Order_Line__c> matchingLines = new List<SVMXC__Service_Order_Line__c>();
				Decimal totalQty = 0;
				// Match-up each ProformaInvoiceLine to a WorkDetailLine.
				for (SVMXC__Service_Order_Line__c wd : wo.SVMXC__Service_Order_Line__r)
				{
					if (wd.SVMXC__Line_Status__c == 'Canceled')
						continue;

					// The Work Detail lines must not be cancelled, and must have the same Product + Qty as the Proforma Line.
					if (invLine.SVMXC__Product__c == wd.SVMXC__Product__c
							&& invLine.SVMXC__Quantity__c == wd.SVMXC__Actual_Quantity2__c)
					{
						match = wd;
						lineNotes = 'Adjustments copied from Work Detail: ' + wd.Name;
						break;
					}
					if (invLine.SVMXC__Product__c == wd.SVMXC__Product__c
							&& invLine.SVMXC__Quantity__c != wd.SVMXC__Actual_Quantity2__c)
					{
						matchingLines.add(wd);
						totalQty += wd.SVMXC__Actual_Quantity2__c;
					}
				}

				// SVMXCFG-499: DMR Price Adjustments Improvements
				if (match == null && !matchingLines.isEmpty() && totalQty == invLine.SVMXC__Quantity__c)
				{
					// Found multiple lines to merge...
					Set<String> mergedLineNames = new Set<String>();
					Set<String> fieldsOutOfSync = new Set<String>();
					match = matchingLines.remove(0);
					Decimal totalAmtAdj = 0.00;
					if (match.SMAX_PS_ServiceAmountAdjustment__c != null)
					{
						totalAmtAdj = match.SMAX_PS_ServiceAmountAdjustment__c * (match.SMAX_PS_ServiceAmountAdjustmentType__c == 'Discount' ? -1.00 : 1.00);
					}
					mergedLineNames.add(match.Name);
					for (SVMXC__Service_Order_Line__c line : matchingLines)
					{
						mergedLineNames.add(line.Name);
						if (match.SMAX_PS_ContractPercentDiscount__c != line.SMAX_PS_ContractPercentDiscount__c)
						{
							match.SMAX_PS_ContractPercentDiscount__c = null;
							fieldsOutOfSync.add('Contract Discount');
						}
						if (match.SMAX_PS_ReplacementBasePrice__c != line.SMAX_PS_ReplacementBasePrice__c)
						{
							match.SMAX_PS_ReplacementBasePrice__c = null;
							fieldsOutOfSync.add('Replacement Base Price');
						}
						if (match.SMAX_PS_ServicePercentAdjustment__c != line.SMAX_PS_ServicePercentAdjustment__c || match.SMAX_PS_ServicePercentAdjustmentType__c != line.SMAX_PS_ServicePercentAdjustmentType__c)
						{
							match.SMAX_PS_ServicePercentAdjustment__c = null;
							match.SMAX_PS_ServicePercentAdjustmentType__c = null;
							fieldsOutOfSync.add('Service Percent Adjustment');
						}
						if (line.SMAX_PS_ServiceAmountAdjustment__c != null)
						{
							totalAmtAdj += line.SMAX_PS_ServiceAmountAdjustment__c * (line.SMAX_PS_ServiceAmountAdjustmentType__c == 'Discount' ? -1.00 : 1.00);
						}
						// SVMXCFG-897 Material Part Description
						if (match.SMAX_PS_Material_Part_Description__c != line.SMAX_PS_Material_Part_Description__c)
						{
							match.SMAX_PS_Material_Part_Description__c = null;
							fieldsOutOfSync.add('Material Part Description');
						}
					}

					if (totalAmtAdj == 0.00)
					{
						match.SMAX_PS_ServiceAmountAdjustment__c = null;
						match.SMAX_PS_ServiceAmountAdjustmentType__c = null;
					}
					else
					{
						match.SMAX_PS_ServiceAmountAdjustment__c = Math.abs(totalAmtAdj);
						match.SMAX_PS_ServiceAmountAdjustmentType__c = (totalAmtAdj < 0.00) ? 'Discount' : 'Uplift';
					}

					if (fieldsOutOfSync.isEmpty())
					{
						lineNotes = 'Adjustments copied from Work Details: ' + mergedLineNames;
					}
					else
					{
						anyUnmatchedLines = true;
						lineNotes = 'Adjustments partially copied from Work Details: ' + mergedLineNames
								+ ' ... but the following Adjustments were skipped because they were not consistent: '
								+ fieldsOutOfSync;
					}
				}

				if (match == null)
				{
					anyUnmatchedLines = true;
					lineNotes = 'No Adjustments were copied. No matching Work Detail(s) found.';
				}

				// Copy all of the pricing fields from the WorkDetails to the InvoiceLines
				SVMXC__Proforma_Invoice_Line__c invLineUpd = new SVMXC__Proforma_Invoice_Line__c(Id=invLine.Id);
				if (match != null)
				{
					// SVMXCFG-832 Adding back the Replacement Base Price
					invLineUpd.SMAX_PS_ReplacementBasePrice__c = (match.SMAX_PS_ReplacementBasePrice__c == null || match.SMAX_PS_ReplacementBasePrice__c == 0)
							? null : match.SMAX_PS_ReplacementBasePrice__c;
					invLineUpd.SMAX_PS_ContractPercentDiscount__c = match.SMAX_PS_ContractPercentDiscount__c;
					invLineUpd.SMAX_PS_ServiceAmountAdjustment__c = match.SMAX_PS_ServiceAmountAdjustment__c;
					invLineUpd.SMAX_PS_ServiceAmountAdjustmentType__c = match.SMAX_PS_ServiceAmountAdjustmentType__c;
					invLineUpd.SMAX_PS_ServicePercentAdjustment__c = match.SMAX_PS_ServicePercentAdjustment__c;
					invLineUpd.SMAX_PS_ServicePercentAdjustmentType__c = match.SMAX_PS_ServicePercentAdjustmentType__c;
					invLineUpd.SVMXC__Work_Details__c = match.Id;
					invLineUpd.SVMXC__Line_Type__c = match.SVMXC__Line_Type__c;

					// SVMXCFG-795 Copy E-Invoice Fields to Invoice Line from Work Detail
					invLineUpd.SMAX_PS_EInvoice_Code_1__c = match.SMAX_PS_EInvoice_Code_1__c;
					invLineUpd.SMAX_PS_EInvoice_Code_2__c = match.SMAX_PS_EInvoice_Code_2__c;
					invLineUpd.SMAX_PS_EInvoice_Code_3__c = match.SMAX_PS_EInvoice_Code_3__c;

					// SVMXCFG-897 Material Part Description
					// SVMXCFG-1002 DMR - Only Copy Material Description when changed
					if (match.SMAX_PS_Material_Part_Description__c != null
							&& match.SMAX_PS_Material_Part_Description__c != match.SVMXC__Product__r.Name)
					{
						invLineUpd.SMAX_PS_Material_Part_Description__c = match.SMAX_PS_Material_Part_Description__c;
					}
				}
				invLineUpd.SVMXC__Line_Notes__c = lineNotes;
				invLineUpdateList.add(invLineUpd);

				// IF any adjustments, set SMAX_PS_Lines_for_Review__c = TRUE
				if (invLineUpd.SMAX_PS_ReplacementBasePrice__c > 0.0 || invLineUpd.SMAX_PS_ContractPercentDiscount__c > 0.0
						|| invLineUpd.SMAX_PS_ServiceAmountAdjustment__c > 0.0 || invLineUpd.SMAX_PS_ServicePercentAdjustment__c > 0.0
						|| invLineUpd.SMAX_PS_Material_Part_Description__c != null)
				{
					inv.SMAX_PS_Lines_for_Review__c = TRUE;
				}
			}

			// Update the Invoice to 'Open' or 'Needs Review'
			inv.SVMXC__Status__c = (anyUnmatchedLines ? 'Needs Review' : 'Open');
		}

		if (!invLineUpdateList.isEmpty())
			update invLineUpdateList;

	}

	//SVMXCFG-591
	public static void updateRejectionReason(List <SVMXC__Proforma_Invoice__c> newList, Map <Id, SVMXC__Proforma_Invoice__c> oldMap)
	{
		System.debug('~~ Trying to update Rejection Reason.');

		//list of work orders that have updated rejection reasons
		List <SVMXC__Service_Order__c> updatedWoList = new List <SVMXC__Service_Order__c>();
		//iterate through updated proforma invoice records
		for (SVMXC__Proforma_Invoice__c pf : newList)
		{
			//get string of old value of rejection reason
			String oldRejectionReason = (oldMap == null) ? null :
					oldMap.get(pf.id).SMAX_PS_Rejection_Reason__c;

			//assess if rejection reason has been updated
			if(pf.SMAX_PS_Work_Order__c != null && pf.SMAX_PS_Rejection_Reason__c != oldRejectionReason)
			{
				SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
				wo.Id = pf.SMAX_PS_Work_Order__c;
				//pass rejection reason from proforma invoice to rejection reason on the work order
				wo.SMAX_PS_Rejection_Reason__c = pf.SMAX_PS_Rejection_Reason__c;
				//add the work orders to updated list
				updatedWoList.add(wo);
				System.debug('~~ Updated WO Rejection Reason: ' + wo);
			}
		}

		//null check for updatedWoList
		if(updatedWoList.size()>0)
		{
			//update wo list
			update updatedWoList;
		}
	}

	// For SVMXCFG-607 - copy billing address from account into proforma invoice - added 6/18/18
	public static void copyBillingAddressFromAcct(List<SVMXC__Proforma_Invoice_Detail__c> invDetList)
	{
		Set<Id> setIds = new Set<ID>();
		for (SVMXC__Proforma_Invoice_Detail__c invDet : invDetList)
		{
			setIds.add(invDet.id);
		}

		Map<Id,SVMXC__Proforma_Invoice_Detail__c> mapIds = new Map<Id,SVMXC__Proforma_Invoice_Detail__c>(
		[SELECT Id, SVMXC__Proforma_Invoice__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Account__r.BillingStreet,
				SVMXC__Proforma_Invoice__r.SVMXC__Account__r.BillingCity,
				SVMXC__Proforma_Invoice__r.SVMXC__Account__r.BillingState,
				SVMXC__Proforma_Invoice__r.SVMXC__Account__r.BillingPostalCode
		FROM SVMXC__Proforma_Invoice_Detail__c WHERE Id IN :setIds]);

		List<SVMXC__Proforma_Invoice__c> invToUpd = new List<SVMXC__Proforma_Invoice__c>();

		for (SVMXC__Proforma_Invoice_Detail__c invDetUpd : mapIds.values())
		{
			SVMXC__Proforma_Invoice__c inv = invDetUpd.SVMXC__Proforma_Invoice__r;
			if(inv != null && inv.SVMXC__Account__r != null)
			{
				inv.SVMXC__Billing_Street__c = inv.SVMXC__Account__r.BillingStreet;
				inv.SVMXC__Billing_City__c = inv.SVMXC__Account__r.BillingCity;
				inv.SVMXC__Billing_State__c = inv.SVMXC__Account__r.BillingState;
				inv.SVMXC__Billing_Postal_Code__c = inv.SVMXC__Account__r.BillingPostalCode;
				invToUpd.add(inv);
			}
		}
		update invToUpd;
	}

	private static String INVOICE_NOT_REQUIRED = 'Invoice Not Required';
	/*
	 *	SVMXINT-566 DMR - Invoice Not Required
	 *	Should be called from the BEFORE UPDATE trigger
	 */
	public static void invoiceNotRequired(List<SVMXC__Proforma_Invoice__c> invNewList, Map<Id, SVMXC__Proforma_Invoice__c> invOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Invoice Not Required', 'When Invoice Not Required is checked, auto discount all lines to 100% and change status.'))
			return;

		// Find "Invoice Not Required" where either it was just set or unlocked
		Map<Id, SVMXC__Proforma_Invoice__c> invoicesToAdjust = new Map<Id, SVMXC__Proforma_Invoice__c>();
		Map<Id, SVMXC__Proforma_Invoice__c> invoicesToVerify = new Map<Id, SVMXC__Proforma_Invoice__c>();
		for (SVMXC__Proforma_Invoice__c inv : invNewList)
		{
			SVMXC__Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			if (old != null && old.SVMXC__Status__c == INVOICE_NOT_REQUIRED && inv.SVMXC__Status__c != old.SVMXC__Status__c)
			{
				// SVMXINT-653 DMR: Invoice Not Required INFINITE-LOOP ... when Status changed back, uncheck also
				inv.SMAX_PS_Invoice_Not_Required__c = false;
			}

			if (old == null || inv.SMAX_PS_Invoice_Not_Required__c == false)
			{
				continue;
			}

			System.debug('Invoice Not Required.. ' + inv);
			if (old.SMAX_PS_Invoice_Not_Required__c == false)
			{
				// Invoice Not Required was just checked.. adjust to 100% if necessary
				invoicesToAdjust.put(inv.Id, inv);
			}
			else if (old.SVMXC__Status__c == 'Locked' && inv.SVMXC__Status__c == 'Open' && inv.RecordTypeId == invDMRRecordTypeId)
			{
				// Invoice Not Required.. just Unlocked.. should be adjusted to 100% and done.
				invoicesToVerify.put(inv.Id, inv);
			}
		}

		// Need to verify both.. but only adjust the ones that havent been adjusted yet
		invoicesToVerify.putAll(invoicesToAdjust);

		if (invoicesToVerify.isEmpty())
			return;

		System.debug('Invoice Not Required.. ' + invoicesToVerify);

		Map<Id, List<SVMXC__Proforma_Invoice_Line__c>> lineMap = new Map<Id, List<SVMXC__Proforma_Invoice_Line__c>>();
		List<SVMXC__Proforma_Invoice_Line__c> allLines = [SELECT Id, Name,SVMXC__Proforma_Invoice__c,
				SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServicePercentAdjustmentType__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE SVMXC__Proforma_Invoice__c IN :invoicesToVerify.keySet()];
		for (SVMXC__Proforma_Invoice_Line__c line : allLines)
		{
			if (!lineMap.containsKey(line.SVMXC__Proforma_Invoice__c))
				lineMap.put(line.SVMXC__Proforma_Invoice__c, new List<SVMXC__Proforma_Invoice_Line__c>());
			lineMap.get(line.SVMXC__Proforma_Invoice__c).add(line);
		}

		Set<Id> finishedInvoiceIds = new Set<Id>();
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		List<SVMXC__Proforma_Invoice_Line__c> linesToAdjust = new List<SVMXC__Proforma_Invoice_Line__c>();
		for (Id invId : invoicesToVerify.keySet())
		{
			SVMXC__Proforma_Invoice__c inv = invoicesToVerify.get(invId);
			List<SVMXC__Proforma_Invoice_Line__c> lines = lineMap.get(invId);
			if (lines == null) lines = new List<SVMXC__Proforma_Invoice_Line__c>();

			Boolean canAdjust = invoicesToAdjust.containsKey(invId);
			Boolean allDiscounted = TRUE;
			for (SVMXC__Proforma_Invoice_Line__c line : lines)
			{
				// Find lines that need adjusting still
				if (line.SMAX_PS_ServicePercentAdjustment__c != 100 || line.SMAX_PS_ServicePercentAdjustmentType__c != 'Discount')
				{
					allDiscounted = FALSE;
					if (canAdjust)
					{
						line.SMAX_PS_ServicePercentAdjustment__c = 100;
						line.SMAX_PS_ServicePercentAdjustmentType__c = 'Discount';
						line.SMAX_PS_AutoAdjust_InvoiceNotReq__c = TRUE;
						linesToAdjust.add(line);
					}
					else
					{
						// WHAT DO WE DO?? Status = "ERROR"?  Don't want to cause an adjustment infinite loop...
						System.debug('Invoice Not Required.. but adjustment loop detected!!');
					}
				}
			}

			if (allDiscounted == TRUE)
			{
				inv.SVMXC__Status__c = INVOICE_NOT_REQUIRED;
				finishedInvoiceIds.add(inv.Id);
			}
			else
			{
				inv.SVMXC__Status__c = 'Locked';

				// Create Work Order Event
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				iEvent.SMAX_PS_Action__c = 'ADJUST DMR';
				iEvent.SMAX_PS_InvoiceId__c = inv.Id;
				events.add(iEvent);
			}
		}

		if (!linesToAdjust.isEmpty())
			update linesToAdjust;

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');

		if (finishedInvoiceIds.isEmpty())
			return;

		// Last step.. update the WO Status
		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
		List<SVMXC__Proforma_Invoice_Detail__c> details = [SELECT Id, Name, SVMXC__Work_Order__c
		FROM SVMXC__Proforma_Invoice_Detail__c WHERE SVMXC__Proforma_Invoice__c IN :finishedInvoiceIds];
		for (SVMXC__Proforma_Invoice_Detail__c detail : details)
		{
			if (detail.SVMXC__Work_Order__c != null)
			{
				SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
				wo.Id = detail.SVMXC__Work_Order__c;
				wo.SVMXC__Order_Status__c = INVOICE_NOT_REQUIRED;
				woMap.put(wo.Id, wo);
			}
		}

		if (!woMap.isEmpty())
			update woMap.values();
	}

	/**
	 * Should be called from the BEFORE INSERT Trigger
	 * SVMXINT-654 When Invoices are received from SAP, determine if they are Cancellations by comparing their
	 * "SAP Invoice Number" to the "SAP Cancel Invoice Number" on existing Invoices
	 */
	public static void onCancellationInvoice(List<SVMXC__Proforma_Invoice__c> invList)
	{
		if (!SMAX_PS_Utility.isActive('Cancelation Invoices', 'Update Record Type for Cancelation Proforma Invoices.')) { return; }

		List<SVMXC__Proforma_Invoice__c> invToLookup = new List<SVMXC__Proforma_Invoice__c>();
		Set<String> invoiceNumbers = new Set<String>();
		for (SVMXC__Proforma_Invoice__c inv : invList)
		{
			if (inv.RecordTypeId == invoiceRecordTypeId && inv.SMAX_PS_SAP_InvoiceNumber__c != null)
			{
				invoiceNumbers.add(inv.SMAX_PS_SAP_InvoiceNumber__c);
				invToLookup.add(inv);
			}
		}

		if (invoiceNumbers.isEmpty()) { return; }

		Map<String, SVMXC__Proforma_Invoice__c> canceledInvoices = new Map<String, SVMXC__Proforma_Invoice__c>();
		for (SVMXC__Proforma_Invoice__c inv : [SELECT Id, Name, SMAX_PS_SAP_CancelInvoiceNumber__c
			FROM SVMXC__Proforma_Invoice__c
			WHERE SMAX_PS_SAP_CancelInvoiceNumber__c IN :invoiceNumbers])
		{
			canceledInvoices.put(inv.SMAX_PS_SAP_CancelInvoiceNumber__c, inv);
		}

		for (SVMXC__Proforma_Invoice__c inv : invToLookup)
		{
			if (canceledInvoices.containsKey(inv.SMAX_PS_SAP_InvoiceNumber__c))
			{
				// Found a Canceled Invoice that matches this Invoice Number
				inv.RecordTypeId = cancelationRecordTypeId;
				inv.SVMXC__Status__c = 'New';
			}
		}
	}

	/**
	 * Should be called from the BEFORE INSERT Trigger
	 * SVMXINT-654 When Cancelation Invoices are received from SAP, change all Amount fields to negative
	 */
	public static void updateCancelationDetailFields(List<SVMXC__Proforma_Invoice_Detail__c> invDetList, Map<Id, SVMXC__Proforma_Invoice_Detail__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Cancelation Detail Fields', 'Update Detail fields for Cancelation Proforma Invoices.')) { return; }

		Set<Id> invIds = new Set<Id>();
		for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
		{
			invIds.add(detail.SVMXC__Proforma_Invoice__c);
		}

		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>(
			[SELECT Id, Name, RecordTypeId FROM SVMXC__Proforma_Invoice__c WHERE Id IN :invIds]);
		for (SVMXC__Proforma_Invoice_Detail__c detail : invDetList)
		{
			SVMXC__Proforma_Invoice__c inv = invMap.get(detail.SVMXC__Proforma_Invoice__c);
			if (inv != null && inv.RecordTypeId == cancelationRecordTypeId)
			{
				detail.SMAX_PS_TotalNetAmount__c = negative(detail.SMAX_PS_TotalNetAmount__c);
				detail.SMAX_PS_TotalTaxAmount__c = negative(detail.SMAX_PS_TotalTaxAmount__c);
				detail.SVMXC__Total_Amount__c = negative(detail.SVMXC__Total_Amount__c);
			}
		}
	}

	/**
	 * Should be called from the BEFORE INSERT Trigger
	 * SVMXINT-654 When Cancelation Invoices are received from SAP, change all Amount fields to negative
	 */
	public static void updateCancelationLineFields(List<SVMXC__Proforma_Invoice_Line__c> invLineList, Map<Id, SVMXC__Proforma_Invoice_Line__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Cancelation Line Fields', 'Update Line fields for Cancelation Proforma Invoices.')) { return; }

		Set<Id> invIds = new Set<Id>();
		for (SVMXC__Proforma_Invoice_Line__c line : invLineList)
		{
			invIds.add(line.SVMXC__Proforma_Invoice__c);
		}

		Map<Id, SVMXC__Proforma_Invoice__c> invMap = new Map<Id, SVMXC__Proforma_Invoice__c>(
		[SELECT Id, Name, RecordTypeId FROM SVMXC__Proforma_Invoice__c WHERE Id IN :invIds]);
		for (SVMXC__Proforma_Invoice_Line__c line : invLineList)
		{
			SVMXC__Proforma_Invoice__c inv = invMap.get(line.SVMXC__Proforma_Invoice__c);
			if (inv != null && inv.RecordTypeId == cancelationRecordTypeId)
			{
				line.SMAX_PS_NetAmount__c = negative(line.SMAX_PS_NetAmount__c);
				line.SMAX_PS_TaxAmount__c = negative(line.SMAX_PS_TaxAmount__c);
				line.SVMXC__Total_Line_Price__c = negative(line.SVMXC__Total_Line_Price__c);
			}
		}
	}

	private static Decimal negative(Decimal amount)
	{
		if (amount != null)
		{
			amount = Math.abs(amount) * -1.00;
		}
		return amount;
	}

	/**
	 * Should be called from the AFTER INSERT Trigger
	 * SVMXCFG-1144 When Invoices are received from SAP, copy the Invoice Number to the assoc DMR if necessary
	 */
	public static void onNewInvoice(List<SVMXC__Proforma_Invoice__c> invList)
	{
		if (!SMAX_PS_Utility.isActive('On New Invoice', 'When Invoices are received from SAP, copy the Invoice Number to the assoc DMR if necessary.')) { return; }

		Map<String, String> dmrInvMap = new Map<String, String>();
		for (SVMXC__Proforma_Invoice__c inv : invList)
		{
			if (inv.RecordTypeId == invoiceRecordTypeId
					&& String.isNotBlank(inv.SMAX_PS_SAP_InvoiceNumber__c)
					&& String.isNotBlank(inv.SMAX_PS_SAP_Invoice_DMR_Number__c))
			{
				dmrInvMap.put(inv.SMAX_PS_SAP_Invoice_DMR_Number__c, inv.SMAX_PS_SAP_InvoiceNumber__c);
			}
		}

		if (dmrInvMap.isEmpty()) return;

		List<SVMXC__Proforma_Invoice__c> dmrList = [SELECT Id, Name,
				SMAX_PS_SAP_DMR_Number__c, SMAX_PS_SAP_DMR_InvoiceNumber__c
		FROM SVMXC__Proforma_Invoice__c
		WHERE SMAX_PS_SAP_DMR_Number__c IN :dmrInvMap.keySet() AND RecordTypeId = :invDMRRecordTypeId];
		for (SVMXC__Proforma_Invoice__c dmr : dmrList)
		{
			String invNum = dmrInvMap.get(dmr.SMAX_PS_SAP_DMR_Number__c);
			if (invNum != null && dmr.SMAX_PS_SAP_DMR_InvoiceNumber__c == null)
			{
				dmr.SMAX_PS_SAP_DMR_InvoiceNumber__c = invNum;
			}
		}

		if (!dmrList.isEmpty())
		{
			update dmrList;
		}
	}

}
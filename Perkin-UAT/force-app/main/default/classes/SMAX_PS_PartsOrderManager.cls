/**
 *  Apex Class for Parts Order [SVMXC__RMA_Shipment_Order__c] Business Logic.
 *  2017-10-05      Veerendra Moodbidri       Initial creation, for Parts Order Outbound Integration.
 *  1. Create Parts Order Event when Order Status is Submitted to ERP.
 *
 * 2022-04-05	Tony	ITSVMX-562 Modify the replenishment parts ordering process in SVMX to automatically change the ordered part from new to refurbished if a refurbished option is available IF the customer/contract allows
 * 2022-08-02	Tony	ITSVMX-562 We no longer want to exclude APAC as this with be done by master data not having refurbished parts
 */

public with sharing class SMAX_PS_PartsOrderManager {

	private SMAX_PS_PartsOrderManager() {
	}

	public static void copyRelatedData(List<SVMXC__RMA_Shipment_Order__c> poList)
	{
		if (!SMAX_PS_Utility.isActive('Copy Related Data', 'Copy Account Details to Parts Order.'))
		{
			return;
		}

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType rmaRT = recTypeMap.get('RMA');

		// If SVMXC__Destination_Location__c, but no SMAX_PS_Technician__c..
		// Find a Tech referencing the same Loc Id in SVMXC__Inventory_Location__c
		Set<Id> locIds = new Set<Id>();
		// SVMXCFG-541 - WO Ship To Mappings
		Set<Id> woIds = new Set<Id>();
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SVMXC__Destination_Location__c != null && po.SMAX_PS_Technician__c == null)
			{
				locIds.add(po.SVMXC__Destination_Location__c);
			}
			else if (po.SVMXC__Source_Location__c != null && po.SMAX_PS_Technician__c == null)
			{
				locIds.add(po.SVMXC__Source_Location__c);
			}
			if (po.SVMXC__Service_Order__c != null)
			{
				woIds.add(po.SVMXC__Service_Order__c);
			}
		}

		Boolean anyMissingTechs = false;
		if (!locIds.isEmpty())
		{
			Map<Id, SVMXC__Service_Group_Members__c> locTechMap = new Map<Id, SVMXC__Service_Group_Members__c>();
			for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Inventory_Location__c, SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c
				FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Inventory_Location__c IN :locIds])
			{
				locTechMap.put(tech.SVMXC__Inventory_Location__c, tech);
			}

			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SVMXC__Destination_Location__c != null && po.SMAX_PS_Technician__c == null
						&& locTechMap.containsKey(po.SVMXC__Destination_Location__c))
				{
					SVMXC__Service_Group_Members__c tech = locTechMap.get(po.SVMXC__Destination_Location__c);
					po.SMAX_PS_Technician__c = tech.Id;
					if (po.SMAX_PS_SalesOrg__c == null) {
						po.SMAX_PS_SalesOrg__c = tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c;
					}
				}
				else if (po.SVMXC__Source_Location__c != null && po.SMAX_PS_Technician__c == null
						&& locTechMap.containsKey(po.SVMXC__Source_Location__c))
				{
					// ITSVMX-266 Map Tech from the Source Location also
					SVMXC__Service_Group_Members__c tech = locTechMap.get(po.SVMXC__Source_Location__c);
					po.SMAX_PS_Technician__c = tech.Id;
					if (po.SMAX_PS_SalesOrg__c == null) {
						po.SMAX_PS_SalesOrg__c = tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c;
					}
				}

				if (po.SMAX_PS_Technician__c == null)
				{
					anyMissingTechs = true;
				}
			}
		}

		// ITSVMX-1227 Reordering the To-Location SalesOrg logic to run prior to the Current User Tech logic
		// SVMXCFG-614: Last try.. if we didn't find a Tech for the StorageLocation, look it up directly for the SalesOrg
		locIds.clear();
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SVMXC__Destination_Location__c != null &&
				(po.SMAX_PS_SalesOrg__c == null || po.SVMXC__Company__c == null))
			{
				locIds.add(po.SVMXC__Destination_Location__c);
			}
		}

		if (!locIds.isEmpty())
		{
			Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SMAX_PS_SalesOrg__c, SVMXC__Account__c
				FROM SVMXC__Site__c WHERE Id IN :locIds]);
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SVMXC__Destination_Location__c != null)
				{
					SVMXC__Site__c loc = locMap.get(po.SVMXC__Destination_Location__c);
					if (loc != null)
					{
						if (po.SMAX_PS_SalesOrg__c == null) {
							po.SMAX_PS_SalesOrg__c = loc.SMAX_PS_SalesOrg__c;
						}
						if (po.SVMXC__Company__c == null) {
							po.SVMXC__Company__c = loc.SVMXC__Account__c;
						}
					}
				}
			}
		}

		// SVMXCFG-614: Try to auto-fill Technician by Current User..
		if (anyMissingTechs)
		{
			List<SVMXC__Service_Group_Members__c> debriefTechs = 
				[SELECT Id, Name FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c = :UserInfo.getUserId()];
			
			if (debriefTechs.size() > 0 )
			{
				for (SVMXC__RMA_Shipment_Order__c po : poList)
				{
					if (po.SMAX_PS_Technician__c == null)
					{
						po.SMAX_PS_Technician__c = debriefTechs[0].Id;
					}
				}
			}
		}

		Set<Id> techIds = new Set<Id>();
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SMAX_PS_Technician__c != null)
			{
				techIds.add(po.SMAX_PS_Technician__c);
			}
		}

		if (!techIds.isEmpty())
		{
			Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
				[SELECT Id, Name, SVMXC__Inventory_Location__c, SVMXC__Inventory_Location__r.SVMXC__Account__c,
					SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c, SMAX_PS_Technician_Manager_Email__c,
					SMAX_PS_Work_Center__c
				FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SMAX_PS_Technician__c != null)
				{
					SVMXC__Service_Group_Members__c tech = techMap.get(po.SMAX_PS_Technician__c);
					if (tech != null && tech.SVMXC__Inventory_Location__c != null)
					{
						if (po.SVMXC__Company__c == null)
						{
							po.SVMXC__Company__c = tech.SVMXC__Inventory_Location__r.SVMXC__Account__c;
						}
						if (po.SMAX_PS_SalesOrg__c == null)
						{
							po.SMAX_PS_SalesOrg__c = tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c;
						}
					}

					if (tech != null && po.RecordTypeId == rmaRT.Id)
					{
						po.SVMXC__Warehouse__c = tech.Name + ' [' + tech.SMAX_PS_Work_Center__c + ']';
					}

					// SVMXINT-442 -- Retrieve the SalesOrg from the Inventory Location instead of Account Function(s)
					//if (po.SVMXC__Company__c != null)
					//    acctIds.add(po.SVMXC__Company__c);

					// SVMXCFG-914 Fill in SMAX_PS_Technician_Manager_Email__c
					if (tech != null)
					{
						po.SMAX_PS_Technician_Manager_Email__c = tech.SMAX_PS_Technician_Manager_Email__c;
					}
				}
			}
		}

		/*
			SVMXCFG-541 - Ship To Mappings
			- Pull from PO.SMAX_PS_ShipTo__c OR po.SVMXC__Company__c INSTEAD.
			Map the (SMAX_PS_Transportation_Zone__c) from the Work Order Ship To Account (SMAX_PS_ShipTo__c) to (SMAX_PS_Transportation_Zone__c) on the Parts Order
			Map the (PKI_SAP_Language__c) from the Work Order Ship To Account (SMAX_PS_ShipTo__c) to the (SMAX_PS_Language__c) on the Parts Order
		*/
		if (!woIds.isEmpty())
		{
			Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name, SMAX_PS_ShipTo__c,
				SMAX_PS_ShipTo__r.SMAX_PS_Transportation_Zone__c, SMAX_PS_ShipTo__r.PKI_SAP_Language__c, SMAX_PS_SalesOrg__c
				FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				SVMXC__Service_Order__c wo = (po.SVMXC__Service_Order__c != null) ? woMap.get(po.SVMXC__Service_Order__c) : null;
				if (wo != null && wo.SMAX_PS_ShipTo__c != null)
				{
					po.SMAX_PS_Transportation_Zone__c = wo.SMAX_PS_ShipTo__r.SMAX_PS_Transportation_Zone__c;
					po.SMAX_PS_Language__c = wo.SMAX_PS_ShipTo__r.PKI_SAP_Language__c;
					// ITSFDC-863 - Map the ShipTo from the Work Order
					if (po.SMAX_PS_ShipTo__c == null)
					{
						po.SMAX_PS_ShipTo__c = wo.SMAX_PS_ShipTo__c;
					}
				}
				if (wo != null && po.SMAX_PS_SalesOrg__c == null)
				{
					// Added for Loaners and RMA
					po.SMAX_PS_SalesOrg__c = wo.SMAX_PS_SalesOrg__c;
				}
			}
		}
		
		// SVMXINT-612 map the Transportation Zone and Language from Account if no WO
		Set<Id> acctIds = new Set<Id>();
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SVMXC__Service_Order__c == null && po.SVMXC__Company__c != null)
			{
				acctIds.add(po.SVMXC__Company__c);
			}
		}

		if (!acctIds.isEmpty())
		{
			Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, 
				SMAX_PS_Transportation_Zone__c, PKI_SAP_Language__c
				FROM Account WHERE Id IN :acctIds]);
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SVMXC__Service_Order__c == null && po.SVMXC__Company__c != null)
				{
					Account acct = acctMap.get(po.SVMXC__Company__c);
					if (acct != null)
					{
						po.SMAX_PS_Transportation_Zone__c = acct.SMAX_PS_Transportation_Zone__c;
						po.SMAX_PS_Language__c = acct.PKI_SAP_Language__c;
					}
				}
			}
		}

		// SVMXINT-630 Lookup Shipment and Delivery Accounts
		Set<String> acctExtIds = new Set<String>();
		// ITSVMX-153 Lookup Destination Location using the Ship to External Ids also
		Set<String> locExtIds = new Set<String>();
		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			if (po.SVMXC__Company__c == null && po.SMAX_PS_SoldTo_ExtId__c != null)
			{
				acctExtIds.add(po.SMAX_PS_SoldTo_ExtId__c);
			}
			if (po.SMAX_PS_ShipTo__c == null && po.SMAX_PS_ShipTo_ExtId__c != null)
			{
				acctExtIds.add(po.SMAX_PS_ShipTo_ExtId__c);
			}
			if (po.SVMXC__Destination_Location__c == null && po.SMAX_PS_ShipTo_ExtId__c != null)
			{
				locExtIds.add(po.SMAX_PS_ShipTo_ExtId__c);
			}
		}

		if (!acctExtIds.isEmpty())
		{
			Map<String, Account> acctMap = new Map<String, Account>();
			for (Account acct: [SELECT Id, Name, PKI_SAP_Customer_Number__c
				FROM Account WHERE PKI_SAP_Customer_Number__c IN :acctExtIds])
			{
				acctMap.put(acct.PKI_SAP_Customer_Number__c, acct);
			}
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SVMXC__Company__c == null && po.SMAX_PS_SoldTo_ExtId__c != null)
				{
					Account acct = acctMap.get(po.SMAX_PS_SoldTo_ExtId__c);
					if (acct != null)
					{
						po.SVMXC__Company__c = acct.Id;
					}
				}
				if (po.SMAX_PS_ShipTo__c == null && po.SMAX_PS_ShipTo_ExtId__c != null)
				{
					Account acct = acctMap.get(po.SMAX_PS_ShipTo_ExtId__c);
					if (acct != null)
					{
						po.SMAX_PS_ShipTo__c = acct.Id;
					}
				}
			}
		}

		// ITSVMX-153 Lookup Destination Location using the Ship to External Ids also
		if (!locExtIds.isEmpty())
		{
			Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
			for (SVMXC__Site__c loc : [SELECT Id, Name, SVMX_PS_External_ID__c
				FROM SVMXC__Site__c WHERE SVMX_PS_External_ID__c IN :locExtIds])
			{
				locMap.put(loc.SVMX_PS_External_ID__c, loc);
			}
			for (SVMXC__RMA_Shipment_Order__c po : poList)
			{
				if (po.SVMXC__Destination_Location__c == null && po.SMAX_PS_ShipTo_ExtId__c != null)
				{
					SVMXC__Site__c loc = locMap.get(po.SMAX_PS_ShipTo_ExtId__c);
					if (loc != null)
					{
						po.SVMXC__Destination_Location__c = loc.Id;
					}
				}
			}
		}

		for (SVMXC__RMA_Shipment_Order__c po : poList)
		{
			// ITSFDC-863 - Last resort.. make sure the ShipTo is filled in using the main Account
			if (po.SMAX_PS_ShipTo__c == null && po.SVMXC__Company__c != null)
			{
				po.SMAX_PS_ShipTo__c = po.SVMXC__Company__c;
			}
		}
	}

	public static void createPartsOrderEvents(List<SVMXC__RMA_Shipment_Order__c> partsOrderNewList, Map<Id, SVMXC__RMA_Shipment_Order__c> partsOrderOldMap)
	{
		if (!SMAX_PS_Utility.isActive('Create Parts Order Events', 'Create Parts Order Platform Events when Order Status is Submitted to ERP.'))
		{
			return;
		}

		List<SMAX_PS_PartsOrder_Event__e> events = new List<SMAX_PS_PartsOrder_Event__e>();
		Map<Id, String> poMap = new Map<Id, String>();

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType requestRT = recTypeMap.get('Request');
		//RecordType shipmentRT = recTypeMap.get('Shipment');
		//RecordType deliveryRT = recTypeMap.get('Delivery');
		RecordType rmaRT = recTypeMap.get('RMA');
		RecordType loanerRT = recTypeMap.get('Loaner');

		// Collect qualified Parts Order Ids for which Events have to be created
		if (!partsOrderNewList.isEmpty()) {
			for (SVMXC__RMA_Shipment_Order__c po : partsOrderNewList) {
				SVMXC__RMA_Shipment_Order__c old = (partsOrderOldMap == null) ? null : partsOrderOldMap.get(po.Id);
				if ( old == null || old.SVMXC__Order_Status__c != po.SVMXC__Order_Status__c)
				{
					if (po.SVMXC__Order_Status__c == 'Submitted to ERP')
					{
						if (po.RecordTypeId == requestRT.Id)
						{
							poMap.put(po.Id, 'REQUEST');
						}
						// ITSFDC-509 Send "RMA" Event
						else if (po.RecordTypeId == rmaRT.Id)
						{
							// ITSVMX-266 Stock Return Integration
							if (po.SVMXC__RMA_Type__c == 'Stock Return') {
								poMap.put(po.Id, 'STOCK_RETURN');
							} else {
								poMap.put(po.Id, 'RMA');
							}
						}
						// ITSFDC-510 Send "LOANER" Event
						else if (po.RecordTypeId == loanerRT.Id)
						{
							poMap.put(po.Id, 'LOANER');
						}
					}
					// ITSFDC-510 Send "LOANER_RETURN" Event
					else if (po.SVMXC__Order_Status__c == 'Return Requested' && po.RecordTypeId == loanerRT.Id)
					{
						poMap.put(po.Id, 'LOANER_RETURN');
					}
					else if (po.SVMXC__Order_Status__c == 'Canceled' && po.RecordTypeId == rmaRT.Id)
					{
						poMap.put(po.Id, 'RMA_CANCELED');
					}
				}
			}
		}

		// Publish the Event
		if (!poMap.isEmpty()) {
			for (Id po : poMap.keySet()) {
				SMAX_PS_PartsOrder_Event__e iEvent = new SMAX_PS_PartsOrder_Event__e();
				iEvent.SMAX_PS_Action__c = poMap.get(po);
				iEvent.SMAX_PS_PartsOrderId__c = po;
				events.add(iEvent);
			}
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_PartsOrderId__c', 'SMAX_PS_Action__c');
	}

	public static void lookupMasterPartsOrder(List<SVMXC__RMA_Shipment_Order__c> partsOrderNewList, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Lookup Master Parts Order', 'Update Master Parts Order Details.'))
		{
			return;
		}

		// SVMXCFG-550: Status changes based on related parts orders... lookup Record Types
		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType requestRT = recTypeMap.get('Request');
		RecordType shipmentRT = recTypeMap.get('Shipment');
		RecordType deliveryRT = recTypeMap.get('Delivery');

		Set<String> extIds = new Set<String>();
		for (SVMXC__RMA_Shipment_Order__c po : partsOrderNewList)
		{
			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);
			if (po.SVMXC__Master_Order__c == null && po.SMAX_PS_RelatedExternalId__c != null)
			{
				extIds.add(po.SMAX_PS_RelatedExternalId__c);
			}
			if (po.RecordTypeId == requestRT.Id && po.SMAX_PS_ExternalId__c != null 
				&& old != null && old.SMAX_PS_ExternalId__c == null)
			{
				// SVMXCFG-550 : Set Status to "Received by ERP" when SAP Number is populated
				po.SVMXC__Order_Status__c = 'Received by ERP';
			}
		}

		Map<String, SVMXC__RMA_Shipment_Order__c> poMap = new Map<String, SVMXC__RMA_Shipment_Order__c>();
		List<SVMXC__RMA_Shipment_Order__c> poList = new List<SVMXC__RMA_Shipment_Order__c>([SELECT Id, SMAX_PS_ExternalId__c, 
			SVMXC__Service_Order__c, SVMXC__Master_Order__c, OwnerId, SVMXC__Company__c, SVMXC__Destination_Location__c
			FROM SVMXC__RMA_Shipment_Order__c WHERE SMAX_PS_ExternalId__c IN :extIds]);
		for (SVMXC__RMA_Shipment_Order__c po : poList) {
			poMap.put(po.SMAX_PS_ExternalId__c, po);
		}

		// SVMXCFG-550 : Need to update related Parts Orders sometimes..
		Map<Id, SVMXC__RMA_Shipment_Order__c> relatedUpdates = new Map<Id, SVMXC__RMA_Shipment_Order__c>();

		// Update Master Parts Order Id
		for (SVMXC__RMA_Shipment_Order__c po : partsOrderNewList) 
		{
			if (po.SVMXC__Master_Order__c == null && po.SMAX_PS_RelatedExternalId__c != null)
			{
				SVMXC__RMA_Shipment_Order__c master = poMap.get(po.SMAX_PS_RelatedExternalId__c);
				if (master != null)
				{
					po.SVMXC__Master_Order__c = (master.SVMXC__Master_Order__c != null) ? master.SVMXC__Master_Order__c : master.Id;
					po.SVMXC__Service_Order__c = master.SVMXC__Service_Order__c;
					po.OwnerId = master.OwnerId;

					// ITSVMX-153 Copy more data from the Shipment to the Deliveries (from all Master Orders)
					if (po.SVMXC__Company__c == null) {
						po.SVMXC__Company__c = master.SVMXC__Company__c;
					}
					if (po.SVMXC__Destination_Location__c == null) {
						po.SVMXC__Destination_Location__c = master.SVMXC__Destination_Location__c;
					}

					SVMXC__RMA_Shipment_Order__c related = new SVMXC__RMA_Shipment_Order__c();
					related.Id = po.SVMXC__Master_Order__c;
					if (po.RecordTypeId == shipmentRT.Id) // Received a Shipment.. change request to "Processed"
					{
						related.SVMXC__Order_Status__c = 'Processed';
						relatedUpdates.put(related.Id, related);
					}
					else if (po.RecordTypeId == deliveryRT.Id) // Received a Delivery.. change request to "Picked"
					{
						related.SVMXC__Order_Status__c = 'Picked';
						relatedUpdates.put(related.Id, related);
					}
				}
			}
		}

		if (!relatedUpdates.isEmpty())
		{
			update relatedUpdates.values();
		}
	}

	/**
	 *	SVMXINT-573 Parts Orders - Double Submit
	 *	Should be called from BEFORE UPDATE
	 */
	public static void poStatusChanges(List<SVMXC__RMA_Shipment_Order__c> partsOrders, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Parts Order Status Changes', 'Prevent or Change Parts Order Status changes.'))
		{
			return;
		}

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType requestRT = recTypeMap.get('Request');
		//RecordType shipmentRT = recTypeMap.get('Shipment');
		//RecordType deliveryRT = recTypeMap.get('Delivery');
		RecordType rmaRT = recTypeMap.get('RMA');
		RecordType loanerRT = recTypeMap.get('Loaner');

		Map<Id, SVMXC__RMA_Shipment_Order__c> successRmaMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
		for (SVMXC__RMA_Shipment_Order__c po : partsOrders) {
			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);
			if ( old != null && po.RecordTypeId == requestRT.Id
				&& po.SVMXC__Order_Status__c == 'Submitted to ERP' && old.SVMXC__Order_Status__c == 'Received by ERP')
			{
				// Prevent this change.. should only be allowed to go to "Submitted to ERP" if in "Open" Status
				// SVMXCFG-914: Allow "Submitted to Manager" also
				// SVMXCFG-1006: Changed to ONLY block "Received->Submitted".. other changes should be allowed
				po.SVMXC__Order_Status__c = old.SVMXC__Order_Status__c;
			}

			// ITSFDC-509 Advance the Order Status as SAP RMA Documents are received
			if ( old != null && po.RecordTypeId == rmaRT.Id)
			{
				if (po.SMAX_PS_ExternalId__c != null && po.SMAX_PS_ExternalId__c != old.SMAX_PS_ExternalId__c)
				{
					po.SVMXC__Order_Status__c = 'Return Requested';
					// Advanced Replacement.. find Parts Requests pending this RMA
					successRmaMap.put(po.Id, po);
				}
				if (po.BD_SAP_Delivery_Number__c != null && po.BD_SAP_Delivery_Number__c != old.BD_SAP_Delivery_Number__c)
				{
					po.SVMXC__Order_Status__c = 'Received';
				}
				if (po.BD_SAP_Return_Number__c != null && po.BD_SAP_Return_Number__c != old.BD_SAP_Return_Number__c)
				{
					po.SVMXC__Order_Status__c = 'Shipment Requested';
				}
				if (po.BD_SAP_Return_Delivery_Number__c != null && po.BD_SAP_Return_Delivery_Number__c != old.BD_SAP_Return_Delivery_Number__c)
				{
					po.SVMXC__Order_Status__c = 'Issued from Warehouse';
				}
			}
			// ITSFDC-510 Advance the Order Status as SAP Loaner Documents are received
			if ( old != null && po.RecordTypeId == loanerRT.Id)
			{
				if (po.SMAX_PS_ExternalId__c != null && po.SMAX_PS_ExternalId__c != old.SMAX_PS_ExternalId__c)
				{
					po.SVMXC__Order_Status__c = 'Loan Requested';
				}
				if (po.BD_SAP_Delivery_Number__c != null && po.BD_SAP_Delivery_Number__c != old.BD_SAP_Delivery_Number__c)
				{
					po.SVMXC__Order_Status__c = 'On Loan';
				}
				if (po.BD_SAP_Return_Number__c != null && po.BD_SAP_Return_Number__c != old.BD_SAP_Return_Number__c)
				{
					po.SVMXC__Order_Status__c = 'Loaner Return';
				}
				if (po.BD_SAP_Return_Delivery_Number__c != null && po.BD_SAP_Return_Delivery_Number__c != old.BD_SAP_Return_Delivery_Number__c)
				{
					po.SVMXC__Order_Status__c = 'Returned';
				}
			}
		}

		// ITSVMX-200 Advanced Replacement.. submit the Parts Requests after the RMA completes successfully
		if (!successRmaMap.isEmpty()) {
			List<SVMXC__RMA_Shipment_Order__c> partsRequests = [SELECT Id, Name, SVMXC__Order_Status__c,
					SMAX_PS_ExternalId__c, SVMXC__Shipment_Reference__c
				FROM SVMXC__RMA_Shipment_Order__c
				WHERE RecordTypeId = :requestRT.Id AND SVMXC__Shipment_Reference__c IN :successRmaMap.keySet()];

			if (!partsRequests.isEmpty()) {
				for (SVMXC__RMA_Shipment_Order__c pRequest : partsRequests) {
					SVMXC__RMA_Shipment_Order__c rma = successRmaMap.get(pRequest.SVMXC__Shipment_Reference__c);
					// The External Id tells us that it has not been successfully integrated yet..
					if (String.isBlank(pRequest.SMAX_PS_ExternalId__c)) {
						pRequest.SVMXC__Order_Status__c = 'Submitted to ERP';
						// NOTE: Cannot use this field.. it will auto populate "Master Order"
						//pRequest.SMAX_PS_RelatedExternalId__c = rma.SMAX_PS_ExternalId__c;
					}
				}
				update partsRequests;
			}
		}
	}

	// SVMXCFG-899 Enforce Parts Order Field Sizes
	public static void trimValues(List<SVMXC__RMA_Shipment_Order__c> partsOrders, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Parts Order Trim Values', 'Trim values in Parts Order fields to ensure they will not error in SAP.'))
		{
			return;
		}

		Id poRequestRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request').Id;

		for (SVMXC__RMA_Shipment_Order__c po : partsOrders) {
			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);
			if (po.RecordTypeId == poRequestRecordTypeId)
			{
				if (po.SVMXC__Destination_City__c != null)
				{
					po.SVMXC__Destination_City__c = po.SVMXC__Destination_City__c.left(40);
				}
				if (po.SVMXC__Destination_Zip__c != null)
				{
					po.SVMXC__Destination_Zip__c = po.SVMXC__Destination_Zip__c.left(10);
				}
			}
		}
	}

	// ITSFDC-509 Assign the WO to the Depot Work Center Technician
//	public static void assignToDepot(List<SVMXC__RMA_Shipment_Order__c> partsOrders, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
//	{
//		if (!SMAX_PS_Utility.isActive('Parts Order Assign To Depot', 'On RMA PArts Orders, assign the Work Order to the Depot Work Center when it is received.'))
//		{
//			return;
//		}
//
//		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
//		RecordType rmaRT = recTypeMap.get('RMA');
//
//		// NOTE: We might need to change this logic to use BOTH WorkCenter + Plant!
//
//		Map<Id, String> woWorkCenterMap = new Map<Id, String>();
//		for (SVMXC__RMA_Shipment_Order__c po : partsOrders)
//		{
//			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);
//			if (po.RecordTypeId == rmaRT.Id && po.SVMXC__RMA_Type__c == 'Instrument' && po.SVMXC__Service_Order__c != null)
//			{
//				if (po.BD_Depot_Work_Center__c != null && po.BD_Depot_Work_Center__c != old.BD_Depot_Work_Center__c)
//				{
//					// Find Technician with matching value, and set the “Assigned Technician” on the WO
//					Id woId = po.SVMXC__Service_Order__c;
//					woWorkCenterMap.put(woId, po.BD_Depot_Work_Center__c);
//				}
//			}
//		}
//
//		if (woWorkCenterMap.isEmpty())
//		{
//			return;
//		}
//
//		// Lookup "Work Center" Technicians...
//		Set<String> workCenters = new Set<String>(woWorkCenterMap.values());
//		Map<String, SVMXC__Service_Group_Members__c> workCenterMap = new Map<String, SVMXC__Service_Group_Members__c>();
//		List<SVMXC__Service_Group_Members__c> techs = [SELECT Id, Name, SMAX_PS_Work_Center__c, BD_Depot_Queue_Id__c
//			FROM SVMXC__Service_Group_Members__c WHERE SMAX_PS_Work_Center__c IN :workCenters];
//		for (SVMXC__Service_Group_Members__c tech : techs)
//		{
//			workCenterMap.put(tech.SMAX_PS_Work_Center__c, tech);
//		}
//
//
//		List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
//		for (Id woId : woWorkCenterMap.keySet())
//		{
//			String workCenter = woWorkCenterMap.get(woId);
//			SVMXC__Service_Group_Members__c tech = workCenterMap.get(workCenter);
//			if (tech != null)
//			{
//				SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
//				wo.Id = woId;
//				wo.SVMXC__Group_Member__c = tech.Id;
//				woList.add(wo);
//			}
//		}
//
//		if (!woList.isEmpty())
//		{
//			update woList;
//		}
//	}

	// ITSFDC-510 Lookup Loaner Equipment (BEFORE INSERT/UPDATE)
	public static void lookupLoanerEquipment(List<SVMXC__RMA_Shipment_Order__c> partsOrders, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Parts Order Loaner Lookup', 'On Loaner Parts Orders, lookup the loaner Equipment by SAP Equipment ID.'))
		{
			return;
		}

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		//RecordType requestRT = recTypeMap.get('Request');
		//RecordType shipmentRT = recTypeMap.get('Shipment');
		//RecordType deliveryRT = recTypeMap.get('Delivery');
		//RecordType rmaRT = recTypeMap.get('RMA');
		RecordType loanerRT = recTypeMap.get('Loaner');

		List<SVMXC__RMA_Shipment_Order__c> loaners = new List<SVMXC__RMA_Shipment_Order__c>();
		Set<String> equipmentIds = new Set<String>();
		for (SVMXC__RMA_Shipment_Order__c po : partsOrders)
		{
			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);
			if (po.RecordTypeId == loanerRT.Id && po.BD_Loaner_Equipment_External_Id__c != null && po.BD_Loaner_Equipment__c == null)
			{
				loaners.add(po);
				equipmentIds.add(po.BD_Loaner_Equipment_External_Id__c);
			}
		}

		if (loaners.isEmpty())
		{
			return;
		}

		// Lookup "Equipment"...
		Map<String, SVMXC__Installed_Product__c> equipmentMap = new Map<String, SVMXC__Installed_Product__c>();
		for (SVMXC__Installed_Product__c ip : [SELECT Id, Name, SVMX_PS_External_ID__c
			FROM SVMXC__Installed_Product__c WHERE SVMX_PS_External_ID__c IN :equipmentIds])
		{
			equipmentMap.put(ip.SVMX_PS_External_ID__c, ip);
		}

		for (SVMXC__RMA_Shipment_Order__c loaner : loaners)
		{
			SVMXC__Installed_Product__c ip = equipmentMap.get(loaner.BD_Loaner_Equipment_External_Id__c);
			if (ip != null)
			{
				loaner.BD_Loaner_Equipment__c = ip.Id;
			}
		}
	}

	// 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
	// NOTE: Should be called on before insert and before update
	public static void refurbishedPartsAllowed(List<SVMXC__RMA_Shipment_Order__c> partsOrders, Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Parts Order Refurbished Parts Allowed', 'If Refurbished Parts are allowed then set the checkbox fields.'))
			return;

		System.debug('Entering SMAX_PS_PartsOrderManager.refurbishedPartsAllowed');

		Set<Id> refurbishWorkOrderIds = new Set<Id>();
		List<SVMXC__RMA_Shipment_Order__c> refurbishPartsOrders = new List<SVMXC__RMA_Shipment_Order__c>();

		// Get the list of parts orders that might qualify for Refurbished Parts
		for (SVMXC__RMA_Shipment_Order__c po :partsOrders) {
			SVMXC__RMA_Shipment_Order__c old = (oldMap == null) ? null : oldMap.get(po.Id);

			// 8/2/2022 ITSVMX-562 We no longer want to exclude APAC as this with be done by master data not having refurb parts
			// if (po.BD_Refurbished_Parts_Allowed__c == false && po.SMAX_PS_Is_APAC_Parts_Order__c == false) {
			if (po.BD_Refurbished_Parts_Allowed__c == false) {

				System.debug('Found a Parts Order that might qualify to use Refurbished Parts: ' + po.Name);
				refurbishWorkOrderIds.add(po.SVMXC__Service_Order__c);
				refurbishPartsOrders.add(po);
			}
		}

		if (refurbishPartsOrders.isEmpty()) return;

		// Get Work Orders with Use Refurbished Parts checkbox
		List<SVMXC__Service_Order__c> workOrderWithUseRefurbPartsList = [
				SELECT Id, BD_Use_Refurbished_Parts__c
				FROM SVMXC__Service_Order__c
				WHERE Id IN :refurbishWorkOrderIds
		];

		// Create Work Order Id to Use Refurbished Parts mapping
		Map<Id, Boolean> workOrderIdToUseRefurbPartsMap = new Map<Id, Boolean>();
		for (SVMXC__Service_Order__c wo :workOrderWithUseRefurbPartsList) {
			workOrderIdToUseRefurbPartsMap.put(wo.Id, wo.BD_Use_Refurbished_Parts__c);
		}

		// Update parts orders that qualify to use refurbished parts
		for (SVMXC__RMA_Shipment_Order__c po :refurbishPartsOrders) {
			if (workOrderIdToUseRefurbPartsMap.get(po.SVMXC__Service_Order__c) == true) {

				po.BD_Refurbished_Parts_Allowed__c = true;
				po.BD_Use_Refurbished_Parts__c = true;
			}
		}
		System.debug('refurbishPartsOrders after updates: ' + refurbishPartsOrders.size() + ' ' + refurbishPartsOrders);

		System.debug('Exiting SMAX_PS_PartsOrderManager.refurbishedPartsAllowed');
	}
}
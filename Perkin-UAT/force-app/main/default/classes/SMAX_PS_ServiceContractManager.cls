/*
 *  Apex Class for Service Contract [SVMXC__Service_Contract__c] Business Logic.
 *  2017-09-01      Veerendra Moodbidri         Initial creation, for Service Contract Outbound Integration.
 *  2017-10-11                                  Added the method "updateRenewedFrom"            
 *  1. Update "Is Deleted" to true in Service Contracts if "Completed Transaction number" is changed in the Parent Service Contract and it does not match with
		the Last Transaction NUmber in the Child Service Contract
 *  2. Update "Is Deleted" to true in all the Covered products related to the above Service Contracts if same conditions are met
 *  3. Update "Is Deleted" to true in all the Included Services related to the above Service Contracts if same conditions are met 
 *  4. Update "Is Deleted" to true in all the Entitlement Dates related to the above Included Services if same conditions are met
 *  Important note: The "Completed Transaction number" update happens only in the Parent Service Contract
 *  5. Update Renewed From/To Service Contract Number using Previous Contract Number and Renewal Contract Number
 */
public with sharing class SMAX_PS_ServiceContractManager {

	private SMAX_PS_ServiceContractManager() {
	}

	// SVMXINT-602 - Treat "Cancelation Notes" as "Is Deleted"
	public static void updateIsDeletedByCancelNotes(List<SVMXC__Service_Contract__c> newContractList, Map<Id, SVMXC__Service_Contract__c> oldContractMap)
	{
		for (SVMXC__Service_Contract__c cont : newContractList)
		{
			//SVMXC__Service_Contract__c old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
			if (cont.SVMXC__Cancelation_Notes__c != null && String.isNotBlank(cont.SVMXC__Cancelation_Notes__c))
			{
				cont.SMAX_PS_IsDeleted__c = true;
			}
		}
	}

	public static void updateIsDeleted(List<SVMXC__Service_Contract__c> newContractList, Map<Id, SVMXC__Service_Contract__c> oldContractMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Is Deleted Flag', 'Update Contract Items, Covered Products, Included Services and Entitlement Dates.'))
		{
			return;
		}

		Map<Id, SVMXC__Service_Contract__c> parentScMap = new Map<Id, SVMXC__Service_Contract__c>();
		Set<Id> contractIds = new Set<Id>();
		Set<String> completedTxns = new Set<String>();

		if (!newContractList.isEmpty()) {
			for (SVMXC__Service_Contract__c cont : newContractList)
			{
				SVMXC__Service_Contract__c old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
				if (old != null && old.SMAX_PS_CompletedTxnNum__c != cont.SMAX_PS_CompletedTxnNum__c)
				{
					contractIds.add(cont.Id);
					parentScMap.put(cont.Id, cont);
					completedTxns.add(cont.SMAX_PS_CompletedTxnNum__c);
				}
			}
		}
		
		// Exit if no records are qualified
		if (contractIds.isEmpty())
		{
			return;
		}

		/*
			Refactored this method as part of SVMXINT-571 "Create SFDC->SAP Service Contract Integration"
			1) Filtered the queries by the Parent Contract, inside of each record's direct parent.
			2) Only loaded records that might need to change..
				A) LastTxnNum doesnt match CompletedTxnNum
				B) IsDeleted = TRUE (might need to change back to FALSE)
		*/
		List<SVMXC__Service_Contract__c> scUpdateList = new List<SVMXC__Service_Contract__c>();
		List<SVMXC__Service_Contract_Products__c> cpUpdateList = new List<SVMXC__Service_Contract_Products__c>();
		List<SVMXC__Service_Contract_Services__c> isUpdateList = new List<SVMXC__Service_Contract_Services__c>();
		List<SMAX_PS_EntitlementDate__c> edatesDeleteList = new List<SMAX_PS_EntitlementDate__c>();
		List<SMAX_PS_EntitlementDate__c> edatesUpdateList = new List<SMAX_PS_EntitlementDate__c>();

		List<SVMXC__Service_Contract__c> itemList = [SELECT Id, Name, SVMX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c,
			SMAX_PS_IsDeleted__c, SVMXC__Cancelation_Notes__c
			FROM SVMXC__Service_Contract__c WHERE SVMX_PS_Parent_Contract__c IN :contractIds
			AND (SMAX_PS_LastTxnNum__c NOT IN :completedTxns OR SMAX_PS_IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking Items: ' + itemList.size());

		for ( SVMXC__Service_Contract__c item : itemList ) 
		{
			SVMXC__Service_Contract__c parentSc = parentScMap.get(item.SVMX_PS_Parent_Contract__c);
			if ( parentSc.SMAX_PS_CompletedTxnNum__c != item.SMAX_PS_LastTxnNum__c && item.SMAX_PS_IsDeleted__c == false)
			{
				item.SMAX_PS_IsDeleted__c = true;
				scUpdateList.add(item);
			}
			else if (parentSc.SMAX_PS_CompletedTxnNum__c == item.SMAX_PS_LastTxnNum__c
				&& item.SMAX_PS_IsDeleted__c == true && String.isBlank(item.SVMXC__Cancelation_Notes__c))
			{
				item.SMAX_PS_IsDeleted__c = false;
				scUpdateList.add(item);
			}
		}

		List<SVMXC__Service_Contract_Products__c> cpList = [SELECT Id, Name, SMAX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c 
			FROM SVMXC__Service_Contract_Products__c WHERE SMAX_PS_Parent_Contract__c IN :contractIds
			AND (SMAX_PS_LastTxnNum__c NOT IN :completedTxns OR SMAX_PS_IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking CPs: ' + cpList.size());

		for (SVMXC__Service_Contract_Products__c cp : cpList) 
		{
			SVMXC__Service_Contract__c parentSc = parentScMap.get(cp.SMAX_PS_Parent_Contract__c);
			if (cp.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c && cp.SMAX_PS_IsDeleted__c == false)
			{
				cp.SMAX_PS_IsDeleted__c = true;
				cpUpdateList.add(cp);
			}
			else if (cp.SMAX_PS_LastTxnNum__c == parentSc.SMAX_PS_CompletedTxnNum__c && cp.SMAX_PS_IsDeleted__c == true)
			{
				cp.SMAX_PS_IsDeleted__c = false;
				cpUpdateList.add(cp);
			}
		}

		List<SVMXC__Service_Contract_Services__c> isList = [SELECT Id, Name, SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c 
			FROM SVMXC__Service_Contract_Services__c WHERE SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c IN :contractIds
			AND (SMAX_PS_LastTxnNum__c NOT IN :completedTxns OR SMAX_PS_IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking Entitlements: ' + isList.size());

		for (SVMXC__Service_Contract_Services__c is : isList) 
		{
			SVMXC__Service_Contract__c parentSc = parentScMap.get(is.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c);
			if (is.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c && is.SMAX_PS_IsDeleted__c == false)
			{
				is.SMAX_PS_IsDeleted__c = true;
				isUpdateList.add(is);
			}
			else if (is.SMAX_PS_LastTxnNum__c == parentSc.SMAX_PS_CompletedTxnNum__c && is.SMAX_PS_IsDeleted__c == true)
			{
				is.SMAX_PS_IsDeleted__c = false;
				isUpdateList.add(is);
			}
		}

		List<SMAX_PS_EntitlementDate__c> eDatesList = [SELECT Id, Name, SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c, SMAX_PS_WorkOrder__c, SMAX_PS_IsDeleted__c 
			FROM SMAX_PS_EntitlementDate__c WHERE SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c IN :contractIds
			AND (SMAX_PS_LastTxnNum__c NOT IN :completedTxns OR SMAX_PS_IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking EntDates: ' + eDatesList.size());

		for (SMAX_PS_EntitlementDate__c eDate : eDatesList) 
		{
			SVMXC__Service_Contract__c parentSc = parentScMap.get(eDate.SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c);
			if (eDate.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c && eDate.SMAX_PS_IsDeleted__c == false)
			{
				// SVMXCFG-455: Don't delete EntDate if WorkOrder lookup populated
				if (eDate.SMAX_PS_WorkOrder__c != null)
				{
					eDate.SMAX_PS_IsDeleted__c = true;
					edatesUpdateList.add(eDate);
				}
				else
				{
					edatesDeleteList.add(eDate);
				}
			}
			else if (eDate.SMAX_PS_LastTxnNum__c == parentSc.SMAX_PS_CompletedTxnNum__c && eDate.SMAX_PS_IsDeleted__c == true)
			{
				eDate.SMAX_PS_IsDeleted__c = false;
				edatesUpdateList.add(eDate);
			}
		}

		// Update Contract Items, Covered Products, Included Services and Entitlement Dates
		if (!scUpdateList.isEmpty())
		{
			update scUpdateList;
		}
		if (!cpUpdateList.isEmpty())
		{
			update cpUpdateList;
		}
		if (!isUpdateList.isEmpty())
		{
			update isUpdateList;
		}
		if (!edatesUpdateList.isEmpty())
		{
			update edatesUpdateList;
		}
		if (!edatesDeleteList.isEmpty())
		{
			delete edatesDeleteList;
		}

		createServiceContractEvents(parentScMap);
	}

	/**
	 *	SVMXINT-571 "Create SFDC->SAP Service Contract Integration"
	 */
	public static void createServiceContractEvents(Map<Id, SVMXC__Service_Contract__c> parentScMap)
	{
		if (!SMAX_PS_Utility.isActive('Create ServiceContract Events', 'Create Service Contract Events to send to SAP when a Service Contract Txn is Completed.'))
			return;

		//Map<Id, SVMXC__Service_Contract__c> parentScMap = new Map<Id, SVMXC__Service_Contract__c>([SELECT Id, Name, 
		//	SMAX_PS_CompletedTxnNum__c, SVMXC__Active__c, SVMX_PS_External_ID__c
		//	FROM SVMXC__Service_Contract__c WHERE Id IN :contractIds]);

		Map<Id, SMAX_PS_ServiceContract_Event__e> eventMap = new Map<Id, SMAX_PS_ServiceContract_Event__e>();
		for (SVMXC__Service_Contract__c sc : parentScMap.values())
		{
			SMAX_PS_ServiceContract_Event__e sce = new SMAX_PS_ServiceContract_Event__e();
			sce.SMAX_PS_ServiceContractId__c = sc.Id;
			sce.SMAX_PS_Action__c = 'STATUS';
			sce.SMAX_PS_SAP_ServiceContractNumber__c = sc.SVMX_PS_External_ID__c;
			sce.SMAX_PS_CreditOkay__c = sc.SVMXC__Active__c;
			//sce.timestamp = Datetime.now();
			eventMap.put(sc.Id, sce);
		}

		AggregateResult[] itemCounts = [SELECT SVMX_PS_Parent_Contract__c, SMAX_PS_IsDeleted__c, COUNT(Id) numItems
			FROM SVMXC__Service_Contract__c 
			WHERE SVMX_PS_Parent_Contract__c IN :parentScMap.keySet()
			GROUP BY SVMX_PS_Parent_Contract__c, SMAX_PS_IsDeleted__c];
		for (AggregateResult result : itemCounts)  
		{
			Id contractId = (Id) result.get('SVMX_PS_Parent_Contract__c');
			SMAX_PS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numItems');
				Boolean isDeleted = (Boolean) result.get('SMAX_PS_IsDeleted__c');
				if (isDeleted)
					sce.SMAX_PS_Count_InactiveItems__c = count;
				else
					sce.SMAX_PS_Count_ActiveItems__c = count;
			}
		}

		AggregateResult[] cpCounts = [SELECT SMAX_PS_Parent_Contract__c, SMAX_PS_IsDeleted__c, COUNT(Id) numCPs
			FROM SVMXC__Service_Contract_Products__c
			WHERE SMAX_PS_Parent_Contract__c IN :parentScMap.keySet() AND SVMXC__Installed_Product__c != null
			GROUP BY SMAX_PS_Parent_Contract__c, SMAX_PS_IsDeleted__c];
		for (AggregateResult result : cpCounts)  
		{
			Id contractId = (Id) result.get('SMAX_PS_Parent_Contract__c');
			SMAX_PS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numCPs');
				Boolean isDeleted = (Boolean) result.get('SMAX_PS_IsDeleted__c');
				if (isDeleted)
					sce.SMAX_PS_Count_InactiveCPs__c = count;
				else
					sce.SMAX_PS_Count_ActiveCPs__c = count;
			}
		}

		AggregateResult[] edCounts = [SELECT SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c contractId, SMAX_PS_Is_Open__c, SMAX_PS_IsDeleted__c, COUNT(Id) numDates
			FROM SMAX_PS_EntitlementDate__c 
			WHERE SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c IN :parentScMap.keySet() AND SMAX_PS_PlannedDate__c != null
			GROUP BY SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c, SMAX_PS_Is_Open__c, SMAX_PS_IsDeleted__c];
		for (AggregateResult result : edCounts)  
		{
			Id contractId = (Id) result.get('contractId');
			SMAX_PS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numDates');
				Boolean isOpen = (Boolean) result.get('SMAX_PS_Is_Open__c');
				Boolean isDeleted = (Boolean) result.get('SMAX_PS_IsDeleted__c');
				if (isOpen)
					if (isDeleted)
						sce.SMAX_PS_Count_InactiveOpenEntDates__c = count;
					else
						sce.SMAX_PS_Count_ActiveOpenEntDates__c = count;
				else
					if (isDeleted)
						sce.SMAX_PS_Count_InactiveUsedEntDates__c = count;
					else
						sce.SMAX_PS_Count_ActiveUsedEntDates__c = count;
			}
		}

		System.debug('SVC CONTRACT EVENTS = ' + eventMap.values());
		SMAX_PS_PlatformEventUtility.publishEvents(eventMap.values(), 'SMAX_PS_ServiceContractId__c', 'SMAX_PS_Action__c');
	}

	public static void updateRenewedFromAndRenewedTo(List<SVMXC__Service_Contract__c> newContractList, Map<Id, SVMXC__Service_Contract__c> oldContractMap) {

		if (!SMAX_PS_Utility.isActive('Update RenewedFrom And RenewedTo', 'Update RenewedFrom from the previous Contract number and Renewal date.'))
			return;

		if (!newContractList.isEmpty()) {
			Set<String> contractNumbers = new Set<String>();
			List<SVMXC__Service_Contract__c> renewedFroms = new List<SVMXC__Service_Contract__c>();
			List<SVMXC__Service_Contract__c> renewedTos = new List<SVMXC__Service_Contract__c>();
			for (SVMXC__Service_Contract__c cont : newContractList) {
				SVMXC__Service_Contract__c old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
				if (cont.SMAX_PS_PreviousContractNumber__c != null && 
					(cont.SVMXC__Renewed_From__c == null || (old != null && old.SMAX_PS_PreviousContractNumber__c != cont.SMAX_PS_PreviousContractNumber__c)))
				{
					renewedFroms.add(cont);
					contractNumbers.add(cont.SMAX_PS_PreviousContractNumber__c);
				}

				if (cont.SMAX_PS_RenewalContractNumber__c != null && 
					(cont.SMAX_PS_Renewed_To__c == null || (old != null && old.SMAX_PS_RenewalContractNumber__c != cont.SMAX_PS_RenewalContractNumber__c)))
				{
					renewedTos.add(cont);
					contractNumbers.add(cont.SMAX_PS_RenewalContractNumber__c);
				}
			}

			if (contractNumbers.isEmpty())
				return;

			Map<String, SVMXC__Service_Contract__c> contractMap = new Map<String, SVMXC__Service_Contract__c>();
			for (SVMXC__Service_Contract__c contract : [SELECT Id, Name, SVMX_PS_External_ID__c FROM SVMXC__Service_Contract__c WHERE SVMX_PS_External_ID__c IN :contractNumbers])
			{
				contractMap.put(contract.SVMX_PS_External_ID__c, contract);
			}


			for (SVMXC__Service_Contract__c cont : renewedFroms)
			{
				if (contractMap.ContainsKey(cont.SMAX_PS_PreviousContractNumber__c)) {
					SVMXC__Service_Contract__c other = contractMap.get(cont.SMAX_PS_PreviousContractNumber__c);
					cont.SVMXC__Renewed_From__c = (other == null) ? null : other.Id;
				}
			}

			for (SVMXC__Service_Contract__c cont : renewedTos)
			{
				if (contractMap.ContainsKey(cont.SMAX_PS_RenewalContractNumber__c)) {
					SVMXC__Service_Contract__c other = contractMap.get(cont.SMAX_PS_RenewalContractNumber__c);
					cont.SMAX_PS_Renewed_To__c = (other == null) ? null : other.Id;
					cont.SVMXC__Renewal_Date__c = Date.Today();
				}
			}
		}
	}

	/**
	 *  Try to fill in the WO# from the ServiceOrder#
	 *  Should be called from the BEFORE insert/update triggers
	 */
	public static void lookupWorkOrders(List<SMAX_PS_EntitlementDate__c> newList, Map<Id, SMAX_PS_EntitlementDate__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('EntitlementDate Lookup WO', 'When EntitlementDates are created or updated, try to lookup their WO from the ServiceOrder number.'))
			return;

		Set<String> svcOrderNums = new Set<String>();
		for (SMAX_PS_EntitlementDate__c eDate : newList)
		{
			if (String.isNotBlank(eDate.SMAX_PS_ServiceOrderNumber__c) && eDate.SMAX_PS_WorkOrder__c == null)
			{
				svcOrderNums.add(eDate.SMAX_PS_ServiceOrderNumber__c);
			}
		}

		if (svcOrderNums.isEmpty())
			return;

		Map<String, SVMXC__Service_Order__c> woMap = new Map<String, SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : [SELECT Id, Name, SVMX_PS_External_ID__c FROM SVMXC__Service_Order__c 
			WHERE SVMX_PS_External_ID__c IN :svcOrderNums])
		{
			woMap.put(wo.SVMX_PS_External_ID__c, wo);
		}

		for (SMAX_PS_EntitlementDate__c eDate : newList)
		{
			if (String.isNotBlank(eDate.SMAX_PS_ServiceOrderNumber__c) && eDate.SMAX_PS_WorkOrder__c == null)
			{
				SVMXC__Service_Order__c wo = woMap.get(eDate.SMAX_PS_ServiceOrderNumber__c);
				if (wo != null)
				{
					eDate.SMAX_PS_WorkOrder__c = wo.Id;
				}
			}
		}
	}

	// ITSFDC-1047 Auto-Populate the "Remote Hours Remaining" on insert only.. this field is controlled by SMAX now
	public static void copyRemoteHoursRemaining(List<SVMXC__Service_Contract__c> newList)
	{
		for (SVMXC__Service_Contract__c contract : newList)
		{
			if (contract.BD_Item_Qty_Remaining__c != null && contract.BD_Item_Qty_Remaining__c != 0
					&& contract.BD_Remote_Hours_Remaining__c == null)
			{
				contract.BD_Remote_Hours_Remaining__c = contract.BD_Item_Qty_Remaining__c;
			}
		}
	}

	// ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
	// Should be called from the BeforeInsert trigger event
	public static void updateContractItemContractType(List<SVMXC__Service_Contract__c> newList) {
		System.debug('Entered SMAX_PS_ServiceContractManager.updateContractItemContractType()');
		System.debug('newList: ' + newList);

		Id contractItemRTId = Schema.SObjectType.SVMXC__Service_Contract__c.getRecordTypeInfosByDeveloperName().get('ContractItem').getRecordTypeId();
		System.debug('contractItemRTId: ' + contractItemRTId);

		// Get list of parent Service Contract Ids
		Set<Id> parentIds = new Set<Id>();
		for (SVMXC__Service_Contract__c contract :newList) {
			System.debug('[' + contract.RecordTypeId + '] [' + contractItemRTId +']');
			if (contract.RecordTypeId == contractItemRTId) {

				// Get parent Service Contract Id
				Id parentId = contract.SVMX_PS_Parent_Contract__c;
				if (parentId != null) {
					parentIds.add(parentId);
				}
			}
		}
		System.debug('parentIds: ' + parentIds);

		if (parentIds.size() <= 0) return;

		// Get list of parent Service Contract records
		List<SVMXC__Service_Contract__c> parentServiceContracts = [
				SELECT Id, SMAX_PS_ContractType__c
				FROM SVMXC__Service_Contract__c
				WHERE Id IN :parentIds
		];
		System.debug('parentServiceContracts: ' + parentServiceContracts);

		// Get map of parent Service Contract Ids to Contract Types
		Map<Id, String> parentServiceContractIdToContractType = new Map<Id, String>();
		for (SVMXC__Service_Contract__c parentContract :parentServiceContracts) {
			parentServiceContractIdToContractType.put(parentContract.Id, parentContract.SMAX_PS_ContractType__c);
		}
		System.debug('parentServiceContractIdToContractType: ' + parentServiceContractIdToContractType);

		for (SVMXC__Service_Contract__c contract :newList) {
			if (contract.RecordTypeId == contractItemRTId) {

				// Set Contract Type to parent Contract Type
				contract.SMAX_PS_ContractType__c = parentServiceContractIdToContractType.get(contract.SVMX_PS_Parent_Contract__c);
			}
		}
		System.debug('Updated Contract Item Records: ' + newList);
	}
}
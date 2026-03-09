/*
* Apex Class for WO [SVMXC__Service_Order__c] Auto Entitlement Logic
* 2017-09-20 Bill Convis - Initial Creation 
* 1: For each WO passed into the Trigger - retrieve all the Covered Products (CP) for the WO's Installed Product
* 2: Find a CP with a "Contract Entitlement" Type which matches the WO "Activity Type"
* 3: Verify that the dates match and that entitlement isn't used up
* 4: If match found, entitle the WO to the Contract/Item/Entitlement
*/
public with sharing class SMAX_PS_AutoEntitlement 
{
	//public class CoveredProductWrapper implements Comparable
	//{
	//	public SVMXC__Service_Contract_Products__c cp;
	//	public List<SMAX_PS_EntitlementDate__c> entitlementDates;

	//	public CoveredProductWrapper(SVMXC__Service_Contract_Products__c cp, List<SMAX_PS_EntitlementDate__c> eDates)
	//	{
	//		this.cp = cp;
	//		this.entitlementDates = (eDates == null) ? new List<SMAX_PS_EntitlementDate__c>() : eDates;
	//	}

	//	// Compare opportunities based on the opportunity amount.
	//	public Integer compareTo(Object compareTo) {
	//		// Cast argument to CoveredProductWrapper
	//		CoveredProductWrapper that = (CoveredProductWrapper)compareTo;
	//		Integer returnValue = 0;
	//		if (this.entitlementDates.size() < that.entitlementDates.size()) {
	//			returnValue = 1;
	//		} else if (this.entitlementDates.size() > that.entitlementDates.size()) {
	//			returnValue = -1;
	//		}
	//		return returnValue;       
	//	}
	//}

	// SVMXCFG-700 Select highest total coverage item
	public class EntitlementWrapper implements Comparable
	{
		public String entType;
		public SVMXC__Service_Contract_Products__c cp;
		public List<SMAX_PS_EntitlementDate__c> entitlementDates;
		public SVMXC__Service_Contract_Services__c ent;

		public EntitlementWrapper(SVMXC__Service_Contract_Products__c cp, SVMXC__Service_Contract_Services__c ent)
		{
			this.entType = ent.SMAX_PS_EntitlementType__c;
			this.cp = cp;
			this.ent = ent;

			this.entitlementDates = new List<SMAX_PS_EntitlementDate__c>();
			try
			{
				if (cp.Entitlement_Dates__r != null)
				{
					for (SMAX_PS_EntitlementDate__c ed : cp.Entitlement_Dates__r)
					{
						if (ed.SMAX_PS_Entitlement__c == ent.Id)
						{
							this.entitlementDates.add(ed);
						}
					}
				}
			}
			catch (Exception e1)
			{
				System.debug('!! Received Error trying to access "cp.Entitlement_Dates__r"... using direct SOQL Query: ' + e1);
				// We are receiving this error if more than 200 Entitlement Dates:
				/* FATAL_ERROR System.QueryException: Aggregate query has too many rows for direct assignment, use FOR loop */
				this.entitlementDates = [SELECT Id, SMAX_PS_CoveredProduct__c, SMAX_PS_Entitlement__c, 
					SMAX_PS_IsDeleted__c, SMAX_PS_PlannedDate__c, SMAX_PS_ServiceOrderNumber__c, 
					SMAX_PS_SAP_Notification_ID__c,SMAX_PS_WorkOrder__c 
					FROM SMAX_PS_EntitlementDate__c 
					WHERE SMAX_PS_CoveredProduct__c = :cp.Id AND SMAX_PS_Entitlement__c = :ent.Id
					AND SMAX_PS_IsDeleted__c = FALSE
					ORDER BY SMAX_PS_PlannedDate__c];
			}
		}

		// SVMXCFG-1162 Only count the "non-consumed" Entitlement Dates
		private Integer availableDateCount = null;
		public Integer countAvailableEntDates()
		{
			if (this.availableDateCount != null)
				return this.availableDateCount;

			Integer result = 0;
			for (SMAX_PS_EntitlementDate__c ed : this.entitlementDates)
			{
				if (ed != null && ed.SMAX_PS_ServiceOrderNumber__c == null && ed.SMAX_PS_SAP_Notification_ID__c == null && ed.SMAX_PS_WorkOrder__c == null)
				{
					result++;
				}
			}
			this.availableDateCount = result;
			return result;
		}

		// Compare CP/Entitlement based on various factors...
		public Integer compareTo(Object compareTo) {
			// Cast argument to EntitlementWrapper
			EntitlementWrapper that = (EntitlementWrapper)compareTo;
			Integer returnValue = 0;
			// SVMXCFG-525: Multiple CPs: Try to find exact match first, then ZZZ
			if (this.entType != that.entType) 
			{
				returnValue = (this.entType == DEFAULT_ENTITLEMENT_TYPE) ? 1 : -1;
			} 
			// SVMXCFG-525: Auto-Entitlement - Sort by NumberOfEntitlementDates (to ensure ones with ED are processed before those without)
			// SVMXCFG-1162 Only count the "non-consumed" Entitlement Dates
			else if (this.countAvailableEntDates() != that.countAvailableEntDates())
			{
				returnValue = (this.countAvailableEntDates() < that.countAvailableEntDates()) ? 1 : -1;
			}
			// SVMXCFG-700 Select highest total coverage item
			else if (this.ent.SMAX_PS_Total_Coverage__c != that.ent.SMAX_PS_Total_Coverage__c) 
			{
				returnValue = (this.ent.SMAX_PS_Total_Coverage__c < that.ent.SMAX_PS_Total_Coverage__c) ? 1 : -1;
			}
			return returnValue;
		}
	}

	private static List<EntitlementWrapper> getEntitlementOptions(String entType, List<SVMXC__Service_Contract_Products__c> cpList, Map<Id, Map<String, SVMXC__Service_Contract_Services__c>> itemEntMap, Boolean allowDefaultEntType)
	{
		List<EntitlementWrapper> result = new List<EntitlementWrapper>();

		// SVMXCFG-525: Multiple CPs: Try to find exact match first, then ZZZ
		List<String> entTypes = new List<String> { entType };
		if (allowDefaultEntType == true) {
			entTypes.add(DEFAULT_ENTITLEMENT_TYPE);
		}

		for (String entitlementType : entTypes)
		{
			for(SVMXC__Service_Contract_Products__c cp : cpList)
			{
				//Get the id from the Contract Item
				Id contractItemId = cp.SVMXC__Service_Contract__r.Id;

				//Load the list of "Entitlements"
				Map<String, SVMXC__Service_Contract_Services__c> entMap = itemEntMap.get(contractItemId);
				SVMXC__Service_Contract_Services__c ent = (entMap == null) ? null : entMap.get(entitlementType);
				if (ent != null)
				{
					EntitlementWrapper entWrap = new EntitlementWrapper(cp, ent);
					result.add(entWrap);
				}
				//else
				//{
				//	wo.SVMXC__Entitlement_Notes__c += '\n No Entitlement Found matching: ' + entitlementType;
				//}
			}
		}

		result.sort();
		return result;
	}

	private static Set<String> ENT_BILLING_TYPES = new Set<String> { 'Contract' };
	private static String DEFAULT_ENTITLEMENT_TYPE = 'ZZZ';
	//private static String WARRANTY_CONTRACT_TYPE = 'ZW01';

	public static void performAutoEntitlementCheck(List<SVMXC__Service_Order__c> wos, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('WO Entitlement Check', 'Perform a Auto-Entitlement check on the WO based on the IP, Order Type and Scheduled Date'))
		{	return;	}

		RecordType remoteRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');

		List<SVMXC__Service_Order__c> wosToCheck = new List<SVMXC__Service_Order__c>();
		List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
		List<SMAX_PS_EntitlementDate__c> edsToUpdate = new List<SMAX_PS_EntitlementDate__c>();
		//Map<Id, List<CoveredProductWrapper>> ipCpMap = new Map<Id, List<CoveredProductWrapper>>(); 
		Map<Id, List<SVMXC__Service_Contract_Products__c>> ipCpMap = new Map<Id, List<SVMXC__Service_Contract_Products__c>>(); 
		Map<Id, Map<String, SVMXC__Service_Contract_Services__c>> itemEntMap = new Map<Id, Map<String, SVMXC__Service_Contract_Services__c>>();
		Map<Id, Id> contrItemParentContract = new Map<Id, Id>();
		Set<Id> ContractItemIDs = new Set<Id>();
		Set<Id> IBIds = new Set<Id>();
		List<Date> scheduledDates = new List<Date>();
		for (SVMXC__Service_Order__c wo : wos)
		{
			Boolean readyForCheck = false;
			//Check if update
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if(old == null && (wo.SVMXC__Perform_Auto_Entitlement__c == true 
				&& ENT_BILLING_TYPES.contains(wo.SVMXC__Billing_Type__c) ) ) {
				readyForCheck = true;
			}
			else if (old == null && wo.RecordTypeId == remoteRT.Id && wo.SVMXC__Component__c != null) {
				// ITSFDC-1047 Remote Support Hour Blocks
				readyForCheck = true;
			}
			if(old != null && (wo.SVMXC__Component__c != old.SVMXC__Component__c 
				|| wo.SVMXC__Billing_Type__c != old.SVMXC__Billing_Type__c 
				|| wo.SMAX_PS_SAP_ActivityType__c != old.SMAX_PS_SAP_ActivityType__c 
				|| (wo.SVMXC__Perform_Auto_Entitlement__c != old.SVMXC__Perform_Auto_Entitlement__c && wo.SVMXC__Perform_Auto_Entitlement__c == true)
			) && (wo.SVMXC__Perform_Auto_Entitlement__c == true || wo.SVMXC__Is_Entitlement_Performed__c == true)
					&& ENT_BILLING_TYPES.contains(wo.SVMXC__Billing_Type__c) ) {
				readyForCheck = true;
			}

			// 6/15/2020 Tony - ITSVMX-49 - RWO without IP should not go through entitlement check
			// if(readyForCheck){
			// 6/1/2021 ITSVMX-307 - Canceled WOs should not go through entitlement check
			//if(readyForCheck && wo.SVMXC__Component__c != null){
			if(readyForCheck && wo.SVMXC__Component__c != null && wo.SVMXC__Order_Status__c != 'Canceled'){
				System.debug('AUTO-ENTITLE Running on WO: ' + wo);
				wosToCheck.add(wo);
				IBIds.add(wo.SVMXC__Component__c);
				// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				scheduledDates.add(entDate);
				// Auto-Entitlement Notes [SVMXCFG-465]
				wo.SVMXC__Entitlement_Notes__c = '* WO Auto-Entitlement Running...';
			} else {
				System.debug('AUTO-ENTITLE NOT-Running on WO: ' + wo);
			}
		}

		if(wosToCheck.isEmpty()) {
			return;
		}

		//Sort the List of Date
		scheduledDates.sort();
		Date startDate = scheduledDates.get(0);
		Date endDate = scheduledDates.get(scheduledDates.size() - 1);

		//Map of Installed Products and their Covered Products
		//Load the covered products contract items such that we can get the Entitlements                 
		for(SVMXC__Service_Contract_Products__c cp : [SELECT Id, Name, SVMXC__Installed_Product__c,
				SVMXC__Service_Contract__r.Id,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Enterprise__c,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c,
				SVMXC__Service_Contract__r.SMAX_PS_SLA_Terms_Notes__c,
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c,
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_PONumber__c,
				//SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_ContractType__c,
				SVMXC__Start_Date__c, SVMXC__End_Date__c,   
				 (SELECT Id, SMAX_PS_CoveredProduct__c, 
						 SMAX_PS_Entitlement__c, 
						 SMAX_PS_IsDeleted__c, 
						 SMAX_PS_PlannedDate__c, 
						 SMAX_PS_ServiceOrderNumber__c,
						 SMAX_PS_SAP_Notification_ID__c,
						 SMAX_PS_WorkOrder__c
				 	FROM Entitlement_Dates__r
				 		WHERE SMAX_PS_IsDeleted__c = FALSE
						ORDER BY SMAX_PS_PlannedDate__c)
					FROM SVMXC__Service_Contract_Products__c
					WHERE SVMXC__Installed_Product__c IN :IBIds
					AND SMAX_PS_Active__c = TRUE
					AND SVMXC__Start_Date__c <= :startDate 
					AND SVMXC__End_Date__c >= :endDate
					AND SMAX_PS_IsDeleted__c = FALSE
					])
		{
			if (!ipCpMap.containsKey(cp.SVMXC__Installed_Product__c)) {
				ipCpMap.put(cp.SVMXC__Installed_Product__c, new List<SVMXC__Service_Contract_Products__c>());
			}
			//CoveredProductWrapper cpWrap = new CoveredProductWrapper(cp, cp.Entitlement_Dates__r);
			ipCpMap.get(cp.SVMXC__Installed_Product__c).add(cp);
			ContractItemIDs.add(cp.SVMXC__Service_Contract__r.Id);
			if(!contrItemParentContract.containsKey(cp.SVMXC__Service_Contract__r.Id)) {
				contrItemParentContract.put(cp.SVMXC__Service_Contract__r.Id, cp.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c);
			}
		}

		//If IPCP Map is Empty - bail out.
		if(!ipCpMap.isEmpty())
		{
			//Map of Contract Items and their Entitlements
			for(SVMXC__Service_Contract_Services__c ent : [SELECT Id, Name,
					SMAX_PS_EntitlementType__c,
					SMAX_PS_EntitledQty__c,
					SMAX_PS_EntitledQtyRemaining__c,
					SVMXC__Service_Contract__c,
					SVMXC__Labor_Discount_Covered__c, 
					SVMXC__Travel_Discount_Covered__c, 
					SVMXC__Parts_Discount_Covered__c, 
					SMAX_PS_ServicePartsDiscountCovered__c, 
					SMAX_PS_ConsumableDiscountCovered__c,
					BD_Remote_Hours_Remaining__c,
					SMAX_PS_Total_Coverage__c
					FROM SVMXC__Service_Contract_Services__c 
					WHERE SVMXC__Service_Contract__c IN: ContractItemIDs
						AND SMAX_PS_IsDeleted__c = FALSE])
			{
				if (!itemEntMap.containsKey(ent.SVMXC__Service_Contract__c)) {
					itemEntMap.put(ent.SVMXC__Service_Contract__c, new Map<String, SVMXC__Service_Contract_Services__c>());
				}
				itemEntMap.get(ent.SVMXC__Service_Contract__c).put(ent.SMAX_PS_EntitlementType__c, ent);
			}
		}

		//Now the main logic
		for(SVMXC__Service_Order__c wo :  wosToCheck)
		{
			Boolean woEntitled = false;

			//Get the Covered Product Entry for this WO
			List<SVMXC__Service_Contract_Products__c> cpList = ipCpMap.get(wo.SVMXC__Component__c);
			if (cpList == null)
			{
				cpList = new List<SVMXC__Service_Contract_Products__c>();
				wo.SVMXC__Entitlement_Notes__c += '\n No Covered Products found.';
			}

			// ITSFDC-1047 ONLY lookup Ent Options for "PHN" (and not "ZZZ")
			String entType = wo.SMAX_PS_SAP_ActivityType__c;
			Boolean isRemote = (wo.RecordTypeId == remoteRT.Id);

			wo.SVMXC__Entitlement_Notes__c += '\n Finding Entitlements matching: ' + entType;
			List<EntitlementWrapper> entOptions = getEntitlementOptions(entType, cpList, itemEntMap, !isRemote);
			for (EntitlementWrapper entWrap : entOptions)
			{
				SVMXC__Service_Contract_Products__c cp = entWrap.cp;
				// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				if (entDate < cp.SVMXC__Start_Date__c || entDate > cp.SVMXC__End_Date__c)
				{
					wo.SVMXC__Entitlement_Notes__c += '\n Skipping CP due to coverage dates: ' + cp.Name;
					continue;
				}
				
				String entitlementType = entWrap.entType;
				wo.SVMXC__Entitlement_Notes__c += '\n Trying to entitle to CP: ' + cp.Name + ' for Entitlement Type: ' + entitlementType;
				//Get the id from the Contract Item
				Id contractItemId = cp.SVMXC__Service_Contract__r.Id;
				List<SMAX_PS_EntitlementDate__c> eDates = entWrap.entitlementDates;

				SVMXC__Service_Contract_Services__c ent = entWrap.ent;
				if (ent != null)
				{
					woEntitled = isEntitled(wo, ent, eDates, edsToUpdate);
					if (woEntitled == false) {
						ent = null;
					}
				}

				if(woEntitled)
				{
					wo.SVMXC__Service_Contract__c = contrItemParentContract.get(contractItemId);
					wo.SMAX_PS_ContractItem__c = contractItemId;
					wo.SMAX_PS_ContractEntitlement__c = ent.Id;										
					wo.SMAX_PS_CoveredProduct__c = cp.Id;
					wo.SVMXC__Auto_Entitlement_Status__c = 'Success';
					wo.SVMXC__Entitlement_Type__c = 'AUTO';
					wo.SVMXC__Is_Entitlement_Performed__c = true;
					wo.SVMXC__Entitlement_Notes__c += '\n Auto Entitlement Completed and is Successful.';
					if (wo.SVMXC__Entitlement_Notes__c.length() >= 32000)
					{
						wo.SVMXC__Entitlement_Notes__c = wo.SVMXC__Entitlement_Notes__c.substring(0, 31995) + '...';
					}
					wo.SVMXC__Perform_Auto_Entitlement__c = false;
					wo.SVMXC__Billing_Type__c = 'Contract';
					String slaTerms = cp.SVMXC__Service_Contract__r.SMAX_PS_SLA_Terms_Notes__c;
					if (slaTerms != null && slaTerms.length() >= 255)
					{
						slaTerms = slaTerms.substring(0, 252) + '...';
					}
					wo.SMAX_PS_SLA_Terms_Notes__c = slaTerms;
					// SVMXCFG-549 : Map new IsEnteprise and IsWarranty fields
					wo.SMAX_PS_IsEntitledWarranty__c = cp.SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c;
					wo.SMAX_PS_Is_Enterprise__c = cp.SVMXC__Service_Contract__r.SMAX_PS_Is_Enterprise__c;

					// SVMXCFG-574 Off-Line Price Fields - To support Offline Contract Discounts
					wo.SMAX_PS_Offline_Contract_Discounts__c = calculateOfflineDiscounts(ent);

					// SVMXCFG-916 Copy Service Contract PO Number to WO
					if (wo.SMAX_PS_CustomerPO__c == null)
					{
						wo.SMAX_PS_CustomerPO__c = cp.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_PONumber__c;
					}

					// ITSFDC-1047 Change "Remote" WO Status to ensure it is sent to SAP
					if (isRemote) {
						// NOTE: We could change to "Field_Service" RecordType as well, but more "correct" to leave as "Remote"
						wo.SVMXC__Order_Status__c = 'Initializing';
						wo.BD_Is_Remote_Support_Hours__c = true;
					}

					// NOTE: Whenever the above mappings change, also change "completeEntitlement" below AND SMAX_PS_CreateScheduledWorkOrdersBatch

					wosToUpdate.add(wo);
					break; // Stop looping over the CPs.. found a match.
				}
			}

			// ITSFDC-1047 Do NOT error-out "Remote" Work Orders
			if ((!woEntitled) && (!isRemote))
			{
				// FRANK 20171213 - PKI decided to cause this txn to fail when not entitled instead
				wo.SVMXC__Order_Type__c = null;
				wo.SVMXC__Billing_Type__c = 'Billable';
				wo.addError('Contract Entitlement failed. Please select a Billing Type of "Billable" or a different Order Type.');

				// None of the CPs were a match..
				//wo.SVMXC__Service_Contract__c = null;
				//wo.SMAX_PS_ContractItem__c = null;
				//wo.SMAX_PS_ContractEntitlement__c = null;										
				//wo.SMAX_PS_CoveredProduct__c = null;
				//wo.SVMXC__Auto_Entitlement_Status__c = 'Failed';
				//wo.SVMXC__Entitlement_Type__c = 'AUTO';
				//wo.SVMXC__Is_Entitlement_Performed__c = TRUE;
				//wo.SVMXC__Entitlement_Notes__c = 'Auto Entitlement Failed.';
				//wo.SVMXC__Perform_Auto_Entitlement__c = FALSE;
				//wo.SVMXC__Billing_Type__c = 'Billable';
				//wosToUpdate.add(wo);
			} else if ((!woEntitled) && isRemote) {
				// Blank out the Remote WO Billing Type if failed entitlement
				wo.SVMXC__Billing_Type__c = null;
			}
		}

		if (!edsToUpdate.isEmpty()) {
			update edsToUpdate;
		}

		// NOTE: No need to update "wosToUpdate".. this is invoked in "before update"

	}

	// New Entitlement Process for WO Load transactions..
	// SAP sends us the Contract & Contract Item, but we need to fill in the Entitlement and Covered Product
	// Also decided to set SVMXC__Entitlement_Type__c = 'SAP'
	public static void completeEntitlement(List<SVMXC__Service_Order__c> wos, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('WO Complete Entitlement', 'Complete the Entitlement on the WO based on the Contract Item assigned in SAP'))
		{	return;	}

		List<SVMXC__Service_Order__c> wosToCheck = new List<SVMXC__Service_Order__c>();
		List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
		List<SMAX_PS_EntitlementDate__c> edsToUpdate = new List<SMAX_PS_EntitlementDate__c>();
		//Map<Id, List<CoveredProductWrapper>> ipCpMap = new Map<Id, List<CoveredProductWrapper>>(); 
		Map<Id, List<SVMXC__Service_Contract_Products__c>> ipCpMap = new Map<Id, List<SVMXC__Service_Contract_Products__c>>(); 
		Map<Id, Map<String, SVMXC__Service_Contract_Services__c>> itemEntMap = new Map<Id, Map<String, SVMXC__Service_Contract_Services__c>>();
		Map<Id, Id> contrItemParentContract = new Map<Id, Id>();
		Set<Id> ContractItemIDs = new Set<Id>();
		Set<Id> IBIds = new Set<Id>();
		List<Date> scheduledDates = new List<Date>();
		for (SVMXC__Service_Order__c wo : wos)
		{
			//SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.SVMXC__Is_Entitlement_Performed__c == false
				&& wo.SVMXC__Service_Contract__c != null && wo.SMAX_PS_ContractItem__c != null
				&& wo.SMAX_PS_ContractEntitlement__c == null && wo.SMAX_PS_CoveredProduct__c == null)
			{
				System.debug('COMPLETE-ENTITLE Running on WO: ' + wo);
				wosToCheck.add(wo);
				IBIds.add(wo.SVMXC__Component__c);
				ContractItemIDs.add(wo.SMAX_PS_ContractItem__c);
				// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				scheduledDates.add(entDate);
				// Auto-Entitlement Notes [SVMXCFG-465]
				wo.SVMXC__Entitlement_Notes__c = '* WO Complete-Entitlement Running...';
			} else {
				System.debug('COMPLETE-ENTITLE NOT-Running on WO: ' + wo);
			}
		}

		if(wosToCheck.isEmpty()) {
			return;
		}

		//Sort the List of Date
		scheduledDates.sort();
//		Date startDate = scheduledDates.get(0);
//		Date endDate = scheduledDates.get(scheduledDates.size() - 1);

		//Map of Installed Products and their Covered Products
		//Load the covered products contract items such that we can get the Entitlements                 
		for(SVMXC__Service_Contract_Products__c cp : [SELECT Id, Name, SVMXC__Installed_Product__c,
				SVMXC__Service_Contract__r.Id,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Enterprise__c,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c,
				SVMXC__Service_Contract__r.SMAX_PS_SLA_Terms_Notes__c, 
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c, 
				//SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_ContractType__c,
				SVMXC__Start_Date__c, SVMXC__End_Date__c,   
				 (SELECT Id, SMAX_PS_CoveredProduct__c, 
						 SMAX_PS_Entitlement__c, 
						 SMAX_PS_IsDeleted__c, 
						 SMAX_PS_PlannedDate__c, 
						 SMAX_PS_ServiceOrderNumber__c,
						 SMAX_PS_SAP_Notification_ID__c,
						 SMAX_PS_WorkOrder__c
				 	FROM Entitlement_Dates__r
				 		WHERE SMAX_PS_IsDeleted__c = FALSE
				 		ORDER BY SMAX_PS_PlannedDate__c)
					FROM SVMXC__Service_Contract_Products__c
					WHERE SVMXC__Installed_Product__c IN :IBIds
					AND SVMXC__Service_Contract__c IN :ContractItemIDs
					AND SMAX_PS_IsDeleted__c = FALSE
					])
					//AND SMAX_PS_Active__c = true 
					//AND SVMXC__Start_Date__c <= :startDate 
					//AND SVMXC__End_Date__c >= :endDate
		{
			if (!ipCpMap.containsKey(cp.SVMXC__Installed_Product__c)) {
				ipCpMap.put(cp.SVMXC__Installed_Product__c, new List<SVMXC__Service_Contract_Products__c>());
			}
			//CoveredProductWrapper cpWrap = new CoveredProductWrapper(cp, cp.Entitlement_Dates__r);
			ipCpMap.get(cp.SVMXC__Installed_Product__c).add(cp);
			//ContractItemIDs.add(cp.SVMXC__Service_Contract__r.Id);
			if(!contrItemParentContract.containsKey(cp.SVMXC__Service_Contract__r.Id)) {
				contrItemParentContract.put(cp.SVMXC__Service_Contract__r.Id, cp.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c);
			}
		}

		//If IPCP Map is Empty - bail out.
		if(!ipCpMap.isEmpty())
		{
			//Map of Contract Items and their Entitlements
			for(SVMXC__Service_Contract_Services__c ent : [SELECT Id, Name,
					SMAX_PS_EntitlementType__c,
					SMAX_PS_EntitledQty__c,
					SMAX_PS_EntitledQtyRemaining__c,
					SVMXC__Service_Contract__c,
					SVMXC__Labor_Discount_Covered__c, 
					SVMXC__Travel_Discount_Covered__c, 
					SVMXC__Parts_Discount_Covered__c, 
					SMAX_PS_ServicePartsDiscountCovered__c, 
					SMAX_PS_ConsumableDiscountCovered__c,
					BD_Remote_Hours_Remaining__c,
					SMAX_PS_Total_Coverage__c
					FROM SVMXC__Service_Contract_Services__c 
					WHERE SVMXC__Service_Contract__c IN: ContractItemIDs
					AND SMAX_PS_IsDeleted__c = FALSE])
			{
				if (!itemEntMap.containsKey(ent.SVMXC__Service_Contract__c)) {
					itemEntMap.put(ent.SVMXC__Service_Contract__c, new Map<String, SVMXC__Service_Contract_Services__c>());
				}
				itemEntMap.get(ent.SVMXC__Service_Contract__c).put(ent.SMAX_PS_EntitlementType__c, ent);
			}
		}

		//Now the main logic
		for(SVMXC__Service_Order__c wo :  wosToCheck)
		{
			Boolean woEntitled = false;

			//Get the Covered Product Entry for this WO
			List<SVMXC__Service_Contract_Products__c> cpList = ipCpMap.get(wo.SVMXC__Component__c);
			if (cpList == null)
			{
				cpList = new List<SVMXC__Service_Contract_Products__c>();
				wo.SVMXC__Entitlement_Notes__c += '\n No Covered Products found.';
			}

			wo.SVMXC__Entitlement_Notes__c += '\n Finding Entitlements matching: ' + wo.SMAX_PS_SAP_ActivityType__c;
			List<EntitlementWrapper> entOptions = getEntitlementOptions(wo.SMAX_PS_SAP_ActivityType__c, cpList, itemEntMap, true);
			for (EntitlementWrapper entWrap : entOptions)
			{
				SVMXC__Service_Contract_Products__c cp = entWrap.cp;
				// NOTE: Do not check entitlement date for "complete".. already entitled, no need to validate
				
				String entitlementType = entWrap.entType;
				//Get the id from the Contract Item
				Id contractItemId = cp.SVMXC__Service_Contract__r.Id;
				if (wo.SMAX_PS_ContractItem__c != contractItemId) {
					continue;
				}

				wo.SVMXC__Entitlement_Notes__c += '\n Trying to entitle to CP: ' + cp.Name + ' for Entitlement Type: ' + entitlementType;
				List<SMAX_PS_EntitlementDate__c> eDates = entWrap.entitlementDates;

				SVMXC__Service_Contract_Services__c ent = entWrap.ent;
				if (ent != null)
				{
					woEntitled = isEntitled(wo, ent, eDates, edsToUpdate);
					if (woEntitled == false) {
						ent = null;
					}
				}

				if(woEntitled)
				{
					//wo.SVMXC__Service_Contract__c = contrItemParentContract.get(contractItemId);
					//wo.SMAX_PS_ContractItem__c = contractItemId;
					wo.SMAX_PS_ContractEntitlement__c = ent.Id;										
					wo.SMAX_PS_CoveredProduct__c = cp.Id;
					wo.SVMXC__Auto_Entitlement_Status__c = 'Success';
					wo.SVMXC__Entitlement_Type__c = 'SAP';
					wo.SVMXC__Is_Entitlement_Performed__c = true;
					wo.SVMXC__Entitlement_Notes__c += '\n Complete Entitlement was Successful.';
					if (wo.SVMXC__Entitlement_Notes__c.length() >= 32000)
					{
						wo.SVMXC__Entitlement_Notes__c = wo.SVMXC__Entitlement_Notes__c.substring(0, 32000) + '...';
					}
					wo.SVMXC__Perform_Auto_Entitlement__c = false;
					String slaTerms = cp.SVMXC__Service_Contract__r.SMAX_PS_SLA_Terms_Notes__c;
					if (slaTerms != null && slaTerms.length() >= 255)
					{
						slaTerms = slaTerms.substring(0, 252) + '...';
					}
					wo.SMAX_PS_SLA_Terms_Notes__c = slaTerms;
					// SVMXCFG-549 : Map new IsEnteprise and IsWarranty fields
					wo.SMAX_PS_IsEntitledWarranty__c = cp.SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c;
					wo.SMAX_PS_Is_Enterprise__c = cp.SVMXC__Service_Contract__r.SMAX_PS_Is_Enterprise__c;
					//if (cp.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_ContractType__c == WARRANTY_CONTRACT_TYPE)
					//{
					//	wo.SMAX_PS_IsEntitledWarranty__c = TRUE;
					//}

					// SVMXCFG-574 Off-Line Price Fields - To support Offline Contract Discounts
					wo.SMAX_PS_Offline_Contract_Discounts__c = calculateOfflineDiscounts(ent);

					// SVMXCFG-916 Copy Service Contract PO Number to WO - We should not do this here, for WO Load

					wosToUpdate.add(wo);
					break; // Stop looping over the CPs.. found a match.
				}
			}

			if (!woEntitled)
			{
				// FOR COMPLETE-ENTITLEMENT ... don't want to "fail"
				wo.SVMXC__Auto_Entitlement_Status__c = 'Failed';
				wo.SVMXC__Entitlement_Type__c = 'SAP';
				wo.SVMXC__Is_Entitlement_Performed__c = true;
				wo.SVMXC__Entitlement_Notes__c += '\n Complete Entitlement was NOT Successful.';
				wo.SVMXC__Perform_Auto_Entitlement__c = false;
			}
		}

		if (!edsToUpdate.isEmpty()) {
			update edsToUpdate;
		}

		// NOTE: No need to update "wosToUpdate".. this is invoked in "before update"

	}

	private static Boolean isEntitled(SVMXC__Service_Order__c wo, SVMXC__Service_Contract_Services__c ent, List<SMAX_PS_EntitlementDate__c> eDates, List<SMAX_PS_EntitlementDate__c> edsToUpdate)
	{
		wo.SVMXC__Entitlement_Notes__c += '\n Checking Entitlement: ' + ent.Name + ' (' + ent.SMAX_PS_EntitlementType__c + ')';
		Boolean woEntitled = false;

		// ITSFDC-1047 For "REMOTE" also ensure Hours remain in the Block ...
		RecordType remoteRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');
		Boolean isRemoteWO = (wo.RecordTypeId == remoteRT.Id);
		Boolean isRemoteEnt = (ent.BD_Remote_Hours_Remaining__c != null);
		if (isRemoteWO && isRemoteEnt)
		{
			if (ent.BD_Remote_Hours_Remaining__c > 0)
			{
				woEntitled = true;
				System.debug('AUTO-ENTITLE Matching to Entitlement for Block of Hours: ' + ent);
				wo.SVMXC__Entitlement_Notes__c += '\n Matching to Entitlement of Remote Hours: ' + ent.Name + ' [' + ent.BD_Remote_Hours_Remaining__c + ' Hours Remaining]';
			}
			else
			{
				woEntitled = false;
				System.debug('AUTO-ENTITLE NOT Matching to Entitlement of Remote Hours: ' + ent);
				wo.SVMXC__Entitlement_Notes__c += '\n NOT Matching to Entitlement of Remote Hours [NO HOURS REMAINING]: ' + ent.Name;
			}
			return woEntitled;
		}
		else if (isRemoteWO || isRemoteEnt)
		{
			// Mis-match between WO & Entitlement (Remote vs Field Service)
			woEntitled = false;
			wo.SVMXC__Entitlement_Notes__c += '\n NOT Matching to Entitlement of Remote Hours [Remote/Field mismatch]: ' + ent.Name;
			return woEntitled;
		}

		if (!woEntitled && eDates != null && !eDates.isEmpty())
		{
			//Get the first Entitlement Date that does not have a WO Number
			for(SMAX_PS_EntitlementDate__c ed : eDates)
			{
				if (ed.SMAX_PS_Entitlement__c == ent.Id)
				{
					wo.SVMXC__Entitlement_Notes__c += '\n Checking EntitlementDate: ' + ed.SMAX_PS_PlannedDate__c;
					if (ed.SMAX_PS_ServiceOrderNumber__c == null && ed.SMAX_PS_SAP_Notification_ID__c == null && ed.SMAX_PS_WorkOrder__c == null)
					{
						woEntitled = true;
						wo.SVMXC__Entitlement_Notes__c += '\n Non-Consumed EntitlementDate Matched: ' + ed.SMAX_PS_PlannedDate__c;
						break;
					}
					else if (wo.SVMX_PS_External_ID__c != null && ed.SMAX_PS_ServiceOrderNumber__c != null)
					{
						String formatted = '00000000000' + ed.SMAX_PS_ServiceOrderNumber__c;
						formatted = formatted.substring(formatted.length()-12);
						String soNumber = wo.SVMX_PS_External_ID__c;
						if (soNumber != null && soNumber.equals(formatted))
						{
							// Found a match for a SAP Service Order Number ... WO Loads
							woEntitled = true;
							//System.debug('AUTO-ENTITLE Existing EntitlementDate mapping found: ' + ed);
							wo.SVMXC__Entitlement_Notes__c += '\n Pre-Consumed EntitlementDate Matched: ' + ed.SMAX_PS_PlannedDate__c;
							break;
						}
					}
				}
			}

			if (woEntitled == false) {
				System.debug('AUTO-ENTITLE No Matching EntitlementDate found..');
			}
		}

		//Are there quantities available on the Entitlment? (NOTE: 0/0 will be entitled)
		if(!woEntitled &&
			ent.SMAX_PS_EntitledQty__c != null && ent.SMAX_PS_EntitledQtyRemaining__c != null 
			&& (ent.SMAX_PS_EntitledQtyRemaining__c > 0 || ent.SMAX_PS_EntitledQty__c == 0))
		{
			woEntitled = true;
			System.debug('AUTO-ENTITLE Matching to Entitlement by Qty: ' + ent);
			wo.SVMXC__Entitlement_Notes__c += '\n Matching to Entitlement by Qty: ' + ent.Name;
		}

		return woEntitled;
	}

	// PRE Entitlement Check on the Case
	public static void performPreEntitlementCheck(List<Case> cases, Map<Id, Case> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Case Pre-Entitlement Check', 'Perform a Pre-Entitlement check on the Case based on the IP and Scheduled Date'))
		{	return;	}

		List<Case> casesToCheck = new List<Case>();
		Set<Id> IBIds = new Set<Id>();
		Map<Id, Date> caseDateMap = new Map<Id, Date>();
		for (Case c : cases)
		{
			Boolean readyForCheck = false;
			Case old = (oldMap == null) ? null : oldMap.get(c.Id);
			Date entDate = (c.CreatedDate == null) ? Date.today() : c.CreatedDate.date();
			//Check if insert...
			if(old == null && (c.SVMXC__Perform_Auto_Entitlement__c == true 
				&& c.SVMXC__Component__c != null) ) {
				readyForCheck = true;
			}
			//Check if update...
			if(old != null && (c.SVMXC__Component__c != old.SVMXC__Component__c 
				|| (c.SVMXC__Perform_Auto_Entitlement__c != old.SVMXC__Perform_Auto_Entitlement__c && c.SVMXC__Perform_Auto_Entitlement__c == true) ) 
				&& (c.SVMXC__Component__c != null ) ) {
				readyForCheck = true;
			}

			if(readyForCheck){
				System.debug('AUTO-ENTITLE Running on Case: ' + c);
				casesToCheck.add(c);
				IBIds.add(c.SVMXC__Component__c);
				caseDateMap.put(c.Id, entDate);
			} else {
				System.debug('AUTO-ENTITLE NOT-Running on Case: ' + c);
			}
		}

		if(casesToCheck.isEmpty()) {
			return;
		}

		//Sort the List of Date
		List<Date> scheduledDates = new List<Date>(caseDateMap.values());
		scheduledDates.sort();
		Date startDate = scheduledDates.get(0);
		Date endDate = scheduledDates.get(scheduledDates.size() - 1);

		//Map of Installed Products and their Covered Products
		Map<Id, List<SVMXC__Service_Contract_Products__c>> ipCpMap = new Map<Id, List<SVMXC__Service_Contract_Products__c>>(); 
		//Load the covered products contract items such that we can get the Entitlements                 
		for(SVMXC__Service_Contract_Products__c cp : [SELECT Id, Name, SVMXC__Installed_Product__c,
				SVMXC__Service_Contract__r.Id,
				SVMXC__Service_Contract__r.Name,
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c, 
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.Name,
				SVMXC__Start_Date__c, SVMXC__End_Date__c
					FROM SVMXC__Service_Contract_Products__c
					WHERE SVMXC__Installed_Product__c IN :IBIds
					AND SMAX_PS_Active__c = TRUE
					AND SVMXC__Start_Date__c <= :startDate 
					AND SVMXC__End_Date__c >= :endDate
					AND SMAX_PS_IsDeleted__c = FALSE])
		{
			if (!ipCpMap.containsKey(cp.SVMXC__Installed_Product__c)) {
				ipCpMap.put(cp.SVMXC__Installed_Product__c, new List<SVMXC__Service_Contract_Products__c>());
			}
			ipCpMap.get(cp.SVMXC__Installed_Product__c).add(cp);
		}

		for (Case c : casesToCheck)
		{
			Id ipId = c.SVMXC__Component__c;
			Date scheduledDate = caseDateMap.get(c.Id);
			List<SVMXC__Service_Contract_Products__c> cpList = ipCpMap.get(ipId);
			SVMXC__Service_Contract_Products__c matchingCp = null;
			if (cpList != null)
			{
				for (SVMXC__Service_Contract_Products__c cp : cpList)
				{
					if (cp.SVMXC__Start_Date__c <= scheduledDate && cp.SVMXC__End_Date__c >= scheduledDate)
					{
						matchingCp = cp;
					}
				}
			}

			if (matchingCp == null)
			{
				c.SVMXC__Entitlement_Notes__c = 'No Active Service Contract Coverage for the Installed Product was found.';
				c.SVMXC__Service_Contract__c = null;
				c.SVMXC__Auto_Entitlement_Status__c = 'Failed';
				c.SVMXC__Is_Entitlement_Performed__c = true;
				c.SVMXC__Perform_Auto_Entitlement__c = false;
				c.SVMXC__Entitlement_Type__c = 'AUTO';
			}
			else
			{
				c.SVMXC__Entitlement_Notes__c = 'Service Contract Coverage was found. Contract Item: ' 
					+ matchingCp.SVMXC__Service_Contract__r.Name
					+ ', Covered Product: ' + matchingCp.Name;
				c.SVMXC__Service_Contract__c = matchingCp.SVMXC__Service_Contract__r.Id;
				c.SVMXC__Auto_Entitlement_Status__c = 'Success';
				c.SVMXC__Is_Entitlement_Performed__c = true;
				c.SVMXC__Perform_Auto_Entitlement__c = false;
				c.SVMXC__Entitlement_Type__c = 'AUTO';
			}
		}
	}

	public static void syncIsBillable(List<SVMXC__Service_Order__c> wos, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Sync Is Billable', 'Copy the Is Billable flag from the Entitled Contract Item to the WO'))
		{	return;	}

		Set<Id> itemIds = new Set<Id>();
		List<SVMXC__Service_Order__c> wosToCheck = new List<SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : wos)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.SVMXC__Billing_Type__c == 'Billable') {
				wo.SMAX_PS_Is_Billable__c = true;
			}
			else if (wo.SMAX_PS_ContractItem__c != null
				&& (old == null || (old != null && wo.SMAX_PS_ContractItem__c != old.SMAX_PS_ContractItem__c))) {
				itemIds.add(wo.SMAX_PS_ContractItem__c);
				wosToCheck.add(wo);
			}
		}

		if (itemIds.isEmpty()) {
			return;
		}

		Map<Id, SVMXC__Service_Contract__c> itemMap = new Map<Id, SVMXC__Service_Contract__c>(
			[SELECT Id, SMAX_PS_Is_Billable__c FROM SVMXC__Service_Contract__c WHERE Id IN :itemIds]);
		for (SVMXC__Service_Order__c wo : wosToCheck)
		{
			SVMXC__Service_Contract__c item = itemMap.get(wo.SMAX_PS_ContractItem__c);
			if (item != null) {
				wo.SMAX_PS_Is_Billable__c = item.SMAX_PS_Is_Billable__c;
			}
		}
	}

	public static String calculateOfflineDiscounts(SVMXC__Service_Contract_Services__c ent)
	{
		/*
		{ "Labor":100.0, "Travel":90.0, "Parts":80.0, "Other Parts":80.0, "Service Parts":70.0, "Consumable":60.0}
		*/
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		gen.writeNumberField('Labor', ent.SVMXC__Labor_Discount_Covered__c == null ? 0 : ent.SVMXC__Labor_Discount_Covered__c);
		gen.writeNumberField('Travel', ent.SVMXC__Travel_Discount_Covered__c == null ? 0 : ent.SVMXC__Travel_Discount_Covered__c);
		gen.writeNumberField('Parts', ent.SVMXC__Parts_Discount_Covered__c == null ? 0 : ent.SVMXC__Parts_Discount_Covered__c);
		gen.writeNumberField('Other Parts', ent.SVMXC__Parts_Discount_Covered__c == null ? 0 : ent.SVMXC__Parts_Discount_Covered__c);
		gen.writeNumberField('Service Parts', ent.SMAX_PS_ServicePartsDiscountCovered__c == null ? 0 : ent.SMAX_PS_ServicePartsDiscountCovered__c);
		gen.writeNumberField('Consumable', ent.SMAX_PS_ConsumableDiscountCovered__c == null ? 0 : ent.SMAX_PS_ConsumableDiscountCovered__c);
		gen.writeEndObject();

		return gen.getAsString();
	}

	// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
	private static Date getEntitlementDate(SVMXC__Service_Order__c wo)
	{
		// Use Today if no ScheduledDate populated (below also)
		if (wo.SVMXC__Scheduled_Date__c == null) {
			wo.SVMXC__Scheduled_Date__c = Date.today();
		}

		return (wo.SMAX_PS_Customer_Required_Start_Date__c != null) ?
			wo.SMAX_PS_Customer_Required_Start_Date__c : wo.SVMXC__Scheduled_Date__c;
	}

}
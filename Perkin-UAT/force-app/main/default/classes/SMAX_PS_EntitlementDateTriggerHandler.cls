/*
 *  Trigger Handler for Entitlement Date [SMAX_PS_EntitlementDate__c]
 *  2022-10-24      Bolt Data - E. Ross      Modifications for Polaris Project.
 */
public with sharing class SMAX_PS_EntitlementDateTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
	public SMAX_PS_EntitlementDateTriggerHandler() {
	}

	public void beforeInsert()
	{
		List<SMAX_PS_EntitlementDate__c> newList = Trigger.new;

		// SVMXCFG-455: When the ServiceOrderNumber is filled in on Entitlement Date, try to fill in the WO Lookup.
		SMAX_PS_ServiceContractManager.lookupWorkOrders(newList, null);
		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
	}

	public void afterInsert() {}
	public void beforeUpdate() 
	{
		List<SMAX_PS_EntitlementDate__c> newList = Trigger.new;
		Map<Id, SMAX_PS_EntitlementDate__c> oldMap = (Map<Id, SMAX_PS_EntitlementDate__c>) Trigger.oldMap;
		
		// SVMXCFG-455: When the ServiceOrderNumber is filled in on Entitlement Date, try to fill in the WO Lookup.
		SMAX_PS_ServiceContractManager.lookupWorkOrders(newList, oldMap);
		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
	}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}
/*
 *  Trigger Handler for Service Contract Entitlement [SVMXC__Service_Contract_Services__c]
 *  2017-11-30      Frank VanLoon         Initial creation, for Service Contract Integration.
 */
public with sharing class SMAX_PS_ServiceContractEntTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

	public SMAX_PS_ServiceContractEntTriggerHandler() {
	}

	public void beforeInsert() {
		List<SVMXC__Service_Contract_Services__c> newList = Trigger.new;

		// Added by Frank - Nov 17 2017
		SMAX_PS_Utility.updateMappedValues('SVMXC__Service_Contract_Services__c', newList, null);
	}

	public void beforeUpdate() {
		List<SVMXC__Service_Contract_Services__c> newList = Trigger.new;
		Map<Id, SVMXC__Service_Contract_Services__c> oldMap = (Map<Id, SVMXC__Service_Contract_Services__c>) Trigger.oldMap;

		// Added by Frank - Nov 17 2017
		SMAX_PS_Utility.updateMappedValues('SVMXC__Service_Contract_Services__c', newList, oldMap);
	}

	public void afterInsert() {}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
}
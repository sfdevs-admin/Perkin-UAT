public with sharing class SMAX_PS_TechnicianTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
	public SMAX_PS_TechnicianTriggerHandler() {
	}

	public void beforeInsert() 
	{
		List<SVMXC__Service_Group_Members__c> newList = Trigger.new;

		SMAX_PS_TechnicianManager.updateTechnicianLocations(newList, null);
		SMAX_PS_TechnicianManager.updateDepotQueues(newList, null);
		BD_Address_i18n.formatAddressTrigger(newList, null);
	}

	public void afterInsert() {}
	public void beforeUpdate() 
	{
		List<SVMXC__Service_Group_Members__c> newList = Trigger.new;
		Map<Id, SVMXC__Service_Group_Members__c> oldMap = (Map<Id, SVMXC__Service_Group_Members__c>) Trigger.oldMap;

		SMAX_PS_TechnicianManager.validateTechnicianGeographies(newList, oldMap);
		SMAX_PS_TechnicianManager.updateTechnicianLocations(newList, oldMap);
		SMAX_PS_TechnicianManager.updateDepotQueues(newList, oldMap);
		BD_Address_i18n.formatAddressTrigger(newList, oldMap);
	}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
}
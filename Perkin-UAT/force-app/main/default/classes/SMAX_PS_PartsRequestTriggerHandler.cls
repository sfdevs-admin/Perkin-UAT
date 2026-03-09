/*
 *  Trigger Handler for Parts Request [SVMXC__Parts_Request__c]
 *  2022-10-24      Bolt Data - E. Ross      Initial creation, for Polaris Project.
 */
public with sharing class SMAX_PS_PartsRequestTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_PartsRequestTriggerHandler() {}

    public void beforeInsert() {
        
        List<SVMXC__Parts_Request__c> newList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updatePartsRequestObject(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<SVMXC__Parts_Request__c> newList = Trigger.new;
        Map<Id, SVMXC__Parts_Request__c> oldMap = (Map<Id, SVMXC__Parts_Request__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updatePartsRequestObject(newList, oldMap);
    }
    public void afterUpdate(){}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {} 
}
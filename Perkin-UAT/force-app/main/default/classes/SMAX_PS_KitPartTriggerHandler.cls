/*
 *  Trigger Handler for Kit Part [SVMX_PS_Kit_Part__c]
 *  2022-10-24      Bolt Data - E. Ross      Initial creation, for Polaris Project.
 */
public with sharing class SMAX_PS_KitPartTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
    
    public SMAX_PS_KitPartTriggerHandler() {}

    public void beforeInsert() {
        
        List<SVMX_PS_Kit_Part__c> newList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<SVMX_PS_Kit_Part__c> newList = Trigger.new;
        Map<Id, SVMX_PS_Kit_Part__c> oldMap = (Map<Id, SVMX_PS_Kit_Part__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
    }
    public void afterUpdate(){}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}
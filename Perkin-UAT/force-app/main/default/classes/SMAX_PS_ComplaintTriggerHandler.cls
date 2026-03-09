public with sharing class SMAX_PS_ComplaintTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_ComplaintTriggerHandler() {
    }
    
    public void beforeInsert() {
        
        List<SMAX_PS_Complaint__c> newList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<SMAX_PS_Complaint__c> newList = Trigger.new;
        Map<Id, SMAX_PS_Complaint__c> oldMap = (Map<Id, SMAX_PS_Complaint__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
    }
    public void afterUpdate()
    {
        List<SMAX_PS_Complaint__c> newList = Trigger.new;
        Map<Id, SMAX_PS_Complaint__c> oldMap = (Map<Id, SMAX_PS_Complaint__c>) Trigger.oldMap;
        SMAX_PS_ComplaintManager.deleteComplaintChildRecords(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}
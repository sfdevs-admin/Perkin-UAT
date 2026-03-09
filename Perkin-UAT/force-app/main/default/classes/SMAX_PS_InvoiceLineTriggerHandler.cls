public with sharing class SMAX_PS_InvoiceLineTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_InvoiceLineTriggerHandler() {
    }
    
    public void beforeInsert()
    {
        List<SVMXC__Proforma_Invoice_Line__c> newList = Trigger.new;
        // SVMTINT-654 - added 2019-05-01
        SMAX_PS_InvoiceManager.updateCancelationLineFields(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate()
    {
        List<SVMXC__Proforma_Invoice_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice_Line__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice_Line__c>) Trigger.oldMap;
        // SVMTINT-654 - added 2019-05-01
        SMAX_PS_InvoiceManager.updateCancelationLineFields(newList, oldMap);
    }

    public void afterUpdate() {
        List<SVMXC__Proforma_Invoice_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice_Line__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice_Line__c>) Trigger.oldMap;
        SMAX_PS_InvoiceManager.adjustDMR(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}
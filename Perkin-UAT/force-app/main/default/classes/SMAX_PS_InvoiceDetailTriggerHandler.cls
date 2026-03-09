public with sharing class SMAX_PS_InvoiceDetailTriggerHandler  implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_InvoiceDetailTriggerHandler() {
    }
    
    public void beforeInsert()
    {
        List<SVMXC__Proforma_Invoice_Detail__c> newList = Trigger.new;
        // SVMTINT-654 - added 2019-05-01
        SMAX_PS_InvoiceManager.updateCancelationDetailFields(newList, null);
    }
    public void afterInsert() 
    {
        List<SVMXC__Proforma_Invoice_Detail__c> newList = Trigger.new;
        SMAX_PS_InvoiceManager.updateDetailFields(newList, null);
        SMAX_PS_InvoiceManager.updateWOstatusToInvoiced(newList); 
        // For SVMXCFG-607 - added 6/18/18
        SMAX_PS_InvoiceManager.copyBillingAddressFromAcct(newList);
    }

    public void beforeUpdate()
    {
        List<SVMXC__Proforma_Invoice_Detail__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice_Detail__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice_Detail__c>) Trigger.oldMap;
        // SVMTINT-654 - added 2019-05-01
        SMAX_PS_InvoiceManager.updateCancelationDetailFields(newList, oldMap);
    }
    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}
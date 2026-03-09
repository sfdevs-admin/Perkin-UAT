/*
 *  Trigger Handler for Proforma Invoice [SVMXC__Proforma_Invoice__c]
 *  2022-10-24      Bolt Data - E. Ross      Modifications for Polaris Project.
 */
public with sharing class SMAX_PS_InvoiceTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_InvoiceTriggerHandler() {
    }
    
    public void beforeInsert() 
    {
        List<SVMXC__Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice__c>) Trigger.oldMap;

        SMAX_PS_InvoiceManager.defaultFields(newList);
        SMAX_PS_InvoiceManager.onCancellationInvoice(newList);
        SMAX_PS_OwnedByCompanyManager.updateProformaInvObject(newList, oldMap);
    }

    public void afterInsert()
    {
        List<SVMXC__Proforma_Invoice__c> newList = Trigger.new;

        SMAX_PS_InvoiceManager.onNewInvoice(newList);
    }

    public void beforeUpdate()
    {
        List<SVMXC__Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice__c>) Trigger.oldMap;
        SMAX_PS_InvoiceManager.unlockDMR(newList, oldMap);
        SMAX_PS_InvoiceManager.copyPriceAdjustments(newList, oldMap);
        SMAX_PS_InvoiceManager.invoiceNotRequired(newList, oldMap);
        SMAX_PS_OwnedByCompanyManager.updateProformaInvObject(newList, oldMap);
    }

    public void afterUpdate() {
        List<SVMXC__Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, SVMXC__Proforma_Invoice__c> oldMap = (Map<Id, SVMXC__Proforma_Invoice__c>) Trigger.oldMap;
        SMAX_PS_InvoiceManager.releaseInvoice(newList, oldMap);
        SMAX_PS_InvoiceManager.rejectDMR(newList, oldMap);
        SMAX_PS_InvoiceManager.cancelInvoice(newList, oldMap);
        SMAX_PS_InvoiceManager.reviewDMRAdjustments(newList, oldMap);
        SMAX_PS_InvoiceManager.updateRejectionReason(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}
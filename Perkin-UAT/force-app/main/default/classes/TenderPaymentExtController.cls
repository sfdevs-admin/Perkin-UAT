public with sharing class TenderPaymentExtController {
    private Id tenderPaymentId;
    
    public TenderPaymentExtController(ApexPages.StandardController stdController) {
        tenderPaymentId = stdController.getId();
    }
    
    public PageReference onSubmit() {
        if (tenderPaymentId != null) {
            SBAA.ApprovalAPI.submit(tenderPaymentId, SBAA__Approval__c.BD_Tender_Payment__c);
        }
        return new PageReference('/' + tenderPaymentId);
    }
    
    public PageReference onRecall() {
        if (tenderPaymentId != null) {
            SBAA.ApprovalAPI.recall(tenderPaymentId, SBAA__Approval__c.BD_Tender_Payment__c);
        }
        return new PageReference('/' + tenderPaymentId);
    }
}
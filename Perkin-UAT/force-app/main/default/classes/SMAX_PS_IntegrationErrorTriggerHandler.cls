/*
 *  Trigger Handler for IntegrationError [SMAX_PS_IntegrationError__c]
 *  2017-09-28      Veerendra Moodbidri       Initial creation, for IntegrationError Integration.
 *  2017-12-04      Frank VanLoon             Added related element method.
 */

public with sharing class SMAX_PS_IntegrationErrorTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public SMAX_PS_IntegrationErrorTriggerHandler() {
    }

    public void beforeInsert()
    {
        List<SMAX_PS_IntegrationError__c> newList = Trigger.new;
        SMAX_PS_IntegrationErrorManager.updateRelatedElement(newList);
    }
    public void afterInsert()
    {
        List<SMAX_PS_IntegrationError__c> newList = Trigger.new;
        SMAX_PS_IntegrationErrorManager.updateIntegrationStatusInWorkDetail(newList);
        SMAX_PS_IntegrationErrorManager.updateWorkOrderLastError(newList);
        SMAX_PS_IntegrationErrorManager.updatePartsOrderErrorStatus(newList);
//        SMAX_PS_IntegrationErrorManager.updateStockTransferErrorStatus(newList);
        SMAX_PS_IntegrationErrorManager.unlockDMR(newList);
    }
    public void beforeUpdate() {}
    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}
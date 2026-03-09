/*
 *  Trigger Handler for Product Stock [SVMXC__Product_Stock__c]
 *  2017-09-07      Veerendra Moodbidri       Initial creation, for Product Stock Integration.
 *  2022-10-24      Bolt Data - E. Ross       Modifications for Polaris Project.
 */
public with sharing class SMAX_PS_ProductStockTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public SMAX_PS_ProductStockTriggerHandler() {
    }

    public void beforeInsert() {
        List<SVMXC__Product_Stock__c> newPstockList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newPstockList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        List<SVMXC__Product_Stock__c> newPstockList = Trigger.new;
        Map<Id, SVMXC__Product_Stock__c> oldPstockMap = (Map<Id, SVMXC__Product_Stock__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newPstockList, oldPstockMap);
    }
    public void afterUpdate()
    {
        List<SVMXC__Product_Stock__c> newPstockList = Trigger.new;
        Map<Id, SVMXC__Product_Stock__c> oldPstockMap = (Map<Id, SVMXC__Product_Stock__c>) Trigger.oldMap;
        SMAX_PS_InventoryManager.afterUpdateComplete(newPstockList, oldPstockMap);
    }
    
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}
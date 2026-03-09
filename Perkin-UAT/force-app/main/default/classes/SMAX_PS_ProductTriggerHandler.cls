/**
 *  Apex Handler for Product [Product2]
 *  2017-08-03      Veerendra
 *  Client          PerkinElmer
 **/
public with sharing class SMAX_PS_ProductTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{

    public SMAX_PS_ProductTriggerHandler() {
    }

    public void afterUpdate()
    {
        List<Product2> newProdList = Trigger.new;
        Map<Id, Product2> oldProdMap = (Map<Id, Product2>) Trigger.oldMap;
        SMAX_PS_ProductManager.updateDeletedFlag(newProdList, oldProdMap);            
    }
        
    public void afterDelete()
    {
        List<Product2> oldProdList = Trigger.old;
        SMAX_PS_ProductManager.deleteProductChildRecords(oldProdList);            
    }

    public void beforeUpdate() {}
    public void beforeInsert() {}
    public void afterInsert() {}
    public void beforeDelete() {}
    public void afterUndelete() {}

}
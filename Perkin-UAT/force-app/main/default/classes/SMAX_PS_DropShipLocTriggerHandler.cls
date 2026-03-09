/*
 *  Trigger Handler for Drop Ship Location [SMAX_PS_Drop_Ship_Locations__c]
 *  2022-11-14      Bolt Data - E. Ross      Initial creation, for Polaris Project.
 */
public with sharing class SMAX_PS_DropShipLocTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_DropShipLocTriggerHandler() {}

    public void beforeInsert() {
        
        List<SMAX_PS_Drop_Ship_Locations__c> newList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updateDropShipLocObject(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<SMAX_PS_Drop_Ship_Locations__c> newList = Trigger.new;
        Map<Id, SMAX_PS_Drop_Ship_Locations__c> oldMap = (Map<Id, SMAX_PS_Drop_Ship_Locations__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateDropShipLocObject(newList, oldMap);
    }
    public void afterUpdate(){}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {} 
}
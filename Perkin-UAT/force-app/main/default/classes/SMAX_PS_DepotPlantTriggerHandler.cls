/*
 *  Trigger Handler for Depot Plant [SMAX_PS_Depot_Plant__c]
 *  2022-10-24      Bolt Data - E. Ross      Initial creation, for Polaris Project.
 */
public with sharing class SMAX_PS_DepotPlantTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{

    public SMAX_PS_DepotPlantTriggerHandler() {}

    public void beforeInsert() {
        
        List<SMAX_PS_Depot_Plant__c> newList = Trigger.new;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<SMAX_PS_Depot_Plant__c> newList = Trigger.new;
        Map<Id, SMAX_PS_Depot_Plant__c> oldMap = (Map<Id, SMAX_PS_Depot_Plant__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
    }
    public void afterUpdate(){}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {} 
}
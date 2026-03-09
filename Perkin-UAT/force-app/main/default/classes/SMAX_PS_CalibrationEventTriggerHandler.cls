/*
 *  Trigger Handler for Calibration Event [Calibration_Event__c]
 *  2022-10-24      Bolt Data - E. Ross      Initial creation, for Polaris Project.
 */
public with sharing class SMAX_PS_CalibrationEventTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_CalibrationEventTriggerHandler() {}

    public void beforeInsert() {
        
        List<Calibration_Event__c> newList = Trigger.new;
        Map<Id, Calibration_Event__c> oldMap = (Map<Id, Calibration_Event__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateCalibrationEventObject(newList, oldMap);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        
        List<Calibration_Event__c> newList = Trigger.new;
        Map<Id, Calibration_Event__c> oldMap = (Map<Id, Calibration_Event__c>) Trigger.oldMap;
        SMAX_PS_OwnedByCompanyManager.updateCalibrationEventObject(newList, oldMap);
    }
    public void afterUpdate(){}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {} 
}
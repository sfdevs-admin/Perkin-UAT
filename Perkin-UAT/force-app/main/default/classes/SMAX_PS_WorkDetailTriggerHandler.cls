public with sharing class SMAX_PS_WorkDetailTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    
    public SMAX_PS_WorkDetailTriggerHandler() {
    }
    
    public void beforeInsert() 
    {
        List<SVMXC__Service_Order_Line__c> newList = Trigger.new;
        // SVMXCFG-329 - Copy Currency Code from WO
        SMAX_PS_WorkDetailManager.copyRelatedData(newList);
        SMAX_PS_WorkDetailManager.updateTechOnDebriefLine(newList, null);
        SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(newList, null);
        SMAX_PS_WorkDetailManager.updateFaultCodes(newList, null);
        SMAX_PS_WorkDetailManager.updateFieldValues(newList, null);
        // ITSFDC-509 Lookup Product Plant (and related fields)
        SMAX_PS_WorkDetailManager.lookupProductPlant(newList, null);
        // 08/04/2023 ITSVMX-1227 Update Work Order Plant and Work Center from either Technician or Additional Work Center
        SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(newList, null);
    }
    
    public void afterInsert() 
    {
        List<SVMXC__Service_Order_Line__c> newList = Trigger.new;
        SMAX_PS_WorkDetailManager.consumeRemoteHours(newList, null);
        //ITSVMX-705 Copy HSN Code for India Region
        SMAX_PS_WorkDetailManager.addsummaryAfter(newList, null);
        // 11/16/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_Kit_Parts.explodeWorkDetailKitParts(newList, null);
        
    }

    public void beforeUpdate() 
    {
        List<SVMXC__Service_Order_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__Service_Order_Line__c> oldMap = (Map<Id, SVMXC__Service_Order_Line__c>) Trigger.oldMap;
        SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(newList, oldMap);
        SMAX_PS_WorkDetailManager.updateFaultCodes(newList, oldMap);
        SMAX_PS_WorkDetailManager.updateDetailLineAndIntegrationStatus(newList, oldMap);
        SMAX_PS_WorkDetailManager.toggleIntegrationStatus(newList, oldMap);
        SMAX_PS_WorkDetailManager.updateFieldValues(newList, oldMap);
        // SVMXINT-528-530 WO One-Click Complete - Swapping out calls..
            SMAX_PS_WorkDetailManager.cancelLines(newList, oldMap);
        // ITSFDC-509 Lookup Product Plant (and related fields)
        SMAX_PS_WorkDetailManager.lookupProductPlant(newList, oldMap);
        //SVMXCFG-690 copy first 40 chars of Work Description to Work Summary
         SMAX_PS_WorkDetailManager.addWorkSummary(newList);
        // 08/04/2023 ITSVMX-1227 Update Work Order Plant and Work Center from either Technician or Additional Work Center
        SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(newList, oldMap);
    }

    public void afterUpdate() 
    {
        List<SVMXC__Service_Order_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__Service_Order_Line__c> oldMap = (Map<Id, SVMXC__Service_Order_Line__c>) Trigger.oldMap;
        // SVMXINT-528-530 WO One-Click Complete - Swapping out calls..
            // [SVMXINT-489] Moved to after update to prevent timing issue..
            //SMAX_PS_WorkDetailManager.createWorkOrderEvent(newList, oldMap);
        // SVMXINT-502: Create Int Errors to detect duplicate processing
        SMAX_PS_WorkDetailManager.logDuplicateErrors(newList, oldMap);
        SMAX_PS_WorkDetailManager.consumeRemoteHours(newList, oldMap);
        // 11/16/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_Kit_Parts.explodeWorkDetailKitParts(newList, oldMap);
        // 06/20/2022 ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
        SMAX_PS_WorkDetailManager.deleteWorkDetailRecords(newList, oldMap);
    }

    public void beforeDelete() {}
    public void afterDelete()
    {
        List<SVMXC__Service_Order_Line__c> oldList = Trigger.old;
        SMAX_PS_WorkDetailManager.consumeRemoteHours(oldList, null);
    }
    public void afterUndelete()
    {
        List<SVMXC__Service_Order_Line__c> newList = Trigger.new;
        SMAX_PS_WorkDetailManager.consumeRemoteHours(newList, null);
    }
}
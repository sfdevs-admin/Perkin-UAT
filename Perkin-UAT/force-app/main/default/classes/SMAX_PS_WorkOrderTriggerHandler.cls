/*
 *  Trigger Handler for Work Order [SVMXC__Service_Order__c]
 *
 * Updates:
 *  2022-10-24      Bolt Data - E. Ross      Modifications for Polaris Project.
 *  2023-08-10      Tony                     ITSVMX-1227 WO Debrief ability to debrief from common shared locations
 */
public with sharing class SMAX_PS_WorkOrderTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    public SMAX_PS_WorkOrderTriggerHandler() { 
    }
    public void beforeInsert()
    {
        List<SVMXC__Service_Order__c> newList = Trigger.new;

        // Added for Integration support.. Dec 2017
        SMAX_PS_WorkOrderManager.preventInvalidWorkOrders(newList);
        // Added for Integration support.. Dec 2017
        SMAX_PS_WorkOrderManager.copyRelatedData(newList, null);
        // SVMXINT-498: Scheduled Date logic for WO Load
        SMAX_PS_WorkOrderManager.syncScheduledDate(newList, null);
        // SVMXINT-534: Derive Quote Currency and Accepted Date from WO
        SMAX_PS_WorkOrderManager.copyQuoteCurrencyDate(newList, null);      
        // Added by Frank - Jan 10 2018
        SMAX_PS_WorkOrderManager.updateMappedValues(newList, null);
        // Refactored by Frank, for Complaints.. Mar 2018
        SMAX_PS_WorkOrderComplaints.updateManualComplaint(newList, null);
        // Added by Frank - Dec 22 2017
        SMAX_PS_WorkOrderComplaints.healthSafetyCheck(newList);
        //Added by Bill Convis - Oct 5 2017
        SMAX_PS_AutoEntitlement.performAutoEntitlementCheck(newList, null);
        // Added by Frank - WO Load Entitlement - Apr 3 2018
        SMAX_PS_AutoEntitlement.completeEntitlement(newList, null);
        SMAX_PS_AutoEntitlement.syncIsBillable(newList, null);
        // SVMXCFG-1000 - Service Estimate Assignment - Feb 21 2019
        SMAX_PS_AutoAssignment.autoAssignServiceEstimates(newList, null);
        // SVMXCFG-1109 - Reordered to AFTER autoAssignServiceEstimates
        SMAX_PS_WorkOrderManager.updateTechnicianDetails(newList, null);
        // 1/8/21 tony ITSVMX-225 - Standard Job Time Automation
        SMAX_PS_WorkOrderStandardJobTime.updateStandardJobTime(newList, null);
        //SMAX_PS_WorkOrderManager.updateStandardJobTime(newList, null);
        // 12/11/2021 Tony ITSVMX-607 Auto-entitle RWO, build in reporting capacity on SLA terms in connection to RWO
        SMAX_PS_WorkOrderManager.updatePotentialEntitlement(newList, null);
        // 2022-04-19 Tony ITSVMX-562 Modify the replenishment parts ordering process
        SMAX_PS_WorkOrderManager.refurbishedPartsAllowed(newList, null);
        // 2022-10-27 Eugene Ross ITSVMX-1028 Polaris Project
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
        // Added by Frank - Sep 27 2018 [SVMXCFG-777]
        // Moved to last so that OwnedByCompany is populated first [ITSVMX-1218]
        SMAX_PS_WorkOrderManager.lookupTranslation(newList, null);
        // 2023-08-10 ITSVMX-1227 WO Debrief ability to debrief from common shared locations
        SMAX_PS_WorkOrderManager.updateWorkOrderDefaultConsumedFromLocation(newList, null);
    }

    public void afterInsert()
    {
        List<SVMXC__Service_Order__c> newList = Trigger.new;

        // ITSFDC-1099 added by Tony 5/14/2020
        SMAX_PS_AutoAssignment.createEventsAfterInsert(newList);

        // Added by Veerendra - 22 Sep 2017
        SMAX_PS_WorkOrderManager.createWorkOrderEvents(newList, null);

        // ITSFDC-507 Perten - Extended Warranty on Instrument Parts
        SMAX_PS_ExtendedWarranty.createCoverage(newList);

        // ITSFDC-509 Auto-Create RMA for Depot WOs
        // ITSVMX-200 Moved to InventoryManager
        SMAX_PS_InventoryManager.autoCreateRMA(newList, null);

        // ITSFDC-1161 (old SVMXCFG-1108) Metrics & KPI
        SMAX_PS_WorkOrderMetrics.countAssignments(newList, null);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnRemote(newList, null);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnTECO(newList, null);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnCallback(newList);

        // 10/4/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_WorkOrderManager.addSuggestedParts(newList, null);
    }

    public void beforeUpdate()
    {
        List<SVMXC__Service_Order__c> newList = Trigger.new;
        Map<Id, SVMXC__Service_Order__c> oldMap = (Map<Id, SVMXC__Service_Order__c>) Trigger.oldMap;

        // ITSFDC-1240 Depot WOs On Hold-Credit status issue
        // added by Tony on April 14 2020
        // 5/7/2020 moved to beginning of method as we need to stop ownership changes from happening
        SMAX_PS_WorkOrderOnHold.validateOwnerChange(newList, oldMap);

        // ITSFDC-1047 - Auto-Map the Depot Record Type when "Escalate to Depot"
        //SMAX_PS_WorkOrderManager.escalateToDepot(newList, oldMap);

        // Added by Frank - Aug 9 2018 [SVMXCFG-682]
        SMAX_PS_WorkOrderManager.copyRelatedData(newList, oldMap);
        // Added by Frank - Jan 10 2018
        SMAX_PS_WorkOrderManager.updateMappedValues(newList, oldMap);
        // ITSFDC-507 Extended Warranty and other Roll-ups
        SMAX_PS_WorkOrderManager.updateRollups(newList, oldMap);
        // Refactored by Frank, for Complaints.. Mar 2018
        SMAX_PS_WorkOrderComplaints.updateManualComplaint(newList, oldMap);
        // Added by Veerendra - 22 Sep 2017
        SMAX_PS_WorkOrderManager.updateWorkOrderStatus(newList, oldMap);

        /* ENTITLEMENT LOGIC */
        //Added by Bill Convis - Oct 5 2017
        SMAX_PS_AutoEntitlement.performAutoEntitlementCheck(newList, oldMap);
        // Added by Frank - WO Load Entitlement - Apr 3 2018
        SMAX_PS_AutoEntitlement.completeEntitlement(newList, oldMap);
        SMAX_PS_AutoEntitlement.syncIsBillable(newList, oldMap);

        // ITSFDC-509 Auto-Create RMA for Depot WOs
        // ITSFDC-1047 Auto-Submit RMA for Depot (renamed and moved from after to before)
        //SMAX_PS_WorkOrderManager.autoSubmitRMA(newList, oldMap);

        /* ASSIGNMENT LOGIC */
        // SVMXCFG-1103: Estimate Conversions
        // ITSFDC-1099: Remove SVMXCFG-1103 code as it is not approved
        //SMAX_PS_AutoAssignment.convertedFromEstimate(newList, oldMap);

        // SVMXINT-493: Sync the Scheduled Date from the Scheduled Datetime
        SMAX_PS_WorkOrderManager.syncScheduledDate(newList, oldMap);
        
        // SVMXINT-534: Derive Quote Currency and Accepted Date from WO
        SMAX_PS_WorkOrderManager.copyQuoteCurrencyDate(newList, null);  
                
        // 7/22/21 Tony - Refactoring this from beforeUpdate to afterUpdate as it is causing problems with ServiceMax managed package code
//      //Added by Frank - Dev 7 2017
//      SMAX_PS_AutoAssignment.confirmScheduling(newList, oldMap);

        // SVMXCFG-837 Unassign change back to "Open"
        SMAX_PS_WorkOrderManager.unassignWO(newList, oldMap);
        // Added by Frank - Nov 28 2017
        SMAX_PS_AutoAssignment.performAutoAssignmentCheck(newList, oldMap);
        // SVMXCFG-1000 - Service Estimate Assignment - Feb 21 2019
        SMAX_PS_AutoAssignment.autoAssignServiceEstimates(newList, oldMap);
        // ITSFDC-509 Auto-Assign Depot Owner Changes
        SMAX_PS_AutoAssignment.autoAssignOwnerChanges(newList, oldMap);
        // SVMXCFG-1109 - Reordered to AFTER autoAssignServiceEstimates
        SMAX_PS_WorkOrderManager.updateTechnicianDetails(newList, oldMap);
        // SVMXCFG-682 Added by Frank - Aug 21 2018
        SMAX_PS_AutoAssignment.finishAssignment(newList, oldMap);

        /* COMPLETE & EVENT LOGIC */
        // Added by Frank, for Regulatory Questions - Jan 16 2018
        SMAX_PS_WorkOrderComplaints.updateComplaintDetails(newList, oldMap);
        // Added by Frank, for Fault Codes - Dec 29 2017
        SMAX_PS_WorkOrderComplaints.validateComplaintAnswers(newList, oldMap);
        // SVMXINT-528-530 WO One-Click Complete - Swapping out calls..
        //SMAX_PS_WorkOrderManager.updateWorkDetailLineStatus(newList, oldMap);
        //SMAX_PS_WorkOrderManager.addWorkCompleteError(newList, oldMap);
        SMAX_PS_WorkOrderDebriefManager.submitCompleteAll(newList, oldMap);

        // SVMXCFG-603: Cancel Work Order
        SMAX_PS_WorkOrderDebriefManager.cancelWorkOrders(newList, oldMap);

        // Added by Frank - Dec 13 2017
        SMAX_PS_WorkOrderManager.forceWorkOrderEvents(newList);

        // ITSFDC-1240 Depot WOs On Hold-Credit status issue
        // added by Tony on April 14 2020
        //SMAX_PS_WorkOrderOnHold.validateOwnerChange(newList, oldMap);

        // 1/8/21 tony ITSVMX-225 - Standard Job Time Automation
        SMAX_PS_WorkOrderStandardJobTime.updateStandardJobTime(newList, oldMap);
        //SMAX_PS_WorkOrderManager.updateStandardJobTime(newList, null);
        // 1/13/21 tony ITSVMX-233 - TAC: RWO/WO - need a field Escalated By to track who converted RWO to WO
        SMAX_PS_WorkOrderManager.updateEscalatedBy(newList, oldMap);

        // 5/21/21 ITSVMX-461 - Trigger to cancel RMA when Depot Repair Work Order is Canceled
        SMAX_PS_WorkOrderManager.cancelDepotRepairRMA(newList, oldMap);

        // 5/26/21 ITSVMX-443 Create WO trigger to update Parent work order to Assigned when Child work order changes to Field Service record type
        SMAX_PS_WorkOrderManager.assignTechToParentWO(newList, oldMap);

        // 10/21/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_WorkOrderManager.checkStockForSuggestedParts(newList, oldMap);

        // 2022-04-19 Tony ITSVMX-562 Modify the replenishment parts ordering process
        SMAX_PS_WorkOrderManager.refurbishedPartsAllowed(newList, oldMap);
        
        // 2022-10-27 Eugene Ross ITSVMX-1028 Polaris Project
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);

        // Added by Frank - Sep 27 2018 [SVMXCFG-777]
        // Moved to last so that OwnedByCompany is populated first [ITSVMX-1218]
        SMAX_PS_WorkOrderManager.lookupTranslation(newList, oldMap);

        // 2023-08-10 ITSVMX-1227 WO Debrief ability to debrief from common shared locations
        SMAX_PS_WorkOrderManager.updateWorkOrderDefaultConsumedFromLocation(newList, oldMap);
    }
    
    public void afterUpdate()
    {
        List<SVMXC__Service_Order__c> newList = Trigger.new;
        Map<Id, SVMXC__Service_Order__c> oldMap = (Map<Id, SVMXC__Service_Order__c>) Trigger.oldMap;

        // Added by Veerendra - 22 Sep 2017
        SMAX_PS_WorkOrderManager.createWorkOrderEvents(newList, oldMap);
        // SVMXINT-502: Create Int Errors to detect duplicate processing
        SMAX_PS_WorkOrderManager.logDuplicateErrors(newList, oldMap);
        // ITSFDC-509 Auto-Create RMA for Depot WOs
        // ITSVMX-200 Moved to InventoryManager
        SMAX_PS_InventoryManager.autoCreateRMA(newList, null);

        // ITSFDC-1161 (old SVMXCFG-1108) Metrics & KPI
        SMAX_PS_WorkOrderMetrics.countAssignments(newList, oldMap);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnRemote(newList, oldMap);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnTECO(newList, oldMap);
        SMAX_PS_WorkOrderMetrics.calculateMetricsOnInvoicing(newList, oldMap);
        // ITSFDC-3222 Delete Metrics when WO is Canceled
        SMAX_PS_WorkOrderMetrics.deleteMetricsOnCanceled(newList);

        // ITSVMX-134 10/2/20 tony: Remove calendar events when a technician rejects the assignment
        SMAX_PS_WorkOrderManager.removeRejectedCalendarEvents(newList, oldMap);

        // 7/22/21 Tony - Refactoring this from beforeUpdate to afterUpdate as it is causing problems with ServiceMax managed package code
        //Added by Frank - Dev 7 2017
        SMAX_PS_AutoAssignment.confirmScheduling(newList, oldMap);

        // 7/30/21 ITSVMX-507 Perten 2.0 Phase 2 Escalate from Depot to regular WO
        SMAX_PS_WorkOrderManager.cancelRMAsOnFieldServiceWOs(newList, oldMap);

        // 10/4/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_WorkOrderManager.addSuggestedParts(newList, oldMap);
        
        //18/02/26 Send Service Report when WO is Closed.
        SMAX_PS_WorkOrderManager.sendServiceReportWhenWOClosed(newList, oldMap);
    }

    public void beforeDelete() {}
    public void afterDelete()
    {
        //List<SVMXC__Service_Order__c> oldList = Trigger.old;
    }

    public void afterUndelete()
    {
        //List<SVMXC__Service_Order__c> newList = Trigger.new;
    }
}
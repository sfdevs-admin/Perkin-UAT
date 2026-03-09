public with sharing class SMAX_PS_EventTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{
    public SMAX_PS_EventTriggerHandler() {
        
    }
    public void beforeInsert() 
    {
        List<Event> newList = Trigger.new;

        SMAX_PS_AutoAssignment.syncEventFields(newList);

        // 10/28/21 ITSVMX-606 Scheduled Duration Redesign
        SMAX_PS_EventManager.updateIsLongJob(newList, null);
        
        // 10/27/2022 Polaris project updates
        SMAX_PS_OwnedByCompanyManager.updateEventObject(newList, null);
    }

    public void afterInsert()
    {
        List<Event> newList = Trigger.new;

        //Timesheet Functionality
        SVMX_PS_TS_TimesheetUtils timesheetUtils = new SVMX_PS_TS_TimesheetUtils();
        timesheetUtils.handleEventsFromSalesforceEvents(newList, null, null, true, false, false);

        SMAX_PS_AutoAssignment.schedulingConfirm(newList, null);

        // ITSVMX-442 Create WO Trigger to Dispatch Parent and Child Together
        SMAX_PS_EventManager.dispatchParentFieldServiceWO(newList);
    }

    public void beforeUpdate() 
    {
        List<Event> newList = Trigger.new;
        Map<Id, Event> oldMap = (Map<Id, Event>) Trigger.oldMap;

        // SVMXCFG-820 Event Trigger Code Update and Batch Class to update event records
        // Rolling back the "updates" - Frank 20181106
        //SMAX_PS_AutoAssignment.syncEventFields(newList);

        // ITSMVX-688 2/9/2022 tony - Long Job Scheduling Enhancements.  Confirm Long Job Scheduling Events.
        SMAX_PS_EventManager.syncWorkOrderToConfirmedLJSEvents(newList, oldMap);
        
        // 10/27/2022 Polaris project updates
        SMAX_PS_OwnedByCompanyManager.updateEventObject(newList, oldMap);
    }

    public void afterUpdate()
    {
        List<Event> newList = Trigger.new;
        Map<Id, Event> oldMap = (Map<Id, Event>) Trigger.oldMap;
        List<Event> oldList = Trigger.old;

        //Timesheet Functionality
        SVMX_PS_TS_TimesheetUtils timesheetUtils = new SVMX_PS_TS_TimesheetUtils();
        timesheetUtils.handleEventsFromSalesforceEvents(newList, oldMap, oldList, false, true, false);

        SMAX_PS_AutoAssignment.schedulingConfirm(newList, oldMap);
        

    }

    public void beforeDelete() 
    {
        List<Event> newList = Trigger.new;
        Map<Id, Event> oldMap = (Map<Id, Event>) Trigger.oldMap;
        List<Event> oldList = Trigger.old;

        //Timesheet Functionality
        SVMX_PS_TS_TimesheetUtils timesheetUtils = new SVMX_PS_TS_TimesheetUtils();
        timesheetUtils.handleEventsFromSalesforceEvents(newList, oldMap, oldList, false, false, true);
    }
    public void afterDelete() 
    {
        List<Event> oldList = Trigger.old;
    }

    public void afterUndelete() 
    {
        List<Event> newList = Trigger.new;
    }   
}
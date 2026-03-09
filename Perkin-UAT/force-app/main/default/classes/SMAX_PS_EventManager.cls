/**
 * Created by frankvanloon on 2019-04-10.
 * Marking this as "without sharing" explicitly to work-around the (dis)ability of CRC users to delete Events
 * 11/9/21  tony - ITSVMX-606 Scheduled Duration Redesign -Added to get around a ServiceMax Managed Package code error when trying to delete events
 * 2/9/2022 tony - ITSMVX-688 Long Job Scheduling Enhancements.  Confirm Long Job Scheduling Events.
 */
public without sharing class SMAX_PS_EventManager
{

    public static void deleteEvents(Set<Id> whatIds)
    {
        System.debug('Deleting Events using deleteEvents: ' + whatIds);
        // SVMXCFG-1093 Delete Old Events when RE-assigned
        List<Event> oldEvents = [SELECT Id FROM Event WHERE WhatId IN :whatIds];
        if (!oldEvents.isEmpty())
        {
            delete oldEvents;
        }
    }

    // 11/30/20 tony - Added to allow deletion of a List of Events using "Without Sharing"
    public static void deleteEventsNoSharingRules(List<Event> events)
    {
        if (events.size() > 0)
        {
            System.debug('About to Delete Calendar Events:' + events);
            delete events;
        }
    }

    // 11/9/21 tony - ITSVMX-606 Scheduled Duration Redesign -Added to get around a ServiceMax Managed Package code
    // error when trying to delete events
    @Future
    public static void deleteEventsNoSharingRulesFuture(Set<Id> eventIds)
    {
        System.debug('Deleting Events using deleteEventsNoSharingRulesFuture: ' + eventIds);
        List<Event> events = [SELECT Id FROM Event WHERE Id IN :eventIds];
        if (!events.isEmpty())
        {
            delete events;
        }
    }

    /**
     * ITSVMX-442 Create WO Trigger to Dispatch Parent and Child Together
     * When a child field service work order is dispatched we need to also dispatch the parent work order
     * Note: Should be called by afterInsert event in trigger handler
     */
    public static void dispatchParentFieldServiceWO(List<Event> events) {

        System.debug('Entering SMAX_PS_EventManager.dispatchParentFieldServiceWO method');
        if (!SMAX_PS_Utility.isActive('Dispatch Parent Field Service WO', 'When a Child Field Service WO is Dispatched we also need to Dispatch the Parent WO.'))
            return;

        // Get the prefix for Work Orders
        schema.SObjectType sObjType = Schema.getGlobalDescribe().get('SVMXC__Service_Order__c');
        String objPrefix = sObjType.getDescribe().getKeyPrefix();
        System.debug('Work Order Prefix: ' + objPrefix);

        // If this is an Event for a Field Service Work Order get the Ids
        Set<Id> woIds = new Set<Id>();
        Map<Id, Event> woIdToEventMap = new Map<Id, Event>();
        for(Event event :events) {

            if (event.WhatId == null) continue; // if there is no WhatId skip this event

            String whatIdStr = Id.valueOf(event.WhatId);
            System.debug('whatIdStr: ' + whatIdStr);
            System.debug('event.SMAX_PS_Work_Order_Record_Type__c: ' + event.SMAX_PS_Work_Order_Record_Type__c);
            if (whatIdStr.startsWith(objPrefix)
                    && event.SMAX_PS_Work_Order_Record_Type__c == 'Field Service') {
                woIds.add(event.WhatId);
                woIdToEventMap.put(event.WhatId, event);
            }
        }
        System.debug('Field Service WOs found: ' + woIds);

        if (woIds.size() == 0) return;

        // Query the Work Orders that have a parent
        // ITSVMX-606: Changing Scheduled Duration field
        List<SVMXC__Service_Order__c> workOrders = [
                SELECT  Id, SVMXC__Group_Member__c, SVMXC__Service_Group__c, SVMXC__Scheduled_Date_Time__c,
                        SVMXC__Scheduled_Date__c, SMAX_PS_Tech_Expertise__c, OwnerId, SVMXC__Order_Status__c, SVMXC__SM_Estimated_Duration__c,
                        BD_Create_Event_After_Insert__c, SMAX_PS_Scheduled_Duration_Hours__c, SVMXC__Group_Member__r.SVMXC__Service_Group__c,
                        SVMXC__Group_Member__r.SVMXC__Salesforce_User__c, SVMX_PS_Parent_Work_Order__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :woIds
                AND SVMX_PS_Parent_Work_Order__c != NULL
        ];
        System.debug('workOrders with parents: ' + workOrders);

        // Get Parent Work Order Ids
        Set<Id> parentWoIds = new Set<Id>();
        for (SVMXC__Service_Order__c wo :workOrders) {
            parentWoIds.add(wo.SVMX_PS_Parent_Work_Order__c);
        }
        System.debug('parentWoIds: ' + parentWoIds);

        if (parentWoIds.size() == 0) return;

        // Query Parent Work Orders
        // ITSVMX-606: Changing Scheduled Duration field
        List<SVMXC__Service_Order__c> parentWorkOrders = [
                SELECT  Id, SVMXC__Group_Member__c, SVMXC__Service_Group__c, SVMXC__Scheduled_Date_Time__c,
                        SVMXC__Scheduled_Date__c, SMAX_PS_Tech_Expertise__c, OwnerId, SVMXC__Order_Status__c, SVMXC__SM_Estimated_Duration__c,
                        BD_Create_Event_After_Insert__c, SMAX_PS_Scheduled_Duration_Hours__c, SVMXC__Group_Member__r.SVMXC__Service_Group__c,
                        SVMXC__Group_Member__r.SVMXC__Salesforce_User__c, SVMX_PS_Parent_Work_Order__c,
                        Name, SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMX_PS_Problem_Summary__c,RecordTypeId
                FROM SVMXC__Service_Order__c
                WHERE Id IN :parentWoIds
        ];
        System.debug('parentWorkOrders: ' + parentWorkOrders.size() + ' - ' + parentWorkOrders);

        // Get the Technician Ids for the Child Work Orders
        Set<Id> techIds = new Set<Id>();
        for (SVMXC__Service_Order__c wo :workOrders) {
            techIds.add(wo.SVMXC__Group_Member__c);
        }

        // Query the Technicians for the Child Work Orders and create a map
        Map<Id, SVMXC__Service_Group_Members__c> techsMap = new Map<Id, SVMXC__Service_Group_Members__c>([
                SELECT Id, SVMXC__Salesforce_User__c, SVMXC__Service_Group__c
                FROM SVMXC__Service_Group_Members__c
                WHERE Id IN :techIds
        ]);
        System.debug('techsMap: ' + techsMap);

        // Dispatch the Parent work orders
        List<Event> eventList = new List<Event>();
        for (SVMXC__Service_Order__c parentWO :parentWorkOrders) {
            for (SVMXC__Service_Order__c wo :workOrders) {
                if (wo.SVMX_PS_Parent_Work_Order__c == parentWO.Id) {
                    Event childEvent = woIdToEventMap.get(wo.Id);
                    Event newEvent = SMAX_PS_AutoAssignment.assignTechnician(parentWO, techsMap.get(wo.SVMXC__Group_Member__c), wo.SVMXC__Scheduled_Date__c, null);
                    newEvent.StartDateTime = childEvent.StartDateTime;
                    newEvent.SVMXC__Driving_Time__c = childEvent.SVMXC__Driving_Time__c;
                    newEvent.SVMXC__Driving_Time_Home__c = childEvent.SVMXC__Driving_Time_Home__c;
                    newEvent.DurationInMinutes = childEvent.DurationInMinutes;
                    newEvent.ActivityDateTime = childEvent.ActivityDateTime;
                    newEvent.EndDateTime = childEvent.EndDateTime;
                    parentWO.SVMXC__Scheduled_Date_Time__c = childEvent.StartDateTime?.addMinutes((Integer)childEvent.SVMXC__Driving_Time__c);
                    parentWO.SVMXC__Scheduled_Date__c = wo.SVMXC__Scheduled_Date__c;
                    parentWO.SVMX_PS_Is_Parent__c = false;
                    eventList.add(newEvent);
                }
            }
        }
        System.debug('Dispatching eventList: ' + eventList.size() + ' - ' + eventList);
        insert eventList;

        System.debug('Updating Parent WOs: ' + parentWorkOrders);
        update parentWorkOrders;

        System.debug('Exiting SMAX_PS_EventManager.dispatchParentFieldServiceWO method');
    }

    /**
     * 10/28/21 ITSVMX-606 Scheduled Duration Redesign
     * Before an Event is created update the SMAX_PS_Is_Long_Job__c value from the Work Order
     * Note: Should be called by beforeInsert event in trigger handler
     */
    public static void updateIsLongJob(List<Event> newList, Map<Id, Event> oldMap) {

        System.debug('Entering SMAX_PS_EventManager.updateIsLongJob method');
        if (!SMAX_PS_Utility.isActive('Update SMAX_PS_Is_Long_Job__c on Event', 'When an event is created update the SMAX_PS_Is_Long_Job__c from the WO.'))
            return;

        // Get the prefix for Work Orders
        schema.SObjectType sObjType = Schema.getGlobalDescribe().get('SVMXC__Service_Order__c');
        String objPrefix = sObjType.getDescribe().getKeyPrefix();
        System.debug('Work Order Prefix: ' + objPrefix);

        // If this is an Event for a Work Order get the Ids
        Set<Id> woIds = new Set<Id>();
        Set<Event> woEvents = new Set<Event>();
        for(Event event :newList) {

            if (event.WhatId == null) continue; // if there is no WhatId skip this event

            String whatIdStr = Id.valueOf(event.WhatId);
            System.debug('whatIdStr: ' + whatIdStr);
            if (whatIdStr.startsWith(objPrefix)) {
                woIds.add(event.WhatId);
                woEvents.add(event);
            }
        }
        System.debug('WOs found: ' + woIds);

        if (woIds.isEmpty()) return;

        // Query the Work Orders to see if they have the Is Long Job value of TRUE
        Map<Id, SVMXC__Service_Order__c> workOrdersMap = new Map<Id, SVMXC__Service_Order__c>([
                SELECT  Id, SVMX_PS_Is_Long_Job__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :woIds
                AND SVMX_PS_Is_Long_Job__c = TRUE
        ]);
        System.debug('workOrders with Is Long Job TRUE: ' + workOrdersMap);

        // Update the SMAX_PS_Is_Long_Job__c to TRUE on the events for these WOs
        for (Event event :woEvents) {
            if (workOrdersMap.get(event.WhatId)?.SVMX_PS_Is_Long_Job__c == true) {
                event.SMAX_PS_Is_Long_Job__c = true;
            }
        }
    }

    // ITSMVX-688 2/9/2022 tony - Long Job Scheduling Enhancements.  Confirm Long Job Scheduling Events.
    // When an Event is changed that is associated to a Work Order and is flagged as a Long Job Scheduled event
    // we update the Work Order with the latest Start Date and Start Date Time from all the LSJ events associated
    // to the Work Order.
    // NOTE: This should be called on the Event Before Update trigger
    public static void syncWorkOrderToConfirmedLJSEvents(List<Event> eventList,  Map<Id, Event> oldMap) {

        if (!SMAX_PS_Utility.isActive('Event Confirm Long Job Events', 'Update the WO Scheduled Date and Scheduled Datetime from the first LJS Event.'))
            return;

        Set<Id> woIds = new Set<Id>();
        Set<Id> newEventIds = new Set<Id>();
        String objKeyPrefix  = SVMXC__Service_Order__c.SObjectType.getDescribe().getKeyPrefix();
        System.debug('Work Order Key Prefix: ' + objKeyPrefix);

        Map<Id, Datetime> woIdToStartDTMap = new Map<Id, Datetime>();

        for (Event event : eventList) {

            String whatIdStr = '' + event.WhatId;
            System.debug('Event WhatId: ' + whatIdStr);

            Event old = (oldMap == null) ? null : oldMap.get(event.Id);

            // If the first 3 characters of the Event WhatId is a Work Order Prefix then we add the Work Order Id to the list
            if (event.StartDateTime != old.StartDateTime && event.SMAX_PS_Is_Long_Job__c == true
                    && event.SMAX_PS_ConfirmLongJob__c == true && whatIdStr.startsWith(objKeyPrefix)) {

                woIds.add(event.WhatId);
                newEventIds.add(event.Id);

                Datetime startDateTime = woIdToStartDTMap.get(event.WhatId);
                if (startDateTime != null && event.StartDateTime < startDateTime) {

                        woIdToStartDTMap.put(event.WhatId, event.StartDateTime);
                }

                if (startDateTime == null) {

                    woIdToStartDTMap.put(event.WhatId, event.StartDateTime);
                }
            }
            event.SMAX_PS_ConfirmLongJob__c = false;
        }
        System.debug('Starting woIdToStartDTMap: ' + woIdToStartDTMap);

        System.debug('woIds: ' + woIds);
        if (woIds.isEmpty()) return;

        List<Event> woLjsEvents = [
                SELECT Id, StartDateTime, EndDateTime, WhatId
                FROM Event
                WHERE WhatId IN :woIds
                AND Id NOT IN :newEventIds
        ];
        System.debug('woLjsEvents: ' + woLjsEvents);


        for (Event event :woLjsEvents) {

            Datetime startDateTime = woIdToStartDTMap.get(event.WhatId);
            if (startDateTime != null && event.StartDateTime < startDateTime) {

                woIdToStartDTMap.put(event.WhatId, event.StartDateTime);
            }

            if (startDateTime == null) {

                woIdToStartDTMap.put(event.WhatId, event.StartDateTime);
            }
        }
        System.debug('woIdToStartDTMap: ' + woIdToStartDTMap);

        List<SVMXC__Service_Order__c> wos = [
                SELECT Id, SVMXC__Scheduled_Date__c, SVMXC__Scheduled_Date_Time__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :woIds
        ];

        for (SVMXC__Service_Order__c wo : wos) {

            System.debug('woIdToStartDTMap.get(wo.Id): ' + woIdToStartDTMap.get(wo.Id));
            wo.SVMXC__Scheduled_Date_Time__c = woIdToStartDTMap.get(wo.Id);
            wo.SVMXC__Scheduled_Date__c = wo.SVMXC__Scheduled_Date_Time__c?.date();
        }

        // Update the Work Orders that have an updated LJS Event
        System.debug('Updating Work Orders: ' + wos.size() + ' ' + wos);
        update wos;
    }

}
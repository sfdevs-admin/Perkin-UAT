/**
 * Created by tony on 12/1/20.
 */

@IsTest
private class SMAX_PS_EventManager_UT {

    @IsTest
    static void testDeleteEventsNoSharingRules() {

        // Create Test Data
        List<Event> events = new List<Event>{
                new Event(
                        DurationInMinutes = 60,
                        ActivityDateTime = Date.today()
                ),
                new Event(
                        DurationInMinutes = 120,
                        ActivityDateTime = Date.today()
                )
        };
        System.debug('Inserting Events: ' + events);
        insert events;

        // Added for code coverage
        update events;
        
        // Execute Test
        System.debug('Calling SMAX_PS_EventManager.deleteEventsNoSharingRules');
        SMAX_PS_EventManager.deleteEventsNoSharingRules(events);

        // Validate Results
        List<Event> results = [
                SELECT Id
                FROM Event
        ];
        //System.assertEquals(0, results.size());
    }

    // ITSVMX-442 Create WO Trigger to Dispatch Parent and Child Together
    @IsTest
    static void testDispatchParentFieldServiceWO() {

        // 4/1/2022 Removed this as we can now use the SMAX_PS_TestDataFactory.createTestUser() without the MIXED DML error
//        // 2/10/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
//        System.runAs(new User(Id = UserInfo.getUserId())) {

        // create test data
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Co.', 'ACC123', 'US');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLoc1', 'LOCEXT123', 'LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TST1234', acct, loc, 'MS123');
        User user = SMAX_PS_TestDataFactory.createTestUser('tst123');
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TeamName1', user, 'TechName1', 'US12', 'LOC456');
        SVMXC__Service_Order__c parentWo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        SVMXC__Service_Order__c childWo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        childWo.SVMX_PS_Parent_Work_Order__c = parentWo.Id;
        childWo.SVMXC__Group_Member__c = tech.Id;
        update childWo;

        // execute test - create dispatch event for child work order
        Test.startTest();
        Event event = SMAX_PS_AutoAssignment.assignTechnician(childWo, tech, System.today(), null);
        insert event;
        Test.stopTest();

        // verify that a dispatch event was created for the parent work order
        List<Event> parentEvents = [
                SELECT Id, WhatId, Subject, StartDateTime, SMAX_PS_Work_Order_Number__c
                FROM Event
                WHERE WhatId = :parentWo.Id
        ];
        System.debug('parentEvents: ' + parentEvents);
       // System.assertEquals(1, parentEvents.size(), 'There should be 1 Parent Event that was created');
//        }

    }

    // 10/28/21 ITSVMX-606 Scheduled Duration Redesign
    @IsTest
    static void testUpdateIsLongJob() {

        // 4/1/2022 Removed this as we can now use the SMAX_PS_TestDataFactory.createTestUser() without the MIXED DML error
//        // 2/10/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
//        System.runAs(new User(Id = UserInfo.getUserId())) {

        // create test data
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Co.', 'ACC123', 'US');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLoc1', 'LOCEXT123', 'LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TST1234', acct, loc, 'MS123');
        User user = SMAX_PS_TestDataFactory.createTestUser('tst123');
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TeamName1', user, 'TechName1', 'US12', 'LOC456');

        Set<Id> woIds = new Set<Id>();
        SVMXC__Service_Order__c wo1 = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo1.SVMXC__SM_Scheduling_Options__c = 'JDM and LJS Enabled';
        wo1.SVMXC__Group_Member__c = tech.Id;
        update wo1;
        woIds.add(wo1.Id);

        // execute test - create events
        Test.startTest();

        SVMXC__Service_Order__c wo2 = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo2.SVMXC__Group_Member__c = tech.Id;
        update wo2;
        woIds.add(wo2.Id);
        List<Event> events = new List<Event>();
        Event event1 = SMAX_PS_AutoAssignment.assignTechnician(wo1, tech, System.today(), null);
        events.add(event1);
        Event event2 = SMAX_PS_AutoAssignment.assignTechnician(wo1, tech, System.today() + 1, null);
        events.add(event2);
        Event event3 = SMAX_PS_AutoAssignment.assignTechnician(wo2, tech, System.today() + 1, null);
        events.add(event3);
        insert events;
        Test.stopTest();

        // verify that both events have the SMAX_PS_Is_Long_Job__c set to TRUE
        List<Event> ljsEvents = [
                SELECT Id, WhatId, Subject, StartDateTime, SMAX_PS_Work_Order_Number__c, SMAX_PS_Is_Long_Job__c
                FROM Event
                WHERE WhatId IN :woIds
                AND SMAX_PS_Is_Long_Job__c = TRUE
        ];
        System.debug('ljsEvents: ' + ljsEvents);
        //System.assertEquals(2, ljsEvents.size(), 'There should be 2 Events with SMAX_PS_Is_Long_Job__c = TRUE created');
//        }
    }

    // ITSMVX-688 2/10/2022 tony - Long Job Scheduling Enhancements.  Confirm Long Job Scheduling Events.
    @IsTest
    static void testSyncWorkOrderToConfirmedLJSEvents() {

        // 4/1/2022 Removed this as we can now use the SMAX_PS_TestDataFactory.createTestUser() without the MIXED DML error
//        // Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
//        System.runAs(new User(Id = UserInfo.getUserId())) {

        // create test data
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Co.', 'ACC123', 'US');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLoc1', 'LOCEXT123', 'LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TST1234', acct, loc, 'MS123');
        User user = SMAX_PS_TestDataFactory.createTestUser('tst123');
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TeamName1', user, 'TechName1', 'US12', 'LOC456');

        Set<Id> woIds = new Set<Id>();
        SVMXC__Service_Order__c wo1 = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo1.SVMXC__SM_Scheduling_Options__c = 'JDM and LJS Enabled';
        wo1.SVMXC__Group_Member__c = tech.Id;
        update wo1;
        woIds.add(wo1.Id);

        // execute test - create events
        Test.startTest();

        SVMXC__Service_Order__c wo2 = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo2.SVMXC__Group_Member__c = tech.Id;
        update wo2;
        woIds.add(wo2.Id);

        List<Event> events = new List<Event>();
        Date today = System.today();
        Event event1 = SMAX_PS_AutoAssignment.assignTechnician(wo1, tech, today, null);
        events.add(event1);
        Event event2 = SMAX_PS_AutoAssignment.assignTechnician(wo1, tech, today + 1, null);
        events.add(event2);
        Event event3 = SMAX_PS_AutoAssignment.assignTechnician(wo2, tech, today + 1, null);
        events.add(event3);
        insert events;

        Datetime newStartDateTime = Datetime.now() + 2.2;
        Datetime newEndDateTime = Datetime.now() + 2.3;
        event1.StartDateTime = newStartDateTime;
        event1.EndDateTime = newEndDateTime;
        event1.SMAX_PS_ConfirmLongJob__c = true;
        event2.SMAX_PS_ConfirmLongJob__c = true;
        update events;

        System.debug('AFTER event1.StartDateTime' + event1.StartDateTime);

        Test.stopTest();

        // verify that the Work Order is updated with latest Scheduled Date and Scheduled Date Time from the LJS Events
        List<SVMXC__Service_Order__c> ljsWorkOrder = [
                SELECT Id, SVMXC__Scheduled_Date__c, SVMXC__Scheduled_Date_Time__c
                FROM SVMXC__Service_Order__c
                WHERE Id = :event1.WhatId
        ];
        System.debug('ljsWorkOrder: ' + ljsWorkOrder);
        //System.assertEquals(event2.StartDateTime.date(), ljsWorkOrder[0].SVMXC__Scheduled_Date__c, 'Work Order Scheduled Date should have been updated with: ' + today + 1);
        //System.assertEquals(event2.StartDateTime, ljsWorkOrder[0].SVMXC__Scheduled_Date_Time__c, 'Work Order Scheduled Date Time should have been updated with: ' + today + 1);
//        }
    }
}
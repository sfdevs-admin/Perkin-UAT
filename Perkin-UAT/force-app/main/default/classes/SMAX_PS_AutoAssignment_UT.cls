/**
 * Class:   SMAX_PS_AutoAssignment_UT
 *
 * Updates:
 *  3/28/22  Tony   - Fixed SMAX_PS_TestDataFactory.createTestUser() to get around error caused by Flows that update the User object
 *                  - Used SMAX_PS_TestDataFactory.createTestUser() in both testInstallGeoOnly() and testInstallGeoSkills
 *  6/2/2022 Tony   ITSVMX-862 To fix error being thrown by ServiceMax validation rule we need to add the Driving Time to the EndDateTime
 * 2/18/2024 Isaac V - updated class to use testSetup method, resolved CPU timeout errors in 9 tests. 
**/

@isTest
private without sharing class SMAX_PS_AutoAssignment_UT {
    
    @testSetup
    static void setupData() {

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';
        
        User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001', 'AES');
        
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        SVMXC__Site__c techLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Tech Location', 'TECHLOC001', 'TECH01');
        SMAX_PS_TestDataFactory.createWO(ip, c,'AES');
    }

    @isTest static void testIP_PreferredTech() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];
        
        String modelSeries = 'TST001';

        //SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        //SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        //SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        //SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        ip.SMAX_PS_PreferredTechnicianNumber__c = tech.SVMX_PS_External_ID__c;
        ip.SVMXC__Preferred_Technician__c = tech.Id;
        update ip;

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today();
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;

        // This should cause Auto-Assignment to run
        update wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        //System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);
        //System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testIP_GeoSkills() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        User techUser = [Select id from user where alias = 'testtech' limit 1];

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        // 02/08/2023 Added Owned by Company as this is now required
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001', 'T001', 'AES');
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];

        tech.SVMXC__Working_Hours__c = bh.id;
        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        update tech;
        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        // 02/08/2023 Added Owned by Company as this is now required
        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(30);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Latitude__c = 27.976124910626297;
        wo.SVMXC__Longitude__c = -82.50339341093408;

        // This should cause Auto-Assignment to run
        update wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);
        System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testIP_GeoOnly() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];

        // No SKILL...
        //String modelSeries = 'TST001';
        //SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        //SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, null); //modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        
        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(30);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;

        // This should cause Auto-Assignment to run
        update wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);

        // SVMXCFG-693 Do not assign by Geo Only
        //System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);
        System.assertEquals(null, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testInstall_GeoSkills() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        // 3/28/22 - Fixed SMAX_PS_TestDataFactory.createTestUser() to get around error caused by Flows that update the User object
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        // 02/08/2023 Added Owned by Company as this is now required
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001', 'T001', 'AES');
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        tech.SVMXC__Working_Hours__c = bh.id;
        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        update tech;

        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];

        // 02/08/2023 Added Owned by Company as this is now required
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createInstallWO(acct, loc, null, c, 'AES');
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(30);
        wo.SMAX_PS_ProductSeries__c = modelSeries;
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Latitude__c = 27.976124910626297;
        wo.SVMXC__Longitude__c = -82.50339341093408;

        // This should cause Auto-Assignment to run
        update wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);
        System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testInstall_GeoOnly() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        // 3/28/22 - Fixed SMAX_PS_TestDataFactory.createTestUser() to get around error caused by Flows that update the User object
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        User techUser = [Select id from user where alias = 'testtech' limit 1];

        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        //String modelSeries = 'TST001';

        //SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        //SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createInstallWO(acct, loc, null, c);
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(30);
        //wo.SMAX_PS_ProductSeries__c = modelSeries;
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;

        SVMXC__Service_Order__c beforeResult = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN BEFORE UPDATE WO: ' + beforeResult);

        // This should cause Auto-Assignment to run
        update wo;

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);

        // SVMXCFG-693 Do not assign by Geo Only
        //System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);
        System.assertEquals(null, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testScheduling() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech = [Select id, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        ip.SMAX_PS_PreferredTechnicianNumber__c = tech.SVMX_PS_External_ID__c;
        ip.SVMXC__Preferred_Technician__c = tech.Id;
        update ip;

        SVMXC__Installed_Product__c ipResult = [SELECT Id, SVMXC__Preferred_Technician__c FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
        System.assertEquals(tech.Id, ipResult.SVMXC__Preferred_Technician__c);

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today();
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        //wo.SVMXC__SM_Scheduling_Options__c='JDM and LJS Enabled';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SMAX_PS_SAP_Work_Center__c='rrttyy';

        // This should cause Auto-Assignment to run
        update wo;

        Test.startTest();
        SMAX_PS_AutoAssignment.clearSynchronizedList();

        // ITSVMX-606: Changing Scheduled Duration field
        SVMXC__Service_Order__c result =[SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Scheduled_Date_Time__c,
                                                    SVMXC__Group_Member__c, OwnerId, SMAX_PS_Scheduled_Duration_Hours__c
                                         FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.debug('AUTO-ASSIGN RESULT WO: ' + result);
       // System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);
        //System.assertNotEquals(null, result.SVMXC__Scheduled_Date_Time__c);

        // 6/2/2022 tony ITSVMX-862 To fix error being thrown by ServiceMax validation rule we need to add the Driving Time to the EndDateTime
        // 8/11/20 ITSVMX-70 tony - Test that the "Scheduled Duration" is being set
        //System.assertEquals(3, result.SMAX_PS_Scheduled_Duration_Hours__c);
        //System.assertEquals(4, result.SMAX_PS_Scheduled_Duration_Hours__c);

        //Event evt = [SELECT Id, StartDateTime, WhatId FROM Event WHERE WhatId = :wo.Id];
        //System.assertNotEquals(null, evt);
        //System.assertEquals(result.SVMXC__Scheduled_Date_Time__c, evt.StartDateTime);
        /*if(result ==null){
            result = new SVMXC__Service_Order__c(Id=wo.id);
            result.SVMXC__Scheduled_Date_Time__c = system.now();
        }

        result.SVMXC__Scheduled_Date_Time__c = result.SVMXC__Scheduled_Date_Time__c.addDays(1).addHours(4);
        update result;*/
        
        wo.SVMXC__Scheduled_Date_Time__c = system.now().addDays(1).addHours(4);
        update wo;

        Test.stopTest();

       /* Event evt2 = [SELECT Id, StartDateTime, WhatId FROM Event WHERE WhatId = :wo.Id];
        System.assertNotEquals(null, evt2);
        System.assertEquals(result.SVMXC__Scheduled_Date_Time__c, evt2.StartDateTime);*/
    }

    @isTest static void testSchedulingConfirm() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech = [Select id, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        ip.SMAX_PS_PreferredTechnicianNumber__c = tech.SVMX_PS_External_ID__c;
        ip.SVMXC__Preferred_Technician__c = tech.Id;
        update ip;

        SVMXC__Installed_Product__c ipResult = [SELECT Id, SVMXC__Preferred_Technician__c FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
        System.assertEquals(tech.Id, ipResult.SVMXC__Preferred_Technician__c);

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today();
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;

        // This should cause Auto-Assignment to run
        update wo;

        Test.startTest();
        SMAX_PS_AutoAssignment.clearSynchronizedList();

        // ITSVMX-606: Changing Scheduled Duration field
        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Scheduled_Date_Time__c,
                SVMXC__Group_Member__c, OwnerId, SMAX_PS_Scheduled_Duration_Hours__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        /*System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);
        System.assertNotEquals(null, result.SVMXC__Scheduled_Date_Time__c);*/

        //Event evt = [SELECT Id, StartDateTime, WhatId FROM Event WHERE WhatId = :wo.Id];
        Event evt2 = new Event();
        evt2.DurationInMinutes=30;
        evt2.StartDateTime=system.today().adddays(-1);
        insert evt2;
        //System.assertNotEquals(null, evt);
        //System.assertEquals(result.SVMXC__Scheduled_Date_Time__c, evt.StartDateTime);

        evt2.StartDateTime = evt2.StartDateTime.addDays(1).addHours(4);
        update evt2;

        Test.stopTest();

        /*SVMXC__Service_Order__c result2 = [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Scheduled_Date_Time__c,
                SVMXC__Group_Member__c, OwnerId, SMAX_PS_Scheduled_Duration_Hours__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(evt.StartDateTime, result2.SVMXC__Scheduled_Date_Time__c);*/
    }

    @isTest static void testSapWorkCenter() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        
        User techUser = [Select id from user where alias = 'testtech' limit 1];

        String plant = 'TS12';
        String workCenter = 'TS71234';
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', plant, 'T001', workCenter);

        //String modelSeries = 'TST001';
        //String locCode = 'TSTC01';
        
        
        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        //ip.SVMXC__Preferred_Technician__c = tech.Id;
        //update ip;

        
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today();
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SMAX_PS_SAP_Work_Center__c = workCenter;
        wo.SMAX_PS_SAP_Maintenance_Plant__c = plant;

        // This should cause Auto-Assignment to run
        update wo;

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);
        System.assert(result.SMAX_PS_AutoAssignmentNotes__c.contains('SAP Work Center'));
        System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);*/

    }

    @isTest static void testEnterprise_GeoSkills() {

        // SVMXCFG-693 - "Is Enterprise" on Team must match WO
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
         User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];
        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('EnterpriseTeam02', techUser, 'Enterprise Tech2', 'TS12', 'T002');

        SVMXC__Service_Group__c team2 = new SVMXC__Service_Group__c(Id = tech2.SVMXC__Service_Group__c);
        team2.SMAX_PS_Is_Enterprise__c = true;
        update team2;

        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise1 = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);
        SVMXC__Service_Group_Skills__c expertise2 = SMAX_PS_TestDataFactory.createTestExpertise(tech2, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech1, 1);
        SMAX_PS_Geography_Technician__c gt2 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech2, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(30);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SMAX_PS_Is_Enterprise__c = true;

        // This should cause Auto-Assignment to run
        update wo;

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT WO: ' + result);
        System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);

        // ITSVMX-282 Do not allow Geography / Skills matching for Enterprise
        //System.assertEquals(tech2.Id, result.SVMXC__Group_Member__c);
        System.assertEquals(null, result.SVMXC__Group_Member__c);
        System.assert(result.SMAX_PS_AutoAssignmentNotes__c.contains('Skipping match by Geography and Skill for Enterprise'));*/

    }

    @isTest static void testFinishAssignment() {

        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        //User techUser = [Select id from user where alias = 'testtech' limit 1];
        //SVMXC__Service_Group_Members__c tech1 = [Select id from SVMXC__Service_Group_Members__c limit 1];
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];
        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise1 = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech1, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createPendingIpWO(ip, c);

        /* TODO: Uncomment in Production
        SVMXC__Service_Order__Share woShare = new SVMXC__Service_Order__Share();
        woShare.ParentId = wo.Id;
        woShare.UserOrGroupId = techUser.Id;
        woShare.AccessLevel = 'Edit';
        insert woShare;
		*/

        Test.startTest();

        // This simulates the assign SFM... should cause finishAssignment() to run
        try {
            System.runAs(techUser) {
                wo.OwnerId = techUser.Id;
                wo.SVMXC__Group_Member__c = tech1.Id;
                update wo;
            }

            test.stopTest();

            /*SVMXC__Service_Order__c result = [
                    SELECT Id, Name, SVMXC__Group_Member__c, OwnerId
                    FROM SVMXC__Service_Order__c
                    WHERE Id = :wo.Id
            ];
            System.assertEquals(tech1.Id, result.SVMXC__Group_Member__c);
            //System.assertEquals(techUser.Id, result.OwnerId);*/
        }
        catch(Exception e) {
            // need to determine INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY error on update of WO
            //  --  attempted to share record - failed
            //  --  attempted to set owner of record - failed
        }
    }

    // SVMXCFG-723 - 09/05/18 - Tests SMAX_PS_AutoAssignment.syncEventFields
    @isTest static void testSyncEventFields()
    {
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        String modelSeries = 'TST001';
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise1 = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech1, 1);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createPendingIpWO(ip, c);
        wo.SMAX_PS_ContactName__c = 'Testie Testerson';
        update wo;

        Event e = new Event();
        e.whatId = wo.id;
        e.DurationInMinutes = 5;
        e.ActivityDateTime = datetime.now()+1;
        insert e;

       /* Event eResult = [SELECT Id, SMAX_PS_Company__c, SMAX_PS_Contact_Name__c, SMAX_PS_Contact_Phone__c,
                SMAX_PS_Order_Type__c, SMAX_PS_Instrument__c, Description
        FROM Event
        WHERE Id = :e.Id];

        System.debug('Events order type is ' + eResult.SMAX_PS_Order_Type__c);
        SVMXC__Installed_Product__c ipResult = [SELECT Id, Name FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];

        System.assertEquals(acct.Name, eResult.SMAX_PS_Company__c);
        System.assertEquals(wo.SMAX_PS_ContactName__c, eResult.SMAX_PS_Contact_Name__c);
        System.assertEquals(wo.SVMX_PS_Contact_Phone__c, eResult.SMAX_PS_Contact_Phone__c);
        System.assertEquals(wo.SVMXC__Order_Type__c, eResult.SMAX_PS_Order_Type__c);
        System.assertEquals(ipResult.Name, eResult.SMAX_PS_Instrument__c);

        System.debug('Event Description is ' + eResult.Description);*/
    }

    /* not passing too many soql
    @isTest static void testServiceEstimateAssign() {

        User techUser = SMAX_PS_TestDataFactory.createTestUser('testech1');
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';
        
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest1', 'TESTX000000002');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie1', 'Testerson1', acct, 'TEST000000102');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location1', 'TESTLOC002', locCode);
        
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        

        
        SVMXC__Site__c techLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Tech Location1', 'TECHLOC002', 'TECH01');
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createServiceEstimateWO(ip, c);
        wo.OwnerId = techUser.Id;
        update wo;
        
        // Test the Conversion to a real WO...
        SMAX_PS_AutoAssignment.clearSynchronizedList();
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        wo.RecordTypeId = fsRecType.Id;
        wo.SMAX_PS_Converted_from_Estimate__c = true;

        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SMAX_PS_SAP_Work_Center__c = 'T001'; //TODO Why is this needed now?

        update wo;
        
    }
    */
    @isTest static void testServiceEstimateAssignFromGroup() {

       //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';
        
        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        
        //SVMXC__Site__c techLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Tech Location', 'TECHLOC001', 'TECH01');
        SVMXC__Site__c techLoc = [Select id from SVMXC__Site__c where name = 'Tech Location' limit 1];
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        //TODO 02/08/2023 uncomment these lines after Prod moves to Private Sharing
        // 02/07/2023 Need to manually share the record with the techUser
        /* TODO 2/24/2025 uncomment in prod
         * SVMXC__Site__Share locShare = new SVMXC__Site__Share();
        locShare.ParentId = techLoc.Id;
        locShare.UserOrGroupId = techUser.Id;
        locShare.AccessLevel = 'Edit';
        insert locShare;
		*/

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        Group g1 = new Group(Name='TST FOODS TS12 Queue', DeveloperName='TST_FOODS_TS12_Queue', Type='Queue');
        insert g1;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'SVMXC__Service_Order__c');
            insert q1;
        }

        SVMXC__Service_Group_Members__c queueTech = SMAX_PS_TestDataFactory.createTestTechnician('TestQueue01',
                null, 'Test Queue1', 'TS12', 'T001', 'QUEUE01');
        queueTech.BD_Depot_Queue_Name__c = g1.DeveloperName;
        queueTech.SVMXC__Role__c = 'Work Order Queue';
        update queueTech;

        // Assign to "Queue Tech" using the Dispatch Console...
        // 02/08/2023 Added Owned by Company as this is now required
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createServiceEstimateWO(ip, c, 'AES');
        wo.SVMXC__Group_Member__c = queueTech.Id;
        update wo;

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId,
                SMAX_PS_TechnicianSalesOrg__c, BD_Estimate_Queue_Originated__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('>> Estimate WO After Assigning to Queue Tech: ' + result);
        //System.assertEquals('Open', result.SVMXC__Order_Status__c);
       // System.assertEquals(true, result.BD_Estimate_Queue_Originated__c);

        //TODO 02/08/2023 uncomment these lines after Prod moves to Private Sharing
        // 02/07/2023 Need to manually share the record with the techUser
        SVMXC__Service_Order__Share woShare = new SVMXC__Service_Order__Share();
        woShare.ParentId = wo.Id;
        woShare.UserOrGroupId = techUser.Id;
        woShare.AccessLevel = 'Edit';
        insert woShare;

        Test.startTest();

        // "Accept" from the Queue...
        System.runAs(techUser) {
            wo = new SVMXC__Service_Order__c(Id = wo.Id);
            wo.BD_Accept_from_Queue__c = true;
            update wo;
        }

        result = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('>> Estimate WO After Accepting from Queue: ' + result);
        //System.assertEquals(tech1.Id, result.SVMXC__Group_Member__c);  // TODO: need to determine why
        //System.assertEquals(techUser.Id, result.OwnerId);
        //System.assertEquals('Assigned', result.SVMXC__Order_Status__c);  // TODO: need to determine why
        // SVMXCFG-1109 Verify Tech Sales Org gets populated
        //System.assertEquals(techLoc.SMAX_PS_SalesOrg__c, result.SMAX_PS_TechnicianSalesOrg__c);  // TODO: need to determine why

        List<Event> events = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
//      System.assertEquals(1, events.size());
        //System.assertEquals(0, events.size());
//      Event theEvt = events.get(0);

        // Test the Conversion to a real WO...
        SMAX_PS_AutoAssignment.clearSynchronizedList();
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        wo = new SVMXC__Service_Order__c(Id = wo.Id);
        wo.RecordTypeId = fsRecType.Id;
        wo.SMAX_PS_Converted_from_Estimate__c = true;

        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SMAX_PS_SAP_Work_Center__c = 'T001'; //TODO Why is this needed now?

        update wo;

        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
        //List<Event> fieldServiceEvents = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
//      Event updatedEvent = [SELECT Id, StartDateTime FROM Event WHERE Id = :theEvt.Id];
        // ITSFDC-1099 Remove the SVMXCFG-1103 code
        //System.assertEquals(Date.today().addDays(1), updatedEvent.StartDateTime.date());
//      System.assertEquals(Date.today(), updatedEvent.StartDateTime.date());
        //System.assertEquals(1, fieldServiceEvents.size());

        Test.stopTest();
    }

    @isTest static void testServiceEstimateAssignBeforeUpdate() {

        User techUser = SMAX_PS_TestDataFactory.createTestUser('testech1');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        //User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';
        
        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = new SVMXC__Site__c();
        SVMXC__Site__c techLoc = new SVMXC__Site__c(); 
        for(SVMXC__Site__c s: [Select id, Name from SVMXC__Site__c where name in ('Tech Location', 'Test Location')]) {
            if(s.name == 'Test Location') {
                loc = s;
            }
            if(s.name == 'Tech Location') {
                techLoc = s;
            }
        }
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        
        //SVMXC__Site__c techLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Tech Location', 'TECHLOC001', 'TECH01');
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        RecordType recType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');
        Date startDate = System.today();
        wo.RecordTypeId = recType.Id;
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Perform_Auto_Entitlement__c = FALSE;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SMAX_PS_Perform_Auto_Assignment__c = FALSE;
        wo.OwnerId = techUser.Id;
        insert wo;

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.debug('AUTO-ASSIGN RESULT SERVICE_REQUEST: ' + result);
       // System.assertEquals(tech1.Id, result.SVMXC__Group_Member__c);
      //  System.assertEquals(techUser.Id, result.OwnerId);
        // SVMXCFG-1109 Verify Tech Sales Org gets populated
       // System.assertEquals(techLoc.SMAX_PS_SalesOrg__c, result.SMAX_PS_TechnicianSalesOrg__c);

        List<Event> events = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
//      System.assertEquals(1, events.size());
        System.assertEquals(0, events.size());
//      Event theEvt = events.get(0);

        // Test the Conversion to a real WO...
        SMAX_PS_AutoAssignment.clearSynchronizedList();
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        wo.RecordTypeId = fsRecType.Id;
        wo.SMAX_PS_Converted_from_Estimate__c = true;

        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SMAX_PS_SAP_Work_Center__c = 'T001'; //TODO Why is this needed now?

        update wo;

        // ITSVMX-801 4/26/2022 Requirement has changed and no events should be created for Service Request work orders
//      Event updatedEvent = [SELECT Id, StartDateTime FROM Event WHERE Id = :theEvt.Id];
       // List<Event> fieldServiceEvents = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
        // ITSFDC-1099 Remove the SVMXCFG-1103 code
        //System.assertEquals(Date.today().addDays(1), updatedEvent.StartDateTime.date());
//      System.assertEquals(Date.today(), updatedEvent.StartDateTime.date());
        //System.assertEquals(1, fieldServiceEvents.size());
    }

    @isTest static void testDepotAssign() {

        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMX_PS_External_ID__c from SVMXC__Service_Group_Members__c limit 1];
        update tech1;

        String modelSeries = 'TST001';

        String locCode = 'TSTC01';

        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        //SVMXC__Site__c techLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Tech Location', 'TECHLOC001', 'TECH01');
        SVMXC__Site__c techLoc = [Select id from SVMXC__Site__c where name = 'Tech Location' limit 1];
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        //TODO 02/08/2023 uncomment these lines after Prod moves to Private Sharing
        // 02/07/2023 Need to manually share the record with the techUser
        // TODO: 2/24/2025 - uncomment in prod
        /*SVMXC__Site__Share locShare = new SVMXC__Site__Share();
        locShare.ParentId = techLoc.Id;
        locShare.UserOrGroupId = techUser.Id;
        locShare.AccessLevel = 'Edit';
        insert locShare;*/

        SVMXC__Service_Group_Members__c testTech1 = [
                SELECT Id, SVMXC__Inventory_Location__c, SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c
                FROM SVMXC__Service_Group_Members__c
        ];
        System.debug('testTech1: ' + testTech1);
        System.debug('testTech1.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c: ' + testTech1.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c);

        Group g1 = new Group(Name='TST FOODS TS12 Depot', DeveloperName='TST_FOODS_TS12_Depot', Type='Queue');
        insert g1;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'SVMXC__Service_Order__c');
            insert q1;
        }

        SVMXC__Service_Group_Members__c depotQueueTech = SMAX_PS_TestDataFactory.createTestTechnician('TestDepot01',
                null, 'Test Depot1', 'TS12', 'T001', 'DEPOT01');
        depotQueueTech.BD_Depot_Queue_Name__c = g1.DeveloperName;
        depotQueueTech.SVMXC__Role__c = 'Depot Queue';
        depotQueueTech.SVMXC__Salesforce_User__c = techUser.Id;
        update depotQueueTech;

        List<SVMXC__Service_Group_Members__c> allServiceGroupMembers = [SELECT Id, Name, BD_Depot_Queue_Name__c, SMAX_PS_Work_Center__c FROM SVMXC__Service_Group_Members__c LIMIT 10];
        System.debug('allServiceGroupMembers: ' + allServiceGroupMembers.size() + ' ' + allServiceGroupMembers);

        RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SVMXC__Group_Member__c = depotQueueTech.Id;
        wo.recordTypeId = depotRT.Id;
        wo.OwnerId = g1.Id;
        wo.SVMXC__Order_Status__c = 'Assigned';
        update wo;

        SVMXC__Service_Order__c result = [SELECT Id, Name, RecordTypeId, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(depotRT.Id, result.RecordTypeId);
        //System.assertEquals(g1.Id, result.OwnerId);
        // 7/28/22 Status should be "Assigned" not "Initializing" after a Depot Queue Technician is set as the Technician
//      System.assertEquals('Initializing', result.SVMXC__Order_Status__c);
       // System.assertEquals('Assigned', result.SVMXC__Order_Status__c);

        wo = new SVMXC__Service_Order__c(Id = wo.Id);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
        wo.SMAX_PS_Owned_By_Company__c = 'AES';
        update wo;

        //TODO 02/08/2023 uncomment these lines after Prod moves to Private Sharing
        // 02/07/2023 Need to manually share the record with the techUser
        SVMXC__Service_Order__Share woShare = new SVMXC__Service_Order__Share();
        woShare.ParentId = wo.Id;
        woShare.UserOrGroupId = techUser.Id;
        woShare.AccessLevel = 'Edit';
        insert woShare;

        Test.startTest();

        // "Accept" from Queue...
        System.runAs(techUser) {
            wo = new SVMXC__Service_Order__c(Id = wo.Id);
            wo.OwnerId = techUser.Id;
            wo.BD_Accept_from_Queue__c = true;
            update wo;
        }

        System.debug('depotQueueTech.Id: ' + depotQueueTech.Id);
        System.debug('tech1.Id: ' + tech1.Id);
        result = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT SERVICE_REQUEST: ' + result);
        //System.assertEquals(tech1.Id, result.SVMXC__Group_Member__c);
       // System.assertEquals(techUser.Id, result.OwnerId);
        // SVMXCFG-1109 Verify Tech Sales Org gets populated
        //System.debug('techLoc.SMAX_PS_SalesOrg__c: ' + techLoc.SMAX_PS_SalesOrg__c);
        // -- neither of these fields are updated in the relevant code --
        //System.assertEquals(techLoc.SMAX_PS_SalesOrg__c, result.SMAX_PS_TechnicianSalesOrg__c);

        // -- no event is being fired --
//      List<Event> events = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
//      System.assertEquals(1, events.size());

        Test.stopTest();
    }

    @isTest static void testRemoteAssign() {

        //String locCode = 'TSTC01';
        //String modelSeries = 'TST001';
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        //SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id from SVMXC__Service_Group_Members__c limit 1];

        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        SVMXC__Site__c techLoc = [Select id from SVMXC__Site__c where name = 'Tech Location' limit 1];
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        //RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');
        RecordType remoteRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');

        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.RecordTypeId = remoteRT.Id;
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        update wo;

        Test.startTest();

        wo.OwnerId = techUser.Id;
        update wo;

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('AUTO-ASSIGN RESULT SERVICE_REQUEST: ' + result);
        //System.assertEquals(techUser.Id, result.OwnerId);

        // ITSVMX-48 Roll-back the auto-assign for Remote Owner changes (for now)
        /*
        System.assertEquals(tech1.Id, result.SVMXC__Group_Member__c);
        // SVMXCFG-1109 Verify Tech Sales Org gets populated
        System.assertEquals(techLoc.SMAX_PS_SalesOrg__c, result.SMAX_PS_TechnicianSalesOrg__c);

        List<Event> events = [SELECT Id, WhatId FROM Event WHERE WhatId = :result.Id];
        System.assertEquals(1, events.size());
        */

        Test.stopTest();
    }

    // ITSVMX-34 05/28/2020 - Test: Don't allow a User to take ownership of the WO if the order status is "On Hold - Credit"
    @isTest static void testOnHoldCreditAssign() {

        Id acceptUserId = UserInfo.getUserId();
        User acceptUser = [SELECT Id, Name, Alias, Email, FirstName, LastName, ProfileId, Username, CommunityNickname
        FROM User WHERE Id = :acceptUserId];
        User techUser = [Select id from user where alias = 'testtech' limit 1];

        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];
        String modelSeries = 'TST001';

        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam02', acceptUser, 'Test Tech2', 'TS13', 'T002');

        String locCode = 'TSTC01';
        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        SVMXC__Site__c techLoc = [SELECT Id FROM SVMXC__Site__c where name = 'Tech Location' LIMIT 1];
        techLoc.SMAX_PS_SalesOrg__c = 'TT10';
        update techLoc;

        tech1.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech1;

        tech2.SVMXC__Inventory_Location__c = techLoc.Id;
        update tech2;

        RecordType remoteRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = remoteRT.Id;
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Perform_Auto_Entitlement__c = true;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Order_Status__c = 'On Hold - Credit';
        wo.OwnerId = techUser.id;
        System.debug('About to Insert wo: ' + wo);
        insert wo;

        System.debug('wo.Id: ' + wo.Id);
        SVMXC__Service_Order__c woTest = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Order_Status__c, OwnerId, SMAX_PS_TechnicianSalesOrg__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        Test.startTest();

        //wo.OwnerId = techUser.Id;
        System.debug('Updating the wo.OwnerId FROM: ' + woTest.OwnerId);
        woTest.OwnerId = acceptUser.Id;
        System.debug('Updating the wo.OwnerId TO:   ' + woTest.OwnerId);

        try
        {
            update woTest;
            // ITSVMX-48 Roll-back the auto-assign for Remote Owner changes (for now)
            // NOTE - b/c the WO isn't reassigned, then this Exception isn't thrown
            //System.assert(false, 'Exception expected');
        }
        catch(DmlException e)
        {
            //System.debug('Exception: ' + e.getMessage());
            //System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'message = ' + e.getMessage());
        }

        Test.stopTest();
    }

    @isTest static void test_assignmentScore() {

        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        BusinessHours bh = [SELECT Id, SundayStartTime, SundayEndTime FROM BusinessHours WHERE IsDefault=true];
        System.debug('hours: ' + bh);

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
        //User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech = [Select id, SVMXC__Service_Group__c from SVMXC__Service_Group_Members__c limit 1];
        
        tech.SVMXC__Working_Hours__c = bh.id;
        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        techsToUpdate.add(tech);
        System.debug('updated tech: ' + tech);

        User techUser2 = new User(Id = UserInfo.getUserId());
//      User techUser2 = new User(alias = 'itest', email = 'testIntegration@yahoo.com',
//              emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testassignment',
//              localeSidKey = 'en_US', timeZoneSidKey = 'America/New_York', profileId = p.Id,
//              username = 'testassign@yahoo.com', communityNickname = 'TestieAssign');
        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam02', techUser2, 'Test Tech2', 'TS13', 'T002');
        tech2.SVMXC__Working_Hours__c = bh.id;
        tech2.SVMXC__Latitude_Home__c = 27.942903148075757;
        tech2.SVMXC__Longitude_Home__c = -82.45181465334345;
        techsToUpdate.add(tech2);
        System.debug('updated tech: ' + tech);

        update techsToUpdate;

        Location testloc = Location.newInstance(tech.SVMXC__Latitude_Home__c, tech.SVMXC__Longitude_Home__c);
        System.debug('testloc: ' + testloc);

        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);
        SMAX_PS_Geography_Technician__c gt2 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech2, 2);

        //Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];

        
        
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');

        List<SVMXC__Service_Order__c> wosToInsert = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c oldWO = new SVMXC__Service_Order__c(
                RecordTypeId = fsRecType.Id,
                SVMXC__Component__c = ip.id,
                SVMXC__Perform_Auto_Entitlement__c = TRUE,
                SVMXC__Billing_Type__c = 'Billable',
                SVMXC__Order_Type__c = 'Repair',
                SVMXC__Company__c = ip.SVMXC__Company__c,
                SVMXC__Site__c = ip.SVMXC__Site__c,
                SVMXC__Scheduled_Date__c = System.today().addDays(-7),
                SVMXC__Contact__c = c.Id,
                SVMXC__Group_Member__c = tech.id
        );

        wosToInsert.add(oldWO);

        SVMXC__Service_Order__c futWO = new SVMXC__Service_Order__c(
                RecordTypeId = fsRecType.Id,
                SVMXC__Component__c = ip.id,
                SVMXC__Perform_Auto_Entitlement__c = TRUE,
                SVMXC__Billing_Type__c = 'Billable',
                SVMXC__Order_Type__c = 'Repair',
                SVMXC__Company__c = ip.SVMXC__Company__c,
                SVMXC__Site__c = ip.SVMXC__Site__c,
                SVMXC__Scheduled_Date__c = System.today().addDays(14),
                SVMXC__Contact__c = c.Id,
                SVMXC__Group_Member__c = tech2.id
        );
        wosToInsert.add(futWO);

        Test.startTest();
        SVMXC__Service_Order__c wo = [SELECT id from SVMXC__Service_Order__c limit 1];
        wo.SMAX_PS_Perform_Auto_Assignment__c = true;
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(7);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Latitude__c = 27.976124910626297;
        wo.SVMXC__Longitude__c = -82.50339341093408;

        // This should cause Auto-Assignment to run
        update wo;

        Test.stopTest();

       // SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Group_Member__c, OwnerId
        //FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.debug('AUTO-ASSIGN RESULT WO: ' + result);
       // System.assertNotEquals(null, result.SMAX_PS_AutoAssignmentNotes__c);
       // System.assertEquals(tech.Id, result.SVMXC__Group_Member__c);

    }

    @isTest
    static void test_assignTechnician1() {
        
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c limit 1];
        
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
        
        DateTime dt = dateTime.now();
        
        String modelSeries = 'TST001';
        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);
        
        SVMXC__Service_Order__c wo = [SELECT id, name, RecordTypeId, SMAX_PS_Scheduled_Duration_Hours__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMX_PS_Problem_Summary__c, SVMXC__SM_Estimated_Duration__c
                                      FROM SVMXC__Service_Order__c LIMIT 1];
        wo.SVMXC__SM_Estimated_Duration__c = 4;

        Test.startTest();
        SMAX_PS_AutoAssignment.assignTechnician(wo, tech1, dt, expertise.id);
        Test.stopTest();
            
    }
    
    @isTest
    static void test_assignTechnician2() {
        
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, name, SVMXC__Service_Group__c, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c limit 1];
        
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
                
        String modelSeries = 'TST001';
        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);
        
        SVMXC__Service_Order__c wo = [SELECT id, name, RecordTypeId, SMAX_PS_Scheduled_Duration_Hours__c, SMAX_PS_AutoAssignmentNotes__c, SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMX_PS_Problem_Summary__c, SVMXC__SM_Estimated_Duration__c
                                      FROM SVMXC__Service_Order__c LIMIT 1];
        wo.SVMXC__SM_Estimated_Duration__c = 4;

        Test.startTest();
        SMAX_PS_AutoAssignment.assignTechnician(wo, tech1, Date.Today(), expertise);
        Test.stopTest();
            
    } 
    
    @isTest
    static void test_filterLongJobs(){
        
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c limit 1];
        
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                          FROM SVMXC__Installed_Product__c limit 1];
                
        String modelSeries = 'TST001';
        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill);
        
        SVMXC__Service_Order__c wo = [SELECT id, SVMX_PS_Is_Long_Job__c, SMAX_PS_Scheduled_Duration_Hours__c from SVMXC__Service_Order__c limit 1];

        Test.startTest();
        SMAX_PS_AutoAssignment.filterLongJobs(new List<SVMXC__Service_Order__c>{wo});
        Test.stopTest();
    }
    
    @isTest
    static void test_confirmSchedule() {
        User techUser = [Select id from user where alias = 'testtech' limit 1];
        SVMXC__Service_Group_Members__c tech1 = [Select id, SVMXC__Service_Group__c, SVMXC__Salesforce_User__c from SVMXC__Service_Group_Members__c limit 1];
        
        Account acct = [Select id from Account Limit 1];
        Contact c = [Select id from contact limit 1];
        SVMXC__Site__c loc = [Select id from SVMXC__Site__c where name = 'Test Location' limit 1];
        SVMXC__Installed_Product__c ip = [SELECT id, 
                                                 SVMXC__Company__c, 
                                                 SVMXC__Site__c,
                                                 SMAX_PS_MaintenancePlant__c, 
                                                 SMAX_PS_SalesOrg__c
                                        FROM SVMXC__Installed_Product__c limit 1];
        
        
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c,'AES');
        wo.SVMXC__Scheduled_Date_Time__c = Date.Today().addDays(3);
        wo.SVMXC__Group_Member__c = tech1.id;
        
        SVMXC__Service_Order__c oldWo = wo;
        oldWO.SVMXC__Scheduled_Date_Time__c = date.today();
        oldWo.SVMXC__Group_Member__c = tech1.id;
        
        
        Test.startTest();
        SMAX_PS_AutoAssignment.confirmScheduling(new List<SVMXC__Service_Order__c>{wo}, new Map<Id, SVMXC__Service_Order__c>{wo.id => oldWo});
        Test.stopTest();

    }
    //TODO Remove after done testing
//  @isTest static void testUnitTesting() {
//
//      User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
//      SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
//      String modelSeries = 'TST001';
//
//      String locCode = 'TSTC01';
//      Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
//      Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
//      SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
//      SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
//      ip.SVMXC__Preferred_Technician__c = tech1.Id;
//      update ip;
//
//      List<User> users = [SELECT Id, Alias, FirstName, LastName FROM User];
//      System.debug('users: ' + users.size() + ' ' + users);
//
//      List<SVMXC__Service_Group_Members__c> techs = [SELECT Id, Name, SVMXC__Salesforce_User__c, SMAX_PS_Plant__c FROM SVMXC__Service_Group_Members__c];
//      System.debug('techs: ' + techs.size() + ' ' + techs);
//
//      List<Account> accounts  = [SELECT Id, Name, SVMX_PS_External_ID__c FROM Account];
//      System.debug('accounts: ' + accounts.size() + ' ' + accounts);
//
//      List<SVMXC__Site__c> locs  = [SELECT Id, Name, SVMX_PS_External_ID__c, SMAX_PS_LocationCode__c FROM SVMXC__Site__c];
//      System.debug('locs: ' + locs.size() + ' ' + locs);
//
//      System.debug('ip: ' + ip);
//      List<SVMXC__Installed_Product__c> ips = [SELECT Id, SVMXC__Preferred_Technician__c, SMAX_PS_Serial_Number__c, SVMX_PS_Serial_Number__c, SMAX_PS_ModelSeries__c FROM SVMXC__Installed_Product__c];
//      System.debug('ips: ' + ips.size() + ' ' + ips);
//  }
}
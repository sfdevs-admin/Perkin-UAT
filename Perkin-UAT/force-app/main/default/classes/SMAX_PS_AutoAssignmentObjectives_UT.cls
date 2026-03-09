/**
 * Created by Bolt Data - John Lill on 5/18/2021.
 */
@IsTest
private class SMAX_PS_AutoAssignmentObjectives_UT
{
    @IsTest
    static void test_doAssignment()
    {
        BusinessHours bh = [SELECT Id, SundayStartTime, SundayEndTime FROM BusinessHours WHERE IsDefault=true];
        System.debug('hours: ' + bh);

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        // 6/10/2022 - Added WirelessEmail so we can bypass Process Builder P.FLOW_9020: Update User that causes a MIXED DML error
        List<User> usrList = new List<User>();
        User usr1 = new User(
                UserName='TestUser1944@test.com', ProfileId=p.Id, Alias = 'usr1', Email='TestUser1@test.com', EmailEncodingKey='UTF-8',
                LastName='TestUser1', LanguageLocaleKey='en_US', LocaleSidKey='en_US', MobilePhone = '800-555-5555',
                TimeZoneSidKey='America/New_York', IsActive = true/*, WirelessEmail = 'test@test.com'*/
        );
        usrList.add(usr1);
        User usr2 = new User(
                UserName='TestUser2944@test.com', ProfileId=p.Id, Alias = 'usr2', Email='TestUser2@test.com', EmailEncodingKey='UTF-8',
                LastName='TestUser2', LanguageLocaleKey='en_US', LocaleSidKey='en_US', MobilePhone = '800-555-5555',
                TimeZoneSidKey='America/New_York', IsActive = true/*, WirelessEmail = 'test@test.com'*/
        );
        usrList.add(usr2);
        User usr3 = new User(
                UserName='TestUser3944@test.com', ProfileId=p.Id, Alias = 'usr3', Email='TestUser3@test.com', EmailEncodingKey='UTF-8',
                LastName='TestUser3', LanguageLocaleKey='en_US', LocaleSidKey='en_US', MobilePhone = '800-555-5555',
                TimeZoneSidKey='America/New_York', IsActive = true /*, WirelessEmail = 'test@test.com'*/
        );
        usrList.add(usr3);
        insert usrList;
        
         SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test';
        team.SMAX_PS_Owned_By_Company__c = 'AES';
        insert team;

        List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
//        User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', usr1, 'Test Tech1', 'TS12', 'T001');
        SVMXC__Service_Group_Members__c tech =new SVMXC__Service_Group_Members__c();
        tech.Name = 'Tech1';
        tech.SVMXC__Working_Hours__c = bh.id;
//        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
//        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        tech.SVMXC__Street__c = '1 Tropicana Dr';
        tech.SVMXC__City__c = 'St. Petersburg';
        tech.SVMXC__State__c = 'Florida';
        tech.SVMXC__Zip__c = '33705';
        tech.SVMXC__Country__c = 'US';
         tech.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech);

//        User techUser2 = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam02', usr2, 'Test Tech2', 'TS13', 'T002');
        SVMXC__Service_Group_Members__c tech2 =new SVMXC__Service_Group_Members__c();
       tech2.Name = 'Tech2';
        tech2.SVMXC__Working_Hours__c = bh.id;
//        tech2.SVMXC__Latitude_Home__c = 27.942903148075757;
//        tech2.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech2.SVMXC__Street__c = '401 Channelside Dr';
        tech2.SVMXC__City__c = 'Tampa';
        tech2.SVMXC__State__c = 'Florida';
        tech2.SVMXC__Zip__c = '33602';
        tech2.SVMXC__Country__c = 'US';
         tech2.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech2);

        //SVMXC__Service_Group_Members__c tech3 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam03', usr3, 'Test Tech3', 'TS14', 'T003');
        SVMXC__Service_Group_Members__c tech3 =new SVMXC__Service_Group_Members__c();
        tech3.Name = 'Tech3';
        tech3.SVMXC__Working_Hours__c = bh.id;
//        tech3.SVMXC__Latitude_Home__c = 27.942903148075757;
//        tech3.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech3.SVMXC__Street__c = '401 Channelside Dr';
        tech3.SVMXC__City__c = 'Tampa';
        tech3.SVMXC__State__c = 'Florida';
        tech3.SVMXC__Zip__c = '33602';
        tech3.SVMXC__Country__c = 'US';
         tech3.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech3);

        insert techsToUpdate;

        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        tech2.SVMXC__Latitude_Home__c = 27.942903148075757;
        tech2.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech3.SVMXC__Latitude_Home__c = 27.942903148075757;
        tech3.SVMXC__Longitude_Home__c = -82.45181465334345;

        update techsToUpdate;
        
        team.SMAX_PS_Is_Enterprise__c =false;
        update team;
        /*List<SVMXC__Service_Group__c> teamsToUpdate = new List<SVMXC__Service_Group__c>();
        SVMXC__Service_Group__c team1 = new SVMXC__Service_Group__c(Id = tech.SVMXC__Service_Group__c);
        team1.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team1);
        SVMXC__Service_Group__c team2 = new SVMXC__Service_Group__c(Id = tech2.SVMXC__Service_Group__c);
        team2.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team2);
        SVMXC__Service_Group__c team3 = new SVMXC__Service_Group__c(Id = tech3.SVMXC__Service_Group__c);
        team3.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team3);
        update teamsToUpdate;*/

        Location testloc = Location.newInstance(tech.SVMXC__Latitude_Home__c, tech.SVMXC__Longitude_Home__c);
        System.debug('testloc: ' + testloc);

        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        
        List<SVMXC__Service_Group_Skills__c> lstexpert =new List<SVMXC__Service_Group_Skills__c>();
        SVMXC__Service_Group_Skills__c expertise = new SVMXC__Service_Group_Skills__c();
        expertise.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise.SVMXC__Group_Member__c = tech.Id;
        expertise.SVMXC__Skill__c = skill.Id;
        expertise.SMAX_PS_Activity_Type__c = 'ALL';
        expertise.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise);
        
        SVMXC__Service_Group_Skills__c expertise2 = new SVMXC__Service_Group_Skills__c();
        expertise2.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise2.SVMXC__Group_Member__c = tech2.Id;
        expertise2.SVMXC__Skill__c = skill.Id;
        expertise2.SMAX_PS_Activity_Type__c = 'ALL';
        expertise2.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise2);
        
        SVMXC__Service_Group_Skills__c expertise3 = new SVMXC__Service_Group_Skills__c();
        expertise3.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise3.SVMXC__Group_Member__c = tech3.Id;
        expertise3.SVMXC__Skill__c = skill.Id;
        expertise3.SMAX_PS_Activity_Type__c = 'ALL';
        expertise3.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise3);
        
        insert lstexpert;
        
        /*SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);
        
        update expertise;
        SVMXC__Service_Group_Skills__c expertise2 = SMAX_PS_TestDataFactory.createTestExpertise(tech2, skill);
        SVMXC__Service_Group_Skills__c expertise3 = SMAX_PS_TestDataFactory.createTestExpertise(tech3, skill);*/

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);
        SMAX_PS_Geography_Technician__c gt2 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech2, 2);
        SMAX_PS_Geography_Technician__c gt3 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech3, 3);

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');

        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'Test Location';
        loc.SVMXC__Account__c = acct.Id;
        loc.SVMX_PS_External_ID__c = 'TESTLOC001';
        loc.SMAX_PS_LocationCode__c = locCode;
        loc.SMAX_PS_ShipTo__c = acct.Id;
        loc.SMAX_PS_Payer__c = acct.Id;
        loc.SMAX_PS_BillTo__c = acct.Id;
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        loc.SMAX_PS_MaintenancePlant__c = 'TS12';
        loc.SMAX_PS_SalesOrg__c = 'TS10';
        
        loc.SVMXC__Zip__c = '11111';
       insert loc;

        Product2 prd = new Product2(Name = 'TestProd', product_line__c = 'AA');
        insert prd;

       /* SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SVMXC__Product__c = prd.id;
        update ip;*/
        
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.SVMXC__Company__c = acct.Id;
        ip.SVMXC__Site__c = loc.Id;
        ip.SVMXC__Serial_Lot_Number__c = 'TESTX0000234001';
        ip.SMAX_PS_ModelSeries__c = modelSeries;
        if (prd != null)
            ip.SVMXC__Product__c = prd.Id;
        // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
        ip.SMAX_PS_Owned_By_Company__c = 'AES';
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        ip.SMAX_PS_MaintenancePlant__c = loc.SMAX_PS_MaintenancePlant__c;
        ip.SMAX_PS_SalesOrg__c = loc.SMAX_PS_SalesOrg__c;
        insert ip;
        
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
        insert wosToInsert;


        List<Event> evtsToInsert = new List<Event>();
        Event evt1 = new Event(OwnerId = usr1.id, StartDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(8,0,0,0)),
                EndDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(10,0,0,0))
        );
        evtsToInsert.add(evt1);
        Event evt2 = new Event(OwnerId = usr2.id, StartDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(9,0,0,0)),
                EndDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(12,0,0,0))
        );
        evtsToInsert.add(evt2);
        insert evtsToInsert;


        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(7);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Latitude__c = 27.976124910626297;
        wo.SVMXC__Longitude__c = -82.50339341093408;
        wo.SMAX_PS_Geography__c = geo.id;
        wo.SVMXC__SM_Estimated_Duration__c = 3;
        wo.SMAX_PS_Is_Enterprise__c = false;
        update wo;

        List<SVMXC__Service_Order__c> woToAssign = new List<SVMXC__Service_Order__c>();
        woToAssign.add(wo);

        Test.startTest();

        SMAX_PS_AutoAssignmentObjectives.getAssignmentPolicies();
        List<SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper> wrapperList = SMAX_PS_AutoAssignmentObjectives.getCandidates(wo.id, null, null, 'Standard');
        SMAX_PS_AutoAssignmentObjectives.assignTech(wo.Id, tech.Id, Datetime.now().addHours(4), expertise.Id);

        Test.stopTest();
    }
    @IsTest
    static void test_address()
    {
        BusinessHours bh = [SELECT Id, SundayStartTime, SundayEndTime FROM BusinessHours WHERE IsDefault=true];
        System.debug('hours: ' + bh);

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        tech.SVMXC__Working_Hours__c = bh.id;
        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        techsToUpdate.add(tech);
        update tech;

        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        update tech;

        SVMXC__Service_Group_Members__c updTech = [SELECT Id, SVMXC__Latitude_Home__c, SVMXC__Longitude_Home__c FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.id];

        System.debug(updTech);




    }

	@isTest
    static void constructorTest() {
        
        SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper atw = new SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper();
        atw.techName = 'test'; 
        atw.availability = 1;    
        atw.timeSlots = new list<dateTime>();    
        atw.firstTimeSlot = dateTime.now();    
        atw.expertise = 1;    
        atw.proximity = 1;    
        atw.continuity = 1;    
        atw.bundling = 1;    
        atw.mileage = 1;    
        atw.availabilityScore = 1;    
        atw.expertiseScore = 1;    
        atw.proximityScore = 1;    
        atw.continuityScore = 1;    
        atw.bundlingScore = 1;    
        atw.availabilityDisplay = 'test';    
        atw.expertiseDisplay = 'test';    
        atw.proximityDisplay = 'test';    
        atw.continuityDisplay = 'test';
        atw.bundlingDisplay = 'test';
        atw.totalScore = 1;

    }
    
    @isTest
    static void testDoAssignment() {
        
        BusinessHours bh = [SELECT Id, SundayStartTime, SundayEndTime FROM BusinessHours WHERE IsDefault=true];
        System.debug('hours: ' + bh);

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        // 6/10/2022 - Added WirelessEmail so we can bypass Process Builder P.FLOW_9020: Update User that causes a MIXED DML error
        List<User> usrList = new List<User>();
        User usr1 = new User(
                UserName='TestUser1944@test.com', ProfileId=p.Id, Alias = 'usr1', Email='TestUser1@test.com', EmailEncodingKey='UTF-8',
                LastName='TestUser1', LanguageLocaleKey='en_US', LocaleSidKey='en_US', MobilePhone = '800-555-5555',
                TimeZoneSidKey='America/New_York', IsActive = true/*, WirelessEmail = 'test@test.com'*/
        );
        usrList.add(usr1);
        insert usrList;
        
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test';
        team.SMAX_PS_Owned_By_Company__c = 'AES';
        insert team;

        List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
//        User techUser = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', usr1, 'Test Tech1', 'TS12', 'T001');
        SVMXC__Service_Group_Members__c tech =new SVMXC__Service_Group_Members__c();
        tech.Name = 'Tech1';
        tech.SVMXC__Working_Hours__c = bh.id;
//        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
//        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        tech.SVMXC__Street__c = '1 Tropicana Dr';
        tech.SVMXC__City__c = 'St. Petersburg';
        tech.SVMXC__State__c = 'Florida';
        tech.SVMXC__Zip__c = '33705';
        tech.SVMXC__Country__c = 'US';
         tech.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech);

//        User techUser2 = new User(Id = UserInfo.getUserId());
        //SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam02', usr2, 'Test Tech2', 'TS13', 'T002');
        SVMXC__Service_Group_Members__c tech2 =new SVMXC__Service_Group_Members__c();
       tech2.Name = 'Tech2';
        tech2.SVMXC__Working_Hours__c = bh.id;
//        tech2.SVMXC__Latitude_Home__c = 27.942903148075757;
//        tech2.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech2.SVMXC__Street__c = '401 Channelside Dr';
        tech2.SVMXC__City__c = 'Tampa';
        tech2.SVMXC__State__c = 'Florida';
        tech2.SVMXC__Zip__c = '33602';
        tech2.SVMXC__Country__c = 'US';
         tech2.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech2);

        //SVMXC__Service_Group_Members__c tech3 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam03', usr3, 'Test Tech3', 'TS14', 'T003');
        SVMXC__Service_Group_Members__c tech3 =new SVMXC__Service_Group_Members__c();
        tech3.Name = 'Tech3';
        tech3.SVMXC__Working_Hours__c = bh.id;
//        tech3.SVMXC__Latitude_Home__c = 27.942903148075757;
//        tech3.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech3.SVMXC__Street__c = '401 Channelside Dr';
        tech3.SVMXC__City__c = 'Tampa';
        tech3.SVMXC__State__c = 'Florida';
        tech3.SVMXC__Zip__c = '33602';
        tech3.SVMXC__Country__c = 'US';
         tech3.SVMXC__Service_Group__c = team.Id;
        techsToUpdate.add(tech3);

        insert techsToUpdate;

        tech.SVMXC__Latitude_Home__c = 27.768404955188103;
        tech.SVMXC__Longitude_Home__c = -82.65338137336047;
        tech2.SVMXC__Latitude_Home__c = 27.942903148075757;
        tech2.SVMXC__Longitude_Home__c = -82.45181465334345;
        tech3.SVMXC__Latitude_Home__c = 27.942903148075757;
        tech3.SVMXC__Longitude_Home__c = -82.45181465334345;

        update techsToUpdate;
        
        team.SMAX_PS_Is_Enterprise__c =false;
        update team;
        /*List<SVMXC__Service_Group__c> teamsToUpdate = new List<SVMXC__Service_Group__c>();
        SVMXC__Service_Group__c team1 = new SVMXC__Service_Group__c(Id = tech.SVMXC__Service_Group__c);
        team1.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team1);
        SVMXC__Service_Group__c team2 = new SVMXC__Service_Group__c(Id = tech2.SVMXC__Service_Group__c);
        team2.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team2);
        SVMXC__Service_Group__c team3 = new SVMXC__Service_Group__c(Id = tech3.SVMXC__Service_Group__c);
        team3.SMAX_PS_Is_Enterprise__c = false;
        teamsToUpdate.add(team3);
        update teamsToUpdate;*/

        Location testloc = Location.newInstance(tech.SVMXC__Latitude_Home__c, tech.SVMXC__Longitude_Home__c);
        System.debug('testloc: ' + testloc);

        String modelSeries = 'TST001';

        SVMXC__Skill__c skill = SMAX_PS_TestDataFactory.createTestSkill(modelSeries);
        
        List<SVMXC__Service_Group_Skills__c> lstexpert =new List<SVMXC__Service_Group_Skills__c>();
        SVMXC__Service_Group_Skills__c expertise = new SVMXC__Service_Group_Skills__c();
        expertise.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise.SVMXC__Group_Member__c = tech.Id;
        expertise.SVMXC__Skill__c = skill.Id;
        expertise.SMAX_PS_Activity_Type__c = 'ALL';
        expertise.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise);
        
        SVMXC__Service_Group_Skills__c expertise2 = new SVMXC__Service_Group_Skills__c();
        expertise2.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise2.SVMXC__Group_Member__c = tech2.Id;
        expertise2.SVMXC__Skill__c = skill.Id;
        expertise2.SMAX_PS_Activity_Type__c = 'ALL';
        expertise2.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise2);
        
        SVMXC__Service_Group_Skills__c expertise3 = new SVMXC__Service_Group_Skills__c();
        expertise3.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise3.SVMXC__Group_Member__c = tech3.Id;
        expertise3.SVMXC__Skill__c = skill.Id;
        expertise3.SMAX_PS_Activity_Type__c = 'ALL';
        expertise3.SVMXC__Skill_Level__c = 5;
        lstexpert.add( expertise3);
        
        insert lstexpert;
        
        /*SVMXC__Service_Group_Skills__c expertise = SMAX_PS_TestDataFactory.createTestExpertise(tech, skill);
        
        update expertise;
        SVMXC__Service_Group_Skills__c expertise2 = SMAX_PS_TestDataFactory.createTestExpertise(tech2, skill);
        SVMXC__Service_Group_Skills__c expertise3 = SMAX_PS_TestDataFactory.createTestExpertise(tech3, skill);*/

        String locCode = 'TSTC01';
        SMAX_PS_Geography__c geo = SMAX_PS_TestDataFactory.createTestGeography(locCode);
        SMAX_PS_Geography_Technician__c gt1 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech, 1);
        SMAX_PS_Geography_Technician__c gt2 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech2, 2);
        SMAX_PS_Geography_Technician__c gt3 = SMAX_PS_TestDataFactory.createTestGeoTech(geo, tech3, 3);

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');

        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'Test Location';
        loc.SVMXC__Account__c = acct.Id;
        loc.SVMX_PS_External_ID__c = 'TESTLOC001';
        loc.SMAX_PS_LocationCode__c = locCode;
        loc.SMAX_PS_ShipTo__c = acct.Id;
        loc.SMAX_PS_Payer__c = acct.Id;
        loc.SMAX_PS_BillTo__c = acct.Id;
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        loc.SMAX_PS_MaintenancePlant__c = 'TS12';
        loc.SMAX_PS_SalesOrg__c = 'TS10';
        
        loc.SVMXC__Zip__c = '11111';
       insert loc;

        Product2 prd = new Product2(Name = 'TestProd', product_line__c = 'AA');
        insert prd;

       /* SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SVMXC__Product__c = prd.id;
        update ip;*/
        
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.SVMXC__Company__c = acct.Id;
        ip.SVMXC__Site__c = loc.Id;
        ip.SVMXC__Serial_Lot_Number__c = 'TESTX0000234001';
        ip.SMAX_PS_ModelSeries__c = modelSeries;
        if (prd != null)
            ip.SVMXC__Product__c = prd.Id;
        // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
        ip.SMAX_PS_Owned_By_Company__c = 'AES';
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        ip.SMAX_PS_MaintenancePlant__c = loc.SMAX_PS_MaintenancePlant__c;
        ip.SMAX_PS_SalesOrg__c = loc.SMAX_PS_SalesOrg__c;
        insert ip;
        
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
        insert wosToInsert;


        List<Event> evtsToInsert = new List<Event>();
        Event evt1 = new Event(OwnerId = usr1.id, StartDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(8,0,0,0)),
                EndDateTime = Datetime.newInstance(Date.today()+7, Time.newInstance(10,0,0,0))
        );
        evtsToInsert.add(evt1);
        insert evtsToInsert;


        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);
        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(7);
        // Simulate an update from SAP.. releasing the WO
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        wo.SVMXC__Latitude__c = 27.976124910626297;
        wo.SVMXC__Longitude__c = -82.50339341093408;
        wo.SMAX_PS_Geography__c = geo.id;
        wo.SVMXC__SM_Estimated_Duration__c = 3;
        wo.SMAX_PS_Is_Enterprise__c = false;
        update wo;

        List<SVMXC__Service_Order__c> woToAssign = new List<SVMXC__Service_Order__c>();
        woToAssign.add(wo);

        Test.startTest();


        SMAX_PS_AutoAssignmentObjectives.doAutoAssignment(wo, [Select id, SMAX_PS_Availability__c, SMAX_PS_Auto_Assignment_Default__c, SMAX_PS_Bundling__c , SMAX_PS_Continuity__c , SMAX_PS_Expertise__c , SMAX_PS_Proximity__c  from SMAX_PS_Assignment_Policy__mdt limit 1] ,true);

        Test.stopTest();
    }
    
}
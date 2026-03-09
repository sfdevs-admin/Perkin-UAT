@isTest(seeAllData=false)
private class SMAX_PS_Technician_UT 
{
    
    // SVMXCFG-647 - Added seeAllData=true to prevent managed package error on createTestUser(...)
    @isTest(seeAllData=true)
    static void testLocationLookup() 
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User techUser = new User(alias = 'testies', email = 'testiesMail@yahoo.com',
            emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testofferson',
            localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
            /*PKI_GBL_Job_Family__c = 'Service',*/ username = 'testiesMail@yahoo.com', communityNickname = 'TestieBoi');
        insert techUser;

        Test.startTest();

        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test Team';
        insert team;

        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.SMAX_PS_Plant__c = 'TS12';
        tech.SMAX_PS_LocationCode__c = 'T001';
        tech.SVMXC__Service_Group__c = team.Id;

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'ParentLocTest', 
            tech.SMAX_PS_Plant__c + tech.SMAX_PS_LocationCode__c, tech.SMAX_PS_LocationCode__c);

        tech.SVMXC__Salesforce_User__c = techUser.Id;
        insert tech;

        // 2/11/21 Tony - added as SMAX_PS_Geography__c is now required
        SMAX_PS_Geography__c geo1 = SMAX_PS_TestDataFactory.createTestGeography('Loc1');
        SMAX_PS_Geography__c geo2 = SMAX_PS_TestDataFactory.createTestGeography('Loc2');
        SMAX_PS_Geography__c geo3 = SMAX_PS_TestDataFactory.createTestGeography('Loc3');
        SMAX_PS_Geography__c geo4 = SMAX_PS_TestDataFactory.createTestGeography('Loc4');

        SMAX_PS_Geography_Technician__c geoTech1 = new SMAX_PS_Geography_Technician__c();
        geoTech1.SMAX_PS_Technician__c = tech.Id;
        geoTech1.SMAX_PS_Location__c = geo1.SMAX_PS_LocationCode__c; // 'TST10'
        geoTech1.SMAX_PS_Geography__c = geo1.Id;

        SMAX_PS_Geography_Technician__c geoTech2 = new SMAX_PS_Geography_Technician__c();
        geoTech2.SMAX_PS_Technician__c = tech.Id;
        geoTech2.SMAX_PS_Location__c = geo2.SMAX_PS_LocationCode__c; // 'TST12';
        geoTech2.SMAX_PS_Geography__c = geo2.Id;

        //ITSVXM-139 GEO3 and GEO4 coding Changes
        SMAX_PS_Geography_Technician__c geoTech3 = new SMAX_PS_Geography_Technician__c();
        geoTech3.SMAX_PS_Technician__c = tech.Id;
        geoTech3.SMAX_PS_Location__c = geo3.SMAX_PS_LocationCode__c; //'TST13';
        geoTech3.SMAX_PS_Geography__c = geo3.Id;
        
        SMAX_PS_Geography_Technician__c geoTech4 = new SMAX_PS_Geography_Technician__c();
        geoTech4.SMAX_PS_Technician__c = tech.Id;
        geoTech4.SMAX_PS_Location__c = geo4.SMAX_PS_LocationCode__c; //'TST14';
        geoTech4.SMAX_PS_Geography__c = geo4.Id;

        //End of changes ITSVXM-139 GEO3 and GEO4 coding Changes


        insert new List<SMAX_PS_Geography_Technician__c> { geoTech1, geoTech2,geoTech3,geoTech4 };

        Test.stopTest();

        // Validate that the tech.SVMXC__Inventory_Location__c is filled in
       /* tech = [SELECT Id, Name, SMAX_PS_Plant__c, SMAX_PS_LocationCode__c, SVMXC__Inventory_Location__c, 
            SVMXC__Salesforce_User__c, SMAX_PS_Technician_Geographies__c
            FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.Id];
        System.assertNotEquals(null, tech.SVMXC__Inventory_Location__c);
        System.assertNotEquals(null, tech.SMAX_PS_Technician_Geographies__c);*/

        // Validate that the loc.SVMXC__Service_Engineer__c is filled in
        loc = [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Service_Engineer__c 
            FROM SVMXC__Site__c WHERE Id = :loc.Id];
       // System.assertNotEquals(null, loc.SVMXC__Service_Engineer__c);

        delete geoTech2;
        //ITSVMX-139 Geo3 and Geo4 coding
        delete geoTech3;
        delete geoTech4;
         //End of ITSVMX-139 Geo3 and Geo4 coding

        tech = [SELECT Id, Name, SMAX_PS_Plant__c, SMAX_PS_LocationCode__c, SVMXC__Inventory_Location__c, 
            SVMXC__Salesforce_User__c, SMAX_PS_Technician_Geographies__c
            FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.Id];
        //System.assertEquals(geoTech1.SMAX_PS_Location__c, tech.SMAX_PS_Technician_Geographies__c);
    }
    
    static testMethod void testGeoTechBatch()
    {
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test Team';
        insert team;

        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.SMAX_PS_Plant__c = 'TS12';
        tech.SMAX_PS_LocationCode__c = 'T001';
        tech.SVMXC__Service_Group__c = team.Id;
        insert tech;

        // 2/11/21 Tony - added as SMAX_PS_Geography__c is now required
        SMAX_PS_Geography__c geo1 = SMAX_PS_TestDataFactory.createTestGeography('TST10');
        SMAX_PS_Geography__c geo2 = SMAX_PS_TestDataFactory.createTestGeography('TST12');
        SMAX_PS_Geography__c geo3 = SMAX_PS_TestDataFactory.createTestGeography('TST13');
        SMAX_PS_Geography__c geo4 = SMAX_PS_TestDataFactory.createTestGeography('TST14');

        SMAX_PS_Geography_Technician__c geoTech1 = new SMAX_PS_Geography_Technician__c();
        geoTech1.SMAX_PS_Technician__c = tech.Id;
        geoTech1.SMAX_PS_Location__c = geo1.SMAX_PS_LocationCode__c; // 'TST10'
        geoTech1.SMAX_PS_Geography__c = geo1.Id;

        SMAX_PS_Geography_Technician__c geoTech2 = new SMAX_PS_Geography_Technician__c();
        geoTech2.SMAX_PS_Technician__c = tech.Id;
        geoTech2.SMAX_PS_Location__c = geo2.SMAX_PS_LocationCode__c; // 'TST12'
        geoTech2.SMAX_PS_Geography__c = geo2.Id;

        // Added ITSVMX-139 for GE03 and GEO4 fields
        SMAX_PS_Geography_Technician__c geoTech3 = new SMAX_PS_Geography_Technician__c();
        geoTech3.SMAX_PS_Technician__c = tech.Id;
        geoTech3.SMAX_PS_Location__c = geo3.SMAX_PS_LocationCode__c; // 'TST13'
        geoTech3.SMAX_PS_Geography__c = geo3.Id;

        SMAX_PS_Geography_Technician__c geoTech4 = new SMAX_PS_Geography_Technician__c();
        geoTech4.SMAX_PS_Technician__c = tech.Id;
        geoTech4.SMAX_PS_Location__c = geo4.SMAX_PS_LocationCode__c; // 'TST14'
        geoTech4.SMAX_PS_Geography__c = geo4.Id;

        //END of code by sarala
        insert new List<SMAX_PS_Geography_Technician__c> { geoTech1, geoTech2, geoTech3, geoTech4 };

        Test.startTest();

        new SMAX_PS_TechnicianGeoBatch().execute(null);
//        SMAX_PS_TechnicianGeoBatch b1 = new SMAX_PS_TechnicianGeoBatch();
//        Database.executeBatch(b1);
        new SMAX_PS_TechnicianLocationBatch().execute(null);
        Test.stopTest();
    }

    // SVMXCFG-1136 additional logic for "Tech Geo 4" field
    //static testMethod void testGeoTech2() Commented for ITSVMX-139
    static testMethod void testGeoTech4()
    {
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test Team';
        insert team;

        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.SMAX_PS_Plant__c = 'TS12';
        tech.SMAX_PS_LocationCode__c = 'T001';
        tech.SVMXC__Service_Group__c = team.Id;
        insert tech;

        // 2/11/21 Tony - added as SMAX_PS_Geography__c is now required for SMAX_PS_Geography_Technician__c records
        List<SMAX_PS_Geography__c> geos = new List<SMAX_PS_Geography__c>();
        for (Integer i = 10; i < 180; i++) //ITSVMX-139
        {
            SMAX_PS_Geography__c geo = new SMAX_PS_Geography__c();
            geo.Name = 'TESTLOC' + i;
            geo.SMAX_PS_LocationCode__c = 'TESTLOC' + i;
            geos.add(geo);
        }
        insert geos;

        List<SMAX_PS_Geography_Technician__c> geoTechs = new List<SMAX_PS_Geography_Technician__c>();
        //for (Integer i = 10; i < 60; i++) ITSVMX-139
       for (Integer i = 10; i < 180; i++) //ITSVMX-139
        {
            SMAX_PS_Geography_Technician__c geoTech = new SMAX_PS_Geography_Technician__c();
            geoTech.SMAX_PS_Technician__c = tech.Id;
            geoTech.SMAX_PS_Location__c = 'TESTLOC' + i;
            geoTech.SMAX_PS_Geography__c = geos[i-10].Id;
            geoTechs.add(geoTech);
        }

        Test.startTest();

        insert geoTechs;

        SVMXC__Service_Group_Members__c result = [SELECT Id, Name,
                SMAX_PS_Technician_Geographies__c, SMAX_PS_Technician_Geographies_2__c,
                SMAX_PS_Technician_Geographies_3__c, SMAX_PS_Technician_Geographies_4__c
        FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.Id];
        System.debug('RESULT = ' + result);

        System.assert(String.isNotBlank(result.SMAX_PS_Technician_Geographies__c));
        System.assert(String.isNotBlank(result.SMAX_PS_Technician_Geographies_2__c));
        System.assert(String.isNotBlank(result.SMAX_PS_Technician_Geographies_3__c));
        System.assert(String.isNotBlank(result.SMAX_PS_Technician_Geographies_4__c));

        Test.stopTest();
    }

    // ITSFDC-509 Lookup the Depot Queue Id
    static testMethod void testDepotQueue()
    {
        Group g1 = new Group(Name='TST FOODS TS12 Depot', DeveloperName='TST_FOODS_TS12_Depot', Type='Queue');
        insert g1;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'SVMXC__Service_Order__c');
            insert q1;
//          QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
//          insert testQueue;
        }

        Test.startTest();

        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'Test Depot Team';
        insert team;

        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.SMAX_PS_Plant__c = 'TS12';
        tech.SMAX_PS_LocationCode__c = 'T001';
        tech.SVMXC__Service_Group__c = team.Id;
        tech.BD_Depot_Queue_Name__c = g1.DeveloperName;
        tech.SVMXC__Role__c = 'Depot Queue';
        insert tech;

        Test.stopTest();

        SVMXC__Service_Group_Members__c techResult = [SELECT Id, Name, BD_Depot_Queue_Id__c
            FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.Id];
        System.assertEquals(g1.Id, techResult.BD_Depot_Queue_Id__c);

    }

    @isTest(seeAllData=false)
    static void testTerritoryGeographies() {
        SVMXC__Territory__c region = new SVMXC__Territory__c(Name='Atlantis', SVMXC__Territory_Code__c='ATLTS',
            SVMXC__Parent_Territory__c = null, BD_Type__c = 'Super Territory');
        insert region;
        SVMXC__Territory__c subRegion = new SVMXC__Territory__c(Name='Western Nowhere', SVMXC__Territory_Code__c='WSTNW',
            SVMXC__Parent_Territory__c = region.Id, BD_Type__c = 'Sub Territory');
        insert subRegion;
        SVMXC__Territory__c country = new SVMXC__Territory__c(Name='Wakanda', SVMXC__Territory_Code__c='WKNDA',
            SVMXC__Parent_Territory__c = subRegion.Id, BD_Type__c = 'Country');
        SVMXC__Territory__c country2 = new SVMXC__Territory__c(Name='Gotham', SVMXC__Territory_Code__c='GOTHM',
            SVMXC__Parent_Territory__c = subRegion.Id, BD_Type__c = 'Country');
        insert new List<SVMXC__Territory__c> { country, country2 };
        SVMXC__Territory__c territory1 = new SVMXC__Territory__c(Name='Western Wakanda', SVMXC__Territory_Code__c='WWAK',
            SVMXC__Parent_Territory__c = country.Id, BD_Type__c = 'Super District');
        SVMXC__Territory__c territory2 = new SVMXC__Territory__c(Name='Eastern Wakanda', SVMXC__Territory_Code__c='EWAK',
            SVMXC__Parent_Territory__c = country.Id, BD_Type__c = 'Super District');
        SVMXC__Territory__c territory3 = new SVMXC__Territory__c(Name='Gotham City', SVMXC__Territory_Code__c='GTMC',
            SVMXC__Parent_Territory__c = country2.Id, BD_Type__c = 'Super District');
        insert new List<SVMXC__Territory__c> { territory1, territory2, territory3 };

        SMAX_PS_Geography__c geo1a = new SMAX_PS_Geography__c(Name='WWAK_A', SMAX_PS_LocationCode__c='WWAK_A',
            BD_Territory__c=territory1.Id);
        SMAX_PS_Geography__c geo1b = new SMAX_PS_Geography__c(Name='WWAK_B', SMAX_PS_LocationCode__c='WWAK_B',
            BD_Territory__c=territory1.Id);
        SMAX_PS_Geography__c geo1c = new SMAX_PS_Geography__c(Name='WWAK_C', SMAX_PS_LocationCode__c='WWAK_C',
                BD_Territory__c=territory1.Id);
        SMAX_PS_Geography__c geo2a = new SMAX_PS_Geography__c(Name='EWAK_A', SMAX_PS_LocationCode__c='EWAK_A',
            BD_Territory__c=territory2.Id);
        SMAX_PS_Geography__c geo3 = new SMAX_PS_Geography__c(Name='NOWH_1', SMAX_PS_LocationCode__c='NOWH_1',
            BD_Territory__c=territory3.Id);
        insert new List<SMAX_PS_Geography__c> { geo1a, geo1b, geo1c, geo2a, geo3 };

        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c(Name='Test Team');
        insert team;

        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c(Name='Chadwick Boseman',
            SMAX_PS_Plant__c='TS12', SMAX_PS_LocationCode__c = 'T001',
            SVMXC__Service_Group__c = team.Id, SVMXC__Service_Territory__c = territory1.Id);
        insert tech;

        // This should be allowed, geo's under the assigned Territory
        SMAX_PS_Geography_Technician__c geoTech1a = new SMAX_PS_Geography_Technician__c(SMAX_PS_Technician__c = tech.Id,
            SMAX_PS_Geography__c=geo1a.Id, SMAX_PS_Location__c = geo1a.SMAX_PS_LocationCode__c);
        SMAX_PS_Geography_Technician__c geoTech1b = new SMAX_PS_Geography_Technician__c(SMAX_PS_Technician__c = tech.Id,
            SMAX_PS_Geography__c=geo1b.Id, SMAX_PS_Location__c = geo1b.SMAX_PS_LocationCode__c);
        insert new List<SMAX_PS_Geography_Technician__c> { geoTech1a, geoTech1b };

        SMAX_PS_Geography_Technician__c geoTech2 = new SMAX_PS_Geography_Technician__c(SMAX_PS_Technician__c = tech.Id,
            SMAX_PS_Geography__c=geo2a.Id, SMAX_PS_Location__c = geo2a.SMAX_PS_LocationCode__c);
        try {
            insert geoTech2;
            System.assert(false, 'GeoTech to Geo2a should not be allowed');
        } catch (Exception e1) {
            String msg = e1.getMessage();
            System.debug('ERROR CAUGHT: ' + msg);
            System.assert(msg.contains('Illegal') && msg.contains(geo2a.SMAX_PS_LocationCode__c));
        }

        SMAX_PS_Geography_Technician__c geoTechGrand = new SMAX_PS_Geography_Technician__c(SMAX_PS_Technician__c = tech.Id,
            SMAX_PS_Geography__c=geo3.Id, SMAX_PS_Location__c = geo3.SMAX_PS_LocationCode__c);
        try {
            insert geoTechGrand;
            System.assert(false, 'GeoTech to Geo3 should not be allowed');
        } catch (Exception e1) {
            String msg = e1.getMessage();
            System.debug('ERROR CAUGHT: ' + msg);
            System.assert(msg.contains('Illegal') && msg.contains(geo3.SMAX_PS_LocationCode__c));
        }

        Test.startTest();

        // Change the Technician to the whole Region..
        tech.SVMXC__Service_Territory__c = region.Id;
        update tech;

        // Now both should be allowed
        insert new List<SMAX_PS_Geography_Technician__c> { geoTech2, geoTechGrand };

        List<SMAX_PS_Geography_Technician__c> results = [SELECT Id, Name FROM SMAX_PS_Geography_Technician__c
            WHERE SMAX_PS_Technician__c = :tech.Id];
        System.assertEquals(4, results.size());

        // Reset the Territory to test the batch job..
        tech.SVMXC__Service_Territory__c = null;
        update tech;

        new SMAX_PS_TechnicianTerritoryBatch().execute(null);

        Test.stopTest();

        SVMXC__Service_Group_Members__c result = [SELECT Id, Name, SVMXC__Service_Territory__c
            FROM SVMXC__Service_Group_Members__c WHERE Id = :tech.Id];
        System.assertEquals(subRegion.Id, result.SVMXC__Service_Territory__c);
        
        SMAX_PS_DispatchManagementDashboard.CheckboxGrid grid = SMAX_PS_DispatchManagementDashboard.loadManageGeoGrid(territory1.Id);
        //SMAX_PS_DispatchManagementTemp.CheckboxGrid grid = SMAX_PS_DispatchManagementTemp.loadManageGeoGrid(territory1.Id);
        System.debug('Result GeoTech GRID: ' + JSON.serialize(grid));
    }
}
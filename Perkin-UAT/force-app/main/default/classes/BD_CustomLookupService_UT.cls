/**
 * Created by tony on 3/25/21.
 */

@IsTest
private class BD_CustomLookupService_UT {

    @TestSetup
    static void setupTestData() {
        System.debug('Setting up test data');

        //create territories
        List<SVMXC__Territory__c> territories = new List<SVMXC__Territory__c>();
        SVMXC__Territory__c territory1 = new SVMXC__Territory__c( Name='Americas', BD_Type__c='Super Territory' );
        territories.add(territory1);

        SVMXC__Territory__c territory2 = new SVMXC__Territory__c( Name='United States', BD_Type__c='Country' );
        territories.add(territory2);

        SVMXC__Territory__c territory3 = new SVMXC__Territory__c( Name='US Rockies', BD_Type__c='Super District' );
        territories.add(territory3);

        SVMXC__Territory__c territory4 = new SVMXC__Territory__c( Name='United Kingdom', BD_Type__c='Sub Territory' );
        territories.add(territory4);
        insert territories;
        System.debug('Inserted territories: ' + territories);

        territory2.SVMXC__Parent_Territory__c = territory1.Id;
        update territory2;

        //create users
        User user1 = SMAX_PS_TestDataFactory.createTestUser('Testy');

        //create technicians and service teams
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Billable Service Team', null, 'Tech Name1', 'Plant1', 'Loc1');
        tech1.SVMXC__Service_Territory__c = territory3.Id;
        tech1.SMAX_PS_Technician_Geographies__c = 'USROCK';
        update tech1;
        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('US Enterprise - GSK', null, 'Tech Name2', 'Plant2', 'Loc2');
        SVMXC__Service_Group_Members__c tech3 = SMAX_PS_TestDataFactory.createTestTechnician('US DX West', null, 'Tech Name3', 'Plant3', 'Loc3');
        SVMXC__Service_Group_Members__c tech4 = SMAX_PS_TestDataFactory.createTestTechnician('Puerto Rico - Enterprise', null, 'Tech Name4', 'Plant4', 'Loc4');

        //create accounts
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Account 1', 'Acc1');

        //create locations
        SVMXC__Site__c location1 = SMAX_PS_TestDataFactory.createTestLocation(acct, 'US Loc1', 'Loc1', 'Loc1');
        SVMXC__Site__c location2 = SMAX_PS_TestDataFactory.createTestLocation(acct, 'US Loc2', 'Loc2', 'Loc2');

        //create geography
        SMAX_PS_Geography__c geo1 = SMAX_PS_TestDataFactory.createTestGeography('Loc1');
        geo1.BD_Territory__c = territory3.Id;
        update geo1;

        SMAX_PS_Geography__c geo2 = SMAX_PS_TestDataFactory.createTestGeography('Loc2');
        geo2.BD_Territory__c = territory3.Id;
        update geo2;

        SMAX_PS_Geography__c geo3 = SMAX_PS_TestDataFactory.createTestGeography('Loc3');
        geo3.BD_Territory__c = territory3.Id;
        update geo3;

        SMAX_PS_Geography__c geo4 = SMAX_PS_TestDataFactory.createTestGeography('Loc4');
        // don't set a territory for this geo

        //create dispatcher access
        SVMXC__Dispatcher_Access__c dispatcherAccess = new SVMXC__Dispatcher_Access__c(SVMXC__Dispatcher__c=user1.Id, SVMXC__Territory__c=territory3.Id);
        insert dispatcherAccess;

        //create geo tech
        SMAX_PS_Geography_Technician__c geoTech = SMAX_PS_TestDataFactory.createTestGeoTech(geo2, tech1, 1);

    }

    @IsTest
    static void test_searchTechnicians() {

        List<Id> fixedSearchResults = new List<Id>();
        List<SVMXC__Service_Group_Members__c> techs = [
                SELECT Id FROM SVMXC__Service_Group_Members__c
        ];
        for (SVMXC__Service_Group_Members__c tech :techs) {
            fixedSearchResults.add(tech.Id);
        }

        List<SVMXC__Site__c> locs = [
                SELECT Id FROM SVMXC__Site__c
        ];
        for (SVMXC__Site__c loc :locs) {
            fixedSearchResults.add(loc.Id);
        }

        Test.setFixedSearchResults(fixedSearchResults);

        List<String> selectedIds = new List<String> {techs[1].Id};
        System.debug('selectedIds: ' + selectedIds);
        List<BD_CustomLookupService.LookupSearchResult> lookupSearchResults = BD_CustomLookupService.searchTechnicians('US', selectedIds);
        System.debug('lookupSearchResults: ' + lookupSearchResults);
        
        System.assertEquals(8, lookupSearchResults.size(), 'There should be 8 search results returned.');

    }
}
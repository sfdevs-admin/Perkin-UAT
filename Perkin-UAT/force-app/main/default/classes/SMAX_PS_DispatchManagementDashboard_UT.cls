/**
 * Created by tony on 1/21/21.
 */

@IsTest
private class SMAX_PS_DispatchManagementDashboard_UT {

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
    static void test_loadPermissions() {

        //setup data

        //validate
        Test.startTest();

        SMAX_PS_DispatchManagementDashboard.DispatchPermissions permissions = SMAX_PS_DispatchManagementDashboard.loadPermissions();
        System.debug('permissions: ' + JSON.serializePretty(permissions));
        //System.assert(permissions.editDispatchers == true, 'You have not assigned the Custom Permission "SMAX_DispatchMgmt_EditDispatchers" to yourself');
        //System.assert(permissions.editTechnicians == true, 'You have not assigned the Custom Permission "SMAX_DispatchMgmt_EditTechnicians" to yourself');

        Test.stopTest();

    }

    @IsTest
    static void test_searchTerritories() {

        //setup test data
        List<String> selectedIds = new List<String>();
        List<Id> fixedSearchResults = new List<Id>();

        // In order to test functionality that uses a SOSL search query a unit test needs to setup Test.setFixedSearchResults()
        List<SVMXC__Territory__c> territories = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name LIKE 'United%'];
        for (SVMXC__Territory__c territory :territories) {
            fixedSearchResults.add(territory.Id);
            if (territory.Name == 'United Kingdom') {
                selectedIds.add(territory.Id);
            }
        }

        List<SMAX_PS_Geography__c> geos = [SELECT Id, Name, SMAX_PS_LocationCode__c, BD_Territory__c FROM SMAX_PS_Geography__c LIMIT 1];
        for (SMAX_PS_Geography__c geo :geos) {
            fixedSearchResults.add(geo.Id);
        }

        List<SVMXC__Service_Group_Members__c> techs = [SELECT Id, Name, SVMXC__Service_Territory__c FROM SVMXC__Service_Group_Members__c LIMIT 1];
        for (SVMXC__Service_Group_Members__c tech :techs) {
            fixedSearchResults.add(tech.Id);
        }

        List<User> users = [SELECT Id, Name FROM User LIMIT 1];
        for (User user :users) {
            fixedSearchResults.add(user.Id);
        }

        Test.setFixedSearchResults(fixedSearchResults);


        //validate
        Test.startTest();

        List<BD_CustomLookupService.LookupSearchResult> wrappers = SMAX_PS_DispatchManagementDashboard.searchTerritories('United', selectedIds);
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(4, wrappers.size(), 'There should be 4 Territories returned');

        Test.stopTest();

    }

    @IsTest
    static void test_searchGeoCheckboxTerritories() {

        //setup data
        List<String> selectedIds = new List<String>();
        List<Id> fixedSearchResults = new List<Id>();

        // In order to test functionality that uses a SOSL search query a unit test needs to setup Test.setFixedSearchResults()
        List<SVMXC__Territory__c> territories = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name LIKE 'United%'];
        for (SVMXC__Territory__c territory :territories) {
            fixedSearchResults.add(territory.Id);
            if (territory.Name == 'United Kingdom') {
                selectedIds.add(territory.Id);
            }
        }
        Test.setFixedSearchResults(fixedSearchResults);

        //validate
        Test.startTest();

        List<BD_CustomLookupService.LookupSearchResult> searchResults = SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTerritories('United', selectedIds);
        System.debug('searchResults: ' + JSON.serializePretty(searchResults));
        //System.assertEquals(1, searchResults.size(), 'Expected 1 records returned');

        Test.stopTest();
    }

    @IsTest
    static void test_searchGeoCheckboxTeams() {

        //setup data
        List<String> selectedIds = new List<String>();
        List<Id> fixedSearchResults = new List<Id>();

        // In order to test functionality that uses a SOSL search query a unit test needs to setup Test.setFixedSearchResults()
        List<SVMXC__Service_Group__c> teams = [SELECT Id, Name, SMAX_PS_Is_Enterprise__c FROM SVMXC__Service_Group__c WHERE Name LIKE 'US %'];
        for (SVMXC__Service_Group__c team :teams) {
            fixedSearchResults.add(team.Id);
            if (team.Name == 'US Enterprise - GSK') {
                selectedIds.add(team.Id);
            }
        }
        Test.setFixedSearchResults(fixedSearchResults);

        //validate
        Test.startTest();

        List<BD_CustomLookupService.LookupSearchResult> searchResults = SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTeams('US ', selectedIds);
        System.debug('searchResults: ' + JSON.serializePretty(searchResults));
        //System.assertEquals(1, searchResults.size(), 'Expected 1 records returned');

        Test.stopTest();
    }

    @IsTest
    static void test_buildWrappers() {

        //setup test data

        //validate
        Test.startTest();

        List<SMAX_PS_DispatchManagementDashboard.TerritoryHierarchyWrapper> wrappers = SMAX_PS_DispatchManagementDashboard.buildWrappers();
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(3, wrappers.size(), 'There should be 3 Top Level Territories returned, the 4th Territory should be a child');

        Test.stopTest();

    }

    @IsTest
    static void test_buildTreeFromSearch() {

        //setup test data
        List<Id> territoryIds = new List<Id>();

        List<SVMXC__Territory__c> territories = [SELECT Id, Name, BD_Type__c FROM SVMXC__Territory__c];
        for (SVMXC__Territory__c territory :territories) {
            territoryIds.add(territory.Id);
        }

        List<SMAX_PS_Geography__c> geos = [SELECT Id, Name, SMAX_PS_LocationCode__c, BD_Territory__c FROM SMAX_PS_Geography__c];
        for (SMAX_PS_Geography__c geo :geos) {
            territoryIds.add(geo.Id);
        }

        List<SVMXC__Service_Group_Members__c> techs = [SELECT Id, Name, SVMXC__Service_Territory__c FROM SVMXC__Service_Group_Members__c];
        for (SVMXC__Service_Group_Members__c tech :techs) {
            territoryIds.add(tech.Id);
        }

        List<User> users = [SELECT Id, Name FROM User];
        for (User user :users) {
            territoryIds.add(user.Id);
        }

        //validate
        Test.startTest();

        List<SMAX_PS_DispatchManagementDashboard.TerritoryHierarchyWrapper> wrappers = SMAX_PS_DispatchManagementDashboard.buildTreeFromSearch(territoryIds);
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(3, wrappers.size(), 'There should be 3 Territories returned, the 4th Territory should be a child');

        Test.stopTest();

    }

    @IsTest
    static void test_getUnassignedGeographiesCount() {

        Test.startTest();

        Integer count = SMAX_PS_DispatchManagementDashboard.getUnassignedGeographiesCount();
        System.debug('Unassigned Geographies count: ' + count);
        //System.assertEquals(1, count, 'There should only be 1 unassigned geography');

        Test.stopTest();
    }

    @IsTest
    static void test_buildDispatcherDataTable() {

        //setup test data
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'US Rockies'];
        String territoryId = territory.Id;

        //validate
        Test.startTest();

        List<SMAX_PS_DispatchManagementDashboard.DispatcherWrapper> wrappers = SMAX_PS_DispatchManagementDashboard.buildDispatcherDataTable(territoryId);
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(1, wrappers.size(), 'There should be 1 Dispatcher');

        Test.stopTest();

    }

    @IsTest
    static void test_buildTechnicianDataTable() {

        //setup test data
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'US Rockies'];
        String territoryId = territory.Id;

        //validate
        Test.startTest();

        List<SMAX_PS_DispatchManagementDashboard.TechnicianWrapper> wrappers = SMAX_PS_DispatchManagementDashboard.buildTechnicianDataTable(territoryId);
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(1, wrappers.size(), 'There should be 1 Technician');

        Test.stopTest();

    }

    @IsTest
    static void test_saveManageGeoGrid() {

        //setup test data
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'US Rockies'];
        String territoryId = territory.Id;

        SMAX_PS_DispatchManagementDashboard.CheckboxGrid checkboxGrid = SMAX_PS_DispatchManagementDashboard.loadManageGeoGrid(territoryId);
        System.debug('checkboxGrid: ' + JSON.serializePretty(checkboxGrid));
       // System.assertEquals(1, checkboxGrid.rowValues.size(), 'There should be 1 rowValue');

        String updates = JSON.serialize(checkboxGrid.grid);


        //validate
        Test.startTest();

        String result = SMAX_PS_DispatchManagementDashboard.saveManageGeoGrid(territoryId, updates);
        System.debug('result: ' + result);
       // System.assertEquals('Success', result, 'If changes are saved the result should be "Success"');

        Test.stopTest();

    }

    @IsTest
    static void test_saveManageDispatchersGrid() {

        //setup test data
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'US Rockies'];
        String territoryId = territory.Id;

        SMAX_PS_DispatchManagementDashboard.CheckboxGrid checkboxGrid = SMAX_PS_DispatchManagementDashboard.loadManageDispatchersGrid(territoryId);
        System.debug('checkboxGrid: ' + JSON.serializePretty(checkboxGrid));
        //System.assertEquals(1, checkboxGrid.rowValues.size(), 'There should be 1 rowValue');

        String updates = JSON.serialize(checkboxGrid.grid);


        //validate
        Test.startTest();

        String result = SMAX_PS_DispatchManagementDashboard.saveManageDispatchersGrid(territoryId, updates);
        System.debug('result: ' + result);
       // System.assertEquals('Success', result, 'If changes are saved the result should be "Success"');

        Test.stopTest();

    }

    @IsTest
    static void test_saveTechnicianEditDetails() {

        //setup test data

        SVMXC__Service_Group_Members__c tech = [SELECT Id, Name, SMAX_PS_LocationCode__c FROM SVMXC__Service_Group_Members__c WHERE SMAX_PS_LocationCode__c = 'Loc1'];
        String techId = tech.Id;

        //validate
        Test.startTest();

        SMAX_PS_DispatchManagementDashboard.TechnicianDetails techDetails = SMAX_PS_DispatchManagementDashboard.loadTechnicianEditDetails(techId);
        System.debug('techDetails: ' + JSON.serializePretty(techDetails));
        //System.assertEquals(3, techDetails.technicianGeographiesList.size(), 'There should be 3 technicianGeographiesList objects');

        //make changes that will cause 1 to be added and 1 to be deleted
        techDetails.technicianGeographiesList[0].assignedToTech = true;
        techDetails.technicianGeographiesList[1].assignedToTech = false;

        String result = SMAX_PS_DispatchManagementDashboard.saveTechnicianEditDetails(techDetails);
        System.debug('result: ' + result);
        //System.assertEquals('Success', result, 'If save executed without issues, then the return result should be "Success"');

        Test.stopTest();

    }

    @IsTest
    static void test_saveGeoCheckbox() {

        //setup test data
        SVMXC__Service_Group_Members__c tech = [SELECT Id, Name, SMAX_PS_LocationCode__c FROM SVMXC__Service_Group_Members__c WHERE SMAX_PS_LocationCode__c = 'Loc1'];
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'US Rockies'];
        SVMXC__Service_Group__c team = [SELECT Id, Name FROM SVMXC__Service_Group__c WHERE Name = 'Billable Service Team'];

        //validate
        Test.startTest();

        SMAX_PS_DispatchManagementDashboard.GeoCheckbox geoCheckbox = SMAX_PS_DispatchManagementDashboard.loadGeoCheckbox(tech.Id, territory.Id);
        System.debug('geoCheckbox: ' + JSON.serializePretty(geoCheckbox));
        //System.assertEquals('US Rockies', geoCheckbox.territoryName, 'Should only find "US Rockies" Territory');

        List<SMAX_PS_DispatchManagementDashboard.ValueLabel> options = geoCheckbox.options;
        List<String> values = geoCheckbox.values;

        String result = SMAX_PS_DispatchManagementDashboard.saveGeoCheckbox(tech.Id, territory.Id, team.Id, options, values);
        System.debug('result: ' + result);
        //System.assertEquals('Success', result, 'If save executed without issues, then the return result should be "Success"');

        Test.stopTest();

    }

    @IsTest
    static void test_buildTeams() {

        //setup test data

        //validate
        Test.startTest();

        List<SMAX_PS_DispatchManagementDashboard.TeamWrapper> wrappers = SMAX_PS_DispatchManagementDashboard.buildTeams();
        System.debug('wrappers: ' + JSON.serializePretty(wrappers));
        //System.assertEquals(4, wrappers.size(), 'There should be 4 Service Team records');

        Test.stopTest();

    }

    @IsTest
    static void test_selectedTerrIdsTeamIdsInDispatcherAccess() {

        //setup test data
        User user = [SELECT Id, Name FROM User WHERE Alias = 'Testy'];

        //validate
        Test.startTest();

        SMAX_PS_DispatchManagementDashboard.DispatcherAccessWrapper wrapper = SMAX_PS_DispatchManagementDashboard.selectedTerrIdsTeamIdsInDispatcherAccess(user.Id);
        System.debug('wrapper: ' + JSON.serializePretty(wrapper));
        //System.assert(wrapper.selectedTeamIds[0] == null, 'selectedTeamIds should have a value');
        //System.assert(wrapper.selectedTerritoryIds[0] != null, 'selectedTerritoryIds should have a value');

        Test.stopTest();

    }

    @IsTest
    static void test_getChildTerritoryIds() {

        //setup test data
        SVMXC__Territory__c territory = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Name = 'Americas'];
        String territoryId = territory.Id;

        //validate
        Test.startTest();

        List<Id> childIds = SMAX_PS_DispatchManagementDashboard.getChildTerritoryIds(territoryId);
        System.debug('childIds: ' + childIds);
        System.assertEquals(2, childIds.size(), 'There should be 2 Territories, the Parent and it\'s Child');

        List<SVMXC__Territory__c> childTerritories = [SELECT Id, Name FROM SVMXC__Territory__c WHERE Id IN :childIds];
        System.debug('childTerritories: ' + JSON.serializePretty(childTerritories));

        Test.stopTest();

    }

    @IsTest
    static void test_saveDispatcherEditDetails() {

        // Setup Data
        UserRole userRole = new UserRole();
        userRole.DeveloperName = 'TestingRole';
        userRole.Name = 'Testing Role';
        insert userRole;

        User user = new User();
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SVMX PS - Customer Care'].Id;
        user.LastName = 'last';
        user.Email = 'Cpt.Awesome@awesomesauce123.com';
        user.Username = 'Cpt.Awesome@pkifull.com';
        user.CompanyName = 'Testing Co 123';
        user.Title = 'Captian';
        user.Alias = 'alias';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.UserRoleId = userRole.Id;
        insert user;

        System.runAs(user) {
            SVMXC__Service_Group__c team1 = new SVMXC__Service_Group__c();
            team1.Name = 'Test Team1';
            insert team1;

            SVMXC__Service_Group__c team2 = new SVMXC__Service_Group__c();
            team2.Name = 'Test Team2';
            insert team2;

            SVMXC__Territory__c territory1 = new SVMXC__Territory__c();
            territory1.Name = 'Test Territory1';
            insert territory1;

            SVMXC__Territory__c territory2 = new SVMXC__Territory__c();
            territory2.Name = 'Test Territory2';
            insert territory2;

            SVMXC__Dispatcher_Access__c dispatcherAccess1 = new SVMXC__Dispatcher_Access__c();
            dispatcherAccess1.SVMXC__Dispatcher__c = user.Id;
            dispatcherAccess1.SVMXC__Service_Team__c = team1.Id;
            insert dispatcherAccess1;

            SVMXC__Dispatcher_Access__c dispatcherAccess2 = new SVMXC__Dispatcher_Access__c();
            dispatcherAccess2.SVMXC__Dispatcher__c = user.Id;
            dispatcherAccess2.SVMXC__Territory__c = territory1.Id;
            insert dispatcherAccess2;


            Test.startTest();

            // Call the method being tested
            List<String> newTerritoryIds = new List<String>{
                    territory2.Id
            };
            List<String> newTeamIds = new List<String>{
                    team2.Id
            };
            String result = SMAX_PS_DispatchManagementDashboard.saveDispatcherEditDetails(user.Id, newTerritoryIds, newTeamIds);
            System.debug('result: ' + result);

            Test.stopTest();

            // Validate Data
            List<SVMXC__Dispatcher_Access__c> dispatcherAccessList1 = [
                    SELECT Id, SVMXC__Dispatcher__c, SVMXC__Territory__c, SVMXC__Service_Team__c, SMAX_PS_External_Id__c
                    FROM SVMXC__Dispatcher_Access__c
                    WHERE SVMXC__Dispatcher__c = :user.Id
                    AND (SVMXC__Territory__c = :territory1.Id OR SVMXC__Service_Team__c = :team1.Id)
            ];
            System.debug('dispatcherAccessList1: ' + dispatcherAccessList1);
            //System.assert(dispatcherAccessList1.size() == 0, 'These records should have been removed');

            List<SVMXC__Dispatcher_Access__c> dispatcherAccessList2 = [
                    SELECT Id, SVMXC__Dispatcher__c, SVMXC__Territory__c, SVMXC__Service_Team__c, SMAX_PS_External_Id__c
                    FROM SVMXC__Dispatcher_Access__c
                    WHERE SVMXC__Dispatcher__c = :user.Id
                    AND (SVMXC__Territory__c = :territory2.Id OR SVMXC__Service_Team__c = :team2.Id)
            ];
            System.debug('dispatcherAccessList2: ' + dispatcherAccessList2);
            //System.assert(dispatcherAccessList2.size() == 2, 'These records should have been added');
        }
    }
}
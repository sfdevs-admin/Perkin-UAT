/**
 * Created by frankvanloon on 12/16/20.
 */

@IsTest
private class SMAX_PS_InventoryCount_UT {
    @IsTest
    static void testInventoryCount()
    {
        // SVMXCFG-647 - Cannot create new User due to managed package error
        //User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        //Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
        loc.SVMXC__Service_Engineer__c = techUser.Id;
        update loc;

        Product2 p = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'Test');
        SVMXC__Product_Stock__c ps1 = SMAX_PS_TestDataFactory.createTestProductStock(loc, p, 'Available', 4);

        Test.startTest();

        // Fill in SMAX_PS_RequestedFrom__c (Location)
        SMAX_PS_InventoryCount__c ic = new SMAX_PS_InventoryCount__c();
        ic.SMAX_PS_Status__c = 'Open';
        ic.SMAX_PS_RequestedFrom__c = loc.Id;
        ic.OwnerId = techUser.Id;
        insert ic;

        // Assert SMAX_PS_RequestedTechnician__c is not blank (Technician)
        SMAX_PS_InventoryCount__c icResult = [SELECT Id, Name, SMAX_PS_RequestedTechnician__c FROM SMAX_PS_InventoryCount__c WHERE Id = :ic.Id];
       // System.assertEquals(tech.Id, icResult.SMAX_PS_RequestedTechnician__c);

        // Lines.. Assert SMAX_PS_ProductStock__c is auto-filled based on SMAX_PS_Product__c
        SMAX_PS_InventoryCountLine__c line1 = new SMAX_PS_InventoryCountLine__c();
        line1.SMAX_PS_InventoryCount__c = ic.Id;
        line1.SMAX_PS_Product__c = p.Id;
        insert line1;

        SMAX_PS_InventoryCountLine__c lineResult = [SELECT Id, SMAX_PS_ProductStock__c FROM SMAX_PS_InventoryCountLine__c WHERE Id = :line1.Id];
       // System.assertEquals(ps1.Id, lineResult.SMAX_PS_ProductStock__c);

        line1.SMAX_PS_Is_Serialized__c = true;
        line1.SMAX_PS_Expected_Serial_Numbers__c = 'ABC123,ABC234';
        line1.SMAX_PS_CountedQty__c = 3;
        Database.SaveResult r1 = Database.update(line1, false);
        //System.assert(r1.isSuccess() == false); // Actual Serials is blank

        line1.SMAX_PS_Actual_Serial_Numbers__c = 'ABC123,ABC098';
        Database.SaveResult r2 = Database.update(line1, false);
        //System.assert(r2.isSuccess() == false); // Wrong number

        line1.SMAX_PS_Actual_Serial_Numbers__c = 'ABC123,ABC234,ABC098';
        Database.SaveResult r3 = Database.update(line1, false);
        //System.assert(r3.isSuccess() == true);

        // Change SMAX_PS_Status__c == 'Confirmed'
        ic.SMAX_PS_Status__c = 'Confirmed';
        update ic;

        // Change SMAX_PS_Status__c == 'Approved' .. send event
        ic.SMAX_PS_Status__c = 'Approved';
        update ic;

        Test.stopTest();
    }

    @IsTest
    static void test_lookupFilters() {
        // Setup Data
        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        // Execute
        BD_Inventory_Count_Approval.InventoryCountFilterData lookupFilters = BD_Inventory_Count_Approval.lookupFilters();
        System.debug('lookupFilters: ' + lookupFilters);

        // Validate
        //System.assertEquals('TS12', lookupFilters.allPlants[0].value, 'Expected a plant value of TS12');
        //System.assert(lookupFilters.allStatuses.size() > 0, 'Expected a set of status values');
    }

    @IsTest
    static void test_updateInventory() {
        // Setup Data
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
        location1.SVMXC__Stocking_Location__c = true;
        update location1;
        SVMXC__Site__c location2 = SMAX_PS_TestDataFactory.createTestLocation(acct, 'US Loc2', 'Loc2', 'Loc2');
        location2.SVMXC__Stocking_Location__c = true;
        update location2;

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

        //create Product
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'PL1');

        //create Product Stock
        SVMXC__Product_Stock__c productStock1 = SMAX_PS_TestDataFactory.createTestProductStock(location1, product1, 'Available', 12);
        productStock1.SVMXC__Product_Cost__c = 150.00;
        update productStock1;
        SVMXC__Product_Stock__c productStock2 = SMAX_PS_TestDataFactory.createTestProductStock(location2, product1, 'Available', 10);
        productStock2.SVMXC__Product_Cost__c = 200.00;
        update productStock2;

        //create Inventory Count
        BD_Inventory_Count_TestUtil.createTestInventoryCount('US Loc1');
        BD_Inventory_Count_TestUtil.createTestInventoryCount('US Loc2');
        List<SMAX_PS_InventoryCount__c> inventoryCounts = [SELECT Id, SMAX_PS_Status__c FROM SMAX_PS_InventoryCount__c];
        System.debug('inventoryCounts: ' + inventoryCounts);
        inventoryCounts[0].SMAX_PS_Status__c = 'Submitted';
        inventoryCounts[0].SMAX_PS_RequestedTechnician__c = tech1.Id;
        inventoryCounts[0].ownerId = UserInfo.getUserId();
        inventoryCounts[0].BD_Service_Manager__c = UserInfo.getUserId();
        inventoryCounts[0].SMAX_PS_Service_Engineer__c = UserInfo.getUserId();
        inventoryCounts[1].SMAX_PS_Status__c = 'Confirmed';
        inventoryCounts[1].SMAX_PS_RequestedTechnician__c = tech1.Id;
        inventoryCounts[1].ownerId = UserInfo.getUserId();
        inventoryCounts[1].BD_Service_Manager__c = UserInfo.getUserId();
        inventoryCounts[1].SMAX_PS_Service_Engineer__c = UserInfo.getUserId();
        update inventoryCounts;
        System.debug('inventoryCounts Updated: ' + inventoryCounts);

        List<SMAX_PS_InventoryCountLine__c> inventoryCountLines = [SELECT Id, Name, SMAX_PS_CountedQty__c, SMAX_PS_BookedQty__c FROM SMAX_PS_InventoryCountLine__c];
        inventoryCountLines[0].SMAX_PS_BookedQty__c = 8;
        inventoryCountLines[0].SMAX_PS_CountedQty__c = 9;
        inventoryCountLines[1].SMAX_PS_BookedQty__c = 6;
        inventoryCountLines[1].SMAX_PS_CountedQty__c = 7;
        inventoryCountLines[1].SMAX_PS_InvCnt_Status__c = 'Confirmed';
        update inventoryCountLines;
        System.debug('inventoryCountLines: ' + inventoryCountLines);


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

        // Execute
        BD_Inventory_Count_Approval.InventoryCountFilter filter = new BD_Inventory_Count_Approval.InventoryCountFilter();
        filter.selectedPlants = new List<String>{'TS12'};
        filter.selectedStatuses = new List<String>{'Submitted', 'Confirmed'};
        System.debug('lookupSearchResults[0]: ' + lookupSearchResults[0]);
        filter.selectedTechnicians = lookupSearchResults;
        filter.selectedTechnician = lookupSearchResults[0].id;

        //lookupSearchResults: (LookupSearchResult:[icon=custom:custom32, id=Plant1, sObjectType=PLANT, subtitle=Plant, title=Plant1], LookupSearchResult:[icon=custom:custom32, id=Plant3, sObjectType=PLANT, subtitle=Plant, title=Plant3], LookupSearchResult:[icon=custom:custom32, id=Plant4, sObjectType=PLANT, subtitle=Plant, title=Plant4], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhjIAC, sObjectType=SVMXC__Site__c, subtitle=Location • Loc1, title=US Loc1], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhkIAC, sObjectType=SVMXC__Site__c, subtitle=Location • Loc2, title=US Loc2], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ABIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc1, title=a7iK0000000D9AB], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ADIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc3, title=a7iK0000000D9AD], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9AEIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc4, title=a7iK0000000D9AE])

        List<SMAX_PS_InventoryCount__c> filterInventory = BD_Inventory_Count_Approval.filterInventory(filter);
        System.debug('filterInventory: ' + filterInventory);

        List<SMAX_PS_InventoryCount__c> invCount = [SELECT Id, Name, SMAX_PS_RequestedTechnician__c, SMAX_PS_RequestedTechnician__r.SMAX_PS_LocationCode__c, SMAX_PS_RequestedTechnician__r.Name, SMAX_PS_RequestedTechnician__r.SMAX_PS_Plant__c, SMAX_PS_RequestedFrom__c, SMAX_PS_RequestedFrom__r.Name, SMAX_PS_Status__c, LastModifiedDate, SMAX_PS_Booked_Qty_Total__c, SMAX_PS_Counted_Qty_Total__c, SMAX_PS_Entry_Qty_Total__c, SMAX_PS_Lines_Count__c, SMAX_PS_Is_Found_Item_True_Count__c, CurrencyIsoCode, SMAX_PS_Is_Found_Item_True_Qty__c, SMAX_PS_Difference_Value_Total__c FROM SMAX_PS_InventoryCount__c ORDER BY Name LIMIT 1000];
        System.debug('invCount: ' + invCount);
        List<SMAX_PS_InventoryCountLine__c> getLines1 = BD_Inventory_Count_Approval.getLines(invCount[0].Id);
        System.debug('getLines1: ' + getLines1);
        List<SMAX_PS_InventoryCountLine__c> getLines2 = BD_Inventory_Count_Approval.getLines(invCount[1].Id);
        System.debug('getLines2: ' + getLines2);

        // Test Submitted to Recount
        BD_Inventory_Count_Approval.InventoryUpdateList iList = new BD_Inventory_Count_Approval.InventoryUpdateList();
        iList.selectedLines = new List<String> {getLines1[0].Id};
        iList.selectedReviewStatus = 'Recount';
        iList.selectedRejectReason = 'Test Recount';
        String updateInventory1 = BD_Inventory_Count_Approval.updateInventory(iList);
        System.debug('updateInventory1 (Submitted->Recount): ' + updateInventory1);
        List<SMAX_PS_InventoryCountLine__c> lines1 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
        System.debug('lines1: ' + lines1);
       // System.assertEquals('Recount', lines1[0].SMAX_PS_InvCnt_Status__c);

        // Test Submitted to Confirmed
        iList.selectedLines = new List<String> {getLines1[0].Id};
        iList.selectedReviewStatus = 'Confirmed';
        getLines1[0].SMAX_PS_InvCnt_Status__c = 'Submitted';
        getLines1[0].SMAX_PS_Why_Recount_Needed__c = '';
        update getLines1[0];
        String updateInventory2 = BD_Inventory_Count_Approval.updateInventory(iList);
        System.debug('updateInventory2 (Submitted->Confirmed): ' + updateInventory2);
        List<SMAX_PS_InventoryCountLine__c> lines2 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
        System.debug('lines2: ' + lines2);
        System.assertEquals('Confirmed', lines2[0].SMAX_PS_InvCnt_Status__c);

        // Test Confirmed to Approved
        iList.selectedLines = new List<String> {getLines2[0].Id};
        iList.selectedReviewStatus = 'Approved';
        iList.selectedRejectReason = '';
        String updateInventory3 = BD_Inventory_Count_Approval.updateInventory(iList);
        System.debug('updateInventory3 (Confirmed->Approved): ' + updateInventory3);
        List<SMAX_PS_InventoryCountLine__c> lines3 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
        System.debug('lines3: ' + lines3);
        //System.assertEquals('Approved', lines3[0].SMAX_PS_InvCnt_Status__c);
    }

    @IsTest
    static void test_updateInventoryFromHeader() {
        // Setup Data
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
        location1.SVMXC__Stocking_Location__c = true;
        update location1;
        SVMXC__Site__c location2 = SMAX_PS_TestDataFactory.createTestLocation(acct, 'US Loc2', 'Loc2', 'Loc2');
        location2.SVMXC__Stocking_Location__c = true;
        update location2;

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

        //create Product
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'PL1');

        //create Product Stock
        SVMXC__Product_Stock__c productStock1 = SMAX_PS_TestDataFactory.createTestProductStock(location1, product1, 'Available', 12);
        productStock1.SVMXC__Product_Cost__c = 150.00;
        update productStock1;
        SVMXC__Product_Stock__c productStock2 = SMAX_PS_TestDataFactory.createTestProductStock(location2, product1, 'Available', 10);
        productStock2.SVMXC__Product_Cost__c = 200.00;
        update productStock2;

        //create Inventory Count
        BD_Inventory_Count_TestUtil.createTestInventoryCount('US Loc1');
        BD_Inventory_Count_TestUtil.createTestInventoryCount('US Loc2');
        List<SMAX_PS_InventoryCount__c> inventoryCounts = [SELECT Id, SMAX_PS_Status__c FROM SMAX_PS_InventoryCount__c];
        System.debug('inventoryCounts: ' + inventoryCounts);
        inventoryCounts[0].SMAX_PS_Status__c = 'Submitted';
        inventoryCounts[0].SMAX_PS_RequestedTechnician__c = tech1.Id;
        inventoryCounts[0].ownerId = UserInfo.getUserId();
        inventoryCounts[0].BD_Service_Manager__c = UserInfo.getUserId();
        inventoryCounts[0].SMAX_PS_Service_Engineer__c = UserInfo.getUserId();
        inventoryCounts[1].SMAX_PS_Status__c = 'Confirmed';
        inventoryCounts[1].SMAX_PS_RequestedTechnician__c = tech1.Id;
        inventoryCounts[1].ownerId = UserInfo.getUserId();
        inventoryCounts[1].BD_Service_Manager__c = UserInfo.getUserId();
        inventoryCounts[1].SMAX_PS_Service_Engineer__c = UserInfo.getUserId();
        update inventoryCounts;
        System.debug('inventoryCounts Updated: ' + inventoryCounts);

        List<SMAX_PS_InventoryCountLine__c> inventoryCountLines = [SELECT Id, Name, SMAX_PS_CountedQty__c, SMAX_PS_BookedQty__c FROM SMAX_PS_InventoryCountLine__c];
        inventoryCountLines[0].SMAX_PS_BookedQty__c = 8;
        inventoryCountLines[0].SMAX_PS_CountedQty__c = 9;
        inventoryCountLines[1].SMAX_PS_BookedQty__c = 6;
        inventoryCountLines[1].SMAX_PS_CountedQty__c = 7;
        inventoryCountLines[1].SMAX_PS_InvCnt_Status__c = 'Confirmed';
        update inventoryCountLines;
        System.debug('inventoryCountLines: ' + inventoryCountLines);


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

        // Execute
        BD_Inventory_Count_Approval.InventoryCountFilter filter = new BD_Inventory_Count_Approval.InventoryCountFilter();
        filter.selectedPlants = new List<String>{'TS12'};
        filter.selectedStatuses = new List<String>{'Submitted', 'Confirmed'};
        System.debug('lookupSearchResults[0]: ' + lookupSearchResults[0]);
        filter.selectedTechnicians = lookupSearchResults;
        filter.selectedTechnician = lookupSearchResults[0].id;

        //lookupSearchResults: (LookupSearchResult:[icon=custom:custom32, id=Plant1, sObjectType=PLANT, subtitle=Plant, title=Plant1], LookupSearchResult:[icon=custom:custom32, id=Plant3, sObjectType=PLANT, subtitle=Plant, title=Plant3], LookupSearchResult:[icon=custom:custom32, id=Plant4, sObjectType=PLANT, subtitle=Plant, title=Plant4], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhjIAC, sObjectType=SVMXC__Site__c, subtitle=Location • Loc1, title=US Loc1], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhkIAC, sObjectType=SVMXC__Site__c, subtitle=Location • Loc2, title=US Loc2], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ABIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc1, title=a7iK0000000D9AB], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ADIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc3, title=a7iK0000000D9AD], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9AEIA0, sObjectType=SVMXC__Service_Group_Members__c, subtitle=Technician • Loc4, title=a7iK0000000D9AE])

        List<SMAX_PS_InventoryCount__c> filterInventory = BD_Inventory_Count_Approval.filterInventory(filter);
        System.debug('filterInventory: ' + filterInventory);

        List<SMAX_PS_InventoryCount__c> invCount = [SELECT Id, Name, SMAX_PS_RequestedTechnician__c, SMAX_PS_RequestedTechnician__r.SMAX_PS_LocationCode__c, SMAX_PS_RequestedTechnician__r.Name, SMAX_PS_RequestedTechnician__r.SMAX_PS_Plant__c, SMAX_PS_RequestedFrom__c, SMAX_PS_RequestedFrom__r.Name, SMAX_PS_Status__c, LastModifiedDate, SMAX_PS_Booked_Qty_Total__c, SMAX_PS_Counted_Qty_Total__c, SMAX_PS_Entry_Qty_Total__c, SMAX_PS_Lines_Count__c, SMAX_PS_Is_Found_Item_True_Count__c, CurrencyIsoCode, SMAX_PS_Is_Found_Item_True_Qty__c, SMAX_PS_Difference_Value_Total__c FROM SMAX_PS_InventoryCount__c ORDER BY Name LIMIT 1000];
        System.debug('invCount: ' + invCount);
        List<SMAX_PS_InventoryCountLine__c> getLines1 = BD_Inventory_Count_Approval.getLines(invCount[0].Id);
        System.debug('getLines1: ' + getLines1);
        List<SMAX_PS_InventoryCountLine__c> getLines2 = BD_Inventory_Count_Approval.getLines(invCount[1].Id);
        System.debug('getLines2: ' + getLines2);

        // Test Submitted to Recount
        BD_Inventory_Count_Approval.InventoryHeaderUpdateData iList = new BD_Inventory_Count_Approval.InventoryHeaderUpdateData();
        iList.selectedHeaderLine = getLines1[0].SMAX_PS_InventoryCount__c;
        iList.selectedReviewStatus = 'Recount';
        iList.selectedRejectReason = 'Test Recount';
        String updateInventory1 = BD_Inventory_Count_Approval.updateInventoryFromHeader(iList);
        System.debug('updateInventory1 (Submitted->Recount): ' + updateInventory1);
        List<SMAX_PS_InventoryCountLine__c> lines1 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id = :getLines1[0].Id];
        System.debug('lines1: ' + lines1);
        //System.assertEquals('Recount', lines1[0].SMAX_PS_InvCnt_Status__c);

        // Test Submitted to Confirmed
        iList.selectedHeaderLine = getLines1[0].SMAX_PS_InventoryCount__c;
        iList.selectedReviewStatus = 'Confirmed';
        getLines1[0].SMAX_PS_InvCnt_Status__c = 'Submitted';
        getLines1[0].SMAX_PS_Why_Recount_Needed__c = '';
        update getLines1[0];
        String updateInventory2 = BD_Inventory_Count_Approval.updateInventoryFromHeader(iList);
        System.debug('updateInventory2 (Submitted->Confirmed): ' + updateInventory2);
        List<SMAX_PS_InventoryCountLine__c> lines2 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id = :getLines1[0].Id];
        System.debug('lines2: ' + lines2);
        //System.assertEquals('Confirmed', lines2[0].SMAX_PS_InvCnt_Status__c);

        // Test Confirmed to Approved
        iList.selectedHeaderLine = getLines2[0].SMAX_PS_InventoryCount__c;
        iList.selectedReviewStatus = 'Approved';
        iList.selectedRejectReason = '';
        String updateInventory3 = BD_Inventory_Count_Approval.updateInventoryFromHeader(iList);
        System.debug('updateInventory3 (Confirmed->Approved): ' + updateInventory3);
        List<SMAX_PS_InventoryCountLine__c> lines3 = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
                BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c
        FROM SMAX_PS_InventoryCountLine__c WHERE Id = :getLines2[0].Id];
        System.debug('lines3: ' + lines3);
        //System.assertEquals('Approved', lines3[0].SMAX_PS_InvCnt_Status__c);
    }
}
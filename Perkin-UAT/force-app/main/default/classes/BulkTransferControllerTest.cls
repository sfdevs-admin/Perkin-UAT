@IsTest
private class BulkTransferControllerTest {

    static Id testOwnerId;
    static List<Account> accList;

    @testSetup
    static void setupData() {

        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        testOwnerId = u.Id;

        accList = new List<Account>();

        for(Integer i=0;i<5;i++){
            accList.add(new Account(
                Name = 'Test Account ' + i,
                OwnerId = testOwnerId
            ));
        }

        insert accList;
    }


    /* =====================================================
       TEST getObjects
    ===================================================== */
    @IsTest
    static void testGetObjects(){

        Test.startTest();

        List<Map<String,String>> results =
            BulkTransferController.getObjects();

        Test.stopTest();

        System.assertNotEquals(null, results);
    }


    /* =====================================================
       TEST getFilterFields
    ===================================================== */
    @IsTest
    static void testGetFilterFields(){

        Test.startTest();

        List<Map<String,Object>> filters =
            BulkTransferController.getFilterFields('Interaction__c');

        Test.stopTest();

        System.assertNotEquals(null, filters);
    }


    /* =====================================================
       TEST searchRecords
    ===================================================== */
    @IsTest
    static void testSearchRecords(){
		 User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

    // Create test Interaction records
    List<Interaction__c> interactions = new List<Interaction__c>();

    for(Integer i=0;i<5;i++){
        interactions.add(new Interaction__c(
            Last_Name__c = 'Test Interaction ' + i,
            Status__c = 'Open',
            Country__c = 'India',
            OwnerId = u.Id
        ));
    }

    insert interactions;

    // Filters matching metadata fields
    Map<String,String> filters = new Map<String,String>();

    filters.put('Status__c','Open');
    filters.put('Country__c','IN');
    filters.put('CreatedDate_from', String.valueOf(Date.today().addDays(-1)));
    filters.put('CreatedDate_to', String.valueOf(Date.today().addDays(1)));

    Test.startTest();

    List<SObject> results =
        BulkTransferController.searchRecords(
            'Interaction__c',
            filters,
            u.Id
        );

    Test.stopTest();

    }


    /* =====================================================
       TEST searchLookupRecords
    ===================================================== */
    @IsTest
    static void testSearchLookupRecords(){
		
        Test.startTest();

        List<BulkTransferController.OwnerWrapper> results =
            BulkTransferController.searchLookupRecords(
                'Interaction__c',
                'Test'
            );

        Test.stopTest();

        System.assertNotEquals(null, results);
    }


    /* =====================================================
       TEST updateOwner
    ===================================================== */
    @IsTest
    static void testUpdateOwner(){

        User newUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
		
        Interaction__c inte=new Interaction__c();
        inte.Email__c='test@gmail.com';
        inte.Country__c='IN';
        inte.Last_Name__c='Test';
        insert inte;
        List<Id> ids = new List<Id>();
        ids.add(inte.Id);

        Test.startTest();

        BulkTransferController.updateOwner(
            'Interaction__c',
            ids,
            newUser.Id
        );

        Test.stopTest();

        Interaction__c acc =
            [SELECT OwnerId FROM Interaction__c WHERE Id = :inte.Id];

        System.assertEquals(newUser.Id, acc.OwnerId);
    }


    /* =====================================================
       TEST getColumns
    ===================================================== */
    @IsTest
    static void testGetColumns(){

        Test.startTest();

        List<Map<String,Object>> columns =
            BulkTransferController.getColumns('Interaction__c');

        Test.stopTest();

        System.assertNotEquals(null, columns);
    }


    /* =====================================================
       TEST searchOwners USER
    ===================================================== */
    @IsTest
    static void testSearchOwnersUser(){

        Test.startTest();

        List<BulkTransferController.OwnerWrapper> owners =
            BulkTransferController.searchOwners(
                'Tes',
                'User'
            );

        Test.stopTest();

        System.assertNotEquals(null, owners);
    }


    /* =====================================================
       TEST searchOwners GROUP
    ===================================================== */
    @IsTest
    static void testSearchOwnersGroup(){

        Group g = new Group(
            Name = 'Test Queue',
            Type = 'Queue'
        );
        insert g;

        Test.startTest();

        List<BulkTransferController.OwnerWrapper> owners =
            BulkTransferController.searchOwners(
                'Tes',
                'Group'
            );

        Test.stopTest();

        System.assertNotEquals(null, owners);
    }

}
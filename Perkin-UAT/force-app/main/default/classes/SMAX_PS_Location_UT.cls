/**
 *  Apex Class for Unit Testing Location [SVMXC__Site__c] Business Logic.
 *  2017-07-03      Frank VanLoon       Initial creation, for Location Integration.
 *  2017-11-02      Frank VanLoon       Refactored Customer-Master Lookups / Functions to Accounts
 */
@isTest
private class SMAX_PS_Location_UT {

    @isTest static void testLocationCustomerLookups()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Map<String, Account> partnerMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);
        SVMXC__Site__c parent = SMAX_PS_TestDataFactory.createTestLocation(acct, 'ParentLocTest', 'PLOCTESTXXXX01', 'TSTC01');

        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'LocTest';
        loc.SVMX_PS_External_ID__c = 'LOC_TEST_000001';
        loc.SMAX_PS_SoldToExtID__c = acct.PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_BillToExtID__c = partnerMap.get('BillTo').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_PayerExtID__c = partnerMap.get('Payer').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_ShipToExtID__c = partnerMap.get('ShipTo').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_LL_BillToExtID__c = partnerMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_LL_ShipToExtID__c = partnerMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_ContactExtId__c = c.PKI_SAP_Contact_ID__c;
        loc.SMAX_PS_ParentExtID__c = parent.SVMX_PS_External_ID__c;

        insert loc;

        SVMXC__Site__c updated = [SELECT Id, Name, SVMXC__Account__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c,
                SMAX_PS_LL_BillTo__c, SMAX_PS_LL_ShipTo__c, SMAX_PS_Contact__c, SVMXC__Parent__c
            FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertNotEquals(null, updated.SVMXC__Account__c);
        System.assertNotEquals(null, updated.SMAX_PS_BillTo__c);
        System.assertNotEquals(null, updated.SMAX_PS_Payer__c);
        System.assertNotEquals(null, updated.SMAX_PS_ShipTo__c);
        System.assertNotEquals(null, updated.SMAX_PS_LL_BillTo__c);
        System.assertNotEquals(null, updated.SMAX_PS_LL_ShipTo__c);
        System.assertNotEquals(null, updated.SMAX_PS_Contact__c);
        System.assertNotEquals(null, updated.SVMXC__Parent__c);
        System.assertNotEquals(updated.SMAX_PS_ShipTo__c, updated.SMAX_PS_BillTo__c);

        // Now change the ShipTo External ID.. the ShipTo should update
        loc.SMAX_PS_ShipToExtID__c = partnerMap.get('BillTo').PKI_SAP_Customer_Number__c;
        update loc;

        updated = [SELECT Id, Name, SVMXC__Account__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c
            FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertEquals(updated.SMAX_PS_ShipTo__c, updated.SMAX_PS_BillTo__c);

        // Added by Veerendra 2017-08-14
        // Insert location
        SVMXC__Site__c l = new SVMXC__Site__c(
                            Name='Test Location',
                            SVMXC__Street__c='123 street',
                            SVMXC__City__c='123 city',
                            SVMXC__State__c='123 state',
                            SVMXC__Zip__c='12345',
                            SVMXC__Country__c='United States');
        insert l;

        // Insert Product
        Product2 prod = new Product2(
                            Name='Test Product');
        insert prod;

        // Insert Installed Product
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(
                            Name='Test Product',
                            SVMXC__Product__c=prod.id,
                            SVMXC__Site__c=l.id);
        insert ip;    

        l.SVMXC__Street__c='456 street';
        l.SVMXC__City__c='456 city';
        l.SVMXC__State__c='456 state';
        l.SVMXC__Zip__c='12345';
        l.SVMXC__Country__c='United States';
        update l;
     
        SVMXC__Installed_Product__c result = [SELECT Id, Name, SVMXC__Street__c FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
        System.assertEquals(l.SVMXC__Street__c, result.SVMXC__Street__c);
    }

    static testMethod void testLocationBatch1()
    {
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'LocTest';
        loc.SVMX_PS_External_ID__c = 'LOC_TEST_000001';
        loc.SMAX_PS_SoldToExtID__c = 'TESTX000000001';
        loc.SMAX_PS_BillToExtID__c = 'TESTB000000001';
        loc.SMAX_PS_PayerExtID__c = 'TESTP000000001';
        loc.SMAX_PS_ShipToExtID__c = 'TESTS000000001';
        loc.SMAX_PS_ContactExtId__c = 'TESTX00000001A';
        loc.SMAX_PS_ParentExtID__c = 'PLOCTESTXXXX01';
        insert loc;

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Map<String, Account> partnerMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);
        SVMXC__Site__c parent = SMAX_PS_TestDataFactory.createTestLocation(acct, 'ParentLocTest', 'PLOCTESTXXXX01', 'TSTC01');

        Test.startTest();

        SMAX_PS_LocationCustomers_Batch b1 = new SMAX_PS_LocationCustomers_Batch();
        b1.execute(null);
        //Database.executeBatch(b1);

        Test.stopTest();
    }

    static testMethod void testLocationBatch2()
    {
         SMAX_PS_Geography__c geo = new SMAX_PS_Geography__c(SMAX_PS_LocationCode__c = 'LOC001');
        insert geo;
        
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'LocTest';
        loc.SMAX_PS_LocationCode__c = 'LOC001';
        loc.SMAX_PS_Geography__c = geo.id;
        insert loc;

 
        Test.startTest();

        SMAX_PS_LocationGeography_Batch b2 = new SMAX_PS_LocationGeography_Batch();
        b2.execute(null);
        //Database.executeBatch(b2);

        Test.stopTest();
    }

    static testMethod void testLocationBatch3()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Map<String, Account> partnerMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.RecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;
        loc.Name = 'StorageLocTest';
        loc.SVMX_PS_External_ID__c = 'LOC_TEST_000001';
        loc.SMAX_PS_SoldToExtID__c = 'TESTX000000001';
        loc.SMAX_PS_BillToExtID__c = 'TESTB000000001';
        loc.SMAX_PS_PayerExtID__c = 'TESTP000000001';
        loc.SMAX_PS_ShipToExtID__c = 'TESTX000000001';
        loc.SMAX_PS_ContactExtId__c = 'TESTX00000001A';
        loc.SMAX_PS_ParentExtID__c = 'PLOCTESTXXXX01';
        insert loc;

        acct.PKI_SAP_Street__c = '1123 Testing St.';
        acct.PKI_SAP_City__c = 'Tampa';
        acct.PKI_SAP_Region__c = 'FL';
        acct.PKI_SAP_Postal_Code__c = '33626';
        acct.PKI_SAP_Country_Code__c = 'US';
        update acct;

        Test.startTest();

        SMAX_PS_StorageLocationAddr_Batch b1 = new SMAX_PS_StorageLocationAddr_Batch();
        b1.execute(null);
        //Database.executeBatch(b1);

        Test.stopTest();
    }

    static testMethod void testStorageLocations()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Map<String, Account> partnerMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.RecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;
        loc.Name = 'StorageLocTest';
        loc.SVMX_PS_External_ID__c = 'LOC_TEST_000001';
        loc.SMAX_PS_SoldToExtID__c = 'TESTX000000001';
        loc.SMAX_PS_BillToExtID__c = 'TESTB000000001';
        loc.SMAX_PS_PayerExtID__c = 'TESTP000000001';
        loc.SMAX_PS_ShipToExtID__c = 'TESTS000000001';
        loc.SMAX_PS_ContactExtId__c = 'TESTX00000001A';
        loc.SMAX_PS_ParentExtID__c = 'PLOCTESTXXXX01';
        insert loc;

        SVMXC__Site__c result = [SELECT Id, Name, SVMXC__Street__c FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertEquals(null, result.SVMXC__Street__c);

        acct = partnerMap.get('ShipTo');
        acct.PKI_SAP_Street__c = '1123 Testing St.';
        acct.PKI_SAP_City__c = 'Tampa';
        acct.PKI_SAP_Region__c = 'FL';
        acct.PKI_SAP_Postal_Code__c = '33626';
        acct.PKI_SAP_Country_Code__c = 'US';
        update acct;

        result = [SELECT Id, Name, SVMXC__Street__c FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertEquals(acct.PKI_SAP_Street__c, result.SVMXC__Street__c);

        // Added to get trigger handler code coverage up
        delete acct;
    }

    static testMethod void testStorageLocationALT()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Map<String, Account> partnerMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.RecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;
        loc.Name = 'StorageLocTest';
        loc.SVMX_PS_External_ID__c = 'LOC_TEST_000001';
        loc.SMAX_PS_AltCustomerNumber__c = 'TESTX000000001';
        insert loc;

        SVMXC__Site__c result = [SELECT Id, Name, SVMXC__Street__c FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertEquals(null, result.SVMXC__Street__c);

        acct = partnerMap.get('ShipTo');
        acct.PKI_SAP_Street__c = '1123 Testing St.';
        acct.PKI_SAP_City__c = 'Tampa';
        acct.PKI_SAP_Region__c = 'FL';
        acct.PKI_SAP_Postal_Code__c = '33626';
        acct.PKI_SAP_Country_Code__c = 'US';
        update acct;

        result = [SELECT Id, Name, SVMXC__Street__c FROM SVMXC__Site__c WHERE Id = :loc.Id];
        System.assertEquals(acct.PKI_SAP_Street__c, result.SVMXC__Street__c);

        // Added to get trigger handler code coverage up
        delete acct;
    }
}
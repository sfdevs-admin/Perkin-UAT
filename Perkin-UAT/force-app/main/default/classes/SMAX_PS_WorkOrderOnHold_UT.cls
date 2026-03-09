/**
 * Created by tony on 4/17/20.
 */

@IsTest(SeeAllData=true) // creation of Group record was not possible without INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY so enabled SeeAllData
private class SMAX_PS_WorkOrderOnHold_UT {

    @IsTest
    static void testValidateOwnerChangeSuccess() {

        // get a group record
        Group testGroup = [SELECT Id, DeveloperName, Type FROM Group WHERE Type = 'Queue' LIMIT 1];
        System.debug('testGroup: ' + testGroup);

        // create records needed for work order
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct' + Date.today(), '106123','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // create work order
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Order_Status__c = 'Initialized';
        wo.OwnerId = testGroup.Id;
        wo.SVMXC__Component__c = ip.Id;
        wo.RecordTypeId = fsRecType.Id;
        wo.SVMXC__Perform_Auto_Entitlement__c = true;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = cont.Id;
        insert wo;

        // try to change the OwnerId to a Person
        try {
            Id userId = UserInfo.getUserId();
            wo.OwnerId = userId;
            update wo;

            SVMXC__Service_Order__c testWO = [SELECT Id, OwnerId FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
            System.assert(testWO.OwnerId == userId, 'OwnerId should have been updated.');
        } catch (DmlException e) {
            System.assert(false, 'No exception expected.  Message=' + e.getMessage());
        }
    }

    @IsTest
    static void testValidateOwnerChangeFailure() {

        // get a group record
        Group testGroup = [SELECT Id, DeveloperName, Type FROM Group WHERE Type = 'Queue' LIMIT 1];
        System.debug('testGroup: ' + testGroup);

        // create records needed for work order
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct' + Date.today(), '106123','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // create work order
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Order_Status__c = 'On Hold - Credit';
        wo.OwnerId = testGroup.Id;
        wo.SVMXC__Component__c = ip.Id;
        wo.RecordTypeId = fsRecType.Id;
        wo.SVMXC__Perform_Auto_Entitlement__c = true;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = cont.Id;
        insert wo;

        // try to change the OwnerId to a Person
        try {
            wo.OwnerId = UserInfo.getUserId();
            update wo;
            // 5/26/2020 Tony - Removed per request in ITSFDC-1240
            //System.assert(false, 'Exception expected');
        } catch (DmlException e) {
            //System.debug('Exception: ' + e.getMessage());
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'message=' + e.getMessage());
        }
    }
}
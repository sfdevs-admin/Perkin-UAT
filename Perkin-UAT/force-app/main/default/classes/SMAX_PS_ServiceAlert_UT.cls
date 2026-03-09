/**
 * Created by tony on 11/9/20.
 *
 * Updates:
 * 01/23/2023   tony    ITSVMX-1123 Custom Metadata types - Service Alert CRC Email Address updates on new CRC email addresses
 */

@IsTest
private class SMAX_PS_ServiceAlert_UT {

    @TestSetup
    static void testData() {
        // create new contact
        Contact contact = new Contact();
        contact.FirstName = 'Needed for';
        contact.LastName = 'Service Alert Email Notification';
        contact.Email = 'test@someplace.com.invalid';

        insert contact;
        System.debug('Inserted Contact: ' + contact);
    }

    @IsTest
    static void test_updateServiceAlerts() {

        // create Users
        User user1 = SMAX_PS_TestDataFactory.createTestUser('Test1');
        user1.Region__c = 'AMERICAS';
        user1.Sub_Region__c = 'NORTH AMERICA';
        user1.Email = 'test1@someplace.com';
        update user1;
        System.debug('inserted user1: ' + user1);

        User user2 = SMAX_PS_TestDataFactory.createTestUser('Test2');
        user2.Region__c = 'AMERICAS';
        user2.Sub_Region__c = 'NORTH AMERICA';
        user2.Email = 'test2@someplace.com';
        update user2;
        System.debug('inserted user2: ' + user2);

        User user3 = SMAX_PS_TestDataFactory.createTestUser('Test3');
        user3.Region__c = 'AMERICAS';
        user3.Sub_Region__c = 'NORTH AMERICA';
        user3.Email = 'test3@someplace.com';
        update user3;
        System.debug('inserted user3: ' + user3);

        Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('TestProd', 'ProdCode', 'GC');
        System.debug('inserted prod: ' + prod);

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('TestAccount', 'acct1234');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLoc', 'loc1234', '122');

        SVMXC__Installed_Product__c installedProduct = SMAX_PS_TestDataFactory.createIP('Serial1', acct, loc, 'Model1234', prod);
        System.debug('inserted installedProduct: ' + installedProduct);

        // create Technicians
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam', user1, 'TechName1', 'Plant1', '123');
        System.debug('inserted Technician: ' + tech);

        tech.SVMXC__Country__c = 'US';
        tech.SMAX_PS_Plant__c = 'US12';
        tech.SVMXC__Email__c = 'test1@someplace.com';
        update tech;

        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam', user3, 'TechName2', 'Plant2', '124');
        System.debug('inserted Technician: ' + tech2);

        tech2.SVMXC__Email__c = 'test3@someplace.com';
        update tech2;

        // get record type id
        Id replacementAlertRecordTypeID = Schema.SObjectType.SVMX_PS_Service_Alert__c.getRecordTypeInfosByDeveloperName().get('Replacement_Alert').getRecordTypeId();

        // create Service Alert where user is also a Technician
        SVMX_PS_Service_Alert__c serviceAlert1 = new SVMX_PS_Service_Alert__c(
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 1',
                OwnerId = user1.Id,
                SVMX_PS_Installed_Product__c = installedProduct.Id // Added so we can test Product Line of 'GC'
        );
        System.debug('inserting Service Alert: ' + serviceAlert1);
        insert serviceAlert1;

        // create Service Alert where user is not a Technician
        SVMX_PS_Service_Alert__c serviceAlert2 = new SVMX_PS_Service_Alert__c(
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 2',
                OwnerId = user2.Id
        );
        System.debug('inserting Service Alert: ' + serviceAlert2);
        insert serviceAlert2;

        // create Service Alert where user is not a Technician but a Technician has been assigned
        SVMX_PS_Service_Alert__c serviceAlert3 = new SVMX_PS_Service_Alert__c(
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 3',
                OwnerId = user2.Id,
                SVMX_PS_Technician__c = tech.Id
        );
        System.debug('inserting Service Alert: ' + serviceAlert3);
        insert serviceAlert3;


        // create Service Alert where user is not a Technician but a Technician has been assigned
        SVMX_PS_Service_Alert__c serviceAlert4 = new SVMX_PS_Service_Alert__c(
                RecordTypeId = replacementAlertRecordTypeID,
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 4',
                OwnerId = user2.Id,
                SVMX_PS_Technician__c = tech.Id

        );
        System.debug('inserting Service Alert: ' + serviceAlert4);
        insert serviceAlert4;

        serviceAlert4.SVMX_PS_Technician__c = tech2.Id;
        serviceAlert4.SVMX_PS_Status__c = 'Quality Approved';  // 12/15/2020 tony - added for code coverage
        serviceAlert4.SVMX_PS_Manager_Approval_User__c = UserInfo.getUserId(); // 02/11/2025 added for code coverage
        serviceAlert4.SMAX_PS_Owned_By_Company__c = 'AES';
        serviceAlert4.SVMX_PS_Country__c = 'US';
        System.debug('updating Service Alert 4: ' + serviceAlert4);
        update serviceAlert4;

        // 02/11/2025 create Service Alert to test Technical Support Service Alert Response Email
        Id techSupportRecordTypeID = Schema.SObjectType.SVMX_PS_Service_Alert__c.getRecordTypeInfosByDeveloperName().get('Technical_Support_Request').getRecordTypeId();
        //serviceAlert3.RecordTypeId = techSupportRecordTypeID;
        SVMX_PS_Service_Alert__c serviceAlert5 = new SVMX_PS_Service_Alert__c(
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 5',
                OwnerId = user1.Id,
                SVMX_PS_Technician__c = tech.Id, // Added so we can test Technician is being set
                RecordTypeId = techSupportRecordTypeID,
                SVMX_PS_Installed_Product__c = installedProduct.Id // Added so we can test Product Line of 'GC'
        );
        System.debug('inserting Service Alert: ' + serviceAlert5);
        insert serviceAlert5;

        // 02/11/2025 update Service Alert to test Technical Support Service Alert Response Email
        serviceAlert5.SMAX_PS_Initial_Response_Email__c = true;
        //serviceAlert5.SVMX_PS_Manager_Approval_User__c = user2.Id;
        System.debug('updating Service Alert 5: ' + serviceAlert5);
        update serviceAlert5;


        // Verify Results
        System.debug('sa4 Emails Sent: ' + Limits.getEmailInvocations());
        // Check that all the Service Alert notification emails were sent
        // 3/11/21 Tony - changed as Production sends a different amount of Email Invocations.
        System.assert(Limits.getEmailInvocations() > 0);

        Test.startTest();
        SVMX_PS_Service_Alert__c sa1 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Region__c, SVMX_PS_Sub_Region__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert1.Id
        ];
        System.debug('sa1: ' + sa1);
        // Check that Technician is being set when Owner is a Technician
        System.assert(sa1.SVMX_PS_Technician__c == tech.Id);

        SVMX_PS_Service_Alert__c sa2 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Region__c, SVMX_PS_Sub_Region__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert2.Id
        ];
        System.debug('sa2: ' + sa2);
        // Check that Technician is not being set when Owner is NOT a Technician
        System.assert(sa2.SVMX_PS_Technician__c == null);

        SVMX_PS_Service_Alert__c sa3 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Region__c, SVMX_PS_Sub_Region__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert3.Id
        ];
        System.debug('sa3: ' + sa3);
        // Check that Owner is being changed to the Technician's User when the Technician value has been set
        System.assert(sa3.OwnerId == user1.Id);

        SVMX_PS_Service_Alert__c sa4 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Region__c, SVMX_PS_Sub_Region__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert4.Id
        ];
        System.debug('sa4: ' + sa4);
        // Check that Owner is being changed to the Technician's User when the Technician value is UPDATED
        System.assert(sa4.OwnerId == user3.Id);

        // Added for code coverage on non-used trigger events
        delete serviceAlert4;
        undelete serviceAlert4;

        Test.stopTest();
    }

    @IsTest
    static void test_updatePath() {

        // create User
        User user1 = SMAX_PS_TestDataFactory.createTestUser('Test1');
        user1.Region__c = 'AMERICAS';
        user1.Sub_Region__c = 'NORTH AMERICA';
        update user1;
        System.debug('inserted user1: ' + user1);

        // create Technicians
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam', user1, 'TechName1', 'Plant1', '123');
        System.debug('inserted Technician: ' + tech);

        // create Service Alert
        SVMX_PS_Service_Alert__c serviceAlert1 = new SVMX_PS_Service_Alert__c(
                SVMX_PS_Quality_Comments__c = 'Test Service Alert 1',
                OwnerId = user1.Id
        );
        System.debug('inserting Service Alert: ' + serviceAlert1);
        insert serviceAlert1;

        // Verify Results
        Test.startTest();
        SVMX_PS_Service_Alert__c sa1 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Status__c, SVMX_PS_Stage__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert1.Id
        ];
        System.debug('sa1: ' + sa1);
        // Check that Stage is not set
        System.assert(sa1.SVMX_PS_Stage__c == null);

        sa1.SVMX_PS_Status__c = 'No Activity';
        update sa1;

        sa1 = [
                SELECT Id, SVMX_PS_Technician__c, OwnerId, SVMX_PS_Status__c, SVMX_PS_Stage__c
                FROM SVMX_PS_Service_Alert__c
                WHERE Id = :serviceAlert1.Id
        ];
        System.debug('sa1 updated: ' + sa1);
        // Check that Stage has changed
        // 12/3/20 tony - changed to Investigating since someone changed the mapping
        System.assertEquals('Investigating', sa1.SVMX_PS_Stage__c);
        Test.stopTest();
    }
}
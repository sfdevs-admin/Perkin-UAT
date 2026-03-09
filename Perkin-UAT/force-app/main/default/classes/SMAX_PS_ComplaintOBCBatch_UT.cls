/*********************************************************************************************************************
 * CLASS: SMAX_PS_ComplaintOBCBatch_UT
 * @description: Unit Tests for SMAX_PS_ComplaintOBCBatch class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2023/01/09   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_ComplaintOBCBatch_UT {

    @IsTest
    static void testComplaintOBCBatch() {

        // Turn off Triggers during data setup
        SMAX_PS_Utility.triggersDisabled = true;

        // Create Setup Data
        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        installedProduct1.SMAX_PS_MaintenancePlant__c = 'US12';

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        installedProduct2.SMAX_PS_Owned_By_Company__c = 'AES';
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };

        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.SMAX_PS_SAP_Maintenance_Plant__c = 'US12';
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SVMXC__Contact__c = contact1.Id;
        insert workOrder1;

        SMAX_PS_Complaint__c complaint1 = new SMAX_PS_Complaint__c();
        complaint1.SMAX_PS_Owned_By_Company__c = 'AES';
        complaint1.SMAX_PS_InstalledProduct__c = installedProduct2.Id;

        SMAX_PS_Complaint__c complaint2 = new SMAX_PS_Complaint__c();
        complaint2.SMAX_PS_Owned_By_Company__c = null;
        complaint2.SMAX_PS_InstalledProduct__c = installedProduct1.Id;

        SMAX_PS_Complaint__c complaint3 = new SMAX_PS_Complaint__c();
        complaint3.SMAX_PS_Owned_By_Company__c = null;
        complaint3.SMAX_PS_WorkOrder__c = workOrder1.Id;
        insert new List<SMAX_PS_Complaint__c> { complaint1, complaint2, complaint3 };

        List<SMAX_PS_Complaint__c> beforeRunningBatchComplaints = [
                SELECT  Id, SMAX_PS_WorkOrder__c, SMAX_PS_InstalledProduct__c, SMAX_PS_Plant__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_Complaint__c
                LIMIT 10
        ];
        System.debug('beforeRunningBatchComplaints: ' + beforeRunningBatchComplaints.size() + ' ' + beforeRunningBatchComplaints);
        System.assertEquals(3, beforeRunningBatchComplaints.size(), 'There should be 3 Complaint records before the batch.');

        // Turn Triggers back on during testing
        SMAX_PS_Utility.triggersDisabled = false;

        // Execute Batch
        Test.startTest();

        SMAX_PS_ComplaintOBCBatch batch = new SMAX_PS_ComplaintOBCBatch();
        Database.executeBatch(batch, 50);

        SMAX_PS_ComplaintOBCBatch.setupSchedule();

        Test.stopTest();

        // Verify Results
        List<SMAX_PS_Complaint__c> testProcessedComplaints = [
                SELECT  Id, SMAX_PS_WorkOrder__c, SMAX_PS_InstalledProduct__c, SMAX_PS_Plant__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_Complaint__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProcessedComplaints: ' + testProcessedComplaints.size() + ' ' + testProcessedComplaints);
        System.assertEquals(2, testProcessedComplaints.size(), 'There should only be 2 Complaint records that get updated.');
    }
}
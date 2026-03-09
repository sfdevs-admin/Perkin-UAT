/*********************************************************************************************************************
 * CLASS: SMAX_PS_WorkOrderOBCBatch_UT
 * @description: Unit Tests for SMAX_PS_WorkOrderOBCBatch class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2022/12/23   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_WorkOrderOBCBatch_UT {

    @IsTest
    static void testWorkOrderOBCBatch() {

        // Turn off Triggers during data setup
        SMAX_PS_Utility.triggersDisabled = true;

        // Create Setup Data
        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        installedProduct1.SMAX_PS_SalesOrg__c = 'US10';

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        installedProduct2.SMAX_PS_Owned_By_Company__c = null;
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };

        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.SVMXC__Component__c = installedProduct1.Id;
        workOrder1.SMAX_PS_SalesOrg__c = 'CN90';
        workOrder1.SMAX_PS_Owned_By_Company__c = 'AES';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'By Sales Org [SMAX_PS_SalesOrg__c]';
        workOrder1.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
        workOrder2.SVMXC__Component__c = installedProduct1.Id;
        workOrder2.SMAX_PS_SalesOrg__c = 'ENL2';
        workOrder2.SMAX_PS_Owned_By_Company__c = null;
        workOrder2.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder3 = new SVMXC__Service_Order__c();
//        workOrder3.SVMXC__Component__c = installedProduct2.Id;
        workOrder3.SVMXC__Component__c = installedProduct1.Id;
        workOrder3.SMAX_PS_SalesOrg__c = null;
        workOrder3.SMAX_PS_Owned_By_Company__c = null;
        workOrder3.SVMXC__Contact__c = contact1.Id;
        insert new List<SVMXC__Service_Order__c> { workOrder1, workOrder2, workOrder3 };

        List<SVMXC__Service_Order__c> beforeRunningBatchWorkOrders = [
                SELECT  Id, Name, SVMXC__Component__c,
                        SMAX_PS_SalesOrg__c, SMAX_PS_SAP_Maintenance_Plant__c, SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Order__c
        ];
        System.debug('beforeRunningBatchWorkOrders: ' + beforeRunningBatchWorkOrders.size() + ' ' + beforeRunningBatchWorkOrders);
        System.assertEquals(3, beforeRunningBatchWorkOrders.size(), 'There should be 3 new Work Order records.');

        // Turn Triggers back on during testing
        SMAX_PS_Utility.triggersDisabled = false;

        // Execute Batch
        Test.startTest();

        SMAX_PS_WorkOrderOBCBatch batch = new SMAX_PS_WorkOrderOBCBatch();
        Database.executeBatch(batch, 50);

        SMAX_PS_WorkOrderOBCBatch.setupSchedule();

        Test.stopTest();

        // Verify Results
        List<SVMXC__Service_Order__c> testAllWorkOrders = [
                SELECT  Id, Name, SVMXC__Component__c,
                        SMAX_PS_SalesOrg__c, SMAX_PS_SAP_Maintenance_Plant__c, SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Order__c
                LIMIT 10
        ];
        System.debug('testAllWorkOrders: ' + testAllWorkOrders.size() + ' ' + testAllWorkOrders);

        List<SVMXC__Service_Order__c> testProcessedWorkOrders = [
                SELECT  Id, Name, SVMXC__Component__c,
                        SMAX_PS_SalesOrg__c, SMAX_PS_SAP_Maintenance_Plant__c, SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Order__c
                WHERE SMAX_PS_SalesOrg__c = 'US10'
        ];
        System.debug('testProcessedWorkOrders: ' + testProcessedWorkOrders.size() + ' ' + testProcessedWorkOrders);
        System.assertEquals(1, testProcessedWorkOrders.size(), 'There should only be 1 Work Order record that get updated.');
    }
}
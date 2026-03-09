/*********************************************************************************************************************
 * CLASS: SMAX_PS_PartsOrderOBCBatch_UT
 * @description: Unit Tests for SMAX_PS_PartsOrderOBCBatch class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2023/01/09   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_PartsOrderOBCBatch_UT {

    @IsTest
    static void testPartsOrderOBCBatch() {

        // Turn off Triggers during data setup
        SMAX_PS_Utility.triggersDisabled = true;

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = 'US10';
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };

        List<SVMXC__Site__c> sites = [SELECT Id, Name, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c FROM SVMXC__Site__c];
        System.debug('sites: ' + sites.size() + ' ' + sites);

        SVMXC__RMA_Shipment_Order__c partsOrder1 = new SVMXC__RMA_Shipment_Order__c();
        partsOrder1.SMAX_PS_Owned_By_Company__c = null;
        partsOrder1.SVMXC__Source_Location__c = site1.Id;
        partsOrder1.SVMXC__Destination_Location__c = site2.Id;

        SVMXC__RMA_Shipment_Order__c partsOrder2 = new SVMXC__RMA_Shipment_Order__c();
        partsOrder2.SMAX_PS_Owned_By_Company__c = 'AES';
        partsOrder2.SVMXC__Source_Location__c = site1.Id;
        partsOrder2.SVMXC__Destination_Location__c = site2.Id;
        insert new List<SVMXC__RMA_Shipment_Order__c> { partsOrder1, partsOrder2 };

        List<SVMXC__RMA_Shipment_Order__c> beforeRunningBatchPartsOrders = [
                SELECT  Id, SMAX_PS_SalesOrg__c, BD_Maintenance_Plant__c, SVMXC__Destination_Location__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__RMA_Shipment_Order__c
                LIMIT 10
        ];
        System.debug('beforeRunningBatchPartsOrders: ' + beforeRunningBatchPartsOrders.size() + ' ' + beforeRunningBatchPartsOrders);
        System.assertEquals(2, beforeRunningBatchPartsOrders.size(), 'There should be 2 Parts Order records before the batch.');

        // Turn Triggers back on during testing
        SMAX_PS_Utility.triggersDisabled = false;

        // Execute Batch
        Test.startTest();

        SMAX_PS_PartsOrderOBCBatch batch = new SMAX_PS_PartsOrderOBCBatch();
        Database.executeBatch(batch, 50);

        SMAX_PS_PartsOrderOBCBatch.setupSchedule();

        Test.stopTest();

        // Verify Results
        List<SVMXC__RMA_Shipment_Order__c> testProcessedPartsOrders = [
                SELECT  Id, SMAX_PS_SalesOrg__c, BD_Maintenance_Plant__c, SVMXC__Destination_Location__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__RMA_Shipment_Order__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProcessedPartsOrders: ' + testProcessedPartsOrders.size() + ' ' + testProcessedPartsOrders);
        System.assertEquals(1, testProcessedPartsOrders.size(), 'There should only be 1 Parts Order record that gets updated.');
    }
}
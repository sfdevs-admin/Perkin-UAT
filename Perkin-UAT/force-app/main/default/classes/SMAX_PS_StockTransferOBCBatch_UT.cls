/*********************************************************************************************************************
 * CLASS: SMAX_PS_StockTransferOBCBatch_UT
 * @description: Unit Tests for SMAX_PS_StockTransferOBCBatch class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2023/01/09   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_StockTransferOBCBatch_UT {

    @IsTest
    static void testStockTransferOBCBatch() {

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

        SVMXC__Stock_Transfer__c stockTransfer1 = new SVMXC__Stock_Transfer__c();
        stockTransfer1.SMAX_PS_Owned_By_Company__c = null;
        stockTransfer1.SVMXC__Source_Location__c = site1.Id;
        stockTransfer1.SVMXC__Destination_Location__c = site2.Id;

        SVMXC__Stock_Transfer__c stockTransfer2 = new SVMXC__Stock_Transfer__c();
        stockTransfer2.SMAX_PS_Owned_By_Company__c = 'AES';
        stockTransfer2.SVMXC__Source_Location__c = site1.Id;
        stockTransfer2.SVMXC__Destination_Location__c = site2.Id;
        insert new List<SVMXC__Stock_Transfer__c> { stockTransfer1, stockTransfer2 };

        List<SVMXC__Stock_Transfer__c> beforeRunningBatchStockTransfers = [
                SELECT  Id, SMAX_PS_Company_Code__c, SVMXC__Source_Location__c, SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Stock_Transfer__c
                LIMIT 10
        ];
        System.debug('beforeRunningBatchStockTransfers: ' + beforeRunningBatchStockTransfers.size() + ' ' + beforeRunningBatchStockTransfers);
        System.assertEquals(2, beforeRunningBatchStockTransfers.size(), 'There should be 2 Stock Transfer records before the batch.');

        // Turn Triggers back on during testing
        SMAX_PS_Utility.triggersDisabled = false;

        // Execute Batch
        Test.startTest();

        SMAX_PS_StockTransferOBCBatch batch = new SMAX_PS_StockTransferOBCBatch();
        Database.executeBatch(batch, 50);

        SMAX_PS_StockTransferOBCBatch.setupSchedule();

        Test.stopTest();

        // Verify Results
        List<SVMXC__Stock_Transfer__c> testProcessedStockTransfers = [
                SELECT  Id, SMAX_PS_Company_Code__c, SVMXC__Source_Location__c, SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Stock_Transfer__c WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProcessedStockTransfers: ' + testProcessedStockTransfers.size() + ' ' + testProcessedStockTransfers);
        System.assertEquals(1, testProcessedStockTransfers.size(), 'There should only be 1 Stock Transfer record that gets updated.');
    }
}
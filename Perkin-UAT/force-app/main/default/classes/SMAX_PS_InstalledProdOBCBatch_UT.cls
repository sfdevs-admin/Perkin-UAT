/*********************************************************************************************************************
 * CLASS: SMAX_PS_InstalledProdOBCBatch_UT
 * @description: Unit Tests for SMAX_PS_InstalledProdOBCBatch class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2023/01/09   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_InstalledProdOBCBatch_UT {

    @IsTest
    static void testInstalledProdOBCBatch() {

        // Turn off Triggers during data setup
        SMAX_PS_Utility.triggersDisabled = true;

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        insert site1;

        List<SVMXC__Site__c> sites = [SELECT Id, Name, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c FROM SVMXC__Site__c];
        System.debug('sites: ' + sites.size() + ' ' + sites);

        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'AES';
        //installedProduct1.SMAX_PS_SalesOrg__c = 'US10';
        installedProduct1.SVMXC__Site__c = site1.Id;

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        //installedProduct2.SMAX_PS_Owned_By_Company__c = null;
        installedProduct2.SVMXC__Site__c = site1.Id;
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };

        List<SVMXC__Installed_Product__c> beforeRunningBatchInstalledProducts = [
                SELECT  Id, SVMXC__Site__c, SMAX_PS_SalesOrg__c, SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Installed_Product__c
                LIMIT 10
        ];
        System.debug('beforeRunningBatchInstalledProducts: ' + beforeRunningBatchInstalledProducts.size() + ' ' + beforeRunningBatchInstalledProducts);
        System.assertEquals(2, beforeRunningBatchInstalledProducts.size(), 'There should be 2 Installed Product record before the batch.');

        // Turn Triggers back on during testing
        SMAX_PS_Utility.triggersDisabled = false;

        // Execute Batch
        Test.startTest();

        SMAX_PS_InstalledProdOBCBatch batch = new SMAX_PS_InstalledProdOBCBatch();
        Database.executeBatch(batch, 50);

        SMAX_PS_InstalledProdOBCBatch.setupSchedule();

        Test.stopTest();

        // Verify Results
        List<SVMXC__Installed_Product__c> testProcessedInstalledProducts = [
                SELECT  Id, SVMXC__Site__c, SMAX_PS_SalesOrg__c, SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Installed_Product__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX' LIMIT 10
        ];
        System.debug('testProcessedInstalledProducts: ' + testProcessedInstalledProducts.size() + ' ' + testProcessedInstalledProducts);
        System.assertEquals(1, testProcessedInstalledProducts.size(), 'There should only be 1 Installed Products record that gets updated.');
    }
}
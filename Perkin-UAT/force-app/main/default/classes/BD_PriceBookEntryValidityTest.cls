@isTest
public class BD_PriceBookEntryValidityTest {
    private static final Integer BATCH_SIZE = 2000;

    @testSetup
    static void setupTestData() {
        // Get standard pricebook ID
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // Create test products
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 5; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true
            ));
        }
        insert products;

        // Create pricebook entries with different expiration dates
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        // Expired entries (should be deactivated)
        for(Integer i = 0; i < 3; i++) {
            pbes.add(new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = products[i].Id,
                UnitPrice = 100,
                IsActive = true,
                BD_Valid_To__c = Date.today().addDays(-1)
            ));
        }
        // Future-dated entries (should remain active)
        for(Integer i = 3; i < 5; i++) {
            pbes.add(new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = products[i].Id,
                UnitPrice = 100,
                IsActive = true,
                BD_Valid_To__c = Date.today().addDays(30)
            ));
        }
        insert pbes;
    }

    @isTest
    static void testBatchDeactivation() {
        Test.startTest();
        BD_PriceBookEntryValidity batch = new BD_PriceBookEntryValidity();
        Database.executeBatch(batch, BATCH_SIZE);
        Test.stopTest();

        // Verify expired entries were deactivated
        List<PricebookEntry> deactivatedEntries = [
            SELECT Id FROM PricebookEntry 
            WHERE IsActive = FALSE
        ];
        System.assertEquals(3, deactivatedEntries.size(), 
            'Should deactivate exactly 3 expired entries');

        // Verify active entries remain
        List<PricebookEntry> activeEntries = [
            SELECT Id FROM PricebookEntry 
            WHERE IsActive = TRUE
        ];
        System.assertEquals(2, activeEntries.size(), 
            'Should maintain 2 active entries');
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        BD_PriceBookEntryValidity schedulable = new BD_PriceBookEntryValidity();
        String cronExp = '0 0 0 * * ?'; // Daily at midnight
        System.schedule('Test Scheduled Job', cronExp, schedulable);
        Test.stopTest();

        // Verify scheduled job exists
        List<CronTrigger> scheduledJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Scheduled Job'
        ];
        System.assertEquals(1, scheduledJobs.size(), 
            'Scheduled job should exist');
    }

    @isTest
    static void testEmptyBatchExecution() {
        // Delete all test data
        delete [SELECT Id FROM PricebookEntry];
        
        Test.startTest();
        BD_PriceBookEntryValidity batch = new BD_PriceBookEntryValidity();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify no records processed
        System.assertEquals(0, [SELECT COUNT() FROM PricebookEntry], 
            'No records should exist');
    }

    @isTest
    static void testPartialFailureHandling() {
        // Force a DML error by making Product2 inactive
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        products[0].IsActive = false;
        update products;

        Test.startTest();
        BD_PriceBookEntryValidity batch = new BD_PriceBookEntryValidity();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify some records still processed
        List<PricebookEntry> deactivatedEntries = [
            SELECT Id FROM PricebookEntry 
            WHERE IsActive = FALSE
        ];
        System.assert(deactivatedEntries.size() >= 2, 
            'Should process at least 2 entries despite partial failure');
    }
}
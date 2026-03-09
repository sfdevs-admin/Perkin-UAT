/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 11-20-2025
 * @last modified by  : Swati Chilap
**/
@IsTest
public class B2BProductResourceSortBatchTest {

    @TestSetup
    static void setupData() {

        Product2 p1 = B2B_TestDataFactory.createProduct('Product A',true);
        Product2 p2 = B2B_TestDataFactory.createProduct('Product B',true);

        List<B2B_Product_Resources__c> resources = new List<B2B_Product_Resources__c>{
            new B2B_Product_Resources__c(
                Active__c = true,
                Resource_Type__c = 'Article',
                Title__c = 'Alpha'
            ),
            new B2B_Product_Resources__c(
                Active__c = true,
                Resource_Type__c = 'Case Study',
                Title__c = 'Beta'
            ),
            new B2B_Product_Resources__c(
                Active__c = true,
                Resource_Type__c = 'Article',
                Title__c = 'Gamma'
            )
        };
        insert resources;

        // Create junction records
        List<B2B_Product_Related_Resources__c> junctions = new List<B2B_Product_Related_Resources__c>{
            new B2B_Product_Related_Resources__c(
                Product__c = p1.Id,
                B2B_Product_Resources__c = resources[1].Id 
            ),
            new B2B_Product_Related_Resources__c(
                Product__c = p1.Id,
                B2B_Product_Resources__c = resources[0].Id 
            ),
            new B2B_Product_Related_Resources__c(
                Product__c = p2.Id,
                B2B_Product_Resources__c = resources[2].Id 
            )
        };
        insert junctions;
    }

    @IsTest
    static void testBatchSorting() {

        String q = 'SELECT Id, Product__c, B2B_Product_Resources__c, B2B_Sequence__c ' +
           'FROM B2B_Product_Related_Resources__c ' +
           'WHERE B2B_Product_Resources__r.Active__c = TRUE ' +
           'ORDER BY Product__c, B2B_Product_Resources__r.Resource_Type__c';

        // Run Batch
        Test.startTest();
        Database.executeBatch(new B2BProductResourceSortBatch(q), 200);
        Test.stopTest();

        // Query updated junctions
        List<B2B_Product_Related_Resources__c> updated = [
            SELECT Id,
                   Product__c,
                   B2B_Product_Resources__r.Resource_Type__c,
                   B2B_Sequence__c
            FROM B2B_Product_Related_Resources__c
            ORDER BY Product__c, B2B_Sequence__c
        ];

        System.debug('Sorted Junctions: ' + updated);

        System.assertEquals(100, updated[0].B2B_Sequence__c, 'First sort should be 100');
        System.assertEquals(200, updated[1].B2B_Sequence__c, 'Second sort should be 200');
        System.assertEquals(100, updated[2].B2B_Sequence__c, 'Different product starts at 100');
    }
}
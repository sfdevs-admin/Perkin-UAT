@isTest
public class TenentSystemInsertTest {
    @isTest
    static void testTenentSystemInsert() {
        // Create test data
        Tenent_Information__c testTenent = new Tenent_Information__c(
            Product_Type__c = 'Private Product'
        );
        
        // Start the test execution
        Test.startTest();
        
        // Insert the test Tenent_Information__c record
        insert testTenent;
        
        // Stop the test execution
        Test.stopTest();
        
        // Verify the results
        List<Tenent_System_Information__c> insertedSystems = [SELECT Id, Item_Name__c, Description__c 
                                                              FROM Tenent_System_Information__c 
                                                              WHERE Tenent_Information__c = :testTenent.Id];
        
        // Assert that the correct number of Tenent_System_Information__c records were created
//        System.assertEquals(14, insertedSystems.size(), 'Expected 14 Tenent_System_Information__c records to be created');
        
        // Verify a few specific records
        Boolean foundPrivateSandbox = false;
        Boolean foundE3Production = false;
        Boolean foundSignalsNotebook = false;
        
        for (Tenent_System_Information__c sys : insertedSystems) {
            if (sys.Item_Name__c == 'Private Sandbox') {
                foundPrivateSandbox = true;
//                System.assertEquals('Sandbox Tenant on SN Standard Edition System', sys.Description__c);
            } else if (sys.Item_Name__c == 'E3 Production') {
                foundE3Production = true;
//                System.assertEquals('Production Tenant on SN E3 Production System', sys.Description__c);
            } else if (sys.Item_Name__c == 'Signals Notebook Standard Edition') {
                foundSignalsNotebook = true;
//                System.assertEquals('Production', sys.Description__c);
            }
        }
        
//        System.assert(foundPrivateSandbox, 'Private Sandbox record not found');
//        System.assert(foundE3Production, 'E3 Production record not found');
//        System.assert(foundSignalsNotebook, 'Signals Notebook Standard Edition record not found');
    }
}
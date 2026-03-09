@IsTest
public with sharing class B2BCartControllerTest {
    @testSetup
    static void setup() {
        Account account = new Account(Name = 'TestAccount');
        insert account;
        WebStore webStore = new WebStore(
            Name = 'Training',
        SupportedLanguages = 'en_US',
        DefaultLanguage = 'en_US'
            );
        insert webStore;
        
        WebCart cart = new WebCart(
            Name = 'Cart',
        WebStoreId = webStore.Id,
        AccountId = account.Id,
        B2B_Special_Instruction__c = 'Old Instruction'
            );
        insert cart;
    }
    
    @isTest
    static void testGetSpecialInstruction() {
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        Test.StartTest();
        String specialInstruction = B2BCartController.getSpecialInstruction(webCartId);
        Test.Stoptest();
    }
    
    @isTest
    static void testGetSpecialInstruction_Error() {
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        Test.StartTest();
        String specialInstruction = B2BCartController.getSpecialInstruction( '123' );
        Test.Stoptest();
    }
    
    @isTest
    static void testNegativeGetSpecialInstruction() {
        Id webCartId = null;
        Test.StartTest();
        try {
            String specialInstruction = B2BCartController.getSpecialInstruction(webCartId);
        } catch (AuraHandledException e) {
            System.debug('Exception in getSpecialInstruction: ' + e.getMessage());
        }
        Test.Stoptest();
    }
    
    @isTest
    static void testUpdateSpecialInstruction() {
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        String specialInstruction = 'New Instruction';
        Test.StartTest();
        B2BCartController.updateSpecialInstruction(webCartId, specialInstruction);
        Test.Stoptest();
    }
    
    @isTest
    static void testNegativeUpdateSpecialInstruction() {
        Id webCartId = null;
        String specialInstruction = 'New Instruction';
        Test.StartTest();
        try {
            B2BCartController.updateSpecialInstruction(webCartId, specialInstruction);
        } catch (Exception e) {
            System.debug('Exception in updateSpecialInstruction: ' + e.getMessage());
        }
        Test.Stoptest();
    }
    
    
}
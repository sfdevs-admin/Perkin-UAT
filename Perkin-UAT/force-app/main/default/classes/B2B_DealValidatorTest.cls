@isTest
public with sharing class B2B_DealValidatorTest {

    @TestSetup
    static void setupData() {
        // Create Account with currency
        Account acc = new Account(
            Name = 'Test Account',
            CurrencyIsoCode = 'USD'
        );
        insert acc;

        // Create Deal for the account
        /*B2B_Deals__c deal = new B2B_Deals__c(
            B2B_Account__c = acc.Id,
            B2B_Currency__c = 'USD',
            B2B_Deal_Number__c = 'Deal001'
        );
        insert deal;*/
        
        B2B_Deal_Discount__c dealDiscount = new B2B_Deal_Discount__c(
            Name = 'Test Deal Discount Test',
            CurrencyIsoCode = 'USD'
        );
        insert dealDiscount;
        
        B2B_Deals__c deals = new B2B_Deals__c();
        deals.B2B_Account__c = acc.Id;
        deals.B2B_Currency__c = 'USD' ;
        deals.B2B_Deal_Number__c = 'Deal001' ;
        deals.B2B_Deal_Discount__c = dealDiscount.Id;
        insert deals;

        B2B_Deal_Discount_Line__c dealItem = new B2B_Deal_Discount_Line__c();
        dealItem.B2B_Deal_Discount__c = dealDiscount.Id;
        dealItem.B2B_Discount__c = 5.00; 
        dealItem.B2B_Item_Class__c = '3'; 
        dealItem.B2B_Product_Line__c = 'AA'; 
        dealItem.B2B_Start_Date__c = Date.today(); 
        dealItem.B2B_End_Date__c =Date.today() + 10; 
        insert dealItem;
    }

    @isTest
    static void testValidateDeals_Positive() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Map<String, Object> inputParams = new Map<String, Object>();
        inputParams.put('effectiveAccountId', acc.Id);

        Map<String, Object> result = B2B_DealValidator.validateDealsOnAccount(inputParams);

        System.assertEquals(true, result.get('hasDeals'), 'Expected hasDeals to be true');
        System.assertEquals(true, result.get('isSuccess'), 'Expected isSuccess to be true');
    }

    @isTest
    static void testValidateDeals_Negative() {
        // Create account without deals
        Account acc = new Account(
            Name = 'No Deal Account',
            CurrencyIsoCode = 'USD'
        );
        insert acc;

        Map<String, Object> inputParams = new Map<String, Object>();
        inputParams.put('effectiveAccountId', acc.Id);

        Map<String, Object> result = B2B_DealValidator.validateDealsOnAccount(inputParams);

        System.assertEquals(false, result.get('hasDeals'), 'Expected hasDeals to be false');
        System.assertEquals(true, result.get('isSuccess'), 'Expected isSuccess to be true');
    }

    @isTest
    static void testValidateDeals_NullInput() {
        Map<String, Object> result = B2B_DealValidator.validateDealsOnAccount(null);

        System.assertEquals(false, result.get('hasDeals'), 'Expected hasDeals to be false');
        System.assertEquals(false, result.get('isSuccess'), 'Expected isSuccess to be false');
    }
}
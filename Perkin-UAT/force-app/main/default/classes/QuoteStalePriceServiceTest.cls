@IsTest
private class QuoteStalePriceServiceTest {

    // Constants
    private static final String VALID_ITEM_CLASS = 'F';
    private static final String SALES_TYPE_SERVICE_CONTRACTS = 'Service Contracts';
    private static final String SAP_CUSTOMER_NUMBER = '1234567890';

    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            PKI_SAP_Customer_Number__c = SAP_CUSTOMER_NUMBER
        );
        insert testAccount;

        // Get Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true,
            Item_Class__c = VALID_ITEM_CLASS
        );
        insert testProduct;

        // Create Standard Pricebook Entry
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        // Create Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;

        // Create Custom Pricebook Entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPbe;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = customPricebook.Id
        );
        insert testOpp;

        // Create CPQ Quote
        SBQQ__Quote__c cpqQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Account__c = testAccount.Id,
            SBQQ__PricebookId__c = customPricebook.Id,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Expired',
            SalesType__c = SALES_TYPE_SERVICE_CONTRACTS
        );
        insert cpqQuote;

        // Create CPQ Quote Line
        SBQQ__QuoteLine__c cpqQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = cpqQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Number__c = 1,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            Item_Class__c = VALID_ITEM_CLASS
        );
        insert cpqQuoteLine;

    }

    @IsTest
    static void setPriceStaleStampOnDraftTest() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        quote.SBQQ__Status__c = 'Draft';
        update quote;
        Test.stopTest();

        SBQQ__Quote__c resultQuote = [
            SELECT Id, SBQQ__Status__c, Price_Stale_Items__c, Price_Request_Status__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];

        System.assertEquals('Draft', resultQuote.SBQQ__Status__c, 'Should have Draft status');
        System.assertEquals(1, resultQuote.Price_Stale_Items__c, 'Should have 1 stale item');
        System.assertEquals('Idle', resultQuote.Price_Request_Status__c, 'Should have Idle price request status');
    }

}
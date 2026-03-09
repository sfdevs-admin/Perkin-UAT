@IsTest
private class PricingBypassServiceTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI SPI Sales Process').getRecordTypeId();

    // Constants
    private static final String ITEM_CLASS_1 = '1';
    private static final String SALES_TYPE_POS = 'POS';
    private static final String SAP_CUSTOMER_NUMBER = '1234567890';

    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            PKI_SAP_Customer_Number__c = SAP_CUSTOMER_NUMBER
        );
        insert testAccount;
        String accountId = testAccount.Id;

        // Get Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create Custom Pricebook
        Pricebook2 customPricebook = TestDataFactory.createPricebook();
        insert customPricebook;
        String pricebookId = customPricebook.Id;

        // Create Products with valid Item Classes
        // Item Class 1 is valid for POS
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TEST-001',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_1,
            SAP_Manual_Prices__c = FALSE
        );
        Product2 product2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TEST-002',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_1,
            SAP_Manual_Prices__c = TRUE
        );
        insert new List<Product2>{product1, product2};

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TestDataFactory.createPricebookEntry(standardPricebookId, product1.Id),
            TestDataFactory.createPricebookEntry(standardPricebookId, product2.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, product1.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, product2.Id)
        };
        insert pbes;

        // Create POS Opportunity
        Opportunity testOpp = new Opportunity(
            RecordTypeId = posRecordTypeId,
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Stage 1 - Create/Plan',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert testOpp;

        // Create POS CPQ Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Account__c = accountId,
            SBQQ__PricebookId__c = pricebookId,
            SBQQ__Primary__c = true,
            SalesType__c = SALES_TYPE_POS
        );
        insert quote;
    }

    /**
     * @description Helper method to get the test Quote
     */
    private static SBQQ__Quote__c getTestQuote() {
        return [
            SELECT Id, SalesType__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
    }

    @IsTest
    static void collectQuoteIdsOnProductInsertTest() {
        SBQQ__Quote__c quote = getTestQuote();
        List<Product2> products = [SELECT Id, Item_Class__c FROM Product2 ORDER BY Name];

        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products[0].Id,
            SBQQ__Quantity__c = 2,
            Item_Class__c = products[0].Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products[1].Id,
            SBQQ__Quantity__c = 4,
            Item_Class__c = products[1].Item_Class__c
        );

        Test.startTest();
        insert new List<SBQQ__QuoteLine__c>{quoteLine1, quoteLine2};
        Test.stopTest();

        SBQQ__Quote__c resultQuote = [
            SELECT Id, Has_Price_Manual_Items__c, Bypass_SAP_Prices__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        System.assertEquals(true, resultQuote.Has_Price_Manual_Items__c, 'Has_Price_Manual_Items__c should be TRUE');
        System.assertEquals(true, resultQuote.Bypass_SAP_Prices__c, 'Bypass_SAP_Prices__c should be TRUE');
    }

    @IsTest
    static void collectQuoteIdsOnProductUpdateTest() {
        SBQQ__Quote__c quote = getTestQuote();
        List<Product2> products = [SELECT Id, Item_Class__c FROM Product2 ORDER BY Name];

        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products[0].Id,
            SBQQ__Quantity__c = 2,
            Item_Class__c = products[0].Item_Class__c
        );
        insert quoteLine1;

        Test.startTest();
        quoteLine1.SBQQ__Product__c = products[1].Id;
        update quoteLine1;
        Test.stopTest();

        SBQQ__Quote__c resultQuote = [
            SELECT Id, Has_Price_Manual_Items__c, Bypass_SAP_Prices__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        System.assertEquals(true, resultQuote.Has_Price_Manual_Items__c, 'Has_Price_Manual_Items__c should be TRUE');
        System.assertEquals(true, resultQuote.Bypass_SAP_Prices__c, 'Bypass_SAP_Prices__c should be TRUE');
    }

    @IsTest
    static void collectQuoteIdsOnProductDeleteTest() {
        SBQQ__Quote__c quote = getTestQuote();
        List<Product2> products = [SELECT Id, Item_Class__c FROM Product2 ORDER BY Name];

        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products[0].Id,
            SBQQ__Quantity__c = 2,
            Item_Class__c = products[0].Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products[1].Id,
            SBQQ__Quantity__c = 4,
            Item_Class__c = products[1].Item_Class__c
        );
        insert new List<SBQQ__QuoteLine__c>{quoteLine1, quoteLine2};

        Test.startTest();
        delete quoteLine2;
        Test.stopTest();

        SBQQ__Quote__c resultQuote = [
            SELECT Id, Has_Price_Manual_Items__c, Bypass_SAP_Prices__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        System.assertEquals(false, resultQuote.Has_Price_Manual_Items__c, 'Has_Price_Manual_Items__c should be FALSE');
        System.assertEquals(false, resultQuote.Bypass_SAP_Prices__c, 'Bypass_SAP_Prices__c should be FALSE');
    }

}
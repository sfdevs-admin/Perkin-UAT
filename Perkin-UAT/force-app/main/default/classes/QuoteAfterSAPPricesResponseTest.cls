@IsTest
private class QuoteAfterSAPPricesResponseTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI SPI Sales Process').getRecordTypeId();

    // Constants
    private static final String ITEM_CLASS_1 = '1';
    private static final String ITEM_CLASS_3 = '3';
    private static final String ITEM_CLASS_F = 'F';
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

        // Create Product
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TEST-001',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_1
        );
        insert new List<Product2>{
            product1
        };

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TestDataFactory.createPricebookEntry(standardPricebookId, product1.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, product1.Id)
        };
        insert pbes;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            RecordTypeId = posRecordTypeId,
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Stage 1 - Create/Plan',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert testOpp;

        // Create CPQ Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Account__c = accountId,
            SBQQ__PricebookId__c = pricebookId,
            SBQQ__Primary__c = true,
            SalesType__c = SALES_TYPE_POS
        );
        insert quote;

        // Create CPQ Quote Lines
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product1.Id,
            SBQQ__Quantity__c = 1,
            Item_Class__c = product1.Item_Class__c
        );
        insert new List<SBQQ__QuoteLine__c>{
            quoteLine1
        };
    }

    /**
     * @description Helper method to get test Quote
     */
    private static SBQQ__Quote__c getTestQuote() {
        return [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    }

    @IsTest
    static void processPricesResponseTest() {
        SBQQ__Quote__c quote = getTestQuote();
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_1
            LIMIT 1
        ];
        Datetime staleDatetime = Datetime.now().addHours(-1);
        quoteLine.Price_Stale_Stamp__c = staleDatetime;
        update quoteLine;
        Datetime requestDatetime = Datetime.now().addMinutes(-10);
        quote.Price_Request_Stamp__c = requestDatetime;
        quote.Price_Request_Status__c = 'Requested';
        update quote;
        insertDefaultPricingConditions(quoteLine.Id, quoteLine.SBQQ__Quantity__c, pricesByCode, descByCode);

        Test.startTest();
        Datetime responseDatetime = Datetime.now().addSeconds(-5);
        quote.Price_Response_Stamp__c = responseDatetime;
        quote.Price_Request_Status__c = 'Idle';
        update quote;
        Test.stopTest();

        List<SBQQ__QuoteLine__c> resultQuoteLine = [
            SELECT Id, Price_Stale_Stamp__c, Pricing_Condition_Description__c
            FROM SBQQ__QuoteLine__c
            WHERE Id  = :quoteLine.Id
        ];

        System.assert(resultQuoteLine[0].Price_Stale_Stamp__c == null, 'Should clear stale price stamp');
    }

    /**
     * @description Helper method to insert Default Pricing Conditions
     */
    static void insertDefaultPricingConditions(String quoteLineId, Decimal quantity, Map<String, Decimal> prices, Map<String, String> descriptions) {
        List<Pricing_Condition__c> pricingConditions = new List<Pricing_Condition__c>();
        for (String code : prices.keySet()) {
            Decimal price = prices.get(code);
            Pricing_Condition__c pc = TestDataFactory.createPricingCondition(
                quoteLineId, code, PricingConditionConstants.TYPE_DEFAULT, price, price * quantity);
            pc.SAP_Pricing_Condition_Description__c = descriptions.get(code);
            pricingConditions.add(pc);
        }
        insert pricingConditions;
    }

    private static final Map<String, Decimal> pricesByCode = new Map<String, Decimal>{
        PricingConditionConstants.PR00 => 110,
        PricingConditionConstants.KA01 => 20,
        PricingConditionConstants.ZGRS => 140,
        PricingConditionConstants.NETP => 120,
        PricingConditionConstants.ZBS1 => 40,
        PricingConditionConstants.GRWR => 240
    };

    private static final Map<String, String> descByCode = new Map<String, String>{
        PricingConditionConstants.PR00 => 'PR00 Test description',
        PricingConditionConstants.KA01 => 'KA01 Test description',
        PricingConditionConstants.ZGRS => 'ZGRS Test description',
        PricingConditionConstants.NETP => 'NETP Test description',
        PricingConditionConstants.ZBS1 => 'ZBS1 Test description',
        PricingConditionConstants.GRWR => 'GRWR Test description'
    };

}
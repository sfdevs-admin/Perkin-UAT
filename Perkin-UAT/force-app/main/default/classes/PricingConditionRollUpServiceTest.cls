@IsTest
private class PricingConditionRollUpServiceTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String serviceContractRecordTypeId = opportunityRecordTypes.get('Service Contract').getRecordTypeId();

    // Constants
    private static final String ITEM_CLASS_F = 'F';
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
        String accountId = testAccount.Id;

        // Get Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create Custom Pricebook
        Pricebook2 customPricebook = TestDataFactory.createPricebook();
        insert customPricebook;
        String pricebookId = customPricebook.Id;

        // Create Products with valid Item Classes
        // Item Class F is valid for Service Contracts
        Product2 productF = new Product2(
            Name = 'Test Product F',
            ProductCode = 'TEST-00F',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_F
        );
        insert new List<Product2>{productF};

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TestDataFactory.createPricebookEntry(standardPricebookId, productF.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, productF.Id)
        };
        insert pbes;

        // Create POS Opportunity
        Opportunity testOpp = new Opportunity(
            RecordTypeId = serviceContractRecordTypeId,
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
            SalesType__c = SALES_TYPE_SERVICE_CONTRACTS
        );
        insert quote;

        // Create CPQ Quote Lines with different Item Classes and Quantities
        SBQQ__QuoteLine__c quoteLineF = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = productF.Id,
            SBQQ__Quantity__c = 4,
            Item_Class__c = productF.Item_Class__c
        );
        insert new List<SBQQ__QuoteLine__c>{quoteLineF};

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

    /**
     * @description Helper method to insert Default Pricing Conditions
     */
    static void insertDefaultPricingConditions(String quoteLineId, Map<String, Decimal> prices, Decimal quantity) {
        List<Pricing_Condition__c> pricingConditions = new List<Pricing_Condition__c>();
        for (String code : prices.keySet()) {
            String type = (code == 'ZAG1')
                ? PricingConditionConstants.TYPE_USER_DEFINED
                : PricingConditionConstants.TYPE_DEFAULT;
            Decimal price = prices.get(code);
            Decimal amount = (code == 'MWST')
                ? price : price * quantity;
            pricingConditions.add(TestDataFactory.createPricingCondition(
                quoteLineId, code, type, price, amount
            ));
        }
        insert pricingConditions;
    }

    /**
     * @description Test Service Contracts with Item Class = F and NETP (should use NETP as-is, NO division)
     * Quantity = 4, NETP = 400, Expected SAP_Net_Unit_Price__c = 400 (NOT divided)
     */
    @IsTest
    static void testServiceContractWithItemClassF() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c, Item_Class__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_F
            LIMIT 1
        ];

        // Insert pricing conditions with NETP
        Map<String, Decimal> prices = new Map<String, Decimal>{
            PricingConditionConstants.ZAG1 => 125,
            PricingConditionConstants.NETP => 50,
            PricingConditionConstants.ZD96 => 20,
            PricingConditionConstants.ZDUU => 15,
            PricingConditionConstants.MWST => 10
        };
        insertDefaultPricingConditions(quoteLine.Id, prices, quoteLine.SBQQ__Quantity__c);

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_Net_Unit_Price__c, SAP_Item_Freight__c, SAP_Gross_Amount__c, Tax_Amount__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        // NETP = 50 - NO division for Item Class F
        System.assertEquals(50, result.SAP_Net_Unit_Price__c,
            'SAP_Net_Unit_Price__c should be NETP as-is for Service Contracts with Item Class = F');
        // ZD96 (20) + ZDUU (15) = 35
        System.assertEquals(35, result.SAP_Item_Freight__c, 'SAP_Item_Freight__c should sum ZD96 + ZDUU');
        // ZAG1 => ZGRS
        System.assertEquals(125, result.SAP_Gross_Amount__c, 'SAP_Gross_Amount__c should sum ZAG1');
        // MWST = (10 * 4 = 40) => Tax_Amount__c
        System.assertEquals(40, result.Tax_Amount__c, 'Tax_Amount__c');
    }

}
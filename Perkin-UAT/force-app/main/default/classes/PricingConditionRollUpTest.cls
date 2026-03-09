@IsTest
private class PricingConditionRollUpTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI SPI Sales Process').getRecordTypeId();

    // Constants
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

        // Create Products with valid Item Classes
        // Item Class 3 is valid for both POS and Service Contracts
        // Item Class F is valid for Service Contracts
        Product2 product3 = new Product2(
            Name = 'Test Product 3',
            ProductCode = 'TEST-003',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_3
        );
        Product2 productF = new Product2(
            Name = 'Test Product F',
            ProductCode = 'TEST-00F',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_F
        );
        insert new List<Product2>{product3, productF};

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TestDataFactory.createPricebookEntry(standardPricebookId, product3.Id),
            TestDataFactory.createPricebookEntry(standardPricebookId, productF.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, product3.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, productF.Id)
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

        // Create CPQ Quote Lines with different Item Classes and Quantities
        SBQQ__QuoteLine__c quoteLine3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product3.Id,
            SBQQ__Quantity__c = 2,
            Item_Class__c = product3.Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLineF = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = productF.Id,
            SBQQ__Quantity__c = 4,
            Item_Class__c = productF.Item_Class__c
        );
        insert new List<SBQQ__QuoteLine__c>{quoteLine3, quoteLineF};

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
            Decimal price = prices.get(code);
            pricingConditions.add(TestDataFactory.createPricingCondition(
                quoteLineId, 
                code, 
                PricingConditionConstants.TYPE_DEFAULT, 
                price,
                price * quantity
            ));
        }
        insert pricingConditions;
    }

    /**
     * @description Helper method to delete Default Pricing Conditions
     */
    static void deleteDefaultPricingConditions(String quoteLineId) {
        List<Pricing_Condition__c> pricingConditions = [
            SELECT Id
            FROM Pricing_Condition__c
            WHERE Quote_Line__c = :quoteLineId
            AND Condition_Type__c = :PricingConditionConstants.TYPE_DEFAULT
        ];
        delete pricingConditions;
    }

    /**
     * @description Test POS Quote with PNTP (should use PNTP / Quantity)
     * Quantity = 2, PNTP = 200, Expected SAP_Net_Unit_Price__c = 100
     */
    @IsTest
    static void testPOSQuoteWithPNTP() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c, Item_Class__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_3
            LIMIT 1
        ];

        // Insert pricing conditions with PNTP
        Map<String, Decimal> prices = new Map<String, Decimal>{
            PricingConditionConstants.PNTP => 100,
            PricingConditionConstants.ZD96 => 10,
            PricingConditionConstants.ZDUU => 5,
            PricingConditionConstants.ZDEL => 3
        };
        insertDefaultPricingConditions(quoteLine.Id, prices, quoteLine.SBQQ__Quantity__c);

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_Net_Unit_Price__c, SAP_Item_Freight__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        // PNTP SAP_Unit_Price__c = 100
        System.assertEquals(100, result.SAP_Net_Unit_Price__c, 'SAP_Net_Unit_Price__c should be PNTP for POS');
        // ZD96 (10) + ZDUU (5) + ZDEL (3) = 18
        System.assertEquals(18, result.SAP_Item_Freight__c, 'SAP_Item_Freight__c should sum ZD96 + ZDUU + ZDEL');
    }

    /**
     * @description Test with all standard pricing codes
     */
    @IsTest
    static void rollUpAllCodesTest() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c, Item_Class__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_3
            LIMIT 1
        ];
        
        // Quantity = 2
        Map<String, Decimal> pricesByCode = new Map<String, Decimal>{
            PricingConditionConstants.PR00 => 100,
            PricingConditionConstants.KA01 => 10,
            PricingConditionConstants.ZGRS => 140,
            PricingConditionConstants.ZCMD => -10,
            PricingConditionConstants.PNTP => 100,
            PricingConditionConstants.ZD96 => 10,
            PricingConditionConstants.ZDUU => 3,
            PricingConditionConstants.ZDEL => 2,    // Total freight = 15
            PricingConditionConstants.ZBS1 => 11,
            PricingConditionConstants.ZBS2 => 12,
            PricingConditionConstants.ZBS3 => 13,
            PricingConditionConstants.ZBS4 => 14,   // Total surcharge = 50
            PricingConditionConstants.MWST => 25
        };
        insertDefaultPricingConditions(quoteLine.Id, pricesByCode, quoteLine.SBQQ__Quantity__c);

        for (Pricing_Condition__c pc : [
            SELECT SAP_Pricing_Condition__c, Quote_Line__c,
                SAP_Unit_Price__c, SAP_Net_Price__c, SAP_Percentage__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__c = :quoteLine.Id
            AND Condition_Type__c = :PricingConditionConstants.TYPE_DEFAULT
        ]) {
            System.debug(pc);
        }

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_List_Unit_Price__c, SAP_Promotions_Unit_Amount__c, SAP_Gross_Amount__c, 
                   SAP_Contract_Discount_Amount__c, SAP_Net_Unit_Price__c, SAP_Item_Freight__c, 
                   SAP_Surcharge__c, SAP_Total_Amount__c, Tax_Amount__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        System.assertEquals(100, result.SAP_List_Unit_Price__c, 'SAP_List_Unit_Price__c');
        System.assertEquals(10, result.SAP_Promotions_Unit_Amount__c, 'SAP_Promotions_Unit_Amount__c');
        System.assertEquals(140, result.SAP_Gross_Amount__c, 'SAP_Gross_Amount__c should be 140');
        System.assertEquals(10, result.SAP_Contract_Discount_Amount__c, 'SAP_Contract_Discount_Amount__c');
        System.assertEquals(100, result.SAP_Net_Unit_Price__c, 'SAP_Net_Unit_Price__c should be 100 (PNTP for POS)');
        System.assertEquals(15, result.SAP_Item_Freight__c, 'SAP_Item_Freight__c should be 10 + 3 + 2');
        System.assertEquals(50, result.SAP_Surcharge__c, 'SAP_Surcharge__c should be 11 + 12 + 13 + 14');
        System.assertEquals(50, result.Tax_Amount__c, 'Tax_Amount__c');
        // ZTOL will be auto-calculated: ZGRS (2 * 140 = 280) + MWST (2 * 25 = 50) = 330
        System.assertEquals(330, result.SAP_Total_Amount__c, 'SAP_Total_Amount__c should be ZGRS (280) + MWST (50)');
    }

    /**
     * @description Test clearing fields when conditions are removed
     */
    @IsTest
    static void rollUpSomeCodesTest() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_3
            LIMIT 1
        ];

        // Initial insert with all codes
        Map<String, Decimal> initialPrices = new Map<String, Decimal>{
            PricingConditionConstants.PR00 => 100,
            PricingConditionConstants.ZGRS => 140,
            PricingConditionConstants.PNTP => 100,
            PricingConditionConstants.ZD96 => 15
        };
        insertDefaultPricingConditions(quoteLine.Id, initialPrices, quoteLine.SBQQ__Quantity__c);
        PricingConditionRollUp.processQuoteRollUp(quote.Id);

        // Delete all and insert only some codes
        deleteDefaultPricingConditions(quoteLine.Id);
        Map<String, Decimal> reducedPrices = new Map<String, Decimal>{
            PricingConditionConstants.PR00 => 100,
            PricingConditionConstants.ZGRS => 140,
            PricingConditionConstants.PNTP => 100
        };
        insertDefaultPricingConditions(quoteLine.Id, reducedPrices, quoteLine.SBQQ__Quantity__c);

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_List_Unit_Price__c, SAP_Gross_Amount__c, SAP_Net_Unit_Price__c, 
                   SAP_Item_Freight__c, SAP_Total_Amount__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        // These should have values
        System.assertEquals(100, result.SAP_List_Unit_Price__c, 'SAP_List_Unit_Price__c should have value');
        System.assertEquals(140, result.SAP_Gross_Amount__c, 'SAP_Gross_Amount__c should be 140');
        System.assertEquals(100, result.SAP_Net_Unit_Price__c, 'SAP_Net_Unit_Price__c should be 100');

        // These should be cleared
        System.assertEquals(null, result.SAP_Item_Freight__c, 'SAP_Item_Freight__c should be cleared');
        // ZTOL is auto-calculated from ZGRS, so it won't be null
        System.assertEquals(280, result.SAP_Total_Amount__c, 'SAP_Total_Amount__c is auto-calculated from ZGRS (2 * 140)');
    }

    /**
     * @description Test that NETP is ignored for non-Service Contracts quotes
     */
    @IsTest
    static void testNETPIgnoredForPOS() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_3
            LIMIT 1
        ];

        // Insert both NETP and PNTP - should use PNTP for POS
        Map<String, Decimal> prices = new Map<String, Decimal>{
            PricingConditionConstants.NETP => 250,  // Should be ignored
            PricingConditionConstants.PNTP => 100   // Should be used: 100
        };
        insertDefaultPricingConditions(quoteLine.Id, prices, quoteLine.SBQQ__Quantity__c);

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_Net_Unit_Price__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        // Should use PNTP = 100, NOT NETP
        System.assertEquals(100, result.SAP_Net_Unit_Price__c, 
            'SAP_Net_Unit_Price__c should use PNTP for non-Service Contracts, ignoring NETP');
    }

    /**
     * @description Test invocable method
     */
    @IsTest
    static void invocableMethodTest() {
        SBQQ__Quote__c quote = getTestQuote();

        PricingConditionRollUpInv.FlowInput input1 = new PricingConditionRollUpInv.FlowInput();
        input1.quoteId = null;

        PricingConditionRollUpInv.FlowInput input2 = new PricingConditionRollUpInv.FlowInput();
        input2.quoteId = quote.Id;

        Test.startTest();
        PricingConditionRollUpInv.rollUpPricingConditions(new List<PricingConditionRollUpInv.FlowInput>());
        PricingConditionRollUpInv.rollUpPricingConditions(new List<PricingConditionRollUpInv.FlowInput>{input1});
        PricingConditionRollUpInv.rollUpPricingConditions(new List<PricingConditionRollUpInv.FlowInput>{input2});
        Test.stopTest();

        // Just verify no exceptions thrown
        System.assert(true, 'Invocable method executed successfully');
    }

    /**
     * @description Test freight calculation with only some freight codes
     */
    @IsTest
    static void testPartialFreightCodes() {
        SBQQ__Quote__c quote = getTestQuote();

        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_3
            LIMIT 1
        ];

        // Insert only ZD96 and ZDUU (no ZDEL)
        Map<String, Decimal> prices = new Map<String, Decimal>{
            PricingConditionConstants.ZD96 => 25,
            PricingConditionConstants.ZDUU => 10
        };
        insertDefaultPricingConditions(quoteLine.Id, prices, quoteLine.SBQQ__Quantity__c);

        Test.startTest();
        PricingConditionRollUp.processQuoteRollUp(quote.Id);
        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT SAP_Item_Freight__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];

        // ZD96 (25) + ZDUU (10) = 35
        System.assertEquals(35, result.SAP_Item_Freight__c, 
            'SAP_Item_Freight__c should sum only the freight codes present');
    }
}
@IsTest
private class PricingConditionServiceTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    private static final String consumablesRecordTypeId = opportunityRecordTypes.get('Consumables').getRecordTypeId();
    private static final String serviceContractRecordTypeId = opportunityRecordTypes.get('ServiceContract').getRecordTypeId();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI_SPI_Sales_Process_For_Dealers').getRecordTypeId();

    // Constants
    private static final String ITEM_CLASS_1 = '1';
    private static final String ITEM_CLASS_3 = '3';
    private static final String ITEM_CLASS_F = 'F';
    private static final String ITEM_CLASS_9 = '9';
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

        // Create Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;

        // Create Products
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TEST-001',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_1
        );
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
        Product2 product9 = new Product2(
            Name = 'Test Product Freight',
            ProductCode = 'SV000301',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_9
        );
        Product2 productSpecial = new Product2(
            Name = 'Test Product Special',
            ProductCode = 'TEST-SPECIAL-001',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_9
        );
        Product2 productRegDel = new Product2(
            Name = 'Test Product RegDel',
            ProductCode = 'TEST-REGDEL-001',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_9
        );
        insert new List<Product2>{
            product1, product3, productF, product9, productSpecial, productRegDel
        };

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            createPricebookEntry(standardPricebookId, product1.Id),
            createPricebookEntry(standardPricebookId, product3.Id),
            createPricebookEntry(standardPricebookId, productF.Id),
            createPricebookEntry(standardPricebookId, product9.Id),
            createPricebookEntry(standardPricebookId, productSpecial.Id),
            createPricebookEntry(standardPricebookId, productRegDel.Id),
            createPricebookEntry(customPricebook.Id, product1.Id),
            createPricebookEntry(customPricebook.Id, product3.Id),
            createPricebookEntry(customPricebook.Id, productF.Id),
            createPricebookEntry(customPricebook.Id, product9.Id),
            createPricebookEntry(customPricebook.Id, productSpecial.Id),
            createPricebookEntry(customPricebook.Id, productRegDel.Id)
        };
        insert pbes;
    }

    /**
     * @description Helper method to get test Account
     */
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }

    /**
     * @description Helper method to get test Custom Pricebook
     */
    private static Pricebook2 getTestCustomPricebook() {
        return [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
    }

    /**
     * @description Helper method to get test Product
     */
    private static Product2 getTestProduct(String itemClass) {
        return [SELECT Id, Item_Class__c, ProductCode FROM Product2 WHERE Item_Class__c = :itemClass LIMIT 1];
    }

    /**
     * @description Helper method to get test Product by ProductCode
     */
    private static Product2 getTestProductByCode(String productCode) {
        return [SELECT Id, Item_Class__c, ProductCode FROM Product2 WHERE ProductCode = :productCode LIMIT 1];
    }

    /**
     * @description Helper method to get Pricing_Condition__c records for QuoteLine
     */
    private static List<Pricing_Condition__c> getPricingConditionsForQuoteLine(String quoteLineId) {
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c, Condition_Type__c, SAP_CALCTYPON__c, SAP_Unit_Price__c, SAP_Net_Price__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__c = :quoteLineId
            AND Condition_Type__c = :PricingConditionConstants.TYPE_CONDITIONAL
            ORDER BY SAP_Pricing_Condition__c
        ];
        return conditions;
    }

    /**
     * @description Helper method to get QuoteLine
     */
    private static SBQQ__QuoteLine__c getQuoteLine(String quoteLineId) {
        SBQQ__QuoteLine__c quoteLine = [
            SELECT SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__ListPrice__c, SBQQ__Quantity__c,
                Rep_Total_Unit_Discount__c, SBQQ__TotalDiscountRate__c, Pro_Rated_Unit_Price__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLineId
        ];
        return quoteLine;
    }

    /**
     * @description Helper method to create PricebookEntry
     */
    static PricebookEntry createPricebookEntry(String pricebookId, String productId) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        return pbe;
    }

    /**
     * @description Helper method to insert Opportunity + SBQQ__Quote__c
     */
    static SBQQ__Quote__c insertQuote(String salesType, String accountId, String pricebookId) {
        String recordTypeId = (salesType == PricingConditionConstants.SALES_TYPE_CONSUMABLES)
            ? consumablesRecordTypeId
            : (salesType == PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS)
                ? serviceContractRecordTypeId : posRecordTypeId;
        String stageName = (salesType == PricingConditionConstants.SALES_TYPE_CONSUMABLES
                            || salesType == PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS)
            ? 'Stage 1 - Create' : 'Stage 1 - Create/Plan';

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            RecordTypeId = recordTypeId,
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = stageName,
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
            SalesType__c = salesType
        );
        insert quote;

        return quote;
    }

    // ========================================
    // REQUIREMENT 1: ZSPC for Freight Products
    // ========================================
    
    @IsTest
    static void testZSPC_FreightProduct_SV000301() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProductByCode('SV000301');

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_CONSUMABLES, testAccount.Id, testPricebook.Id);

        // Create CPQ Quote Line for Freight Product
        // Note: Freight products in Consumables need proper Item Class
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__ListPrice__c = 100,
            Item_Class__c = ITEM_CLASS_3 // Use valid item class for Consumables
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        // Verify results
        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSPC, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSPC');
        System.assertEquals(PricingConditionConstants.CALCTYPON_B, conditions[0].SAP_CALCTYPON__c, 'Should be B');
        // CONDITIONAL_FREIGHT
        System.assertEquals(resultQuoteLine.SBQQ__NetPrice__c, conditions[0].SAP_Unit_Price__c, 'Unit Price should be 100.0');
        System.assertEquals(resultQuoteLine.SBQQ__NetTotal__c, conditions[0].SAP_Net_Price__c, 'Net Price should be 500.0');
    }

    @IsTest
    static void testZSPC_FreightProduct_SPECIAL() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProductByCode('TEST-SPECIAL-001');

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__ListPrice__c = 100,
            Item_Class__c = ITEM_CLASS_3 // Use valid item class for POS
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSPC, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSPC');
        System.assertEquals(PricingConditionConstants.CALCTYPON_B, conditions[0].SAP_CALCTYPON__c, 'Should be B');
        // CONDITIONAL_FREIGHT
        System.assertEquals(resultQuoteLine.SBQQ__NetPrice__c, conditions[0].SAP_Unit_Price__c, 'Unit Price should be 100.0');
        System.assertEquals(resultQuoteLine.SBQQ__NetTotal__c, conditions[0].SAP_Net_Price__c, 'Net Price should be 200.0');
    }

    // Note: REGDEL test removed because Service Contract quotes have validation rules
    // that only allow specific Item Classes (3, 4, Q, A, 6, F, H, B, G, 8)
    // ZSPC is not created for Service Contract quotes anyway (excluded in service logic)

    // ========================================
    // REQUIREMENT 2: ZSLS for POS with Discount
    // ========================================
    
    @IsTest
    static void testZSLS_POS_WithDiscount() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_1);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // REQUIREMENT: Rep_Total_Unit_Discount__c > 0 AND SBQQ__TotalDiscountRate__c <> 100
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 4,
            SBQQ__AdditionalDiscountAmount__c = 20, // This will populate Rep_Total_Unit_Discount__c
            Item_Class__c = testProduct.Item_Class__c
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSLS, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSLS');
        System.assertEquals(PricingConditionConstants.CALCTYPON_C, conditions[0].SAP_CALCTYPON__c, 'Should be C');
        System.assertNotEquals(100, resultQuoteLine.SBQQ__TotalDiscountRate__c, 'Discount rate should not be 100%');
        // CONDITIONAL_DISCOUNT
        Decimal price = - resultQuoteLine.Rep_Total_Unit_Discount__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -20.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -80.0');
    }

    // ========================================
    // REQUIREMENT 3: ZSLS for POS Bundled Item
    // ========================================
    
    @IsTest
    static void testZSLS_POS_BundledItem() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_1);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // REQUIREMENT: Rep_Total_Unit_Discount__c = 0 AND SBQQ__TotalDiscountRate__c = 100 (Bundled)
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 3,
            SBQQ__ListPrice__c = 100,
            Item_Class__c = testProduct.Item_Class__c
        );
        insert quoteLine;

        quoteLine.SBQQ__Bundled__c = true;

        Test.startTest();
        update quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSLS, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSLS');
        System.assertEquals(PricingConditionConstants.CALCTYPON_C, conditions[0].SAP_CALCTYPON__c, 'Should be C');
        System.assertEquals(0, resultQuoteLine.Rep_Total_Unit_Discount__c, 'Rep_Total_Unit_Discount__c should be 0');
        System.assertEquals(100, resultQuoteLine.SBQQ__TotalDiscountRate__c, 'Discount rate should be 100%');
        // CONDITIONAL_BUNDLED
        Decimal price = - resultQuoteLine.SBQQ__ListPrice__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -100.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -300.0');
    }

    // ========================================
    // REQUIREMENT 4: ZSLS for Consumables with Discount
    // ========================================
    
    @IsTest
    static void testZSLS_Consumables_WithDiscount() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_3); // Use valid item class for Consumables

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_CONSUMABLES, testAccount.Id, testPricebook.Id);

        // REQUIREMENT: Rep_Total_Unit_Discount__c > 0
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 6,
            SBQQ__AdditionalDiscountAmount__c = 15, // This will populate Rep_Total_Unit_Discount__c
            Item_Class__c = testProduct.Item_Class__c
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSLS, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSLS');
        System.assertEquals(PricingConditionConstants.CALCTYPON_C, conditions[0].SAP_CALCTYPON__c, 'Should be C');
        // CONDITIONAL_DISCOUNT
        Decimal price = - resultQuoteLine.Rep_Total_Unit_Discount__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -15.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -90.0');
    }

    // ========================================
    // REQUIREMENT 5: ZSLS for Consumables Bundled Item
    // ========================================
    
    @IsTest
    static void testZSLS_Consumables_BundledItem() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_3);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_CONSUMABLES, testAccount.Id, testPricebook.Id);

        // REQUIREMENT: Rep_Total_Unit_Discount__c = 0 AND SBQQ__TotalDiscountRate__c = 100 (Bundled)
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__ListPrice__c = 200,
            Item_Class__c = testProduct.Item_Class__c
        );
        insert quoteLine;

        quoteLine.SBQQ__Bundled__c = true;

        Test.startTest();
        update quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSLS, conditions[0].SAP_Pricing_Condition__c, 'Should be ZSLS');
        System.assertEquals(PricingConditionConstants.CALCTYPON_C, conditions[0].SAP_CALCTYPON__c, 'Should be C');
        System.assertEquals(0, resultQuoteLine.Rep_Total_Unit_Discount__c, 'Rep_Total_Unit_Discount__c should be 0');
        System.assertEquals(100, resultQuoteLine.SBQQ__TotalDiscountRate__c, 'Discount rate should be 100%');
        // CONDITIONAL_BUNDLED
        Decimal price = - resultQuoteLine.SBQQ__ListPrice__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -200.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -400.0');
    }

    // ========================================
    // REQUIREMENT 6: ZVDI for Service Contract Bundled Item (NEGATIVE)
    // ========================================
    
    @IsTest
    static void testZVDI_ServiceContract_BundledItem() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_F);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS, testAccount.Id, testPricebook.Id);

        // REQUIREMENT: Item_Class__c = 'F' AND Rep_Total_Unit_Discount__c = 0 AND SBQQ__TotalDiscountRate__c = 100 (Bundled)
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__ListPrice__c = 50,
            Item_Class__c = testProduct.Item_Class__c
        );
        insert quoteLine;

        quoteLine.SBQQ__Bundled__c = true;

        Test.startTest();
        update quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZVDI, conditions[0].SAP_Pricing_Condition__c, 'Should be ZVDI');
        System.assertEquals(PricingConditionConstants.CALCTYPON_M, conditions[0].SAP_CALCTYPON__c, 'Should be M');
        System.assertEquals(0, resultQuoteLine.Rep_Total_Unit_Discount__c, 'Rep_Total_Unit_Discount__c should be 0');
        System.assertEquals(100, resultQuoteLine.SBQQ__TotalDiscountRate__c, 'Discount rate should be 100%');
        // CONDITIONAL_SERVICE_BUNDLED
        Decimal price = - resultQuoteLine.SBQQ__ListPrice__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -50.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -250.0');
    }

    // ========================================
    // Pro_Rated_Unit_Price__c Logic
    // ========================================
    
    @IsTest
    static void testZVDI_Service_ProRated() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_F);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS, testAccount.Id, testPricebook.Id);

        // Create CPQ Quote Line for ZVDI with Pro_Rated_Unit_Price__c and Item Class F (Material)
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__ListPrice__c = 100,
            Pro_Rated_Unit_Price__c = 70,
            Item_Class__c = testProduct.Item_Class__c
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZVDI, conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals(PricingConditionConstants.CALCTYPON_M, conditions[0].SAP_CALCTYPON__c, 'Should be M');
        // CONDITIONAL_SERVICE_PRO_RATED
        Decimal price = resultQuoteLine.Pro_Rated_Unit_Price__c - resultQuoteLine.SBQQ__ListPrice__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -30.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -60.0');
    }

    // ========================================
    // INVOCABLE METHOD TEST
    // ========================================
    
    @IsTest
    static void invocableMethodTest() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct9 = getTestProduct(ITEM_CLASS_9);
        Product2 testProductF = getTestProduct(ITEM_CLASS_F);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // Create CPQ Quote Lines
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProductF.Id,
            SBQQ__Quantity__c = 1,
            Item_Class__c = testProductF.Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct9.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 75,
            Item_Class__c = testProduct9.Item_Class__c
        );

        insert new List<SBQQ__QuoteLine__c> {
            quoteLine1, quoteLine2
        };

        PricingConditionCompleteInv.FlowInput input1 = new PricingConditionCompleteInv.FlowInput();
        input1.quoteId = null;

        PricingConditionCompleteInv.FlowInput input2 = new PricingConditionCompleteInv.FlowInput();
        input2.quoteId = quote.Id;

        Test.startTest();
        PricingConditionCompleteInv.completePricingConditions(new List<PricingConditionCompleteInv.FlowInput>());
        PricingConditionCompleteInv.completePricingConditions(new List<PricingConditionCompleteInv.FlowInput>{input1});
        PricingConditionCompleteInv.completePricingConditions(new List<PricingConditionCompleteInv.FlowInput>{input2});
        Test.stopTest();

        // Verify that pricing conditions were created
        List<Pricing_Condition__c> conditions = [
            SELECT Id, SAP_Pricing_Condition__c, Quote_Line__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__c IN :new List<String>{quoteLine1.Id, quoteLine2.Id}
        ];
        System.assert(conditions.size() > 0, 'Should have created pricing conditions');
    }

    // ========================================
    // EDGE CASES AND UPDATE SCENARIOS
    // ========================================
    
    @IsTest
    static void testUpdateScenario_ChangeDiscount() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_1);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // Create initial quote line with discount
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__AdditionalDiscountAmount__c = 10,
            Item_Class__c = testProduct.Item_Class__c
        );
        insert quoteLine;

        // Change discount
        quoteLine.SBQQ__AdditionalDiscountAmount__c = 20;

        Test.startTest();
        update quoteLine;
        Test.stopTest();

        // Verify pricing condition was updated
        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        SBQQ__QuoteLine__c resultQuoteLine = getQuoteLine(quoteLine.Id);

        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals(PricingConditionConstants.ZSLS, conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals(PricingConditionConstants.CALCTYPON_C, conditions[0].SAP_CALCTYPON__c, 'Should be C');
        // CONDITIONAL_DISCOUNT
        Decimal price = - resultQuoteLine.Rep_Total_Unit_Discount__c;
        System.assertEquals(price, conditions[0].SAP_Unit_Price__c, 'Unit Price should be -20.0');
        System.assertEquals(price * resultQuoteLine.SBQQ__Quantity__c, conditions[0].SAP_Net_Price__c, 'Net Price should be -40.0');
    }

    @IsTest
    static void testNoConditionCreated_WhenNoTriggers() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct = getTestProduct(ITEM_CLASS_1);

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // Create quote line without any triggers for pricing conditions
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Item_Class__c = testProduct.Item_Class__c
        );

        Test.startTest();
        insert quoteLine;
        Test.stopTest();

        // Verify no pricing conditions were created
        List<Pricing_Condition__c> conditions = getPricingConditionsForQuoteLine(quoteLine.Id);
        System.assertEquals(0, conditions.size(), 'Should have no pricing conditions');
    }
}
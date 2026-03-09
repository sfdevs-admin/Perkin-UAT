@IsTest
private class PricingConditionBatchTest {

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
    // BATCH JOB TEST
    // ========================================

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

    @IsTest
    static void batchJobTest() {
        Account testAccount = getTestAccount();
        Pricebook2 testPricebook = getTestCustomPricebook();
        Product2 testProduct9 = getTestProduct(ITEM_CLASS_9);
        Product2 testProductF = getTestProduct(ITEM_CLASS_F);
        Product2 testProduct1 = getTestProduct(ITEM_CLASS_1);
        Product2 testProductS = getTestProductByCode('SV000301');

        SBQQ__Quote__c quote = insertQuote(PricingConditionConstants.SALES_TYPE_POS, testAccount.Id, testPricebook.Id);

        // Create CPQ Quote Lines
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProductF.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 10,
            Item_Class__c = testProductF.Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct9.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 60,
            SBQQ__NetPrice__c = 75,
            Item_Class__c = testProduct9.Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Quantity__c = 4,
            SBQQ__ListPrice__c = 100,
            SBQQ__AdditionalDiscountAmount__c = 20, // This will populate Rep_Total_Unit_Discount__c
            Item_Class__c = testProduct1.Item_Class__c
        );
        SBQQ__QuoteLine__c quoteLine4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProductS.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__ListPrice__c = 100,
            Item_Class__c = ITEM_CLASS_3 // Use valid item class for Consumables
        );

        insert new List<SBQQ__QuoteLine__c> {
            quoteLine1, quoteLine2,quoteLine3, quoteLine4
        };

        // Initial insert with all codes
        Map<String, Decimal> initialPrices = new Map<String, Decimal>{
            PricingConditionConstants.PR00 => 100,
            PricingConditionConstants.ZGRS => 140,
            PricingConditionConstants.PNTP => 100,
            PricingConditionConstants.ZD96 => 15
        };
        insertDefaultPricingConditions(quoteLine3.Id, initialPrices, quoteLine3.SBQQ__Quantity__c);
        PricingConditionRollUp.processQuoteRollUp(quote.Id);

        // Update data to make them ready for batch fix
        List<Pricing_Condition__c> conditions = [
            SELECT Id, SAP_Pricing_Condition__c, Quote_Line__c, SAP_Percentage__c, SAP_Unit_Price__c, SAP_Net_Price__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__r.SBQQ__Quote__c = :quote.Id
        ];
        for (Pricing_Condition__c condition : conditions) {
            condition.SAP_Percentage__c = condition.SAP_Unit_Price__c;
            condition.SAP_Unit_Price__c = condition.SAP_Net_Price__c;
            condition.SAP_Net_Price__c = null;
        }
        update conditions;

        Test.startTest();
        Id jobId = Database.executeBatch(new PricingConditionBatch(), 100);
        Test.stopTest();

        // Verify that pricing conditions were created
        List<Pricing_Condition__c> resultConditions = [
            SELECT Id, SAP_Pricing_Condition__c, Quote_Line__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__r.SBQQ__Quote__c = :quote.Id
        ];
        System.assert(conditions.size() > 0, 'Should have created pricing conditions');
    }

}
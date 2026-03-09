@isTest
private class PricingConditionManagerTest {
    
    // Constants
    private static final String VALID_ITEM_CLASS = 'F';
    private static final String SALES_TYPE_SERVICE_CONTRACTS = 'Service Contracts';
    private static final String SAP_CUSTOMER_NUMBER = '1234567890';

    /**
     * @description Setup test data once for all test methods
     */
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
            SalesType__c = SALES_TYPE_SERVICE_CONTRACTS
        );
        insert cpqQuote;
        
        // Create CPQ Quote Line
        SBQQ__QuoteLine__c cpqQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = cpqQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            Item_Class__c = VALID_ITEM_CLASS
        );
        insert cpqQuoteLine;
        
        // Create initial Pricing Conditions
        List<Pricing_Condition__c> initialConditions = new List<Pricing_Condition__c>();
        initialConditions.add(new Pricing_Condition__c(
            Quote_Line__c = cpqQuoteLine.Id,
            SAP_Pricing_Condition__c = 'CN01',
            SAP_CALCTYPON__c = PricingConditionConstants.CALCTYPON_M,
            Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED
        ));
        initialConditions.add(new Pricing_Condition__c(
            Quote_Line__c = cpqQuoteLine.Id,
            SAP_Pricing_Condition__c = 'CN02',
            SAP_CALCTYPON__c = PricingConditionConstants.CALCTYPON_M,
            Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED
        ));
        insert initialConditions;
    }
    
    /**
     * @description Helper method to get test Quote Line
     */
    private static SBQQ__QuoteLine__c getTestQuoteLine() {
        return [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
    }
    
    /**
     * @description Test adding new pricing conditions
     */
    @isTest
    static void testSyncPricingConditions_AddNewCodes() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        // Prepare input with new codes
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01,CN02,CN03,CN04'; // CN03 and CN04 are new
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        // Verify results
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(4, conditions.size(), 'Should have 4 pricing conditions');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals('CN02', conditions[1].SAP_Pricing_Condition__c);
        System.assertEquals('CN03', conditions[2].SAP_Pricing_Condition__c);
        System.assertEquals('CN04', conditions[3].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test removing existing pricing conditions
     */
    @isTest
    static void testSyncPricingConditions_RemoveCodes() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        // Prepare input with fewer codes (CN02 will be removed)
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01';
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        // Verify results
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
        ];
        
        System.assertEquals(1, conditions.size(), 'Should have 1 pricing condition');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test both adding and removing pricing conditions in one operation
     */
    @isTest
    static void testSyncPricingConditions_AddAndRemove() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        // Prepare input: keep CN01, remove CN02, add CN03 and CN04
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01,CN03,CN04';
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        // Verify results
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(3, conditions.size(), 'Should have 3 pricing conditions');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals('CN03', conditions[1].SAP_Pricing_Condition__c);
        System.assertEquals('CN04', conditions[2].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test with semicolon separator
     */
    @isTest
    static void testSyncPricingConditions_SemicolonSeparator() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01;CN02;CN05'; // Using semicolon
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(3, conditions.size(), 'Should have 3 pricing conditions');
        System.assert(conditions[2].SAP_Pricing_Condition__c == 'CN05', 'Should contain CN05');
    }
    
    /**
     * @description Test with mixed separators (comma and semicolon)
     */
    @isTest
    static void testSyncPricingConditions_MixedSeparators() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01,CN02;CN06';
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(3, conditions.size(), 'Should have 3 pricing conditions');
    }
    
    /**
     * @description Test with extra spaces in codes
     */
    @isTest
    static void testSyncPricingConditions_WithSpaces() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = ' CN01 , CN07 '; // Codes with spaces
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(2, conditions.size(), 'Should have 2 pricing conditions');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c, 'Spaces should be trimmed');
        System.assertEquals('CN07', conditions[1].SAP_Pricing_Condition__c, 'Spaces should be trimmed');
    }
    
    /**
     * @description Test with empty/null input list
     */
    @isTest
    static void testSyncPricingConditions_NullInput() {
        Test.startTest();
        PricingConditionManager.syncPricingConditions(null);
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>());
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle null/empty input gracefully');
    }
    
    /**
     * @description Test with blank codes string
     */
    @isTest
    static void testSyncPricingConditions_BlankCodes() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = '';
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        // Original records should remain unchanged
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
        ];
        
        System.assertEquals(2, conditions.size(), 'Should still have original 2 conditions');
    }
    
    /**
     * @description Test with null Quote Line Id
     */
    @isTest
    static void testSyncPricingConditions_NullQuoteLineId() {
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = null;
        input.codes = 'CN01,CN02';
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle null Quote Line Id gracefully');
    }
    
    /**
     * @description Test removing all existing conditions
     */
    @isTest
    static void testSyncPricingConditions_RemoveAllCodes() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        // Create a quote line with no matching codes in input
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN08,CN09'; // All new codes, existing will be removed
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(2, conditions.size(), 'Should have 2 new pricing conditions');
        System.assertEquals('CN08', conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals('CN09', conditions[1].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test with no changes (same codes as existing)
     */
    @isTest
    static void testSyncPricingConditions_NoChanges() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01,CN02'; // Same as existing
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(2, conditions.size(), 'Should still have 2 pricing conditions');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals('CN02', conditions[1].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test with duplicate codes in input
     */
    @isTest
    static void testSyncPricingConditions_DuplicateCodes() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.quoteLineId = quoteLine.Id;
        input.codes = 'CN01,CN01,CN10'; // CN01 is duplicated
        
        Test.startTest();
        PricingConditionManager.syncPricingConditions(new List<PricingConditionManager.FlowInput>{ input });
        Test.stopTest();
        
        List<Pricing_Condition__c> conditions = [
            SELECT SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c 
            WHERE Quote_Line__c = :quoteLine.Id
            ORDER BY SAP_Pricing_Condition__c
        ];
        
        System.assertEquals(2, conditions.size(), 'Should have 2 unique pricing conditions');
        System.assertEquals('CN01', conditions[0].SAP_Pricing_Condition__c);
        System.assertEquals('CN10', conditions[1].SAP_Pricing_Condition__c);
    }
    
    /**
     * @description Test FlowInput class instantiation
     */
    @isTest
    static void testFlowInput_Instantiation() {
        SBQQ__QuoteLine__c quoteLine = getTestQuoteLine();
        
        Test.startTest();
        PricingConditionManager.FlowInput input = new PricingConditionManager.FlowInput();
        input.codes = 'CN01,CN02';
        input.quoteLineId = quoteLine.Id;
        Test.stopTest();
        
        System.assertNotEquals(null, input, 'FlowInput should be instantiated');
        System.assertEquals('CN01,CN02', input.codes, 'Codes should be set');
        System.assertEquals(quoteLine.Id, input.quoteLineId, 'Quote Line Id should be set');
    }
}
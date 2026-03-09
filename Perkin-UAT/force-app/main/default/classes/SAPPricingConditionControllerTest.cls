@isTest
private class SAPPricingConditionControllerTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    private static final String serviceContractRecordTypeId = opportunityRecordTypes.get('ServiceContract').getRecordTypeId();

    // Constants for test data
    private static final String VALID_ITEM_CLASS = 'F';
    private static final String SALES_TYPE_SERVICE_CONTRACTS = 'Service Contracts';
    private static final String SAP_CUSTOMER_NUMBER = '1234567890';
    private static final Decimal DEFAULT_QUANTITY = 1;
    private static final Decimal DEFAULT_PRICE = 100;
    private static final Decimal STANDARD_PRICE = 100;
    
    /**
     * @description Setup test data once for all test methods
     * This is the Salesforce recommended approach for test data creation
     */
    @TestSetup
    static void setupTestData() {
        // Step 1: Create Account with required SAP Customer Number
        Account testAccount = createTestAccount();
        insert testAccount;
        
        // Step 2: Create Contact with required SAP Customer Number
        Contact testContact = createTestContact(testAccount.Id);
        insert testContact;
        
        // Step 3: Get Standard Pricebook (required for Pricebook setup)
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Step 4: Create Product with valid Item Class for Service Contracts
        Product2 testProduct = createTestProduct('Test Product', 'TEST-001', VALID_ITEM_CLASS);
        insert testProduct;
        
        // Step 5: Create Standard Pricebook Entry (required before custom pricebook entry)
        PricebookEntry standardPbe = createPricebookEntry(standardPricebookId, testProduct.Id, STANDARD_PRICE);
        insert standardPbe;
        
        // Step 6: Create Custom Pricebook
        Pricebook2 customPricebook = createPricebook('Test Pricebook');
        insert customPricebook;
        
        // Step 7: Create Custom Pricebook Entry
        PricebookEntry customPbe = createPricebookEntry(customPricebook.Id, testProduct.Id, DEFAULT_PRICE);
        insert customPbe;
        
        // Step 8: Create Opportunity linked to Account with Pricebook
        Opportunity testOpp = createTestOpportunity(testAccount.Id, customPricebook.Id);
        insert testOpp;
        
        // Step 9: Create CPQ Quote with Sales Type = Service Contracts and Pricebook
        SBQQ__Quote__c cpqQuote = createTestQuote(testOpp.Id, testAccount.Id, customPricebook.Id);
        insert cpqQuote;
        
        // Step 10: Create CPQ Quote Line with Product and Item_Class__c field
        SBQQ__QuoteLine__c cpqQuoteLine = createTestQuoteLine(cpqQuote.Id, testProduct.Id, DEFAULT_QUANTITY, DEFAULT_PRICE);
        insert cpqQuoteLine;
        
        // Step 11: Create Pricing Conditions
        List<Pricing_Condition__c> pricingConditions = createTestPricingConditions(cpqQuoteLine.Id);
        insert pricingConditions;
    }
    
    // ============================================
    // HELPER METHODS FOR TEST DATA CREATION
    // ============================================
    
    /**
     * @description Creates a test Account with SAP Customer Number
     * @return Account record ready for insert
     */
    private static Account createTestAccount() {
        return new Account(
            Name = 'Test Account',
            PKI_SAP_Customer_Number__c = SAP_CUSTOMER_NUMBER
        );
    }
    
    /**
     * @description Creates a test Contact with SAP Customer Number
     * @param accountId The Account Id to link the Contact to
     * @return Contact record ready for insert
     */
    private static Contact createTestContact(Id accountId) {
        return new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = accountId,
            PKI_SAP_Customer_Number__c = SAP_CUSTOMER_NUMBER
        );
    }
    
    /**
     * @description Creates a test Opportunity with Pricebook
     * @param accountId The Account Id to link the Opportunity to
     * @param pricebookId The Pricebook Id to assign to the Opportunity
     * @return Opportunity record ready for insert
     */
    private static Opportunity createTestOpportunity(Id accountId, Id pricebookId) {
        String recordTypeId = serviceContractRecordTypeId;
        String stageName = 'Stage 1 - Create';

        return new Opportunity(
            RecordTypeId = recordTypeId,
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = stageName,
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
    }
    
    /**
     * @description Creates a test Product with specified Item Class
     * @param productName The name of the product
     * @param productCode The product code
     * @param itemClass The IGOR Item Class (must be 3, 4, Q, A, 6, F, H, B, G, or 8 for Service Contracts)
     * @return Product2 record ready for insert
     */
    private static Product2 createTestProduct(String productName, String productCode, String itemClass) {
        return new Product2(
            Name = productName,
            ProductCode = productCode,
            IsActive = true,
            Item_Class__c = itemClass
        );
    }
    
    /**
     * @description Creates a custom Pricebook
     * @param pricebookName The name of the pricebook
     * @return Pricebook2 record ready for insert
     */
    private static Pricebook2 createPricebook(String pricebookName) {
        return new Pricebook2(
            Name = pricebookName,
            IsActive = true
        );
    }
    
    /**
     * @description Creates a Pricebook Entry
     * @param pricebookId The Pricebook Id
     * @param productId The Product Id
     * @param unitPrice The unit price
     * @return PricebookEntry record ready for insert
     */
    private static PricebookEntry createPricebookEntry(Id pricebookId, Id productId, Decimal unitPrice) {
        return new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
    }
    
    /**
     * @description Creates a test CPQ Quote with Pricebook
     * @param opportunityId The Opportunity Id to link the Quote to
     * @param accountId The Account Id to link the Quote to
     * @param pricebookId The Pricebook Id to assign to the Quote
     * @return SBQQ__Quote__c record ready for insert
     */
    private static SBQQ__Quote__c createTestQuote(Id opportunityId, Id accountId, Id pricebookId) {
        return new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Account__c = accountId,
            SBQQ__PricebookId__c = pricebookId,
            SBQQ__Primary__c = true,
            SalesType__c = SALES_TYPE_SERVICE_CONTRACTS
        );
    }
    
    /**
     * @description Creates a test CPQ Quote Line with Item_Class__c field populated
     * @param quoteId The Quote Id to link the Quote Line to
     * @param productId The Product Id to add to the Quote Line
     * @param quantity The quantity
     * @param netPrice The net price
     * @return SBQQ__QuoteLine__c record ready for insert
     */
    private static SBQQ__QuoteLine__c createTestQuoteLine(Id quoteId, Id productId, Decimal quantity, Decimal netPrice) {
        return new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = quantity,
            SBQQ__NetPrice__c = netPrice,
            Item_Class__c = VALID_ITEM_CLASS
        );
    }
    
    /**
     * @description Creates a test CPQ Quote Line with custom Item Class
     * @param quoteId The Quote Id to link the Quote Line to
     * @param productId The Product Id to add to the Quote Line
     * @param quantity The quantity
     * @param netPrice The net price
     * @param itemClass The Item Class value
     * @return SBQQ__QuoteLine__c record ready for insert
     */
    private static SBQQ__QuoteLine__c createTestQuoteLineWithItemClass(Id quoteId, Id productId, Decimal quantity, Decimal netPrice, String itemClass) {
        return new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = quantity,
            SBQQ__NetPrice__c = netPrice,
            Item_Class__c = itemClass
        );
    }
    
    /**
     * @description Creates a list of test Pricing Conditions (max 4 chars for SAP codes)
     * @param quoteLineId The Quote Line Id to link the Pricing Conditions to
     * @return List of Pricing_Condition__c records ready for insert
     */
    private static List<Pricing_Condition__c> createTestPricingConditions(Id quoteLineId) {
        List<Pricing_Condition__c> conditions = new List<Pricing_Condition__c>();
        
        conditions.add(new Pricing_Condition__c(
            Quote_Line__c = quoteLineId,
            Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED,
            SAP_Pricing_Condition__c = 'CN01' // 4 chars max
        ));
        
        conditions.add(new Pricing_Condition__c(
            Quote_Line__c = quoteLineId,
            Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED,
            SAP_Pricing_Condition__c = 'CN02' // 4 chars max
        ));
        
        conditions.add(new Pricing_Condition__c(
            Quote_Line__c = quoteLineId,
            SAP_Pricing_Condition__c = null
        ));
        
        return conditions;
    }
    
    /**
     * @description Retrieves the test Account
     * @return Account record from test data
     */
    private static Account getTestAccount() {
        return [SELECT Id, PKI_SAP_Customer_Number__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
    
    /**
     * @description Retrieves the test Pricebook
     * @return Pricebook2 record from test data
     */
    private static Pricebook2 getTestPricebook() {
        return [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
    }
    
    /**
     * @description Retrieves the test Quote
     * @return SBQQ__Quote__c record from test data
     */
    private static SBQQ__Quote__c getTestQuote() {
        return [SELECT Id, SalesType__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c WHERE SBQQ__Primary__c = true LIMIT 1];
    }
    
    /**
     * @description Retrieves the test Quote Line
     * @return SBQQ__QuoteLine__c record from test data
     */
    private static SBQQ__QuoteLine__c getTestQuoteLine() {
        return [SELECT Id, Item_Class__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quantity__c = :DEFAULT_QUANTITY LIMIT 1];
    }
    
    /**
     * @description Retrieves the test Product
     * @return Product2 record from test data
     */
    private static Product2 getTestProduct() {
        return [SELECT Id, Item_Class__c, ProductCode FROM Product2 WHERE ProductCode = 'TEST-001' LIMIT 1];
    }
    
    /**
     * @description Retrieves the test PricebookEntry
     * @return PricebookEntry record from test data
     */
    private static PricebookEntry getTestPricebookEntry() {
        Pricebook2 testPricebook = getTestPricebook();
        Product2 testProduct = getTestProduct();
        return [SELECT Id, UnitPrice FROM PricebookEntry 
                WHERE Pricebook2Id = :testPricebook.Id 
                AND Product2Id = :testProduct.Id LIMIT 1];
    }
    
    // ============================================
    // TEST METHODS
    // ============================================
    
    /**
     * @description Test getAllConditions method returns conditions successfully
     */
    @isTest
    static void testGetAllConditions_Success() {
        Test.startTest();
        List<SAPPricingConditionController.ConditionWrapper> conditions = 
            SAPPricingConditionController.getAllConditions();
        Test.stopTest();
        
        System.assertNotEquals(null, conditions, 'Conditions list should not be null');
        System.debug('Number of conditions returned: ' + conditions.size());
    }
    
    /**
     * @description Test getAllConditions method returns properly structured wrapper objects
     */
    @isTest
    static void testGetAllConditions_VerifyWrapperStructure() {
        Test.startTest();
        List<SAPPricingConditionController.ConditionWrapper> conditions = 
            SAPPricingConditionController.getAllConditions();
        Test.stopTest();
        
        if(!conditions.isEmpty()) {
            SAPPricingConditionController.ConditionWrapper firstCondition = conditions[0];
            
            System.assertNotEquals(null, firstCondition.code, 'Code should be accessible');
            System.assertNotEquals(null, firstCondition.label, 'Label should be accessible');
            System.assertNotEquals(null, firstCondition.developerName, 'DeveloperName should be accessible');
            System.assertNotEquals(null, firstCondition.isPrimary, 'IsPrimary should be accessible');
        }
    }
    
    /**
     * @description Test getPreSelectedCodes with a valid Quote Line Id
     */
    @isTest
    static void testGetPreSelectedCodes_WithValidQuoteLineId() {
        SBQQ__QuoteLine__c testQuoteLine = getTestQuoteLine();
        
        Test.startTest();
        List<String> selectedCodes = 
            SAPPricingConditionController.getPreSelectedCodes(testQuoteLine.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, selectedCodes, 'Selected codes list should not be null');
        System.assertEquals(2, selectedCodes.size(), 'Should return 2 non-null condition codes');
        System.assert(selectedCodes.contains('CN01'), 'Should contain CN01');
        System.assert(selectedCodes.contains('CN02'), 'Should contain CN02');
    }
    
    /**
     * @description Test getPreSelectedCodes with null Quote Line Id
     */
    @isTest
    static void testGetPreSelectedCodes_WithNullQuoteLineId() {
        Test.startTest();
        List<String> selectedCodes = 
            SAPPricingConditionController.getPreSelectedCodes(null);
        Test.stopTest();
        
        System.assertNotEquals(null, selectedCodes, 'Selected codes list should not be null');
        System.assertEquals(0, selectedCodes.size(), 'Should return empty list for null quote line ID');
    }
    
    /**
     * @description Test getPreSelectedCodes with an invalid Quote Line Id
     */
    @isTest
    static void testGetPreSelectedCodes_WithInvalidQuoteLineId() {
        Schema.DescribeSObjectResult describeResult = SBQQ__QuoteLine__c.SObjectType.getDescribe();
        String keyPrefix = describeResult.getKeyPrefix();
        Id fakeId = (Id)(keyPrefix + '0'.repeat(15));
        
        Test.startTest();
        List<String> selectedCodes = 
            SAPPricingConditionController.getPreSelectedCodes(fakeId);
        Test.stopTest();
        
        System.assertNotEquals(null, selectedCodes, 'Selected codes list should not be null');
        System.assertEquals(0, selectedCodes.size(), 'Should return empty list for non-existent quote line ID');
    }
    
    /**
     * @description Verify that test Quote and related records are set up correctly
     */
    @isTest
    static void testGetPreSelectedCodes_VerifyQuoteSetup() {
        SBQQ__Quote__c cpqQuote = getTestQuote();
        Account testAccount = getTestAccount();
        SBQQ__QuoteLine__c testQuoteLine = getTestQuoteLine();
        PricebookEntry pbe = getTestPricebookEntry();
        
        System.assertEquals(SALES_TYPE_SERVICE_CONTRACTS, cpqQuote.SalesType__c, 
            'CPQ Quote should have Sales Type set to Service Contracts');
        
        System.assertNotEquals(null, cpqQuote.SBQQ__PricebookId__c,
            'CPQ Quote should have Pricebook assigned');
        
        System.assertNotEquals(null, testAccount.PKI_SAP_Customer_Number__c, 
            'Account should have PKI SAP Customer Number');
        System.assertEquals(SAP_CUSTOMER_NUMBER, testAccount.PKI_SAP_Customer_Number__c,
            'Account PKI SAP Customer Number should match');
        
        System.assertEquals(VALID_ITEM_CLASS, testQuoteLine.Item_Class__c,
            'Quote Line should have valid Item Class for Service Contracts');
        
        System.assertEquals(DEFAULT_PRICE, pbe.UnitPrice,
            'Pricebook Entry should have correct unit price');
    }

    /**
     * @description Test ConditionWrapper constructor with valid values
     */
    @isTest
    static void testConditionWrapper_Constructor() {
        String testCode = 'T001';
        String testLabel = 'Test Label';
        String testDevName = 'Test_Dev_Name';
        Boolean testIsPrimary = true;
        String testDescription = 'Test Description';
        
        Test.startTest();
        SAPPricingConditionController.ConditionWrapper wrapper = 
            new SAPPricingConditionController.ConditionWrapper(
                testCode, 
                testLabel, 
                testDevName, 
                testIsPrimary, 
                testDescription
            );
        Test.stopTest();
        
        System.assertEquals(testCode, wrapper.code, 'Code should match');
        System.assertEquals(testLabel, wrapper.label, 'Label should match');
        System.assertEquals(testDevName, wrapper.developerName, 'Developer name should match');
        System.assertEquals(testIsPrimary, wrapper.isPrimary, 'IsPrimary should match');
        System.assertEquals(testDescription, wrapper.description, 'Description should match');
    }
    
    /**
     * @description Test ConditionWrapper constructor handles null values properly
     */
    @isTest
    static void testConditionWrapper_WithNullValues() {
        Test.startTest();
        SAPPricingConditionController.ConditionWrapper wrapper = 
            new SAPPricingConditionController.ConditionWrapper(
                null, 
                null, 
                null, 
                false, 
                null
            );
        Test.stopTest();
        
        System.assertEquals(null, wrapper.code, 'Code can be null');
        System.assertEquals(null, wrapper.label, 'Label can be null');
        System.assertEquals(null, wrapper.developerName, 'Developer name can be null');
        System.assertEquals(false, wrapper.isPrimary, 'IsPrimary should be false');
        System.assertEquals(null, wrapper.description, 'Description can be null');
    }
    
    /**
     * @description Negative test: Verify validation rule fires when Account lacks SAP Customer Number
     */
    @isTest
    static void testValidation_AccountWithoutSAPNumber() {
        Account accountWithoutSAP = new Account(
            Name = 'Account Without SAP',
            PKI_SAP_Customer_Number__c = null
        );
        insert accountWithoutSAP;
        
        Pricebook2 testPricebook = getTestPricebook();
        
        Opportunity testOpp = createTestOpportunity(accountWithoutSAP.Id, testPricebook.Id);
        insert testOpp;
        
        SBQQ__Quote__c cpqQuote = createTestQuote(testOpp.Id, accountWithoutSAP.Id, testPricebook.Id);
        
        Test.startTest();
        try {
            insert cpqQuote;
            System.assert(false, 'Should have thrown validation exception for missing SAP Customer Number');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('PKI SAP Customer Number') || 
                         e.getMessage().contains('RULE_QUOTE_001'), 
                'Exception should mention PKI SAP Customer Number: ' + e.getMessage());
        }
        Test.stopTest();
    }

}
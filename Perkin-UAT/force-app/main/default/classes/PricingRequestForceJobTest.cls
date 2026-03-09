@IsTest
private class PricingRequestForceJobTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI SPI Sales Process').getRecordTypeId();

    // Constants
    private static final String ITEM_CLASS_3 = '3';
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
        // Item Class 3 is valid for POS
        Product2 product3 = new Product2(
            Name = 'Test Product 3',
            ProductCode = 'TEST-003',
            IsActive = true,
            Item_Class__c = ITEM_CLASS_3
        );
        insert new List<Product2>{product3};

        // Create Pricebook Entries
        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TestDataFactory.createPricebookEntry(standardPricebookId, product3.Id),
            TestDataFactory.createPricebookEntry(customPricebook.Id, product3.Id)
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
        insert new List<SBQQ__QuoteLine__c>{quoteLine3};
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
    static void pricingRequestForceJobTest() {
        SBQQ__Quote__c quote = getTestQuote();
        quote.Price_Request_Status__c = PricingRequestForceJob.STATUS_FORCE;
        update quote;

        Test.startTest();
        PricingRequestForceJob nextJob = new PricingRequestForceJob();
        String cronStr = '0 ' + Datetime.now().addMinutes(1).minute() + ' * * * ?';
        System.schedule('Test-PricingRequestForce' + Datetime.now(), cronStr, nextJob);
        Test.stopTest();

        SBQQ__Quote__c resultQuote = [
            SELECT Id, Price_Request_Status__c, Price_Request_Stamp__c, Price_Response_Error__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];

        System.assertEquals(PricingRequestForceJob.STATUS_REQUESTED, resultQuote.Price_Request_Status__c, 'SAP Pricing should be Requested');
        System.assert(resultQuote.Price_Request_Stamp__c != null, 'SAP Pricing request stamp should be populated');
    }
}
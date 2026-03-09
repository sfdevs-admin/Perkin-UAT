@IsTest
private class OnDocumentFieldsServiceTest {

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
            Item_Class__c = product1.Item_Class__c,
            ContractStartDate__c = Date.today(),
            IPI_Amount__c = 100.1
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
    static void populateOnDocumentFieldsTest() {
        SBQQ__Quote__c quote = getTestQuote();
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_1
            LIMIT 1
        ];

        Test.startTest();
        quoteLine.ContractStartDate__c = Date.today().addMonths(1);
        quoteLine.ContractEndDate__c = Date.today().addMonths(5);
        quoteLine.MaterialSerialNumber__c = 'N876543';
        quoteLine.Foreign_Import_Control_Code__c = '76543';
        quoteLine.IPI_Amount__c = 1200.50;
        quoteLine.IPI_Percentage__c = 5.0;
        update quoteLine;
        Test.stopTest();

        List<SBQQ__QuoteLine__c> resultQuoteLine = [
            SELECT Id, On_Document_Coverage_Dates__c, On_Document_Material__c, On_Document_IPI__c,
                Contract_Start_Date_Formatted__c, Contract_End_Date_Formatted__c
            FROM SBQQ__QuoteLine__c
            WHERE Id  = :quoteLine.Id
        ];

        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_Coverage_Dates__c), 'Should populate On_Document_Coverage_Dates__c');
        String coverageDates = resultQuoteLine[0].On_Document_Coverage_Dates__c;
        System.assert(coverageDates.contains(resultQuoteLine[0].Contract_Start_Date_Formatted__c), 'Should contain formatted ContractStartDate__c');
        System.assert(coverageDates.contains(resultQuoteLine[0].Contract_End_Date_Formatted__c), 'Should contain formatted ContractEndDate__c');
        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_Material__c), 'Should populate On_Document_Material__c');
        String material = resultQuoteLine[0].On_Document_Material__c;
        System.assert(material.contains(quoteLine.MaterialSerialNumber__c), 'Should contain MaterialSerialNumber__c');
        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_IPI__c), 'Should populate On_Document_IPI__c');
        String ipi = resultQuoteLine[0].On_Document_IPI__c;
        System.assert(ipi.contains(quoteLine.Foreign_Import_Control_Code__c), 'Should contain Foreign_Import_Control_Code__c');
    }

    @IsTest
    static void populateAfterLanguageChangeTest() {
        SBQQ__Quote__c quote = getTestQuote();
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            AND Item_Class__c = :ITEM_CLASS_1
            LIMIT 1
        ];

        quoteLine.ContractStartDate__c = Date.today().addMonths(1);
        quoteLine.ContractEndDate__c = Date.today().addMonths(5);
        quoteLine.MaterialSerialNumber__c = 'N876543';
        quoteLine.Foreign_Import_Control_Code__c = '76543';
        quoteLine.IPI_Amount__c = 1212.12;
        quoteLine.IPI_Percentage__c = 1.2;
        update quoteLine;

        Test.startTest();
        quote.BD_Quote_Language__c = 'pt_BR';
        update quote;
        Test.stopTest();

        List<SBQQ__QuoteLine__c> resultQuoteLine = [
            SELECT Id, On_Document_Coverage_Dates__c, On_Document_Material__c, On_Document_IPI__c,
                Contract_Start_Date_Formatted__c, Contract_End_Date_Formatted__c
            FROM SBQQ__QuoteLine__c
            WHERE Id  = :quoteLine.Id
        ];

        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_Coverage_Dates__c), 'Should populate On_Document_Coverage_Dates__c');
        String coverageDates = resultQuoteLine[0].On_Document_Coverage_Dates__c;
        System.assert(coverageDates.contains(resultQuoteLine[0].Contract_Start_Date_Formatted__c), 'Should contain formatted ContractStartDate__c');
        System.assert(coverageDates.contains(resultQuoteLine[0].Contract_End_Date_Formatted__c), 'Should contain formatted ContractEndDate__c');
        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_Material__c), 'Should populate On_Document_Material__c');
        String material = resultQuoteLine[0].On_Document_Material__c;
        System.assert(material.contains(quoteLine.MaterialSerialNumber__c), 'Should contain MaterialSerialNumber__c');
        System.assert(String.isNotBlank(resultQuoteLine[0].On_Document_IPI__c), 'Should populate On_Document_IPI__c');
        String ipi = resultQuoteLine[0].On_Document_IPI__c;
        System.assert(ipi.contains(quoteLine.Foreign_Import_Control_Code__c), 'Should contain Foreign_Import_Control_Code__c');
    }

    @IsTest
    static void populateOnDocumentQuoteFieldsTest() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        quote.Billing_Cycle__c = 'Bi Annual';
        quote.Foreign_Import_Control_Code__c = '76543';
        quote.Quote_Type__c = 'Preliminary Quote';
        quote.SBQQ__PaymentTerms__c = 'Net 60 after Installation';
        quote.Tax_Exempt__c = 'Yes';
        quote.ContractStartDate__c = Date.today().addMonths(1);
        quote.ContractEndDate__c = Date.today().addMonths(5);
        update quote;
        quote.BD_Quote_Language__c = 'pt_BR';
        update quote;
        Test.stopTest();

        List<SBQQ__Quote__c> resultQuote = [
            SELECT Id, Expiration_Date_Formatted__c, Quote_Date_Formatted__c,
                Contract_Start_Date_Formatted__c, Contract_End_Date_Formatted__c,
                Quote_Document_Tax_Exempt__c, Quote_Document_Type__c, Quote_Document_Billing_Cycle__c,
                Quote_Document_Payment_Terms__c
            FROM SBQQ__Quote__c
            WHERE Id  = :quote.Id
        ];

        //System.assert(String.isNotBlank(resultQuote[0].Expiration_Date_Formatted__c), 'Should populate Expiration_Date_Formatted__c');
        //System.assert(String.isNotBlank(resultQuote[0].Quote_Date_Formatted__c), 'Should populate Quote_Date_Formatted__c');
        //System.assert(String.isNotBlank(resultQuote[0].Contract_Start_Date_Formatted__c), 'Should populate Contract_Start_Date_Formatted__c');
        //System.assert(String.isNotBlank(resultQuote[0].Contract_End_Date_Formatted__c), 'Should populate Contract_End_Date_Formatted__c');
        //System.assertEquals('Sim', resultQuote[0].Quote_Document_Tax_Exempt__c, 'Should be proper Quote_Document_Tax_Exempt__c = Sim');
        //System.assertEquals('COTAÇÃO PRELIMINAR', resultQuote[0].Quote_Document_Type__c, 'Should be proper Quote_Document_Type__c = COTAÇÃO PRELIMINAR');
        //System.assertEquals('Semestral', resultQuote[0].Quote_Document_Billing_Cycle__c, 'Should be proper Quote_Document_Billing_Cycle__c = Semestral');
        //System.assertEquals('60 dias líquidos após a instalação', resultQuote[0].Quote_Document_Payment_Terms__c, 'Should be proper Quote_Document_Payment_Terms__c');
    }
}
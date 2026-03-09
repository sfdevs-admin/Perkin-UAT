@IsTest
private class QuoteDocumentControllerTest {

    // Constants
    private static final String VALID_ITEM_CLASS = '3';
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

        // Create Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;

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

        // Create SBQQ__QuoteTemplate__c
        SBQQ__QuoteTemplate__c qt1 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Header');
        SBQQ__QuoteTemplate__c qt2 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Executive Summary');
        SBQQ__QuoteTemplate__c qt3 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Main');
        SBQQ__QuoteTemplate__c qt4 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Product Details');
        SBQQ__QuoteTemplate__c qt5 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Product Literature');
        SBQQ__QuoteTemplate__c qt6 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Included Parts');
        SBQQ__QuoteTemplate__c qt7 = new SBQQ__QuoteTemplate__c(Name = 'Quote - Financing Options');
        insert new List<SBQQ__QuoteTemplate__c> {qt1, qt2, qt3, qt4, qt5, qt6, qt7};
    }

    @IsTest
    static void prepareSectionsTest() {
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        String documentName = quote.Name + '-Test';

        quote.BD_Quote_Language__c = 'en_US';
        quote.Quote_Page__c = true;
        quote.Header_Page__c = true;
        quote.Executive_Summary_Page__c = true;
        quote.Quote_Highlights_Page__c = false;
        quote.Marketing_Collateral_Page__c = false;
        quote.Included_Parts_Page__c = true;
        quote.Financing_Leasing_Page__c = false;
        update quote;

        String result;
        Test.startTest();
        result = QuoteDocumentController.prepareSections(quote.Id, documentName);
        Test.stopTest();

        List<QuoteDocumentController.QuoteDocumentParams> sectionParams =
            (List<QuoteDocumentController.QuoteDocumentParams>)JSON.deserialize(
                result, List<QuoteDocumentController.QuoteDocumentParams>.class
            );
        System.assertEquals(4, sectionParams.size(), 'Should have 4 sections');
    }

    @IsTest
    static void checkJobStatusTest() {
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Status = 'Completed' LIMIT 1];

        String result;
        Test.startTest();
        result = QuoteDocumentController.checkJobStatus(job.Id);
        Test.stopTest();

        System.assertEquals(job.Status, result, 'Should have Completed status');
    }

    @IsTest
    static void saveSectionTest() {
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTemplate__c template = [SELECT Id, Name FROM SBQQ__QuoteTemplate__c WHERE Name = 'Quote - Main' LIMIT 1];
        String documentName = quote.Name + '-Test';
        //String quoteId, String templateId, String fileName, String language

        String jobId;
        Test.startTest();
        jobId = QuoteDocumentController.saveSection(quote.Id, template.Id, documentName + '.pdf', 'en_US');
        Test.stopTest();

        System.assert(String.isNotBlank(jobId), 'Should return AsyncApexJob Id');
    }

    @IsTest
    static void getSectionIdsTest() {
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTemplate__c template = [SELECT Id, Name FROM SBQQ__QuoteTemplate__c WHERE Name = 'Quote - Main' LIMIT 1];
        String documentName = quote.Name + '-Test';

        Document testDocBody = new Document(
            Name = 'Test DOC1.txt',
            FolderId = UserInfo.getUserId(),
            Body = Blob.valueOf('ABCDEF')
        );
        insert testDocBody;

        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
            Name = documentName + '-03',
            SBQQ__Quote__c = quote.Id,
            SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c,
            SBQQ__QuoteTemplate__c = template.Id,
            SBQQ__DocumentId__c = testDocBody.Id
        );
        insert doc;

        List<String> result;
        Test.startTest();
        result = QuoteDocumentController.getSectionIds(quote.Id, documentName);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should have 1 section Id');
        System.assertEquals(testDocBody.Id, result[0], 'Should return test section Id');
    }

    @IsTest
    static void deleteSectionsTest() {
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTemplate__c template = [SELECT Id, Name FROM SBQQ__QuoteTemplate__c WHERE Name = 'Quote - Main' LIMIT 1];
        String documentName = quote.Name + '-Test';
        //String quoteId, String templateId, String fileName, String language

        Document testDocBody = new Document(
            Name = 'Test DOC1.txt',
            FolderId = UserInfo.getUserId(),
            Body = Blob.valueOf('ABCDEF')
        );
        insert testDocBody;

        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
            Name = documentName + '-03',
            SBQQ__Quote__c = quote.Id,
            SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c,
            SBQQ__QuoteTemplate__c = template.Id,
            SBQQ__DocumentId__c = testDocBody.Id
        );
        insert doc;

        Test.startTest();
        QuoteDocumentController.deleteSections(quote.Id, documentName);
        Test.stopTest();
    }

}
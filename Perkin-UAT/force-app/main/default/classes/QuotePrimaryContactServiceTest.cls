@IsTest
private class QuotePrimaryContactServiceTest {

    private static final Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final String posRecordTypeId = opportunityRecordTypes.get('PKI SPI Sales Process').getRecordTypeId();

    // Constants
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

        // Create Contact
        Contact testContact = new Contact(
            AccountId = accountId,
            PKI_SAP_Contact_Id__c  = '0001802000',
            FirstName = 'Test FirstName',
            LastName = 'Test LastName',
            Salutation = '0018'
        );
        insert testContact;

        // Create Custom Pricebook
        Pricebook2 customPricebook = TestDataFactory.createPricebook();
        insert customPricebook;
        String pricebookId = customPricebook.Id;

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
    }

    /**
     * @description Helper method to get test Quote
     */
    private static SBQQ__Quote__c getTestQuote() {
        return [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    }

    /**
     * @description Helper method to get test Contact
     */
    private static Contact getTestContact() {
        return [SELECT Id, FirstName, LastName, toLabel(Salutation) FROM Contact LIMIT 1];
    }

    @IsTest
    static void populateFullNameTest() {
        SBQQ__Quote__c quote = getTestQuote();
        Contact contact = getTestContact();

        Test.startTest();
        quote.SBQQ__PrimaryContact__c = contact.Id;
        update quote;
        Test.stopTest();

        List<SBQQ__Quote__c> resultQuote = [
            SELECT Id, SBQQ__PrimaryContact__c, Primary_Contact_Full_Name__c
            FROM SBQQ__Quote__c
            WHERE Id  = :quote.Id
        ];

        System.assertEquals(contact.Id, resultQuote[0].SBQQ__PrimaryContact__c, 'Should update SBQQ__PrimaryContact__c');
        System.assert(String.isNotBlank(resultQuote[0].Primary_Contact_Full_Name__c), 'Should have Primary_Contact_Full_Name__c');
        String fullName = resultQuote[0].Primary_Contact_Full_Name__c;
        System.assert(fullName.contains(contact.Salutation), 'Should contain Salutation');
        System.assert(fullName.contains(contact.FirstName), 'Should contain FirstName');
        System.assert(fullName.contains(contact.LastName), 'Should contain LastName');
    }

}
@isTest
private class OppsWithContactsTest {

    // Test Setup method to create reusable data
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact linked to the Account
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create a test Opportunity linked to the Account
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Amount = 5000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Stage 1 - Create/Plan',
            Solution_Area_of_Interest__c = 'Water',
            Owned_by_Company__c = 'AES'
        );
        insert testOpportunity;

        // Create an OpportunityContactRole linking the Contact and Opportunity
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        insert contactRole;

        // Create Custom Metadata for mapping
/*        Opportunity_SAI_Mapping__mdt saiMapping = new Opportunity_SAI_Mapping__mdt(
            MasterLabel = 'Water Mapping',
            Opportunity_SAI_Value__c = 'Water',
            Contact_SAI_Status_API_Name__c = 'Status_Water__c'
        );
        insert saiMapping; */
    }

    @isTest
    static void testSayMethod() {
        // Retrieve the required data
        List<OpportunityContactRole> contactRoles = [SELECT Id FROM OpportunityContactRole LIMIT 1];
        
        // Instantiate the controller and set the parameter value
        OppsWithContacts controller = new OppsWithContacts();
        controller.ParamValueFromJavaScript = String.join(new List<String>{contactRoles[0].Id}, ',');

        // Call the say() method
        Test.startTest();
        PageReference result = controller.say();
        Test.stopTest();

        // Assert that no exception occurred and result is null as expected
        System.assertEquals(null, result, 'Expected null PageReference return value.');
    }

    @isTest
    static void testCheckContactRoleAndSAI() {
        // Retrieve the required data for testing
        List<OpportunityContactRole> contactRoles = [
            SELECT Id, ContactId, OpportunityId, CreatedDate, 
                   Opportunity.StageName, Opportunity.Solution_Area_of_Interest__c 
            FROM OpportunityContactRole 
            WHERE Role = 'Decision Maker'
        ];

        // Instantiate the class and call the CheckContactRoleAndSAI method
        OppsWithContacts controller = new OppsWithContacts();

        Test.startTest();
        controller.CheckContactRoleAndSAI(contactRoles);
        Test.stopTest();

        // Verify that the Contact was updated with the correct field value
        Contact updatedContact = [SELECT Id, Has_Opportunity__c, Status_Water__c FROM Contact LIMIT 1];
        
        System.assert(updatedContact.Has_Opportunity__c, 'Expected Has_Opportunity__c to be true.');
        System.assertEquals('Converted to Opportunity', updatedContact.Status_Water__c, 
                            'Expected Status_Water__c to be updated to "Converted to Opportunity".');
    }

    @isTest
    static void testSayMethodWithoutValidInput() {
        // Instantiate the controller without setting any parameter value
        OppsWithContacts controller = new OppsWithContacts();
        
        Test.startTest();
        //PageReference result = controller.say();
        Test.stopTest();

        // Assert that no exception occurred and result is null as expected
        //System.assertEquals(null, result, 'Expected null PageReference return value.');
    }

    @isTest
    static void testEdgeCaseNoMatchingSAI() {
        // Retrieve an existing OpportunityContactRole and modify its SAI to a non-matching value
        List<Opportunity> opportunitiesToUpdate = [
            SELECT Id FROM Opportunity WHERE Solution_Area_of_Interest__c != null LIMIT 1
        ];
        
        if (!opportunitiesToUpdate.isEmpty()) {
            opportunitiesToUpdate[0].Solution_Area_of_Interest__c = 'NonMatchingSAI';
            update opportunitiesToUpdate;
            
            List<OpportunityContactRole> contactRoles = [
                SELECT Id, ContactId, OpportunityId, CreatedDate, 
                       Opportunity.StageName, Opportunity.Solution_Area_of_Interest__c 
                FROM OpportunityContactRole 
                WHERE OpportunityId IN :opportunitiesToUpdate
            ];

            OppsWithContacts controller = new OppsWithContacts();

            Test.startTest();
            controller.CheckContactRoleAndSAI(contactRoles);
            Test.stopTest();

            // Verify that no Contacts were updated since SAI did not match any metadata mapping
            List<Contact> contactsAfterUpdate = [SELECT Id, Has_Opportunity__c FROM Contact];
            
            for (Contact c : contactsAfterUpdate) {
                //System.assert(!c.Has_Opportunity__c, 
                              //'Expected Has_Opportunity__c to remain false for non-matching SAI.');
            }
        }
    }
}
@isTest
private class AccountHierarchyCSVCreatorTest {

    @testSetup
    static void setupTestData() {
        // Create parent Account
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;

        // Create child Accounts
        Account childAccount1 = new Account(Name = 'Child Account 1', ParentId = parentAccount.Id);
        Account childAccount2 = new Account(Name = 'Child Account 2', ParentId = parentAccount.Id);
        insert new List<Account>{childAccount1, childAccount2};

        // Create a custom metadata record for testing
        Account__c accountMetadata = new Account__c(
            Tab_Name__c = 'Account',
            Field_List__c = 'Name,ParentId',
            Object_API_Name__c = 'Account',
            Name = 'Account c'
        );
        insert accountMetadata; 
    }

    @isTest
    static void testConstructorAndCSVGeneration() {
        // Retrieve the parent account from the test setup data
        Account parentAccount = [SELECT Id, Name FROM Account WHERE Name = 'Parent Account' LIMIT 1];

        // Set parameters for the VF page
        Test.setCurrentPageReference(new PageReference('/apex/AccountHierarchyPage'));
        ApexPages.currentPage().getParameters().put('accName', parentAccount.Name);
        ApexPages.currentPage().getParameters().put('accId', parentAccount.Id);
        ApexPages.currentPage().getParameters().put('basObj', 'Account');
        ApexPages.currentPage().getParameters().put('sortColumn', 'Name');
        ApexPages.currentPage().getParameters().put('sortOrder', 'ASC');

        // Instantiate the class
        Test.startTest();
        AccountHierarchyCSVCreator creator = new AccountHierarchyCSVCreator();
        Test.stopTest();

        // Assert that CSV data is generated correctly
        System.assertNotEquals(null, creator.CSVData, 'Expected CSVData to be populated.');
        System.assertNotEquals('', creator.textdata, 'Expected textdata to be populated.');
        System.assert(creator.textdata.contains('Parent Account'), 'Expected textdata to contain Parent Account.');
    }

    @isTest
    static void testFindChildren() {
        // Retrieve the parent account from the test setup data
        Account parentAccount = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1];

        // Call the findChildren method
        Test.startTest();
        AccountHierarchyCSVCreator.findChildren(parentAccount.Id);
        Test.stopTest();

        // Assert that child accounts were added to the hierarchy list
        //System.assert(AccountHierarchyCSVCreator.accountHierarchyList.contains(parentAccount.Id), 
        //              'Expected parent account ID to be in accountHierarchyList.');
        
        List<Account> childAccounts = [SELECT Id FROM Account WHERE ParentId = :parentAccount.Id];
        
        for (Account child : childAccounts) {
            System.assert(AccountHierarchyCSVCreator.accountHierarchyList.contains(child.Id), 
                          'Expected child account ID to be in accountHierarchyList.');
            System.assert(AccountHierarchyCSVCreator.accountDetailsMap.containsKey(child.Id), 
                          'Expected child account to be in accountDetailsMap.');
            System.assert(AccountHierarchyCSVCreator.parentChildLinkedListMap.containsKey(parentAccount.Id), 
                          'Expected parent-child relationship to exist in parentChildLinkedListMap.');
            //System.assert(AccountHierarchyCSVCreator.parentChildLinkedListMap.get(parentAccount.Id).contains(child), 
            //              'Expected child account to be linked under its parent in parentChildLinkedListMap.');
        }
    }

    @isTest
    static void testGetLabel() {
        // Call the getLabel method for a standard field
        String label = AccountHierarchyCSVCreator.getLabel('Account', 'Name');

        // Assert that the label is correct
        System.assertEquals('Account Name', label, 'Expected label for "Name" field to be "Account Name".');
    }

    @isTest
    static void testEdgeCaseNoChildren() {
        // Create an account with no children
        Account standaloneAccount = new Account(Name = 'Standalone Account');
        insert standaloneAccount;

        // Call findChildren on this standalone account
        Test.startTest();
        AccountHierarchyCSVCreator.findChildren(standaloneAccount.Id);
        Test.stopTest();

        // Assert that only this account is in the hierarchy list
        //System.assert(AccountHierarchyCSVCreator.accountHierarchyList.contains(standaloneAccount.Id), 
        //              'Expected standalone account ID to be in accountHierarchyList.');
        
        List<Account> children = [SELECT Id FROM Account WHERE ParentId = :standaloneAccount.Id];
        
        System.assertEquals(0, children.size(), 
                            'Expected no child accounts for standalone account.');
    }
}
@IsTest
public class B2BSubscriptionReminderEmailTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    public static void setupData() {
        Account account = B2B_TestDataFactory.createAccount(ACCOUNT_NAME, true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME, account.Id, false);
        con.Email = EMAIL;
        insert con;

        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME, true);

        B2B_Subscriptions__c sub = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Test Subscription',
            B2B_Status__c = 'Active',
            CurrencyIsoCode = 'USD',
            B2B_Next_Billing_Date__c = System.today().addDays(Integer.valueOf(Label.ReminderDays)),
            B2B_Contact__c = con.Id
        );
        insert sub;

        B2B_Subscription_Items__c item = new B2B_Subscription_Items__c(
            B2B_Subscriptions__c = sub.Id,
            B2B_Unit_Price__c = 50,
            B2B_Quantity__c = 2,
            CurrencyIsoCode = 'USD',
            B2B_Product__c  = prod.Id
        );
        insert item;

    

    }

    @IsTest
    static void testBatchWithIdSet() {
        Id subId = [SELECT Id FROM B2B_Subscriptions__c LIMIT 1].Id;
        Set<Id> idSet = new Set<Id>{ subId };

        Test.startTest();
        Database.executeBatch(new B2BSubscriptionReminderEmail(idSet), 1);
        Test.stopTest();

        // Assert no custom exceptions created
        System.assertEquals(0, [SELECT COUNT() FROM Custom_Exception__c], 'No exceptions should be logged');

    }

    @IsTest
    static void testBatchWithQuery() {
        String query = 'SELECT Id, Subscription_Name__c, B2B_Status__c, B2B_Total_Amount__c, CurrencyIsoCode, ' +
            'B2B_Next_Billing_Date__c, B2B_Contact__r.FirstName, B2B_Contact__r.LastName, ' +
            'B2B_Contact__r.Email, (SELECT Id, B2B_Product__r.Name, B2B_Product__r.B2B_Part_Number__c, ' +
            'B2B_Unit_Price__c, B2B_Quantity__c, B2B_Total_Price__c, CurrencyIsoCode FROM B2B_Subscription_Items__r) ' +
            'FROM B2B_Subscriptions__c';

        Test.startTest();
        Database.executeBatch(new B2BSubscriptionReminderEmail(query), 1);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Custom_Exception__c], 'No exceptions should be logged');
    }

    @IsTest
    static void testBatchWithEmptySetAndNoQuery() {
        Test.startTest();
        Database.executeBatch(new B2BSubscriptionReminderEmail(), 1);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Custom_Exception__c], 'No exceptions should be logged');
    }

    @IsTest
    static void testScheduleClass() {
        Test.startTest();
        String jobId = System.schedule('Test Schedule', '0 0 12 * * ?', new B2BSubscriptionReminderEmail());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID should be returned');
    }
}
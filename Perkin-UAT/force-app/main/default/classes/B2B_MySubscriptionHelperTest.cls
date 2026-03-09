@IsTest
private class B2B_MySubscriptionHelperTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            CurrencyIsoCode = 'USD'
		);
        insert testAccount;

        // Create Subscription
        B2B_Subscriptions__c subscription = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Test Subscription',
            Description__c = 'Monthly test plan',
            B2B_Account__c = testAccount.Id,
            B2B_Status__c = 'Active',
            B2B_Billing_Frequency__c = 'Monthly',
            B2B_Shipping_Method__c = 'Ground',
            B2B_Payment_Method__c = 'Credit Card'
        );
        insert subscription;

        // Create Product
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            B2B_Display_Name__c = 'Display Product',
            B2B_Part_Number__c = 'TP-001',
            B2B_Short_Description__c = 'Short description'
        );
        insert product;

        // Create Subscription Item
        B2B_Subscription_Items__c item = new B2B_Subscription_Items__c(
            B2B_Subscriptions__c = subscription.Id,
            B2B_Product__c = product.Id,
            B2B_Quantity__c = 2,
            B2B_Unit_Price__c = 99.99,
            CurrencyIsoCode = 'USD'
        );
        insert item;
    }

    @IsTest
    static void testGetSubscriptionListsHelper() {
        Account testAccount = [SELECT Id FROM Account WHERE CurrencyIsoCode != null LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'accountId' => testAccount.Id
        };

        Map<String, Object> result = B2B_MySubscriptionHelper.getSubscriptionListsHelper(input);

        System.assertEquals(true, result.get('isSuccess'));
        List<B2B_SubscriptionWrapper> subscriptionLists = (List<B2B_SubscriptionWrapper>) result.get('subscriptionLists');
        System.assertNotEquals(0, subscriptionLists.size());
        System.assertEquals('Test Subscription', subscriptionLists[0].subscriptionName);
    }

    @IsTest
    static void testGetSubscriptionItemsHelper() {
        B2B_Subscriptions__c subscription = [SELECT Id FROM B2B_Subscriptions__c LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'subscriptionId' => subscription.Id
        };

        Map<String, Object> result = B2B_MySubscriptionHelper.getSubscriptionItemsHelper(input);

        System.assertEquals(true, result.get('isSuccess'));
        B2B_SubscriptionWrapper wrapper = (B2B_SubscriptionWrapper) result.get('subscriptionData');
        System.assertEquals('Test Subscription', wrapper.subscriptionName);
        System.assertEquals(1, wrapper.items.size());
        System.assertEquals('TP-001', wrapper.items[0].sku);
    }

    @IsTest
    static void testGetSubscriptionItemsHelper_noItems() {
        // Create another subscription without items
        Account testAccount = [SELECT Id FROM Account WHERE CurrencyIsoCode != null LIMIT 1];
        B2B_Subscriptions__c emptySub = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Empty Sub',
            B2B_Account__c = testAccount.Id,
            B2B_Status__c = 'Inactive',
            B2B_Billing_Frequency__c = 'Weekly'
        );
        insert emptySub;

        Map<String, Object> input = new Map<String, Object>{
            'subscriptionId' => emptySub.Id
        };

        Map<String, Object> result = B2B_MySubscriptionHelper.getSubscriptionItemsHelper(input);

        //System.assertEquals(false, result.get('isSuccess'));
        System.assert(result.get('message') != null);
    }

    @IsTest
    static void testGetSubscriptionItemsHelper_invalidInput() {
        Map<String, Object> input = new Map<String, Object>{
            'subscriptionId' => null
        };

        Map<String, Object> result = B2B_MySubscriptionHelper.getSubscriptionItemsHelper(input);

        System.assertEquals(false, result.get('isSuccess'));
        System.assert(((String)result.get('message')).contains('Missing subscriptionId'));
    }
}
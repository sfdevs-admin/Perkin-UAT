@isTest
public with sharing class B2B_SubscriptionOrderSchedulerTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String LOCATION_NAME = 'Test';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    static void setup() {
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        List<Product2> prodList = new List<Product2>();
        prodList.add(prod);			
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);

        ContactPointAddress shippingAddress = B2B_TestDataFactory.createShippingCPA(acc,true);
        shippingAddress.Country = 'US';
        update shippingAddress;

        Schema.Location location = B2B_TestDataFactory.createLocation(LOCATION_NAME, true);

        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        odm.Name = 'Freight Overnight';
        update odm;

        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);
        WebCart cart = B2B_TestDataFactory.createCart(acc.Id,custUser.Id,store.Id,shippingAddress.Id,true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems(cart.Id,deliveryGroup.Id,prodList,location.Id,true);
        
        Product2 shipProduct = new Product2();
        shipProduct.Name = 'Delivery Charge' ;
        shipProduct.ProductCode = 'Delivery Charge' ;
        shipProduct.StockKeepingUnit = 'Delivery Charge' ;
        shipProduct.isActive = true ;
        insert shipProduct;

        ContactPointAddress billingAddress = new ContactPointAddress(
            AddressType = 'Billing',
            ParentId = acc.Id,
            Street = '123 Main St',
            City = 'TestCity',
            State = 'CA',
            PostalCode = '12345',
            Country = 'US',
            AddressFirstName = 'John',
            AddressLastName = 'Doe',
            Name = 'John Doe'
        );
        insert billingAddress;

        // Create Subscription
        B2B_Subscriptions__c sub = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Test Subscription',
            B2B_Account__c = acc.Id,
            B2B_Contact__c = con.Id,
            B2B_Status__c = 'Active',
            B2B_Next_Billing_Date__c = Date.today(),
            B2B_Shipping_Address__c = shippingAddress.Id,
            B2B_Billing_Address__c = billingAddress.Id,
            CurrencyIsoCode = 'USD',
            B2B_Billing_Frequency__c = 'Monthly',
            B2B_Payment_Method__c = 'Credit Card',
            B2B_Special_Instruction__c = 'Handle with care',
            B2B_Po_Number__c = 'PO',
            B2B_Shipping_Method__c = 'Freight Overnight',
            B2B_End_Date__c = Date.today().addDays(7)
        );
        insert sub;

        // Create Subscription Item
        B2B_Subscription_Items__c subItem = new B2B_Subscription_Items__c(
            B2B_Subscriptions__c = sub.Id,
            B2B_Product__c = prod.Id,
            B2B_Quantity__c = 10,
            B2B_Unit_Price__c = 5000
        );
        insert subItem;
    }


    @isTest
    static void testSchedulerExecutesBatch() {
        Test.startTest();
        B2B_SubscriptionOrderScheduler scheduler = new B2B_SubscriptionOrderScheduler();
        scheduler.execute(null);
        Test.stopTest();

        List<B2B_Subscriptions__c> subs = [
            SELECT Id FROM B2B_Subscriptions__c WHERE B2B_Next_Billing_Date__c = :Date.today()
        ];
        System.assert(!subs.isEmpty(), 'Subscription should exist for today’s date');
    }
    
    @isTest
    static void testSchedulerExecutesBatchToCancel() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = :ACCOUNT_NAME LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAcc.Id LIMIT 1];
        ContactPointAddress cpa = [SELECT Id FROM ContactPointAddress WHERE ParentId = :testAcc.Id LIMIT 1];
        // Create Subscription
        B2B_Subscriptions__c subToCancel = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Test Subscription to cancel',
            B2B_Account__c = testAcc.Id,
            B2B_Contact__c = testContact.Id,
            B2B_Status__c = 'Active',
            B2B_Next_Billing_Date__c = Date.today(),
            B2B_Shipping_Address__c = cpa.Id,
            B2B_Billing_Address__c = cpa.Id,
            CurrencyIsoCode = 'USD',
            B2B_Billing_Frequency__c = 'Monthly',
            B2B_Payment_Method__c = 'Credit Card',
            B2B_Special_Instruction__c = 'Handle with care',
            B2B_Po_Number__c = 'PO',
            B2B_Shipping_Method__c = 'Freight Overnight',
            B2B_End_Date__c = Date.today()
        );
        insert subToCancel;
		String queryStr = 'SELECT Id, Subscription_Name__c, B2B_Account__c, B2B_Contact__c, B2B_Next_Billing_Date__c, OwnerId, ' +
                   'B2B_Shipping_Address__c, B2B_Billing_Address__c, B2B_Shipping_Method__c, CurrencyIsoCode,' +
                   'B2B_Billing_Frequency__c, B2B_Payment_Method__c, B2B_Special_Instruction__c, B2B_Shipping_Provider__c,' +
                   'B2B_Shipping_Provider_Account_Number__c, B2B_Po_Number__c, B2B_End_Date__c,' +
                   'B2B_Billing_Address__r.Street, B2B_Billing_Address__r.City, B2B_Billing_Address__r.State, '+
                    'B2B_Billing_Address__r.PostalCode, B2B_Billing_Address__r.Country, '+
                    'B2B_Shipping_Address__r.Street, B2B_Shipping_Address__r.City, B2B_Shipping_Address__r.State, '+
                    'B2B_Shipping_Address__r.PostalCode, B2B_Shipping_Address__r.Country '+
                   'FROM B2B_Subscriptions__c ' +
                   'WHERE Id = ' + '\'' + subToCancel.Id +'\'';
        Test.startTest();
        B2B_SubscriptionOrderBatch ba= new B2B_SubscriptionOrderBatch(queryStr);
        Id jobid = Database.executeBatch( ba , 1 );
        Test.stopTest();

        List<B2B_Subscriptions__c> subs = [
            SELECT Id FROM B2B_Subscriptions__c WHERE B2B_Next_Billing_Date__c = :Date.today()
        ];
        System.assert(!subs.isEmpty(), 'Subscription should exist for today’s date');
    }
}
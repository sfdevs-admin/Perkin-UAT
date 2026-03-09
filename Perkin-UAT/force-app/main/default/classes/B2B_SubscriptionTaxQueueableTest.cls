/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 08-13-2025
 * @last modified by  : Gaurav Setia
**/
@IsTest
private class B2B_SubscriptionTaxQueueableTest {

    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String LOCATION_NAME = 'Test';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    static void setup() {
        Product2 product = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);	
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        OrderDeliveryMethod ordDelMed = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        Order ord = B2B_TestDataFactory.createOrder('Test Order', acc.Id, Test.getStandardPricebookId(), true);
        OrderDeliveryGroup ordDelGrp = B2B_TestDataFactory.createOrderDeliveryGroup('Test ODG', ordDelMed.Id, ord.Id, true);
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id LIMIT 1];
        OrderItem orderItem = B2B_TestDataFactory.createOrderItem(ord.Id, pbEntry.Id, ordDelGrp.Id, true);

        ContactPointAddress shippingAddress = B2B_TestDataFactory.createShippingCPA(acc,true);
        shippingAddress.Country = 'US';
        update shippingAddress;

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
            B2B_Stripe_Payment_Intent__c = 'pi_13451Sre2OxY3Au2'
        );
        insert sub;

        // Create Subscription Item
        B2B_Subscription_Items__c subItem = new B2B_Subscription_Items__c(
            B2B_Subscriptions__c = sub.Id,
            B2B_Product__c = product.Id,
            B2B_Quantity__c = 10,
            B2B_Unit_Price__c = 5000
        );
        insert subItem;

        ord.ShippingCountry = 'SE';
        ord.B2B_Subscriptions__c = sub.Id;
        update ord;
    }
   
    @IsTest
    static void executeTest() {
        //Given
        List<Order> orders = [SELECT Id, B2B_Subscriptions__c, ShippingCountry, CurrencyIsoCode, 
            (SELECT Id, UnitPrice, Quantity, TotalPrice, Product2Id FROM OrderItems )
            FROM Order LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new B2BStripeTaxMock(orders[0]));
        //When
        Test.startTest();
        ID jobID = System.enqueueJob(new B2B_SubscriptionTaxQueueable(orders[0].Id, orders[0].B2B_Subscriptions__c));
        B2B_SubscriptionTaxQueueable.applyFlatTax(orders[0], orders[0].OrderItems);
        B2B_SubscriptionTaxQueueable.applyFlatTaxToOrderItems(orders[0].OrderItems, 10.00);
        Test.stopTest();

        //Then
        System.assert(jobID != null, 'jobID should not be null');
    }

}
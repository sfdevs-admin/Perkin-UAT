@isTest
public with sharing class B2BGTMOrderConfContTest {

    private static final String PRODUCT_NAME = 'Test Product';
    private static final String CUSTOMER_EMAIL = 'customer@testing.cust';
    private static final String GUEST_CUSTOMER_EMAIL = 'guest_customer@testing.cust';
    private static final String LOCATION_NAME = 'Test';
    
    @TestSetup
    static void makeData(){
        Account userAccount = B2B_TestDataFactory.createAccount('TestAccount', true);
        Contact userContact = B2B_TestDataFactory.createContact('TestContact', userAccount.Id, true);
        User customerUser = B2B_TestDataFactory.createUser('Customer', CUSTOMER_EMAIL, userContact.Id, true); 

        B2B_TestDataFactory.createOrderDeliveryMethod(true);
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Store',true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(userAccount,true);
        WebCart currentCart  = B2B_TestDataFactory.createCart(userAccount.Id, customerUser.id , store.Id, cpa.Id ,true);
	
        B2B_Attachment__c attach = new B2B_Attachment__c(
        	Cart__c = currentCart.Id
        );
        insert attach;
        
        CommerceEntitlementPolicy policy = new CommerceEntitlementPolicy(
            Name = 'test policy',
			Description = 'test policy', 
            CanViewProduct = true, 
            CanViewPrice = true,
            IsActive = true,
            B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY'
        );
        insert policy;
        
        CommerceEntitlementProduct prodEntitlement = new CommerceEntitlementProduct(
        	PolicyId = policy.Id,
            ProductId = prod.Id
        );
        insert prodEntitlement;

        Order order = new Order(
            AccountId = userAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert order; 

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            ListPrice = 100.00,
            UnitPrice = 100.00
        );
        insert orderItem;
    }

    @isTest
    public static void B2B_CreateProductEntitlementBatch_test(){
        List<Order> order = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        Order retOrd = B2BGTMOrderConfCont.getOrderWithItems(order[0].Id);
        Test.stopTest();
        Assert.isNotNull(retOrd);
    }
    
}
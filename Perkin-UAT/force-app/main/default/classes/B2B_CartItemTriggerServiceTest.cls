@IsTest
public without sharing class B2B_CartItemTriggerServiceTest {
     @testSetup static void setup() {
        // WebStore testWebStore = new WebStore(Name='TestWebStore');
        // insert testWebStore;

        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);
        // Product2 prod = B2B_TestDataFactory.createProduct('Test Product',true);
        Product2 prod = new Product2();
            prod.Name = 'Prod1';
            prod.ProductCode = 'Prod1';
            prod.StockKeepingUnit = 'Prod1';
            prod.isActive = true ;
            prod.product_line__c = 'AA' ;
            prod.Item_Class__c = '3' ;
        insert prod;

        List<Product2> prodList = new List<Product2>();
        prodList.add(prod);	

        Account account = B2B_TestDataFactory.createAccount('Test Account', true);
        Contact contact = B2B_TestDataFactory.createContact('Test Contact', account.Id, true);
        User user = B2B_TestDataFactory.createUser('test', 'test@gmail.com', contact.Id, true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(account,true);
        WebCart cart = B2B_TestDataFactory.createCart(account.Id, user.Id, webStore.Id, cpa.Id, true);

        Schema.Location location = B2B_TestDataFactory.createLocation('Test', true);
        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        // List<cartItem> cartitems1 = B2B_TestDataFactory.createCartitems(cart.Id,deliveryGroup.Id,prodList,location.Id,true);

        B2B_Deal_Discount__c dealDiscount = new B2B_Deal_Discount__c();
        dealDiscount.Name = 'Deal Discount Test';
        insert dealDiscount;

        B2B_Deals__c deals = new B2B_Deals__c();
        deals.B2B_Account__c = account.Id;
        deals.B2B_Currency__c = 'USD' ;
        deals.B2B_Deal_Number__c = 'Deal001' ;
        deals.B2B_Deal_Discount__c = dealDiscount.Id;
        insert deals;

        B2B_Deal_Discount_Line__c dealItem = new B2B_Deal_Discount_Line__c();
        // dealItem.B2B_Deal_Discount__c = deals.Id;
        dealItem.B2B_Deal_Discount__c = dealDiscount.Id;
        dealItem.B2B_Discount__c = 5.00; 
        dealItem.B2B_Item_Class__c = '3'; 
        dealItem.B2B_Product_Line__c = 'AA'; 
        dealItem.B2B_Start_Date__c = Date.today(); 
        dealItem.B2B_End_Date__c =Date.today() + 10; 
        insert dealItem;

        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems(cart.Id,deliveryGroup.Id,prodList,location.Id,true);


        
    }

    @isTest
    static void testCartItemTrigger() {
        // Fetch the inserted cart item
        CartItem ci = [SELECT Id, B2B_Deal_Discount__c, B2B_Original_Price__c 
                       FROM CartItem LIMIT 1];

        System.assertEquals(5, ci.B2B_Deal_Discount__c, 'Discount should be applied');
    }
}
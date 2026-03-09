@isTest
public with sharing class B2BCartCalcShippingTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String PRODUCT_NAME_HAZ = 'Test Haz Product';
    private static final String LOCATION_NAME = 'Test';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';
    @TestSetup
    static void setup() {
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        Product2 hazProd = B2B_TestDataFactory.createProduct(PRODUCT_NAME_HAZ,true);
        hazProd.B2B_Is_Hazardous__c = true;
        update hazProd;
        List<Product2> prodList = new List<Product2>();
        prodList.add(prod);	
        prodList.add(hazProd);		
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Account acc1 = B2B_TestDataFactory.createAccount('Test Acc',true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        Contact con1 = B2B_TestDataFactory.createContact('Test con',acc1.Id,true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(acc,true);
        ContactPointAddress cpa1 = B2B_TestDataFactory.createShippingCPA(acc1,true);
        Schema.Location location = B2B_TestDataFactory.createLocation(LOCATION_NAME, true);
        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        //OrderDeliveryMethod odm1 = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        User custUser1 = B2B_TestDataFactory.createUser('test','t@u.com',con1.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);
        WebStore store1 = B2B_TestDataFactory.createWebstore('Test Store 1',true);
        WebCart cart = B2B_TestDataFactory.createCart(acc.Id,custUser.Id,store.Id,cpa.Id,true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems1(cart.Id,deliveryGroup.Id,prodList,location.Id,true);
        
        //WebCart cart1 = B2B_TestDataFactory.createCart(acc1.Id,custUser1.Id,store1.Id,cpa1.Id,true);
        WebCart cart1 = new WebCart(
                                Name = 'Cart1',
                                AccountId = acc1.Id,
                                OwnerId = custUser1.Id,
                                Status = 'Active',
                                Type = 'Cart',
                                WebStoreId = store1.Id
        );
        insert cart1;
        
        System.debug('cart1'+cart1);
        CartDeliveryGroup deliveryGroup1 = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart1.Id,odm.Id,'US',true);
        Product2 prod1 = new Product2();
        prod1.Name = 'prod1' ;
        prod1.ProductCode = 'prod1' ;
        prod1.StockKeepingUnit = 'prod1' ;
        prod1.isActive = true ;
        insert prod1;
        PricebookEntry pbe1 = new PricebookEntry(
            	Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = prod1.Id,
                UnitPrice = 99999999,
                IsActive = true,
                CurrencyIsoCode = 'USD'
        );
        insert pbe1;
        System.debug('pbe1'+pbe1);
        List<Product2> prodList1 = new List<Product2>();
        prodList1.add(prod1);
        List<cartItem> cartitems1 = B2B_TestDataFactory.createCartitems(cart1.Id,deliveryGroup1.Id,prodList1,location.Id,true);
        System.debug('cartitems1'+cartitems1);
        
        Product2 shipProduct = new Product2();
        shipProduct.Name = 'Delivery Charge' ;
        shipProduct.ProductCode = 'Delivery Charge' ;
        shipProduct.StockKeepingUnit = 'Delivery Charge' ;
        shipProduct.isActive = true ;
        insert shipProduct;
    }
    
    @isTest
    public static void testCartWithNoCartDeliveryGroup(){
        CartDeliveryGroup deliveryGroup = [SELECT Id FROM CartDeliveryGroup WHERE Name = 'Default' LIMIT 1];
        delete deliveryGroup;
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        system.debug('cart '+cart);
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        system.debug('cartObject '+cartObject);
        system.debug('cartObject type '+cartObject.getName());
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        B2BCartCalcShipping calculator = new B2BCartCalcShipping();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
    
    @isTest
    public static void testCartWithNoShippingProduct(){
        Product2 shippingProduct = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' LIMIT 1];
        delete shippingProduct;
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        system.debug('cart '+cart);
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        system.debug('cartObject '+cartObject);
        system.debug('cartObject type '+cartObject.getName());
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        B2BCartCalcShipping calculator = new B2BCartCalcShipping();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
    
    @IsTest
    public static void testShippingMethodsAreCreated() {
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        //system.debug('cart '+cart);
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        system.debug('cartObject '+cartObject);
        system.debug('cartObject type '+cartObject.getName());
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        B2BCartCalcShipping calculator = new B2BCartCalcShipping();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
    
    @IsTest
    public static void testShippingMethodsAreCreatedWithMorePrice() {
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart1' LIMIT 1];
        system.debug('cart1 '+cart);
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        system.debug('cartObject '+cartObject);
        system.debug('cartObject type '+cartObject.getName());
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        B2BCartCalcShipping calculator = new B2BCartCalcShipping();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
    
    @IsTest
    public static void testNoMetadataRecordReturned() {
        CartDeliveryGroup deliveryGroup = [SELECT Id, Name, DeliverToCountry FROM CartDeliveryGroup WHERE Name = 'Default' LIMIT 1];
        deliveryGroup.DeliverToCountry = 'United States';
        update deliveryGroup;
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        system.debug('cart '+cart);
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        system.debug('cartObject '+cartObject);
        system.debug('cartObject type '+cartObject.getName());
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        B2BCartCalcShipping calculator = new B2BCartCalcShipping();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
}
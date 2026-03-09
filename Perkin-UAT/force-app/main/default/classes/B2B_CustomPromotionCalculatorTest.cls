@isTest
public with sharing class B2B_CustomPromotionCalculatorTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String LOCATION_NAME = 'Test';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';

    static B2B_CustomPromotionCalculator calculator = new B2B_CustomPromotionCalculator();

    @TestSetup
    static void setup() {
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        List<Product2> prodList = new List<Product2>();
        prodList.add(prod);			
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(acc,true);
        Schema.Location location = B2B_TestDataFactory.createLocation(LOCATION_NAME, true);
        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);
        WebCart cart = B2B_TestDataFactory.createCart(acc.Id,custUser.Id,store.Id,cpa.Id,true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems(cart.Id,deliveryGroup.Id,prodList,location.Id,true);
        
        
        B2B_Deal_Discount__c dealdiscount = new B2B_Deal_Discount__c(
        	Name = 'Test dealdiscount',
            CurrencyIsoCode = 'USD'
        );
        insert dealdiscount;
        
        B2B_Deals__c deals = new B2B_Deals__c();
        deals.B2B_Account__c = acc.Id;
        deals.B2B_Currency__c = 'USD' ;
        deals.B2B_Deal_Number__c = 'Deal001' ;
        deals.B2B_Deal_Discount__c = dealdiscount.Id;
        insert deals;
        
        B2B_Deal_Discount_Line__c dealItem = new B2B_Deal_Discount_Line__c();
        dealItem.B2B_Deal_Discount__c = dealdiscount.Id;
        dealItem.B2B_Discount__c = 5.00; 
        dealItem.B2B_Item_Class__c = '3'; 
        dealItem.B2B_Product_Line__c = 'AA'; 
        dealItem.B2B_Start_Date__c = Date.today(); 
        dealItem.B2B_End_Date__c =Date.today() + 10; 
        insert dealItem;
    }

    @isTest
    public static void testValidAccount(){
        CartDeliveryGroup deliveryGroup = [SELECT Id FROM CartDeliveryGroup WHERE Name = 'Default' LIMIT 1];
        delete deliveryGroup;
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
        
    }
    @isTest
    public static void testValidAccountNegavtive(){
        B2B_Deals__c deal = [SELECT Id FROM B2B_Deals__c WHERE B2B_Deal_Number__c =: 'Deal001' LIMIT 1];
		delete deal;
        CartDeliveryGroup deliveryGroup = [SELECT Id FROM CartDeliveryGroup WHERE Name = 'Default' LIMIT 1];
        delete deliveryGroup;
        Schema.WebCart cart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject,CartExtension.OptionalBuyerActionDetails.empty());
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
        
    }

    @isTest
    public static void testCartValidationOutput() {
        WebCart cartRecord = [SELECT Id, AccountId FROM WebCart WHERE Name='Cart' LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cartRecord.Id);

        //Add fake ValidationOutput to trigger cleanUpCVO for-loop
        CartExtension.CartValidationOutput mockCVO = new CartExtension.CartValidationOutput(
            CartExtension.CartValidationOutputTypeEnum.PROMOTIONS,
            CartExtension.CartValidationOutputLevelEnum.INFO
        );
        cartObject.getCartValidationOutputs().add(mockCVO);

        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
            cartObject, CartExtension.OptionalBuyerActionDetails.empty()
        );

        Test.startTest();
        calculator.calculate(request); 
        Test.stopTest();
    }

    @isTest
    public static void testForGuest() {
        WebCart cartRecord = [SELECT Id, AccountId FROM WebCart WHERE Name='Cart' LIMIT 1];
        cartRecord.AccountId = UserInfo.getUserId();
        update cartRecord;
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cartRecord.Id);

        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
            cartObject, CartExtension.OptionalBuyerActionDetails.empty()
        );

        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
    
    @isTest
    public static void testAddCartValidationOutputTrigger() {
        WebCart cartRecord = [SELECT Id, AccountId FROM WebCart WHERE Name='Cart' LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cartRecord.Id);
    
        // Inject mock adjustment basis
        CartExtension.CartAdjustmentBasis mockBasis = new CartExtension.CartAdjustmentBasis();
        mockBasis.setAdjustmentBasisDetail('Mock Detail');
        cartObject.getCartAdjustmentBases().add(mockBasis);
    
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
            cartObject, CartExtension.OptionalBuyerActionDetails.empty()
        );
    
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
    }
}
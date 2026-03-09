@IsTest
public without sharing class B2BCustomPricingServiceTest {
    @testSetup static void setup() {
        // WebStore testWebStore = new WebStore(Name='TestWebStore');
        // insert testWebStore;

        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);
        Product2 prod = B2B_TestDataFactory.createProduct('Test Product',true);
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
        List<cartItem> cartitems1 = B2B_TestDataFactory.createCartitems(cart.Id,deliveryGroup.Id,prodList,location.Id,true);

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


        Product2 shipProduct = new Product2();
        shipProduct.Name = 'Prod1';
        shipProduct.ProductCode = 'Prod1';
        shipProduct.StockKeepingUnit = 'Prod1';
        shipProduct.isActive = true ;
        shipProduct.product_line__c = 'AA' ;
        shipProduct.Item_Class__c = '3' ;
        insert shipProduct;
    }


    @isTest 
    static void testProcessPriceIntegration() {
        Test.startTest();
        Account account = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Prod1' LIMIT 1];
        
        commercestorepricing.PricingRequestItem requestItem = new commercestorepricing.PricingRequestItem(prod.Id);
        commercestorepricing.PricingRequest request = new commercestorepricing.PricingRequest();
        request.setWebStoreId(webStore.Id);
        request.setEffectiveAccountId(account.Id);
        request.addPricingRequestItem(requestItem);

        User user = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];

        System.runAS(user) {
            B2BCustomPricingService apexSample = new B2BCustomPricingService();
            commercestorepricing.PricingResponse response = apexSample.processPrice(request);
        }
        Test.stopTest();
    }

    @isTest 
    static void testGuestProcessPriceIntegration() {
        Test.startTest();
        Id accountId = UserInfo.getUserId();
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Prod1' LIMIT 1];
        
        commercestorepricing.PricingRequestItem requestItem = new commercestorepricing.PricingRequestItem(prod.Id);
        commercestorepricing.PricingRequest request = new commercestorepricing.PricingRequest();
        request.setWebStoreId(webStore.Id);
        request.setEffectiveAccountId(accountId);
        request.addPricingRequestItem(requestItem);

        B2BCustomPricingService apexSample = new B2BCustomPricingService();
        commercestorepricing.PricingResponse response = apexSample.processPrice(request);

        Test.stopTest();
    }


    @isTest
    static void test_processTransactionalPrice_withCustomAccount() {
        Account acc = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Prod1' LIMIT 1];
        String cartItemId = [SELECT Id FROM CartItem WHERE Cart.AccountId =: acc.Id LIMIT 1].Id;

        // Prepare request item using correct constructor
        commercestorepricing.TransactionalPricingRequestItem reqItem = 
            // new commercestorepricing.TransactionalPricingRequestItem('Line-001', prod.Id, 2);
            new commercestorepricing.TransactionalPricingRequestItem(cartItemId, prod.Id, 2);

        // Prepare full request
        commercestorepricing.TransactionalPricingRequest request = new commercestorepricing.TransactionalPricingRequest();
        request.setEffectiveAccountId(acc.Id);
        request.setCurrencyIsoCode('USD');
        request.addTxnPricingRequestItem(reqItem);

        Test.startTest();
        commercestorepricing.TransactionalPricingResponse response = new B2BCustomPricingService().processTransactionalPrice(request);
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals('USD', response.getCurrencyIsoCode());
        System.assertEquals(1, response.getTxnPricingResponseItems().size());
    }



}
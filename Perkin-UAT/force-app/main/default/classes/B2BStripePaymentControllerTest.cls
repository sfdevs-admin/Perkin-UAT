@IsTest
public class B2BStripePaymentControllerTest {

    @TestSetup static void makeData(){
        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);

        Account account = B2B_TestDataFactory.createAccount('Test Account', true);
        Contact contact = B2B_TestDataFactory.createContact('Test Contact', account.Id, true);
        User user = B2B_TestDataFactory.createUser('test', 'test@gmail.com', contact.Id, true);

        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(account, true);

        WebCart cart = B2B_TestDataFactory.createCart(account.Id, user.Id, webStore.Id, cpa.Id, true);

        Product2 product = B2B_TestDataFactory.createProduct('Test Product',true);

        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        CartDeliveryGroup cdg = B2B_TestDataFactory.createCartDeliveryGroup(cart.Id, odm.Id, true);

        CartItem ci = new CartItem(
            CartId = cart.Id,
            Product2Id = product.Id,
            Quantity = 1,
            CartDeliveryGroupId = cdg.Id,
            Name = product.Name,
            SalesPrice =  5 ,
            UnitAdjustedPrice = 5,
            ListPrice =  5 ,
            NetUnitPrice = 5,
            GrossUnitPrice = 5,
            TotalLineAmount = 5 ,
            TotalPrice = 5 ,
            TotalListPrice = 5,
            Type = 'Product'
        );
        insert ci;

        Contact con = [SELECT Id, Email FROM Contact WHERE Id= :contact.Id LIMIT 1];
        con.Email = 'customer@test.com';
        update con;
    }
    
    @isTest static void testGetCustomerId() {

        Test.StartTest();
        User user = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomerGet', 200, true));

        System.runAS(user) {
            B2BStripePaymentController.getCustomerId();
        }
        Test.StopTest();
    }

    @isTest static void testGetCustomerId_createCustomer() {

        Contact con = [SELECT Id, Email FROM Contact WHERE Email = 'customer@test.com' LIMIT 1];

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomer', 200, true));
        try{
            B2BStripeService.createStripeCustomer(con.Id, 'customer@test.com');
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testProcessPayments() {

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        String customerId = 'cus01234567890';
        String href = 'https://pki--ecomdev.my.site.com/PayNow/';

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('checkoutSession', 200, true));
        B2BStripePaymentController.processPayments(webCartId, customerId, href);
        Test.StopTest();
    }
    
    @isTest static void testValidateSession() {

        String sessionId = 'ses01234567890';
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('checkoutSession', 200, true));
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, true));
        B2BStripePaymentController.validateSession(sessionId, webCartId);
        Test.StopTest();
    }

    @isTest static void testConvertCartToOrder() {

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        String paymentIntent = 'pi_13451Sre2OxY3Au2';

        CartCheckoutSession session = new CartCheckoutSession(
            WebCartId = webCartId,
            State = 'Start',
            IsArchived = false,
            Name = 'Test'
        );
        insert session;

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, true));

        try {
            B2BStripePaymentController.convertCartToOrder(webCartId, paymentIntent, null);
        }
        catch(Exception e){
            System.debug('Exception in convertCartToOrder: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testConvertCartToOrder_Exception() {

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1].Id;
        String paymentIntent = 'pi_13451Sre2OxY3Au2';

        CartCheckoutSession session = new CartCheckoutSession(
            WebCartId = webCartId,
            State = 'Start',
            IsArchived = false,
            Name = 'Test'
        );
        insert session;

        Test.StartTest();
        OrderDeliveryMethod odm = [SELECT Id FROM OrderDeliveryMethod WHERE Name = 'default Shipping' LIMIT 1];
        delete odm;

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, false));

        try {
            B2BStripePaymentController.convertCartToOrder(webCartId, paymentIntent, null);
        }
        catch(Exception e){
            System.debug('Exception in convertCartToOrder: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testCreatePaymentIntentByMethod() {

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('customerId', 'cus01234567890');
        mapParams.put('paymentIntent', 'pi_13451Sre2OxY3Au2');
        mapParams.put('amount', 100);
        mapParams.put('currencyCode', 'USD');
        mapParams.put('orderId', 'orderId');
        mapParams.put('subscriptionId', 'subscriptionId');
        
        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, true));

        try {
            B2BStripeService.createPaymentIntentByMethod(mapParams);
        }
        catch(Exception e){
            System.debug('Exception in createPaymentIntent: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testCreateCoupon() {

        Integer discountedAmount = 10;
        String currencyCode = 'usd';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('coupon', 200, true));

        try {
            B2BStripeService.createCoupon(discountedAmount, currencyCode);
        }
        catch(Exception e){
            System.debug('Exception in createCoupon: ' + e.getMessage());
        }
        Test.StopTest();
    }
}
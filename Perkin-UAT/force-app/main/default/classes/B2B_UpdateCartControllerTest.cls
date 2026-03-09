@isTest
public with sharing class B2B_UpdateCartControllerTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    // private static final String PRODUCT_NAME = 'Test Product';
    // private static final String LOCATION_NAME = 'Test';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    static void createTestData(){
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(acc,true);
        // Schema.Location location = B2B_TestDataFactory.createLocation(LOCATION_NAME, true);
        // OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);
        WebCart cart = B2B_TestDataFactory.createCart(acc.Id,custUser.Id,store.Id,cpa.Id,true);
    }

    @isTest
    static void updateCartWithShippingProviderDetailsTest(){
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('cartId', cart.Id);
        mapParams.put('shippingProvider', 'UPS');
        mapParams.put('shippingAccountNumber', '123456789');

        Test.startTest();
        Map<String,Object> result = B2B_UpdateCartController.updateCartWithShippingProviderDetails(mapParams);
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }

    @isTest
    static void updateCartWithShippingProviderDetailsNegativeTest(){
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('cartId', 'cart.Id');
        mapParams.put('shippingProvider', 'UPS');
        mapParams.put('shippingAccountNumber', '123456789');

        Test.startTest();
        Map<String,Object> result = B2B_UpdateCartController.updateCartWithShippingProviderDetails(mapParams);
        Test.stopTest();
        System.assertEquals(false, result.get('isSuccess'));
    }
}
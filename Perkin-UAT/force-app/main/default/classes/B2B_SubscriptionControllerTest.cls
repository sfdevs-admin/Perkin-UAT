@isTest
public class B2B_SubscriptionControllerTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String Community_Nickname = 'testuserPerkinStack';
    private static final String EMAIL = 'test@user.com';
    @TestSetup
    public static void setupData() {
        Account account = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        // Create a Contact
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,account.Id,false);
        con.Email = EMAIL;
        insert con;
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        
        // Create Subscription
        B2B_Subscriptions__c sub = new B2B_Subscriptions__c(
            Subscription_Name__c = 'Test Subscription',
            Description__c = 'Test Description',
            B2B_Status__c = 'Inactive',
            B2B_Account__c = account.Id,
            B2B_Billing_Frequency__c = 'Monthly',
            CurrencyIsoCode = 'USD',
            B2B_Contact__c = con.Id
        );
        insert sub;
        
        // Create Subscription Item
        B2B_Subscription_Items__c item = new B2B_Subscription_Items__c(
            CurrencyIsoCode = 'USD',
            B2B_Subscriptions__c = sub.Id,
            B2B_Quantity__c = 1,
            B2B_Product__c = prod.Id,
            B2B_Unit_Price__c = 100
        );
        insert item;
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);	
        B2BUtils.testWebStoreId = store.Id;
        
        WebCart cart = B2B_TestDataFactory.createCart(account.Id,custUser.Id,store.Id,null,true);
        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems1(cart.Id,deliveryGroup.Id,new List<Product2>{prod}
                                                                        ,null,true);
        
    }
    
    @IsTest
    static void testGetSubscriptionList() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Map<String, Object> params = new Map<String, Object>
        {'accountId' => acc.Id,
            'productId' => prod.Id,
            'billingFrequency' => 'Monthly'
            };
                
                Test.startTest();
        User usr = [Select Id,UserRoleId from User where CommunityNickname =: Community_Nickname];
        System.RunAs(usr) {
            Map<String, Object> result = B2B_SubscriptionController.getSubscriptions(params);
            
            System.assertEquals(true, result.get('isSuccess'), 'Should be successful');
            System.assert(result.containsKey('subscriptions'), 'Subscriptions should be returned');
            Map<Id, B2B_Subscriptions__c> subs = (Map<Id, B2B_Subscriptions__c>) result.get('subscriptions');
            System.assert(!subs.isEmpty(), 'Should return at least one subscription');
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateRecordException() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Map<String, Object> insertRecord = new Map<String, Object>{
            'Subscription_Name__c' => 'New Subscription',
                'B2B_Status__c' => 'Active',
                'B2B_Account__c' => acc.Id,
                'B2B_Billing_Frequency__c' => 'Monthly'
                };
                    
                    Map<String, Object> params = new Map<String, Object>{
                        'sobjectType' => 'B2B_Subscriptions__c',
                            'insertRecord' => insertRecord,
                            'accountId' => acc.Id
                            };
                                
                                Test.startTest();
        User usr = [Select Id,UserRoleId from User where CommunityNickname =: Community_Nickname];
        System.RunAs(usr) {
            Map<String, Object> result = B2B_SubscriptionController.createRecord(params);
            System.assertEquals(false, result.get('isSuccess'), 'Should be unsuccessful');
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateRecord() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Map<Object, Object> insertRecord = new Map<Object, Object>{
            'Subscription_Name__c' => 'New Subscription',
                'B2B_Status__c' => 'Active',
                'B2B_Account__c' => acc.Id,
                'B2B_Billing_Frequency__c' => 'Monthly'
                };
                    
                    Map<String, Object> params = new Map<String, Object>{
                        'sobjectType' => 'B2B_Subscriptions__c',
                            'insertRecord' => insertRecord,
                            'accountId' => acc.Id
                            };
                                
                                Test.startTest();
        User usr = [Select Id,UserRoleId from User where CommunityNickname =: Community_Nickname];
        System.RunAs(usr) {
            Map<String, Object> result = B2B_SubscriptionController.createRecord(params);
            System.assertEquals(true, result.get('isSuccess'), 'Should be successful');
            System.assert(result.get('message') == '', 'Message should be blank if no errors');
        }
        Test.stopTest();
        
    }
    
    
    @IsTest
    static void test_createCartAndItems_success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        B2B_Subscriptions__c sub = [SELECT Id FROM B2B_Subscriptions__c LIMIT 1];
        WebCart webcart = [SELECT Id FROM WebCart LIMIT 1];
        List<User> usrList = [Select Id,UserRoleId from User where CommunityNickname =: Community_Nickname];
        User usr = usrList[0];
        Map<String, Object> params = new Map<String, Object>{
            'effectiveAccountId' => acc.Id,
                'communityId'        => 'testCommunity',
                'recordId'           => sub.Id,
                'webCartId' => webcart.Id
                };
                    
                    System.RunAs(usr) {
                        Test.startTest();
                        Map<String, Object> result = B2B_SubscriptionController.createCartAndItems(params);
                        Test.stopTest();
                        
                        System.assertEquals(true, result.get('isSuccess'), 'Expected success in createCartAndItems');
                    }
    }
    
    @IsTest
    static void test_createCartAndItems_failure() {
        Map<String, Object> params = new Map<String, Object>(); // missing required keys
        params.put('testexception',true);
        Test.startTest();
        Map<String, Object> result = B2B_SubscriptionController.createCartAndItems(params);
        Test.stopTest();
        
        System.assertEquals(false, result.get('isSuccess'), 'Expected failure due to missing params');
        System.assert(result.containsKey('msg'), 'Should have an error message');
    }
    
    @IsTest
    static void test_checkForSubscriptionCart_success() {
        WebCart wc = [SELECT Id FROM WebCart LIMIT 1];
        Map<String, Object> params = new Map<String, Object>{
            'cartId' => wc.Id
                };
                    
                    Test.startTest();
        Map<String, Object> result = B2B_SubscriptionController.checkForSubscriptionCart(params);
        Test.stopTest();
        
        System.assertEquals(true, result.get('isSuccess'), 'Expected success in checkForSubscriptionCart');
        System.assertNotEquals(null, result.get('hasSubscription'), 'Expected hasSubscription to be set');
    }
    
    @IsTest
    static void test_checkForSubscriptionCart_failure() {
        Map<String, Object> params = new Map<String, Object>(); // no cartId
        params.put('testexception',true);
        Test.startTest();
        Map<String, Object> result = B2B_SubscriptionController.checkForSubscriptionCart(params);
        Test.stopTest();
        
        System.assertEquals(false, result.get('isSuccess'), 'Expected failure due to missing cartId');
    }
    
    
    
}
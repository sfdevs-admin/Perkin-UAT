@isTest
public class B2B_CartNotificationTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String Community_Nickname = 'testuserPerkinStack';
    private static final String EMAIL = 'test@user.com';
    @testSetup
    // Utility to create a portal-enabled user
    private static void createTestData() {
        Account account = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        // Create a Contact
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,account.Id,false);
        con.Email = EMAIL;
        insert con;
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
         WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);	
        B2BUtils.testWebStoreId = store.Id;
        
        WebCart cart = B2B_TestDataFactory.createCart(account.Id,custUser.Id,store.Id,null,true);
        OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        CartDeliveryGroup deliveryGroup = B2B_TestDataFactory.createCartDeliveryGroupWithCountryCode(cart.Id,odm.Id,'US',true);
        List<cartItem> cartitems = B2B_TestDataFactory.createCartitems1(cart.Id,deliveryGroup.Id,new List<Product2>{prod}
                                                                        ,null,true);
    }
    
    @isTest
    static void testBatchExecute() {
        Test.startTest();
        B2B_CartNotification batch = new B2B_CartNotification();
        Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Assert exception log not inserted
        System.assertEquals(0, [SELECT COUNT() FROM Custom_Exception__c]);
    }
    
    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        String jobId = System.schedule(
            'CartNotifJob', 
            '0 0 23 * * ?', 
            new B2B_CartNotification()
        );
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job should be scheduled');
    }
    
    @isTest
    static void testWithCartIdConstructor() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Set<Id> cartIdSet = new Set<Id>{cart.Id};
            
            Test.startTest();
        String q = 'SELECT Id,Owner.FirstName,Owner.LastName,TotalProductAmount, '+
                ' Owner.Email,GrandTotalAmount,Currencyisocode,TotalTaxAmount,TotalChargeAmount,'+
                ' (SELECT Id,Product2.Name,Product2.B2B_Part_Number__c,Quantity,'+
                'SalesPrice,TotalPrice,Currencyisocode FROM CartItems WHERE TYPE != \'Charge\') FROM WebCart WHERE Id IN :cartIdSet';
        B2B_CartNotification batch = new B2B_CartNotification(q, cartIdSet, 1);
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Custom_Exception__c]);
    }
}
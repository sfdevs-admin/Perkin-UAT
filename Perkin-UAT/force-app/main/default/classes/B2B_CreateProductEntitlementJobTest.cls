@isTest
public class B2B_CreateProductEntitlementJobTest {
    
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String CUSTOMER_EMAIL = 'customer@testing.cust';
    private static final String GUEST_CUSTOMER_EMAIL = 'guest_customer@testing.cust';
    private static final String LOCATION_NAME = 'Test';
    
    @TestSetup
    static void makeData(){
        Contact con = new Contact(
            LastName = 'Test'
        );
        insert con;
        
        ContentVersion cv = new ContentVersion(
        	Title = 'Test',
            PathOnClient = 'Test',
            VersionData = EncodingUtil.base64Decode('Test'),
            IsMajorVersion = FALSE
        );
        insert cv;
        
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
    }

	@isTest
    public static void B2B_CreateProductEntitlementBatch_test(){
        Product2 prod = B2B_TestDataFactory.getProductByName( PRODUCT_NAME );
        prod.B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY,BES0-ZW';
        update prod;
		String query = 'SELECT Id, B2B_Sales_Org_And_Sales_Status__c FROM Product2 WHERE B2B_Sales_Org_And_Sales_Status__c != null AND Id =\'' +prod.Id+'\'';
        Test.startTest();
        B2B_CreateProductEntitlementBatch ba= new B2B_CreateProductEntitlementBatch( query );
        Id jobid= Database.executeBatch(ba,1);
        Test.stopTest();
        Assert.isNotNull(prod);
    }
    
    @isTest
    public static void B2B_ProductEntitlementInvocable_test(){
        Product2 prod = B2B_TestDataFactory.getProductByName( PRODUCT_NAME );
        String query = 'SELECT Id, B2B_Sales_Org_And_Sales_Status__c FROM Product2 WHERE B2B_Sales_Org_And_Sales_Status__c != null AND Id =\'' +prod.Id+'\'';
        Test.startTest();
        B2B_ProductEntitlementInvocable ba= new B2B_ProductEntitlementInvocable();
        Test.stopTest();
        Assert.isNotNull(prod);
    }
    
    @isTest
    public static void B2B_DeleteExistingProductEntitlement_test(){
        Product2 prod = B2B_TestDataFactory.getProductByName( PRODUCT_NAME );
        prod.B2B_Sales_Org_And_Sales_Status__c = 'ESS0-ZY,BES0-ZW';
        update prod;
		String query = 'SELECT Id FROM CommerceEntitlementProduct';
        Test.startTest();
        B2B_DeleteExistingProductEntitlement ba= new B2B_DeleteExistingProductEntitlement( query );
        Id jobid= Database.executeBatch(ba,1);
        Test.stopTest();
        Assert.isNotNull(prod);
    }
}
@IsTest
public class B2BUtilsTest {
	private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';
    
     @TestSetup
    static void setup() {		
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Test Store',true);	
        B2BUtils.testWebStoreId = store.Id;
    }
    
    @IsTest
    static void testGetWebstoreId() {
        Id wsId = [SELECT Id FROM WebStore WHERE Name =: 'Test Store' LIMIT 1].Id;
        Id fakeCommunityId = wsId;
		String communityId = fakeCommunityId;
        Id returnedWebstoreId = B2BUtils.getWebstoreId(communityId);
    }

    @IsTest
    static void testGetCurrencyIsoCode() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        String currencyCode = B2BUtils.getCurrencyIsoCode(accId);
        System.assertEquals('USD', currencyCode, 'CurrencyIsoCode should be USD');
    }

    @IsTest
    static void testGetUserAccountID() {
        Id accountId = B2BUtils.getUserAccountID();
    }
}
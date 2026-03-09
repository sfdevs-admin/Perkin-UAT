@isTest
public with sharing class B2B_WishlistControllerTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String WEBSTORE_NAME = 'Test Store';
    private static final String Community_Nickname = 'testuser_Pki';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    static void createTestData(){
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        List<Product2> prodList = new List<Product2>();
        prodList.add(prod);			
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        User custUser = B2B_TestDataFactory.createActiveUser(Community_Nickname,EMAIL,con.Id,true);
        WebStore store = B2B_TestDataFactory.createWebstore(WEBSTORE_NAME,true);
    }

    @isTest
    static void isProductExistInWishlistTest(){

        User communityUser = [SELECT Id, Name FROM User WHERE CommunityNickname = :Community_Nickname AND isActive = true LIMIT 1];
        Account account = [Select Id FROM Account LIMIT 1];
        WebStore webstore = [SELECT Id FROM WebStore LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];

        System.runAs(communityUser){
            Wishlist wishlist = new Wishlist();
            wishlist.Name = 'TestWishlist';
            wishlist.WebStoreId = webstore.Id;
            wishlist.AccountId = account.Id;
            insert wishlist;

            WishlistItem wishlistItem = new WishlistItem();
            wishlistItem.Name = 'Test wishlistItem'; 
            wishlistItem.WishlistId = wishlist.Id;
            wishlistItem.Product2Id = product.Id;
            insert wishlistItem;
        }

        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId', communityUser.Id);
        mapParams.put('productId', product.Id);

        Test.startTest();
        Map<String,Object> result = B2B_WishlistController.isProductExistInWishlist(mapParams);
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void isProductExistInWishlistNegativeTest(){
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId', 'communityUser.Id');
        mapParams.put('productId', 'product.Id');

        Test.startTest();
        Map<String,Object> result = B2B_WishlistController.isProductExistInWishlist(mapParams);
        Test.stopTest();
        System.assertEquals(false, result.get('isSuccess'));
    }

    @isTest
    static void deleteWishListItemTest(){

        User communityUser = [SELECT Id, Name FROM User WHERE CommunityNickname = :Community_Nickname AND isActive = true LIMIT 1];
        Account account = [Select Id FROM Account LIMIT 1];
        WebStore webstore = [SELECT Id FROM WebStore LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];

        System.runAs(communityUser){
            Wishlist wishlist = new Wishlist();
            wishlist.Name = 'TestWishlist';
            wishlist.WebStoreId = webstore.Id;
            wishlist.AccountId = account.Id;
            insert wishlist;

            WishlistItem wishlistItem = new WishlistItem();
            wishlistItem.Name = 'Test wishlistItem'; 
            wishlistItem.WishlistId = wishlist.Id;
            wishlistItem.Product2Id = product.Id;
            insert wishlistItem;

            Wishlist wishlist1 = [SELECT Id,WebStoreId FROM Wishlist LIMIT 1];
            WishlistItem wishlistItem1 = [SELECT Id FROM WishlistItem LIMIT 1];

            Map<String,Object> mapParams = new Map<String,Object>();
            mapParams.put('webstoreId', wishlist1.WebStoreId);
            mapParams.put('wishlistId', wishlist1.Id);
            mapParams.put('wishlistItemId', wishlistItem1.Id);

            Test.startTest();
            Map<String,Object> result = B2B_WishlistController.deleteWishListItem(mapParams);
            Test.stopTest();
            System.assertEquals(false, result.get('isSuccess'));
        }
    }
}
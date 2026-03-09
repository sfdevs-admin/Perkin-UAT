@IsTest
public class B2B_CategoryNavTableControllerTest {

    @TestSetup 
    static void makeData(){
        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);
        ProductCatalog catalog = B2B_TestDataFactory.createProductCatalog('Test Catalog', true);
        ProductCategory category = B2B_TestDataFactory.createProductCategory('Test Category', catalog.Id, true); 
        ProductCategory category1 = B2B_TestDataFactory.createProductCategory('Test Category2', catalog.Id, true);
    }
    
    @isTest 
    static void testGetFeaturedCategories_Success() {
        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();

        Test.StartTest();
        ProductCategory category = [
            SELECT Id, B2B_Featured_Category__c, B2B_Featured_Category_Sort_Order__c
            FROM ProductCategory 
            WHERE Name = 'Test Category' 
            LIMIT 1
        ];
        
        ProductCategory category1 = [
            SELECT Id, B2B_Featured_Category__c, B2B_Featured_Category_Sort_Order__c
            FROM ProductCategory 
            WHERE Name = 'Test Category2' 
            LIMIT 1
        ];

        List<B2B_Commerce_Category__c> listToInsert = new List<B2B_Commerce_Category__c>();
        B2B_Commerce_Category__c commCat1 = new B2B_Commerce_Category__c(
        	Active__c = true,
            Label__c = 'Label__c',
            Parent_Category__c = category.Id,
            Child_Category__c = category1.Id,
            Technology_Type__c = 'Technology_Type__c'
        );
        listToInsert.add(commCat1);
        B2B_Commerce_Category__c commCat = new B2B_Commerce_Category__c(
        	Active__c = true,
            Label__c = 'Label__c',
            Parent_Category__c = category.Id,
            Child_Category__c = category.Id,
            Technology_Type__c = 'Technology_Type__c'
        );
        listToInsert.add(commCat);
        insert listToInsert;
        
        
        mapParamsInput.put('categoryId',category.Id);
        B2B_CategoryNavTableController obj = new B2B_CategoryNavTableController();
        B2B_CategoryNavTableService o = new B2B_CategoryNavTableService();
        result = B2B_CategoryNavTableController.fetchChildCategories(mapParamsInput);
        Test.StopTest();
        
        System.assertEquals(true, (Boolean)result.get('isSuccess'), 'Expected success when featured categories exist');
    }
    
    @isTest 
    static void testGetFeaturedCategories_Error() {
        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();

        Test.StartTest();
        result = B2B_CategoryNavTableController.fetchChildCategories(null);
        Test.StopTest();
        
        System.assertEquals(false, (Boolean)result.get('isSuccess'), 'Expected success when featured categories exist');
    }
    
    @isTest 
    static void testGetFeaturedCategories_Error1() {
        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();

        Test.StartTest();
        result = B2B_CategoryNavTableController.fetchChildCategories(mapParamsInput);
        Test.StopTest();
        
        System.assertEquals(false, (Boolean)result.get('isSuccess'), 'Expected success when featured categories exist');
    }
    
    @isTest 
    static void testGetFeaturedCategories_Error2() {
        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();
		mapParamsInput.put('categoryId',null);
        Test.StartTest();
        result = B2B_CategoryNavTableController.fetchChildCategories(mapParamsInput);
        Test.StopTest();
        
        System.assertEquals(false, (Boolean)result.get('isSuccess'), 'Expected success when featured categories exist');
    }
}
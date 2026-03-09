@IsTest
public class B2BFeaturedCategoryControllerTest {

    @TestSetup static void makeData(){
        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);
        ProductCatalog catalog = B2B_TestDataFactory.createProductCatalog('Test Catalog', true);
        ProductCategory category = B2B_TestDataFactory.createProductCategory('Test Category', catalog.Id, true);  
    }

    @isTest static void testGetFeaturedCategories_Success() {

        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();

        Test.StartTest();
        ProductCategory category = [
            SELECT Id, B2B_Featured_Category__c, B2B_Featured_Category_Sort_Order__c
            FROM ProductCategory 
            WHERE Name = 'Test Category' 
            LIMIT 1
        ];

        category.B2B_Featured_Category__c = true;
        category.B2B_Featured_Category_Sort_Order__c = 1;
        update category;

        result = B2BFeaturedCategoryController.getFeaturedCategories(mapParamsInput);
        Test.StopTest();
        
        System.assertEquals(true, (Boolean)result.get('isSuccess'), 'Expected success when featured categories exist');
    }

    @isTest static void testGetFeaturedCategories_NoCategories() {

        Map<String,Object> mapParamsInput = new Map<String,Object>();
        Map<String,Object> result = new Map<String,Object>();

        Test.StartTest();
        result = B2BFeaturedCategoryController.getFeaturedCategories(mapParamsInput);
        Test.StopTest();
        
        System.assertEquals(false, (Boolean)result.get('isSuccess'), 'Expected failure when no featured categories exist');
    }

    @isTest static void testGetFeaturedCategories_Exception() {

        Map<String, Object> mapParamsInput = new Map<String, Object>();
        mapParamsInput.put('throwTestException', true); 

        Map<String, Object> result = new Map<String, Object>();

        Test.startTest();
        result = B2BFeaturedCategoryController.getFeaturedCategories(mapParamsInput);
        Test.stopTest();
        
        System.assertEquals(false, (Boolean)result.get('isSuccess'), 'Expected failure when an exception occurs');
    }
}
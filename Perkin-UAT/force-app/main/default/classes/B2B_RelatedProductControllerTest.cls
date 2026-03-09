/**
 * @description       : test class for B2B_RelatedProductController & B2B_RelatedProductService
 * @author            : Meenakshi Jain
 * @Created date      : April 2025
**/
@isTest
public class B2B_RelatedProductControllerTest {
    //variables
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String PRODUCTCHILD_NAME = 'Test Child Product';
    
    //create test data
    @testSetup
    public static void makeData(){
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,false);
        prod.B2B_Featured_Product__c = true;
        Product2 childProd = B2B_TestDataFactory.createProduct(PRODUCTCHILD_NAME,false);
        childProd.B2B_Featured_Product__c = true;
        List<Product2> prodList = new List<Product2>{prod,childProd};
            insert prodList;
        
        B2B_Related_Product__c b2bRelated = new B2B_Related_Product__c();
        b2bRelated.Parent_Product__c = prod.Id;
        b2bRelated.Child_Product__c = childProd.Id;
        insert b2bRelated;
    }
    
    //test for pdp page
    @isTest
    static void testPDPPage(){
        List<product2> prodList = [SELECT Id FROM Product2 WHERE Name =: PRODUCT_NAME ];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('isHomePage',false);
        mapParams.put('productId',prodList[0].Id);
        Map<String,Object> outputParam = B2B_RelatedProductController.getRelatedProducts(mapParams);
        Assert.areEqual(true, outputParam.containsKey('isSuccess'));
        Assert.areEqual(true, outputParam.containsKey('relatedProductList'));
        
    }
    
    //test for catch block
    @isTest
    static void testCatch(){
        Map<String,Object> outputParam = B2B_RelatedProductController.getRelatedProducts(null);
        Assert.areEqual(false, outputParam.get('isSuccess'));
    }
    
    //test for Home page
    @isTest
    static void testHomePage(){
        List<product2> prodList = [SELECT Id FROM Product2 WHERE Name =: PRODUCT_NAME ];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('isHomePage',true);
        
        Map<String,Object> outputParam = B2B_RelatedProductController.getRelatedProducts(mapParams);
        Assert.areEqual(true, outputParam.containsKey('isSuccess'));
        Assert.areEqual(true, outputParam.containsKey('relatedProductList'));
        
    }
}
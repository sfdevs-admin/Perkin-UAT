/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
public without sharing class B2BFeaturedCategoryHelper {
    
    public static Map<String,Object> getFeaturedCategories(Map<String,Object> mapParams) {
 
        Boolean isSuccess = false;
        String message = '';

        if (Test.isRunningTest() && mapParams.containsKey('throwTestException') && (Boolean)mapParams.get('throwTestException')) {
            throw new QueryException('Simulated exception for test coverage');
        }
        
        List<ProductCategory> featuredCategories = [
            SELECT Id, Name 
            FROM ProductCategory 
            WHERE B2B_Featured_Category__c = true 
            ORDER BY B2B_Featured_Category_Sort_Order__c 
            LIMIT 6
        ];

        if(!featuredCategories.isEmpty()){
            mapParams.put('featuredCategories', featuredCategories);
            isSuccess= true;
        }
        else{
            message = System.Label.B2B_Featured_Categories_Not_Found;
        }
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);

        return mapParams;
    }
}
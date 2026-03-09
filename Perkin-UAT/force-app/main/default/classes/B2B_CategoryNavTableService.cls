/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Suhail Ahmed T 
**/
// test class- B2B_CategoryNavTableControllerTest
public without sharing class B2B_CategoryNavTableService {
    private static String firstCategoryLabel = 'Kits & Bundles';
    private static String lastCategoryLabel = 'Other Parts';
    public B2B_CategoryNavTableService() {

    }

    public static Map<String,Object> fetchChildCategories(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        System.debug('fetchChildCategories mapParams-- '+JSON.serialize(mapParams));
        if( mapParams.containsKey('categoryId') ){
            String categoryId = (String)mapParams.get('categoryId');
            if( String.isNotBlank( categoryId ) ){
                List<B2B_Commerce_Category__c> childCategoryList = new List<B2B_Commerce_Category__c>();
                if ( Schema.sObjectType.B2B_Commerce_Category__c.isAccessible() ) {
                    childCategoryList = [SELECT Id, Name, Active__c, Label__c, Parent_Category__c, Child_Category__c, Technology_Type__c 
                                         FROM B2B_Commerce_Category__c 
                                         WHERE Parent_Category__c = :categoryId AND Active__c = true 
                                         
                                        ORDER BY Technology_Type__c,Label__c];
                } else {
                    message = System.Label.B2B_Commerce_Category_Object_Access_Error;
                }
                if( ! childCategoryList.isEmpty() ){
                    Map<String,List<Object>> childCategoryMap = new Map<String,List<Object>>();
                    for( B2B_Commerce_Category__c childCategory : childCategoryList ){
                        List<Object> categoryList = !childCategoryMap.containsKey( childCategory.Technology_Type__c ) ?
                            new List<Object>() :
                        childCategoryMap.get(childCategory.Technology_Type__c);
                       
                         
                        if(childCategory.Label__c == firstCategoryLabel){
                            categoryList.add(0,childCategory);
                        }else if(childCategory.Label__c == lastCategoryLabel){
                            categoryList.add(1,childCategory);
                        }else{
                            categoryList.add(childCategory);
                        }
                        childCategoryMap.put(childCategory.Technology_Type__c ,categoryList );
                        
                    }
                    List<CategoryWrapper> categoryWrapperList = new List<CategoryWrapper>();
                    for( String technologyType : childCategoryMap.keySet() ){
                        CategoryWrapper wrap = new CategoryWrapper();
                        wrap.technologyType = technologyType;
                        List<Object> categoryList = childCategoryMap.get(technologyType);
                        if(!categoryList.isEmpty()){
                            if(categoryList.size() > 2 && 
                               ((B2B_Commerce_Category__c)categoryList[1]).Label__c == lastCategoryLabel){
                                categoryList.add(categoryList[1]);
                                categoryList.remove(1);
                            }
                        }
                        wrap.childCategoryList = categoryList;
                        categoryWrapperList.add(wrap);
                    }
                    mapParams.put('childCategoryMap', childCategoryMap);
                    mapParams.put('categoryWrapperList', categoryWrapperList);
                    isSuccess = true;
                }
                else{
                    message = System.Label.B2B_Commerce_Category_No_Child_Error;
                }
            }
            else{
                message = System.Label.B2B_Commerce_Category_Id_Blank_Error;
            }
        }
         else{
            message = System.Label.B2B_Commerce_Category_Id_Blank_Error;
        }
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        return mapParams;
    }

    public class CategoryWrapper {
        @AuraEnabled
        public String technologyType;
        @AuraEnabled
        public List<Object> childCategoryList;
    }
}
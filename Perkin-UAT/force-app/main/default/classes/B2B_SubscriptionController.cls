/**
* @description       : 
* @author            : Gaurav Setia
* @group             : 
* @last modified on  : 07-24-2025
* @last modified by  : Gaurav Setia
* Test class - B2B_SubscriptionControllerTest
**/
public without sharing class B2B_SubscriptionController {
    
    @AuraEnabled
    public static Map<String,Object> createCartAndItems(Map<String,Object> mapParams){
        try{
            B2B_SubscriptionHelper.createCartAndItemsFromSubscriptions(mapParams);
            if(Test.isrunningTest() && mapParams.containsKey('testexception')){
                Integer res = 1/0;
            }
        } catch (Exception ex) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams ;
            mapParams.put('isSuccess', false);
            mapParams.put('msg', ex.getMessage());
        }
        return mapParams; 
    }
    
    @AuraEnabled
    public static Map<String,Object> checkForSubscriptionCart(Map<String,Object> mapParams){
        try{
            B2B_SubscriptionHelper.checkForSubscriptionCart(mapParams);
            if(Test.isrunningTest() && mapParams.containsKey('testexception')){
                Integer res = 1/0;
            }
        } catch (Exception ex) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams ;
            mapParams.put('isSuccess', false);
            mapParams.put('msg', ex.getMessage());
        }
        return mapParams; 
    } 
   
    @AuraEnabled
    public static Map<String,Object> getSubscriptions(Map<String,Object> mapParams){
        B2B_SubscriptionHelper.getSubscriptionList(mapParams);
        return mapParams; 
    }
    
    @AuraEnabled
    public static Map<String,Object> createRecord(Map<String,Object> mapParams){
        B2B_SubscriptionHelper.createRecord(mapParams);        
        return mapParams; 
    }
}
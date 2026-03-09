/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 07-08-2025
 * @last modified by  : Gaurav Setia
**/
public without sharing class B2B_ShippingController {
    
    @AuraEnabled
    public static Map<String,Object> getShippingDetails(Map<String,Object> mapParams){
        try{
            B2B_ShippingHelper.getShippingDetails(mapParams);
        } catch (Exception ex) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams ;
            mapParams.put('isSuccess', false);
            mapParams.put('msg', ex.getMessage());
        }
        return mapParams; 
    }
}
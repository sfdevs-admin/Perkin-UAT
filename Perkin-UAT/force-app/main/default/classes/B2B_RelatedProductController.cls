/**
 * @description       : 
 * @author            : surya.thakur
 * @group             : 
 * @last modified on  : 04-10-2024
 * @last modified by  : surya.thakur
 * test class 		  : B2B_RelatedProductControllerTest
**/
public with sharing class B2B_RelatedProductController {
    public B2B_RelatedProductController() {}

    @AuraEnabled
    public static Map<String,Object> getRelatedProducts(Map<String,Object> mapParams){
        try {
            B2B_RelatedProductService.getRelatedProducts(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message',e.getMessage());
        }
        return mapParams;
    }
}
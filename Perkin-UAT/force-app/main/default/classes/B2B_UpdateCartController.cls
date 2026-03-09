/*
    test class : B2B_UpdateCartControllerTest
*/

public without sharing class B2B_UpdateCartController {
    @AuraEnabled(cacheable=false)
    public static Map<String,Object> updateCartWithShippingProviderDetails(Map<String,Object> mapParams){   
        try {
            B2B_UpdateCartHelper.updateCartWithShippingProviderDetailsHelper(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }
}
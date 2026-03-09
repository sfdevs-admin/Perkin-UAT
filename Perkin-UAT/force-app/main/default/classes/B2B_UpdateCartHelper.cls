/*
    test class : B2B_UpdateCartControllerTest
*/

public without sharing class B2B_UpdateCartHelper {
    public static Map<String,Object> updateCartWithShippingProviderDetailsHelper(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        String cartId = (String) mapParams.get('cartId');
        String shippingProvider = (String) mapParams.get('shippingProvider');
        String shippingAccountStr = (String) mapParams.get('shippingAccountNumber');
        
        if(cartId != null && shippingProvider != null && shippingAccountStr != null){
            WebCart cartRecord = new WebCart();
            cartRecord.Id = cartId;
            cartRecord.B2B_Shipping_Provider__c = shippingProvider;
            cartRecord.B2B_Shipping_Provider_Account_Number__c = shippingAccountStr;
            update cartRecord;
            isSuccess=true;
        }
        else{
            message='An error occured while trying to update the Cart. Please contact your admin.';
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }
}
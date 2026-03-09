/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 09-06-2025
 * @last modified by  : S.T
**/
public without sharing class B2BCheckoutBillingAddressController {

    @TestVisible
    public static Boolean hasException = false;

    @AuraEnabled
    public static AddressValidationResponse validateAddress(AddressWrapper address){
        AddressValidationResponse avr = new AddressValidationResponse();
        Set<String> invalidFields = new Set<String>();
        if (address.street == null) {
            invalidFields.add('street');
        }
        if (address.city == null) {
            invalidFields.add('city');
        }
        if (address.region == null) {
            invalidFields.add('province');
        }
        if (address.postalCode == null) {
            invalidFields.add('postalCode');
        }
        if (address.country == null) {
            invalidFields.add('country');
        }
        String addressAsStr = '["' + address.street + ' ' + address.subpremise + '", "'+ address.city +', ' + address.region + ', ' + address.postalCode + '"]';
        
        System.debug('Validate Address Response: ' + B2BCheckoutBillingAddressService.validateAddress(addressAsStr));    
        return B2BCheckoutBillingAddressService.validateAddress(addressAsStr); 
    }

    @AuraEnabled
    public static void updateBiilingAddressOnCart(AddressWrapper address){
        try {
            if(Test.isRunningTest() && hasException) {
                throw new IllegalArgumentException('Error Test');
            }

            B2BCheckoutBillingAddressService.updateBiilingAddressOnCart(address);
        } 
        catch (Exception e) {
            Custom_Exception__c log = new Custom_Exception__c(
                Exception_Messages__c = e.getMessage(),
                Exception_Type__c = 'Update Billing Address On WebCart', 
                Extended_Status__c = 'Fail'
            );
            insert log;
        }
    }

    @AuraEnabled
    public static WebCart getExistingBillingAddress(String cartId) {
        try {
            if (Test.isRunningTest() && hasException) {
                throw new IllegalArgumentException('Error Test');
            }

            return B2BCheckoutBillingAddressService.getExistingBillingAddress(cartId);

        } catch (Exception e) {
            Custom_Exception__c log = new Custom_Exception__c(
                Exception_Messages__c = e.getMessage(),
                Exception_Type__c = 'Get Billing Address From WebCart',
                Extended_Status__c = 'Fail'
            );
            insert log;
            return null;
        }
    }

    @AuraEnabled
    public static Map<String,Object> getBillingCpaExist(Map<String,Object> mapParams) {
        mapParams = B2BCheckoutBillingAddressService.getBillingCpaExistHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> logExceptionForPayment(Map<String,Object> mapParams){
        try{
            B2BCheckoutBillingAddressService.logExceptionForPayment(mapParams);
        } catch (Exception ex) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams ;
            mapParams.put('isSuccess', false);
            mapParams.put('msg', ex.getMessage());
        }
        return mapParams; 
    }

    @AuraEnabled
    public static Map<String,Object> getExistingOrders(Map<String,Object> mapParams){
        try{
            B2BCheckoutBillingAddressService.getExistingOrders(mapParams);
        } catch (Exception ex) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams ;
            mapParams.put('isSuccess', false);
            mapParams.put('msg', ex.getMessage());
        }
        return mapParams; 
    }

    public class AddressValidationResponse {
        @AuraEnabled
        public boolean isValid { get; set; }

        @AuraEnabled
        public String address { get; set; }

        @AuraEnabled 
        public String street { get; set; }

        @AuraEnabled 
        public String route { get; set; }

        @AuraEnabled 
        public String streetNumber { get; set; }

        @AuraEnabled 
        public String subpremise { get; set; }

        @AuraEnabled 
        public String city { get; set; }

        @AuraEnabled 
        public String postalCode { get; set; }

        @AuraEnabled 
        public String state { get; set; }

        @AuraEnabled
        public String country { get; set; }

        @AuraEnabled
        public Set<String> invalidFields { get; set; }


    }

    public class AddressWrapper {
        @AuraEnabled
        public String id { get; set; }

        @AuraEnabled
        public String firstName { get; set; }

        @AuraEnabled
        public String lastName { get; set; }

        @AuraEnabled
        public String street { get; set; }

        @AuraEnabled 
        public String subpremise { get; set; }
    
        @AuraEnabled
        public String city { get; set; }
    
        @AuraEnabled
        public String region { get; set; }
    
        @AuraEnabled
        public String postalCode { get; set; }

        @AuraEnabled
        public String country { get; set; }
    }
}
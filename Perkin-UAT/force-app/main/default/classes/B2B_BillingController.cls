public without sharing class B2B_BillingController {
    @AuraEnabled
    public static Map<String, Object> getBillingDetails(Map<String, Object> mapParams) {
        mapParams = B2B_BillingHelper.getBillingDetailsHelper(mapParams);
        return mapParams;
    }
}
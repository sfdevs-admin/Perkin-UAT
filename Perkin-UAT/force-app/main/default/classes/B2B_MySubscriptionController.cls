public without sharing class B2B_MySubscriptionController {
    @AuraEnabled
    public static Map<String,Object> getSubscriptionLists(Map<String,Object> mapParams) {
        mapParams = B2B_MySubscriptionHelper.getSubscriptionListsHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> getSubscriptionItems(Map<String,Object> mapParams) {
        mapParams = B2B_MySubscriptionHelper.getSubscriptionItemsHelper(mapParams);
        
        return mapParams;
    }
}
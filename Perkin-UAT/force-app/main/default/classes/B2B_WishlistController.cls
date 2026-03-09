public with sharing class B2B_WishlistController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> isProductExistInWishlist(Map<String,Object> mapParams){   
        try {
            B2B_WishlistHelper.productInWishlistHelper(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }

    @Auraenabled
    public static Map<String,Object> deleteWishListItem(Map<String,Object> mapParams) {
        try {
            B2B_WishlistHelper.deleteWishListItemHelper(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }
}
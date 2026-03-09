public with sharing class B2B_WishlistHelper {
    public static Map<String,Object> productInWishlistHelper(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        String userId = (String) mapParams.get('userId');
        String productId = (String) mapParams.get('productId');

        List<WishlistItem> wishlistItem = [SELECT Id,CreatedById,product2id,WishlistId,Wishlist.WebStoreId FROM WishlistItem 
                                          WHERE CreatedById=:userId AND product2id=:productId LIMIT 1 ];
        
        if(!wishlistItem.isEmpty()){
            mapParams.put('wishlistItem', wishlistItem);
            isSuccess=true;
        }
        else{
            message = 'An error occured';
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }

    public static Map<String,Object> deleteWishListItemHelper(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        String webstoreId = (String) mapParams.get('webstoreId');
        String wishlistId = (String) mapParams.get('wishlistId');
        String wishlistItemId = (String) mapParams.get('wishlistItemId');
        
        if(webstoreId != null && wishlistId != null && wishlistItemId != null){
            ConnectApi.CommerceWishlist.removeWishlistItem(webstoreId, null, wishlistId, wishlistItemId);
            isSuccess=true;
        }
        else{
            message = 'Wishlist Item data does not exist';
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }
    
}
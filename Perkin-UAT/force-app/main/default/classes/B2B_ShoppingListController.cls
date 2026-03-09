public without sharing class B2B_ShoppingListController {
    @AuraEnabled
    public static Map<String,Object> getShoppingLists(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.getShoppingListsHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> getShoppingListItems(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.getShoppingListItemsHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> deleteShoppingList(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.deleteShoppingListHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> deleteShoppingListItem(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.deleteShoppingListItemHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> updateShoppingListItemQty(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.updateShoppingListItemQtyHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> createShoppingList(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.createShoppingListHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> addItemToShoppingList(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.addItemToShoppingListHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> getShoppingListById(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.getShoppingListByIdHelper(mapParams);
        
        return mapParams;
    }
    @AuraEnabled
    public static Map<String,Object> getPublicShoppingListById(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.getPublicShoppingListByIdHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> cloneShoppingList(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.cloneShoppingListHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> getWebstoreId(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.getWebstoreIdHelper(mapParams);
        
        return mapParams;
    }

    @AuraEnabled
    public static Map<String,Object> updateShoppingListDetails(Map<String,Object> mapParams) {
        mapParams = B2B_ShoppingListHelper.updateShoppingListDetailsHelper(mapParams);
        
        return mapParams;
    }
}
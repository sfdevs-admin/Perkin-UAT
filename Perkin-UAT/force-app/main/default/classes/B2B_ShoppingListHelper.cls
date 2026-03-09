public without sharing class B2B_ShoppingListHelper {
    //Get all active shopping list for current user's Account
    public static Map<String, Object> getShoppingListsHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        List<B2B_Shopping_List__c> shoppingLists;
        String userId = UserInfo.getUserId();
        String accountId = [SELECT AccountId FROM User WHERE Id = :userId].AccountId;

        try {
            shoppingLists = [SELECT Id, B2B_Name__c, B2B_Description__c, B2B_Active__c, B2B_Account__c, B2B_Default__c 
                            FROM B2B_Shopping_List__c 
                            WHERE B2B_Active__c = true AND B2B_Account__c = :accountId
                            ORDER BY B2B_Default__c DESC, CreatedDate ASC];

            if (shoppingLists.size() > 0) {
                isSuccess = true;
            } else {
                message = 'No shopping lists found';
            }
        } catch (Exception e) {
            message = 'Error occurred while calculating packaging fees: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('shoppingLists', shoppingLists);
        return mapParams;
    }

    // Get List of shopping list items for request shopping list ID
    public static Map<String, Object> getShoppingListItemsHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        List<Map<String, Object>> itemList = new List<Map<String, Object>>();

        try {
            Id shoppingListId = (Id) mapParams.get('shoppingListId');

            if (String.isNotBlank(shoppingListId)) {
                List<B2B_Shopping_List_Item__c> items = [
                    SELECT Id,
                        B2B_Product__c,
                        B2B_Product__r.Name,
                        B2B_Product__r.B2B_Part_Number__c,
                        B2B_Product__r.B2B_Short_Description__c,
                        B2B_Product__r.B2B_Display_Name__c,
                        B2B_Product__r.B2B_Item_Class_Description__c,
                        B2B_Product__r.B2B_Brand_Name__c,
                        B2B_Quantity__c,
                        B2B_Shopping_List__r.B2B_Name__c,
                        B2B_Shopping_List__r.B2B_Description__c,
                        B2B_Shopping_List__r.B2B_Default__c
                    FROM B2B_Shopping_List_Item__c
                    WHERE B2B_Shopping_List__c = :shoppingListId
                ];

                for (B2B_Shopping_List_Item__c item : items) {
                    Map<String, Object> entry = new Map<String, Object>{
                        'id' => item.Id,
                        'productId' => item.B2B_Product__c,
                        'productName' => item.B2B_Product__r?.Name,
                        'sku' => item.B2B_Product__r?.B2B_Part_Number__c,
                        'description' => item.B2B_Product__r?.B2B_Short_Description__c,
                        'quantity' => item.B2B_Quantity__c,
                        'shoppingListName' => item.B2B_Shopping_List__r?.B2B_Name__c,
                        'shoppingListDescription' => item.B2B_Shopping_List__r?.B2B_Description__c,
                        'isDefault' => item.B2B_Shopping_List__r?.B2B_Default__c,
                        'displayName' => item.B2B_Product__r?.B2B_Display_Name__c,
                        'itemClass' => item.B2B_Product__r?.B2B_Item_Class_Description__c,
                        'brandName' => item.B2B_Product__r?.B2B_Brand_Name__c
                    };
                    itemList.add(entry);
                }

                if (!itemList.isEmpty()) {
                    isSuccess = true;
                } else {
                    message = 'No items found for this shopping list.';
                }
            } else {
                message = 'Missing shoppingListId.';
            }
        } catch (Exception e) {
            message = 'Error while fetching shopping list items: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('shoppingListItems', itemList);

        return mapParams;
    }

    //Delete Shopping List for request ID
    public static Map<String, Object> deleteShoppingListHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        try {
            Id shoppingListId = (Id) mapParams.get('shoppingListId');

            if (String.isNotBlank(shoppingListId)) {
                B2B_Shopping_List__c listToDelete = [
                    SELECT Id 
                    FROM B2B_Shopping_List__c 
                    WHERE Id = :shoppingListId 
                    LIMIT 1
                ];

                if (listToDelete != null) {
                    // Delete related Shopping List Items
                    List<B2B_Shopping_List_Item__c> itemsToDelete = [
                        SELECT Id 
                        FROM B2B_Shopping_List_Item__c 
                        WHERE B2B_Shopping_List__c = :shoppingListId
                    ];

                    if (!itemsToDelete.isEmpty()) {
                        delete itemsToDelete;
                    }

                    delete listToDelete;

                    isSuccess = true;
                    message = 'Shopping list and its items deleted successfully.';
                } else {
                    message = 'Shopping list not found.';
                }
            } else {
                message = 'Missing shoppingListId.';
            }
        } catch (Exception e) {
            message = 'Error while deleting shopping list: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);

        return mapParams;
    }


    // Delete the shopping list item 
    public static Map<String, Object> deleteShoppingListItemHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        try {
            Id shoppingListItemId = (Id) mapParams.get('shoppingListItemId');

            if (String.isNotBlank(shoppingListItemId)) {
                B2B_Shopping_List_Item__c itemToDelete = [
                    SELECT Id 
                    FROM B2B_Shopping_List_Item__c 
                    WHERE Id = :shoppingListItemId 
                    LIMIT 1
                ];

                if (itemToDelete != null) {
                    delete itemToDelete;
                    isSuccess = true;
                    message = 'Shopping list item deleted successfully.';
                } else {
                    message = 'Shopping list item not found.';
                }
            } else {
                message = 'Missing shoppingListItemId.';
            }
        } catch (Exception e) {
            message = 'Error while deleting shopping list item: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);

        return mapParams;
    }

    //update the Quantity of shopping item
    public static Map<String, Object> updateShoppingListItemQtyHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        try {
            Id itemId = (Id) mapParams.get('shoppingListItemId');
            Decimal quantity = (Decimal) mapParams.get('quantity');

            if (String.isNotBlank(itemId) && quantity != null) {
                B2B_Shopping_List_Item__c itemToUpdate = [
                    SELECT Id, B2B_Quantity__c
                    FROM B2B_Shopping_List_Item__c
                    WHERE Id = :itemId
                    LIMIT 1
                ];

                itemToUpdate.B2B_Quantity__c = quantity;

                update itemToUpdate;

                isSuccess = true;
                message = 'Quantity updated successfully.';
            } else {
                message = 'Missing itemId or quantity.';
            }
        } catch (Exception e) {
            message = 'Error while updating quantity: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);

        return mapParams;
    }

    //create a new shopping list from PDP
    public static Map<String, Object> createShoppingListHelper(Map<String, Object> mapParams) {
        Map<String, Object> response = new Map<String, Object>();
        Boolean isSuccess = false;
        String message = '';
        B2B_Shopping_List__c newList;

        try {
            String name = (String)mapParams.get('name');
            String description = (String)mapParams.get('description');
            Boolean isDefault = (Boolean)mapParams.get('isDefault');

            if (String.isBlank(name)) {
                message = 'List name is required.';
            } else {
                String userId = UserInfo.getUserId();
                String accountId = [
                    SELECT AccountId 
                    FROM User 
                    WHERE Id = :userId 
                    LIMIT 1
                ].AccountId;

                // If isDefault is true, unset default for existing lists
                if (isDefault == true) {
                    List<B2B_Shopping_List__c> existingDefaults = [
                        SELECT Id 
                        FROM B2B_Shopping_List__c 
                        WHERE B2B_Account__c = :accountId AND B2B_Default__c = true
                    ];
                    for (B2B_Shopping_List__c shoppingList : existingDefaults) {
                        shoppingList.B2B_Default__c = false;
                    }
                    if (!existingDefaults.isEmpty()) {
                        update existingDefaults;
                    }
                }

                newList = new B2B_Shopping_List__c(
                    B2B_Name__c = name,
                    B2B_Description__c = description,
                    B2B_Account__c = accountId,
                    B2B_Active__c = true,
                    B2B_Default__c = isDefault == true
                );
                insert newList;

                isSuccess = true;
                message = 'Shopping list created successfully.';
            }
        } catch (Exception e) {
            message = 'Error while creating shopping list: ' + e.getMessage();
        }

        response.put('isSuccess', isSuccess);
        response.put('message', message);
        response.put('shoppingList', newList);

        return response;
    }

    //Add products to shopping list from PDP
    public static Map<String, Object> addItemToShoppingListHelper(Map<String, Object> mapParams) {
        Map<String, Object> response = new Map<String, Object>();
        Boolean isSuccess = false;
        String message = '';
        B2B_Shopping_List_Item__c newItem;

        String shoppingListId = (String)mapParams.get('shoppingListId');
        String productId = (String)mapParams.get('productId');
        Decimal quantity = (Decimal)mapParams.get('quantity');

        try {
            if (String.isBlank(shoppingListId) || String.isBlank(productId) || quantity == null) {
                message = 'Missing shopping list, product, or quantity.';
            } else {
                // Check if item already exists in the list
                List<B2B_Shopping_List_Item__c> existingItems = [
                    SELECT Id 
                    FROM B2B_Shopping_List_Item__c
                    WHERE B2B_Shopping_List__c = :shoppingListId
                    AND B2B_Product__c = :productId
                    LIMIT 1
                ];

                if (!existingItems.isEmpty()) {
                    message = System.Label.B2B_PDP_Product_Exist_Message;
                } else {
                    newItem = new B2B_Shopping_List_Item__c(
                        B2B_Shopping_List__c = shoppingListId,
                        B2B_Product__c = productId,
                        B2B_Quantity__c = quantity
                    );
                    insert newItem;

                    isSuccess = true;
                    message = 'Item added to shopping list successfully.';
                }
            }
        } catch (Exception e) {
            message = 'Error while adding item to shopping list: ' + e.getMessage();
        }

        response.put('isSuccess', isSuccess);
        response.put('message', message);
        response.put('shoppingListItem', newItem);

        return response;
    }

    //Get shopping list for provided ID
    public static Map<String, Object> getShoppingListByIdHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        List<B2B_Shopping_List__c> shoppingLists = new List<B2B_Shopping_List__c>();

        try {
            // Get shopping list Id from mapParams
            Id shoppingListId = (Id) mapParams.get('shoppingListId');

            if (shoppingListId != null) {
                shoppingLists = [
                    SELECT Id, B2B_Name__c, B2B_Description__c, B2B_Active__c, 
                        B2B_Account__c, B2B_Default__c, B2B_Public__c
                    FROM B2B_Shopping_List__c
                    WHERE Id = :shoppingListId  AND B2B_Active__c =: TRUE
                    ORDER BY B2B_Default__c DESC
                ];

                if (!shoppingLists.isEmpty()) {
                    isSuccess = true;
                } else {
                    message = 'No shopping list found with the provided Id';
                }
            } else {
                message = 'Shopping List Id is required';
            }
        } catch (Exception e) {
            message = 'Error occurred while fetching shopping list: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('shoppingLists', shoppingLists);
        return mapParams;
    }

    //Get Public shopping list for provided ID
    public static Map<String, Object> getPublicShoppingListByIdHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        List<B2B_Shopping_List__c> publicShoppingList = new List<B2B_Shopping_List__c>();

        try {
            // Get shopping list Id from mapParams
            Id shoppingListId = (Id) mapParams.get('shoppingListId');

            if (shoppingListId != null) {
                publicShoppingList = [
                    SELECT Id, B2B_Name__c, B2B_Description__c, B2B_Active__c, 
                        B2B_Account__c, B2B_Default__c, B2B_Public__c
                    FROM B2B_Shopping_List__c
                    WHERE Id = :shoppingListId AND B2B_Public__c = TRUE AND B2B_Active__c = TRUE
                ];

                if (!publicShoppingList.isEmpty()) {
                    isSuccess = true;
                } else {
                    message = 'No public shopping list found with the provided Id';
                }
            } else {
                message = 'Public Shopping List Id is required';
            }
        } catch (Exception e) {
            message = 'Error occurred while fetching public shopping list: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('publicShoppingList', publicShoppingList);
        return mapParams;
    }

    // Ceate a new list by Cloning Public List from Public Shopping Page
    public static Map<String, Object> cloneShoppingListHelper(Map<String, Object> mapParams) {
        Map<String, Object> response = new Map<String, Object>();
        Boolean isSuccess = false;
        String message = '';
        Id newListId;

        try {
            Id publicListId = (Id) mapParams.get('publicListId');
            String newName = (String) mapParams.get('newName');
            String newDescription = (String) mapParams.get('newDescription');
            Boolean makeDefault = (Boolean) mapParams.get('makeDefault');

            if (publicListId == null || String.isBlank(newName)) {
                message = 'Public List Id and New Name are required.';
                response.put('isSuccess', isSuccess);
                response.put('message', message);
                return response;
            }

            // Step 1: Create Shopping List using existing method
            Map<String, Object> createListParams = new Map<String, Object>{
                'name' => newName,
                'description' => newDescription,
                'isDefault' => makeDefault
            };

            Map<String, Object> createListResponse = createShoppingListHelper(createListParams);

            if (createListResponse.containsKey('isSuccess') && (Boolean)createListResponse.get('isSuccess')) {
                B2B_Shopping_List__c newList = (B2B_Shopping_List__c) createListResponse.get('shoppingList');
                newListId = newList.Id;

                // Step 2: Fetch items from source public list
                List<B2B_Shopping_List_Item__c> itemsToClone = [
                    SELECT B2B_Product__c, B2B_Quantity__c, B2B_Shopping_List__c
                    FROM B2B_Shopping_List_Item__c
                    WHERE B2B_Shopping_List__c = :publicListId
                ];

                // Step 3: Clone items
                List<B2B_Shopping_List_Item__c> clonedItems = new List<B2B_Shopping_List_Item__c>();
                for (B2B_Shopping_List_Item__c item : itemsToClone) {
                    clonedItems.add(new B2B_Shopping_List_Item__c(
                        B2B_Product__c = item.B2B_Product__c,
                        B2B_Quantity__c = item.B2B_Quantity__c,
                        B2B_Shopping_List__c = newListId
                    ));
                }

                if (!clonedItems.isEmpty()) {
                    insert clonedItems;
                }

                isSuccess = true;
                message = System.Label.B2B_PublicList_Clone_Success;
            } else {
                message = (String)createListResponse.get('message');
            }

        } catch (Exception ex) {
            message = 'Error while cloning shopping list: ' + ex.getMessage();
        }

        // Prepare response
        response.put('isSuccess', isSuccess);
        response.put('message', message);
        response.put('newShoppingListId', newListId);

        return response;
    }

    //Get webstoreid for provided community Id
    public static Map<String, Object> getWebstoreIdHelper(Map<String, Object> mapParams) {
        Map<String, Object> response = new Map<String, Object>();
        Boolean isSuccess = false;  
        String message = '';

        String communityId = (String)mapParams.get('communityId');
        String webstoreId = [
                    SELECT WebStoreId
                    FROM WebStoreNetwork
                    WHERE NetworkId = :communityId
                    LIMIT 1
                ]
                .WebStoreId;

        if (String.isNotEmpty(webstoreId)) {
            response.put('isSuccess', true);
            response.put('webstoreId', webstoreId);
        }

        return response;
    }


    public static Map<String, Object> updateShoppingListDetailsHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        Id shoppingListId = (Id) mapParams.get('shoppingListId');
        String newName = (String) mapParams.get('newName');
        String newDescription = (String) mapParams.get('newDescription');
        Boolean makeDefault = (Boolean) mapParams.get('makeDefault');

        try {
            B2B_Shopping_List__c listToUpdate = [
                SELECT Id, B2B_Name__c, B2B_Description__c, B2B_Default__c, B2B_Account__c
                FROM B2B_Shopping_List__c
                WHERE Id = :shoppingListId
                LIMIT 1
            ];

            listToUpdate.B2B_Name__c = newName;
            listToUpdate.B2B_Description__c = newDescription;
            listToUpdate.B2B_Default__c = makeDefault;

            List<B2B_Shopping_List__c> listsToUpdate = new List<B2B_Shopping_List__c>();
            listsToUpdate.add(listToUpdate);

            if (makeDefault) {
                // set all other lists for this account to false
                List<B2B_Shopping_List__c> otherLists = [
                    SELECT Id, B2B_Default__c
                    FROM B2B_Shopping_List__c
                    WHERE B2B_Account__c = :listToUpdate.B2B_Account__c
                    AND Id != :shoppingListId
                    AND B2B_Default__c = true
                ];

                for (B2B_Shopping_List__c olist : otherLists) {
                    olist.B2B_Default__c = false;
                    listsToUpdate.add(olist);
                }
            }

            update listsToUpdate;

            isSuccess = true;
            message = System.Label.B2B_ShoppingDetails_Update_Successfully;
        } catch (Exception e) {
            message = 'Error updating shopping list: ' + e.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);

        return mapParams;
    }





}
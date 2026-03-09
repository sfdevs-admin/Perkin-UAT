/**
 * @description       :
 * @author            : Gaurav Setia
 * @group             :
 * @last modified on  : 09-06-2025
 * @last modified by  : S.T
 * Test class - B2B_SubscriptionControllerTest
 **/
public inherited sharing class B2B_SubscriptionHelper {
    
    /**
     * Converts the subscription to cart, add the subscription products into the cart, and then return the cart details.
     **/
    public static Map<String,Object> createCartAndItemsFromSubscriptions(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        
        if(mapParams != null && mapParams.containsKey('effectiveAccountId') && mapParams.get('effectiveAccountId') != null
            && mapParams.containsKey('communityId') && mapParams.get('communityId') != null
            && mapParams.containsKey('recordId') && mapParams.get('recordId') != null)
        {
            Id subscriptionId = (Id) mapParams.get('recordId');
            Id effectiveAccountId = (Id) mapParams.get('effectiveAccountId');
            Id cartId = mapParams.containsKey('cartId') ? (Id) mapParams.get('cartId') : null;
            Id webStoreId = B2BUtils.getWebstoreId((String) mapParams.get('communityId'));
            String currencyCode = B2BUtils.getCurrencyIsoCode(effectiveAccountId);

            // failed pricing product ids
            Set<Id> failedProductIds = new Set<Id>();
            if(mapParams.containsKey('pricingFailedProductIds') && mapParams.get('pricingFailedProductIds') != null){
                List<Object> rawList = (List<Object>) mapParams.get('pricingFailedProductIds');
                for(Object pid : rawList){
                    failedProductIds.add((Id)pid);
                }
            }

            // failedProductIds.add('01tbc000004RWuIAAW');
            
            Map<Id, B2B_Subscription_Items__c> prodIdTosubItemsMap = fetchSubscriptionsAndItems(subscriptionId, effectiveAccountId, failedProductIds);
            if(cartId == null) {
                cartId = createCart(mapParams);
            }
            
            if(cartId != null && prodIdTosubItemsMap != null) {
                createCartItems(effectiveAccountId, webStoreId, currencyCode, prodIdTosubItemsMap);
                copySubscriptionFields(cartId, prodIdTosubItemsMap);
                isSuccess = true;
            } else {
                message = 'Cart creation process failed.';
            }
        } else {
            message = 'Invalid or missing mapParams.';
        }
        
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        return mapParams;
    }
    
    /**
     * Check if cart's a subscription cart.
     **/
    public static Map<String,Object> checkForSubscriptionCart(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        
        if(mapParams != null && mapParams.containsKey('cartId') && mapParams.get('cartId') != null)
        {
            Id cartId = (Id) mapParams.get('cartId');
            
            Webcart cart = fetchCartAndItems(cartId);
            if(cart != null) {
                mapParams.put('hasSubscription', cart?.B2B_Is_Subscription__c);
                mapParams.put('billingFrequency', cart?.B2B_Subscriptions__r.B2B_Billing_Frequency__c);
                mapParams.put('subscriptionName', cart?.B2B_Subscriptions__r.Subscription_Name__c);
                isSuccess = true;
            } else {
                message = 'Cart not available.';
            }
        } else {
            message = 'Invalid or missing mapParams.';
        }
        
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        return mapParams;
    }
    
    private static Map<Id, B2B_Subscription_Items__c> fetchSubscriptionsAndItems(Id subscriptionId, Id effectiveAccountId, Set<Id> failedProductIds) {
        Map<Id, B2B_Subscription_Items__c> prodIdTosubItemsMap  = new  Map<Id, B2B_Subscription_Items__c>();
        List<B2B_Subscriptions__c> subscriptions;
        Id contactId = [SELECT contactId FROM User WHERE Id =: UserInfo.getUserId()]?.contactId;
        if(subscriptionId != null && effectiveAccountId != null) {
            subscriptions = [
                SELECT 
                Id, Name, B2B_Account__c, B2B_Billing_Address__c, B2B_Billing_Frequency__c, B2B_Contact__c,
                B2B_Next_Billing_Date__c, B2B_Payment_Method__c, B2B_Shipping_Address__c, B2B_Shipping_Method__c, 
                B2B_Start_Date__c, B2B_Status__c,
                (
                    SELECT 
                        Id, Name, CurrencyIsoCode, B2B_Subscriptions__c, B2B_Quantity__c,
                        B2B_Product__c, B2B_Unit_Price__c, B2B_List_Price__c, B2B_Discount__c
                    FROM 
                    B2B_Subscription_Items__r
                )
                FROM 
                B2B_Subscriptions__c 
                WHERE 
                Id = :subscriptionId 
                AND 
                B2B_Status__c IN ('Inactive', 'Paused')
                AND
                B2B_Account__c = :effectiveAccountId
                AND
                B2B_Contact__c = :contactId
            ];
        }
        
        if(subscriptions != null && subscriptions.size() > 0) {
            for(B2B_Subscription_Items__c subItem : subscriptions[0].B2B_Subscription_Items__r) {
                // prodIdTosubItemsMap.put(subItem.B2B_Product__c, subItem);

                // skip if product is in failedProductIds
                if( failedProductIds == null || failedProductIds.isEmpty() || !failedProductIds.contains(subItem.B2B_Product__c)){
                    prodIdTosubItemsMap.put(subItem.B2B_Product__c, subItem);
                }
            }
            return prodIdTosubItemsMap;
        }
        
        return null;
    }
    
    private static WebCart fetchCartAndItems(Id cartId) {
        List<Webcart> carts;
        
        if(cartId != null) {
            carts = [
                SELECT 
                Id, Name, Status, Type, B2B_Is_Subscription__c, B2B_Subscriptions__c, 
                B2B_Subscriptions__r.B2B_Billing_Frequency__c,B2B_Subscriptions__r.Subscription_Name__c,
                (
                    SELECT 
                        Id, Name, CurrencyIsoCode, ListPrice, B2B_Is_Subscription__c, Product2Id,
                        B2B_Subscription_Price__c, B2B_Subscription_Item__c, Quantity,
                        UnitAdjustedPrice, UnitAdjustedPriceWithItemAdj
                    FROM 
                    CartItems
                )
                FROM 
                WebCart 
                WHERE 
                Id = :cartId
            ];
            
            return carts[0];
        }
        
        return null;
    }
    
    private static Id createCart(Map<String,Object> mapParams) {
        Id effectiveAccountId = (Id) mapParams.get('effectiveAccountId');
        Id cartId = mapParams.containsKey('cartId') ? (Id) mapParams.get('cartId') : null;
        Id webStoreId = B2BUtils.getWebstoreId((String) mapParams.get('communityId'));
        String currencyCode = B2BUtils.getCurrencyIsoCode(effectiveAccountId);
        
        ConnectApi.CartSummary cartSummary = null;

        // custom field 
        List<SObject> webCartList = new List<SObject>();
        WebCart webCart = new WebCart();
        webCart.B2B_Is_Subscription__c = true;
        webCartList.add(webCart);
        
        ConnectApi.CartInput cartInput  = new ConnectApi.CartInput();
        cartInput.effectiveAccountId = effectiveAccountId;
        cartInput.currencyIsoCode = currencyCode;
        cartInput.isSecondary = false;
        cartInput.customFields = webCartList;
        
        
        cartSummary = !Test.isRunningTest() ? ConnectApi.CommerceCart.createCart(webStoreId , cartInput) :
        B2B_CommerceCartServiceMock.createCart(mapParams);
        if(cartSummary != null) {
            return cartSummary.cartId;
        }
        return null;
    }
    
    private static void createCartItems(Id accId, Id webStoreId, String currencyCode, Map<Id, B2B_Subscription_Items__c> prodIdTosubItemsMap) {
        List<ConnectApi.BatchResult> lstBatchResults = null;
        List<ConnectApi.BatchInput> cartItems = new List<ConnectApi.BatchInput>();
        
        if(prodIdTosubItemsMap != null) {
            for(Id proId : prodIdTosubItemsMap.keySet()) {
                List<SObject> webCartItemList = new List<SObject>();
                CartItem ci = new CartItem();
                ci.B2B_Original_Price__c = prodIdTosubItemsMap.get(proId).B2B_List_Price__c;
                ci.B2B_Deal_Discount__c = prodIdTosubItemsMap.get(proId).B2B_Discount__c;
                webCartItemList.add(ci);
                ConnectApi.CartItemInput cartItemInputObject = new ConnectApi.CartItemInput();
                cartItemInputObject.productId = String.valueOf(prodIdTosubItemsMap.get(proId).B2B_Product__c);
                cartItemInputObject.quantity = String.valueOf(prodIdTosubItemsMap.get(proId).B2B_Quantity__c);
                cartItemInputObject.type = ConnectApi.CartItemType.Product;
                cartItemInputObject.customFields = webCartItemList;
                
                ConnectApi.BatchInput addBatchInputObject = new ConnectApi.BatchInput(cartItemInputObject);
                cartItems.add(addBatchInputObject);
            }
        }
        
        if(!Test.isRunningTest()){
            lstBatchResults = ConnectApi.CommerceCart.addItemsToCart(webStoreId, accId , 'current' , cartItems, currencyCode);
        }
        
        if(lstBatchResults != null && lstBatchResults[0].isSuccess) {
            //Todo Add exception logging for any failed insertion
            //ConnectApi.CartItem batchResult = (ConnectApi.CartItem)lstBatchResults[0].getResult();
        }
    }
    
    private static void copySubscriptionFields(Id cartId, Map<Id, B2B_Subscription_Items__c> prodIdTosubItemsMap) {
        List<sObject> sobjectToUpdate = new List<sObject>();
        Map<Id, Id> product2ItemIdsMap = new Map<Id, Id>();
        
        Webcart cart = fetchCartAndItems(cartId);
        if(cart != null && prodIdTosubItemsMap != null) {
            cart.B2B_Is_Subscription__c = true;
            cart.B2B_Subscriptions__c = prodIdTosubItemsMap.values()[0].B2B_Subscriptions__c;
            cart.Name = 'Subscription Cart';
            sobjectToUpdate.add(cart);
            
            for(CartItem newItem : cart.CartItems) {
                Decimal price = prodIdTosubItemsMap.get(newItem.Product2Id).B2B_Unit_Price__c;

                //commented code 
                // Decimal discountedPercent = ((newItem.UnitAdjustedPrice - newItem.UnitAdjustedPriceWithItemAdj) / newItem.UnitAdjustedPrice * 100).setScale(2, RoundingMode.HALF_UP);
                // Decimal discountedPrice = price - (price * discountedPercent) / 100;
                // Decimal totalLineAmount = (discountedPrice * newItem.Quantity).setScale(2, RoundingMode.HALF_UP);
                
                newItem.B2B_Is_Subscription__c = true;
                newItem.B2B_Subscription_Price__c = price;
                newItem.B2B_Subscription_Item__c = prodIdTosubItemsMap.get(newItem.Product2Id).Id;
                newItem.ListPrice = prodIdTosubItemsMap.get(newItem.Product2Id).B2B_List_Price__c;
                
                //commented code 
                // newItem.UnitAdjustedPrice = price;
                // newItem.UnitItemAdjustmentAmount = -(price - discountedPrice);
                // newItem.UnitAdjustedPriceWithItemAdj = discountedPrice;
                // newItem.ListPrice = price;
                // newItem.SalesPrice = discountedPrice;
                // newItem.TotalLineAmount = totalLineAmount;
                // newItem.TotalPrice = totalLineAmount;
                // newItem.TotalPromoAdjustmentAmount = -((price - discountedPrice) * newItem.Quantity);
                // newItem.TotalAdjustmentAmount = -((price - discountedPrice) * newItem.Quantity);
                // newItem.TotalPriceAfterAllAdjustments = totalLineAmount;


                sobjectToUpdate.add(newItem);
            }
        }
        
        if(sobjectToUpdate != null && sobjectToUpdate.size() > 0) {
            Database.update(sobjectToUpdate);
        }
    }
    
    
    //Get all active subscription list for current user's Account
    public static Map<String, Object> getSubscriptionList(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        
        Map<String,List<B2B_Subscriptions__c>> billingFrequencyVsSubscriptionMap = new Map<String,List<B2B_Subscriptions__c>>();
        Map<Id,B2B_Subscriptions__c> subscriptions= new Map<Id,B2B_Subscriptions__c>();
        try {
            String accountId = (String) mapParams.get('accountId');
            String currencyIsoCode = String.isNotBlank(accountId) ? B2BUtils.getCurrencyIsoCode(accountId) : 'USD';
            
            subscriptions= new Map<Id,B2B_Subscriptions__c>([SELECT Id, Subscription_Name__c, Description__c,
            B2B_Status__c, B2B_Account__c ,B2B_Billing_Frequency__c,
            (SELECT 
                        Id, Name, CurrencyIsoCode, B2B_Subscriptions__c, B2B_Quantity__c,
                        B2B_Product__c, B2B_Unit_Price__c
                    FROM 
                    B2B_Subscription_Items__r
                    WHERE B2B_Product__c =:(String) mapParams.get('productId')
                )
            FROM B2B_Subscriptions__c
            WHERE B2B_Billing_Frequency__c =: (String) mapParams.get('billingFrequency')
            AND B2B_Account__c =:(String) mapParams.get('accountId') AND 
            CurrencyIsoCode =: currencyIsoCode AND
			B2B_Status__c != 'Expired'
             ORDER BY Subscription_Name__c ASC, CreatedDate ASC] );
            
            if(subscriptions.isEmpty())
                message = 'No Subscriptions found';
            
            isSuccess = true;
            
        } catch (Exception e) {
            message = 'Error while getching subscriptions ' + e.getMessage();
        }
        
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('subscriptions', subscriptions);
        return mapParams;
    }
    
    //Create Record of Subscription/Subscription item based on sobjecttype
    public static Map<String, Object> createRecord(Map<String, Object> mapParams) {
        String message = '';
        Boolean isSuccess = false;
        
        try{
            String objectType = (String)mapParams.get('sobjectType');
            //Convert Generic Map to Sobject
            Sobject subscriptionRecord = B2B_SubscriptionUtil.getInstance(objectType,
            (Map<Object,Object> ) mapParams.get('insertRecord'));
            if(subscriptionRecord != null){
                if(objectType =='B2B_Subscriptions__c'){
                    User user = [SELECT Id,ContactId FROM User
                     WHERE Id =: UserInfo.getUserId()];
                    if(user?.contactId != null){
                        subscriptionRecord.put('B2B_Contact__c',user.contactId);
                    }
                    
                }
                if(String.isNotBlank((String) mapParams.get('accountId'))){
                    subscriptionRecord.put('CurrencyIsoCode',B2BUtils.getCurrencyIsoCode((String) mapParams.get('accountId')));
                }
                mapParams.put('insertRecord',subscriptionRecord);
                mapParams.put('doInsert',true);
                //insert Record
                B2B_SubscriptionUtil.createSubscription(mapParams);
                
            }
            isSuccess = true;
        }
        catch (Exception e) {
            message = 'Error while creating Record ' + e.getMessage();
            isSuccess = false;
            
        }
        
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        
        return mapParams;
    }
    
}
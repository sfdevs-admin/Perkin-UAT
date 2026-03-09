/**
 * Trigger handler to update B2B_Deal_Discount__c and B2B_Original_Price__c on cart item AFTER INSERT
 * Test class - B2B_CartItemTriggerServiceTest
 */
public without sharing class B2B_CartItemTriggerService {

    public static void updateDealInformation(List<CartItem> cartItems) {

        B2BCustomPricingService customPricing = new B2BCustomPricingService();
        B2B_CartItemTriggerService cartItemTrigger = new B2B_CartItemTriggerService();

        if (cartItems.isEmpty()) return;
        try {

            CartContext ctx = buildCartContext(cartItems);
            if (ctx == null || ctx.productIds.isEmpty() || ctx.accountId == null) return;

            String sObjName = ctx.accountId.getSObjectType().getDescribe().getName();
            if (customPricing.isValidAccount(sObjName)) {
                if (customPricing.validateDealsOnAccount(ctx.accountId)) {
                    cartItemTrigger.updateDealInformartionOnCartItem(ctx.accountId, ctx.productIds, customPricing, ctx.cartItemMap);
                }
            }
        } catch(Exception e) {
            Custom_Exception__c log = new Custom_Exception__c(Exception_Messages__c = e.getMessage(), Exception_Type__c = 'Update Deal Information On CartItem Via Trigger', Extended_Status__c = 'Fail');
            insert log;
        }
    }

    private static CartContext buildCartContext(List<CartItem> cartItems) {
        Set<Id> cartItemIds = new Map<Id, CartItem>(cartItems).keySet();

        Map<Id, CartItem> cartItemMap = new Map<Id, CartItem>(
            [SELECT Id, Product2Id, ListPrice, 
                    Cart.AccountId, Type
             FROM CartItem
             WHERE Id IN :cartItemIds]
        );

        Set<Id> productIds = new Set<Id>();
        Id accountId;

        for (CartItem ci : cartItemMap.values()) {
            if (ci.Product2Id != null) productIds.add(ci.Product2Id);
            if (ci.Cart != null && ci.Cart.AccountId != null) {
                accountId = ci.Cart.AccountId;
            }
        }

        if (cartItemMap.isEmpty()) return null;

        return new CartContext(cartItemMap, productIds, accountId);
    }

    private void updateDealInformartionOnCartItem(Id accountId, Set<Id> productIds, B2BCustomPricingService customPricing, Map<Id, CartItem> cartItemMap) {
        // Fetch deals and build discount map
        Map<Id, Product2> productMap = customPricing.fetchProducts(productIds);

        Map<String, Id> keyToProductIdMap = customPricing.buildKeyToProductIdMap(productMap);
        Set<String> lineClassKeys = keyToProductIdMap.keySet();

        if (lineClassKeys.isEmpty()) return;

        List<B2B_Deal_Discount_Line__c> activeDeals = customPricing.fetchActiveDeals(accountId);
        Map<String, Decimal> discountMap = customPricing.buildDiscountMap(activeDeals, lineClassKeys);

        // update discounts and original price
        List<CartItem> updates = new List<CartItem>();
        for (CartItem ci : cartItemMap.values()) {
            if (ci.Type == 'Product') {
                Product2 prod = productMap.get(ci.Product2Id);
                if (prod == null) continue;

                String key = prod.product_line__c + '|' + prod.Item_Class__c;
                Decimal discountPercent = discountMap.containsKey(key) ? discountMap.get(key) : 0;

                Decimal originalPrice = ci.ListPrice != null ? ci.ListPrice : 0;

                updates.add(new CartItem(
                    Id = ci.Id,
                    B2B_Deal_Discount__c = discountPercent,
                    B2B_Original_Price__c = originalPrice
                ));
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    private class CartContext {
        Map<Id, CartItem> cartItemMap;
        Set<Id> productIds;
        Id accountId;

        CartContext(Map<Id, CartItem> cartItemMap, Set<Id> productIds, Id accountId) {
            this.cartItemMap = cartItemMap;
            this.productIds = productIds;
            this.accountId = accountId;
        }
    }
}
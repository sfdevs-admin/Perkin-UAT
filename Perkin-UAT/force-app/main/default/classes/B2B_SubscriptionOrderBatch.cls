/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 09-06-2025
 * @last modified by  : S.T
**/
public with sharing class B2B_SubscriptionOrderBatch implements Database.Batchable<SObject>, Database.Stateful {
    private final String className = 'B2B_SubscriptionOrderBatch';

    public final String query;
    private List<Id> subscriptionIds;

    public B2B_SubscriptionOrderBatch(String queryStr) {
        this.query = queryStr;
    }

    /**
     * @description       : Defines the scope of the records to be processed in the batch.
     * @param bc          : The batchable context.
     * @return            : QueryLocator containing the records for processing.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /**
     * @description       : Processes each batch of B2B_Subscriptions__c records and create order and order items.
     *                      Add the shipping and taxes, process payments and create order summaries.
     * @param bc          : The batchable context.
     * @param objects     : The list of B2B_Subscriptions__c records to process in this batch.
     */
    public void execute(Database.BatchableContext bc, List<SObject> objects) {
        
        try {
            if (objects == null || objects.isEmpty()) {
                return;
            }
            subscriptionIds = new List<Id>();
            List<B2B_Subscriptions__c> subscriptions = new List<B2B_Subscriptions__c>();
            List<B2B_Subscriptions__c> subscriptionsToCancel = new List<B2B_Subscriptions__c>();
            List<B2B_Subscriptions__c> subscriptionsInput = (List<B2B_Subscriptions__c>) objects;
            System.debug('###subscriptions ' + subscriptionsInput);
            Date today = Date.today();
            for (B2B_Subscriptions__c sub : subscriptionsInput) {
                if( today.isSameDay( sub.B2B_End_Date__c )){
                    subscriptionsToCancel.add(sub);
                }else{
                    subscriptionIds.add(sub.Id);
                    subscriptions.add(sub);
                }
            }
            if( subscriptionsToCancel != null && subscriptionsToCancel.size() > 0 ){
                B2B_SubscriptionOrderHelper.cancelSubscriptions( subscriptionsToCancel );
            }
            if( subscriptions != null || subscriptions.size() > 0 ) {
                //Step 1: Create Order and Order Items for Subscriptions and Subscription Items
                List<Order> orderList = createOrderAndItems(subscriptions);
                B2B_SubscriptionOrderHelper.updateSubscriptions(subscriptions, 'Step 1: Order and Order Items Creation');
                System.debug('###orderList ' + orderList);

                if (orderList != null && orderList.size() > 0) {
                    List<Id> orderIds = new List<Id>();
                    for (Order ord : orderList) {
                        orderIds.add(ord.Id);
                    }

                    List<Order> fetchedOrders = B2B_SubscriptionOrderHelper.getOrderDetails(orderIds);
                    System.debug('###fetchedOrders ' + fetchedOrders);
                    
                    B2B_SubscriptionOrderHelper.createContentDocLinkToOrder( subscriptions, fetchedOrders );

                    List<Product2> shippingProducts = [SELECT Id FROM Product2 WHERE Name =:System.Label.B2B_Shipping_Product_Name LIMIT 1];

                    if(shippingProducts != null && shippingProducts.size() > 0) {
                        System.debug('Shipping Products found: ' + shippingProducts);
                        // Step 2: Apply Shipping Charges
                        applyShipping(fetchedOrders, shippingProducts[0].Id);
                        B2B_SubscriptionOrderHelper.updateSubscriptions(subscriptions, 'Step 2: Shipping Calculations');
                    } 
                    
                    // Step 3: Apply Taxes
                    System.debug('Applying Taxes');
                    applyTaxes(fetchedOrders);
                    B2B_SubscriptionOrderHelper.updateSubscriptions(subscriptions, 'Step 3: Tax Calculations');
                }
            }    
        } catch (Exception e) {
            B2B_SubscriptionOrderHelper.logSubscriptionException(subscriptionIds, e.getMessage(), e.getStackTraceString(), className);
            System.debug('Error in execute method: ' + e.getMessage());
        }
    }

    /**
     * @description       : Finalizes the batch execution.
     * @param bc          : The batchable context.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('JobId => ' + bc.getJobId());
    }

    /**
     * @description       : Creates orders and order items for the given subscriptions.
     * @param subscriptions : The list of B2B_Subscriptions__c records to create orders for.
     * @return            : List of created Order records.
     */
    private List<Order> createOrderAndItems(List<B2B_Subscriptions__c> subscriptions) {
        List<Id> subIds = new List<Id>();
        Map<Id, List<B2B_Subscription_Items__c>> subItemMap = new Map<Id, List<B2B_Subscription_Items__c>>();
        
        for (B2B_Subscriptions__c s : subscriptions) {
            subIds.add(s.Id);
        }

        for (B2B_Subscription_Items__c item : [
            SELECT Id, B2B_Subscriptions__c, B2B_Product__c, B2B_Quantity__c, B2B_Unit_Price__c, B2B_Total_Price__c, B2B_List_Price__c,
            B2B_Discount__c            
            FROM B2B_Subscription_Items__c
            WHERE B2B_Subscriptions__c IN :subIds
        ]) {
            if (!subItemMap.containsKey(item.B2B_Subscriptions__c)) {
                subItemMap.put(item.B2B_Subscriptions__c, new List<B2B_Subscription_Items__c>());
            }
            subItemMap.get(item.B2B_Subscriptions__c).add(item);
        }
        System.debug('###subItemMap ' + subItemMap);

        // Step 1: Create Order and Order Items for Subscriptions and Subscription Items
        List<Order> createdOrders = B2B_SubscriptionOrderHelper.createOrdersWithItems(subscriptions, subItemMap);
        System.debug('###createdOrders ' + createdOrders);
        return createdOrders;
    }

    /**
     * @description       : Applies shipping charges to the orders.
     * @param orders      : The list of orders to apply shipping charges to.
     * @param shippingProductId : The ID of the shipping product to be applied.
     */
    private void applyShipping(List<Order> orders, Id shippingProductId) {
        List<OrderItem> itemsToInsert = new List<OrderItem>();
        for (Order ord : orders) {
            Decimal shippingCharge = B2B_SubscriptionShippingCalHelper.calculateShippingCharge(ord);
            System.debug('Shipping charge for Order ' + ord.Id + ': ' + shippingCharge);
            
            if(shippingProductId != null) {
                OrderItem shippingItem = new OrderItem(
                    OrderId = ord.Id,
                    Quantity = 1,
                    UnitPrice = shippingCharge,
                    Type = 'Delivery Charge',
                    Product2Id = shippingProductId,
                    ListPrice = shippingCharge,
                    OrderDeliveryGroupId = ord.orderItems.get(0).OrderDeliveryGroupId
                );
                itemsToInsert.add(shippingItem);
            }
        }
        if (itemsToInsert != null && itemsToInsert.size() > 0) {
            insert itemsToInsert;
        }
    }

    /**
     * @description       : Applies taxes to the orders.
     * @param orders      : The list of orders to apply taxes to.
     */
    private void applyTaxes(List<Order> orders) {
        for(Order ord : orders) {
            // B2B_SubscriptionOrderHelper.applyTaxesToOrder(ord);
            ID jobID = System.enqueueJob(new B2B_SubscriptionTaxQueueable(ord.Id, ord.B2B_Subscriptions__c));
        }
    }
}
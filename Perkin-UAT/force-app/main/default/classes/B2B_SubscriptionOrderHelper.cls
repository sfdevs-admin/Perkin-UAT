/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 02-26-2026
 * @last modified by  : Swati Chilap
 * @Test Class        : B2B_SubscriptionOrderSchedulerTest
**/
public with sharing class B2B_SubscriptionOrderHelper {

    private final String className = 'B2B_SubscriptionOrderHelper';
    
    public static List<Order> createOrdersWithItems(
        List<B2B_Subscriptions__c> subscriptions,
        Map<Id, List<B2B_Subscription_Items__c>> subItemMap
    ) {
        List<Order> orders = new List<Order>();
        orders = createOrders(subscriptions);
        insertOrderItems(orders, subscriptions, subItemMap);
        return orders;
    }

    private static List<Order> createOrders(List<B2B_Subscriptions__c> subscriptions) {
        List<Order> ordersToInsert = new List<Order>();

        for (B2B_Subscriptions__c sub : subscriptions) {
            if (sub.B2B_Billing_Address__r == null || sub.B2B_Shipping_Address__r == null) {
                System.debug('Missing billing or shipping address on subscription: ' + sub.Id);
                continue;
            }

            Order order = new Order(
                Status = 'Draft',
                AccountId = sub.B2B_Account__c,
                EffectiveDate = Date.today(),
                OrderedDate = Datetime.now(),
                Type = 'Subscription',
                Name = 'Subscription Order - ' + sub.Subscription_Name__c,
                B2B_Subscriptions__c = sub.Id,
                B2B_Is_Subscription__c = true,
                BillToContactId = sub.B2B_Contact__c,
                OwnerId = sub.OwnerId,
                CurrencyIsoCode = sub.CurrencyIsoCode,
                B2B_Special_Instruction__c = sub.B2B_Special_Instruction__c,
                B2B_Shipping_Provider__c = sub.B2B_Shipping_Provider__c,
                B2B_Shipping_Provider_Account_Number__c = sub.B2B_Shipping_Provider_Account_Number__c,
                SalesStoreId = getWebstore().Id,
                // Billing
                BillingStreet     = sub.B2B_Billing_Address__r.Street,
                BillingCity       = sub.B2B_Billing_Address__r.City,
                BillingState      = sub.B2B_Billing_Address__r.State,
                BillingPostalCode = sub.B2B_Billing_Address__r.PostalCode,
                BillingCountry    = sub.B2B_Billing_Address__r.Country,

                // Shipping
                ShippingStreet     = sub.B2B_Shipping_Address__r.Street,
                ShippingCity       = sub.B2B_Shipping_Address__r.City,
                ShippingState      = sub.B2B_Shipping_Address__r.State,
                ShippingPostalCode = sub.B2B_Shipping_Address__r.PostalCode,
                ShippingCountry    = sub.B2B_Shipping_Address__r.Country
            );
            if( sub.B2B_Payment_Method__c != null && sub.B2B_Payment_Method__c == 'PO') {
                order.PoNumber = sub.B2B_Po_Number__c;
            }

            ordersToInsert.add(order);
        }

        if (ordersToInsert != null && ordersToInsert.size() > 0) { 
            insert ordersToInsert;
        }
        return ordersToInsert;
    }

    private static void insertOrderItems(
        List<Order> orders,
        List<B2B_Subscriptions__c> subscriptions,
        Map<Id, List<B2B_Subscription_Items__c>> subItemMap
    ) {
        if (orders.isEmpty()) return;

        Map<Id, Order> subToOrderMap = new Map<Id, Order>();
        for (Order ord : orders) {
            subToOrderMap.put(ord.B2B_Subscriptions__c, ord);
        }

        Map<String, OrderDeliveryGroup> subToODGMap = createOrderDeliveryGroup(subToOrderMap, subscriptions);
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        for (List<B2B_Subscription_Items__c> itemList : subItemMap.values()) {
            for (B2B_Subscription_Items__c item : itemList) {
                Order relatedOrder = subToOrderMap.get(item.B2B_Subscriptions__c);
                if (relatedOrder == null) continue;

                OrderItem orderItem = new OrderItem(
                    OrderId = relatedOrder.Id,
                    Product2Id = item.B2B_Product__c,
                    Quantity = item.B2B_Quantity__c,
                    UnitPrice = item.B2B_Unit_Price__c,
                    TotalLineAmount = item.B2B_Total_Price__c,
                    ListPrice = item.B2B_Unit_Price__c,
                    B2B_Original_Price__c = item.B2B_List_Price__c,
                    B2B_Deal_Discount__c = item.B2B_Discount__c,
                    ReferencePrice = item.B2B_List_Price__c,
                    OrderDeliveryGroupId = subToODGMap.get(item.B2B_Subscriptions__c).Id,
                    Type = 'Order Product'
                );
                orderItemsToInsert.add(orderItem);
            }
        }

        if (orderItemsToInsert != null && orderItemsToInsert.size() > 0) {
            insert orderItemsToInsert;
        }
    }

    private static Map<String, OrderDeliveryGroup> createOrderDeliveryGroup(Map<Id, Order> mapParams, List<B2B_Subscriptions__c> subscriptions) {

        List<OrderDeliveryMethod> deliveryMethods = new List<OrderDeliveryMethod>();
        Map<String, OrderDeliveryMethod> deliveryMethodMap = new Map<String, OrderDeliveryMethod>();
        List<OrderDeliveryGroup> OrderDeliveryGroupsToInsert = new List<OrderDeliveryGroup>();
        Map<String, OrderDeliveryGroup> subToODGMap = new Map<String, OrderDeliveryGroup>();
        for(B2B_Subscriptions__c sub : subscriptions) {
            OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod();
            orderDeliveryMethod.Name = sub.B2B_Shipping_Method__c;
            orderDeliveryMethod.CurrencyIsoCode = sub.CurrencyIsoCode;
            orderDeliveryMethod.ReferenceNumber = sub.Id;
            deliveryMethods.add(orderDeliveryMethod);
        }

        if(deliveryMethods != null && deliveryMethods.size() > 0) {
            insert deliveryMethods;
        }

        for(OrderDeliveryMethod method : deliveryMethods) {
            deliveryMethodMap.put(method.ReferenceNumber, method);
        }

        for(B2B_Subscriptions__c sub : subscriptions) {
            Order order = mapParams.get(sub.Id);

            OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DesiredDeliveryDate = Date.today(),
                DeliverToName = 'Subscription OrderDeliveryGroup',
                DeliverToStreet = order.ShippingStreet,
                DeliverToCity = order.ShippingCity,
                DeliverToState = order.ShippingState,
                DeliverToPostalCode = order.ShippingPostalCode,
                DeliverToCountry = order.ShippingCountry,
                Description = sub.Id,
                OrderDeliveryMethodId = deliveryMethodMap.get(sub.Id).Id,
                OrderId = order.Id
            );
            OrderDeliveryGroupsToInsert.add(orderDeliveryGroup);
        }

        if(OrderDeliveryGroupsToInsert != null && OrderDeliveryGroupsToInsert.size() > 0) {
            insert OrderDeliveryGroupsToInsert;
        }

        for(OrderDeliveryGroup orderDeliveryGroup : OrderDeliveryGroupsToInsert) {
            subToODGMap.put(orderDeliveryGroup.Description, orderDeliveryGroup);
        }
        return subToODGMap;
    }

    /**
     * @description       : Fetches order details for the given order IDs.
     * @param orderIds    : The list of order IDs to fetch details for.
     * @return            : List of Order records with details.
     */
    public static List<Order> getOrderDetails(List<Id> orderIds) {
        return [
            SELECT
                Id, TotalAmount, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, ShippingCity, 
                B2B_Subscriptions__c, B2B_Subscriptions__r.B2B_Shipping_Method__c, CurrencyIsoCode, AccountId,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, OrderNumber,
                GrandTotalAmount, B2B_Subscriptions__r.B2B_Contact__r.StripeCustomerId__c, B2B_Subscriptions__r.B2B_Payment_Method__c,
                B2B_Subscriptions__r.B2B_Stripe_Payment_Intent__c , B2B_Subscriptions__r.B2B_Stripe_Payment_Method__c,
                B2B_Subscriptions__r.OwnerId, Payment_Intent__c, Name, 
                B2B_Subscriptions__r.B2B_Special_Instruction__c, B2B_Subscriptions__r.B2B_Shipping_Provider__c, 
                B2B_Subscriptions__r.B2B_Shipping_Provider_Account_Number__c, B2B_Subscriptions__r.B2B_Po_Number__c,
                (SELECT Id, OrderId, Quantity, UnitPrice, Type, Product2Id, TotalPrice, OrderDeliveryGroupId FROM OrderItems)
            FROM 
            Order
            WHERE 
            Id IN :orderIds
        ];
    }

    // Method to fetch Order Delivery Group for a given Order Id
    public static OrderDeliveryGroup getOrderDeliveryGroup(Id orderId) {
        List<OrderDeliveryGroup> odgList = [
            SELECT Id, DeliverToState, DeliverToCity, DeliverToCountry, DeliverToStreet, DeliverToName, DeliverToPostalCode 
            FROM OrderDeliveryGroup 
            WHERE OrderId = :orderId
            LIMIT 1
        ];
        return odgList != null && !odgList.isEmpty() ? odgList[0] : null;
    }

    public static void updateSubscriptions(List<B2B_Subscriptions__c> subscriptions, String renewStatus) {
        List<B2B_Subscriptions__c> subscriptionsToUpdate = new List<B2B_Subscriptions__c>();

        for(B2B_Subscriptions__c sub : subscriptions) {
            sub.B2B_Renew_Status__c = renewStatus;
            subscriptionsToUpdate.add(sub);
        }

        if (subscriptionsToUpdate != null && subscriptionsToUpdate.size() > 0) {
            update subscriptionsToUpdate;
        }
    }

    public static void createContentDocLinkToOrder( List<B2B_Subscriptions__c> subscriptions, List<Order> ordersToInsert ){
        Set<Id> subIds = new Set<Id>();
        for(B2B_Subscriptions__c sub : subscriptions) {
            subIds.add(sub.Id);
        }

        Map<Id,ContentDocumentLink> subsIdToDocLinkMap = getContentDocumentLink( subIds );
        List<ContentDocumentLink> contentDocLinksToInsert = new List<ContentDocumentLink>();
        for ( Order ord : ordersToInsert ) {
            //only for PO payment method
            if ( ord.B2B_Subscriptions__r.B2B_Payment_Method__c != null && ord.B2B_Subscriptions__r.B2B_Payment_Method__c == 'PO' && subsIdToDocLinkMap.containsKey( ord.B2B_Subscriptions__c ) ) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = subsIdToDocLinkMap.get(ord.B2B_Subscriptions__c).ContentDocumentId;
                cdl.LinkedEntityId = ord.Id;
                cdl.Visibility = 'AllUsers';
                contentDocLinksToInsert.add(cdl);
            }
        }

        if (contentDocLinksToInsert != null && contentDocLinksToInsert.size() > 0) {
            insert contentDocLinksToInsert;
        }
    }

    public static Map<Id,ContentDocumentLink> getContentDocumentLink( Set<Id> subIds ) {
        Map<Id,ContentDocumentLink> subsToDocLinkMap = new Map<Id,ContentDocumentLink>();
        List<ContentDocumentLink> contentDocLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :subIds];

        if (contentDocLinks != null && contentDocLinks.size() > 0) {
            for( ContentDocumentLink cdl : contentDocLinks ) {
                subsToDocLinkMap.put(cdl.LinkedEntityId, cdl);
            }
            return subsToDocLinkMap;
        } else {
        }
        return subsToDocLinkMap;
    }

    public static void createContentDocLinkToOrderSummary( Id orderSumId, Order order ){
        Set<Id> subIds = new Set<Id>();
        subIds.add(order.B2B_Subscriptions__c);
        Map<Id,ContentDocumentLink> subsIdToDocLinkMap = getContentDocumentLink( subIds );
        List<ContentDocumentLink> contentDocLinksToInsert = new List<ContentDocumentLink>();
        if ( order.B2B_Subscriptions__r.B2B_Payment_Method__c != null && order.B2B_Subscriptions__r.B2B_Payment_Method__c == 'PO' && subsIdToDocLinkMap.containsKey( order.B2B_Subscriptions__c ) ) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = subsIdToDocLinkMap.get(order.B2B_Subscriptions__c).ContentDocumentId;
            cdl.LinkedEntityId = orderSumId;
            cdl.Visibility = 'AllUsers';
            contentDocLinksToInsert.add(cdl);
        }

        if (contentDocLinksToInsert != null && contentDocLinksToInsert.size() > 0) {
            insert contentDocLinksToInsert;
        }
    }

    public static void logSubscriptionException(List<Id> subIds, String expMsg, String stackTrace, String className) {
        List<Custom_Exception__c> exceptionsToInsert = new List<Custom_Exception__c>();    

        for(Id sub : subIds) {
            Custom_Exception__c exc = new Custom_Exception__c();
            exc.Name = 'Subscription Order Exceptions';
            exc.Stack_Trace__c = stackTrace;
            exc.Exception_Messages__c = expMsg;
            exc.Exception_Type__c = 'Subscription Order Renewal';
            exc.Class_Name__c = className;
            exc.B2B_Subscriptions__c = sub;
            exceptionsToInsert.add(exc);
        }

        if (exceptionsToInsert != null && exceptionsToInsert.size() > 0) {
            insert exceptionsToInsert;
        }        
    }

    public static WebStore getWebstore() {
        List<WebStore> webstores = new List<WebStore>();
        if(Test.isRunningTest()){
         	webstores = [SELECT Id, Name FROM WebStore];
        }else{
         	webstores = [SELECT Id, Name FROM WebStore WHERE Name = :System.Label.B2B_PerkinElmer];   
        }
        WebStore store = webstores[0];
        return store;
    }

    public static void cancelSubscriptions(List<B2B_Subscriptions__c> subscriptions) {
        List<B2B_Subscriptions__c> subscriptionsToUpdate = new List<B2B_Subscriptions__c>();

        for(B2B_Subscriptions__c sub : subscriptions) {
            sub.B2B_Status__c = 'Cancelled';
            subscriptionsToUpdate.add(sub);
        }

        if (subscriptionsToUpdate != null && subscriptionsToUpdate.size() > 0) {
            update subscriptionsToUpdate;
        }
    }
}
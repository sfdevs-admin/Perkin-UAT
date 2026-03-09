/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 02-27-2026
 * @last modified by  : Suhail Ahmed T 
**/
public with sharing class B2B_SubscriptionTaxQueueable implements Queueable, Database.AllowsCallouts {
    private final String className = 'B2B_SubscriptionTaxQueueable';
    private Id orderId;
    private Id subscriptionId;

    public B2B_SubscriptionTaxQueueable(Id orderId, Id subscriptionId) {
        this.orderId = orderId;
        this.subscriptionId = subscriptionId;
    }

    public void execute(QueueableContext context) {
        try {
            List<Order> orderList = B2B_SubscriptionOrderHelper.getOrderDetails(new List<Id>{orderId});
            if (orderList != null && orderList.size() > 0) {
                Order order = orderList[0];
                OrderDeliveryGroup orderDeliveryGroup = B2B_SubscriptionOrderHelper.getOrderDeliveryGroup(order.Id); 

                // Check if DeliverToState is null and throw exception if so
                if(!Test.isRunningTest()) {
                    if (orderDeliveryGroup == null || String.isBlank(orderDeliveryGroup.DeliverToState)) {
                        throw new CalloutException('State is missing in the shipping address. Please update the address and try again.');
                    }
                }
                
                if (isExternalTaxApplicable(order.CurrencyIsoCode)) {
                    Boolean isTaxExempt = B2BMetadataService.isAccountTaxExempt(
                        new Map<String, Object>{
                            'accountId' => order.AccountId,
                            'stateCode' => orderDeliveryGroup.DeliverToState
                        }
                    );
                    if (!isTaxExempt) {
                        HttpResponse response = B2B_SubscriptionStripeTaxHelper.calculateTaxes(order, order.OrderItems);
                        System.debug('Stripe Tax Response for Order ' + orderId + ': ' + response.getBody());

                        B2BStripeTaxResponseWrapper taxResponse = (B2BStripeTaxResponseWrapper) JSON.deserialize(
                            response.getBody(),
                            B2BStripeTaxResponseWrapper.class
                        );

                        System.debug('taxResponse::: ' + taxResponse);

                        // create order item tax line items from stripe response
                        createOrderItemTaxLinesFromStripe(taxResponse, order.OrderItems);
                    }
                } else {
                    // Fallback: apply flat tax (if not exempt or not external tax applicable)
                    applyFlatTax(order, order.OrderItems);
                }           

                ID jobID = System.enqueueJob(new B2B_SubscriptionPaymentQueueable(orderId, subscriptionId));
            }
            // Optionally: parse and store tax details here
        } catch (Exception e) {
            B2B_SubscriptionOrderHelper.logSubscriptionException(new List<Id>{subscriptionId}, e.getMessage(), e.getStackTraceString(), className);
            System.debug('Failed tax calculation for order ' + orderId + ': ' + e.getMessage());
        }
    }

    private Boolean isExternalTaxApplicable(String currencyCode) {
        return currencyCode == 'USD' || currencyCode == 'CAD';
    }

    private static void createOrderItemTaxLinesFromStripe(
        B2BStripeTaxResponseWrapper taxWrapper,
        List<OrderItem> orderItems
    ) {
        Map<String, OrderItem> orderItemById = new Map<String, OrderItem>();
        for (OrderItem oi : orderItems) {
            orderItemById.put(oi.Id, oi);
        }

        Map<String, B2BStripeTaxResponseWrapper.LineItemData> taxLineItems = taxWrapper.getLineItemsByReference();
        String estimatedRate = taxWrapper.getEstimatedTaxRate();
        List<OrderItemTaxLineItem> taxLineItemsToInsert = new List<OrderItemTaxLineItem>();

        // 1. Tax for product order items
        for (String orderItemId : taxLineItems.keySet()) {
            B2BStripeTaxResponseWrapper.LineItemData lineTaxData = taxLineItems.get(orderItemId);
            OrderItem oi = orderItemById.get(orderItemId);
            if (oi == null) continue;

            OrderItemTaxLineItem taxLine = new OrderItemTaxLineItem();
            taxLine.OrderItemId = oi.Id;
            taxLine.TaxEffectiveDate = Date.today(); // Use current date or extract if available
            taxLine.Type = 'Estimated';
            taxLine.Name = 'sales_tax';
            taxLine.Rate = String.isNotBlank(estimatedRate) ? Decimal.valueOf(estimatedRate) : 0;
            taxLine.Amount = Decimal.valueOf(lineTaxData.amount_tax) / 100;

            taxLineItemsToInsert.add(taxLine);
        }

        // 2. Tax for shipping (delivery charge) item
        if (taxWrapper.shipping_cost != null && taxWrapper.shipping_cost.amount_tax != null && taxWrapper.shipping_cost.amount_tax > 0) {
            for (OrderItem oi : orderItems) {
                if (oi.Type == 'Delivery Charge') {
                    OrderItemTaxLineItem shippingTax = new OrderItemTaxLineItem();
                    shippingTax.OrderItemId = oi.Id;
                    shippingTax.TaxEffectiveDate = Date.today();
                    shippingTax.Type = 'Estimated';
                    shippingTax.Name = 'shipping_tax';
                    shippingTax.Rate = Decimal.valueOf(estimatedRate);
                    shippingTax.Amount = Decimal.valueOf(taxWrapper.shipping_cost.amount_tax) / 100;

                    taxLineItemsToInsert.add(shippingTax);
                    break; // only one delivery item expected
                }
            }
        }

        if (!taxLineItemsToInsert.isEmpty()) {
            insert taxLineItemsToInsert;
            System.debug('Inserted OrderItemTaxLineItem records: ' + taxLineItemsToInsert.size());
        }
    }
	
    @TestVisible
    private static void applyFlatTax(Order ord, List<OrderItem> orderItems) {
        String countryCode = ord.ShippingCountry;

        if (String.isBlank(countryCode)) {
            // Log or throw depending on context
            System.debug('Flat tax failed: Missing shipping country.');
            throw new CalloutException('Shipping country is required to apply flat tax.');
        }

        B2B_Country_Tax_Config__mdt countryTaxConfig = B2BMetadataService.getFlatTaxRateByCountryCode(
            ord.CurrencyIsoCode,
            countryCode
        );

        if (countryTaxConfig == null || countryTaxConfig.SAP_Goods_Tax__c == null) {
            System.debug('No flat tax config found for country: ' + countryCode);
            return;
        }

        Decimal flatTaxRate = Decimal.valueOf(countryTaxConfig.SAP_Goods_Tax__c);

        if (flatTaxRate > 0) {
            applyFlatTaxToOrderItems(orderItems, flatTaxRate);
        }
    }

    @TestVisible
    private static void applyFlatTaxToOrderItems(List<OrderItem> orderItems, Decimal flatTaxRate) {
        List<OrderItemTaxLineItem> taxLineItemsToInsert = new List<OrderItemTaxLineItem>();

        for (OrderItem item : orderItems) {
            Decimal itemSubtotal = item.TotalPrice;

            if (itemSubtotal == null) {
                continue;
            }

            Decimal taxAmount = ((itemSubtotal * flatTaxRate) / 100).setScale(2, RoundingMode.HALF_UP);

            OrderItemTaxLineItem taxLine = new OrderItemTaxLineItem();
            taxLine.OrderItemId = item.Id;
            taxLine.TaxEffectiveDate = Date.today();
            taxLine.Type = 'Estimated'; 
            taxLine.Name = 'flat_tax';  
            taxLine.Rate = flatTaxRate;
            taxLine.Amount = taxAmount;

            taxLineItemsToInsert.add(taxLine);
        }

        if (!taxLineItemsToInsert.isEmpty()) {
            insert taxLineItemsToInsert;
            System.debug('Inserted flat tax line items: ' + taxLineItemsToInsert.size());
        }
    }
}
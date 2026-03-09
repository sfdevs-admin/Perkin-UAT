/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 08-13-2025
 * @last modified by  : Gaurav Setia
**/
public with sharing class B2B_SubscriptionPaymentQueueable implements Queueable, Database.AllowsCallouts {
    private final String className = 'B2B_SubscriptionPaymentQueueable';
    private Id orderId;
    private Id subscriptionId;

    public B2B_SubscriptionPaymentQueueable(Id orderId, Id subscriptionId) {
        this.orderId = orderId;
        this.subscriptionId = subscriptionId;
    }

    public void execute(QueueableContext context) {
        try {
            List<Order> orderList = B2B_SubscriptionOrderHelper.getOrderDetails(new List<Id>{orderId});

            if(orderList != null &&orderList.size() > 0) {
                Order order = orderList[0];
                B2B_Subscriptions__c sub = new B2B_Subscriptions__c();
                sub.Id = order.B2B_Subscriptions__c;

                if(order.B2B_Subscriptions__r.B2B_Payment_Method__c != null && order.B2B_Subscriptions__r.B2B_Payment_Method__c != 'PO') {
                    Map<String,Object> mapParams = new Map<String,Object>();
                    mapParams.put('amount', order.GrandTotalAmount);
                    mapParams.put('currencyCode', order.CurrencyIsoCode);
                    mapParams.put('customerId', order.B2B_Subscriptions__r.B2B_Contact__r.StripeCustomerId__c);
                    mapParams.put('paymentMethod', order.B2B_Subscriptions__r.B2B_Stripe_Payment_Method__c);
                    mapParams.put('paymentIntent', order.B2B_Subscriptions__r.B2B_Stripe_Payment_Intent__c);
                    mapParams.put('orderId', order.Id);
                    mapParams.put('subscriptionId', order.B2B_Subscriptions__c);
                    mapParams.put('billingStreet', order.BillingStreet);
                    mapParams.put('billingCity', order.BillingCity);
                    mapParams.put('billingState', order.BillingState);
                    mapParams.put('billingPostalCode', order.BillingPostalCode);
                    mapParams.put('billingCountry', order.BillingCountry);
                    
                    B2BStripeWrapper.PaymentIntent intent = B2BStripeService.createPaymentIntentByMethod(mapParams);

                    if(order.B2B_Subscriptions__r.B2B_Stripe_Payment_Method__c == null) {
                        sub.B2B_Stripe_Payment_Method__c = intent.payment_method;
                    }
                } else {
                    //Todo for po
                }
                B2B_SubscriptionOrderHelper.updateSubscriptions(new List<B2B_Subscriptions__c> {sub}, 'Step 4: Process Payment');
                
                Id orderSumId = activateOrderCreateOrderSummaries(order);
                if(orderSumId != null) {
                    updateOrderSummaryFields(orderSumId, order);
                    addPaymentRecords(orderSumId, order);
                }

                B2B_SubscriptionOrderHelper.updateSubscriptions(new List<B2B_Subscriptions__c> {sub}, 'Step 5: Subscription Renewed');
            }
        }
        catch (Exception ex) {
            B2B_SubscriptionOrderHelper.logSubscriptionException(new List<Id>{subscriptionId}, ex.getMessage(), ex.getStackTraceString(), className);
            System.debug('Error in B2B_SubscriptionPaymentQueueable: ' + ex.getMessage());
        }
    }

    /**
     * @description       : Creates order summaries for the processed orders.
     * @param order      : The order record to create summary for.
     */
    private Id activateOrderCreateOrderSummaries(Order order) {
        
        order.Status = 'Activated'; 
        update order;

        // Create Order Summary
        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = order.Id; //replace this recordId with an appropriate value.
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor;
        if(Test.isRunningTest()) {
           osor = new ConnectApi.OrderSummaryOutputRepresentation();
        } else {
           osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
        }
        
        System.debug('Order Summary created with ID: ' + osor.orderSummaryId);
        return osor.orderSummaryId;
    }

    /**
     * @description       : Updates order summary fields.
     * @param orderSumId : The ID of the order summary to update.
     */
    @TestVisible
    private void updateOrderSummaryFields(Id orderSumId, Order order) {
       OrderSummary orderSummary = new OrderSummary();
        orderSummary.Id = orderSumId;
        orderSummary.OrderNumber = Order.Name + ' - ' + Order.OrderNumber;
        if(!Test.isRunningTest()) {
            update orderSummary;
        }

        B2B_SubscriptionOrderHelper.createContentDocLinkToOrderSummary( orderSumId, order );
    }

    /**
     * @description       : Adds payment records to the order summary.
     * @param orderSumId  : The ID of the order summary to add payment records to.
     */
    @TestVisible
    private void addPaymentRecords(Id orderSumId, Order order) {
        PaymentAuthorization paymentAuth = new PaymentAuthorization();
        paymentAuth.OrderPaymentSummaryId = createOrderPaymentSummary(orderSumId, order);
        paymentAuth.AccountId = order.AccountId;
        paymentAuth.CurrencyIsoCode = order.CurrencyIsoCode;
        paymentAuth.EffectiveDate = Date.today();
        paymentAuth.GatewayDate = Date.today();
        paymentAuth.GatewayAuthCode = order.B2B_Subscriptions__r.B2B_Stripe_Payment_Intent__c;
        paymentAuth.GatewayRefDetails = order.B2B_Subscriptions__r.B2B_Payment_Method__c;
        paymentAuth.GatewayRefNumber = order.B2B_Subscriptions__r.B2B_Payment_Method__c;
        paymentAuth.GatewayResultCodeDescription = order.B2B_Subscriptions__r.B2B_Payment_Method__c;
        paymentAuth.GatewayResultCode = 'success';
        paymentAuth.Status = 'Processed';
        paymentAuth.SfResultCode = 'Success';
        paymentAuth.ProcessingMode = 'External';
        paymentAuth.PaymentGatewayId = getPaymentGateway()?.Id;
        paymentAuth.PaymentGroupId = createPaymentGroup(order);
        paymentAuth.PaymentMethodId = createAlternatePaymentMethod(order);
        paymentAuth.Amount = order.GrandTotalAmount;

        if(!Test.isRunningTest()) {
            insert paymentAuth;     
        }                         
    }

    private PaymentGateway getPaymentGateway() {
        List<PaymentGateway> gateways = [SELECT Id FROM PaymentGateway];
        if (gateways != null && gateways.size() > 0) {
            return gateways[0];
        }
        return null; // Handle case where no PaymentGateway records exist
    }

    private Id createOrderPaymentSummary(Id orderSumId, Order order) {
        OrderPaymentSummary orderpaymentSummary = new OrderPaymentSummary();
        orderpaymentSummary.orderSummaryId = orderSumId;
        orderpaymentSummary.LastPaymentGatewayMessage = order.B2B_Subscriptions__r.B2B_Payment_Method__c;
        orderpaymentSummary.CurrencyIsoCode = order.CurrencyIsoCode;
        orderpaymentSummary.type = 'External';
        orderpaymentSummary.method = 'Subcription OPS';
        
        if(!Test.isRunningTest()) {
            insert orderpaymentSummary;
        }
        return orderpaymentSummary.Id;
    }

    private Id createPaymentGroup(Order order) {
        PaymentGroup paymentGroup = new PaymentGroup();
        paymentGroup.CurrencyIsoCode = order.CurrencyIsoCode;
        paymentGroup.SourceObjectId = order.Id;

        if(!Test.isRunningTest()) {
            insert paymentGroup; 
        }
        return paymentGroup.Id;
    }

    private Id createAlternatePaymentMethod(Order order) {
        AlternativePaymentMethod altPaymentMethod = new AlternativePaymentMethod();
        altPaymentMethod.GatewayToken = order.B2B_Subscriptions__r.B2B_Stripe_Payment_Intent__c;
        altPaymentMethod.OwnerId = order.B2B_Subscriptions__r.OwnerId;
        altPaymentMethod.PaymentMethodCity = order.ShippingCity;
        altPaymentMethod.PaymentMethodCountry = order.ShippingCountry;
        altPaymentMethod.PaymentMethodPostalCode = order.ShippingPostalCode;
        altPaymentMethod.PaymentMethodState = order.ShippingState;
        altPaymentMethod.PaymentMethodStreet = order.ShippingStreet;
        altPaymentMethod.ProcessingMode = 'External';
        altPaymentMethod.Status = 'InActive';
        altPaymentMethod.Type = 'Subscription';
        altPaymentMethod.PaymentGatewayId = getPaymentGateway()?.Id;
        altPaymentMethod.IsAutoPayEnabled = false;

        if(!Test.isRunningTest()) {
            insert altPaymentMethod; 
        }
        return altPaymentMethod.Id;
    }


}
public class B2B_SubscriptionWrapper {

    @AuraEnabled public Id Id { get; set; }
    @AuraEnabled public String subscriptionName { get; set; }
    @AuraEnabled public String subscriptionDescription { get; set; }
    @AuraEnabled public Id subscriptionAccountId { get; set; }
    @AuraEnabled public String subscriptionStatus { get; set; }
    @AuraEnabled public String subscriptionBillingFrequency { get; set; }
    @AuraEnabled public String subscriptionShippingMethod { get; set; }
    @AuraEnabled public String subscriptionPaymentMethod { get; set; }
    @AuraEnabled public String subscriptionNextBillingDate { get; set; }

    @AuraEnabled public List<SubscriptionItemWrapper> items { get; set; }

    public B2B_SubscriptionWrapper() {
        items = new List<SubscriptionItemWrapper>();
    }

    public class SubscriptionItemWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String sku { get; set; }
    }
}
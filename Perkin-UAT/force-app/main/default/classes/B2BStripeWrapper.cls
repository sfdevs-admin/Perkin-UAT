public with sharing class B2BStripeWrapper {

    public virtual class B2BStripeError {
        @AuraEnabled
        public StripeError error;
    }

    public class StripeError {
        public String type;
        public String message;
    }

    public class StripeCustomers extends B2BStripeError {
        public List<StripeCustomer> data;
    }

    public class StripeCustomer extends B2BStripeError {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String name;
    }

    public class CheckoutSession extends B2BStripeError {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String customer;
        @AuraEnabled
        public String mode;
        @AuraEnabled
        public Decimal amount_total;
        @AuraEnabled
        public String payment_intent;
        @AuraEnabled
        public String payment_link;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String payment_status;
        @AuraEnabled
        public String CustomerDetails;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public String success_url;
        @AuraEnabled
        public String checkout_currency;
        @AuraEnabled
        public Metadata metadata;
    }

    public class Metadata {
        public String sf_id;
        public String cart_item_id;

    }

    public class CustomerDetails extends B2BStripeError {
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String phone;
    }


    public class StripeProduct extends B2BStripeError {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String default_price;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String unit_label;
    }

    public class ValidateSession extends B2BStripeError {
        @AuraEnabled
        public Boolean isSessionValid;
        @AuraEnabled
        public String paymentIntent;
        @AuraEnabled
        public String paymentMethodType;
    }

    public class PaymentIntent extends B2BStripeError {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String payment_method;
        @AuraEnabled
        public List<String> payment_method_types;
    }

    public class Coupon extends B2BStripeError {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Decimal amount_off;
        @AuraEnabled
        public String duration;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Boolean valid;
    }
}
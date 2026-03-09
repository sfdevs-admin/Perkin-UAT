/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 08-09-2025
 * @last modified by  : Gaurav Setia
**/
public with sharing class B2BStripeService {
    private static final String POST_METHOD = 'POST';
    private static final String GET_METHOD = 'GET';

    public class B2BStripeException extends Exception {
    }

    public static B2BStripeWrapper.StripeCustomer createStripeCustomer(String contactId, String billingEmail) {
        Contact contact = B2BStripeServiceHelper.getContactById(contactId);
        HttpResponse response = new HttpResponse();
        String endPoint = 'v1/customers';
        String requestBody = 'email=' + billingEmail + '&name=' + contact.Name;
        response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.StripeCustomer result = (B2BStripeWrapper.StripeCustomer) JSON.deserialize(response.getBody(), B2BStripeWrapper.StripeCustomer.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.StripeCustomer getStripeCustomerByEmail(String billingEmail) {
        
        String endPoint = 'v1/customers/search';
        String requestBody = 'query=email:' + '"' + billingEmail + '"';

        HttpResponse response = new HttpResponse();
        response = makeCalloutToStripe(endPoint, GET_METHOD, requestBody, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.StripeCustomers stripeCustomers = (B2BStripeWrapper.StripeCustomers) JSON.deserialize(response.getBody(), B2BStripeWrapper.StripeCustomers.class);
        B2BStripeWrapper.StripeCustomer stripeCustomer = new B2BStripeWrapper.StripeCustomer();
        if (stripeCustomers.data != null && !stripeCustomers.data.isEmpty()) {
            stripeCustomer = stripeCustomers.data[0];
        }

        if (response.getStatusCode() != 200 && String.isNotBlank(stripeCustomers.error.message)) {
            throw new B2BStripeException(stripeCustomers.error.type + ': ' + stripeCustomers.error.message);
        } else {
            return stripeCustomer;
        }
    }

    public static B2BStripeWrapper.CheckoutSession getCheckoutSession(String checkoutSessionId) {
        HttpResponse response = new HttpResponse();
        String endPoint = 'v1/checkout/sessions/' + checkoutSessionId;
        response = makeCalloutToStripe(endPoint, GET_METHOD, '', 'application/x-www-form-urlencoded');

        B2BStripeWrapper.CheckoutSession result = (B2BStripeWrapper.CheckoutSession) JSON.deserialize(response.getBody(), B2BStripeWrapper.CheckoutSession.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.CheckoutSession createCheckoutSession(String customerId, String webCartId, String href) {
        System.debug('CREATE CHECKOUT SESSION');

        String endPoint = 'v1/checkout/sessions';
        HttpResponse response = new HttpResponse();
        String requestString = B2BStripeServiceHelper.createCheckoutRequestString(customerId, webCartId, href);

        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.CheckoutSession result = (B2BStripeWrapper.CheckoutSession) JSON.deserialize(response.getBody(), B2BStripeWrapper.CheckoutSession.class);
        System.debug('CREATE CHECKOUT SESSION RESULT === '  +result);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }

    }

    public static HttpResponse makeCalloutToStripe(String endPoint, String requestMethod, String requestBody, String contentType) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:StripeCredential/' + endPoint);
        req.setMethod(requestMethod);
        req.setHeader('Content-Type', contentType);
        req.setBody(requestBody);

        return http.send(req);
    }

    public static B2BStripeWrapper.PaymentIntent createPaymentIntentByMethod(Map<String,Object> mapParams) {

        if(mapParams != null && mapParams.containsKey('customerId') && mapParams.get('customerId') != null &&
            mapParams.containsKey('paymentIntent') && mapParams.get('paymentIntent') != null &&
            mapParams.containsKey('amount') && mapParams.get('amount') != null &&
            mapParams.containsKey('currencyCode') && mapParams.get('currencyCode') != null)
        {
            String customerId = (String) mapParams.get('customerId');
            String paymentIntent = (String) mapParams.get('paymentIntent');
            String paymentMethod = mapParams.containsKey('paymentMethod') ? (String) mapParams.get('paymentMethod') : null;
            Decimal amount = (Decimal) mapParams.get('amount');
            String currencyCode = (String) mapParams.get('currencyCode');
        
            if(paymentMethod == null && paymentIntent != null && paymentIntent.startsWith('pi_')) {
                B2BStripeWrapper.PaymentIntent intent = retrievePaymentIntent(paymentIntent);
                paymentMethod = intent.payment_method;
            }
            amount = amount * 100; // As Stripe expects amount in cents

            String endPoint = 'v1/payment_intents';
            String requestBody = 'amount=' + String.valueOf(Integer.valueOf(amount)) + '&currency=' + currencyCode + '&customer=' + customerId + '&payment_method=' + paymentMethod + '&off_session=true&confirm=true';
            requestBody += '&' + B2BStripeServiceHelper.createPaymentIntentRequestString(mapParams);
            System.debug('requestBody ==  ' + requestBody);

            HttpResponse response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');
            
            System.debug(response.getBody());
            B2BStripeWrapper.PaymentIntent result = (B2BStripeWrapper.PaymentIntent) JSON.deserialize(response.getBody(), B2BStripeWrapper.PaymentIntent.class);
            if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
                throw new B2BStripeException(result.error.type + ': ' + result.error.message);
            } else {
                return result;
            }
        }
        throw new B2BStripeException('Invalid/Missing parameters for creating Payment Intent');
    }

    public static B2BStripeWrapper.PaymentIntent retrievePaymentIntent(String paymentIntentId) {
        //pi_3PHKELDuoNhH1Sre2OxY3Au2
        String endPoint = 'v1/payment_intents/' + paymentIntentId;
        String requestBody = '';
        HttpResponse response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');
        
        B2BStripeWrapper.PaymentIntent result = (B2BStripeWrapper.PaymentIntent) JSON.deserialize(response.getBody(), B2BStripeWrapper.PaymentIntent.class);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.Coupon createCoupon(Integer discountedAmount, String currencyCode) {
        System.debug('CREATE COUPON');

        String endPoint = 'v1/coupons';
        HttpResponse response = new HttpResponse();
        String requestString = 'amount_off=' + discountedAmount + '&currency=' + currencyCode + '&duration=once&name=DISCOUNT';

        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.Coupon result = (B2BStripeWrapper.Coupon) JSON.deserialize(response.getBody(), B2BStripeWrapper.Coupon.class);
        System.debug('CREATE COUPON RESULT === '  +result);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }
}
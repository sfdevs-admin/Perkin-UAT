@isTest
public class B2BStripeHttpCalloutMock implements HttpCalloutMock {
    Long dt = DateTime.now().addDays(30).getTime() / 1000 ;

    public String calloutType { get; set; }
    public Integer statusCode { get; set; }
    public Boolean useCustomRespond { get; set; }

    public B2BStripeHttpCalloutMock(String calloutType, Integer statusCode, Boolean useCustomRespond) {
        this.statusCode = statusCode;
        this.calloutType = calloutType;
        this.useCustomRespond = useCustomRespond;
    }


    public HTTPResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        String responseBody = '';
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(statusCode);


        if (useCustomRespond) {
            switch on calloutType {

                when 'stripeCustomer' {
                    responseBody = statusCode == 200 ? '{"id": "1234567890", "name" : "Test Customer", "email" : "customer@test.com"}' :
                            '{"error" : {"message" : "Stripe Customer Error"}}';
                }

                when 'stripeCustomerGet' {
                    responseBody = statusCode == 200 ? '{"data": [{"id": "1234567890", "name" : "Test Customer", "email" : "customer@test.com"}]}' :
                            '{"error" : {"message" : "Get Stripe Customer Error"}}' ;
                }

                when 'checkoutSession' {
                    responseBody = statusCode == 200 ? '{"id": "ses01234567890", "customer": "cus_0123456789", "status": "open", "url": "https://success.com"}' :
                            '{"error" : {"message" : "Checkout Session Error"}}';
                }

                when 'invoice' {
                    responseBody = statusCode == 200 ? '{"id": "1234567890", "customer" : "cus01234567890", "paid" : true}' :
                            '{"error" : {"message" : "Invoice Error"}}' ;
                }

                when 'invoiceItem' {
                    responseBody = statusCode == 200 ? '{"id": "1234567890", "customer" : "cus01234567890", "quantity" : 2, "amount" : 100}' :
                            '{"error" : {"message" : "Invoice Item Error"}}' ;
                }

                when 'searchProducts' {
                    responseBody = statusCode == 200 ? '{"data": [' +
                            '{"id": "prod_123456789",  "name": "First Stripe Product", "metadata": {"cart_item_id": "ci_123456789","sf_id": "sf_id867585"}},' +
                            '{"id": "prod_973284669",  "name": "Second Stripe Product", "metadata": {"cart_item_id": "ci_12345546","sf_id": "sf_id867345"}}' +
                            ']}' : '{"error" : {"message" : "Search Products Error"}}' ;
                }

                when 'paymentIntent' {
                    responseBody = statusCode == 200 ? '{"id": "pi_13451Sre2OxY3Au2", "amount": "12", "amount_received": "12", "latest_charge": "latest",  "status":"open", "payment_method_types": ["card"]}' :
                            '{"error" : {"message" : "Payment Intent Error"}}';
                }
                
                when 'coupon' {
                    responseBody = statusCode == 200 ? '{"id": "1234567890", "amount_off": "10", "currency":"usd", "duration": "once", "name": "Test Coupon", "valid": true}' :
                            '{"error" : {"message" : "Coupon Error"}}';
                }
            }

        } else {
            if (request.getEndpoint().contains('v1/products/search')) {
                responseBody = '{"data": [' +
                        '{"id": "prod_123456789",  "name": "First Stripe Product", "metadata": {"cart_item_id": "ci_123456789","sf_id": "sf_id867585"}},' +
                        '{"id": "prod_973284669",  "name": "Second Stripe Product", "metadata": {"cart_item_id": "ci_12345546","sf_id": "sf_id867345"}}' +
                        ']}' ;
            }
        }


        response.setBody(responseBody);

        return response;
    }
}
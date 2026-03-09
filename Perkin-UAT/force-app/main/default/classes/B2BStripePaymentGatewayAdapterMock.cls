@isTest
global class B2BStripePaymentGatewayAdapterMock implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"amount": 10000}, {"paymentMethod": {"alternativePaymentMethod": {"gatewayToken": "testPayment"}}}');

        return res;
    }
}
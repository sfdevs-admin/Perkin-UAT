@isTest
global class B2BStripePaymentGatewayAdapterTest {
    
    @isTest
    static void testProcessRequest() {
        Test.startTest();
        commercepayments.PostAuthorizationRequest request = new commercepayments.PostAuthorizationRequest(10000);

        commercepayments.AlternativePaymentMethodRequest alternativePaymentMethodRequest = new commercepayments.AlternativePaymentMethodRequest('testPayment');

        request.paymentMethod = new commercepayments.PostAuthApiPaymentMethodRequest(alternativePaymentMethodRequest);
        Map<String, String> paymentData = new Map<String, String>();
        paymentData.put('paymentMethod', 'card');
        request.additionalData =paymentData;
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(request, commercepayments.RequestType.PostAuth);

        Test.setMock(HttpCalloutMock.class, new B2BStripePaymentGatewayAdapterMock());

        B2BStripePaymentGatewayAdapter adapter = new B2BStripePaymentGatewayAdapter();
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

    @isTest
    static void testProcessRequest_Exception() {
        Test.startTest();
        commercepayments.PostAuthorizationRequest request = new commercepayments.PostAuthorizationRequest(10000);

        commercepayments.AlternativePaymentMethodRequest alternativePaymentMethodRequest = new commercepayments.AlternativePaymentMethodRequest('testPayment');

        request.paymentMethod = new commercepayments.PostAuthApiPaymentMethodRequest(alternativePaymentMethodRequest);
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(request, commercepayments.RequestType.PostAuth);

        Test.setMock(HttpCalloutMock.class, new B2BStripePaymentGatewayAdapterMock());

        B2BStripePaymentGatewayAdapter adapter = new B2BStripePaymentGatewayAdapter();
        adapter.throwException= true;
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }
}
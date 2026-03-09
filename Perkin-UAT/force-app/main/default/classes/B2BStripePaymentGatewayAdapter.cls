global class B2BStripePaymentGatewayAdapter implements commercepayments.PaymentGatewayAdapter {

    @TestVisible
    private Boolean throwException = false;

    // Salesforce Result Codes
    private static final commercepayments.SalesforceResultCodeInfo RC_SUCCESS = toCodeInfo(commercepayments.SalesforceResultCode.Success);
    private static final commercepayments.SalesforceResultCodeInfo RC_DECLINE = toCodeInfo(commercepayments.SalesforceResultCode.Decline);

    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.PaymentGatewayRequest paymentRequest = gatewayContext.getPaymentRequest();
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        System.debug('requestType: ' + requestType);
        
        commercepayments.GatewayResponse response;
        try {
            if(Test.isRunningTest() && throwException) {
                throw new CalloutException('Exception for Test Coverage');
            }

            if (requestType == commercepayments.RequestType.PostAuth) {
                System.debug('PostAuth PaymentGatewayRequest: ' + paymentRequest);
                response = createPostAuthResponse( (commercepayments.PostAuthorizationRequest) paymentRequest);
            }
            return response;
        } 
        catch (Exception e) {
            B2BLogCustomException.LogException(e, 'B2BStripePaymentGatewayAdapter', 'processRequest');
            return new commercepayments.GatewayErrorResponse('400', e.getMessage());
        }
    }

    /* 
    * postAuth is used to process an authorization that was created on the Client Side.
    * to create the necessary Payment records and associate them with the Order we need to retrieve
    * the Authorization info from Stripe using the Request Transaction Id then populate and return
    * a commercepayments.PostAuthorizationResponse object. The platform will do the rest of the heavy lifting
    */
    private commercepayments.GatewayResponse createPostAuthResponse(commercepayments.PostAuthorizationRequest postAuthRequest) {
        
        System.debug('createPostAuthResponse entry: ' + postAuthRequest);
        commercepayments.PostAuthApiPaymentMethodRequest apiPaymentMethod =(commercepayments.PostAuthApiPaymentMethodRequest) postAuthRequest.paymentMethod;
        commercepayments.AlternativePaymentMethodRequest altPaymentMethod= (commercepayments.AlternativePaymentMethodRequest) apiPaymentMethod.alternativePaymentMethod;

        // LWC passes in the Stripe RequestId as the gatewayToken
        String gatewayToken = (String) altPaymentMethod.gatewayToken;
        System.debug('gatewayToken: ' + gatewayToken);

        String paymentMethodName = postAuthRequest.additionalData.get('paymentMethod');
        String paymentMethod = getPaymentMethodLabel(paymentMethodName);
        System.debug('paymentMethod: ' + paymentMethod);


        commercepayments.PostAuthorizationResponse postAuthResponse = new commercepayments.PostAuthorizationResponse();
        try {

            // populate the commercepayments.PostAuthorizationResponse
            postAuthResponse.setGatewayAuthCode(gatewayToken);
            postAuthResponse.setGatewayResultCode('success');
            postAuthResponse.setSalesforceResultCodeInfo(RC_SUCCESS);
            postAuthResponse.setAmount(postAuthRequest.amount);
            postAuthResponse.setGatewayDate(system.now());

            postAuthResponse.setGatewayResultCodeDescription(paymentMethod);
            postAuthResponse.setGatewayReferenceNumber(paymentMethod);
            postAuthResponse.setGatewayMessage(paymentMethod);
            postAuthResponse.setGatewayReferenceDetails(paymentMethod);
        } 
        catch(Exception e) {
            B2BLogCustomException.LogException(e, 'B2BStripePaymentGatewayAdapter', 'createPostAuthResponse');
            return new commercepayments.GatewayErrorResponse('500', e.getMessage());
        }

        System.debug('createPostAuthResponse exit: ' + postAuthResponse);
        return postAuthResponse;
    }
    
    private static commercepayments.SalesforceResultCodeInfo toCodeInfo(commercepayments.SalesforceResultCode code) {
        return new commercepayments.SalesforceResultCodeInfo(code);
    }
    
    private static String getPaymentMethodLabel(String paymentMethodName) {
        String paymentMethod;
        if(paymentMethodName != null) {
            switch on paymentMethodName {
                when 'us_bank_account' {
                    paymentMethod = Label.B2B_Payment_Method_US_Bank_Account;
                }
                when 'acss_debit' {
                    paymentMethod = Label.B2B_Payment_Method_CA_Pre_Auth_Debit;
                }
                when 'sepa_debit' {
                    paymentMethod = Label.B2B_Payment_Method_EU_SEPA_Debit;
                }
                when else {
                    paymentMethod = paymentMethodName;
                }
            }
        }
        return paymentMethod;
    }
}
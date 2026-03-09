public with sharing class B2BTaxService {
  private static final String CLASS_NAME = 'B2BTaxService';
  private static final Map<String, Object> TAX_CONFIG = B2BMetadataService.getTaxConfiguration(CLASS_NAME);
  
  private static final String ENDPOINT = (String) TAX_CONFIG.get('EndPoint');
  private static final String HTTP_METHOD = (String) TAX_CONFIG.get('HTTPMethod');
  private static final String NAMED_CREDENTIAL = (String) TAX_CONFIG.get('NamedCredential');
  private static final String SECRET_KEY = (String) TAX_CONFIG.get('HmacKey');
  private static final String USERNAME = (String) TAX_CONFIG.get('Username');
  private static final String PASSWORD = (String) TAX_CONFIG.get('Password');
  private static final String HMAC_ALGORITHM = (String) TAX_CONFIG.get('HmacAlgorithm');
  private static final String ORGID_CA = (String) TAX_CONFIG.get('OrgIdCA');
  private static final String ORGID_US = (String) TAX_CONFIG.get('OrgIdUS');
  private static final String DATE_HEADER = Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
  
  public static Map<String, B2BTaxResponseWrapper.LineResult> getResponseFromExternalService(CartExtension.Cart cart, Map<String, CartExtension.CartItem> cartItemById) {
    try {
      String authorizationValue = B2BHMACGeneratorHandler.generateAuthorizationValue(
        TAX_CONFIG, DATE_HEADER
        );
      
      String requestBody = buildTaxRequest(cart, cartItemById);
      HttpResponse response = sendHttpRequest(requestBody, authorizationValue);
      
      LogEntryController.log(requestBody, response, 'Sovos Tax API', cart.getId());
      
      if (response.getStatusCode() == 200) {
        return parseResponseJson(response.getBody());
      } else {
        throw new CalloutException('Failed to get tax data. Status Code: ' + response.getStatusCode());
      }
    } catch (Exception ex) {
      B2BLogCustomException.LogException(ex, '', '');
      throw new CalloutException('Error retrieving tax data: ' + ex.getMessage());
    }
  }
  
  private static HttpResponse sendHttpRequest(String requestBody, String authorizationValue) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(B2BConstants.CALLOUT + NAMED_CREDENTIAL + '/' + ENDPOINT);
    request.setMethod(HTTP_METHOD);
    request.setHeader(B2BConstants.HTTP_HEADER_CONTENT_TYPE, B2BConstants.HTTP_HEADER_CONTENT_TYPE_JSON);
    request.setHeader(B2BConstants.HTTP_HEADER_DATE, DATE_HEADER.trim());
    request.setHeader(B2BConstants.HTTP_HEADER_AUTHORIZATION, authorizationValue);
    request.setHeader(B2BConstants.HTTP_HEADER_HMAC_ALGORITHM, HMAC_ALGORITHM);
    request.setBody(requestBody);
    
    // System.debug('Request Payload: ' + requestBody);
    return new Http().send(request);
  }
  
  private static String buildTaxRequest(CartExtension.Cart cart, Map<String, CartExtension.CartItem> cartItemById) {
    Id accountId = cart.getAccountId();
    String customerVendorCode = B2BMetadataService.getSAPCustomerNumber(accountId);
    String orgID;
    if (cart.getCurrencyIsoCode() == 'USD') {
      orgID = ORGID_US;
    } else if (cart.getCurrencyIsoCode() == 'CAD') {
      orgID = ORGID_CA;
    }
    B2BTaxRequestWrapper requestPayload = new B2BTaxRequestWrapper();
    requestPayload.usrname = USERNAME;
    requestPayload.pswrd = PASSWORD;
    requestPayload.isAudit = false;
    requestPayload.trnSrc = 'SOVOS';
    requestPayload.tdmRequired = true;
    requestPayload.trnDocNum = 'TESTDEBIT';
    requestPayload.txCalcTp = 1;
    requestPayload.currn = cart.getCurrencyIsoCode();
    requestPayload.docDt = DATE_HEADER;
    requestPayload.tdcReqrd = true;
    requestPayload.custmsDutTrfAmt = 0.0;
    requestPayload.dlvrAmt = cart.getTotalChargeAmount();
    requestPayload.dlvrInsAmt = 0.0;
    requestPayload.rsltLvl = 5;
    requestPayload.lines = new List<B2BTaxRequestWrapper.LineItem>();
    
    for (CartExtension.CartItem item : cartItemById.values()) {
      B2BTaxRequestWrapper.LineItem lineItem = new B2BTaxRequestWrapper.LineItem();
      // lineItem.grossAmt = item.getTotalLineGrossAmount();
      lineItem.grossAmt = item.getTotalLineAmount();
      lineItem.goodSrvCd = item.getSku();
      lineItem.qnty = Integer.valueOf(item.getQuantity());
      // lineItem.orgCd = 'AES';
      // lineItem.orgCd = 'PECAS0';
      // lineItem.orgCd = 'PEQAS1US0';
      // lineItem.orgCd = 'PEQASUSPR';
      lineItem.orgCd = orgID;
      lineItem.trnTp = 1;
      lineItem.txAmt = item.getTotalLineTaxAmount();
      lineItem.sTCountry = cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getCountry();
      lineItem.sTPstlCd = cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getPostalCode();
      lineItem.sTCity = cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getCity();
      lineItem.sTStateProv = cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getState();
      lineItem.lnItmId = item.getId();
      // lineItem.bTStNameNum = '5810 Helen St ';
      // lineItem.bTTaxID = 'Art Vandelay';
      // lineItem.lOAGeoCd = 10899;
      // lineItem.lORGeoCd = 10899;
      // lineItem.lSPGeoCd = 13566;
      // lineItem.lUGeoCd = 13566;

      // lineItem.custVendCd = '0004014113';
      // lineItem.custVendCd = '0004706949';
      // lineItem.custVendCd = '0004526070';
      // lineItem.custVendCd = '0004504523';
      lineItem.custVendCd = customerVendorCode;
      
      requestPayload.lines.add(lineItem);
    }
    
    return JSON.serialize(requestPayload);
  }
  
  private static Map<String, B2BTaxResponseWrapper.LineResult> parseResponseJson(String jsonResponse) {
    B2BTaxResponseWrapper taxResponse = (B2BTaxResponseWrapper) JSON.deserialize(jsonResponse, B2BTaxResponseWrapper.class);
    Map<String, B2BTaxResponseWrapper.LineResult> taxDataMap = new Map<String, B2BTaxResponseWrapper.LineResult>();
    
    for (B2BTaxResponseWrapper.LineResult lineItem : taxResponse.lnRslts) {
      taxDataMap.put(lineItem.lnId, lineItem);
    }
    
    return taxDataMap;
  }
}
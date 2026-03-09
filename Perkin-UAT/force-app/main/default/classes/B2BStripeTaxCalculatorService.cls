public with sharing class B2BStripeTaxCalculatorService {
  private static final String CLASS_NAME = 'B2BStripeTaxCalculatorService';
  private static final Map<String, Object> TAX_CONFIG = B2BMetadataService.getTaxConfiguration(
    CLASS_NAME
  );

  private static final String ENDPOINT = (String) TAX_CONFIG.get('EndPoint');
  private static final String HTTP_METHOD = (String) TAX_CONFIG.get(
    'HTTPMethod'
  );
  private static final String NAMED_CREDENTIAL = (String) TAX_CONFIG.get(
    'NamedCredential'
  );

  public static B2BStripeTaxResponseWrapper getStripeTax(
    CartExtension.Cart cart,
    Map<String, CartExtension.CartItem> cartItemById
  ) {
    List<String> bodyParams = buildFormEncodedBody(cart, cartItemById);
    String requestBody = String.join(bodyParams, '&');

    HttpResponse res = performStripeTaxCallout(requestBody);

    LogEntryController.log(requestBody, res, 'Stripe Tax API', cart.getId());

    if (res.getStatusCode() != 200) {
      String errorMessage = System.Label.B2B_Stripe_Tax_Failed_Message;

      Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      if (parsedBody.containsKey('error')) {
        Map<String, Object> errorDetails = (Map<String, Object>) parsedBody.get(
          'error'
        );
        if (
          String.valueOf(errorDetails.get('code')) ==
          'customer_tax_location_invalid'
        ) {
          errorMessage = String.valueOf(errorDetails.get('message'));
        }
      }
      createCartValidationError(cart.getId(), errorMessage);
    }

    B2BStripeTaxResponseWrapper taxResponse = (B2BStripeTaxResponseWrapper) JSON.deserialize(
      res.getBody(),
      B2BStripeTaxResponseWrapper.class
    );

    System.debug('taxResponse::: ' + taxResponse);

    // return taxResponse.getLineItemsByReference();
    return taxResponse;
  }

  @future(callout=true)
  public static void createCartValidationError(Id cartId, String errorMessage) {
    CartValidationOutput validationError = new CartValidationOutput(
      CartId = cartId,
      Level = 'Error',
      Message = errorMessage.left(255),
      Name = cartId, // fallback for uniqueness
      RelatedEntityId = cartId,
      Type = 'Taxes'
    );
    insert validationError;
  }

  public static List<String> buildFormEncodedBody(
    CartExtension.Cart cart,
    Map<String, CartExtension.CartItem> cartItemById
  ) {
    List<String> params = new List<String>();

    Set<String> cartItemIds = new Set<String>(cartItemById.keySet());
    Map<String, String> cartItemIdToTaxCode = new Map<String, String>();

    String shippigTaxCode;
    List<Product2> shippingProducts = [
      SELECT Id, B2B_Entity_Use_Code__c
      FROM Product2
      WHERE Name = :System.Label.B2B_Shipping_Product_Name
      LIMIT 1
    ];
    if (shippingProducts.size() > 0) {
      shippigTaxCode = shippingProducts[0].B2B_Entity_Use_Code__c;
    }
    for (CartItem ci : [
      SELECT Id, Product2.B2B_Entity_Use_Code__c
      FROM CartItem
      WHERE Id IN :cartItemIds
    ]) {
      cartItemIdToTaxCode.put(ci.Id, ci.Product2.B2B_Entity_Use_Code__c);
    }

    // Static fields
    params.add('currency=' + cart.getCurrencyIsoCode());
    params.add('expand[0]=line_items');

    params.add(
      'customer_details[address][country]=' +
      cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getCountry()
    );
    params.add(
      'customer_details[address][postal_code]=' +
      cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getPostalCode()
    );
    params.add(
      'customer_details[address][line1]=' +
      cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getStreet()
    ); //'2000 Auburn Drive');
    params.add(
      'customer_details[address][state]=' +
      cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getState()
    );
    params.add(
      'customer_details[address][city]=' +
      cart.getCartDeliveryGroups().get(0).getDeliverToAddress()?.getCity()
    );

    params.add('customer_details[address_source]=shipping');

    // Line items with indexing
    Integer index = 0;
    Boolean shippingCostAdded = false;

    for (String itemId : cartItemById.keySet()) {
      CartExtension.CartItem item = cartItemById.get(itemId);

      if (item.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
        Decimal itemAmount = item.getTotalLineAmount();
        Long amountInCents = (itemAmount * 100).setScale(0).longValue();

        params.add(
          'line_items[' + index + '][amount]=' + String.valueOf(amountInCents)
        );
        params.add('line_items[' + index + '][reference]=' + itemId);
        params.add(
          'line_items[' +
            index +
            '][quantity]=' +
            Integer.valueOf(item.getQuantity())
        );

        String taxCode = cartItemIdToTaxCode.containsKey(itemId)
          ? cartItemIdToTaxCode.get(itemId)
          : '';
        params.add('line_items[' + index + '][tax_code]=' + taxCode);

        index++;
      } else if (
        item.getType() == CartExtension.SalesItemTypeEnum.CHARGE &&
        !shippingCostAdded
      ) {
        // Add single shipping cost fields
        Decimal shippingAmount = item.getTotalLineAmount();
        Long shippingAmountInCents = (shippingAmount * 100)
          .setScale(0)
          .longValue();

        params.add(
          'shipping_cost[amount]=' + String.valueOf(shippingAmountInCents)
        );
        params.add('shipping_cost[tax_code]=' + shippigTaxCode);
        shippingCostAdded = true;
      }
    }

    return params;
  }

  private static HttpResponse performStripeTaxCallout(String requestBody) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(B2BConstants.CALLOUT + NAMED_CREDENTIAL + '/' + ENDPOINT);
    req.setMethod(HTTP_METHOD);
    req.setHeader(
      B2BConstants.HTTP_HEADER_CONTENT_TYPE,
      B2BConstants.HTTP_HEADER_CONTENT_TYPE_ENCODED
    );
    req.setBody(requestBody);

    Http http = new Http();
    return http.send(req);
  }
}
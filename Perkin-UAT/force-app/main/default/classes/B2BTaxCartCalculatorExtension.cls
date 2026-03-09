/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 02-26-2026
 * @last modified by  : Suhail Ahmed T 
**/
// This tax calculator extension class makes a call to an external service to retrieve tax
// information for a cart item and its adjustments and saves it to a cart data transfer object
// (DTO). For a tax calculator extension to be processed by the checkout flow, you must implement the
// CartExtension.TaxCartCalculator class.
@SuppressWarnings('PMD')
public class B2BTaxCartCalculatorExtension extends CartExtension.TaxCartCalculator {
  public virtual override void calculate(
    CartExtension.CartCalculateCalculatorRequest request
  ) {
    CartExtension.Cart cart;
    try {
      cart = request.getCart();
       //system.debug('cart delievery group '+cart.getCartDeliveryGroups()[0].getDeliverToAddress());
      Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>();
      Map<String, CartExtension.CartItem> shippingItemById = new Map<String, CartExtension.CartItem>();

      CartExtension.CartValidationOutputList cartValidationOutputList = cleanUpPreviousTaxes(cart);
      existingCartTaxesCleanUp(cart, cartItemById, shippingItemById);

      //Get the State code from shipping address
      String stateCode = !cart.getCartDeliveryGroups().isEmpty() &&
          cart.getCartDeliveryGroups().get(0)?.getDeliverToAddress()?.getState() != null ?
          cart.getCartDeliveryGroups().get(0)?.getDeliverToAddress()?.getState() :
      null;
      system.debug('stateCode '+stateCode);

      //if state = null then thow error
      if(stateCode == null){
        CartExtension.CartValidationOutput cvo = showCheckoutError('State is missing in the shipping address. Please update the address and try again.');
        cartValidationOutputList.add(cvo);
      }

      if (isExternalTaxApplicable(cart.getCurrencyIsoCode())) {
        //SOVOS tax API callout is paused for some time
        // applyExternalTax(cart, cartItemById);

        Boolean isTaxExempt = B2BMetadataService.isAccountTaxExempt(
          new Map<String, Object>{
            'accountId' => cart.getAccountId(),
            'stateCode' => stateCode
          }
        );

        //Stripe tax calculation API
        if (!isTaxExempt) {
            applyStripeTax(cart, cartItemById);
        }
      } else {
          applyFlatTax(cart, cartItemById);
      }
    } catch (Exception e) {
        system.debug('exception :: ' + e);
        B2BStripeTaxCalculatorService.createCartValidationError(
            cart.getId(),
            System.Label.B2B_Stripe_Tax_Failed_Message
        );
        throw new CalloutException('There was a problem with the request.');
    }
      return;
  }

  private Boolean isExternalTaxApplicable(String currencyCode) {
    return currencyCode == 'USD' || currencyCode == 'CAD';
  }

  /** 
   * //SOVOS API CALLOUT
  private void applyExternalTax(
    CartExtension.Cart cart,
  Map<String, CartExtension.CartItem> cartItemById
  ) {
    Map<String, B2BTaxResponseWrapper.LineResult> taxData = B2BTaxService.getResponseFromExternalService(
      cart,
    cartItemById
      );
    applyTaxesToCart(cartItemById, taxData);
  }
  */

  private void applyFlatTax(
      CartExtension.Cart cart,
      Map<String, CartExtension.CartItem> cartItemById
  ) {
      //Get the country code from shipping address
      String countryCode = !cart.getCartDeliveryGroups().isEmpty() &&
          cart.getCartDeliveryGroups().get(0)?.getDeliverToAddress()?.getCountry() != null ?
          cart.getCartDeliveryGroups().get(0)?.getDeliverToAddress()?.getCountry() :
      null;
      system.debug('countryCode '+countryCode);
      //if country = null then thow error
      if(countryCode == null){
          
          B2BStripeTaxCalculatorService.createCartValidationError(
              cart.getId(),
              System.Label.B2B_Stripe_Tax_Failed_Message+' - '+Label.TaxCountryErrorMsg
          );
          throw new CalloutException('There was a problem with the request.');
      }
      
      //if country code then fetch tax rate from metadata
      B2B_Country_Tax_Config__mdt countryTaxConfig = B2BMetadataService.getFlatTaxRateByCountryCode(
          cart.getCurrencyIsoCode(),countryCode
      );
      Decimal flatTaxRate = Decimal.valueOf(countryTaxConfig.SAP_Goods_Tax__c);

    if (flatTaxRate > 0) {
      applyFlatTaxToCart(cart, cartItemById, flatTaxRate);
    }
  }

  private static CartExtension.CartValidationOutputList cleanUpPreviousTaxes(CartExtension.Cart cart) {
    CartExtension.CartValidationOutputList cartValidationOutputCollection = cart.getCartValidationOutputs();
    for (Integer i = (cartValidationOutputCollection.size() - 1); i >= 0; i--) {
      CartExtension.CartValidationOutput cvo = cartValidationOutputCollection.get(
        i
      );
      if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.TAXES) {
        cartValidationOutputCollection.remove(cvo);
      }
    }
    return cartValidationOutputCollection;
  }

  private static CartExtension.CartValidationOutput showCheckoutError(String errorMessage){
    CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
        CartExtension.CartValidationOutputTypeEnum.TAXES,
        CartExtension.CartValidationOutputLevelEnum.ERROR
    );
    cvo.setMessage(errorMessage);
    return cvo;
  }

  private void existingCartTaxesCleanUp(
    CartExtension.Cart cart,
    Map<String, CartExtension.CartItem> cartItemById,
    Map<String, CartExtension.CartItem> shippingItemById
  ) {
    // Map cart ID to cart item with type Product.
    CartExtension.CartItemList cartItemCollection = cart.getCartItems();

   
system.debug('cartItemCollection.size()  '+cartItemCollection.size());
    for (Integer i = (cartItemCollection.size() - 1); i >= 0; i--) {
        //Clear existing cart entries
        CartExtension.CartItem cartItem = cartItemCollection.get(i);
        
         if (cartItem.getCartTaxes().size() > 0) {
            cartItem.getCartTaxes().clear();
          }
        cartItemById.put(
          cartItemCollection.get(i).getId(),
          cartItemCollection.get(i)
        );
         // The cartItemCollection contains both products and shipping cart items.
         // Commenting below as Shipping also needs to be taxed
      /*if (
        cartItemCollection.get(i).getType() ==
        CartExtension.SalesItemTypeEnum.PRODUCT
      ) {
        cartItemById.put(
          cartItemCollection.get(i).getId(),
          cartItemCollection.get(i)
        );
      } else if (
        cartItemCollection.get(i).getType() ==
        CartExtension.SalesItemTypeEnum.CHARGE
      ) {
        // Shipping cart items are uniquely identified using delivery group id.
        CartExtension.CartDeliveryGroup deliveryGroup = cartItemCollection.get(
            i
          )
          .getCartDeliveryGroup();
        // shippingItemById.put(deliveryGroup.getId(), cartItemCollection.get(i));

        cartItemById.put(deliveryGroup.getId(), cartItemCollection.get(i));
      }*/
    }
  }

  /** 
  private static void applyTaxesToCart(
    Map<String, CartExtension.CartItem> cartItemById,
  Map<String, B2BTaxResponseWrapper.LineResult> taxDataFromExternalService
  ) {
    // System.debug('taxDataFromExternalService :: ' + taxDataFromExternalService);
    boolean isCvoPresent = false;
    List<CartExtension.CartValidationOutput> cartValidationOutputCollection = new List<CartExtension.CartValidationOutput>();
    
    // Validate if tax details exist for all cart items
    for (String cartItemId : cartItemById.keySet()) {
      if (!taxDataFromExternalService.containsKey(cartItemId)) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
          CartExtension.CartValidationOutputTypeEnum.TAXES,
        CartExtension.CartValidationOutputLevelEnum.INFO
          );
        cvo.setMessage('No tax rates configured for this location.');
        cartValidationOutputCollection.add(cvo);
        isCvoPresent = true;
      }
    }
    if (isCvoPresent) {
      return;
    }
    
    // Apply tax details to cart items
    for (String cartItemId : taxDataFromExternalService.keySet()) {
      if (String.isNotBlank(cartItemId)) {
        B2BTaxResponseWrapper.LineResult taxDetails = taxDataFromExternalService.get(
          cartItemId
          );
        CartExtension.CartItem cartItem = cartItemById.get(cartItemId);
        
        boolean isCartItemModified = false;
        if (
        cartItem.getUnitAdjustedPrice() != null 
        ) {
          if (!cartItem.getCartTaxes().isEmpty()) {
            cartItem.getCartTaxes().clear();
          }
          for (
            Integer i = cartItem.getCartItemPriceAdjustments().size() - 1;
          i >= 0;
          i--
          ) {
            CartExtension.CartTaxList cipaTaxes = cartItem.getCartItemPriceAdjustments()
              .get(i)
              .getCartTaxes();
            if (!cipaTaxes.isEmpty()) {
              cipaTaxes.clear();
            }
          }
          isCartItemModified = true;
        }
        
        if (
          cartItem.getCartTaxes() == null ||
          cartItem.getCartTaxes().isEmpty() ||
          isCartItemModified
        ) {
          cartItem.setGrossUnitPrice(taxDetails.grossAmt);
          
          CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
          for (
            B2BTaxResponseWrapper.JurisdictionResult jurisdiction : taxDetails.jurRslts
          ) {
            CartExtension.CartTax cartTax = new CartExtension.CartTax(
              CartExtension.TaxTypeEnum.ESTIMATED,
            jurisdiction.txAmt,
            jurisdiction.txName
              );
            cartTax.setTaxRate(String.valueOf(jurisdiction.txRate));
            cartTaxCollection.add(cartTax);
          }
        }
      }
    }
  }
  */

  // Apply flat tax to cart items
  private void applyFlatTaxToCart(
    CartExtension.Cart cart,
    Map<String, CartExtension.CartItem> cartItemById,
    Decimal flatTaxRate
  ) {
    CartExtension.CartItemList cartItemCollection = cart.getCartItems();
    Integer size = cartItemCollection.size();

    for (Integer i = 0; i < size; i++) {
      CartExtension.CartItem cartItem = cartItemCollection.get(i);
      String cartItemId = cartItem.getId();

      CartExtension.CartItem item = cartItemById.get(cartItemId);
      if (item == null) {
        continue;
      }

      Decimal itemSubtotal = item.getTotalLineAmount(); //item.getUnitAdjustedPrice();  // Get item price
      if (itemSubtotal == null) {
        continue;
      }

      Decimal taxAmount = ((itemSubtotal * flatTaxRate) / 100).setScale(2, RoundingMode.HALF_UP);

      CartExtension.CartTaxList cartTaxCollection = item.getCartTaxes();
      CartExtension.CartTax cartTax = new CartExtension.CartTax(
        CartExtension.TaxTypeEnum.ESTIMATED,
        taxAmount,
        'Flat Tax'
      );
      cartTax.setTaxRate(String.valueOf(flatTaxRate));
      cartTaxCollection.add(cartTax);

      System.debug(
        'Flat Tax Applied: ' + taxAmount + ' for Item: ' + cartItemId
      );
    }
  }

  private void applyStripeTax(
    CartExtension.Cart cart,
    Map<String, CartExtension.CartItem> cartItemById
  ) {
    B2BStripeTaxResponseWrapper taxResponse = B2BStripeTaxCalculatorService.getStripeTax(
      cart,
      cartItemById
    );
    // Pass the taxResponse and the line items map to applyStripeTaxesToCart
    applyStripeTaxesToCart(
      cartItemById,
      taxResponse.getLineItemsByReference(),
      taxResponse
    );
  }

  private static void applyStripeTaxesToCart(
    Map<String, CartExtension.CartItem> cartItemById,
    Map<String, B2BStripeTaxResponseWrapper.LineItemData> taxDataFromExternalService,
    B2BStripeTaxResponseWrapper taxWrapper
  ) {
    // Step 2: Apply taxes for normal (non-shipping) items
    for (String cartItemId : taxDataFromExternalService.keySet()) {
      B2BStripeTaxResponseWrapper.LineItemData taxDetails = taxDataFromExternalService.get(
        cartItemId
      );
      CartExtension.CartItem cartItem = cartItemById.get(cartItemId);

      if (cartItem == null)
        continue;

      cartItem.getCartTaxes().clear();
      CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();

      CartExtension.CartTax cartTax = new CartExtension.CartTax(
        CartExtension.TaxTypeEnum.ESTIMATED,
        Decimal.valueOf(taxDetails.amount_tax) / 100,
        'sales_tax'
      );
      cartTax.setTaxRate(taxWrapper.getEstimatedTaxRate());
      cartTaxCollection.add(cartTax);
    }

    if (taxWrapper.shipping_cost != null) {
      for (CartExtension.CartItem cartItem : cartItemById.values()) {
        if (cartItem.getType() == CartExtension.SalesItemTypeEnum.CHARGE) {
          cartItem.getCartTaxes().clear();
          CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();

          CartExtension.CartTax shippingTax = new CartExtension.CartTax(
            CartExtension.TaxTypeEnum.ESTIMATED,
            Decimal.valueOf(taxWrapper.shipping_cost.amount_tax) / 100,
            'shipping_tax'
          );
          shippingTax.setTaxRate(taxWrapper.getEstimatedTaxRate());
          cartTaxCollection.add(shippingTax);
          break; // only one CHARGE item expected
        }
      }
    }
  }
}
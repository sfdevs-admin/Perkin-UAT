// This class must extend the CartExtension.ShippingCartCalculator class to be processed.
public class B2BCartCalcShipping extends CartExtension.ShippingCartCalculator {

  public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
    CartExtension.Cart cart = request.getCart();
    // Clean up CVO based on Shipping
    CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

    for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
      CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
      if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.SHIPPING) {
        cartValidationOutputList.remove(cvo);
      }
    }

    //Retrieve the currency code & total amount from the WebCart and calculate the 6% of Net Pay
    String currencyCode = cart.getCurrencyIsoCode();
    Decimal totalAmount = cart.getTotalProductAmount();

    // To create the Cart delivery group methods, we need to get the ID of the cart delivery group.
    CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
    if (cartDeliveryGroups.size() == 0) {
      CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
        CartExtension.CartValidationOutputTypeEnum.SHIPPING,
        CartExtension.CartValidationOutputLevelEnum.ERROR
      );
      cvo.setMessage(System.Label.B2B_Cart_Delivery_Groups_Error_Msg);
      cartValidationOutputList.add(cvo);
    } else {
      CartExtension.CartItemList cartItems = cart.getCartItems();
      Integer numberOfUniqueItems = cartItems.size();
      List<Id> productIds = new List<Id>();
      Map<Id, Decimal> productIdToTotalAmount = new Map<Id, Decimal>();
       system.debug('cartItems: '+cartItems);
      for (Integer i = (cartItems.size() - 1); i >= 0; i--) {
        CartExtension.CartItem cartItem = cartItems.get(i);
        if (cartItem.getProduct2Id() != null && cartItem.getQuantity() != null && cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
            productIds.add(cartItem.getProduct2Id());
            productIdToTotalAmount.put(cartItem.getProduct2Id(), cartItem.getTotalAmount());
        }
    }     

      Boolean hasHazardousItem = false;
      Boolean hasNonHazardousItem = false;
      Decimal hazardousProductsTotalAmount = 0;
      Decimal nonHazardousProductsTotalAmount = 0;

      if(productIds.size() > 0){
        List<Product2> products = [SELECT Id, Name, Hazmat__c, B2B_Is_Hazardous__c FROM Product2 WHERE Id IN : productIds];
        if(products.size() > 0){
          for(Product2 product : products){
              if(product.B2B_Is_Hazardous__c == true){  
                  hasHazardousItem = true;
                  hazardousProductsTotalAmount += productIdToTotalAmount.get(product.Id);
              } else {
                  hasNonHazardousItem = true;
                  nonHazardousProductsTotalAmount += productIdToTotalAmount.get(product.Id);
              }
          }
        }
      }
        //if no valid products are present in the cart, throw an error)
      
      CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);
      CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();

      //get the selected shipping address from the cart
      Address address = cartDeliveryGroup.getDeliverToAddress();

      // Clean up the CartDeliveryGroupMethods
      for (Integer j = (cartDeliveryGroupMethods.size() - 1); j >= 0; j--) {
        CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(j);
        cartDeliveryGroupMethods.remove(method);
      }
      // To clear selected Cart Delivery Group Method
      cartDeliveryGroup.setSelectedCartDeliveryGroupMethod(null);

      // Get the Shipping Product
      List<Product2> shippingProducts = [SELECT Id FROM Product2 WHERE Name =:System.Label.B2B_Shipping_Product_Name LIMIT 1];
      if(shippingProducts.size() == 0) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                CartExtension.CartValidationOutputLevelEnum.ERROR );
        cvo.setMessage(System.Label.B2B_Shipping_Product_Error_Msg);
        cartValidationOutputList.add(cvo);
      } else {
        String shippingProduct = Id.valueOf(shippingProducts[0].Id);
        // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
        List<B2B_Shipping_Methods__mdt> returnedShippingMethods = getShippingMethodMetadataRecords(address, hasHazardousItem, hasNonHazardousItem);
        system.debug('returned shipping methods: '+returnedShippingMethods);
        if(returnedShippingMethods.size() == 0){
          CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                CartExtension.CartValidationOutputLevelEnum.ERROR );
          cvo.setMessage(System.Label.B2B_Shipping_Method_Error_Msg);
          cartValidationOutputList.add(cvo);
        }
        else{
          B2B_Shipping_Methods__mdt Freight_Standard_Ground = null;
          B2B_Shipping_Methods__mdt Freight_Overnight = null;
          Boolean createCDGM = true;
          Boolean isNonHazItemBelowThreshold = true;
          for(Integer i = 0; i < (returnedShippingMethods.size()); i++){

            if(returnedShippingMethods[i].Country_Code__c == 'US' || returnedShippingMethods[i].Country_Code__c == 'CA') {
              if(hasHazardousItem && hasNonHazardousItem) {
                if(returnedShippingMethods[i].isHazardous__c) {
                  totalAmount = hazardousProductsTotalAmount;
                  createCDGM = true;
                } else {
                  isNonHazItemBelowThreshold = nonHazardousProductsTotalAmount < returnedShippingMethods[i].Threshold_Value__c;
                  createCDGM = false;
                  if(returnedShippingMethods[i].MasterLabel == 'Freight Standard Ground') {
                    Freight_Standard_Ground = returnedShippingMethods[i];
                  } else if(returnedShippingMethods[i].MasterLabel == 'Freight Overnight') {
                      Freight_Overnight = returnedShippingMethods[i];
                  }
                }
              }
            }

            if(createCDGM) {

              Map<String,Object> mapParams = new Map<String,Object>();
              mapParams.put('currentShippingMetadataRecord', returnedShippingMethods[i]);
              mapParams.put('totalAmount', totalAmount);
              mapParams.put('belowThreshold', totalAmount < returnedShippingMethods[i].Threshold_Value__c);
              mapParams.put('shippingProduct', shippingProduct);
              mapParams.put('isNonHazItemBelowThreshold', isNonHazItemBelowThreshold);
              
              if(returnedShippingMethods[i].MasterLabel == 'Freight Hazardous') {
                 mapParams.put('nonHazFreight', Freight_Standard_Ground);
              } else if(returnedShippingMethods[i].MasterLabel == 'Freight Hazardous Overnight') {
                  mapParams.put('nonHazFreight', Freight_Overnight);
              }
           
              CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod = populateCartDeliveryGroupMethodWithShippingOptions(mapParams);
              cartDeliveryGroupMethods.add(cartDeliveryGroupMethod);

              //set default shipping methdod with lowest shipping fees except Freight Collect 
              if (cartDeliveryGroupMethods.isEmpty()) return;

              CartExtension.CartDeliveryGroupMethod defaultMethod = null;
              Decimal minFee = null;

              // iterate
              for (Integer j = 0; j < cartDeliveryGroupMethods.size(); j++) {
                  CartExtension.CartDeliveryGroupMethod m = cartDeliveryGroupMethods.get(j);
                  
                  String nameLower = (m.getName() != null) ? m.getName().toLowerCase() : '';

                  // Skip Freight Collect entries
                  if (nameLower.contains('freight collect')) {
                      continue;
                  }

                  Decimal fee = m.getShippingFee();
                  if (minFee == null || fee < minFee) {
                      minFee = fee;
                      defaultMethod = m;
                  }
              }

              // set the default method if one was found
              if (defaultMethod != null) {
                  cartDeliveryGroup.setSelectedCartDeliveryGroupMethod(defaultMethod);
              }
            }
          }
        }
      }
    }
  }

  private static List<B2B_Shipping_Methods__mdt> getShippingMethodMetadataRecords(Address address, Boolean hasHazardousItem, Boolean hasNonHazardousItem){
    List<B2B_Shipping_Methods__mdt> shippingMethods = new List<B2B_Shipping_Methods__mdt>();
    
    if(address.Country == 'US' || address.Country == 'CA'){
      String countryCode = address.Country;
      String query = 'SELECT Id, MasterLabel, DeveloperName, Below_Threshold_Shipping_Charge__c, Above_Threshold_Shipping_Charge__c, Country_Code__c, Currency_Code__c, Percent_Calculation__c, Percent_of_Net_Cost__c, Threshold_Value__c, Maximum_Shipping_Charge__c, isActive__c, isHazardous__c'+
                     ' FROM B2B_Shipping_Methods__mdt' +
                     ' WHERE Country_Code__c=:countryCode' +
                     ' AND isActive__c=true';

      if(hasHazardousItem && !hasNonHazardousItem) {
        query += ' AND isHazardous__c=true ';
      } 
      else if(!hasHazardousItem && hasNonHazardousItem) {
        query += ' AND isHazardous__c=false';
      }
      query += ' ORDER By MasterLabel Desc';
      
      shippingMethods = Database.query(query);
    }
    else{
      shippingMethods = [
        SELECT Id, MasterLabel, DeveloperName, Below_Threshold_Shipping_Charge__c, Above_Threshold_Shipping_Charge__c, Country_Code__c, Currency_Code__c, Percent_Calculation__c, Percent_of_Net_Cost__c, Threshold_Value__c, Maximum_Shipping_Charge__c, isActive__c, isHazardous__c 
        FROM B2B_Shipping_Methods__mdt 
        WHERE Country_Code__c=:address.Country 
        AND isActive__c=true
        ORDER By MasterLabel Desc];
    }
    System.debug('##Shipping Methods: '+ shippingMethods);
    return shippingMethods; 
  }

  private static CartExtension.CartDeliveryGroupMethod populateCartDeliveryGroupMethodWithShippingOptions(Map<String,Object> mapParams){

    Decimal sixPercentofTotalAmount = 0;
    Decimal totalAmount = (Decimal) mapParams.get('totalAmount');
    String shippingProduct = (String) mapParams.get('shippingProduct');
    B2B_Shipping_Methods__mdt currentShippingMetadataRecord = (B2B_Shipping_Methods__mdt) mapParams.get('currentShippingMetadataRecord');
    Decimal percentOfNetCost = currentShippingMetadataRecord.Percent_of_Net_Cost__c;
    Decimal maximumShippingCharge = currentShippingMetadataRecord.Maximum_Shipping_Charge__c;
    Decimal belowThresholdShippingCharge = currentShippingMetadataRecord.Below_Threshold_Shipping_Charge__c;
    Decimal aboveThresholdShippingCharge = currentShippingMetadataRecord.Above_Threshold_Shipping_Charge__c;
    String shippingMethodName = currentShippingMetadataRecord.MasterLabel;
    Boolean percentCalculation = currentShippingMetadataRecord.Percent_Calculation__c;
    Decimal percentOfTotalAmount = 0;

    B2B_Shipping_Methods__mdt nonHazFreight = (B2B_Shipping_Methods__mdt) mapParams.get('nonHazFreight');
    Boolean isNonHazItemBelowThreshold = (Boolean) mapParams.get('isNonHazItemBelowThreshold');
    
    if (nonHazFreight != null) {
      if(isNonHazItemBelowThreshold) {
        belowThresholdShippingCharge += nonHazFreight.Below_Threshold_Shipping_Charge__c;
        aboveThresholdShippingCharge += nonHazFreight.Below_Threshold_Shipping_Charge__c;
      }
      else {
        belowThresholdShippingCharge += nonHazFreight.Above_Threshold_Shipping_Charge__c;
        aboveThresholdShippingCharge += nonHazFreight.Above_Threshold_Shipping_Charge__c;
      }
    }

    CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod;
    if(percentCalculation){
      if(percentOfNetCost > 0){
        sixPercentofTotalAmount = totalAmount*(percentOfNetCost/100);
        if(sixPercentofTotalAmount > maximumShippingCharge){
          sixPercentofTotalAmount = maximumShippingCharge;
        }
        sixPercentofTotalAmount = sixPercentofTotalAmount.setScale(2, RoundingMode.HALF_UP);
        cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingMethodName, sixPercentofTotalAmount, shippingProduct);
      }
      else{
        if(mapParams.get('belowThreshold') == true){
          percentOfTotalAmount = totalAmount*(belowThresholdShippingCharge/100);
          if(percentOfTotalAmount > maximumShippingCharge){
            percentOfTotalAmount = maximumShippingCharge;
          }
          percentOfTotalAmount = percentOfTotalAmount.setScale(2, RoundingMode.HALF_UP);
          cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingMethodName, percentOfTotalAmount, shippingProduct);
        }
        else{
          percentOfTotalAmount = totalAmount*(aboveThresholdShippingCharge/100);
          if(percentOfTotalAmount > maximumShippingCharge){
            percentOfTotalAmount = maximumShippingCharge;
          }
          percentOfTotalAmount = percentOfTotalAmount.setScale(2, RoundingMode.HALF_UP);
          cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingMethodName, percentOfTotalAmount, shippingProduct);
        }
      }
    }
    else{
      if(mapParams.get('belowThreshold') == true){
        belowThresholdShippingCharge = belowThresholdShippingCharge.setScale(2, RoundingMode.HALF_UP);
        cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingMethodName, belowThresholdShippingCharge, shippingProduct);
      }
      else{
        aboveThresholdShippingCharge = aboveThresholdShippingCharge.setScale(2, RoundingMode.HALF_UP);
        cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingMethodName, aboveThresholdShippingCharge, shippingProduct);
      }
    }
    return cartDeliveryGroupMethod;    
  }
}
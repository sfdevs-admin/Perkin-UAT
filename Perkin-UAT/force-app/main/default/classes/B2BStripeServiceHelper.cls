/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 08-09-2025
 * @last modified by  : Gaurav Setia
**/
public without sharing class B2BStripeServiceHelper {
 
    public static List<String> CART_ITEMS_QUERY_FIELDS = new List<String> {
        'Quantity', 'ListPrice', 'Product2.Name', 'UnitAdjustedPriceWithItemAdj ', 'CurrencyIsoCode', 'Type'
    };

    public static List<String> CART_QUERY_FIELDS = new List<String> {
        'Id', 'Name', 'PONumber', 'TotalTaxAmount', 'CurrencyIsoCode', 'TotalCartLevelAdjAmount'
    };

    public static List<String> CART_DELIVERY_GROUP_FIELDS = new List<String> {
        'DeliverToStreet', 'DeliverToName', 'DeliverToCity', 'DeliverToState', 'DeliverToPostalCode', 'DeliverToCountry'
    };

    //You can use formulas here , but result of the formula should be a string
    // If you need to have Integer or Boolean use TEXT({yourformula}) function
    public static Map<String,String> CART_ITEMS_MAP = new Map<String,String> {
        '[quantity]' => 'TEXT(IF(Quantity = 0, 1, Quantity))',
        '[price_data][currency]' => 'CurrencyIsoCode',
        '[price_data][product_data][name]' => 'Product2.Name'
    };
    
    public static Map<String,String> CART_METADATA_MAP = new Map<String,String> {
        '[SF_Cart_Id]' => 'Id',
        '[SF_Cart_Name]' => 'Name',
        '[PO_Number]' => 'PONumber'
    };

    public static Map<String,String> CART_DELIVERY_GROUP_METADATA_MAP = new Map<String,String> {
        '[DeliverToStreet]' => 'DeliverToStreet',
        '[DeliverToName]' => 'DeliverToName',
        '[DeliverToCity]' => 'DeliverToCity',
        '[DeliverToState]' => 'DeliverToState',
        '[DeliverToPostalCode]' => 'DeliverToPostalCode',
        '[DeliverToCountry]' => 'DeliverToCountry'
    };

    public static String createCheckoutRequestString(String customerId, String webCartId , String href) {
        String checkoutMode = 'payment';
        String result = 'customer=' + customerId + 
        '&success_url=' + href + '?session={CHECKOUT_SESSION_ID}' +
        '&cancel_url=' + href;

        String cartItemsQuery = 'SELECT ' + String.join(CART_ITEMS_QUERY_FIELDS, ',') + ' FROM CartItem WHERE CartId =: webCartId';
        List<CartItem> items = Database.query(cartItemsQuery);

        List<String> params = new List<String>();

        for(Integer index = 0; items.size() > index; index++) {
            CartItem cartItem = items[index];

            String adjustedPrice = (cartItem.Type == 'Product') 
                ? 'TEXT(IF(ISNULL(UnitAdjustedPriceWithItemAdj), 0, ROUND(UnitAdjustedPriceWithItemAdj * 100, 0)))' 
                : 'TEXT(IF(ISNULL(ListPrice), 0, ROUND(ListPrice * 100, 0)))';
            
            CART_ITEMS_MAP.put('[price_data][unit_amount]', adjustedPrice);

            for(String key : CART_ITEMS_MAP.keySet()) {
                String value = getFieldValue((SObject) items[index], CART_ITEMS_MAP.get(key));

                if(key == '[price_data][currency]') {
                    value = value.toLowerCase();
                }

                params.add('line_items[' + index + ']' + key + '=' + value);
            }
        }

        String cartQuery = 'SELECT ' + String.join(CART_QUERY_FIELDS, ',') + ' FROM Webcart WHERE Id =: webCartId';
        WebCart cart = Database.query(cartQuery);

        //Adding Tax Line Item
        Integer totalTaxAmount = Math.round(cart.TotalTaxAmount * 100);
        params.add('line_items[' + items.size() + '][price_data][unit_amount]=' + totalTaxAmount);
        params.add('line_items[' + items.size() + '][price_data][product_data][name]=Tax');
        params.add('line_items[' + items.size() + '][price_data][currency]=' + cart.CurrencyIsoCode.toLowerCase());
        params.add('line_items[' + items.size() + '][quantity]=1');

        //Adding Promotions
        if(cart.TotalCartLevelAdjAmount < 0) {
            Integer totalPromotionAmount = Math.round(cart.TotalCartLevelAdjAmount * (-100));
            B2BStripeWrapper.Coupon coupon = B2BStripeService.createCoupon(totalPromotionAmount, cart.CurrencyIsoCode.toLowerCase());
            params.add('discounts[0][coupon]=' + coupon.id);
        }

        for(String key : CART_METADATA_MAP.keySet()) {
            String value = getFieldValue((SObject) cart, CART_METADATA_MAP.get(key));

            params.add('payment_intent_data[metadata]' + key + '=' + value);
        }
        // params.add('payment_intent_data[setup_future_usage]=on_session');
        params.add('metadata[sf_id]=' + webCartId);


        String deliveryGroupQuery = 'SELECT ' + String.join(CART_DELIVERY_GROUP_FIELDS, ',') + ' FROM CartDeliveryGroup WHERE CartId =: webCartId LIMIT 1';
        List<CartDeliveryGroup> deliveryGroup = Database.query(deliveryGroupQuery);

        if(!deliveryGroup.isEmpty()) {
            for(String key : CART_DELIVERY_GROUP_METADATA_MAP.keySet()) {
                String value = getFieldValue((SObject) deliveryGroup[0], CART_DELIVERY_GROUP_METADATA_MAP.get(key));

                params.add('payment_intent_data[metadata]' + key + '=' + value);
            }
        }

        params.add('&mode=' + checkoutMode);
        // params.add('&payment_intent_data[setup_future_usage]=off_session');

        //Add Payment Methods
        List<String> paymentMethods = getPaymentMethodsByCountry(deliveryGroup[0].DeliverToCountry);
        for (Integer i = 0; i < paymentMethods.size(); i++) {
            params.add('&payment_method_types[' + i + ']=' + paymentMethods[i]);
        }
        
        //Add Payment Method Options (if required)
        List<String> paymentMethodOptions = getPaymentMethodOptionsByCountry(deliveryGroup[0].DeliverToCountry);
        if(paymentMethodOptions != null) {
            params.addAll(paymentMethodOptions);
        }

        //Enabling Stripe Tax
        params.add('&automatic_tax[enabled]=' + Label.B2B_Enable_Stripe_Tax);
        params.add('&customer_update[address]=auto');

        //Add Subscription Check
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('cartId', webCartId);
        mapParams = B2B_SubscriptionHelper.checkForSubscriptionCart(mapParams);
        if(mapParams != null && mapParams.containsKey('hasSubscription') && Boolean.valueOf(mapParams.get('hasSubscription'))) {
            params.add('&payment_intent_data[setup_future_usage]=off_session');
        }

        System.debug(result + String.join(params, '&'));
        return result + '&' + String.join(params, '&');
    }

    public static String createPaymentIntentRequestString(Map<String,Object> mapParams) { 

        List<String> params = new List<String>();
        if(mapParams != null && mapParams.containsKey('orderId') && mapParams.get('orderId') != null
            && mapParams.containsKey('subscriptionId') && mapParams.get('subscriptionId') != null) {
            
            String orderId = (String) mapParams.get('orderId');
            String subId = (String) mapParams.get('subscriptionId');
            String billingStreet = mapParams.containsKey('billingStreet') ? (String) mapParams.get('billingStreet') : null;
            String billingCity = mapParams.containsKey('billingCity') ? (String) mapParams.get('billingCity') : null;
            String billingState = mapParams.containsKey('billingState') ? (String) mapParams.get('billingState') : null;
            String billingPostalCode = mapParams.containsKey('billingPostalCode') ? (String) mapParams.get('billingPostalCode') : null;
            String billingCountry = mapParams.containsKey('billingCountry') ? (String) mapParams.get('billingCountry') : null;  
            
            params.add('metadata[SF_Subscription_Id]=' + subId);
            params.add('metadata[SF_Order_Id]=' + orderId);
            params.add('metadata[BillingStreet]=' + billingStreet);
            params.add('metadata[BillingCity]=' + billingCity);
            params.add('metadata[BillingState]=' + billingState);
            params.add('metadata[BillingPostalCode]=' + billingPostalCode);
            params.add('metadata[BillingCountry]=' + billingCountry);
        }
        return String.join(params, '&');
    }

    public static String getFieldValue(SObject obj, String field) {

        FormulaEval.FormulaInstance evaluator = Formula.builder()
                            .withReturnType(FormulaEval.FormulaReturnType.STRING)
                            .withType(obj.getSObjectType())
                            .withFormula(field)
                            .build();
        String result = String.valueOf(evaluator.evaluate(obj));
        return String.isNotBlank(result) ? EncodingUtil.urlEncode(result, 'UTF-8') : '';
    }

    public static Contact getContactById(String contactId) {
        return [ SELECT Name, Email, StripeCustomerId__c FROM Contact WHERE Id =:contactId];
    }

    // Helper method to fetch payment methods based on locale
    private static List<String> getPaymentMethodsByCountry(String countryCode) {

        //Get Custom Metadata Type
        if(countryCode != null && countryCode != '') {
            List<B2B_Payment_Methods_By_Country__mdt> paymentConfigs = [
                SELECT Payment_Methods__c
                FROM B2B_Payment_Methods_By_Country__mdt 
                WHERE Country_Code__c = :countryCode 
                LIMIT 1
            ];

            if (!paymentConfigs.isEmpty()) {
                String methodsString = paymentConfigs[0].Payment_Methods__c; 
                return methodsString.split(',');
            }
        }

        // Fallback to default payment methods if no config found
        return new List<String>{'card'}; // Default to 'card' only
    }

    // Helper method to fetch payment methods options based on locale
    private static List<String> getPaymentMethodOptionsByCountry(String countryCode) {

        List<String> params = new List<String>();

        if (String.isNotBlank(countryCode)) {
            List<B2B_Payment_Methods_By_Country__mdt> configs = [
                SELECT Payment_Method_Options__c 
                FROM B2B_Payment_Methods_By_Country__mdt 
                WHERE Country_Code__c = :countryCode 
                LIMIT 1
            ];

            if (!configs.isEmpty() && String.isNotBlank(configs[0].Payment_Method_Options__c)) {
                String rawOptions = configs[0].Payment_Method_Options__c;
                List<String> optionLines = rawOptions.split(';');

                for (String line : optionLines) {
                    line = line.trim();
                    if (line.contains('=')) {
                        List<String> keyValue = line.split('=');
                        if (keyValue.size() == 2) {
                            String fullKey = keyValue[0].trim();
                            String value = keyValue[1].trim();

                            List<String> parts = fullKey.split('\\.');
                            String paramKey = '&payment_method_options[' + parts[0] + ']';

                            for (Integer i = 1; i < parts.size(); i++) {
                                paramKey += '[' + parts[i] + ']';
                            }

                            params.add(paramKey + '=' + value);
                        }
                    }
                }
            }
        }

        return params;
    }
}
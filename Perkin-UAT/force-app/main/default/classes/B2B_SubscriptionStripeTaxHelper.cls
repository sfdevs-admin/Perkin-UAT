public with sharing class B2B_SubscriptionStripeTaxHelper {
    private static final String CLASS_NAME = 'B2BStripeTaxCalculatorService';
    private static final Map<String, Object> TAX_CONFIG = B2BMetadataService.getTaxConfiguration(CLASS_NAME);

    private static final String ENDPOINT = (String) TAX_CONFIG.get('EndPoint');
    private static final String HTTP_METHOD = (String) TAX_CONFIG.get('HTTPMethod');
    private static final String NAMED_CREDENTIAL = (String) TAX_CONFIG.get('NamedCredential');

    public static HttpResponse calculateTaxes(Order order, List<OrderItem> orderItems) {
        List<String> params = buildFormEncodedBody(order, orderItems);
        String requestBody = String.join(params, '&');
        return performStripeTaxCallout(requestBody);
    }

    private static List<String> buildFormEncodedBody(Order order, List<OrderItem> orderItems) {
        List<String> params = new List<String>();

        // Get shipping product tax code
        List<Product2> shippingProducts = [
            SELECT B2B_Entity_Use_Code__c
            FROM Product2
            WHERE Name = :System.Label.B2B_Shipping_Product_Name
            LIMIT 1
        ];

        Map<Id, String> productIdToTaxCode = new Map<Id, String>();
        Set<Id> productIds = new Set<Id>();
        for (OrderItem item : orderItems) {
            if (item.Product2Id != null) {
                productIds.add(item.Product2Id);
            }
        }

        for (Product2 p : [
            SELECT Id, B2B_Entity_Use_Code__c
            FROM Product2
            WHERE Id IN :productIds
        ]) {
            productIdToTaxCode.put(p.Id, p.B2B_Entity_Use_Code__c);
        }

        // Static fields
        params.add('currency=' + order.CurrencyIsoCode);
        params.add('expand[0]=line_items');

        // Shipping address
        params.add('customer_details[address][country]=' + order.ShippingCountry);
        params.add('customer_details[address][postal_code]=' + order.ShippingPostalCode);
        params.add('customer_details[address][line1]=' + order.ShippingStreet);
        params.add('customer_details[address][state]=' + order.ShippingState);
        params.add('customer_details[address][city]=' + order.ShippingCity);
        params.add('customer_details[address_source]=shipping');

        Integer index = 0;
        Boolean shippingCostAdded = false;

        for (OrderItem item : orderItems) {
            if (item.Type == 'Order Product') {
                Long amountInCents = (item.UnitPrice * item.Quantity * 100).setScale(0).longValue();
                params.add('line_items[' + index + '][amount]=' + amountInCents);
                params.add('line_items[' + index + '][reference]=' + item.Id);
                params.add('line_items[' + index + '][quantity]=' + Integer.valueOf(item.Quantity));

                String taxCode = productIdToTaxCode.get(item.Product2Id);
                if (taxCode != null) {
                    params.add('line_items[' + index + '][tax_code]=' + taxCode);
                }

                index++;
            } else if (!shippingCostAdded && item.Type == 'Delivery Charge') {
                Long shippingAmountInCents = (item.UnitPrice * 100).setScale(0).longValue();

                String shippingTaxCode = shippingProducts.isEmpty() ? '' : shippingProducts[0].B2B_Entity_Use_Code__c;

                params.add('shipping_cost[amount]=' + shippingAmountInCents);
                params.add('shipping_cost[tax_code]=' + shippingTaxCode);
                shippingCostAdded = true;
            }
        }

        return params;
    }

    private static HttpResponse performStripeTaxCallout(String requestBody) {
        System.debug('##requestBody ::: ' + requestBody);

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
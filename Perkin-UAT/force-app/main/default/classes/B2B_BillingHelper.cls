/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Suhail Ahmed T 
**/
public without sharing class B2B_BillingHelper {
    public static Map<String, Object> getBillingDetailsHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        Map<String, Object> data = new Map<String, Object>();

        try {
            if (mapParams == null || !mapParams.containsKey('orderNumber')) {
                message = System.Label.B2B_Missing_OrderSummary; 
            } else {
                String orderNumber = (String) mapParams.get('orderNumber');

                List<OrderSummary> orderSummaries = [
                    SELECT Id, OrderNumber, BillingCity, BillingCountry, BillingState,
                           BillingStreet, BillingPostalCode, BillingEmailAddress
                    FROM OrderSummary
                    WHERE OrderNumber = :orderNumber
                    // WHERE OrderNumber = :'NOCGE-7OW6I-N2XEO-CNL5S'
                    LIMIT 1
                ];

                if (!orderSummaries.isEmpty()) {
                    OrderSummary orderSummary = orderSummaries[0];

                    data.put('Id', orderSummary.Id);
                    data.put('OrderNumber', orderSummary.OrderNumber);
                    data.put('BillingCity', orderSummary.BillingCity);
                    data.put('BillingCountry', orderSummary.BillingCountry);
                    data.put('BillingState', orderSummary.BillingState);
                    data.put('BillingStreet', orderSummary.BillingStreet);
                    data.put('BillingPostalCode', orderSummary.BillingPostalCode);
                    data.put('BillingEmailAddress', orderSummary.BillingEmailAddress);

                    isSuccess = true;
                    message = System.Label.B2B_Billing_Success;
                } else {
                    message =System.label.B2B_No_OrderSummary_Found;
                }
            }
        } catch (Exception ex) {
            message = 'Error: ' + ex.getMessage();
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        mapParams.put('data', data);

        return mapParams;
    }
}
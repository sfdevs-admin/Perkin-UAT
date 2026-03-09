/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
public inherited sharing class B2B_ShippingHelper {
    
    /** 
     * Fetch the shipping details and get the estimated delivery date.
    **/
    public static Map<String,Object> getShippingDetails(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';

        if(mapParams != null && (mapParams.containsKey('recordId') || mapParams.containsKey('orderRefNumber'))) {
            
            String recordId = mapParams.get('recordId') != null ? (String) mapParams.get('recordId') : null; 
            String orderRefNumber = mapParams.get('orderRefNumber') != null ? (String) mapParams.get('orderRefNumber') : null;

            OrderDeliveryGroupSummary orderDeliveryGroupSummary;
            if(recordId != null) {
               orderDeliveryGroupSummary = getOrderDeliveryGroupSummary(recordId, true);
            } else {
                orderDeliveryGroupSummary = getOrderDeliveryGroupSummary(orderRefNumber, false);
            }
             
            if(orderDeliveryGroupSummary != null) {
                mapParams.put('orderSummaryId', orderDeliveryGroupSummary?.OrderSummaryId);
                mapParams.put('shippingStreet', orderDeliveryGroupSummary?.DeliverToStreet);
                mapParams.put('shippingCity', orderDeliveryGroupSummary?.DeliverToCity);
                mapParams.put('shippingState', orderDeliveryGroupSummary?.DeliverToState);
                mapParams.put('shippingPostalCode', orderDeliveryGroupSummary?.DeliverToPostalCode);
                mapParams.put('shippingCountry', orderDeliveryGroupSummary?.DeliverToCountry);
                mapParams.put('shippingMethod', orderDeliveryGroupSummary?.OrderDeliveryMethod.Name);
                //mapParams.put('shippingCharges', orderDeliveryGroupSummary?.GrandTotalAmount);
                mapParams.put('shippingCharges', orderDeliveryGroupSummary?.TotalLineAmount);
                mapParams.put('currencyCode', orderDeliveryGroupSummary?.CurrencyIsoCode);

                if(orderDeliveryGroupSummary?.OrderSummary?.B2B_Shipping_Estimated_Date__c != null) {
                    mapParams.put('shippingDate', orderDeliveryGroupSummary?.OrderSummary?.B2B_Shipping_Estimated_Date__c);
                    isSuccess = true;
                } else {
                    String sourcingDC = getSourcingDCByCountryAndCurrency(orderDeliveryGroupSummary.CurrencyIsoCode, orderDeliveryGroupSummary.DeliverToCountry);
                    if(sourcingDC != null) {
                        List<String> sourcingDCList = new List<String>();
                        if(sourcingDC.contains(';')) {
                            sourcingDCList.addAll(sourcingDC.split(';'));
                        } else {
                            sourcingDCList.add(sourcingDC);
                        }
                        List<Id> productIds = new List<Id>();
                        for(OrderItemSummary item : orderDeliveryGroupSummary.OrderItemSummaries) {
                            productIds.add(item.Product2Id);
                        }
                        Integer shippingdays = getEstDeliveryDates(sourcingDCList, productIds);
                        Date myDate = Date.today() + shippingdays;
                        String dayString = myDate.format();
                        mapParams.put('shippingDate', dayString);
                        // mapParams.put('shippingDate', Date.today() + shippingdays);
                        isSuccess = true;
                    }
                }
            } else {
                message = System.Label.B2B_OrderSummary_Not_Found;
            }
        } else {
            message = System.Label.B2B_Invalid_Params;
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        return mapParams;
    }

    /** 
     * Fetch the OrderDeliveryGroupSummary record and details.
    **/
    private static OrderDeliveryGroupSummary getOrderDeliveryGroupSummary(String recordIdOrNumber, Boolean hasRecordId) {
        OrderDeliveryGroupSummary orderDeliveryGroupSummary;

        String query = 'SELECT Id, DeliverToStreet, DeliverToCity, DeliverToCountry, DeliverToState, DeliverToPostalCode, OrderSummaryId, ' 
            + 'OrderDeliveryMethod.Name, TotalLineAmount, GrandTotalAmount, CurrencyIsoCode, OrderSummary.B2B_Shipping_Estimated_Date__c, ' 
            + '( ' 
            + 'SELECT Id, Product2Id ' 
            + 'FROM OrderItemSummaries '
            + 'WHERE Type = \'Order Product\' ' 
            + ') ' 
            + 'FROM OrderDeliveryGroupSummary ';

        String whereClause;
        if(hasRecordId) {
            whereClause = 'WHERE OrderSummaryId = :recordIdOrNumber';
        } else {
            whereClause = 'WHERE OrderSummary.OrderNumber = :recordIdOrNumber';
        }
            
        List<OrderDeliveryGroupSummary> OrderDeliveryGroupSummaries = Database.query(query + whereClause);
           
        if(OrderDeliveryGroupSummaries != null && OrderDeliveryGroupSummaries.size() > 0){
            orderDeliveryGroupSummary = OrderDeliveryGroupSummaries[0];
        }
        return orderDeliveryGroupSummary;
    }

    /** 
     * Fetch the sales org by country and currency code.
    **/
    private static String getSourcingDCByCountryAndCurrency(String currencyCode, String countryCode) {
        String sourcingDC = null;

        List<B2B_Country_Selector__mdt> countryList = [
            SELECT 
                Id, Country_Code__c, Currency_Code__c, Sort_Order__c, Sourcing_DC__c
            FROM 
            B2B_Country_Selector__mdt 
            WHERE 
            Currency_Code__c = :currencyCode AND Country_Code__c = :countryCode AND isActive__c = true
            ORDER BY Sort_Order__c ASC 
        ];

        if(countryList != null && countryList.size() > 0){
            sourcingDC = countryList[0].Sourcing_DC__c;
        }
        return sourcingDC;
    }

    /** 
     * Fetch the estimated delivery dates based on the passed in parameters 
     * and returns the max estimated delivery date.
    **/
    private static Integer getEstDeliveryDates(List<String> salesOrgList, List<Id> productIds) {
        Integer estimatedDays = null;

        List<B2B_Product_Shipping__c> productShippingList = [
            SELECT 
            B2B_Estimated_Days__c
            FROM 
            B2B_Product_Shipping__c
            WHERE 
            B2B_Is_Active__c = true
            AND
            B2B_Sourcing_DC__c IN :salesOrgList
            AND 
            B2B_Product__c = :productIds
        ];

        if(productShippingList != null && productShippingList.size() > 0) {
            for(B2B_Product_Shipping__c shipping : productShippingList) {
                if(estimatedDays == null || (shipping.B2B_Estimated_Days__c != null && estimatedDays <= shipping.B2B_Estimated_Days__c)) {
                    estimatedDays = Integer.valueOf(shipping.B2B_Estimated_Days__c); 
                }
            }
        }

        if(estimatedDays == null || estimatedDays == 0) {
            estimatedDays = Integer.valueOf(System.Label.B2B_Default_Shipping_Estimated_Days);
        }
        return estimatedDays;
    }  
}
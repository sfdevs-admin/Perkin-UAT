/**
 * @Test Class        : B2B_SubscriptionOrderSchedulerTest
**/
public with sharing class B2B_SubscriptionShippingCalHelper {

    public static Decimal calculateShippingCharge(Order orderRecord) {
        try {
            if (orderRecord == null || orderRecord.B2B_Subscriptions__c == null) return 0;

            String shippingMethod = orderRecord.B2B_Subscriptions__r.B2B_Shipping_Method__c;

            if (String.isBlank(shippingMethod) || String.isBlank(orderRecord.ShippingCountry)) {
                return 0;
            }
			System.debug('Shipping calculation ::: ' + shippingMethod +', '+ orderRecord.ShippingCountry);
            B2B_Shipping_Methods__mdt method = fetchShippingMethod(shippingMethod, orderRecord.ShippingCountry);
            if (method == null) return 0;

            return calculateCharge(orderRecord.TotalAmount, method);
        } catch (Exception ex) {
            System.debug('Error calculating shipping charge: ' + ex.getMessage());
            return 0;
        }
    }

    private static B2B_Shipping_Methods__mdt fetchShippingMethod(String methodLabel, String countryCode) {
        List<B2B_Shipping_Methods__mdt> methods = [
                SELECT MasterLabel, Threshold_Value__c, Below_Threshold_Shipping_Charge__c, 
                       Above_Threshold_Shipping_Charge__c, Percent_Calculation__c, 
                       Percent_of_Net_Cost__c, Maximum_Shipping_Charge__c, Country_Code__c
                FROM B2B_Shipping_Methods__mdt
                WHERE MasterLabel = :methodLabel
                AND Country_Code__c = :countryCode
                AND isActive__c = TRUE
                LIMIT 1
            ];
            return methods.isEmpty() ? null : methods[0];
      
    }

    private static Decimal calculateCharge(Decimal totalAmountRaw, B2B_Shipping_Methods__mdt method) {
        Decimal totalAmount = totalAmountRaw != null ? totalAmountRaw : 0;
        Decimal shippingCharge = 0;

        if (method.Percent_Calculation__c && method.Percent_of_Net_Cost__c != null) {
            shippingCharge = totalAmount * (method.Percent_of_Net_Cost__c / 100);
        } else {
            Boolean isBelowThreshold = method.Threshold_Value__c != null && totalAmount < method.Threshold_Value__c;
            shippingCharge = isBelowThreshold ? method.Below_Threshold_Shipping_Charge__c : method.Above_Threshold_Shipping_Charge__c;
        }

        if (method.Maximum_Shipping_Charge__c != null && shippingCharge > method.Maximum_Shipping_Charge__c) {
            shippingCharge = method.Maximum_Shipping_Charge__c;
        }

        return shippingCharge.setScale(2, RoundingMode.HALF_UP);
    }
}
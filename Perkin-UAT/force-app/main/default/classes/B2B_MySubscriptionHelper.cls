/**
 * @description       : 
 * @author            : Suhail Ahmed T 
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
public without sharing class B2B_MySubscriptionHelper {

    public static Map<String, Object> getSubscriptionListsHelper(Map<String, Object> mapParams) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            // String userId = UserInfo.getUserId();
            // String accountId = [SELECT AccountId FROM User WHERE Id = :userId].AccountId;

            Id accountId = B2BUtils.getUserAccountID();
            String currencyCode = B2BUtils.getCurrencyIsoCode(accountId);

            List<B2B_SubscriptionWrapper> wrapperList = new List<B2B_SubscriptionWrapper>();

            List<B2B_Subscriptions__c> subscriptionLists = [
                SELECT Id, Subscription_Name__c, Description__c, B2B_Account__c, B2B_Status__c, 
                       B2B_Billing_Frequency__c, B2B_Shipping_Method__c, B2B_Payment_Method__c, B2B_Next_Billing_Date__c
                FROM B2B_Subscriptions__c
                WHERE B2B_Account__c = :accountId
                AND CurrencyIsoCode =: currencyCode
                ORDER BY CreatedDate ASC
            ];

            for (B2B_Subscriptions__c sub : subscriptionLists) {
                B2B_SubscriptionWrapper wrapper = new B2B_SubscriptionWrapper();
                wrapper.Id = sub.Id;
                wrapper.subscriptionName = sub.Subscription_Name__c;
                wrapper.subscriptionDescription = sub.Description__c;
                wrapper.subscriptionAccountId = sub.B2B_Account__c;
                wrapper.subscriptionStatus = sub.B2B_Status__c;
                wrapper.subscriptionBillingFrequency = sub.B2B_Billing_Frequency__c;
                wrapper.subscriptionShippingMethod = sub.B2B_Shipping_Method__c;
                wrapper.subscriptionPaymentMethod = sub.B2B_Payment_Method__c;
                // wrapper.subscriptionNextBillingDate = sub.B2B_Next_Billing_Date__c;

                if (sub.B2B_Next_Billing_Date__c != null) {
                    wrapper.subscriptionNextBillingDate = sub.B2B_Next_Billing_Date__c.format();
                } else {
                    wrapper.subscriptionNextBillingDate = '';
                }

                wrapperList.add(wrapper);
            }

            response.put('subscriptionLists', wrapperList);
            response.put('isSuccess', true);
        } catch (Exception ex) {
            response.put('isSuccess', false);
            response.put('message', ex.getMessage());
        }
        return response;
    }

    public static Map<String, Object> getSubscriptionItemsHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        B2B_SubscriptionWrapper subscriptionWrapper = new B2B_SubscriptionWrapper();
        Id accountId = B2BUtils.getUserAccountID();
        String currencyCode = B2BUtils.getCurrencyIsoCode(accountId);
        try {
            Id subscriptionId = (Id) mapParams.get('subscriptionId');

            if (String.isNotBlank(subscriptionId)) {
                // Query the subscription itself
                B2B_Subscriptions__c parentSub = [
                    SELECT Id,
                        Subscription_Name__c,
                        Description__c,
                        B2B_Account__c,
                        B2B_Status__c,
                        B2B_Billing_Frequency__c,
                        B2B_Shipping_Method__c,
                        B2B_Shipping_Address__c,
                        B2B_Billing_Address__c,
                        B2B_Payment_Method__c,
                        B2B_Next_Billing_Date__c
                    FROM B2B_Subscriptions__c
                    WHERE Id = :subscriptionId
                    AND CurrencyIsoCode =: currencyCode
                    LIMIT 1
                ];

                // Populate subscription wrapper
                subscriptionWrapper.Id = parentSub.Id;
                subscriptionWrapper.subscriptionName = parentSub.Subscription_Name__c;
                subscriptionWrapper.subscriptionDescription = parentSub.Description__c;
                subscriptionWrapper.subscriptionAccountId = parentSub.B2B_Account__c;
                subscriptionWrapper.subscriptionStatus = parentSub.B2B_Status__c;
                subscriptionWrapper.subscriptionBillingFrequency = parentSub.B2B_Billing_Frequency__c;
                subscriptionWrapper.subscriptionShippingMethod = parentSub.B2B_Shipping_Method__c;
                subscriptionWrapper.subscriptionPaymentMethod = parentSub.B2B_Payment_Method__c;
                // subscriptionWrapper.subscriptionNextBillingDate = parentSub.B2B_Next_Billing_Date__c;

                if (parentSub.B2B_Next_Billing_Date__c != null) {
                    subscriptionWrapper.subscriptionNextBillingDate = parentSub.B2B_Next_Billing_Date__c.format();
                } else {
                subscriptionWrapper.subscriptionNextBillingDate = '';
                }

                
                isSuccess = true;
                // Query associated items
                List<B2B_Subscription_Items__c> items = [
                    SELECT Id,
                        B2B_Product__c,
                        B2B_Unit_Price__c,
                        B2B_Total_Price__c,
                        B2B_Quantity__c,
                        CurrencyIsoCode,
                        B2B_Product__r.B2B_Display_Name__c,
                        B2B_Product__r.B2B_Part_Number__c,
                        B2B_Product__r.B2B_Short_Description__c
                    FROM B2B_Subscription_Items__c
                    WHERE B2B_Subscriptions__c = :subscriptionId
                ];

                for (B2B_Subscription_Items__c item : items) {
                    B2B_SubscriptionWrapper.SubscriptionItemWrapper itemWrapper = new B2B_SubscriptionWrapper.SubscriptionItemWrapper();
                    itemWrapper.id = item.Id;
                    itemWrapper.productId = item.B2B_Product__c;
                    itemWrapper.price = item.B2B_Unit_Price__c;
                    itemWrapper.totalPrice = item.B2B_Total_Price__c;
                    itemWrapper.quantity = item.B2B_Quantity__c;
                    itemWrapper.currencyIsoCode = currencyCode; //item.CurrencyIsoCode;
                    itemWrapper.productName = item.B2B_Product__r?.B2B_Display_Name__c;
                    itemWrapper.sku = item.B2B_Product__r?.B2B_Part_Number__c;
                    itemWrapper.description = item.B2B_Product__r?.B2B_Short_Description__c;

                    subscriptionWrapper.items.add(itemWrapper);
                }

                if (!subscriptionWrapper.items.isEmpty()) {
                    isSuccess = true;
                } else {
                    message = System.Label.B2B_No_Subscription_Items_Found;
                }
            } else {
                message = System.Label.B2B_Subscription_Id_Missing;
            }
        } catch (Exception e) {
            message = System.Label.B2B_Subcription_Error_Msg + ' ' + e.getMessage();
        }

        // Prepare the response
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        mapParams.put('subscriptionData', subscriptionWrapper);

        return mapParams;
    }

}
/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 08-20-2025
 * @last modified by  : S.T
 * @Test Class        : B2B_SubscriptionOrderSchedulerTest
**/
public with sharing class B2B_SubscriptionOrderScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        String queryStr = 'SELECT Id, Subscription_Name__c, B2B_Account__c, B2B_Contact__c, B2B_Next_Billing_Date__c, OwnerId, ' +
                   'B2B_Shipping_Address__c, B2B_Billing_Address__c, B2B_Shipping_Method__c, CurrencyIsoCode,' +
                   'B2B_Billing_Frequency__c, B2B_Payment_Method__c, B2B_Special_Instruction__c, B2B_Shipping_Provider__c,' +
                   'B2B_Shipping_Provider_Account_Number__c, B2B_Po_Number__c, B2B_End_Date__c,' +
                   'B2B_Billing_Address__r.Street, B2B_Billing_Address__r.City, B2B_Billing_Address__r.State, '+
                    'B2B_Billing_Address__r.PostalCode, B2B_Billing_Address__r.Country, '+
                    'B2B_Shipping_Address__r.Street, B2B_Shipping_Address__r.City, B2B_Shipping_Address__r.State, '+
                    'B2B_Shipping_Address__r.PostalCode, B2B_Shipping_Address__r.Country '+
                   'FROM B2B_Subscriptions__c ' +
                   'WHERE B2B_Status__c = \'Active\' ' +
                   'AND B2B_Next_Billing_Date__c = TODAY';

        System.debug('Query string :: ' + queryStr);
        B2B_SubscriptionOrderBatch batch = new B2B_SubscriptionOrderBatch(queryStr);
        Database.executeBatch(batch, Integer.valueOf(System.Label.B2B_Subscription_Order_Batch_Size) );
    }
}
/**
 * Created by mgaska001 on 31.10.2025.
 */

public with sharing class BD_QuoteLineHandler {

    static public void beforeInsert(List<SBQQ__QuoteLine__c> newList)
    {
        OnDocumentFieldsService.populateOnDocumentFields(newList, new Map<Id, SBQQ__QuoteLine__c>());
    }

    static public void afterInsert(List<SBQQ__QuoteLine__c> newList)
    {
        PricingConditionService.completeConditionalCodes(newList, new Map<Id, SBQQ__QuoteLine__c>());
        PricingBypassService.populateBypassSAPPrices(newList, new Map<Id, SBQQ__QuoteLine__c>());
    }

    static public void beforeUpdate(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap)
    {
        OnDocumentFieldsService.populateOnDocumentFields(newList, oldMap);
    }

    static public void afterUpdate(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap)
    {
        PricingConditionService.completeConditionalCodes(newList, oldMap);
        PricingBypassService.populateBypassSAPPrices(newList, oldMap);
    }

    static public void afterDelete(Map<Id, SBQQ__QuoteLine__c> oldMap)
    {
        PricingBypassService.populateBypassSAPPrices(new List<SBQQ__QuoteLine__c>(), oldMap);
    }

}
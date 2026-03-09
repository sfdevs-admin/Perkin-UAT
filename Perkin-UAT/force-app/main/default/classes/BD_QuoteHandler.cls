/**
 * Created by mgaska001 on 05.11.2025.
 */

public with sharing class BD_QuoteHandler {

    static public void beforeInsert(List<SBQQ__Quote__c> newList)
    {
        QuotePrimaryContactService.populateFullName(newList, new Map<Id, SBQQ__Quote__c>());
    }

    static public void beforeUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap)
    {
        QuotePrimaryContactService.populateFullName(newList, oldMap);
        OnDocumentFieldsService.populateOnDocumentQuoteFields(newList, oldMap);
    }

    static public void afterUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap)
    {
        QuoteAfterSAPPricesResponse.processPricesResponse(newList, oldMap);
        OnDocumentFieldsService.populateOnDocumentFieldsAfterLanguageChange(newList, oldMap);
        QuoteStalePriceService.setPriceStaleStampOnDraft(newList, oldMap);
    }

}
/**
 * Created by mgaska001 on 05.11.2025.
 */

public with sharing class QuoteAfterSAPPricesResponse {

    /**
     * @description SC-531 Method for trigger handler on SBQQ__Quote__c after update to manage
     * related SBQQ__QuoteLine__c records update based on SAP data that comes from integration
     */
    public static void processPricesResponse(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<Id, SBQQ__Quote__c> processMap = new Map<Id, SBQQ__Quote__c>();

        for (SBQQ__Quote__c newQuote : newList) {
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (newQuote.Price_Request_Status__c != oldQuote.Price_Request_Status__c
                && oldQuote.Price_Request_Status__c == 'Requested'
                && newQuote.Price_Request_Status__c == 'Idle') {
                processMap.put(newQuote.Id, newQuote);
            }
        }

        if (processMap.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = processMap.keySet();
        for (String quoteId : quoteIds) {
            PricingConditionRollUp.processQuoteRollUp(quoteId);
        }

        Map<Id, SBQQ__QuoteLine__c> recordsToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        updatePricingConditionDescriptions(quoteIds, recordsToUpdate);
        clearQuoteLinesStaleStamp(processMap, recordsToUpdate);

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate.values();
        }
    }

    /**
     * @description SC-403, SC-531 Method is users to clear stale price stamp on SBQQ__QuoteLine__c records
     * for Quotes that have prices successfully integrated from SAP
     * initially implemented in flow Quote_TRG_Clear_Price_Stale_Stamp
     */
    private static void clearQuoteLinesStaleStamp(
        Map<Id, SBQQ__Quote__c> processMap,
        Map<Id, SBQQ__QuoteLine__c> recordsToUpdate
    ) {
        Set<Id> quoteIds = processMap.keySet();
        for (SBQQ__QuoteLine__c quoteLine : [
            SELECT Id, SBQQ__Quote__c, Price_Stale_Stamp__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
            AND Price_Stale_Stamp__c != NULL
        ]) {
            SBQQ__Quote__c quote = processMap.get(quoteLine.SBQQ__Quote__c);
            if (quote.Price_Request_Stamp__c > quoteLine.Price_Stale_Stamp__c) {
                Id quoteLineId = quoteLine.Id;
                if (!recordsToUpdate.containsKey(quoteLineId)) {
                    recordsToUpdate.put(quoteLineId, new SBQQ__QuoteLine__c(
                        Id = quoteLineId
                    ));
                }
                recordsToUpdate.get(quoteLineId).Price_Stale_Stamp__c = null;
            }
        }
    }

    /**
     * @description SC-531 Method for trigger handler on SBQQ__Quote__c after update to manage
     * related SBQQ__QuoteLine__c records update based on SAP data that comes from integration
     * this method concatenate Pricing_Condition__c descriptions
     */
    private static void updatePricingConditionDescriptions(
        Set<Id> quoteIds,
        Map<Id, SBQQ__QuoteLine__c> recordsToUpdate
    ) {
        Map<Id, String> descriptions = fetchCombinedDescriptions(quoteIds);
        for (SBQQ__QuoteLine__c quoteLine : [
            SELECT Id, SBQQ__Quote__c, Pricing_Condition_Description__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ]) {
            Id quoteLineId = quoteLine.Id;
            String description = descriptions.get(quoteLineId);
            if (quoteLine.Pricing_Condition_Description__c != description) {
                if (!recordsToUpdate.containsKey(quoteLineId)) {
                    recordsToUpdate.put(quoteLineId, new SBQQ__QuoteLine__c(
                        Id = quoteLineId
                    ));
                }
                recordsToUpdate.get(quoteLineId).Pricing_Condition_Description__c = description;
            }
        }
    }

    /**
     * @description Helper method to query and concatenate Pricing_Condition__c descriptions
     */
    private static Map<Id, String> fetchCombinedDescriptions(Set<Id> quoteIds) {
        Map<Id, List<String>> descriptions = new Map<Id, List<String>>();
        for (Pricing_Condition__c pricingCondition : [
            SELECT Id, Quote_Line__c, SAP_Pricing_Condition_Description__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__r.SBQQ__Quote__c IN :quoteIds
            AND SAP_Pricing_Condition_Description__c != NULL
            AND Condition_Type__c =: PricingConditionConstants.TYPE_USER_DEFINED 
            ORDER BY Quote_Line__c, SAP_Pricing_Condition__c
        ]) {
            Id quoteLineId = pricingCondition.Quote_Line__c;
            if (!descriptions.containsKey(quoteLineId)) {
                descriptions.put(quoteLineId, new List<String>());
            }
            descriptions.get(quoteLineId).add(pricingCondition.SAP_Pricing_Condition_Description__c);
        }

        Map<Id, String> combined = new Map<Id, String>();
        for (String quoteLineId : descriptions.keySet()) {
            combined.put(quoteLineId, String.join(descriptions.get(quoteLineId), '\n'));
        }

        return combined;
    }
}
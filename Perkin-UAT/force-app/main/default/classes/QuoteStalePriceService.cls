/**
 * Created by mgaska001 on 16.12.2025.
 */

public with sharing class QuoteStalePriceService {

    /**
     * @description SC-553 Method for trigger handler on SBQQ__Quote__c after update to manage
     * change Quote status to Draft and populate Price Stale Stamp on every first Quote Line
     * we need this for update based on SAP data that comes from integration
     */
    public static void setPriceStaleStampOnDraft(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<Id, SBQQ__Quote__c> processMap = new Map<Id, SBQQ__Quote__c>();

        for (SBQQ__Quote__c newQuote : newList) {
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (newQuote.SBQQ__Status__c != oldQuote.SBQQ__Status__c
                && newQuote.SBQQ__Status__c == 'Draft'
                && !newQuote.BD_Submitted_to_SAP__c
                && newQuote.SBQQ__LineItemCount__c > 0) {
                processMap.put(newQuote.Id, newQuote);
            }
        }

        if (processMap.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = processMap.keySet();

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, Name, SBQQ__Quote__c, SBQQ__Number__c, Price_Stale_Stamp__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Number__c = 1
            AND SBQQ__Product__c != NULL
            AND Is_Kit_Component__c = FALSE
            AND Price_Stale_Stamp__c = NULL
            AND SBQQ__Quote__c IN :quoteIds
        ];

        if (!quoteLines.isEmpty()) {
            for (SBQQ__QuoteLine__c ql : quoteLines) {
                Datetime dt = Datetime.now();
                ql.Price_Stale_Stamp__c = dt;
            }
            update quoteLines;
        }

        List<SBQQ__Quote__c> staleQuotes = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
            AND Price_Request_Status__c = NULL
            AND Price_Stale_Items__c > 0
        ];

        if (!staleQuotes.isEmpty()) {
            for (SBQQ__Quote__c quote : staleQuotes) {
                quote.Price_Request_Status__c = 'Idle';
            }
            update staleQuotes;
        }
    }

}
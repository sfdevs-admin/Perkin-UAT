/**
 * Created by mgaska001 on 02.02.2026.
 */

public with sharing class PricingBypassService {

    public static void populateBypassSAPPrices(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        Set<Id> quoteIds = collectQuoteIdsOnProductChange(newList, oldMap);
        if (!quoteIds.isEmpty()) {
            populateBypassSAPPricesOnQuotes(quoteIds);
        }
    }

    public static Set<Id> collectQuoteIdsOnProductChange(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        List<QuoteProduct> quoteProducts = new List<QuoteProduct>();

        // We can't directly reference related Product2 records
        if (newList.isEmpty()) {
            // After delete SBQQ__QuoteLine__c handler
            for (SBQQ__QuoteLine__c oldQuoteLine : oldMap.values()) {
                productIds.add(oldQuoteLine.SBQQ__Product__c);
                quoteProducts.add(new QuoteProduct(oldQuoteLine.SBQQ__Quote__c, null, oldQuoteLine.SBQQ__Product__c));
            }
        } else {
            // After insert or After update SBQQ__QuoteLine__c handler
            for (SBQQ__QuoteLine__c newQuoteLine : newList) {
                SBQQ__QuoteLine__c oldQuoteLine = oldMap.get(newQuoteLine.Id);
                if (oldQuoteLine == null) {
                    productIds.add(newQuoteLine.SBQQ__Product__c);
                    quoteProducts.add(new QuoteProduct(newQuoteLine.SBQQ__Quote__c, newQuoteLine.SBQQ__Product__c, null));
                } else if (oldQuoteLine.SBQQ__Product__c != newQuoteLine.SBQQ__Product__c) {
                    productIds.add(newQuoteLine.SBQQ__Product__c);
                    productIds.add(oldQuoteLine.SBQQ__Product__c);
                    quoteProducts.add(new QuoteProduct(newQuoteLine.SBQQ__Quote__c, newQuoteLine.SBQQ__Product__c, oldQuoteLine.SBQQ__Product__c));
                }
            }
        }

        Set<Id> manualProductIds = fetchProductsWithManualPrices(productIds);
        if (!manualProductIds.isEmpty()) {
            for (QuoteProduct quoteProduct : quoteProducts) {
                if (quoteProduct.quoteId == null) {
                    continue;
                }
                if (manualProductIds.contains(quoteProduct.newProductId) != manualProductIds.contains(quoteProduct.oldProductId)) {
                    quoteIds.add(quoteProduct.quoteId);
                }
            }
        }

        return quoteIds;
    }

    public static void populateBypassSAPPricesOnQuotes(Set<Id> quoteIds) {
        Map<Id, SBQQ__Quote__c> quotes = fetchQuotes(quoteIds);
        Set<Id> hasManualItems = rollupManualItems(quoteIds);

        List<SBQQ__Quote__c> recordsToUpdate = new List<SBQQ__Quote__c>();
        for (Id quoteId : quotes.keySet()) {
            SBQQ__Quote__c quote = quotes.get(quoteId);
            Boolean hasPriceManualItems = hasManualItems.contains(quoteId);
            // Avoid not necessary updates
            // Update Has_Price_Manual_Items__c checkbox only when changed
            if (quote.Has_Price_Manual_Items__c != hasPriceManualItems) {
                quote.Has_Price_Manual_Items__c = hasPriceManualItems;
                // Update Bypass_SAP_Prices__c checkbox only when Has_Price_Manual_Items__c changed and should be aligned
                if (quote.Bypass_SAP_Prices__c != hasPriceManualItems) {
                    quote.Bypass_SAP_Prices__c = hasPriceManualItems;
                }
                recordsToUpdate.add(quote);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    private static Map<Id, SBQQ__Quote__c> fetchQuotes(Set<Id> quoteIds) {
        Map<Id, SBQQ__Quote__c> quotes = new Map<Id, SBQQ__Quote__c>([
            SELECT Id, Has_Price_Manual_Items__c, Bypass_SAP_Prices__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);
        return quotes;
    }

    private static Set<Id> rollupManualItems(Set<Id> quoteIds) {
        Set<Id> hasManualItems = new Set<Id>();
        for (AggregateResult result : [
            SELECT SBQQ__Quote__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
            AND SBQQ__Product__r.SAP_Manual_Prices__c = TRUE
            GROUP BY SBQQ__Quote__c
        ]) {
            Id quoteId = (Id) result.get('SBQQ__Quote__c');
            hasManualItems.add(quoteId);
        }
        return hasManualItems;
    }

    private static Set<Id> cacheSelectProductIds = new Set<Id>();
    private static Set<Id> cacheManualProductIds = new Set<Id>();

    private static Set<Id> fetchProductsWithManualPrices(Set<Id> productIds) {
        Set<Id> manualProductIds = new Set<Id>();
        Set<Id> selectProductIds = new Set<Id>();
        for (Id productId : productIds) {
            if (cacheSelectProductIds.contains(productId)) {
                if (cacheManualProductIds.contains(productId)) {
                    manualProductIds.add(productId);
                }
            } else {
                selectProductIds.add(productId);
            }
        }
        if (!selectProductIds.isEmpty()) {
            for (Product2 p : [
                SELECT Id
                FROM Product2
                WHERE Id IN :selectProductIds
                AND SAP_Manual_Prices__c = TRUE
            ]) {
                manualProductIds.add(p.Id);
            }
            cacheSelectProductIds.addAll(selectProductIds);
            cacheManualProductIds.addAll(manualProductIds);
        }
        return manualProductIds;
    }

    public class QuoteProduct {
        public Id quoteId;
        public Id newProductId;
        public Id oldProductId;

        public QuoteProduct(Id quoteId, Id newProductId, Id oldProductId) {
            this.quoteId = quoteId;
            this.newProductId = newProductId;
            this.oldProductId = oldProductId;
        }
    }
}
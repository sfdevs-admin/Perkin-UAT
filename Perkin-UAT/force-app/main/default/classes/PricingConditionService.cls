public with sharing class PricingConditionService {



    /**
     * @description SC-553 Method for adjust existing SBQQ__Quote__c with Pricing_Condition__c records used to fix missing data
     * Pricing_Condition__c records with Condition_Type__c = Conditional and SAP_Pricing_Condition__c codes IN (ZSLS, ZVDI, ZSPC)
     */
    public static void completeConditionalCodesForQuote(String quoteId) {
        List<SBQQ__QuoteLine__c> quoteLines = fetchQuoteLines(quoteId);
        completeConditionalCodes(quoteLines, new Map<Id, SBQQ__QuoteLine__c>());
    }

    /**
     * @description SC-531 Method for trigger handler on SBQQ__QuoteLine__c after insert or after update to manage
     * Pricing_Condition__c records with Condition_Type__c = Conditional and SAP_Pricing_Condition__c codes IN (ZSLS, ZVDI, ZSPC)
     */
    public static void completeConditionalCodes(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        List<Pricing_Condition__c> recordsToUpsert = new List<Pricing_Condition__c>();
        List<Pricing_Condition__c> recordsToDelete = new List<Pricing_Condition__c>();
        Map<Id, SBQQ__QuoteLine__c> processMap = new Map<Id, SBQQ__QuoteLine__c>();
        Set<String> quoteIds = new Set<String>();
        Set<String> quoteLineIds = new Set<String>();

        // Collect data to process change 
        collectConditionalCodesProcessData(newList, oldMap, processMap, quoteIds, quoteLineIds);
        if (processMap.isEmpty() && quoteIds.isEmpty() && quoteLineIds.isEmpty()) {
            return;
        }
        // Query related SBQQ__Quote__c records
        Map<Id, SBQQ__Quote__c> quotes = fetchQuotes(quoteIds);
        // Query existing Pricing_Condition__c of Conditional type   
        Map<String, Map<String, Pricing_Condition__c>> pricingConditions = fetchPricingConditions(
            quoteLineIds, PricingConditionConstants.TYPE_CONDITIONAL
        );

        List<String> conditionScenariosService = new List<String>{
            PricingConditionConstants.CONDITIONAL_SERVICE_DISCOUNT,
            PricingConditionConstants.CONDITIONAL_SERVICE_BUNDLED,
            PricingConditionConstants.CONDITIONAL_SERVICE_PRO_RATED,
            PricingConditionConstants.CONDITIONAL_SERVICE_PRO_RATED_DISCOUNT
        };

        List<String> conditionScenariosOther = new List<String>{
            PricingConditionConstants.CONDITIONAL_FREIGHT,
            PricingConditionConstants.CONDITIONAL_DISCOUNT,
            PricingConditionConstants.CONDITIONAL_BUNDLED
        };

        for (SBQQ__QuoteLine__c processQuoteLine : processMap.values()) {
            SBQQ__Quote__c quote = quotes.get(processQuoteLine.SBQQ__Quote__c);

            List<String> conditionScenarios =
                (quote.SalesType__c == PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS)
                    ? conditionScenariosService : conditionScenariosOther;
            for (String condition : conditionScenarios) {
                ConditionalAmount conditionalAmount = fillConditionalData(condition, processQuoteLine);
                if (conditionalAmount != null) {
                    manageConditionalCodeForUpsert(
                        processQuoteLine.Id, conditionalAmount, processQuoteLine.CurrencyIsoCode,
                        pricingConditions, recordsToUpsert
                    );
                    // Only one SAP_Pricing_Condition__c for SBQQ__QuoteLine__c: ZSPC, ZSLS OR ZVDI
                    break;
                }
            }
        }

        // Prepare Pricing_Condition__c records for delete that are no longer needed
        for (String quoteLineId : pricingConditions.keySet()) {
            recordsToDelete.addAll(pricingConditions.get(quoteLineId).values());
        }

        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }

    public static ConditionalAmount fillConditionalData(String condition, SBQQ__QuoteLine__c quoteLine) {

        if (condition == PricingConditionConstants.CONDITIONAL_FREIGHT) {
            // ZSPC for Freight and Special Products
            // IF Product Code CONTAINS "SPECIAL" OR "REGDEL" OR SV000301-SV000305
            // ZSPC: SBQQ__NetPrice__c, SBQQ__NetTotal__c
            if (isFreightProductCode(quoteLine.SBQQ__ProductCode__c)
                && quoteLine.SBQQ__NetPrice__c != null
                && quoteLine.SBQQ__NetTotal__c != null
            ) {
                Decimal price = quoteLine.SBQQ__NetPrice__c;
                Decimal amount = quoteLine.SBQQ__NetTotal__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZSPC, PricingConditionConstants.CALCTYPON_B, price, amount
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_DISCOUNT) {
            // ZSLS for POS Sales Type and for Consumables Sales Type
            // Rep_Total_Unit_Discount__c > 0 AND SBQQ__TotalDiscountRate__c <> 100
            // ZSLS: - Rep_Total_Unit_Discount__c, - Rep_Total_Unit_Discount__c * SBQQ__Quantity__c
            if (quoteLine.Rep_Total_Unit_Discount__c > 0
                && quoteLine.SBQQ__TotalDiscountRate__c != 100
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = - quoteLine.Rep_Total_Unit_Discount__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZSLS, PricingConditionConstants.CALCTYPON_C,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_BUNDLED) {
            // ZSLS for POS Sales Type and for Consumables Sales Type
            // Rep_Total_Unit_Discount__c = 0 AND SBQQ__TotalDiscountRate__c = 100 (Bundled)
            // ZSLS: - SBQQ__ListPrice__c, - SBQQ__ListPrice__c * SBQQ__Quantity__c
            if (quoteLine.SBQQ__Bundled__c
                && quoteLine.Rep_Total_Unit_Discount__c == 0
                && quoteLine.SBQQ__TotalDiscountRate__c == 100
                && quoteLine.SBQQ__ListPrice__c != null
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = - quoteLine.SBQQ__ListPrice__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZSLS, PricingConditionConstants.CALCTYPON_C,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_SERVICE_DISCOUNT) {
            // ZVDI Services
            // Pro_Rated_Unit_Price__c EMPTY AND Rep_Total_Unit_Discount__c > 0 AND SBQQ__TotalDiscountRate__c <> 100
            // ZVDI: - quoteLine.Rep_Total_Unit_Discount__c, - Rep_Total_Unit_Discount__c * SBQQ__Quantity__c
            if (quoteLine.Pro_Rated_Unit_Price__c == null
                && quoteLine.Rep_Total_Unit_Discount__c > 0
                && quoteLine.SBQQ__TotalDiscountRate__c != 100
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = - quoteLine.Rep_Total_Unit_Discount__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZVDI, PricingConditionConstants.CALCTYPON_M,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_SERVICE_BUNDLED) {
            // ZVDI Services
            // Rep_Total_Unit_Discount__c = 0 AND SBQQ__TotalDiscountRate__c = 100 (Bundled)
            // ZVDI: - SBQQ__ListPrice__c * SBQQ__Quantity__c
            if (quoteLine.SBQQ__Bundled__c
                && quoteLine.Rep_Total_Unit_Discount__c == 0
                && quoteLine.SBQQ__TotalDiscountRate__c == 100
                && quoteLine.SBQQ__ListPrice__c != null
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = - quoteLine.SBQQ__ListPrice__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZVDI, PricingConditionConstants.CALCTYPON_M,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_SERVICE_PRO_RATED) {
            // ZVDI Services
            // Pro_Rated_Unit_Price__c NOT EMPTY AND Rep_Total_Unit_Discount__c = 0
            // ZVDI: Pro_Rated_Unit_Price__c - SBQQ__ListPrice__c
            if (quoteLine.Pro_Rated_Unit_Price__c != null
                && quoteLine.Rep_Total_Unit_Discount__c == 0
                && quoteLine.SBQQ__ListPrice__c != null
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = quoteLine.Pro_Rated_Unit_Price__c - quoteLine.SBQQ__ListPrice__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZVDI, PricingConditionConstants.CALCTYPON_M,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        } else if (condition == PricingConditionConstants.CONDITIONAL_SERVICE_PRO_RATED_DISCOUNT) {
            // ZVDI for Material Groups
            // Pro_Rated_Unit_Price__c NOT EMPTY AND Rep_Total_Unit_Discount__c > 0 AND SBQQ__TotalDiscountRate__c <> 100
            // ZVDI: Pro_Rated_Unit_Price__c - SBQQ__ListPrice__c - Rep_Total_Unit_Discount__c
            if (quoteLine.Pro_Rated_Unit_Price__c != null
                && quoteLine.Rep_Total_Unit_Discount__c > 0
                && quoteLine.SBQQ__TotalDiscountRate__c != 100
                && quoteLine.SBQQ__ListPrice__c != null
                && quoteLine.SBQQ__Quantity__c != null
            ) {
                Decimal price = quoteLine.Pro_Rated_Unit_Price__c - quoteLine.SBQQ__ListPrice__c - quoteLine.Rep_Total_Unit_Discount__c;
                return new ConditionalAmount(
                    PricingConditionConstants.ZVDI, PricingConditionConstants.CALCTYPON_M,
                    price, price * quoteLine.SBQQ__Quantity__c
                );
            }
        }

        return null;
    }

    /**
     * @description Helper method to:
     * Collect all SBQQ__QuoteLine__c.Id that will be used for query existing Pricing_Condition__c records
     * Check conditions for creating Pricing_Condition__c records
     * Collect all related SBQQ__Quote__c.Id and SBQQ__QuoteLine__c records to process
     */
    private static void collectConditionalCodesProcessData(
        List<SBQQ__QuoteLine__c> newList,
        Map<Id, SBQQ__QuoteLine__c> oldMap,
        Map<Id, SBQQ__QuoteLine__c> processMap,
        Set<String> quoteIds, 
        Set<String> quoteLineIds
    ) {
        for (SBQQ__QuoteLine__c newQuoteLine : newList) {
            Boolean processOld = false;
            Boolean processNew = false;
            // Collect all SBQQ__QuoteLine__c.Id that will be used for query existing Pricing_Condition__c records
            SBQQ__QuoteLine__c oldQuoteLine = oldMap.get(newQuoteLine.Id);
            if (oldQuoteLine != null) {
                // Check conditions for creating Pricing_Condition__c records on old record
                if (checkForInsertPricingCondition(oldQuoteLine)) {
                    processOld = true;
                }
            }
            // Check conditions for creating Pricing_Condition__c records
            if (checkForInsertPricingCondition(newQuoteLine)) {
                processNew = true;
            }
            if (processOld && processNew) {
                // Check if these are no changes
                if (!checkForUpdatePricingCondition(newQuoteLine, oldQuoteLine)) {
                    processOld = processNew = false;
                }
            }
            if (processNew) {
                quoteLineIds.add(newQuoteLine.Id);
                quoteIds.add(newQuoteLine.SBQQ__Quote__c);
                processMap.put(newQuoteLine.Id, newQuoteLine);
            } else if (processOld) {
                quoteLineIds.add(oldQuoteLine.Id);
            }
        }
    }

    /**
     * @description Helper method to check conditions for creating Pricing_Condition__c record
     */
    private static Boolean checkForInsertPricingCondition(SBQQ__QuoteLine__c newQuoteLine) {
        // Check for freight products
        if (isFreightProductCode(newQuoteLine.SBQQ__ProductCode__c) && newQuoteLine.SBQQ__NetPrice__c != null) {
            return true;
        }
        
        // Check for discount scenarios (applicable to POS, Consumables, and Service Contracts)
        if (newQuoteLine.Rep_Total_Unit_Discount__c > 0) {
            return true;
        }
        
        // Check for bundled items
        if (newQuoteLine.SBQQ__Bundled__c 
            && newQuoteLine.Rep_Total_Unit_Discount__c == 0
            && newQuoteLine.SBQQ__TotalDiscountRate__c == 100 
            && newQuoteLine.SBQQ__ListPrice__c != null) {
            return true;
        }
        
        // Check for Pro_Rated_Unit_Price__c
        if (newQuoteLine.Pro_Rated_Unit_Price__c != null) {
            return true;
        }
        
        return false;
    }

    /**
     * @description Helper method to check if any changes were done that require Pricing_Condition__c record update
     */
    private static Boolean checkForUpdatePricingCondition(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine) {
        if (oldQuoteLine.Rep_Total_Unit_Discount__c == newQuoteLine.Rep_Total_Unit_Discount__c
            && oldQuoteLine.SBQQ__Bundled__c == newQuoteLine.SBQQ__Bundled__c
            && oldQuoteLine.SBQQ__TotalDiscountRate__c == newQuoteLine.SBQQ__TotalDiscountRate__c
            && !ChangeUtil.isPriceChanged(oldQuoteLine.Pro_Rated_Unit_Price__c, newQuoteLine.Pro_Rated_Unit_Price__c)
            && oldQuoteLine.SBQQ__ProductCode__c == newQuoteLine.SBQQ__ProductCode__c
            && oldQuoteLine.CurrencyIsoCode == newQuoteLine.CurrencyIsoCode
            && !ChangeUtil.isPriceChanged(oldQuoteLine.SBQQ__ListPrice__c, newQuoteLine.SBQQ__ListPrice__c)
            && !ChangeUtil.isPriceChanged(oldQuoteLine.SBQQ__NetPrice__c, newQuoteLine.SBQQ__NetPrice__c)
            && !ChangeUtil.isPriceChanged(oldQuoteLine.SBQQ__NetTotal__c, newQuoteLine.SBQQ__NetTotal__c)
            && oldQuoteLine.Item_Class__c == newQuoteLine.Item_Class__c
            && oldQuoteLine.SBQQ__Quantity__c == newQuoteLine.SBQQ__Quantity__c
        ) {
            return false;
        }
        return true;
    }

    /**
     * @description Method to manage Pricing_Condition__c record for insert or update
     */
    private static void manageConditionalCodeForUpsert(
        String quoteLineId, ConditionalAmount conditionalAmount, String currencyIsoCode,
        Map<String, Map<String, Pricing_Condition__c>> pricingConditions,
        List<Pricing_Condition__c> recordsToUpsert) {
        // Remove from existing Pricing_Condition__c records collection all that are processed
        // Create new Pricing_Condition__c record or prepare for update existing ones if need change
        Pricing_Condition__c pricingCondition = pricingConditions.get(quoteLineId)?.remove(conditionalAmount.code);
        if (pricingCondition == null) {
            pricingCondition = new Pricing_Condition__c();
            pricingCondition.Quote_Line__c = quoteLineId;
            pricingCondition.SAP_Pricing_Condition__c = conditionalAmount.code;
            pricingCondition.SAP_CALCTYPON__c = conditionalAmount.calc;
            pricingCondition.Condition_Type__c = PricingConditionConstants.TYPE_CONDITIONAL;
            pricingCondition.SAP_Unit_Price__c = conditionalAmount.price;
            pricingCondition.SAP_Net_Price__c = conditionalAmount.amount;
            pricingCondition.CurrencyIsoCode = currencyIsoCode;
            pricingCondition.Source__c = PricingConditionConstants.SOURCE_SALESFORCE;
            recordsToUpsert.add(pricingCondition);
        } else if (pricingCondition.SAP_Unit_Price__c != conditionalAmount.price
            || pricingCondition.SAP_Net_Price__c != conditionalAmount.amount
            || pricingCondition.CurrencyIsoCode != currencyIsoCode) {
            pricingCondition.SAP_Unit_Price__c = conditionalAmount.price;
            pricingCondition.SAP_Net_Price__c = conditionalAmount.amount;
            pricingCondition.CurrencyIsoCode = currencyIsoCode;
            recordsToUpsert.add(pricingCondition);
        }
    }

    /**
     * @description Helper method to check freight or special ProductCode
     */
    private static Boolean isFreightProductCode(String productCode) {
        return PricingConditionConstants.isFreightOrSpecialProductCode(productCode);
    }

    /**
     * @description Helper method to query Pricing_Condition__c and group records by Quote_Line__c and SAP_Pricing_Condition__c
     */
    private static Map<String, Map<String, Pricing_Condition__c>> fetchPricingConditions(Set<String> quoteLineIds, String type) {
        Map<String, Map<String, Pricing_Condition__c>> pricingConditions = new Map<String, Map<String, Pricing_Condition__c>>();
        if (quoteLineIds.isEmpty()) {
            return pricingConditions;
        }
        for (Pricing_Condition__c pricingCondition : [
            SELECT Id, SAP_Pricing_Condition__c, Quote_Line__c, SAP_Unit_Price__c, SAP_Net_Price__c, CurrencyIsoCode
            FROM Pricing_Condition__c
            WHERE Quote_Line__c IN :quoteLineIds
            AND Condition_Type__c = :type
            ORDER BY Quote_Line__c, SAP_Pricing_Condition__c
        ]) {
            String quoteLineId = pricingCondition.Quote_Line__c;
            if (!pricingConditions.containsKey(quoteLineId)) {
                pricingConditions.put(quoteLineId, new Map<String, Pricing_Condition__c>());
            }
            pricingConditions.get(quoteLineId).put(pricingCondition.SAP_Pricing_Condition__c, pricingCondition);
        }
        return pricingConditions;
    }

    /**
     * @description Helper method to query SBQQ__Quote__c with SalesType__c
     */
    private static Map<Id, SBQQ__Quote__c> fetchQuotes(Set<String> quoteIds) {
        if (quoteIds.isEmpty()) {
            return new Map<Id, SBQQ__Quote__c>();
        }
        return new Map<Id, SBQQ__Quote__c>([
            SELECT Id, SalesType__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);
    }

    /**
     * @description Helper method to query SBQQ__QuoteLine__c records for given quoteId
     */
    private static List<SBQQ__QuoteLine__c> fetchQuoteLines(String quoteId) {
        return [
            SELECT Id, CurrencyIsoCode, SBQQ__Quote__c, SBQQ__Bundled__c, SBQQ__ProductCode__c,
                Rep_Total_Unit_Discount__c, SBQQ__TotalDiscountRate__c, Pro_Rated_Unit_Price__c,
                SBQQ__ListPrice__c, SBQQ__NetPrice__c, Item_Class__c, SBQQ__Quantity__c, SBQQ__NetTotal__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
        ];
    }

    public class ConditionalAmount {
        public String code;
        public String calc;
        public Decimal price;
        public Decimal amount;

        public ConditionalAmount(String code, String calc, Decimal price, Decimal amount) {
            this.code = code;
            this.calc = calc;
            this.price = price;
            this.amount = amount;
        }
    }
}
/**
 * Created by mgaska001 on 03.11.2025.
 */

public with sharing class PricingConditionRollUp {

    public static final Map<String, Set<String>> rollupFields = new Map<String, Set<String>>{
         'SAP_List_Unit_Price__c' => new Set<String>{
            PricingConditionConstants.PR00
        },
        'SAP_Promotions_Unit_Amount__c' => new Set<String>{
            PricingConditionConstants.KA01
        },
        'SAP_Gross_Amount__c' => new Set<String>{
            PricingConditionConstants.ZGRS
        },
        'SAP_Total_Amount__c' => new Set<String>{
            PricingConditionConstants.ZTOL
        },
        'SAP_Contract_Discount_Amount__c' => new Set<String>{
            PricingConditionConstants.ZCMD,
            PricingConditionConstants.ZUBP
        },
        'SAP_Contract_Discount_Percentage__c' => new Set<String>{
             PricingConditionConstants.ZCMD,
             PricingConditionConstants.ZUBP
        },
        'SAP_Deal_Price__c' => new Set<String>{
            PricingConditionConstants.ZSPB
        },
        'SAP_Item_Freight__c' => new Set<String>{
            PricingConditionConstants.ZD96,
            PricingConditionConstants.ZDUU,
            PricingConditionConstants.ZDEL
        },
        'SAP_Surcharge__c' => new Set<String>{
            PricingConditionConstants.ZBS1,
            PricingConditionConstants.ZBS2,
            PricingConditionConstants.ZBS3,
            PricingConditionConstants.ZBS4
        }
        // Note: MWST, ZOIG, ZAIG, XR codes, and IPVA handled separately in processRollUpCalculations
        // Note: ZGRS for Freight and Special products handled separately
    };

    public static final String ROLLUP_UNIT_PRICE = 'UNIT';
    public static final String ROLLUP_NET_PRICE = 'NET';

    public static final Map<String, String> rollupPriceField = new Map<String, String>{
        'SAP_Net_Unit_Price__c' => ROLLUP_UNIT_PRICE,
        'SAP_List_Unit_Price__c' => ROLLUP_UNIT_PRICE,
        'SAP_Promotions_Unit_Amount__c' => ROLLUP_NET_PRICE,
        'SAP_Gross_Amount__c' => ROLLUP_UNIT_PRICE,
        'SAP_Total_Amount__c' => ROLLUP_NET_PRICE,
        'SAP_Contract_Discount_Amount__c' => ROLLUP_NET_PRICE,
        'SAP_Contract_Discount_Percentage__c' => ROLLUP_UNIT_PRICE,
        'SAP_Deal_Price__c' => ROLLUP_NET_PRICE,
        'SAP_Item_Freight__c' => ROLLUP_UNIT_PRICE,
        'SAP_Surcharge__c' => ROLLUP_UNIT_PRICE,
        'IPI_Percentage__c' => ROLLUP_UNIT_PRICE,
        'IPI_Amount__c' => ROLLUP_NET_PRICE
    };

    public static final Set<String> unitCodes = new Set<String> {
        PricingConditionConstants.PR00,
        PricingConditionConstants.ZGRS,
        PricingConditionConstants.NETP,
        PricingConditionConstants.PNTP,
        PricingConditionConstants.ZCMD,
        PricingConditionConstants.ZUBP,
        PricingConditionConstants.ZD96,
        PricingConditionConstants.ZDUU,
        PricingConditionConstants.ZDEL,
        PricingConditionConstants.ZBS1,
        PricingConditionConstants.ZBS2,
        PricingConditionConstants.ZBS3,
        PricingConditionConstants.ZBS4,
        PricingConditionConstants.IPVA
    };

    public static final Set<String> netCodes = new Set<String> {
        PricingConditionConstants.KA01,
        PricingConditionConstants.ZTOL,
        PricingConditionConstants.ZCMD,
        PricingConditionConstants.ZUBP,
        PricingConditionConstants.ZSPB,
        PricingConditionConstants.BX23
    };

    // Tax condition codes by region
    private static final Set<String> TAX_CODES_MWST = new Set<String>{ 
        PricingConditionConstants.MWST 
    };
    private static final Set<String> TAX_CODES_JAPAN = new Set<String>{ 
        PricingConditionConstants.ZOIG, 
        PricingConditionConstants.ZAIG 
    };
    private static final Set<String> TAX_CODES_BRAZIL = new Set<String>{ 
        PricingConditionConstants.BX13, 
        PricingConditionConstants.BX23, 
        PricingConditionConstants.BX51, 
        PricingConditionConstants.BX72, 
        PricingConditionConstants.BX82 
    };
    private static final Set<String> TAX_CODES_NORTH_AMERICA = new Set<String>{ 
        PricingConditionConstants.XR1, 
        PricingConditionConstants.XR2, 
        PricingConditionConstants.XR3, 
        PricingConditionConstants.XR4, 
        PricingConditionConstants.XR5, 
        PricingConditionConstants.XR6 
    };

    /**
     * @description SC-531 Dispatcher method that orchestrates the roll-up process
     * Performs all SOQLs upfront and invokes processing methods in sequence
     * ZGRS and ZTOL are created for ALL quotes (not just Service Contracts)
     * 
     * @param quoteId The quote ID to process
     */
    public static void processQuoteRollUp(String quoteId) {
        // Step 1: Query all required data upfront
        Map<Id, SBQQ__QuoteLine__c> quoteLines = fetchQuoteLines(quoteId);
        Map<Id, List<Pricing_Condition__c>> allPricingConditions = fetchAllPricingConditions(quoteId);
        
        // Step 2: Manage calculated Pricing Conditions (ZGRS and ZTOL) - for ALL quotes
        manageCalculatedPricingConditions(quoteLines, allPricingConditions);
        
        // Step 3: Query roll-up prices after calculated pricing conditions processing
        Map<String, Map<String, Decimal>> rollUpPrices = fetchRollUpPrices(quoteId, PricingConditionConstants.TYPE_DEFAULT);
        
        // Step 4: Process the roll-up calculations (always executed)
        List<SBQQ__QuoteLine__c> recordsToUpdate = processRollUpCalculations(quoteLines, rollUpPrices, allPricingConditions);
        
        // Step 5: Perform DML operation
        if (!recordsToUpdate.isEmpty()) {
            upsert recordsToUpdate;
        }
    }

    /**
     * @description Fetches all pricing conditions for the quote grouped by quote line
     * @param quoteId The quote ID to query conditions for
     * @return Map of quote line ID to list of pricing conditions
     */
    private static Map<Id, List<Pricing_Condition__c>> fetchAllPricingConditions(String quoteId) {
        Map<Id, List<Pricing_Condition__c>> conditionsByQuoteLine = new Map<Id, List<Pricing_Condition__c>>();
        
        for (Pricing_Condition__c pc : [
            SELECT Id, Quote_Line__c, SAP_Pricing_Condition__c, SAP_Unit_Price__c, SAP_Net_Price__c,
                   Condition_Type__c, Source__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__r.SBQQ__Quote__c = :quoteId
        ]) {
            if (!conditionsByQuoteLine.containsKey(pc.Quote_Line__c)) {
                conditionsByQuoteLine.put(pc.Quote_Line__c, new List<Pricing_Condition__c>());
            }
            conditionsByQuoteLine.get(pc.Quote_Line__c).add(pc);
        }
        
        return conditionsByQuoteLine;
    }

    /**
     * @description Manages calculated pricing conditions (ZGRS and ZTOL) for all quote lines
     * Executes for ALL quotes (not limited to Service Contracts)
     * @param quoteLines Map of quote line records
     * @param allPricingConditions Map of all pricing conditions by quote line
     */
    private static void manageCalculatedPricingConditions(
        Map<Id, SBQQ__QuoteLine__c> quoteLines,
        Map<Id, List<Pricing_Condition__c>> allPricingConditions) {
        
        List<Pricing_Condition__c> recordsToUpsert = new List<Pricing_Condition__c>();
        
        for (Id quoteLineId : quoteLines.keySet()) {
            SBQQ__QuoteLine__c quoteLine = quoteLines.get(quoteLineId);
            List<Pricing_Condition__c> conditions = allPricingConditions.get(quoteLineId);
            
            if (conditions == null) {
                conditions = new List<Pricing_Condition__c>();
            }
            
            // Process ZGRS
            Pricing_Condition__c zgrsResult = manageZGRSCondition(quoteLine, conditions);
            Decimal zgrsAmount = 0;
            if (zgrsResult != null) {
                recordsToUpsert.add(zgrsResult);
                zgrsAmount = zgrsResult.SAP_Unit_Price__c;
            }
            
            // Process ZTOL (pass ZGRS amount if it was just created)
            Pricing_Condition__c ztolResult = manageZTOLCondition(quoteLine, conditions, zgrsAmount);
            if (ztolResult != null) {
                recordsToUpsert.add(ztolResult);
            }
        }
        
        // Perform DML if there are records to process
        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
    }

    /**
     * @description Manages ZGRS Pricing Condition for a single quote line
     * @param quoteLine The quote line record
     * @param conditions List of all pricing conditions for this quote line
     * @return Pricing_Condition__c record to upsert, or null if no action needed
     */
    private static Pricing_Condition__c manageZGRSCondition(
        SBQQ__QuoteLine__c quoteLine,
        List<Pricing_Condition__c> conditions) {
        
        // Find existing ZGRS (any type) and calculate User Defined sum
        Pricing_Condition__c defaultZGRS = null;
        Boolean hasZGRSOtherType = false;
        Decimal userDefinedSum = 0;
        
        for (Pricing_Condition__c pc : conditions) {
            // Check for ZGRS
            if (pc.SAP_Pricing_Condition__c == PricingConditionConstants.ZGRS) {
                if (pc.Condition_Type__c == PricingConditionConstants.TYPE_DEFAULT) {
                    defaultZGRS = pc;
                } else {
                    hasZGRSOtherType = true;
                }
            }
            
            // Sum User Defined conditions
            // We have to rely on SAP_Unit_Price__c and then multiply it by the Quote Line quantity
            if (pc.Condition_Type__c == PricingConditionConstants.TYPE_USER_DEFINED && 
                pc.SAP_Unit_Price__c != null) {
                userDefinedSum += pc.SAP_Unit_Price__c;
            }
        }

        // Case 1: ZGRS exists with other type (not Default) - Skip, don't interfere
        if (hasZGRSOtherType && defaultZGRS == null) {
            return null;
        }

        // Skip if no User Defined conditions (sum is 0)
        if (userDefinedSum == 0) {
            return null;
        }
        
        // Case 2: No ZGRS Default exists -> Create new with Source = Salesforce
        if (defaultZGRS == null) {
            defaultZGRS = createPricingCondition(quoteLine, PricingConditionConstants.ZGRS);
        }
        
        // Case 2+3: ZGRS Default exists but Source = Salesforce -> Update
        if (defaultZGRS.Source__c == PricingConditionConstants.SOURCE_SALESFORCE) {
            populatePricingConditionPrices(quoteLine, defaultZGRS, userDefinedSum);
            return defaultZGRS;
        }
        
        // Case 4: ZGRS Default exists and Source = SAP -> No action (preserve SAP data)
        return null;
    }

    /**
     * @description Manages ZTOL Pricing Condition for a single quote line
     * @param quoteLine The quote line record
     * @param conditions List of all pricing conditions for this quote line
     * @param newlyCreatedZGRS Amount of ZGRS if it was just created (0 if not created)
     * @return Pricing_Condition__c record to upsert, or null if no action needed
     */
    private static Pricing_Condition__c manageZTOLCondition(
        SBQQ__QuoteLine__c quoteLine,
        List<Pricing_Condition__c> conditions,
        Decimal newlyCreatedZGRS) {
        
        // Find existing ZTOL (any type)
        Pricing_Condition__c defaultZTOL = null;
        Boolean hasZTOLOtherType = false;
        
        for (Pricing_Condition__c pc : conditions) {
            if (pc.SAP_Pricing_Condition__c == PricingConditionConstants.ZTOL) {
                if (pc.Condition_Type__c == PricingConditionConstants.TYPE_DEFAULT) {
                    defaultZTOL = pc;
                } else {
                    hasZTOLOtherType = true;
                }
            }
        }

        // Case 1: ZTOL exists with other type (not Default) - Skip, don't interfere
        if (hasZTOLOtherType && defaultZTOL == null) {
            return null;
        }

        // Calculate ZTOL amount = ZGRS + ZVDI + ZSLS + Tax
        Decimal ztolAmount = calculateZTOLAmount(quoteLine, conditions, newlyCreatedZGRS);

        // Case 2: No ZTOL Default exists -> Create new with Source = Salesforce
        if (defaultZTOL == null) {
            defaultZTOL = createPricingCondition(
                quoteLine,
                PricingConditionConstants.ZTOL
            );
        }

        // Case 2+3: ZTOL Default exists and Source = Salesforce -> Update
        if (defaultZTOL.Source__c == PricingConditionConstants.SOURCE_SALESFORCE) {
            populatePricingConditionPrices(quoteLine, defaultZTOL, ztolAmount);
            return defaultZTOL;
        }

        // Case 4: ZTOL Default exists and Source = SAP -> No action (preserve SAP data)
        return null;
    }

    /**
     * @description Calculates the base amount for ZTOL
     * @param conditions List of all pricing conditions for the quote line
     * @param newlyCreatedZGRS Amount of ZGRS if it was just created (0 if not created)
     * @return Base amount for ZTOL calculation
     */
    private static Decimal calculateZTOLAmount(
        SBQQ__QuoteLine__c quoteLine, List<Pricing_Condition__c> conditions, Decimal newlyCreatedZGRS) {

        Decimal quantity = (quoteLine.SBQQ__Quantity__c != null && quoteLine.SBQQ__Quantity__c != 0)
            ? quoteLine.SBQQ__Quantity__c : 1;
        Boolean isServiceContract = (quoteLine.SBQQ__Quote__r.SalesType__c == PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS);

        // Calculate ZTOL amount = ZGRS + ZVDI + ZSLS + Tax
        // ZGRS
        Decimal zgrsAmount = 0;
        if (newlyCreatedZGRS > 0) {
            zgrsAmount = newlyCreatedZGRS;
        } else {
            zgrsAmount = getConditionAmount(conditions, PricingConditionConstants.ZGRS, PricingConditionConstants.TYPE_DEFAULT);
        }
        Decimal taxAmount = calculateTaxAmount(conditions);
        if (isServiceContract) {
            // For Service Contracts SAP send Tax for 1 unit, have to multiply per quantity to get whole Tax
            taxAmount = taxAmount * quantity;
        }
        Decimal zvdiAmount = getConditionAmount(conditions, PricingConditionConstants.ZVDI, PricingConditionConstants.TYPE_CONDITIONAL);
        Decimal zslsAmount = getConditionAmount(conditions, PricingConditionConstants.ZSLS, PricingConditionConstants.TYPE_CONDITIONAL);
        Decimal ztolAmount = (zgrsAmount + zvdiAmount + zslsAmount) * quantity + taxAmount;

        return ztolAmount;
    }

    /**
     * @description Gets amount from first Pricing Condition with specified code
     * @param conditions List of all pricing conditions for the quote line
     * @param code The SAP pricing condition code to find
     * @return Amount (first occurrence) or 0 if not found
     */
    private static Decimal getConditionAmount(List<Pricing_Condition__c> conditions, String code, String type) {
        for (Pricing_Condition__c pc : conditions) {
            if (pc.SAP_Pricing_Condition__c == code
                && pc.Condition_Type__c == type
                && pc.SAP_Unit_Price__c != null
            ) {
                return pc.SAP_Unit_Price__c;
            }
        }
        return 0;
    }

    /**
     * @description Calculates tax amount based on regional tax codes
     * Takes only ONE record per code (eliminates duplicate codes)
     * Priority: MWST > Japan (ZOIG+ZAIG) > Brazil (BX13+BX23+BX51+BX72+BX82) > North America (XR1-XR6)
     * @param conditions List of pricing conditions for the quote line
     * @return Calculated tax amount
     */
    private static Decimal calculateTaxAmount(List<Pricing_Condition__c> conditions) {
        Decimal taxAmount = 0;
        Boolean taxFound = false;
        
        // Build a map of condition codes to FIRST amount only (eliminates duplicate codes)
        Map<String, Decimal> conditionMap = new Map<String, Decimal>();
        
        for (Pricing_Condition__c pc : conditions) {
            if (pc.SAP_Pricing_Condition__c != null &&
                pc.SAP_Net_Price__c != null &&
                pc.Condition_Type__c == PricingConditionConstants.TYPE_DEFAULT) {

                // Only take first occurrence of each code (ignore duplicates)
                String code = pc.SAP_Pricing_Condition__c;
                if (!conditionMap.containsKey(code)) {
                    conditionMap.put(code, pc.SAP_Net_Price__c);
                }
            }
        }
        
        // Priority 1: MWST (most countries)
        if (!taxFound && conditionMap.containsKey(PricingConditionConstants.MWST)) {
            taxAmount = conditionMap.get(PricingConditionConstants.MWST);
            taxFound = true;
        }
        
        // Priority 2: Japan (ZOIG + ZAIG)
        if (!taxFound && hasAnyCondition(conditionMap, TAX_CODES_JAPAN)) {
            taxAmount = sumConditions(conditionMap, TAX_CODES_JAPAN);
            taxFound = true;
        }
        
        // Priority 3: Brazil (BX13 + BX23 + BX51 + BX72 + BX82)
        if (!taxFound && hasAnyCondition(conditionMap, TAX_CODES_BRAZIL)) {
            taxAmount = sumConditions(conditionMap, TAX_CODES_BRAZIL);
            taxFound = true;
        }
        
        // Priority 4: North America (XR1 + XR2 + XR3 + XR4 + XR5 + XR6)
        if (!taxFound && hasAnyCondition(conditionMap, TAX_CODES_NORTH_AMERICA)) {
            taxAmount = sumConditions(conditionMap, TAX_CODES_NORTH_AMERICA);
            taxFound = true;
        }
        
        return taxAmount;
    }

    /**
     * @description Checks if any of the specified condition codes exist in the map
     */
    private static Boolean hasAnyCondition(Map<String, Decimal> conditionMap, Set<String> codes) {
        for (String code : codes) {
            if (conditionMap.containsKey(code)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Sums the values of specified condition codes from the map
     */
    private static Decimal sumConditions(Map<String, Decimal> conditionMap, Set<String> codes) {
        Decimal sum = 0;
        for (String code : codes) {
            if (conditionMap.containsKey(code)) {
                sum += conditionMap.get(code);
            }
        }
        return sum;
    }

    /**
     * @description Creates a new Pricing Condition record with standard fields
     * @param quoteLine The quote line to associate with
     * @param sapPricingCondition The SAP pricing condition code (ZGRS or ZTOL)
     * @return New Pricing_Condition__c record populated with data
     */
    private static Pricing_Condition__c createPricingCondition(
        SBQQ__QuoteLine__c quoteLine, String sapPricingCondition) {

        Pricing_Condition__c condition = new Pricing_Condition__c(
            Quote_Line__c = quoteLine.Id,
            SAP_Pricing_Condition__c = sapPricingCondition,
            SAP_CALCTYPON__c = PricingConditionConstants.CALCTYPON_C,
            Condition_Type__c = PricingConditionConstants.TYPE_DEFAULT,
            Source__c = PricingConditionConstants.SOURCE_SALESFORCE
        );

        return condition;
    }

    /**
     * @description Creates a new Pricing Condition record with standard fields
     * @param quoteLine The quote line to associate with
     * @param condition The pricing condition record to update amount
     * @param sapNetPrice The calculated SAP Net Price
     * @return New Pricing_Condition__c record populated with data
     */
    private static void populatePricingConditionPrices(
        SBQQ__QuoteLine__c quoteLine, Pricing_Condition__c condition, Decimal sapAmount) {

        String currencyIsoCode = quoteLine.SBQQ__Quote__r.CurrencyIsoCode;
        Decimal quantity = (quoteLine.SBQQ__Quantity__c != null && quoteLine.SBQQ__Quantity__c != 0)
            ? quoteLine.SBQQ__Quantity__c : 1;

        if (condition.SAP_Pricing_Condition__c == PricingConditionConstants.ZTOL) {
            // For ZTOL we have SAP_Net_Price__c amount
            condition.SAP_Unit_Price__c = sapAmount / quantity;
            condition.SAP_Net_Price__c = sapAmount;
        } else {
            // For ZGRS we have SAP_Unit_Price__c price
            condition.SAP_Unit_Price__c = sapAmount;
            condition.SAP_Net_Price__c = sapAmount * quantity;
        }

        condition.currencyIsoCode = currencyIsoCode;
    }

    /**
     * @description Processes roll-up calculations for all quote lines
     * @param quoteLines Map of quote line records
     * @param rollUpPrices Map of aggregated pricing conditions by quote line
     * @return List of quote lines that need to be updated
     */
    private static List<SBQQ__QuoteLine__c> processRollUpCalculations(
        Map<Id, SBQQ__QuoteLine__c> quoteLines,
        Map<String, Map<String, Decimal>> rollUpPrices,
        Map<Id, List<Pricing_Condition__c>> allPricingConditions) {
        
        List<SBQQ__QuoteLine__c> recordsToUpdate = new List<SBQQ__QuoteLine__c>();

        for (Id quoteLineId : quoteLines.keySet()) {
            SBQQ__QuoteLine__c quoteLine = quoteLines.get(quoteLineId);
            Map<String, Decimal> prices = rollUpPrices.containsKey(quoteLineId) 
                ? rollUpPrices.get(quoteLineId) 
                : new Map<String, Decimal>();
            List<Pricing_Condition__c> conditions = allPricingConditions.containsKey(quoteLineId)
                ? allPricingConditions.get(quoteLineId)
                : new List<Pricing_Condition__c>();
            
            manageQuoteLineRollUpPrices(quoteLine, prices, conditions, recordsToUpdate);
        }

        return recordsToUpdate;
    }

    /**
     * @description Manages the roll-up prices for a single quote line
     * @param quoteLine The quote line to process
     * @param rollUpPrices Map of field names/codes to aggregated prices
     * @param recordsToUpdate List to add updated records to
     */
    private static void manageQuoteLineRollUpPrices(
        SBQQ__QuoteLine__c quoteLine,
        Map<String, Decimal> rollUpPrices,
        List<Pricing_Condition__c> conditions,
        List<SBQQ__QuoteLine__c> recordsToUpdate) {

        Boolean quoteLineChanged = false;
        SBQQ__QuoteLine__c quoteLineToUpdate = new SBQQ__QuoteLine__c(
            Id = quoteLine.Id
        );

        // Get Sales Type and Item Class for special logic
        Decimal quantity = (quoteLine.SBQQ__Quantity__c != null && quoteLine.SBQQ__Quantity__c != 0)
            ? quoteLine.SBQQ__Quantity__c : 1;
        Boolean isServiceContract = (quoteLine.SBQQ__Quote__r.SalesType__c == PricingConditionConstants.SALES_TYPE_SERVICE_CONTRACTS);
        Boolean isFreightOrSpecial = PricingConditionConstants.isFreightOrSpecialProductCode(quoteLine.SBQQ__ProductCode__c);
        String codeZSPB = rollupCodeForField(PricingConditionConstants.ZSPB, 'SAP_Deal_Price__c');
        Boolean hasDealPrice = (rollUpPrices.containsKey(codeZSPB) && rollUpPrices.get(codeZSPB) != 0);

        for (String fieldName : rollupFields.keySet()) {
            Decimal oldPrice = (Decimal)quoteLine.get(fieldName);
            Decimal newPrice;

            // Ignore SAP_Gross_Amount__c for isFreightOrSpecial
            if (fieldName == 'SAP_Gross_Amount__c' && isFreightOrSpecial) {
                continue;
            }

            Set<String> codes = rollupFields.get(fieldName);
            Boolean hasRollupPrice = false;
            Decimal sum = 0;
            for (String code : codes) {
                String rollupCode = rollupCodeForField(code, fieldName);
                if (rollUpPrices.containsKey(rollupCode)) {
                    hasRollupPrice = true;
                    sum += rollUpPrices.get(rollupCode);
                }
            }
            if (hasRollupPrice) {
                // Divide by Quantity calculated value for discounts
                if (fieldName == 'SAP_Contract_Discount_Amount__c'
                ) {
                    newPrice = - sum / quantity;
                } else if (fieldName == 'SAP_Promotions_Unit_Amount__c'
                    || fieldName == 'SAP_Deal_Price__c'
                ) {
                    newPrice = sum / quantity;
                } else {
                    newPrice = sum;
                }

                // Clear SAP_Contract_Discount_Amount__c and SAP_Contract_Discount_Percentage__c
                // when there is Deal Price
                if ((fieldName == 'SAP_Contract_Discount_Amount__c'
                    || fieldName == 'SAP_Contract_Discount_Percentage__c')
                    && hasDealPrice) {
                    newPrice = null;
                }
            }

            if (checkPricesChanged(oldPrice, newPrice)) {
                quoteLineToUpdate.put(fieldName, newPrice);
                quoteLineChanged = true;
            }
        }

        // Special logic for SAP_Net_Unit_Price__c - handled outside the main loop
        // Determine which pricing condition to use based on Sales Type
        // Service Contracts: Use NETP, Non-Service Contracts (POS, Consumables): Use PNTP
        // Update SAP_Net_Unit_Price__c if value changed (or clear if no condition exists)
        Decimal oldNetPrice = quoteLine.SAP_Net_Unit_Price__c;
        Decimal netPrice = null;
        String netPriceCode = rollupCodeForField(
            (isServiceContract) ? PricingConditionConstants.NETP : PricingConditionConstants.PNTP, 'SAP_Net_Unit_Price__c');
        if (rollUpPrices.containsKey(netPriceCode)) {
            netPrice = rollUpPrices.get(netPriceCode);
        }
        if (checkPricesChanged(oldNetPrice, netPrice)) {
            quoteLineToUpdate.SAP_Net_Unit_Price__c = netPrice;
            quoteLineChanged = true;
        }

        // Special logic for SAP_Gross_Amount__c - handled for Freight or Special Products
        // ZGRS contains discounts, that should not be included twice in pricing waterfall
        // SBQQ__ListPrice__c is used directly
        if (isFreightOrSpecial) {
            Decimal amount = quoteLine.SBQQ__ListPrice__c;
            Decimal oldAmount = quoteLine.SAP_Gross_Amount__c;
            if (checkPricesChanged(oldAmount, amount)) {
                quoteLineToUpdate.SAP_Gross_Amount__c = amount;
                quoteLineChanged = true;
            }
        }

        // Process Tax_Amount__c (special logic)
        Decimal taxAmount = 0;
        if (!quoteLine.SBQQ__Bundled__c) {
            taxAmount = calculateTaxAmount(conditions);
            if (isServiceContract) {
                // For Service Contracts SAP send Tax for 1 unit, have to multiply per quantity to get whole Tax
                taxAmount = taxAmount * quantity;
            }
        }
        Decimal oldTax = quoteLine.Tax_Amount__c;
        if (checkPricesChanged(oldTax, taxAmount)) {
            quoteLineToUpdate.put('Tax_Amount__c', taxAmount);
            quoteLineChanged = true;
        }

        // Process IPI fields (IPVA)
        String codeIPVA = rollupCodeForField(PricingConditionConstants.IPVA, 'IPI_Percentage__c');
        if (!quoteLine.SBQQ__Bundled__c && rollUpPrices.containsKey(codeIPVA)) {
            // IPI_Amount__c = SAP Net Price from BX23
            String codeBX23 = rollupCodeForField(PricingConditionConstants.BX23, 'IPI_Amount__c');
            Decimal ipvaAmount = rollUpPrices.get(codeBX23);
            if (ipvaAmount == null) {
                ipvaAmount = 0;
            }
            if (isServiceContract) {
                ipvaAmount = ipvaAmount * quantity;
            }
            if (checkPricesChanged(quoteLine.IPI_Amount__c, ipvaAmount)) {
                quoteLineToUpdate.put('IPI_Amount__c', ipvaAmount);
                quoteLineChanged = true;
            }

            // IPI_Percentage__c = SAP Percentage from IPVA
            Decimal ipvaPercentage = rollUpPrices.get(codeIPVA);
            if (checkPricesChanged(quoteLine.IPI_Percentage__c, ipvaPercentage)) {
                quoteLineToUpdate.put('IPI_Percentage__c', ipvaPercentage);
                quoteLineChanged = true;
            }
        } else {
            // Clear IPI fields if no IPVA condition
            if (quoteLine.IPI_Amount__c != null) {
                quoteLineToUpdate.put('IPI_Amount__c', null);
                quoteLineChanged = true;
            }
            if (quoteLine.IPI_Percentage__c != null) {
                quoteLineToUpdate.put('IPI_Percentage__c', null);
                quoteLineChanged = true;
            }
        }

        if (quoteLineChanged) {
            recordsToUpdate.add(quoteLineToUpdate);
        }
    }

    private static String rollupCodeForField(String code, String fieldName) {
        return code + ':' + rollupPriceField.get(fieldName);
    }

    /**
     * @description Checks if price values have changed
     * @param oldPrice Previous price value
     * @param newPrice New price value
     * @return true if prices are different, false otherwise
     */
    private static Boolean checkPricesChanged(Decimal oldPrice, Decimal newPrice) {
        if (oldPrice == null && newPrice == null) {
            return false;
        } else if (oldPrice == null || newPrice == null) {
            return true;
        } else {
            return oldPrice != newPrice;
        }
    }

    /**
     * @description Helper method to query Pricing_Condition__c and group records by Quote_Line__c and SAP_Pricing_Condition__c
     * Saves summed amounts for every Quote_Line__c field based on Default Pricing_Condition__c records
     * @param quoteId The quote ID to query conditions for
     * @param type The condition type to filter by
     * @return Map of quote line ID to map of code/field to aggregated price
     */
    private static Map<String, Map<String, Decimal>> fetchRollUpPrices(String quoteId, String type) {
        Map<String, Map<String, Decimal>> rollUpPrices = new Map<String, Map<String, Decimal>>();

        // Cannot use convertCurrency inside SUM() - Salesforce limitation
        // Query individual records and sum manually to preserve currency
        Map<String, List<Pricing_Condition__c>> conditionsByLineAndCode = new Map<String, List<Pricing_Condition__c>>();
        
        for (Pricing_Condition__c pc : [
            SELECT SAP_Pricing_Condition__c, Quote_Line__c, SAP_Unit_Price__c, SAP_Net_Price__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__r.SBQQ__Quote__c = :quoteId
            AND Condition_Type__c = :type
        ]) {
            String key = pc.Quote_Line__c + '_' + pc.SAP_Pricing_Condition__c;
            if (!conditionsByLineAndCode.containsKey(key)) {
                conditionsByLineAndCode.put(key, new List<Pricing_Condition__c>());
            }
            conditionsByLineAndCode.get(key).add(pc);
        }
        
        // Manually sum to preserve currency
        for (String key : conditionsByLineAndCode.keySet()) {
            List<Pricing_Condition__c> conditions = conditionsByLineAndCode.get(key);
            if (conditions.isEmpty()) {
                continue;
            }
            
            Pricing_Condition__c first = conditions[0];
            String quoteLineId = first.Quote_Line__c;
            String code = first.SAP_Pricing_Condition__c;

            // Store results
            if (!rollUpPrices.containsKey(quoteLineId)) {
                rollUpPrices.put(quoteLineId, new Map<String, Decimal>());
            }

            if (code == PricingConditionConstants.IPVA) {
                // Special handling for IPVA percentage stored on SAP_Unit_Price__c
                Decimal maxPercentage = 0;
                for (Pricing_Condition__c pc : conditions) {
                    if (pc.SAP_Unit_Price__c != null && pc.SAP_Unit_Price__c > maxPercentage) {
                        maxPercentage = pc.SAP_Unit_Price__c;
                    }
                }
                rollUpPrices.get(quoteLineId).put(code + ':' + ROLLUP_UNIT_PRICE, maxPercentage);
            } else {
                // Sum SAP_Unit_Price__c or SAP_Net_Price__c
                Decimal unit = 0;
                Decimal net = 0;
                for (Pricing_Condition__c pc : conditions) {
                    if (unitCodes.contains(code) && pc.SAP_Unit_Price__c != null) {
                        unit += pc.SAP_Unit_Price__c;
                    }
                    if (netCodes.contains(code) && pc.SAP_Net_Price__c != null) {
                        net += pc.SAP_Net_Price__c;
                    }
                }
                if (unit != 0) {
                    rollUpPrices.get(quoteLineId).put(code + ':' + ROLLUP_UNIT_PRICE, unit);
                }
                if (net != 0) {
                    rollUpPrices.get(quoteLineId).put(code + ':' + ROLLUP_NET_PRICE, net);
                }
            }
        }
        
        return rollUpPrices;
    }

    /**
     * @description Helper method to query SBQQ__QuoteLine__c records with all SAP pricing fields
     * Also retrieves Quote information needed for Pricing Condition creation (Currency)
     * @param quoteId The quote ID to query lines for
     * @return Map of quote line ID to quote line record
     */
    private static Map<Id, SBQQ__QuoteLine__c> fetchQuoteLines(String quoteId) {
        return new Map<Id, SBQQ__QuoteLine__c>([
            SELECT Id, SBQQ__ListPrice__c, SBQQ__NetPrice__c, SBQQ__Quote__c,
                SBQQ__Quote__r.CurrencyIsoCode, SBQQ__Quote__r.SalesType__c, SBQQ__Quantity__c,
                Item_Class__c, SBQQ__ProductCode__c, SBQQ__Bundled__c,
                SAP_List_Unit_Price__c, SAP_Promotions_Unit_Amount__c, SAP_Gross_Amount__c,
                SAP_Contract_Discount_Amount__c, SAP_Contract_Discount_Percentage__c,
                SAP_Net_Unit_Price__c, SAP_Item_Freight__c, SAP_Surcharge__c, SAP_Total_Amount__c, Tax_Amount__c,
                IPI_Percentage__c, IPI_Amount__c, SAP_Deal_Price__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
        ]);
    }

}
/**
 * Batch class to process Service Contract renewals
 * Runs weekly to create Opportunities and Quotes for contracts nearing expiration
 * ENHANCED VERSION WITH SBQQ TRIGGER BYPASS
 */
public class ContractRenewalBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Track statistics
    private Integer contractsProcessed = 0;
    private Integer opportunitiesCreated = 0;
    private Integer quotesCreated = 0;
    private Integer quoteLinesCreated = 0;
    private Integer pricingConditionsCreated = 0;
    private List<String> errors = new List<String>();
    
    /**
     * Start method - Query Service Contracts that need renewal
     * Excludes contracts that already have associated opportunities
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        Integer advance = 120;
        Integer period = 7;
        Batch_Contract_Renewal_Settings__c batchSettings = Batch_Contract_Renewal_Settings__c.getOrgDefaults();
        if (batchSettings.In_Advance_Days__c != null) {
            advance = Integer.valueOf(batchSettings.In_Advance_Days__c);
        }
        if (batchSettings.Period__c != null) {
            period = Integer.valueOf(batchSettings.Period__c);
        }

        // Optional Territory filter
        String territory, superTerritory, subTerritory, globalTerritory, countryCode;
        if (String.isNotBlank(batchSettings.fxPKICountryISOAlpha2__c)) {
            countryCode = batchSettings.fxPKICountryISOAlpha2__c;
        }
        if (String.isNotBlank(batchSettings.fxPKITerritory__c)) {
            territory = batchSettings.fxPKITerritory__c;
        }
        if (String.isNotBlank(batchSettings.fxPKISuperTerritory__c)) {
            superTerritory = batchSettings.fxPKISuperTerritory__c;
        }
        if (String.isNotBlank(batchSettings.fxPKISubTerritory__c)) {
            subTerritory = batchSettings.fxPKISubTerritory__c;
        }
        if (String.isNotBlank(batchSettings.fxPKIGlobalTerritory__c)) {
            globalTerritory = batchSettings.fxPKIGlobalTerritory__c;
        }

        // Calculate the target date range
        Date targetStartDate = Date.today().addDays(advance);
        Date targetEndDate = Date.today().addDays(advance + period);

        // Query parent contracts with related Opportunities to filter in execute()
        String query = 
            'SELECT Id, Name, OwnerId, SVMXC__Sales_Rep__c, SMAX_PS_SalesRepName__c, ' +
            '       SVMXC__Company__c, ' +
            '       SVMXC__Company__r.Name, ' +
            '       SVMXC__Company__r.fxPKITerritory__c, ' +
            '       SVMXC__Company__r.CurrencyIsoCode, ' +
            '       SVMXC__Company__r.fxPKICountryISOAlpha3__c, ' +
            '       SVMXC__Contact__c, ' +
            '       SVMXC__End_Date__c, ' +
            '       SVMXC__Service_Pricebook__c, ' +
            '       SVMX_PS_External_ID__c, ' +
            '       SMAX_PS_SalesOrg__c, ' +
            '       SMAX_PS_ItemPrice__c, ' +
            '       SVMX_PS_Parent_Contract__c, ' +
            '       (SELECT Id FROM Opportunities__r LIMIT 1) ' +
            'FROM SVMXC__Service_Contract__c ';
        String conditions =
            'WHERE SMAX_PS_ItemCategory__c != \'MVN\' ' +
            '  AND SMAX_PS_ContractType__c != \'ZOSC\' ' +
            '  AND SVMX_PS_Parent_Contract__c = null ' +
            '  AND SVMXC__End_Date__c >= :targetStartDate ' +
            '  AND SVMXC__End_Date__c <= :targetEndDate ';
        if (String.isNotBlank(countryCode)) {
            conditions += ' AND SVMXC__Company__r.fxPKICountryISOAlpha2__c = :countryCode ';
        }
        if (String.isNotBlank(territory)) {
            conditions += ' AND SVMXC__Company__r.fxPKITerritory__c = :territory ';
        }
        if (String.isNotBlank(superTerritory)) {
            conditions += ' AND SVMXC__Company__r.fxPKISuperTerritory__c = :superTerritory ';
        }
        if (String.isNotBlank(subTerritory)) {
            conditions += ' AND SVMXC__Company__r.fxPKISubTerritory__c = :subTerritory ';
        }
        if (String.isNotBlank(globalTerritory)) {
            conditions += ' AND SVMXC__Company__r.fxPKIGlobalTerritory__c = :globalTerritory ';
        }

        query += conditions;
        query += 'ORDER BY SVMXC__End_Date__c, Name';
        
        System.debug('Query: ' + query);
        System.debug('Conditions: ' + conditions);
        System.debug('Target Date Range: ' + targetStartDate + ' to ' + targetEndDate);

        return Database.getQueryLocator(query);
    }
    
    /**
     * Execute method - Process each batch of Service Contracts
     */
    public void execute(Database.BatchableContext bc, List<SVMXC__Service_Contract__c> scope) {
        
        System.debug('=== EXECUTE METHOD START ===');
        System.debug('Scope size: ' + scope.size());
        
        // Filter out contracts that already have opportunities
        Map<Id, SVMXC__Service_Contract__c> contractsToProcess = new Map<Id, SVMXC__Service_Contract__c>();
        for (SVMXC__Service_Contract__c contract : scope) {
            if (contract.Opportunities__r == null || contract.Opportunities__r.isEmpty()) {
                contractsToProcess.put(contract.Id, contract);
            } else {
                System.debug('Skipping contract ' + contract.Name + ' - already has opportunity');
            }
        }
        
        if (contractsToProcess.isEmpty()) {
            System.debug('No contracts to process after filtering');
            return;
        }
        
        System.debug('Processing ' + contractsToProcess.size() + ' contracts');
        
        // DISABLE SBQQ TRIGGERS TO AVOID QUEUEABLE JOB LIMITS
        SBQQ.TriggerControl.disable();
        System.debug('SBQQ Triggers Disabled');
        
        try {
            // Query active pricebooks (once per batch)
            List<Pricebook2> activePricebooks = [
                SELECT Id, Name, IsActive
                FROM Pricebook2
                WHERE IsActive = true
            ];
            System.debug('Active pricebooks found: ' + activePricebooks.size());
            
            // Query child contracts for all parent contracts in scope
            Set<Id> parentContractIds = contractsToProcess.keySet();
            System.debug('Parent contract IDs: ' + parentContractIds.size());
            
            Map<Id, List<SVMXC__Service_Contract__c>> parentToChildContracts = new Map<Id, List<SVMXC__Service_Contract__c>>();
            List<SVMXC__Service_Contract__c> allChildContracts = [
                SELECT Id, Name, SMAX_PS_ItemPrice__c, SVMX_PS_Parent_Contract__c
                FROM SVMXC__Service_Contract__c
                WHERE SVMX_PS_Parent_Contract__c IN :parentContractIds
                AND Active_Today__c = TRUE
            ];
            
            System.debug('Child contracts found: ' + allChildContracts.size());
            
            for (SVMXC__Service_Contract__c childContract : allChildContracts) {
                if (!parentToChildContracts.containsKey(childContract.SVMX_PS_Parent_Contract__c)) {
                    parentToChildContracts.put(childContract.SVMX_PS_Parent_Contract__c, new List<SVMXC__Service_Contract__c>());
                }
                parentToChildContracts.get(childContract.SVMX_PS_Parent_Contract__c).add(childContract);
            }
            
            System.debug('Parent to child map populated. Keys: ' + parentToChildContracts.keySet().size());

            // Limit contracts to process - with only active not deleted children
            for (Id parentContractId : parentContractIds) {
                if (!parentToChildContracts.containsKey(parentContractId)) {
                    contractsToProcess.remove(parentContractId);
                }
            }

            // Collect all child contract IDs for bulk queries
            Set<Id> allChildContractIds = new Set<Id>();
            for (List<SVMXC__Service_Contract__c> children : parentToChildContracts.values()) {
                for (SVMXC__Service_Contract__c child : children) {
                    allChildContractIds.add(child.Id);
                }
            }
            System.debug('Total child contract IDs collected: ' + allChildContractIds.size());
            
            // Query Service Contract Products for all child contracts
            Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts = new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
            List<SVMXC__Service_Contract_Products__c> allProducts = [
                SELECT Id, SVMXC__Service_Contract__c, SVMXC__Installed_Product__c,
                       SVMXC__Installed_Product__r.SMAX_PS_ModelNumber__c,
                       SVMXC__Installed_Product__r.SVMXC__Product__c,
                       SVMXC__Installed_Product__r.SVMXC__Product__r.ProductCode,
                       SVMXC__Installed_Product__r.SVMXC__Product__r.product_line__c,
                       SVMXC__Installed_Product__r.SVMXC__Product__r.Item_Class__c,
                       SVMXC__Installed_Product__r.SVMXC__Product__r.IGOR_PAC__c,
                       SVMXC__Installed_Product__r.SVMXC__Serial_Lot_Number__c,
                       SMAX_PS_SLA_Terms_Notes__c
                FROM SVMXC__Service_Contract_Products__c
                WHERE SVMXC__Service_Contract__c IN :allChildContractIds
                AND SVMXC__Installed_Product__c != NULL
            ];
            
            System.debug('Contract products found: ' + allProducts.size());

            for (SVMXC__Service_Contract_Products__c prod : allProducts) {
                if (!contractProducts.containsKey(prod.SVMXC__Service_Contract__c)) {
                    contractProducts.put(prod.SVMXC__Service_Contract__c, new List<SVMXC__Service_Contract_Products__c>());
                }
                contractProducts.get(prod.SVMXC__Service_Contract__c).add(prod);
            }

            // Collect all Product Codes
            Set<String> productCodes = ContractRenewalDataManagement.collectProductCodes(allProducts);

            // Query all products and setup map by ProductCode
            Map<String, Product2> productMap = new Map<String, Product2>();
            Set<Id> productIds = new Set<Id>();
            for (Product2 prod : [
                SELECT Id, ProductCode, product_line__c, Item_Class__c, IGOR_PAC__c
                FROM Product2
                WHERE ProductCode IN :productCodes
                AND IsActive = TRUE
                AND Item_Class__c = 'F'
            ]) {
                productMap.put(prod.ProductCode, prod);
                productIds.add(prod.Id);
            }

            System.debug('Product Codes collected: ' + productCodes.size());
            System.debug('Products collected: ' + productMap.size());

            // Query Contact AccountIds for validation
            Set<Id> contactIds = new Set<Id>();
            for (SVMXC__Service_Contract__c contract : contractsToProcess.values()) {
                if (contract.SVMXC__Contact__c != null) {
                    contactIds.add(contract.SVMXC__Contact__c);
                }
            }
            
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            if (!contactIds.isEmpty()) {
                contactMap = new Map<Id, Contact>([
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id IN :contactIds
                ]);
            }

            // Process each contract
            List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
            Map<Integer, SVMXC__Service_Contract__c> indexToContract = new Map<Integer, SVMXC__Service_Contract__c>();
            
            Integer index = 0;
            for (SVMXC__Service_Contract__c contract : contractsToProcess.values()) {
                Id salesRepId = ContractRenewalUserManager.getSalesRep(
                    contract.SMAX_PS_SalesRepName__c, contract.SVMXC__Company__r.fxPKITerritory__c
                );
                Opportunity opp = ContractRenewalDataManagement.createOpportunity(contract, salesRepId, activePricebooks);
                opportunitiesToInsert.add(opp);
                indexToContract.put(index, contract);
                index++;
            }
            
            // Insert Opportunities
            insert opportunitiesToInsert;
            opportunitiesCreated += opportunitiesToInsert.size();
            System.debug('Opportunities inserted: ' + opportunitiesToInsert.size());
            
            // Create Opportunity Contact Roles
            List<OpportunityContactRole> contactRolesToInsert = new List<OpportunityContactRole>();
            for (Integer i = 0; i < opportunitiesToInsert.size(); i++) {
                SVMXC__Service_Contract__c contract = indexToContract.get(i);
                Opportunity opp = opportunitiesToInsert.get(i);
                
                if (contract.SVMXC__Contact__c != null) {
                    OpportunityContactRole ocr = ContractRenewalDataManagement.createOpportunityContactRole(
                        opp.Id, 
                        contract.SVMXC__Contact__c
                    );
                    if (ocr != null) {
                        contactRolesToInsert.add(ocr);
                    }
                }
            }
            
            if (!contactRolesToInsert.isEmpty()) {
                insert contactRolesToInsert;
                System.debug('Contact roles inserted: ' + contactRolesToInsert.size());
            }
            
            // Create Quotes with contactAccountId
            List<SBQQ__Quote__c> quotesToInsert = new List<SBQQ__Quote__c>();
            Map<Integer, Opportunity> indexToOpportunity = new Map<Integer, Opportunity>();
            
            for (Integer i = 0; i < opportunitiesToInsert.size(); i++) {
                SVMXC__Service_Contract__c contract = indexToContract.get(i);
                Opportunity opp = opportunitiesToInsert.get(i);
                
                // Get contactAccountId from contactMap
                Id contactAccountId = null;
                if (contract.SVMXC__Contact__c != null && contactMap.containsKey(contract.SVMXC__Contact__c)) {
                    contactAccountId = contactMap.get(contract.SVMXC__Contact__c).AccountId;
                }
                
                Id salesRepId = ContractRenewalUserManager.getSalesRep(
                    contract.SMAX_PS_SalesRepName__c, contract.SVMXC__Company__r.fxPKITerritory__c
                );
                SBQQ__Quote__c quote = ContractRenewalDataManagement.createQuote(
                    contract,
                    salesRepId,
                    opp.Id, 
                    contactAccountId,
                    opp.Pricebook2Id
                );
                quotesToInsert.add(quote);
                indexToOpportunity.put(i, opp);
            }
            
            // Insert Quotes
            insert quotesToInsert;
            quotesCreated += quotesToInsert.size();
            System.debug('Quotes inserted: ' + quotesToInsert.size());

            // Sync Quote errors to Opportunity after insert
            for (SBQQ__Quote__c quote : quotesToInsert) {
                if (String.isNotBlank(quote.Contract_Renewal_Error_Log__c)) {
                    ContractRenewalDataManagement.syncQuoteErrorsToOpportunity(quote);
                }
            }
            
            // Create Quote Lines with error handling
            List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
            Map<Integer, SBQQ__Quote__c> quoteLineIndexToQuote = new Map<Integer, SBQQ__Quote__c>();
            Map<Integer, List<SVMXC__Service_Contract_Products__c>> quoteLineIndexToProducts = new Map<Integer, List<SVMXC__Service_Contract_Products__c>>();
            
            System.debug('=== STARTING QUOTE LINE CREATION ===');
            System.debug('Number of quotes to process: ' + quotesToInsert.size());
            
            Integer quoteLineIndex = 0;
            for (Integer i = 0; i < quotesToInsert.size(); i++) {
                SVMXC__Service_Contract__c contract = indexToContract.get(i);
                SBQQ__Quote__c quote = quotesToInsert.get(i);
                Opportunity opp = indexToOpportunity.get(i);
                
                System.debug('--- Processing Quote #' + i + ' ---');
                System.debug('Contract: ' + contract.Name + ', Quote: ' + quote.Id);
                
                List<SVMXC__Service_Contract__c> childContracts = parentToChildContracts.get(contract.Id);
                
                if (childContracts != null && !childContracts.isEmpty()) {
                    // Query pricebook entries for this opportunity's pricebook
                    Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>();
                    if (opp.Pricebook2Id != null) {
                        for (PricebookEntry pbe : [
                            SELECT Id, Product2Id 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :opp.Pricebook2Id 
                            AND Product2Id IN :productIds 
                            AND IsActive = true
                        ]) {
                            pricebookEntryMap.put(pbe.Product2Id, pbe);
                        }
                    }
                    
                    System.debug('Child contracts: ' + childContracts.size() + ', Pricebook entries: ' + pricebookEntryMap.size());
                    
                    // Use createQuoteLinesWithErrorHandling wrapper method
                    List<SBQQ__QuoteLine__c> quoteLines = ContractRenewalDataManagement.createQuoteLinesWithErrorHandling(
                        childContracts,
                        quote.Id,
                        opp.Id,
                        contractProducts,
                        pricebookEntryMap,
                        productMap,
                        opp.Pricebook2Id
                    );
                    
                    System.debug('Quote lines created: ' + quoteLines.size());
                    
                    // Map quote lines to their data
                    if (quoteLines != null) {
                        for (Integer j = 0; j < quoteLines.size(); j++) {
                            SBQQ__QuoteLine__c quoteLine = quoteLines[j];
                            SVMXC__Service_Contract__c childContract = childContracts[j];
                            
                            quoteLinesToInsert.add(quoteLine);
                            quoteLineIndexToQuote.put(quoteLineIndex, quote);
                            
                            List<SVMXC__Service_Contract_Products__c> products = contractProducts.get(childContract.Id);
                            if (products != null && !products.isEmpty()) {
                                quoteLineIndexToProducts.put(quoteLineIndex, products);
                            }
                            
                            quoteLineIndex++;
                        }
                    }
                }
            }
            
            System.debug('Total quote lines to insert: ' + quoteLinesToInsert.size());
            
            // Insert Quote Lines in chunks to avoid queueable limits
            if (!quoteLinesToInsert.isEmpty()) {
                // Insert quote lines in smaller chunks if needed
                Integer chunkSize = 200; // Adjust based on your needs
                List<SBQQ__QuoteLine__c> insertedQuoteLines = new List<SBQQ__QuoteLine__c>();
                
                for (Integer i = 0; i < quoteLinesToInsert.size(); i += chunkSize) {
                    Integer endIndex = Math.min(i + chunkSize, quoteLinesToInsert.size());
                    List<SBQQ__QuoteLine__c> chunk = new List<SBQQ__QuoteLine__c>();
                    
                    for (Integer j = i; j < endIndex; j++) {
                        chunk.add(quoteLinesToInsert[j]);
                    }
                    
                    System.debug('Inserting quote line chunk: ' + (i/chunkSize + 1) + ' (' + chunk.size() + ' records)');
                    insert chunk;
                    insertedQuoteLines.addAll(chunk);
                    quoteLinesCreated += chunk.size();
                }
                
                System.debug('Quote lines successfully inserted: ' + quoteLinesCreated);
                
                // Create Pricing Conditions
                List<Pricing_Condition__c> pricingConditionsToInsert = new List<Pricing_Condition__c>();
                Map<Id, SVMXC__Service_Contract_Products__c> quoteLineToProductMap = new Map<Id, SVMXC__Service_Contract_Products__c>();
                
                // Build a map of Quote to Currency for efficiency
                Set<Id> quoteIds = new Set<Id>();
                for (Integer i = 0; i < insertedQuoteLines.size(); i++) {
                    SBQQ__Quote__c quote = quoteLineIndexToQuote.get(i);
                    if (quote != null) {
                        quoteIds.add(quote.Id);
                    }
                }
                
                Map<Id, String> quoteToCurrency = new Map<Id, String>();
                for (SBQQ__Quote__c q : [SELECT Id, CurrencyIsoCode FROM SBQQ__Quote__c WHERE Id IN :quoteIds]) {
                    quoteToCurrency.put(q.Id, q.CurrencyIsoCode);
                }
                
                for (Integer i = 0; i < insertedQuoteLines.size(); i++) {
                    SBQQ__QuoteLine__c quoteLine = insertedQuoteLines.get(i);
                    SBQQ__Quote__c quote = quoteLineIndexToQuote.get(i);
                    List<SVMXC__Service_Contract_Products__c> products = quoteLineIndexToProducts.get(i);
                    
                    if (products != null && !products.isEmpty()) {
                        SVMXC__Service_Contract_Products__c contractProduct = products[0];
                        
                        String currencyCode = quoteToCurrency.get(quote.Id);
                        
                        List<Pricing_Condition__c> pricingConditions = ContractRenewalDataManagement.createPricingConditions(
                            contractProduct,
                            quoteLine.Id,
                            currencyCode
                        );
                        
                        pricingConditionsToInsert.addAll(pricingConditions);
                        quoteLineToProductMap.put(quoteLine.Id, contractProduct);
                    }
                }
                
                // Insert Pricing Conditions
                if (!pricingConditionsToInsert.isEmpty()) {
                    insert pricingConditionsToInsert;
                    pricingConditionsCreated += pricingConditionsToInsert.size();
                    System.debug('Pricing conditions inserted: ' + pricingConditionsCreated);
                }
                
                // Update Quote Lines with SAP codes
                if (!quoteLineToProductMap.isEmpty()) {
                    ContractRenewalDataManagement.updateQuoteLinesWithSAPCodes(quoteLineToProductMap);
                }
            }
            
            contractsProcessed += contractsToProcess.size();
            
        } catch (Exception e) {
            String errorMsg = 'Error processing batch: ' + e.getMessage() + '\n' + e.getStackTraceString();
            errors.add(errorMsg);
            System.debug(LoggingLevel.ERROR, errorMsg);
        } finally {
            // RE-ENABLE SBQQ TRIGGERS
            SBQQ.TriggerControl.enable();
            System.debug('SBQQ Triggers Re-enabled');
        }
        
        System.debug('=== EXECUTE METHOD END ===');
    }
    
    /**
     * Finish method - Send summary email
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('=== BATCH SUMMARY ===');
        System.debug('Contracts Processed: ' + contractsProcessed);
        System.debug('Opportunities Created: ' + opportunitiesCreated);
        System.debug('Quotes Created: ' + quotesCreated);
        System.debug('Quote Lines Created: ' + quoteLinesCreated);
        System.debug('Pricing Conditions Created: ' + pricingConditionsCreated);
        
        if (!errors.isEmpty()) {
            System.debug('ERRORS: ' + errors.size());
            for (String error : errors) {
                System.debug(error);
            }
        }
    }
}
public class ContractRenewalDataManagement {
    
     /**
     * Invocable method for Flow to create Opportunity, Quote, and Quote Lines from Contract
     * @param requests List of FlowRequest objects containing Contract Id
     * @return List of FlowResult objects with created record Ids and any errors
     */
    @InvocableMethod(
        label='Create Renewal Records from Contract'
        description='Creates Opportunity, Quote, and Quote Lines from a Service Contract'
        category='Contract Renewal'
    )
    public static List<FlowResult> createRenewalRecordsFromContract(List<FlowRequest> requests) {
        List<FlowResult> results = new List<FlowResult>();
        
        for (FlowRequest request : requests) {
            FlowResult result = new FlowResult();
            result.contractId = request.contractId;
            
            try {
                // Validate input
                if (String.isBlank(request.contractId)) {
                    result.isSuccess = false;
                    result.errorMessage = 'Contract Id is required';
                    results.add(result);
                    continue;
                }
                
                // Query parent contract with all required fields
                List<SVMXC__Service_Contract__c> contracts = [
                    SELECT Id, Name, OwnerId, SVMXC__Sales_Rep__c, SMAX_PS_SalesRepName__c,
                        SVMXC__Company__c,
                        SVMXC__Company__r.Name,
                        SVMXC__Company__r.fxPKITerritory__c,
                        SVMXC__Company__r.CurrencyIsoCode,
                        SVMXC__Company__r.fxPKICountryISOAlpha3__c,
                        SVMXC__Contact__c,
                        SVMXC__End_Date__c,
                        SVMXC__Service_Pricebook__c,
                        SVMX_PS_External_ID__c,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_ItemPrice__c,
                        SVMX_PS_Parent_Contract__c
                    FROM SVMXC__Service_Contract__c
                    WHERE Id = :request.contractId
                    LIMIT 1
                ];
                
                if (contracts.isEmpty()) {
                    result.isSuccess = false;
                    result.errorMessage = 'Contract not found with Id: ' + request.contractId;
                    results.add(result);
                    continue;
                }
                
                SVMXC__Service_Contract__c parentContract = contracts[0];
                
                // Query active pricebooks
                List<Pricebook2> activePricebooks = [
                    SELECT Id, Name, IsActive
                    FROM Pricebook2
                    WHERE IsActive = true
                ];
                
                // Step 1: Create Opportunity
                Opportunity opp = ContractRenewalDataManagement.createOpportunity(
                    parentContract,
                    UserInfo.getUserId(),
                    activePricebooks
                );
                insert opp;
                result.opportunityId = opp.Id;
                result.opportunityName = opp.Name;
                
                // Step 2: Create Opportunity Contact Role
                if (parentContract.SVMXC__Contact__c != null) {
                    OpportunityContactRole ocr = ContractRenewalDataManagement.createOpportunityContactRole(
                        opp.Id,
                        parentContract.SVMXC__Contact__c
                    );
                    if (ocr != null) {
                        insert ocr;
                    }
                }
                
                // Query Contact's AccountId for Quote validation
                Id contactAccountId = null;
                if (parentContract.SVMXC__Contact__c != null) {
                    List<Contact> contacts = [
                        SELECT Id, AccountId
                        FROM Contact
                        WHERE Id = :parentContract.SVMXC__Contact__c
                        LIMIT 1
                    ];
                    if (!contacts.isEmpty()) {
                        contactAccountId = contacts[0].AccountId;
                    }
                }
                
                // Step 3: Create Quote
                SBQQ__Quote__c quote = ContractRenewalDataManagement.createQuote(
                    parentContract,
                    UserInfo.getUserId(),
                    opp.Id,
                    contactAccountId,
                    opp.Pricebook2Id
                );
                insert quote;
                result.quoteId = quote.Id;
                
                // Query Quote to get the auto-generated Name
                SBQQ__Quote__c insertedQuote = [
                    SELECT Id, Name
                    FROM SBQQ__Quote__c 
                    WHERE Id = :quote.Id 
                    LIMIT 1
                ];
                result.quoteName = insertedQuote.Name;

                // Sync any Quote errors to Opportunity
                if (String.isNotBlank(quote.Contract_Renewal_Error_Log__c)) {
                    ContractRenewalDataManagement.syncQuoteErrorsToOpportunity(quote);
                }
                
                // Step 4: Query child contracts
                List<SVMXC__Service_Contract__c> childContracts = [
                    SELECT Id, Name, SMAX_PS_ItemPrice__c
                    FROM SVMXC__Service_Contract__c
                    WHERE SVMX_PS_Parent_Contract__c = :parentContract.Id
                ];
                
                if (childContracts.isEmpty()) {
                    result.isSuccess = true;
                    result.errorMessage = 'No child contracts found. Opportunity and Quote created successfully.';
                    results.add(result);
                    continue;
                }
                
                // Step 5: Prepare data for Quote Lines
                ContractRenewalDataManagement.QuoteLineData quoteLineData = 
                    prepareQuoteLineData(childContracts, opp.Pricebook2Id);
                
                // Step 6: Create Quote Lines
                List<SBQQ__QuoteLine__c> quoteLines = 
                    ContractRenewalDataManagement.createQuoteLinesWithErrorHandling(
                        childContracts,
                        quote.Id,
                        opp.Id,
                        quoteLineData.contractProducts,
                        quoteLineData.pricebookEntries,
                        quoteLineData.products,
                        opp.Pricebook2Id
                    );
                
                if (!quoteLines.isEmpty()) {
                    insert quoteLines;
                    result.quoteLineCount = quoteLines.size();
                    
                    // Step 7: Create Pricing Conditions
                    createPricingConditionsForQuoteLines(
                        quoteLines, 
                        quoteLineData.contractProducts,
                        parentContract.SVMXC__Company__r.CurrencyIsoCode
                    );
                }
                
                result.isSuccess = true;
                result.errorMessage = 'Successfully created ' + quoteLines.size() + 
                                     ' quote lines from ' + childContracts.size() + ' child contracts.';
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.errorMessage = 'Error: ' + e.getMessage() + ' | Stack Trace: ' + e.getStackTraceString();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Helper method to prepare Quote Line data (query related records)
     * @param childContracts List of child Service Contracts
     * @param pricebook2Id The Pricebook2 Id from Opportunity
     * @return QuoteLineData object with all required data
     */
    public static ContractRenewalDataManagement.QuoteLineData prepareQuoteLineData(
        List<SVMXC__Service_Contract__c> childContracts,
        Id pricebook2Id
    ) {
        ContractRenewalDataManagement.QuoteLineData data = 
            new ContractRenewalDataManagement.QuoteLineData();
        
        // Query Service Contract Products with Installed Products
        List<SVMXC__Service_Contract_Products__c> contractProducts = [
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
            WHERE SVMXC__Service_Contract__c IN :childContracts
            AND SVMXC__Installed_Product__c != NULL
        ];
        
        // Build map of Contract Id to Products
        for (SVMXC__Service_Contract_Products__c scp : contractProducts) {
            if (!data.contractProducts.containsKey(scp.SVMXC__Service_Contract__c)) {
                data.contractProducts.put(scp.SVMXC__Service_Contract__c, 
                                         new List<SVMXC__Service_Contract_Products__c>());
            }
            data.contractProducts.get(scp.SVMXC__Service_Contract__c).add(scp);
        }

        // Collect all Product Codes
        Set<String> productCodes = collectProductCodes(contractProducts);

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
        data.products.putAll(productMap);

        // Query PricebookEntries
        if (pricebook2Id != null && !productIds.isEmpty()) {
            List<PricebookEntry> pbes = [
                SELECT Id, Product2Id, Pricebook2Id
                FROM PricebookEntry
                WHERE Product2Id IN :productIds
                AND Pricebook2Id = :pricebook2Id
                AND IsActive = true
            ];
            
            for (PricebookEntry pbe : pbes) {
                data.pricebookEntries.put(pbe.Product2Id, pbe);
            }
        }
        
        return data;
    }

    public static Set<String> collectProductCodes(List<SVMXC__Service_Contract_Products__c> contractProducts) {
        // Collect all Product Codes
        Set<String> productCodes = new Set<String>();
        for (SVMXC__Service_Contract_Products__c prod : contractProducts) {
            productCodes.addAll(collectProductCodes(prod.SVMXC__Installed_Product__r));
        }
        return productCodes;
    }

    private static Set<String> collectProductCodes(SVMXC__Installed_Product__c installedProduct) {
        Set<String> productCodes = new Set<String>();
        String productCode = installedProduct.SMAX_PS_ModelNumber__c;
        if (String.isNotBlank(productCode)) {
            productCodes.add(productCode);
        }
        if (installedProduct.SVMXC__Product__c != null) {
            String installedProductLine = installedProduct.SVMXC__Product__r.product_line__c;
            String installedProductCode = installedProduct.SVMXC__Product__r.ProductCode;
            if (String.isNotBlank(installedProductLine) && String.isNotBlank(installedProductCode)) {
                String altProductCode = (installedProductCode.startsWith(installedProductLine))
                    ? installedProductCode : installedProductLine + installedProductCode;
                if (String.isBlank(productCode) || productCode != altProductCode) {
                    productCodes.add(altProductCode);
                }
            }
        }
        return productCodes;
    }

	 /**
     * Helper method to create Pricing Conditions for Quote Lines
     * @param quoteLines List of inserted Quote Lines
     * @param contractProducts Map of Contract Id to Service Contract Products
     * @param currencyIsoCode Currency code from parent contract
     */
    public static void createPricingConditionsForQuoteLines(
        List<SBQQ__QuoteLine__c> quoteLines,
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts,
        String currencyIsoCode
    ) {
        // Query Quote Lines with Material lookup
        Map<Id, SBQQ__QuoteLine__c> quoteLinesMap = new Map<Id, SBQQ__QuoteLine__c>([
            SELECT Id, Material__c
            FROM SBQQ__QuoteLine__c
            WHERE Id IN :quoteLines
        ]);
        
        // Build a map from Installed Product ID to Contract ID using contractProducts
        Map<Id, Id> installedProductToContractMap = new Map<Id, Id>();
        for (Id contractId : contractProducts.keySet()) {
            List<SVMXC__Service_Contract_Products__c> products = contractProducts.get(contractId);
            if (products != null) {
                for (SVMXC__Service_Contract_Products__c scp : products) {
                    if (scp.SVMXC__Installed_Product__c != null) {
                        installedProductToContractMap.put(scp.SVMXC__Installed_Product__c, contractId);
                    }
                }
            }
        }
        
        List<Pricing_Condition__c> allPricingConditions = new List<Pricing_Condition__c>();
        Map<Id, SVMXC__Service_Contract_Products__c> quoteLineToProductMap = 
            new Map<Id, SVMXC__Service_Contract_Products__c>();
        
        for (SBQQ__QuoteLine__c ql : quoteLinesMap.values()) {
            if (ql.Material__c != null) {
                // Get Contract ID from the installed product
                Id contractId = installedProductToContractMap.get(ql.Material__c);
                
                if (contractId != null) {
                    List<SVMXC__Service_Contract_Products__c> products = contractProducts.get(contractId);
                    
                    if (products != null && !products.isEmpty()) {
                        // Find the specific contract product that matches this installed product
                        SVMXC__Service_Contract_Products__c contractProduct = null;
                        for (SVMXC__Service_Contract_Products__c scp : products) {
                            if (scp.SVMXC__Installed_Product__c == ql.Material__c) {
                                contractProduct = scp;
                                break;
                            }
                        }
                        
                        if (contractProduct != null) {
                            quoteLineToProductMap.put(ql.Id, contractProduct);
                            
                            List<Pricing_Condition__c> pricingConditions = 
                                ContractRenewalDataManagement.createPricingConditions(
                                    contractProduct,
                                    ql.Id,
                                    currencyIsoCode
                                );
                            
                            allPricingConditions.addAll(pricingConditions);
                        }
                    }
                }
            }
        }
        
        // Insert Pricing Conditions
        if (!allPricingConditions.isEmpty()) {
            insert allPricingConditions;
            
            // Update Quote Lines with SAP codes
            if (!quoteLineToProductMap.isEmpty()) {
                ContractRenewalDataManagement.updateQuoteLinesWithSAPCodes(quoteLineToProductMap);
            }
        }
    }	
    
    // ============================================================================
    // WRAPPER CLASSES FOR FLOW
    // ============================================================================
    
    public class FlowRequest {
        @InvocableVariable(required=true label='Contract Id' description='Parent Service Contract Id')
        public String contractId;
	}

    /**
     * Output wrapper for Flow invocable method
     */
    public class FlowResult {
        @InvocableVariable(label='Success' description='Indicates if the operation was successful')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Contract Id' description='Input Contract Id')
        public String contractId;
        
        @InvocableVariable(label='Opportunity Id' description='Created Opportunity Id')
        public String opportunityId;
        
        @InvocableVariable(label='Opportunity Name' description='Created Opportunity Name')
        public String opportunityName;
        
        @InvocableVariable(label='Quote Id' description='Created Quote Id')
        public String quoteId;
        
        @InvocableVariable(label='Quote Name' description='Created Quote Name')
        public String quoteName;
        
        @InvocableVariable(label='Quote Line Count' description='Number of Quote Lines created')
        public Integer quoteLineCount;
        
        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
    }
    
    /**
     * Creates an Opportunity from a Service Contract (without DML)
     * Optimized for batch processing - no SOQL queries, no DML
     * @param contract The Service Contract record with all required fields populated
     * @param activePricebooks List of active pricebooks (queried in batch execute method)
     * @return The Opportunity record (not inserted - batch handles bulk DML)
     */
    public static Opportunity createOpportunity(
        SVMXC__Service_Contract__c contract,
        Id salesRepId,
        List<Pricebook2> activePricebooks
    ) {
        
        // Initialize Opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = salesRepId;
        
        // Get RecordType for ServiceContract (uses describe, not SOQL)
        Id serviceContractRecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('ServiceContract')
            .getRecordTypeId();
        opp.RecordTypeId = serviceContractRecordTypeId;
        
        // Set AccountId
        opp.AccountId = contract.SVMXC__Company__c;
        
        // Set Primary Contact
        opp.Primary_Contact__c = contract.SVMXC__Contact__c;
        
        // Set Pricebook using ContractPricebookMatcher
        // Convert List to Map for the method that returns Id
        Map<Id, Pricebook2> pricebookMap = new Map<Id, Pricebook2>(activePricebooks);
        opp.Pricebook2Id = ContractPricebookMatcher.findPricebookIdForContract(
            contract, 
            pricebookMap
        );
                
        // Set CurrencyIsoCode from Account relationship
        opp.CurrencyIsoCode = contract.SVMXC__Company__r.CurrencyIsoCode;
        
        // Set Opportunity Name
        opp.Name = contract.SVMXC__Company__r.Name + 
                   ' Renewal Service Contract ' + 
                   contract.Name;
        
        // Set Service Maintenance Contract lookup
        opp.Service_Maintenance_Contract__c = contract.Id;
        
        // Set Revenue Recognition Date (TODAY + 107 days)
        opp.Revenue_Rec_Date__c = Date.today().addDays(107);
        
        // Set Type based on SVMX_PS_External_ID__c
        if (String.isNotBlank(contract.SVMX_PS_External_ID__c)) {
            String externalId = contract.SVMX_PS_External_ID__c.trim();
            
            if (externalId.startsWith('0015')) {
                opp.Type = 'Warranty Conversion';
            } else if (externalId.startsWith('0035')) {
                opp.Type = 'Renewal';
            }
        }
        
        // Set CloseDate (TODAY + 106 days)
        opp.CloseDate = Date.today().addDays(106);
        
        // Set Stage
        opp.StageName = 'Stage 1 - Create';
        
        // Return opportunity without DML (batch will handle bulk insert)
        return opp;
    }
    
    /**
     * Creates an OpportunityContactRole for the Opportunity (without DML)
     * @param opportunityId The Opportunity Id
     * @param contactId The Contact Id from the Opportunity's Primary_Contact__c field
     * @return The OpportunityContactRole record (not inserted - batch handles bulk DML)
     */
    public static OpportunityContactRole createOpportunityContactRole(
        Id opportunityId,
        Id contactId
    ) {
        
        // Check if contactId is provided
        if (contactId == null) {
            return null;
        }
        
        // Initialize OpportunityContactRole
        OpportunityContactRole ocr = new OpportunityContactRole();
        
        // Set Opportunity relationship
        ocr.OpportunityId = opportunityId;
        
        // Set Contact relationship
        ocr.ContactId = contactId;
        
        // Set as Primary Contact
        ocr.IsPrimary = true;
        
        // Return OpportunityContactRole without DML (batch will handle bulk insert)
        return ocr;
    }
    
    /**
     * Creates a Quote from a Service Contract (without DML)
     * Optimized for batch processing - no SOQL queries, no DML
     * Handles error logging internally after insert
     * @param contract The Service Contract record with all required fields populated
     * @param opportunityId The related Opportunity Id (must be created first)
     * @param contactAccountId The AccountId of the Contact (pass from batch to avoid SOQL)
     * @return The Quote record (not inserted - batch handles bulk DML)
     */
    public static SBQQ__Quote__c createQuote(
        SVMXC__Service_Contract__c contract,
        Id salesRepId,
        Id opportunityId,
        Id contactAccountId,
        Id pricebook2Id
    ) {
        
        // Initialize Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.OwnerId = salesRepId;

        // Set SalesType
        quote.SalesType__c = 'Service Contracts';
        
        // Set Account (Bill To and Ship To)
        quote.SBQQ__Account__c = contract.SVMXC__Company__c;
        quote.BD_Account_Ship_To__c = contract.SVMXC__Company__c;
        
        // Set Contacts with validation
        if (contract.SVMXC__Contact__c != null) {
            // Check if Contact belongs to the Quote Account
            if (contactAccountId == contract.SVMXC__Company__c) {
                quote.End_User_Contact__c = contract.SVMXC__Contact__c;
                quote.SBQQ__PrimaryContact__c = contract.SVMXC__Contact__c;
            } else {
                // Log error - Contact does not belong to Account
                String errorMsg = 'Contact does not belong to Account. Contact AccountId: ' + 
                                contactAccountId + ', Quote AccountId: ' + contract.SVMXC__Company__c;
                
                // Store temporarily on quote record
                quote.Contract_Renewal_Error_Log__c = formatError(errorMsg);
            }
        }
        
        // Set Primary Quote flag
        quote.SBQQ__Primary__c = true;
        
        // Set Status
        quote.SBQQ__Status__c = 'Draft';
        
        // Set SalesRep - same as Owner (will be empty if Owner is a Queue)
        quote.SBQQ__SalesRep__c = salesRepId;

        // Set Quote Type
        quote.SBQQ__Type__c = 'Renewal';
        
        // Set Payment Terms
        quote.SBQQ__PaymentTerms__c = 'Use Customer Default';
        
        // Set Contract Dates
        if (contract.SVMXC__End_Date__c != null) {
            quote.ContractStartDate__c = contract.SVMXC__End_Date__c.addDays(1);
            quote.ContractEndDate__c = contract.SVMXC__End_Date__c.addYears(1);
        }

        // Set Opportunity and Pricebook relationship
        // Both SBQQ__PriceBook__c and SBQQ__PricebookId__c has to be populated
        quote.SBQQ__Opportunity2__c = opportunityId;
        quote.SBQQ__PriceBook__c = pricebook2Id;
        quote.SBQQ__PricebookId__c = pricebook2Id;
        quote.CurrencyIsoCode = contract.SVMXC__Company__r.CurrencyIsoCode;

        return quote;
    }
    
    /**
     * Updates Opportunity error log after Quote is inserted
     * Call this immediately after inserting Quote if it has error log
     * @param quote The inserted Quote record with error log
     */
    public static void syncQuoteErrorsToOpportunity(SBQQ__Quote__c quote) {
        if (String.isNotBlank(quote.Contract_Renewal_Error_Log__c) && 
            quote.SBQQ__Opportunity2__c != null) {
            
            Opportunity opp = new Opportunity(
                Id = quote.SBQQ__Opportunity2__c,
                Contract_Renewal_Error_Log__c = quote.Contract_Renewal_Error_Log__c
            );
            update opp;
        }
    }
    
	/**
     * Wrapper method to create Quote Lines with automatic error handling
     * All error logging is handled internally - no error map needed from caller
     * @param childContracts List of child Service Contracts
     * @param quoteId The related Quote Id
     * @param opportunityId The related Opportunity Id
     * @param contractProducts Map of Contract Id to Service Contract Products list
     * @param pricebookEntries Map of Product2Id to PricebookEntry
     * @param products Map of ProductCode to Product2 record
     * @param pricebook2Id The Pricebook2 Id
     * @return List of Quote Line Items (ready for insert) - excludes null entries
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLinesWithErrorHandling(
        List<SVMXC__Service_Contract__c> childContracts,
        Id quoteId,
        Id opportunityId,
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts,
        Map<Id, PricebookEntry> pricebookEntries,
        Map<String, Product2> products,
        Id pricebook2Id
    ) {
        // Internal error log map
        Map<Id, String> errorLogs = new Map<Id, String>();
        
        // Create quote lines
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        for (SVMXC__Service_Contract__c childContract : childContracts) {
            
            SBQQ__QuoteLine__c quoteLine = createQuoteLine(
                childContract, 
                quoteId, 
                contractProducts, 
                pricebookEntries, 
                products, 
                pricebook2Id,
                errorLogs
            );
            
            // Only add non-null quote lines (null = validation failed)
            if (quoteLine != null) {
                quoteLines.add(quoteLine);
            }
        }
        
        // Update Quote and Opportunity with errors if any were collected
        if (!errorLogs.isEmpty()) {
            updateQuoteAndOpportunityErrorLogs(errorLogs);
        }
        
        return quoteLines;
    }
    
    /**
     * Creates Quote Line Items from child Service Contracts (without DML)
     * Optimized for batch processing - requires pre-queried data
     * @param childContract The child Service Contract record
     * @param quoteId The related Quote Id (must be created first)
     * @param contractProducts Map of Contract Id to Service Contract Products list
     * @param pricebookEntries Map of Product2Id to PricebookEntry for the relevant pricebook
     * @param products Map of ProductCode to Product2 record (with product_line__c, Item_Class__c, IGOR_PAC__c, ProductCode)
     * @param pricebook2Id The Pricebook2 Id to use for querying PricebookEntries
     * @param errorLogs Map to collect error logs for Quote Lines (key: quoteId, value: error message)
     * @return The Quote Line Item record (not inserted - batch handles bulk DML), or null if product validation fails
     */
    public static SBQQ__QuoteLine__c createQuoteLine(
        SVMXC__Service_Contract__c childContract,
        Id quoteId,
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts,
        Map<Id, PricebookEntry> pricebookEntries,
        Map<String, Product2> products,
        Id pricebook2Id,
        Map<Id, String> errorLogs
    ) {

        // Initialize Quote Line
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();

        // Set Quote relationship
        quoteLine.SBQQ__Quote__c = quoteId;

        // Get Service Contract Products for this child contract
        List<SVMXC__Service_Contract_Products__c> contractProductList =
            contractProducts.get(childContract.Id);

        if (contractProductList == null || contractProductList.isEmpty()) {
            String errorMsg = 'Unable to create Quote Line for Child Contract ' +
                childContract.Name + ' (ID: ' + childContract.Id + '). ' +
                'No Service Contract Products found.';
            logError(quoteId, errorMsg, errorLogs);
            return null;
        }

        SVMXC__Service_Contract_Products__c contractProduct = contractProductList[0];
        SVMXC__Installed_Product__c installedProduct = contractProduct.SVMXC__Installed_Product__r;

        if (installedProduct == null) {
            String errorMsg = 'Unable to create Quote Line for Child Contract ' +
                childContract.Name + ' (ID: ' + childContract.Id + '). ' +
                'Installed Product is null.';
            logError(quoteId, errorMsg, errorLogs);
            return null;
        }

        Set<String> productCodes = collectProductCodes(installedProduct);
        if (productCodes.isEmpty()) {
            String errorMsg = 'Unable to create Quote Line for Child Contract ' +
                childContract.Name + ' (ID: ' + childContract.Id + '). ' +
                'Product ID is null on Installed Product.';
            logError(quoteId, errorMsg, errorLogs);
            return null;
        }

        Product2 product = null;
        for (String productCode : productCodes) {
            product = products.get(productCode);
            if (product != null) {
                break;
            }
        }

        if (product == null) {
            String errorMsg = 'Unable to create Quote Line for Child Contract ' +
                childContract.Name + ' (ID: ' + childContract.Id + '). ' +
                'Products (' + String.join(productCodes, ',') + ') not found in products map.';
            logError(quoteId, errorMsg, errorLogs);
            return null;
        }

        // Only set product fields if we have a valid product
        Id finalProductId = product.Id;
        quoteLine.SBQQ__Product__c = finalProductId;

        PricebookEntry pbe = pricebookEntries.get(finalProductId);
        if (pbe != null) {
            quoteLine.SBQQ__PricebookEntryId__c = pbe.Id;
        } else if (pricebook2Id != null) {
            PricebookEntry queriedPbe = queryPricebookEntry(finalProductId, pricebook2Id);
            if (queriedPbe != null) {
                quoteLine.SBQQ__PricebookEntryId__c = queriedPbe.Id;
                pricebookEntries.put(finalProductId, queriedPbe);
            }
        }

        quoteLine.product_line__c = product.product_line__c;
        quoteLine.Item_Class__c = product.Item_Class__c;
        quoteLine.IGOR_PAC__c = product.IGOR_PAC__c;

        // Always reference the ORIGINAL Installed Product
        quoteLine.Material__c = installedProduct.Id;
        quoteLine.MaterialSerialNumber__c = installedProduct.SVMXC__Serial_Lot_Number__c;
        if (installedProduct.SVMXC__Product__r != null) {
            quoteLine.MaterialProductCode__c = installedProduct.SVMXC__Product__r.ProductCode;
        }

        quoteLine.SBQQ__Quantity__c = 12;
        quoteLine.Old_Contract_Item_Price__c = childContract.SMAX_PS_ItemPrice__c;

        return quoteLine;
    }

    /**
     * Helper method to query PricebookEntry for a product
     * @param productId The Product2 Id
     * @param pricebook2Id The Pricebook2 Id
     * @return The PricebookEntry if found, null otherwise
     */
    private static PricebookEntry queryPricebookEntry(Id productId, Id pricebook2Id) {
        if (productId == null || pricebook2Id == null) {
            return null;
        }
        
        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :productId
            AND Pricebook2Id = :pricebook2Id
            AND IsActive = true
            LIMIT 1
        ];
        
        return pbes.isEmpty() ? null : pbes[0];
    }
    
     /**
     * Creates Pricing Conditions from Service Contract Products (without DML)
     * Parses SMAX_PS_SLA_Terms_Notes__c to extract 4-character SAP codes
     * Handles both formats:
     * - Single line: "ZMNT-Asset MaintainZG02-GxP LaboratoryZOS1-Repair Coverage"
     * - Multiple lines: "ZMNT\nZG02\nZOS1" or "ZMNT-Description\nZG02-Description"
     * @param contractProduct The Service Contract Product containing the SLA Terms Notes
     * @param quoteLineId The related Quote Line Id (must be created first)
     * @param currencyIsoCode The currency from the Quote Line
     * @return List of Pricing Condition records (not inserted - batch handles bulk DML)
     */
    public static List<Pricing_Condition__c> createPricingConditions(
        SVMXC__Service_Contract_Products__c contractProduct,
        Id quoteLineId,
        String currencyIsoCode
    ) {
        
        List<Pricing_Condition__c> pricingConditions = new List<Pricing_Condition__c>();
        
        // Check if SMAX_PS_SLA_Terms_Notes__c has content
        if (String.isBlank(contractProduct.SMAX_PS_SLA_Terms_Notes__c)) {
            return pricingConditions;
        }
        
        String slaTermsNotes = contractProduct.SMAX_PS_SLA_Terms_Notes__c.trim();
        Set<String> sapCodes = new Set<String>();
        
        // Check if the text contains newlines
        if (slaTermsNotes.contains('\n') || slaTermsNotes.contains('\r')) {
            
            // Split by line breaks (handle both \n and \r\n)
            List<String> lines = slaTermsNotes.split('[\r\n]+');
            
            for (String line : lines) {
                if (String.isNotBlank(line)) {
                    String trimmedLine = line.trim();
                    
                    // Extract first 4 characters as SAP code
                    String sapCode = '';
                    if (trimmedLine.length() >= 4) {
                        sapCode = trimmedLine.substring(0, 4).toUpperCase();
                    } else {
                        // If line is shorter than 4 chars, use the entire line
                        sapCode = trimmedLine.toUpperCase();
                    }
                    
                    // Validate it looks like a SAP code (alphanumeric)
                    if (Pattern.matches('[A-Z0-9]{3,4}', sapCode)) {
                        sapCodes.add(sapCode);
                    }
                }
            }
        } else {
            
            // Use regex to find all 4-character codes followed by a dash
            // Pattern: 4 uppercase letters/numbers followed by a dash
            Pattern sapPattern = Pattern.compile('([A-Z0-9]{4})-');
            Matcher sapMatcher = sapPattern.matcher(slaTermsNotes);
            
            // Extract all matching SAP codes
            while (sapMatcher.find()) {
                String sapCode = sapMatcher.group(1);
                sapCodes.add(sapCode);
            }
        }
        
        // Create Pricing Condition records for each unique SAP code
        for (String sapCode : sapCodes) {
            Pricing_Condition__c pricingCondition = new Pricing_Condition__c();
            
            // Set SAP Pricing Condition code
            pricingCondition.SAP_Pricing_Condition__c = sapCode;
            pricingCondition.Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED;
            pricingCondition.CurrencyIsoCode = currencyIsoCode;
            pricingCondition.Quote_Line__c = quoteLineId;
            pricingCondition.Source__c = PricingConditionConstants.SOURCE_SALESFORCE;
            pricingCondition.SAP_CALCTYPON__c = PricingConditionConstants.CALCTYPON_M;
            
            // Add to list
            pricingConditions.add(pricingCondition);
        }
        
        return pricingConditions;
    }
    
     /**
     * Updates Quote Lines with SAP Pricing Conditions codes after Pricing Conditions are inserted
     * Queries the Pricing Condition records to get the SAP codes instead of re-parsing
     * @param quoteLineToProductMap Map of Quote Line Id to Service Contract Product
     */
    public static void updateQuoteLinesWithSAPCodes(Map<Id, SVMXC__Service_Contract_Products__c> quoteLineToProductMap) {
        
        // Query all Pricing Conditions for these Quote Lines
        List<Pricing_Condition__c> pricingConditions = [
            SELECT Id, Quote_Line__c, SAP_Pricing_Condition__c
            FROM Pricing_Condition__c
            WHERE Quote_Line__c IN :quoteLineToProductMap.keySet()
            ORDER BY Quote_Line__c, SAP_Pricing_Condition__c
        ];
        
        // Build map of Quote Line Id to List of SAP codes
        Map<Id, List<String>> quoteLineToSAPCodesMap = new Map<Id, List<String>>();
        
        for (Pricing_Condition__c pc : pricingConditions) {
            if (!quoteLineToSAPCodesMap.containsKey(pc.Quote_Line__c)) {
                quoteLineToSAPCodesMap.put(pc.Quote_Line__c, new List<String>());
            }
            
            if (String.isNotBlank(pc.SAP_Pricing_Condition__c)) {
                quoteLineToSAPCodesMap.get(pc.Quote_Line__c).add(pc.SAP_Pricing_Condition__c);
            }
        }
        
        // Build list of Quote Lines to update
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        
        for (Id quoteLineId : quoteLineToSAPCodesMap.keySet()) {
            List<String> sapCodesList = quoteLineToSAPCodesMap.get(quoteLineId);
            
            if (!sapCodesList.isEmpty()) {
                // Join all SAP codes with semicolon
                String sapCodesString = String.join(sapCodesList, ';');
                
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                    Id = quoteLineId,
                    SAP_Pricing_Condtions__c = sapCodesString
                );
                quoteLinesToUpdate.add(quoteLine);
            }
        }
        
        // Update Quote Lines
        if (!quoteLinesToUpdate.isEmpty()) {
            update quoteLinesToUpdate;
        }
    }
    
    // ============================================================================
    // ERROR LOGGING METHODS
    // ============================================================================
    
    /**
     * Logs error message to error log collection map
     * Formats error with timestamp and appends to existing errors
     * @param quoteId The Quote Id
     * @param errorMessage New error message to append
     * @param errorLogs Map to collect error logs for batch processing
     */
    private static void logError(
        Id quoteId, 
        String errorMessage,
        Map<Id, String> errorLogs
    ) {
        if (String.isBlank(errorMessage) || quoteId == null || errorLogs == null) {
            return;
        }
        
        String formattedError = formatError(errorMessage);
        
        if (!errorLogs.containsKey(quoteId)) {
            errorLogs.put(quoteId, '');
        }
        errorLogs.put(quoteId, appendError(errorLogs.get(quoteId), formattedError));
    }
    
    /**
     * Formats error message with timestamp
     * @param errorMessage The error message
     * @return Formatted error with timestamp
     */
    private static String formatError(String errorMessage) {
        String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        return '[' + timestamp + '] ' + errorMessage;
    }
    
    /**
     * Helper method to append error message to existing log
     * @param existingLog Current content of error log field (can be null)
     * @param errorMessage New error message to append (should already include timestamp)
     * @return Updated error log with new message appended
     */
    private static String appendError(String existingLog, String errorMessage) {
        if (String.isBlank(existingLog)) {
            return errorMessage;
        } else {
            return existingLog + '\n' + errorMessage;
        }
    }
    
    /**
     * Updates Quote and Opportunity with accumulated error logs
     * Called internally after quote line processing
     * @param quoteErrorLogs Map of Quote Id to accumulated error messages
     */
    private static void updateQuoteAndOpportunityErrorLogs(Map<Id, String> quoteErrorLogs) {
        if (quoteErrorLogs == null || quoteErrorLogs.isEmpty()) {
            return;
        }
        
        // Query Quotes to get Opportunity Ids and existing error logs
        Map<Id, SBQQ__Quote__c> quotesToUpdate = new Map<Id, SBQQ__Quote__c>(
            [SELECT Id, SBQQ__Opportunity2__c, Contract_Renewal_Error_Log__c 
             FROM SBQQ__Quote__c 
             WHERE Id IN :quoteErrorLogs.keySet()]
        );
        
        List<SBQQ__Quote__c> quotesForUpdate = new List<SBQQ__Quote__c>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, String> oppErrorLogs = new Map<Id, String>();
        
        // Prepare Quote updates and collect Opportunity error logs
        for (Id quoteId : quoteErrorLogs.keySet()) {
            SBQQ__Quote__c quote = quotesToUpdate.get(quoteId);
            if (quote != null) {
                String newErrorLog = quoteErrorLogs.get(quoteId);
                
                // Append to existing Quote error log
                quote.Contract_Renewal_Error_Log__c = appendError(
                    quote.Contract_Renewal_Error_Log__c, 
                    newErrorLog
                );
                quotesForUpdate.add(quote);
                
                // Collect Opportunity error logs
                if (quote.SBQQ__Opportunity2__c != null) {
                    opportunityIds.add(quote.SBQQ__Opportunity2__c);
                    if (!oppErrorLogs.containsKey(quote.SBQQ__Opportunity2__c)) {
                        oppErrorLogs.put(quote.SBQQ__Opportunity2__c, '');
                    }
                    oppErrorLogs.put(
                        quote.SBQQ__Opportunity2__c, 
                        appendError(oppErrorLogs.get(quote.SBQQ__Opportunity2__c), newErrorLog)
                    );
                }
            }
        }
        
        // Update Quotes
        if (!quotesForUpdate.isEmpty()) {
            update quotesForUpdate;
        }
        
        // Query existing Opportunity error logs
        Map<Id, Opportunity> existingOpportunities = new Map<Id, Opportunity>(
            [SELECT Id, Contract_Renewal_Error_Log__c 
             FROM Opportunity 
             WHERE Id IN :opportunityIds]
        );
        
        // Update Opportunities with appended error logs
        if (!oppErrorLogs.isEmpty()) {
            List<Opportunity> oppsForUpdate = new List<Opportunity>();
            for (Id oppId : oppErrorLogs.keySet()) {
                Opportunity existingOpp = existingOpportunities.get(oppId);
                String existingLog = existingOpp != null ? existingOpp.Contract_Renewal_Error_Log__c : '';
                
                oppsForUpdate.add(new Opportunity(
                    Id = oppId,
                    Contract_Renewal_Error_Log__c = appendError(existingLog, oppErrorLogs.get(oppId))
                ));
            }
            update oppsForUpdate;
        }
    }
    
    // ============================================================================
    // WRAPPER CLASSES
    // ============================================================================
    
    /**
     * Wrapper class to hold related data for batch processing
     */
    public class QuoteLineData {
        public Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts;
        public Map<Id, PricebookEntry> pricebookEntries;
        public Map<String, Product2> products;
        
        public QuoteLineData() {
            this.contractProducts = new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
            this.pricebookEntries = new Map<Id, PricebookEntry>();
            this.products = new Map<String, Product2>();
        }
    }
}
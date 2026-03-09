public class ContractPricebookMatcher {
    
    // Main method to find pricebook for a service contract with pricebook list
    public static String findPricebookForContract(SVMXC__Service_Contract__c contract, List<Pricebook2> pricebooks) {
        String salesOrg = contract.SMAX_PS_SalesOrg__c;
        String countryCode = contract.SVMXC__Company__r?.fxPKICountryISOAlpha3__c;
        String currencyCode = contract.SVMXC__Company__r?.CurrencyIsoCode;
        
        List<String> pricebookNames = new List<String>();
        for (Pricebook2 pb : pricebooks) {
            pricebookNames.add(pb.Name);
        }
        
        return findPricebook(salesOrg, countryCode, currencyCode, pricebookNames);
    }
    
    // Overloaded method that accepts Map
    public static String findPricebookForContract(SVMXC__Service_Contract__c contract, Map<Id, Pricebook2> pricebookMap) {
        return findPricebookForContract(contract, pricebookMap.values());
    }
    
    // Core matching logic
    public static String findPricebook(String salesOrg, String countryCode, String currencyCode, List<String> pricebookNames) {
        List<String> matches;
        
        // Step 1: Try to find by Sales Org
        if (String.isNotBlank(salesOrg)) {
            matches = searchPricebooks(pricebookNames, salesOrg);
            if (!matches.isEmpty()) {
                if (matches.size() == 1) {
                    return matches[0];
                } else {
                    // Multiple matches - apply business rules
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        return selected;
                    }
                }
            }
        }
        
        // Step 2: Try to find by Country Code
        if (String.isNotBlank(countryCode)) {
            matches = searchPricebooks(pricebookNames, countryCode);
            if (!matches.isEmpty()) {
                if (matches.size() == 1) {
                    return matches[0];
                } else {
                    // Multiple matches - apply business rules
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        return selected;
                    }
                }
            }
        }
        
        // Step 3: Try to find by Currency
        if (String.isNotBlank(currencyCode)) {
            // Convert CNY to RMB for pricebook search
            String searchCurrency = convertCurrencyForSearch(currencyCode);
            matches = searchPricebooks(pricebookNames, searchCurrency);
            if (!matches.isEmpty()) {
                if (matches.size() == 1) {
                    return matches[0];
                } else {
                    // Multiple matches - apply business rules
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        return selected;
                    }
                    // If business rules don't resolve, return first match
                    return matches[0];
                }
            }
        }
        
        // No match found
        return null;
    }
    
    // Convert currency code for pricebook search (CNY -> RMB)
    private static String convertCurrencyForSearch(String currencyCode) {
        if (currencyCode == 'CNY') {
            return 'RMB';
        }
        return currencyCode;
    }
    
    // Search for pricebooks containing the search term (case-insensitive)
    private static List<String> searchPricebooks(List<String> pricebookNames, String searchTerm) {
        if (String.isBlank(searchTerm) || pricebookNames == null || pricebookNames.isEmpty()) {
            return new List<String>();
        }
        
        List<String> matches = new List<String>();
        String searchTermUpper = searchTerm.toUpperCase();
        
        for (String pbName : pricebookNames) {
            if (String.isNotBlank(pbName) && pbName.toUpperCase().contains(searchTermUpper)) {
                matches.add(pbName);
            }
        }
        
        return matches;
    }
    
    // Apply business rules to select the appropriate pricebook
    private static String applyBusinessRules(String salesOrg, String countryCode, String currencyCode, List<String> pricebooks) {
        if (pricebooks == null || pricebooks.isEmpty()) {
            return null;
        }
        
        // Rules for 1US0
        if (salesOrg == '1US0') {
            // Argentina
            if (countryCode == 'ARG') {
                return findPricebookContaining(pricebooks, '1US0_A1_USD');
            }
            // Brazil
            else if (countryCode == 'BRA') {
                return findPricebookContaining(pricebooks, '1US0_BD_USD');
            }
            // United States
            else if (countryCode == 'USA') {
                return findPricebookContaining(pricebooks, '1US0_US_USD');
            }
            // Other countries (not USA, ARG, BRA) -> Mexico
            else if (String.isNotBlank(countryCode) && 
                     countryCode != 'USA' && 
                     countryCode != 'ARG' && 
                     countryCode != 'BRA') {
                return findPricebookContaining(pricebooks, '1US0_MD_USD');
            }
        }
        
        // Rules for BRS0
        else if (salesOrg == 'BRS0') {
            if (currencyCode == 'BRL') {
                return findPricebookContaining(pricebooks, 'BRS0_BR_BRL');
            }
            else if (currencyCode == 'USD') {
                return findPricebookContaining(pricebooks, 'BRS0_L1_USD');
            }
        }
        
        // Rules for CAS0
        else if (salesOrg == 'CAS0') {
            return findPricebookContaining(pricebooks, 'CAS0_CA_CAD');
        }
        
        // Rules for CN10
        else if (salesOrg == 'CN10') {
            if (currencyCode == 'CNY') {
                return findPricebookContaining(pricebooks, 'CN10_CN_RMB');
            }
            else if (currencyCode == 'USD') {
                return findPricebookContaining(pricebooks, 'CN10_CR_USD');
            }
        }
        
        // Rules for MXS0
        else if (salesOrg == 'MXS0') {
            return findPricebookContaining(pricebooks, 'MXS0_MX_MXN');
        }
        
        // Rules for PR10
        else if (salesOrg == 'PR10') {
            return findPricebookContaining(pricebooks, 'PR10_US_USD');
        }
        
        // Rules for SGS0
        else if (salesOrg == 'SGS0') {
            // India, Pakistan, Bangladesh
            if (countryCode == 'IND' || countryCode == 'PAK' || countryCode == 'BGD') {
                return findPricebookContaining(pricebooks, 'SGS0_IN_USD');
            }
            // Indonesia
            else if (countryCode == 'IDN') {
                return findPricebookContaining(pricebooks, 'SGS0_ID_USD');
            }
            // Philippines
            else if (countryCode == 'PHL') {
                return findPricebookContaining(pricebooks, 'SGS0_PH_USD');
            }
            // Singapore
            else if (countryCode == 'SGP') {
                if (currencyCode == 'SGD') {
                    return findPricebookContaining(pricebooks, 'SGS0_SG_SGD');
                }
                else if (currencyCode == 'USD') {
                    return findPricebookContaining(pricebooks, 'SGS0_PS_USD');
                }
            }
            // South Korea
            else if (countryCode == 'KOR') {
                return findPricebookContaining(pricebooks, 'SGS0_KR_USD');
            }
            // Taiwan
            else if (countryCode == 'TWN') {
                return findPricebookContaining(pricebooks, 'SGS0_TW_USD');
            }
        }
        
        // Rules for ZA10
        else if (salesOrg == 'ZA10') {
            if (currencyCode == 'USD') {
                return findPricebookContaining(pricebooks, 'ZA10_ZU_USD');
            }
            else if (currencyCode == 'ZAR') {
                return findPricebookContaining(pricebooks, 'ZA10_ZR_ZAR');
            }
        }
        
        // No rule matched, return null to indicate business rules couldn't resolve
        return null;
    }
    
    // Helper method to find a pricebook name containing a specific substring
    private static String findPricebookContaining(List<String> pricebooks, String searchTerm) {
        for (String pb : pricebooks) {
            if (pb.contains(searchTerm)) {
                return pb;
            }
        }
        return null;
    }
    
    // Batch method to process multiple service contracts
    public static Map<Id, String> findPricebooksForContracts(List<SVMXC__Service_Contract__c> contracts, List<Pricebook2> pricebooks) {
        Map<Id, String> contractToPricebook = new Map<Id, String>();
        
        for (SVMXC__Service_Contract__c contract : contracts) {
            String pricebookName = findPricebookForContract(contract, pricebooks);
            contractToPricebook.put(contract.Id, pricebookName);
        }
        
        return contractToPricebook;
    }
    
    // Overloaded batch method with Map
    public static Map<Id, String> findPricebooksForContracts(List<SVMXC__Service_Contract__c> contracts, Map<Id, Pricebook2> pricebookMap) {
        return findPricebooksForContracts(contracts, pricebookMap.values());
    }
    
    // Method to get Pricebook2 Id from name (using passed map)
    public static Id getPricebookIdByName(String pricebookName, Map<Id, Pricebook2> pricebookMap) {
        if (String.isBlank(pricebookName) || pricebookMap == null) {
            return null;
        }
        
        for (Pricebook2 pb : pricebookMap.values()) {
            if (pb.Name == pricebookName) {
                return pb.Id;
            }
        }
        
        return null;
    }
    
    // Method to get Pricebook2 Id from name (using passed list)
    public static Id getPricebookIdByName(String pricebookName, List<Pricebook2> pricebooks) {
        if (String.isBlank(pricebookName) || pricebooks == null) {
            return null;
        }
        
        for (Pricebook2 pb : pricebooks) {
            if (pb.Name == pricebookName) {
                return pb.Id;
            }
        }
        
        return null;
    }
    
    // Wrapper method that returns Pricebook2 Id directly
    public static Id findPricebookIdForContract(SVMXC__Service_Contract__c contract, Map<Id, Pricebook2> pricebookMap) {
        String pricebookName = findPricebookForContract(contract, pricebookMap);
        return getPricebookIdByName(pricebookName, pricebookMap);
    }
    
    // Result wrapper class for detailed matching info
    public class MatchResult {
        public String pricebookName { get; set; }
        public Id pricebookId { get; set; }
        public String matchMethod { get; set; } // 'Sales Org', 'Country Code', 'Currency', 'Business Rules'
        public Boolean isMultipleMatches { get; set; }
        public List<String> allMatches { get; set; }
        
        public MatchResult() {
            this.allMatches = new List<String>();
            this.isMultipleMatches = false;
        }
    }
    
    // Enhanced method that returns detailed matching information
    public static MatchResult findPricebookWithDetails(SVMXC__Service_Contract__c contract, Map<Id, Pricebook2> pricebookMap) {
        MatchResult result = new MatchResult();
        
        String salesOrg = contract.SMAX_PS_SalesOrg__c;
        String countryCode = contract.SVMXC__Company__r?.fxPKICountryISOAlpha3__c;
        String currencyCode = contract.SVMXC__Company__r?.CurrencyIsoCode;
        
        List<String> pricebookNames = new List<String>();
        for (Pricebook2 pb : pricebookMap.values()) {
            pricebookNames.add(pb.Name);
        }
        
        List<String> matches;
        
        // Step 1: Try to find by Sales Org
        if (String.isNotBlank(salesOrg)) {
            matches = searchPricebooks(pricebookNames, salesOrg);
            if (!matches.isEmpty()) {
                result.allMatches = matches;
                result.isMultipleMatches = matches.size() > 1;
                result.matchMethod = 'Sales Org';
                
                if (matches.size() == 1) {
                    result.pricebookName = matches[0];
                } else {
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        result.pricebookName = selected;
                        result.matchMethod = 'Sales Org + Business Rules';
                    }
                }
                
                if (String.isNotBlank(result.pricebookName)) {
                    result.pricebookId = getPricebookIdByName(result.pricebookName, pricebookMap);
                    return result;
                }
            }
        }
        
        // Step 2: Try to find by Country Code
        if (String.isNotBlank(countryCode)) {
            matches = searchPricebooks(pricebookNames, countryCode);
            if (!matches.isEmpty()) {
                result.allMatches = matches;
                result.isMultipleMatches = matches.size() > 1;
                result.matchMethod = 'Country Code';
                
                if (matches.size() == 1) {
                    result.pricebookName = matches[0];
                } else {
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        result.pricebookName = selected;
                        result.matchMethod = 'Country Code + Business Rules';
                    }
                }
                
                if (String.isNotBlank(result.pricebookName)) {
                    result.pricebookId = getPricebookIdByName(result.pricebookName, pricebookMap);
                    return result;
                }
            }
        }
        
        // Step 3: Try to find by Currency
        if (String.isNotBlank(currencyCode)) {
            // Convert CNY to RMB for pricebook search
            String searchCurrency = convertCurrencyForSearch(currencyCode);
            matches = searchPricebooks(pricebookNames, searchCurrency);
            if (!matches.isEmpty()) {
                result.allMatches = matches;
                result.isMultipleMatches = matches.size() > 1;
                result.matchMethod = 'Currency';
                
                if (matches.size() == 1) {
                    result.pricebookName = matches[0];
                } else {
                    String selected = applyBusinessRules(salesOrg, countryCode, currencyCode, matches);
                    if (String.isNotBlank(selected)) {
                        result.pricebookName = selected;
                        result.matchMethod = 'Currency + Business Rules';
                    } else {
                        result.pricebookName = matches[0];
                        result.matchMethod = 'Currency (First Match)';
                    }
                }
                
                if (String.isNotBlank(result.pricebookName)) {
                    result.pricebookId = getPricebookIdByName(result.pricebookName, pricebookMap);
                    return result;
                }
            }
        }
        
        // No match found
        result.matchMethod = 'No Match';
        return result;
    }
}
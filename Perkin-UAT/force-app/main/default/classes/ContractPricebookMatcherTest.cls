@isTest
private class ContractPricebookMatcherTest {
    
    // Test data setup
    @testSetup
    static void setupTestData() {
        // Create User with System Administrator profile
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = sysAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create Permission Set with custom permission
        PermissionSet ps = new PermissionSet(
            Name = 'Allow_Account_Creation_Test_PB',
            Label = 'Allow Account Creation Test PB'
        );
        insert ps;
        
        // Get the Custom Permission
        CustomPermission customPerm = [
            SELECT Id 
            FROM CustomPermission 
            WHERE DeveloperName = 'C_PERM_9200_Allow_Creating_Account' 
            LIMIT 1
        ];
        
        // Assign custom permission to Permission Set
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = customPerm.Id
        );
        insert sea;
        
        // Assign Permission Set to User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;
        
        // Run as System Administrator with custom permission
        System.runAs(testUser) {
            // Create PKI Countries with all required fields
            List<PKI_Country__c> countries = new List<PKI_Country__c>();
            
            countries.add(new PKI_Country__c(
                Name = 'United States',
                Country_ISO_Alpha_3__c = 'USA',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'NORTH AMERICA',
                Sub_Territory__c = 'NORTH AMERICA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Argentina',
                Country_ISO_Alpha_3__c = 'ARG',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'LATIN AMERICA',
                Sub_Territory__c = 'OTHER SOUTH AMERICA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Brazil',
                Country_ISO_Alpha_3__c = 'BRA',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'LATIN AMERICA',
                Sub_Territory__c = 'LATIN AMERICA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Mexico',
                Country_ISO_Alpha_3__c = 'MEX',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'LATIN AMERICA',
                Sub_Territory__c = 'OTHER CENTRAL AMERICA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Canada',
                Country_ISO_Alpha_3__c = 'CAN',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'NORTH AMERICA',
                Sub_Territory__c = 'NORTH AMERICA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'China',
                Country_ISO_Alpha_3__c = 'CHN',
                Global_Territory__c = 'GREATER CHINA',
                Super_Territory__c = 'GREATER CHINA',
                Territory__c = 'GREATER CHINA',
                Sub_Territory__c = 'GREATER CHINA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Singapore',
                Country_ISO_Alpha_3__c = 'SGP',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'EERCIS',
                Sub_Territory__c = 'SEA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'India',
                Country_ISO_Alpha_3__c = 'IND',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'GREATER INDIA',
                Sub_Territory__c = 'GREATER INDIA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Pakistan',
                Country_ISO_Alpha_3__c = 'PAK',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'GREATER INDIA',
                Sub_Territory__c = 'GREATER INDIA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Bangladesh',
                Country_ISO_Alpha_3__c = 'BGD',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'GREATER INDIA',
                Sub_Territory__c = 'GREATER INDIA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Indonesia',
                Country_ISO_Alpha_3__c = 'IDN',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'EERCIS',
                Sub_Territory__c = 'SEA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Philippines',
                Country_ISO_Alpha_3__c = 'PHL',
                Global_Territory__c = 'APAC',
                Super_Territory__c = 'APAC',
                Territory__c = 'EERCIS',
                Sub_Territory__c = 'SEA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'South Korea',
                Country_ISO_Alpha_3__c = 'KOR',
                Global_Territory__c = 'KOSJ',
                Super_Territory__c = 'KOSJ',
                Territory__c = 'KOSJ',
                Sub_Territory__c = 'KOREA AND JAPAN'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'Taiwan',
                Country_ISO_Alpha_3__c = 'TWN',
                Global_Territory__c = 'GREATER CHINA',
                Super_Territory__c = 'GREATER CHINA',
                Territory__c = 'GREATER CHINA',
                Sub_Territory__c = 'GREATER CHINA'
            ));
            
            countries.add(new PKI_Country__c(
                Name = 'South Africa',
                Country_ISO_Alpha_3__c = 'ZAF',
                Global_Territory__c = 'EMT AND INDIA',
                Super_Territory__c = 'APAC',
                Territory__c = 'EMT AND INDIA',
                Sub_Territory__c = 'SOUTH AFRICA'
            ));
            
            insert countries;
            
            // Create Accounts with PKI Country references
            List<Account> accounts = new List<Account>();
            Map<String, PKI_Country__c> countryMap = new Map<String, PKI_Country__c>();
            for (PKI_Country__c country : countries) {
                countryMap.put(country.Country_ISO_Alpha_3__c, country);
            }
            
            accounts.add(new Account(
                Name = 'US Account',
                PKICountry__c = countryMap.get('USA').Id,
                PKI_SAP_Customer_Number__c = '0001234567',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'USD'
            ));
            
            accounts.add(new Account(
                Name = 'Argentina Account',
                PKICountry__c = countryMap.get('ARG').Id,
                PKI_SAP_Customer_Number__c = '0001234568',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'USD'
            ));
            
            accounts.add(new Account(
                Name = 'Brazil Account',
                PKICountry__c = countryMap.get('BRA').Id,
                PKI_SAP_Customer_Number__c = '0001234569',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'BRL'
            ));
            
            accounts.add(new Account(
                Name = 'Mexico Account',
                PKICountry__c = countryMap.get('MEX').Id,
                PKI_SAP_Customer_Number__c = '0001234570',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'MXN'
            ));
            
            accounts.add(new Account(
                Name = 'Canada Account',
                PKICountry__c = countryMap.get('CAN').Id,
                PKI_SAP_Customer_Number__c = '0001234571',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'CAD'
            ));
            
            accounts.add(new Account(
                Name = 'China Account',
                PKICountry__c = countryMap.get('CHN').Id,
                PKI_SAP_Customer_Number__c = '0001234572',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'CNY'
            ));
            
            accounts.add(new Account(
                Name = 'Singapore Account',
                PKICountry__c = countryMap.get('SGP').Id,
                PKI_SAP_Customer_Number__c = '0001234573',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'SGD'
            ));
            
            accounts.add(new Account(
                Name = 'India Account',
                PKICountry__c = countryMap.get('IND').Id,
                PKI_SAP_Customer_Number__c = '0001234574',
                MDM_Status__c = 'Active',
                CurrencyIsoCode = 'USD'
            ));
            
            insert accounts;
            
            // Create Pricebooks
            List<Pricebook2> pricebooks = new List<Pricebook2>();
            
            // 1US0 Pricebooks
            pricebooks.add(new Pricebook2(Name = '1US0_A1_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = '1US0_BD_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = '1US0_US_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = '1US0_MD_USD', IsActive = true));
            
            // BRS0 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'BRS0_BR_BRL', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'BRS0_L1_USD', IsActive = true));
            
            // CAS0 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'CAS0_CA_CAD', IsActive = true));
            
            // CN10 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'CN10_CN_RMB', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'CN10_CR_USD', IsActive = true));
            
            // MXS0 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'MXS0_MX_MXN', IsActive = true));
            
            // PR10 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'PR10_US_USD', IsActive = true));
            
            // SGS0 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'SGS0_IN_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_ID_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_PH_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_SG_SGD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_PS_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_KR_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'SGS0_TW_USD', IsActive = true));
            
            // ZA10 Pricebooks
            pricebooks.add(new Pricebook2(Name = 'ZA10_ZU_USD', IsActive = true));
            pricebooks.add(new Pricebook2(Name = 'ZA10_ZR_ZAR', IsActive = true));
            
            insert pricebooks;
        } // End of System.runAs
    }
    
    // Helper method to get accounts
    static Map<String, Account> getAccountMap() {
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, Name, fxPKICountryISOAlpha3__c, CurrencyIsoCode 
                            FROM Account]) {
            accountMap.put(acc.Name, acc);
        }
        return accountMap;
    }
    
    // Helper method to get pricebooks
    static List<Pricebook2> getPricebooks() {
        return [SELECT Id, Name FROM Pricebook2 WHERE IsActive = true];
    }
    
    static Map<Id, Pricebook2> getPricebookMap() {
        return new Map<Id, Pricebook2>([SELECT Id, Name FROM Pricebook2 WHERE IsActive = true]);
    }
    
    @isTest
    static void test1US0_USA() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract USA',
            SMAX_PS_SalesOrg__c = '1US0',
            SVMXC__Company__c = accountMap.get('US Account').Id
        );
        insert contract;
        
        // Re-query to get formula fields
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('1US0_US_USD', result, 'Should match US pricebook for 1US0 sales org with USA country');
    }
    
    @isTest
    static void test1US0_Argentina() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Argentina',
            SMAX_PS_SalesOrg__c = '1US0',
            SVMXC__Company__c = accountMap.get('Argentina Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('1US0_A1_USD', result, 'Should match Argentina pricebook for 1US0 sales org');
    }
    
    @isTest
    static void test1US0_Brazil() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Brazil',
            SMAX_PS_SalesOrg__c = '1US0',
            SVMXC__Company__c = accountMap.get('Brazil Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('1US0_BD_USD', result, 'Should match Brazil pricebook for 1US0 sales org');
    }
    
    @isTest
    static void test1US0_Mexico() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Mexico',
            SMAX_PS_SalesOrg__c = '1US0',
            SVMXC__Company__c = accountMap.get('Mexico Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('1US0_MD_USD', result, 'Should match Mexico pricebook for 1US0 sales org with other country');
    }
    
    @isTest
    static void testBRS0_BRL() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Brazil',
            SMAX_PS_SalesOrg__c = 'BRS0',
            SVMXC__Company__c = accountMap.get('Brazil Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('BRS0_BR_BRL', result, 'Should match BRL pricebook for BRS0 sales org');
    }
    
    @isTest
    static void testCAS0() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Canada',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('CAS0_CA_CAD', result, 'Should match Canada pricebook for CAS0 sales org');
    }
    
    @isTest
    static void testCN10_CNY() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract China',
            SMAX_PS_SalesOrg__c = 'CN10',
            SVMXC__Company__c = accountMap.get('China Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('CN10_CN_RMB', result, 'Should match CNY pricebook for CN10 sales org');
    }
    
    @isTest
    static void testMXS0() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Mexico',
            SMAX_PS_SalesOrg__c = 'MXS0',
            SVMXC__Company__c = accountMap.get('Mexico Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('MXS0_MX_MXN', result, 'Should match Mexico pricebook for MXS0 sales org');
    }
    
    @isTest
    static void testSGS0_India() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract India',
            SMAX_PS_SalesOrg__c = 'SGS0',
            SVMXC__Company__c = accountMap.get('India Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('SGS0_IN_USD', result, 'Should match India pricebook for SGS0 sales org');
    }
    
    @isTest
    static void testSGS0_Singapore_SGD() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Singapore',
            SMAX_PS_SalesOrg__c = 'SGS0',
            SVMXC__Company__c = accountMap.get('Singapore Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        System.assertEquals('SGS0_SG_SGD', result, 'Should match Singapore SGD pricebook for SGS0 sales org');
    }
    
    @isTest
    static void testFindPricebookWithMap() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebookMap);
        Test.stopTest();
        
        System.assertEquals('CAS0_CA_CAD', result, 'Should work with Map parameter');
    }
    
    @isTest
    static void testBatchMethod() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        List<SVMXC__Service_Contract__c> contracts = new List<SVMXC__Service_Contract__c>();
        contracts.add(new SVMXC__Service_Contract__c(
            Name = 'Contract 1',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        ));
        contracts.add(new SVMXC__Service_Contract__c(
            Name = 'Contract 2',
            SMAX_PS_SalesOrg__c = 'MXS0',
            SVMXC__Company__c = accountMap.get('Mexico Account').Id
        ));
        insert contracts;
        
        contracts = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                     SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c 
                     WHERE Id IN :contracts];
        
        Test.startTest();
        Map<Id, String> results = ContractPricebookMatcher.findPricebooksForContracts(contracts, pricebooks);
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return results for both contracts');
        System.assertEquals('CAS0_CA_CAD', results.get(contracts[0].Id), 'First contract should match Canada pricebook');
        System.assertEquals('MXS0_MX_MXN', results.get(contracts[1].Id), 'Second contract should match Mexico pricebook');
    }
    
    @isTest
    static void testBatchMethodWithMap() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        List<SVMXC__Service_Contract__c> contracts = new List<SVMXC__Service_Contract__c>();
        contracts.add(new SVMXC__Service_Contract__c(
            Name = 'Contract 1',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        ));
        insert contracts;
        
        contracts = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                     SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c 
                     WHERE Id IN :contracts];
        
        Test.startTest();
        Map<Id, String> results = ContractPricebookMatcher.findPricebooksForContracts(contracts, pricebookMap);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return result for contract');
    }
    
    @isTest
    static void testGetPricebookIdByNameWithMap() {
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        Test.startTest();
        Id pbId = ContractPricebookMatcher.getPricebookIdByName('CAS0_CA_CAD', pricebookMap);
        Test.stopTest();
        
        System.assertNotEquals(null, pbId, 'Should find pricebook ID');
        
        // Test with null/blank name
        Id nullResult = ContractPricebookMatcher.getPricebookIdByName(null, pricebookMap);
        System.assertEquals(null, nullResult, 'Should return null for null name');
        
        Id blankResult = ContractPricebookMatcher.getPricebookIdByName('', pricebookMap);
        System.assertEquals(null, blankResult, 'Should return null for blank name');
        
        // Test with invalid name
        Id invalidResult = ContractPricebookMatcher.getPricebookIdByName('INVALID_PB', pricebookMap);
        System.assertEquals(null, invalidResult, 'Should return null for invalid name');
    }
    
    @isTest
    static void testGetPricebookIdByNameWithList() {
        List<Pricebook2> pricebooks = getPricebooks();
        
        Test.startTest();
        Id pbId = ContractPricebookMatcher.getPricebookIdByName('CAS0_CA_CAD', pricebooks);
        Test.stopTest();
        
        System.assertNotEquals(null, pbId, 'Should find pricebook ID');
        
        // Test with null name
        Id nullResult = ContractPricebookMatcher.getPricebookIdByName(null, pricebooks);
        System.assertEquals(null, nullResult, 'Should return null for null name');
    }
    
    @isTest
    static void testFindPricebookIdForContract() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        Id pbId = ContractPricebookMatcher.findPricebookIdForContract(contract, pricebookMap);
        Test.stopTest();
        
        System.assertNotEquals(null, pbId, 'Should return pricebook ID');
    }
    
    @isTest
    static void testFindPricebookWithDetails() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = 'CAS0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        ContractPricebookMatcher.MatchResult result = ContractPricebookMatcher.findPricebookWithDetails(contract, pricebookMap);
        Test.stopTest();
        
        System.assertEquals('CAS0_CA_CAD', result.pricebookName, 'Should match correct pricebook');
        System.assertNotEquals(null, result.pricebookId, 'Should have pricebook ID');
        System.assertEquals('Sales Org', result.matchMethod, 'Should match by Sales Org');
        System.assertEquals(false, result.isMultipleMatches, 'Should not have multiple matches');
        System.assertEquals(1, result.allMatches.size(), 'Should have one match');
    }
    
    @isTest
    static void testNoMatch() {
        List<Pricebook2> pricebooks = getPricebooks();
        
        // Create a contract with values that won't match any pricebook
        Test.startTest();
        String result = ContractPricebookMatcher.findPricebook('XXXX', 'ZZZ', 'ZZZ', new List<String>());
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null when no match found with empty pricebook list');
        
        // Test with pricebooks but no matching criteria
        result = ContractPricebookMatcher.findPricebook('NONEXISTENT', 'XYZ', 'ABC', 
            new List<String>{'1US0_A1_USD', 'BRS0_BR_BRL', 'CAS0_CA_CAD'});
        System.assertEquals(null, result, 'Should return null when no match found with non-matching criteria');
    }
    
    @isTest
    static void testNullInputs() {
        List<Pricebook2> pricebooks = getPricebooks();
        
        Test.startTest();
        
        // Test with null contract fields
        String result1 = ContractPricebookMatcher.findPricebook(null, null, null, new List<String>{'Test'});
        System.assertEquals(null, result1, 'Should handle null inputs gracefully');
        
        // Test with empty pricebook list
        String result2 = ContractPricebookMatcher.findPricebook('1US0', 'USA', 'USD', new List<String>());
        System.assertEquals(null, result2, 'Should return null for empty pricebook list');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCountryCodeMatching() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = null, // No sales org
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        // Should match by country code since no sales org
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        // Should find a pricebook containing CAN (country code)
        System.assertNotEquals(null, result, 'Should find a match by country code');
    }
    
    @isTest
    static void testCurrencyMatching() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = null, // No sales org
            SVMXC__Company__c = accountMap.get('Brazil Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        // Should match by currency since no sales org
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();
        
        // Should find a pricebook containing BRL (currency)
        System.assertNotEquals(null, result, 'Should find a match by currency');
        System.assert(result.contains('BRL'), 'Result should contain BRL currency code');
    }
    
    @isTest
    static void testMultipleMatchesWithBusinessRules() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();
        
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = '1US0',
            SVMXC__Company__c = accountMap.get('US Account').Id
        );
        insert contract;
        
        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c, 
                    SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];
        
        Test.startTest();
        ContractPricebookMatcher.MatchResult result = ContractPricebookMatcher.findPricebookWithDetails(contract, pricebookMap);
        Test.stopTest();
        
        System.assertEquals('1US0_US_USD', result.pricebookName, 'Should apply business rules for USA');
        System.assert(result.matchMethod.contains('Business Rules'), 'Should indicate business rules were applied');
    }
    
    @isTest
    static void testCaseInsensitiveSearch() {
        List<String> pricebookNames = new List<String>{'Test_PB_USD', 'Another_PB_EUR'};
        
        Test.startTest();
        // Test case insensitive search
        String result = ContractPricebookMatcher.findPricebook(null, null, 'usd', pricebookNames);
        Test.stopTest();
        
        System.assertEquals('Test_PB_USD', result, 'Should match case-insensitively');
    }
    
    @isTest
    static void testAllSalesOrgBusinessRules() {
        // Test PR10
        List<String> pricebookNames = new List<String>{'PR10_US_USD'};
        String result = ContractPricebookMatcher.findPricebook('PR10', 'USA', 'USD', pricebookNames);
        System.assertEquals('PR10_US_USD', result, 'Should match PR10 pricebook');
        
        // Test ZA10 with USD
        pricebookNames = new List<String>{'ZA10_ZU_USD', 'ZA10_ZR_ZAR'};
        result = ContractPricebookMatcher.findPricebook('ZA10', 'ZAF', 'USD', pricebookNames);
        System.assertEquals('ZA10_ZU_USD', result, 'Should match ZA10 USD pricebook');
        
        // Test ZA10 with ZAR
        result = ContractPricebookMatcher.findPricebook('ZA10', 'ZAF', 'ZAR', pricebookNames);
        System.assertEquals('ZA10_ZR_ZAR', result, 'Should match ZA10 ZAR pricebook');
        
        // Test CN10 with USD
        pricebookNames = new List<String>{'CN10_CN_RMB', 'CN10_CR_USD'};
        result = ContractPricebookMatcher.findPricebook('CN10', 'CHN', 'USD', pricebookNames);
        System.assertEquals('CN10_CR_USD', result, 'Should match CN10 USD pricebook');
        
        // Test BRS0 with USD
        pricebookNames = new List<String>{'BRS0_BR_BRL', 'BRS0_L1_USD'};
        result = ContractPricebookMatcher.findPricebook('BRS0', 'BRA', 'USD', pricebookNames);
        System.assertEquals('BRS0_L1_USD', result, 'Should match BRS0 USD pricebook');
        
        // Test SGS0 countries
        pricebookNames = new List<String>{'SGS0_IN_USD', 'SGS0_ID_USD', 'SGS0_PH_USD', 'SGS0_KR_USD', 'SGS0_TW_USD'};
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'PAK', 'USD', pricebookNames);
        System.assertEquals('SGS0_IN_USD', result, 'Should match Pakistan to India pricebook');
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'BGD', 'USD', pricebookNames);
        System.assertEquals('SGS0_IN_USD', result, 'Should match Bangladesh to India pricebook');
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'IDN', 'USD', pricebookNames);
        System.assertEquals('SGS0_ID_USD', result, 'Should match Indonesia pricebook');
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'PHL', 'USD', pricebookNames);
        System.assertEquals('SGS0_PH_USD', result, 'Should match Philippines pricebook');
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'KOR', 'USD', pricebookNames);
        System.assertEquals('SGS0_KR_USD', result, 'Should match South Korea pricebook');
        
        result = ContractPricebookMatcher.findPricebook('SGS0', 'TWN', 'USD', pricebookNames);
        System.assertEquals('SGS0_TW_USD', result, 'Should match Taiwan pricebook');
        
        // Test SGS0 Singapore with different currencies
        pricebookNames = new List<String>{'SGS0_SG_SGD', 'SGS0_PS_USD'};
        result = ContractPricebookMatcher.findPricebook('SGS0', 'SGP', 'USD', pricebookNames);
        System.assertEquals('SGS0_PS_USD', result, 'Should match Singapore USD pricebook');
    }

    @IsTest
    static void invalidSalesOrgTest() {
        Map<String, Account> accountMap = getAccountMap();
        List<Pricebook2> pricebooks = getPricebooks();

        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract Invalid SalesOrg',
            SMAX_PS_SalesOrg__c = 'XX0',
            SVMXC__Company__c = accountMap.get('India Account').Id
        );
        insert contract;

        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c,
            SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];

        Test.startTest();
        String result = ContractPricebookMatcher.findPricebookForContract(contract, pricebooks);
        Test.stopTest();

        System.assert(result.contains(contract.SVMXC__Company__r.CurrencyIsoCode), 'Result should contain USD currency code');
    }

    @isTest
    static void invalidSalesOrgFindPricebookWithDetailsTest() {
        Map<String, Account> accountMap = getAccountMap();
        Map<Id, Pricebook2> pricebookMap = getPricebookMap();

        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            SMAX_PS_SalesOrg__c = 'XX0',
            SVMXC__Company__c = accountMap.get('Canada Account').Id
        );
        insert contract;

        contract = [SELECT Id, SMAX_PS_SalesOrg__c, SVMXC__Company__r.fxPKICountryISOAlpha3__c,
            SVMXC__Company__r.CurrencyIsoCode FROM SVMXC__Service_Contract__c WHERE Id = :contract.Id];

        Test.startTest();
        ContractPricebookMatcher.MatchResult result = ContractPricebookMatcher.findPricebookWithDetails(contract, pricebookMap);
        Test.stopTest();

        System.assertEquals('CAS0_CA_CAD', result.pricebookName, 'Should match correct pricebook');
        System.assertNotEquals(null, result.pricebookId, 'Should have pricebook ID');
        System.assertEquals('Currency', result.matchMethod, 'Should match by Currency');
        System.assertEquals(false, result.isMultipleMatches, 'Should not have multiple matches');
        System.assertEquals(1, result.allMatches.size(), 'Should have one match');
    }

}
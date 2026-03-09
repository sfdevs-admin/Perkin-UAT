@IsTest
public class ContractRenewalDataManagementTest {
    
    /**
     * Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create User with System Administrator profile
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + Datetime.now().getTime() + '@example.com',
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
            Name = 'Allow_Account_Creation_Test',
            Label = 'Allow Account Creation Test'
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
            // Create PKI Country
            List<PKI_Country__c> countries = new List<PKI_Country__c>();
            
            countries.add(new PKI_Country__c(
                Name = 'United States',
                Country_ISO_Alpha_3__c = 'USA',
                Global_Territory__c = 'AMERICAS',
                Super_Territory__c = 'AMERICAS',
                Territory__c = 'NORTH AMERICA',
                Sub_Territory__c = 'NORTH AMERICA'
            ));
            
            insert countries;
            
            PKI_Country__c testCountry = countries[0];
            
            // Create Account with PKI Country and SAP Customer Number
            Account testAccount = new Account(
                Name = 'Test Account',
                CurrencyIsoCode = 'USD',
                PKICountry__c = testCountry.Id,
                PKI_SAP_Customer_Number__c = '0001234567',
                MDM_Status__c = 'Active'
            );
            insert testAccount;
            
            // Create Contact with SAP Customer Number
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = testAccount.Id,
                PKI_SAP_Contact_Id__c = 'SAPID',
                PKI_SAP_Customer_Number__c = '0001234567'
            );
            insert testContact;
            
            // Create Second Account for testing contact validation
            Account secondAccount = new Account(
                Name = 'Second Account',
                CurrencyIsoCode = 'USD',
                PKICountry__c = testCountry.Id,
                PKI_SAP_Customer_Number__c = '0001234568',
                MDM_Status__c = 'Active'
            );
            insert secondAccount;
            
            // Create Products
            List<Product2> products = new List<Product2>();
            
            // Valid product with Item_Class = 3 (valid for Service Contracts)
            Product2 validProduct = new Product2(
                Name = 'Valid Product',
                ProductCode = 'VALID003',
                IsActive = true,
                product_line__c = 'ABC',
                Item_Class__c = '3',  // Valid
                IGOR_PAC__c = 'PAC0'
            );
            products.add(validProduct);
            
            // Alternative product with valid Item_Class = F (valid for Service Contracts)
            Product2 alternativeProduct = new Product2(
                Name = 'Alternative Product',
                ProductCode = 'XYZVALID001',
                IsActive = true,
                product_line__c = 'XYZ',
                Item_Class__c = 'F',  // Valid
                IGOR_PAC__c = 'PAC1'
            );
            products.add(alternativeProduct);

            // Product with Item_Class = 1
            Product2 itemClass1Product = new Product2(
                Name = 'Item Class 1 Product',
                ProductCode = 'VALID001',
                IsActive = true,
                product_line__c = 'XYZ',
                Item_Class__c = '1',  // INVALID for Service Contracts
                IGOR_PAC__c = 'PAC2'
            );
            products.add(itemClass1Product);
            
            // Product with Item_Class = 4
            Product2 itemClass4ProductNoAlt = new Product2(
                Name = 'Item Class 4 Product No Alternative',
                ProductCode = 'VALID004',
                IsActive = true,
                product_line__c = 'ZZZ',
                Item_Class__c = '4',  // INVALID for Service Contracts
                IGOR_PAC__c = 'PAC3'
            );
            products.add(itemClass4ProductNoAlt);
            
            // Special ProductCode that bypasses Item_Class validation (SV000301-SV000305)
            // Can have any Item_Class because ProductCode is in exception list
            Product2 specialProductCode = new Product2(
                Name = 'Special Product Code',
                ProductCode = 'SV000301',  // Exception ProductCode
                IsActive = true,
                product_line__c = 'SVC',
                Item_Class__c = '3',  // Use valid value to avoid Flow error
                IGOR_PAC__c = 'PAC4'
            );
            products.add(specialProductCode);
            
            // Product with valid Item_Class G
            Product2 validProductG = new Product2(
                Name = 'Valid Product G',
                ProductCode = 'VALIDG001',
                IsActive = true,
                product_line__c = 'DEF',
                Item_Class__c = 'G',  // Valid
                IGOR_PAC__c = 'PAC5'
            );
            products.add(validProductG);

            // Service products with valid Item_Class = F (valid for Service Contracts)
            Product2 serviceProduct3 = new Product2(
                Name = 'Service Product 3',
                ProductCode = 'ICPVALID003',
                IsActive = true,
                product_line__c = 'GC',
                Item_Class__c = 'F',  // Valid
                IGOR_PAC__c = 'V33'
            );
            products.add(serviceProduct3);

            // Service products with valid Item_Class = F (valid for Service Contracts)
            Product2 serviceProduct1 = new Product2(
                Name = 'Service Product 1',
                ProductCode = 'ICPVALID001',
                IsActive = true,
                product_line__c = 'GC',
                Item_Class__c = 'F',  // Valid
                IGOR_PAC__c = 'V11'
            );
            products.add(serviceProduct1);

            // Service products with valid Item_Class = F (valid for Service Contracts)
            Product2 serviceProduct4 = new Product2(
                Name = 'Service Product 4',
                ProductCode = 'ICPVALID004',
                IsActive = true,
                product_line__c = 'GC',
                Item_Class__c = 'F',  // Valid
                IGOR_PAC__c = 'V44'
            );
            products.add(serviceProduct4);

            // Service products with valid Item_Class = F (valid for Service Contracts)
            Product2 serviceProductF = new Product2(
                Name = 'Service Product F',
                ProductCode = 'ICPVALID00F',
                IsActive = true,
                product_line__c = 'GC',
                Item_Class__c = 'F',  // Valid
                IGOR_PAC__c = 'VFF'
            );
            products.add(serviceProductF);

            insert products;
            
            // Create Standard Pricebook (if not exists)
            Id standardPricebookId = Test.getStandardPricebookId();
            
            // Create Custom Pricebook
            Pricebook2 customPricebook = new Pricebook2(
                Name = 'Custom Pricebook',
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            insert customPricebook;
            
            // Create Pricebook Entries
            List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
            
            // Standard Pricebook Entries
            for (Product2 product : products) {
                pricebookEntries.add(new PricebookEntry(
                    Product2Id = product.Id,
                    Pricebook2Id = standardPricebookId,
                    UnitPrice = 100,
                    IsActive = true,
                    CurrencyIsoCode = 'USD'
                ));
            }
            
            // Custom Pricebook Entries
            for (Product2 product : products) {
                pricebookEntries.add(new PricebookEntry(
                    Product2Id = product.Id,
                    Pricebook2Id = customPricebook.Id,
                    UnitPrice = 150,
                    IsActive = true,
                    CurrencyIsoCode = 'USD'
                ));
            }
            
            insert pricebookEntries;
            
            List<SVMXC__Installed_Product__c> installedProducts = new List<SVMXC__Installed_Product__c>();
    
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Valid Installed Product',
                SMAX_PS_ModelNumber__c = 'ICPVALID003',
                SVMXC__Product__c = validProduct.Id,
                SVMXC__Serial_Lot_Number__c = 'SN12345'
            ));
            
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Item Class 1 Installed Product',
                SMAX_PS_ModelNumber__c = 'ICPVALID001',
                SVMXC__Product__c = itemClass1Product.Id,
                SVMXC__Serial_Lot_Number__c = 'SN67890'
            ));
            
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Item Class 4 Installed Product No Alt',
                SMAX_PS_ModelNumber__c = 'ICPVALID004',
                SVMXC__Product__c = itemClass4ProductNoAlt.Id,
                SVMXC__Serial_Lot_Number__c = 'SN11111'
            ));
            
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Special Product Code Installed',
                SMAX_PS_ModelNumber__c = 'ICPVALID00F',
                SVMXC__Product__c = specialProductCode.Id,
                SVMXC__Serial_Lot_Number__c = 'SN22222'
            ));
            
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Valid Product G Installed',
                SMAX_PS_ModelNumber__c = 'ICPVALID00F',
                SVMXC__Product__c = validProductG.Id,
                SVMXC__Serial_Lot_Number__c = 'SN33333'
            ));
            
            insert installedProducts;
            
            // Create Parent Service Contract
            SVMXC__Service_Contract__c parentContract = new SVMXC__Service_Contract__c(
                Name = 'Parent Contract',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0015ABC123',
                SMAX_PS_ItemPrice__c = 1000,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD'
            );
            insert parentContract;
            
            // Create Child Service Contracts
            List<SVMXC__Service_Contract__c> childContracts = new List<SVMXC__Service_Contract__c>();
            
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Valid',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035XYZ456',
                SMAX_PS_ItemPrice__c = 500,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id
            ));
            
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Item Class 1',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035ABC789',
                SMAX_PS_ItemPrice__c = 600,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id
            ));
            
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract No Product',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035DEF999',
                SMAX_PS_ItemPrice__c = 700,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id
            ));
            
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Invalid No Alt',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035GHI888',
                SMAX_PS_ItemPrice__c = 800,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id
            ));
            
            insert childContracts;
            
            installedProducts[0].SVMXC__Service_Contract__c = childContracts[0].Id;
            installedProducts[1].SVMXC__Service_Contract__c = childContracts[1].Id;
            installedProducts[2].SVMXC__Service_Contract__c = childContracts[3].Id;
            installedProducts[3].SVMXC__Service_Contract__c = childContracts[0].Id; // Different product for same contract
            installedProducts[4].SVMXC__Service_Contract__c = childContracts[1].Id; // Different product for same contract
            update installedProducts;
                    
            // Create Service Contract Products - ONE per child contract to avoid duplicates
            List<SVMXC__Service_Contract_Products__c> contractProducts = new List<SVMXC__Service_Contract_Products__c>();
            
            String slaTermsNotes = 'ZP01 Pricing Condition 1\nZP02 Pricing Condition 2';
            
            // Child Contract Valid - uses installedProducts[0]
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[0].Id,
                SVMXC__Installed_Product__c = installedProducts[0].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            
            // Child Contract Item Class 1 - uses installedProducts[1]
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[1].Id,
                SVMXC__Installed_Product__c = installedProducts[1].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            
            // No product for childContracts[2] - testing missing product scenario
            
            // Child Contract Invalid No Alt - uses installedProducts[2]
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[3].Id,
                SVMXC__Installed_Product__c = installedProducts[2].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            
            insert contractProducts;
        }
    }
    
	/**
     * Test the Flow invocable method createRenewalRecordsFromContract
     * Simplified test with single child contract to avoid duplicate issues.
     */
    @IsTest
    static void testCreateRenewalRecordsFromContract_Success() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        
        System.runAs(testUser) {
            // Create a new simple parent contract for this test
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
            Product2 validProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'VALID001' LIMIT 1];
            
            // Create Parent Service Contract
            SVMXC__Service_Contract__c testParentContract = new SVMXC__Service_Contract__c(
                Name = 'Test Parent Contract for Flow',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0015TESTFLOW',
                SMAX_PS_ItemPrice__c = 1000,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD'
            );
            insert testParentContract;
            
            // Create ONE Child Service Contract
            SVMXC__Service_Contract__c testChildContract = new SVMXC__Service_Contract__c(
                Name = 'Test Child Contract for Flow',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035TESTFLOW',
                SMAX_PS_ItemPrice__c = 500,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = testParentContract.Id
            );
            insert testChildContract;
            
            // Create ONE Installed Product linked to the child contract
            SVMXC__Installed_Product__c testInstalledProduct = new SVMXC__Installed_Product__c(
                Name = 'Test Installed Product for Flow',
                SVMXC__Product__c = validProduct.Id,
                SMAX_PS_ModelNumber__c = 'ICPVALID00F',
                SVMXC__Serial_Lot_Number__c = 'SNTEST123',
                SVMXC__Service_Contract__c = testChildContract.Id
            );
            insert testInstalledProduct;
            
            // Create ONE Service Contract Product with single-line format
            SVMXC__Service_Contract_Products__c testContractProduct = new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = testChildContract.Id,
                SVMXC__Installed_Product__c = testInstalledProduct.Id,
                SMAX_PS_SLA_Terms_Notes__c = 'ZP01-Pricing Condition Test'  // Single-line format
            );
            insert testContractProduct;
            
            // Prepare Flow input
            ContractRenewalDataManagement.FlowRequest request = new ContractRenewalDataManagement.FlowRequest();
            request.contractId = testParentContract.Id;
            
            List<ContractRenewalDataManagement.FlowRequest> requests = 
                new List<ContractRenewalDataManagement.FlowRequest>{request};
            
            Test.startTest();
            List<ContractRenewalDataManagement.FlowResult> results = 
                ContractRenewalDataManagement.createRenewalRecordsFromContract(requests);
            Test.stopTest();
            
            // Verify results
            System.assertEquals(1, results.size(), 'Should return one result');
            
            ContractRenewalDataManagement.FlowResult result = results[0];
            
            System.assertEquals(true, result.isSuccess, 'Operation should be successful. Error: ' + result.errorMessage);
            System.assertEquals(testParentContract.Id, result.contractId, 'Contract Id should match');
            System.assertNotEquals(null, result.opportunityId, 'Opportunity should be created');
            System.assertNotEquals(null, result.opportunityName, 'Opportunity Name should be set');
            System.assertNotEquals(null, result.quoteId, 'Quote should be created');
            System.assertNotEquals(null, result.quoteName, 'Quote Name should be set');
            System.assertEquals(1, result.quoteLineCount, 'Should create 1 quote line');
            
            // Verify Opportunity was created
            Opportunity createdOpp = [
                SELECT Id, Name, AccountId, Primary_Contact__c, Type, StageName
                FROM Opportunity
                WHERE Id = :result.opportunityId
            ];
            System.assertEquals(testAccount.Id, createdOpp.AccountId, 'Account should match');
            System.assertEquals('Warranty Conversion', createdOpp.Type, 'Type should be Warranty Conversion');
            
            // Verify Quote was created
            SBQQ__Quote__c createdQuote = [
                SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c
                FROM SBQQ__Quote__c
                WHERE Id = :result.quoteId
            ];
            System.assertEquals(result.opportunityId, createdQuote.SBQQ__Opportunity2__c, 'Quote should link to Opportunity');
            
            // Verify Quote Lines were created
            List<SBQQ__QuoteLine__c> createdQuoteLines = [
                SELECT Id, SBQQ__Product__c, Item_Class__c, SAP_Pricing_Condtions__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :result.quoteId
            ];
            System.assertEquals(1, createdQuoteLines.size(), 'Should have 1 quote line');
            System.assertEquals('F', createdQuoteLines[0].Item_Class__c, 'Item Class should be F');
            
            // Verify Pricing Conditions were created
            List<Pricing_Condition__c> pricingConditions = [
                SELECT Id, SAP_Pricing_Condition__c
                FROM Pricing_Condition__c
                WHERE Quote_Line__c IN :createdQuoteLines
            ];
            System.assertEquals(1, pricingConditions.size(), 
                               'Should have 1 Pricing Condition (ZP01 from single-line format)');
            System.assertEquals('ZP01', pricingConditions[0].SAP_Pricing_Condition__c,
                               'SAP code should be ZP01');
            
            // Verify Quote Line field was updated with SAP codes
            System.assertNotEquals(null, createdQuoteLines[0].SAP_Pricing_Condtions__c,
                                  'SAP_Pricing_Condtions__c field should be populated');
            System.assertEquals('ZP01', createdQuoteLines[0].SAP_Pricing_Condtions__c,
                               'Should contain ZP01');
        }
    }
    
    /**
     * Test Flow invocable method with blank Contract Id
     */
    @IsTest
    static void testCreateRenewalRecordsFromContract_BlankContractId() {
        ContractRenewalDataManagement.FlowRequest request = new ContractRenewalDataManagement.FlowRequest();
        request.contractId = '';
        
        List<ContractRenewalDataManagement.FlowRequest> requests = 
            new List<ContractRenewalDataManagement.FlowRequest>{request};
        
        Test.startTest();
        List<ContractRenewalDataManagement.FlowResult> results = 
            ContractRenewalDataManagement.createRenewalRecordsFromContract(requests);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Operation should fail');
        System.assert(results[0].errorMessage.contains('Contract Id is required'), 
                      'Error message should mention missing Contract Id');
    }
    
    /**
     * Test Flow invocable method with invalid Contract Id
     */
    @IsTest
    static void testCreateRenewalRecordsFromContract_InvalidContractId() {
        ContractRenewalDataManagement.FlowRequest request = new ContractRenewalDataManagement.FlowRequest();
        request.contractId = 'a0012345678901234'; // Invalid Id
        
        List<ContractRenewalDataManagement.FlowRequest> requests = 
            new List<ContractRenewalDataManagement.FlowRequest>{request};
        
        Test.startTest();
        List<ContractRenewalDataManagement.FlowResult> results = 
            ContractRenewalDataManagement.createRenewalRecordsFromContract(requests);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Operation should fail');
        System.assert(results[0].errorMessage.contains('Contract not found'), 
                      'Error message should mention contract not found');
    }
    
    /**
     * Test Flow invocable method with contract that has no child contracts
     */
    @IsTest
    static void testCreateRenewalRecordsFromContract_NoChildContracts() {
        // Create a standalone parent contract without children
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
            
            SVMXC__Service_Contract__c standAloneContract = new SVMXC__Service_Contract__c(
                Name = 'Stand Alone Contract',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today(),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0015STANDALONE',
                SMAX_PS_ItemPrice__c = 1000,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD'
            );
            insert standAloneContract;
            
            ContractRenewalDataManagement.FlowRequest request = new ContractRenewalDataManagement.FlowRequest();
            request.contractId = standAloneContract.Id;
            
            List<ContractRenewalDataManagement.FlowRequest> requests = 
                new List<ContractRenewalDataManagement.FlowRequest>{request};
            
            Test.startTest();
            List<ContractRenewalDataManagement.FlowResult> results = 
                ContractRenewalDataManagement.createRenewalRecordsFromContract(requests);
            Test.stopTest();
            
            System.assertEquals(1, results.size(), 'Should return one result');
            System.assertEquals(true, results[0].isSuccess, 'Operation should be successful');
            System.assertNotEquals(null, results[0].opportunityId, 'Opportunity should be created');
            System.assertNotEquals(null, results[0].quoteId, 'Quote should be created');
            System.assertEquals(null, results[0].quoteLineCount, 'No Quote Lines should be created');
            System.assert(results[0].errorMessage.contains('No child contracts found'), 
                          'Error message should mention no child contracts');
        }
    }
    
    /**
     * Test prepareQuoteLineData helper method
     */
    @IsTest
    static void testPrepareQuoteLineData() {
        List<SVMXC__Service_Contract__c> childContracts = [
            SELECT Id, Name, SMAX_PS_ItemPrice__c
            FROM SVMXC__Service_Contract__c 
            WHERE SVMX_PS_Parent_Contract__c != NULL
        ];
        
        Id pricebook2Id = Test.getStandardPricebookId();
        
        Test.startTest();
        ContractRenewalDataManagement.QuoteLineData data = 
            ContractRenewalDataManagement.prepareQuoteLineData(childContracts, pricebook2Id);
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'QuoteLineData should not be null');
        System.assertNotEquals(null, data.contractProducts, 'Contract Products map should not be null');
        System.assertNotEquals(null, data.products, 'Products map should not be null');
        System.assertNotEquals(null, data.pricebookEntries, 'Pricebook Entries map should not be null');
        
        // Verify data was populated
        System.assert(data.contractProducts.size() > 0, 'Should have contract products');
        System.assert(data.products.size() > 0, 'Should have products');
    }
    
    /**
     * Test createOpportunity method with Warranty Conversion type
     */
    @IsTest
    static void testCreateOpportunity_WarrantyConversion() {
        SVMXC__Service_Contract__c contract = [
            SELECT Id, Name, OwnerId, SVMXC__Company__c, SVMXC__Contact__c, 
                   SVMXC__End_Date__c, SVMX_PS_External_ID__c, SMAX_PS_SalesOrg__c,
                   SVMXC__Company__r.Name, SVMXC__Company__r.CurrencyIsoCode,
                   SVMXC__Company__r.fxPKICountryISOAlpha3__c
            FROM SVMXC__Service_Contract__c 
            WHERE Name = 'Parent Contract'
            LIMIT 1
        ];
        
        List<Pricebook2> activePricebooks = [
            SELECT Id, Name, IsActive 
            FROM Pricebook2 
            WHERE IsActive = TRUE
        ];
        
        Test.startTest();
        Opportunity opp = ContractRenewalDataManagement.createOpportunity(
            contract,
            UserInfo.getUserId(),
            activePricebooks
        );
        Test.stopTest();
        
        System.assertNotEquals(null, opp, 'Opportunity should be created');
        System.assertEquals(contract.SVMXC__Company__c, opp.AccountId, 'AccountId should match');
        System.assertEquals(contract.SVMXC__Contact__c, opp.Primary_Contact__c, 'Primary Contact should match');
        System.assertEquals('Warranty Conversion', opp.Type, 'Type should be Warranty Conversion');
        System.assertEquals('Stage 1 - Create', opp.StageName, 'Stage should be Stage 1 - Create');
    }
    
    /**
     * Test createQuote with valid contact
     */
    @IsTest
    static void testCreateQuote_ValidContact() {
        SVMXC__Service_Contract__c contract = [
            SELECT Id, Name, OwnerId, SVMXC__Company__c, SVMXC__Contact__c, 
                   SVMXC__End_Date__c, SVMX_PS_External_ID__c,
                   SVMXC__Company__r.Name, SVMXC__Company__r.CurrencyIsoCode,
                   SVMXC__Contact__r.AccountId
            FROM SVMXC__Service_Contract__c 
            WHERE Name = 'Parent Contract'
            LIMIT 1
        ];
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            Pricebook2Id =  Test.getStandardPricebookId()
        );
        insert opp;
        
        Test.startTest();
        SBQQ__Quote__c quote = ContractRenewalDataManagement.createQuote(
            contract,
            UserInfo.getUserId(),
            opp.Id,
            contract.SVMXC__Contact__r.AccountId,
            opp.Pricebook2Id
        );
        insert quote;
        Test.stopTest();
        
        SBQQ__Quote__c insertedQuote = [
            SELECT Id, End_User_Contact__c, SBQQ__PrimaryContact__c, Contract_Renewal_Error_Log__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        
        System.assertEquals(contract.SVMXC__Contact__c, insertedQuote.End_User_Contact__c, 'Contact should be set');
        System.assertEquals(contract.SVMXC__Contact__c, insertedQuote.SBQQ__PrimaryContact__c, 'Primary Contact should be set');
        System.assertEquals(null, insertedQuote.Contract_Renewal_Error_Log__c, 'Should not have error log');
    }
    
    /**
     * Test createQuote with invalid contact (wrong account)
     */
    @IsTest
    static void testCreateQuote_InvalidContact() {
        SVMXC__Service_Contract__c contract = [
            SELECT Id, Name, OwnerId, SVMXC__Company__c, SVMXC__Contact__c, 
                   SVMXC__End_Date__c, SVMX_PS_External_ID__c,
                   SVMXC__Company__r.Name, SVMXC__Company__r.CurrencyIsoCode
            FROM SVMXC__Service_Contract__c 
            WHERE Name = 'Parent Contract'
            LIMIT 1
        ];
        
        Account secondAccount = [SELECT Id FROM Account WHERE Name = 'Second Account' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = contract.SVMXC__Company__c,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            Pricebook2Id =  Test.getStandardPricebookId()
        );
        insert opp;
        
        Test.startTest();
        // Wrong account
        SBQQ__Quote__c quote = ContractRenewalDataManagement.createQuote(
            contract,
            UserInfo.getUserId(),
            opp.Id,
            secondAccount.Id,
            opp.Pricebook2Id
        );
        insert quote;
        
        ContractRenewalDataManagement.syncQuoteErrorsToOpportunity(quote);
        Test.stopTest();
        
        SBQQ__Quote__c insertedQuote = [
            SELECT Id, End_User_Contact__c, SBQQ__PrimaryContact__c, Contract_Renewal_Error_Log__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        
        System.assertEquals(null, insertedQuote.End_User_Contact__c, 'Contact should not be set');
        System.assertEquals(null, insertedQuote.SBQQ__PrimaryContact__c, 'Primary Contact should not be set');
        System.assertNotEquals(null, insertedQuote.Contract_Renewal_Error_Log__c, 'Should have error log');
        System.assert(insertedQuote.Contract_Renewal_Error_Log__c.contains('Contact does not belong to Account'), 'Error should mention contact mismatch');
        
        Opportunity updatedOpp = [
            SELECT Id, Contract_Renewal_Error_Log__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertNotEquals(null, updatedOpp.Contract_Renewal_Error_Log__c, 'Opportunity should have error log');
    }
    
    /**
     * Test createQuoteLine with valid product
     */
    @IsTest
    static void testCreateQuoteLine_ValidProduct() {
        SVMXC__Service_Contract__c childContract = [
            SELECT Id, SMAX_PS_ItemPrice__c, Name
            FROM SVMXC__Service_Contract__c 
            WHERE Name = 'Child Contract Valid'
            LIMIT 1
        ];
        
        SVMXC__Service_Contract_Products__c contractProduct = [
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
            WHERE SVMXC__Service_Contract__c = :childContract.Id
            LIMIT 1
        ];
        
        Product2 product = [
            SELECT Id, product_line__c, Item_Class__c, IGOR_PAC__c, ProductCode
            FROM Product2
            WHERE ProductCode = 'ICPVALID003'
            LIMIT 1
        ];

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :product.Id
            AND IsActive = TRUE
            AND Pricebook2Id = :standardPricebookId
            LIMIT 1
        ];
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            Pricebook2Id =  standardPricebookId
        );
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SalesType__c = 'Service Contracts',
            SBQQ__PriceBook__c = opp.Pricebook2Id
        );
        insert quote;
        
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts = 
            new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
        contractProducts.put(childContract.Id, new List<SVMXC__Service_Contract_Products__c>{contractProduct});
        
        Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
        pricebookEntries.put(product.Id, pbe);
        
        Map<String, Product2> products = new Map<String, Product2>();
        products.put(product.ProductCode, product);

        Map<Id, String> errorLogs = new Map<Id, String>();
        
        Test.startTest();
        SBQQ__QuoteLine__c quoteLine = ContractRenewalDataManagement.createQuoteLine(
            childContract,
            quote.Id,
            contractProducts,
            pricebookEntries,
            products,
            standardPricebookId,
            errorLogs
        );
        Test.stopTest();
        
        System.assertNotEquals(null, quoteLine, 'Quote Line should be created');
        System.assertEquals(product.Id, quoteLine.SBQQ__Product__c, 'Product should match');
        System.assertEquals('F', quoteLine.Item_Class__c, 'Item Class should be F');
        System.assertEquals(12, quoteLine.SBQQ__Quantity__c, 'Quantity should be 12');
        System.assert(errorLogs.isEmpty(), 'Should not have errors');
    }
    
    /**
     * Test createQuoteLine with no Service Contract Products
     */
    @IsTest
    static void testCreateQuoteLine_NoProducts() {
        SVMXC__Service_Contract__c childContract = [
            SELECT Id, SMAX_PS_ItemPrice__c, Name
            FROM SVMXC__Service_Contract__c 
            WHERE Name = 'Child Contract No Product'
            LIMIT 1
        ];
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SalesType__c = 'Service Contracts',
            SBQQ__PriceBook__c = opp.Pricebook2Id
        );
        insert quote;
        
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts = 
            new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
        // Empty - no products
        
        Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
        Map<String, Product2> products = new Map<String, Product2>();
        Map<Id, String> errorLogs = new Map<Id, String>();
        
        Test.startTest();
        SBQQ__QuoteLine__c quoteLine = ContractRenewalDataManagement.createQuoteLine(
            childContract,
            quote.Id,
            contractProducts,
            pricebookEntries,
            products,
            opp.Pricebook2Id,
            errorLogs
        );
        Test.stopTest();
        
        System.assertEquals(null, quoteLine, 'Quote Line should be null when no products');
        System.assert(!errorLogs.isEmpty(), 'Should have error log');
        System.assert(errorLogs.get(quote.Id).contains('No Service Contract Products found'), 'Error should mention missing products');
    }

    /**
     * Test createQuoteLinesWithErrorHandling wrapper method
     */
    @IsTest
    static void testCreateQuoteLinesWithErrorHandling() {
        List<SVMXC__Service_Contract__c> childContracts = [
            SELECT Id, SMAX_PS_ItemPrice__c, Name
            FROM SVMXC__Service_Contract__c 
            WHERE SVMX_PS_Parent_Contract__c != NULL
        ];
        
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
        ];
        
        Map<Id, List<SVMXC__Service_Contract_Products__c>> contractProducts = 
            new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
        
        for (SVMXC__Service_Contract_Products__c prod : allProducts) {
            if (!contractProducts.containsKey(prod.SVMXC__Service_Contract__c)) {
                contractProducts.put(prod.SVMXC__Service_Contract__c, new List<SVMXC__Service_Contract_Products__c>());
            }
            contractProducts.get(prod.SVMXC__Service_Contract__c).add(prod);
        }
        
        Set<Id> productIds = new Set<Id>();
        for (SVMXC__Service_Contract_Products__c prod : allProducts) {
            productIds.add(prod.SVMXC__Installed_Product__r.SVMXC__Product__c);
        }
        
        Map<String, Product2> products = new Map<String, Product2>();
        for (Product2 prod : [
            SELECT Id, product_line__c, Item_Class__c, IGOR_PAC__c, ProductCode
            FROM Product2
            WHERE Id IN :productIds
        ]) {
            products.put(prod.ProductCode, prod);
        }
        
        // Add Service products
        for (Product2 altProd : [
            SELECT Id, product_line__c, Item_Class__c, IGOR_PAC__c, ProductCode 
            FROM Product2 
            WHERE ProductCode LIKE 'ICP%'
        ]) {
            products.put(altProd.ProductCode, altProd);
            productIds.add(altProd.Id);
        }

        Id standardPricebookId = Test.getStandardPricebookId();

        Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id 
            FROM PricebookEntry 
            WHERE Product2Id IN :productIds
            AND IsActive = TRUE
        ]) {
            pricebookEntries.put(pbe.Product2Id, pbe);
        }
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebookId
        );
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SalesType__c = 'Service Contracts',
            SBQQ__PriceBook__c = standardPricebookId
        );
        insert quote;
        
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = ContractRenewalDataManagement.createQuoteLinesWithErrorHandling(
            childContracts,
            quote.Id,
            opp.Id,
            contractProducts,
            pricebookEntries,
            products,
            standardPricebookId
        );
        Test.stopTest();
        
        System.assertNotEquals(null, quoteLines, 'Quote Lines list should not be null');
        // Should have some valid quote lines (at least 1 from valid product)
        System.assert(quoteLines.size() > 0, 'Should have at least one valid quote line');
        
        // Check if errors were logged
        SBQQ__Quote__c updatedQuote = [
            SELECT Id, Contract_Renewal_Error_Log__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];
        
        // Should have errors logged for invalid products
        System.assertNotEquals(null, updatedQuote.Contract_Renewal_Error_Log__c, 'Should have error logs');
    }
    
     /**
     * Test updateQuoteLinesWithSAPCodes
     */
    @IsTest
    static void testUpdateQuoteLinesWithSAPCodes() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        
        System.runAs(testUser) {
            // Use test setup data
            Account testAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Id standardPricebookId = Test.getStandardPricebookId();

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = testAccount.Id,
                CloseDate = Date.today().addDays(30),
                StageName = 'Prospecting',
                Pricebook2Id = standardPricebookId
            );
            insert opp;
            
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Account__c = testAccount.Id,
                SBQQ__Status__c = 'Draft',
                SalesType__c = 'Service Contracts',
                SBQQ__PriceBook__c = standardPricebookId
            );
            insert quote;
            
            Product2 product = [SELECT Id, Item_Class__c FROM Product2 WHERE ProductCode = 'ICPVALID001' LIMIT 1];
            PricebookEntry pbe = [
                SELECT Id, Product2Id, Pricebook2Id
                FROM PricebookEntry
                WHERE Product2Id = :product.Id
                AND Pricebook2Id = :standardPricebookId
                AND IsActive = TRUE
                LIMIT 1
            ];

            // Create Quote Line with Item_Class__c to pass validation
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__PricebookEntryId__c = pbe.Id,
                SBQQ__Quantity__c = 1,
                Item_Class__c = product.Item_Class__c  // Required for validation
            );
            insert quoteLine;
            
            // Create Pricing Conditions
            List<Pricing_Condition__c> pricingConditions = new List<Pricing_Condition__c>();
            pricingConditions.add(new Pricing_Condition__c(
                Quote_Line__c = quoteLine.Id,
                SAP_Pricing_Condition__c = 'ZP01',
                Condition_Type__c = 'User Defined',
                CurrencyIsoCode = testAccount.CurrencyIsoCode
            ));
            pricingConditions.add(new Pricing_Condition__c(
                Quote_Line__c = quoteLine.Id,
                SAP_Pricing_Condition__c = 'ZP02',
                Condition_Type__c = 'User Defined',
                CurrencyIsoCode = testAccount.CurrencyIsoCode
            ));
            insert pricingConditions;
            
            // Create dummy contract product for map
            SVMXC__Service_Contract_Products__c contractProduct = [
                SELECT Id FROM SVMXC__Service_Contract_Products__c LIMIT 1
            ];
            
            Map<Id, SVMXC__Service_Contract_Products__c> quoteLineToProductMap = 
                new Map<Id, SVMXC__Service_Contract_Products__c>();
            quoteLineToProductMap.put(quoteLine.Id, contractProduct);
            
            Test.startTest();
            ContractRenewalDataManagement.updateQuoteLinesWithSAPCodes(quoteLineToProductMap);
            Test.stopTest();
            
            // Verify Quote Line was updated with SAP codes
            SBQQ__QuoteLine__c updatedQuoteLine = [
                SELECT Id, SAP_Pricing_Condtions__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :quoteLine.Id
            ];
            
            System.assertNotEquals(null, updatedQuoteLine.SAP_Pricing_Condtions__c, 
                                  'SAP Pricing Conditions should be set');
            System.assert(updatedQuoteLine.SAP_Pricing_Condtions__c.contains('ZP01'), 
                         'Should contain ZP01');
            System.assert(updatedQuoteLine.SAP_Pricing_Condtions__c.contains('ZP02'), 
                         'Should contain ZP02');
        }
    }
}
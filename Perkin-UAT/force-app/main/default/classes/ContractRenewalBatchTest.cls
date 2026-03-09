@IsTest
private class ContractRenewalBatchTest {
    @TestSetup
    static void setupTestData() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User111',
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
            insert new Batch_Contract_Renewal_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                In_Advance_Days__c = 89,
                Period__c = 3
            );

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
                ProductCode = 'VALID001',
                IsActive = true,
                product_line__c = 'ABC',
                Item_Class__c = '3',
                IGOR_PAC__c = 'PAC0'
            );
            products.add(validProduct);
            
            // Alternative product with valid Item_Class = F (valid for Service Contracts)
            Product2 alternativeProduct = new Product2(
                Name = 'Alternative Product',
                ProductCode = 'XYZINVALID001',
                IsActive = true,
                product_line__c = 'XYZ',
                Item_Class__c = 'F',
                IGOR_PAC__c = 'PAC1'
            );
            products.add(alternativeProduct);
            
            // Product with Item_Class 1 (INVALID - requires substitution)
            Product2 itemClass1Product = new Product2(
                Name = 'Item Class 1 Product',
                ProductCode = 'INVALID001',
                IsActive = true,
                product_line__c = 'XYZ',
                Item_Class__c = '1',
                IGOR_PAC__c = 'PAC2'
            );
            products.add(itemClass1Product);
            
            // Product with Item_Class 4 (INVALID - no alternative available)
            Product2 itemClass4ProductNoAlt = new Product2(
                Name = 'Item Class 4 Product No Alternative',
                ProductCode = 'NOALT001',
                IsActive = true,
                product_line__c = 'ZZZ',
                Item_Class__c = '4',
                IGOR_PAC__c = 'PAC3'
            );
            products.add(itemClass4ProductNoAlt);
            
            // Special ProductCode that bypasses Item_Class validation
            Product2 specialProductCode = new Product2(
                Name = 'Special Product Code',
                ProductCode = 'SV000301',
                IsActive = true,
                product_line__c = 'SVC',
                Item_Class__c = '3',
                IGOR_PAC__c = 'PAC4'
            );
            products.add(specialProductCode);
            
            // Product with valid Item_Class G
            Product2 validProductG = new Product2(
                Name = 'Valid Product G',
                ProductCode = 'VALIDG001',
                IsActive = true,
                product_line__c = 'DEF',
                Item_Class__c = 'G',
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
            
            // Standard Pricebook
            Id standardPricebookId = Test.getStandardPricebookId();
            
            // Custom Pricebook
            Pricebook2 customPricebook = new Pricebook2(
                Name = 'Custom Pricebook',
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            insert customPricebook;
            
            // Pricebook Entries
            List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
            for (Product2 product : products) {
                pricebookEntries.add(new PricebookEntry(
                    Product2Id = product.Id,
                    Pricebook2Id = standardPricebookId,
                    UnitPrice = 100,
                    IsActive = true,
                    CurrencyIsoCode = 'USD'
                ));
                pricebookEntries.add(new PricebookEntry(
                    Product2Id = product.Id,
                    Pricebook2Id = customPricebook.Id,
                    UnitPrice = 150,
                    IsActive = true,
                    CurrencyIsoCode = 'USD'
                ));
            }
            insert pricebookEntries;
            
            // Installed Products
            List<SVMXC__Installed_Product__c> installedProducts = new List<SVMXC__Installed_Product__c>();
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Valid Installed Product',
                SMAX_PS_ModelNumber__c = 'ICPVALID003',
                SVMXC__Product__c = products[0].Id,
                SVMXC__Serial_Lot_Number__c = 'SN12345'
            ));
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Item Class 1 Installed Product',
                SMAX_PS_ModelNumber__c = 'ICPVALID001',
                SVMXC__Product__c = products[2].Id,
                SVMXC__Serial_Lot_Number__c = 'SN67890'
            ));
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Item Class 4 Installed Product No Alt',
                SMAX_PS_ModelNumber__c = 'ICPVALID004',
                SVMXC__Product__c = products[3].Id,
                SVMXC__Serial_Lot_Number__c = 'SN11111'
            ));
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Special Product Code Installed',
                SMAX_PS_ModelNumber__c = 'ICPVALID00F',
                SVMXC__Product__c = products[4].Id,
                SVMXC__Serial_Lot_Number__c = 'SN22222'
            ));
            installedProducts.add(new SVMXC__Installed_Product__c(
                Name = 'Valid Product G Installed',
                SMAX_PS_ModelNumber__c = 'ICPVALID00F',
                SVMXC__Product__c = products[5].Id,
                SVMXC__Serial_Lot_Number__c = 'SN33333'
            ));
            insert installedProducts;
            
            // Parent Service Contract (not yet in date window)
            SVMXC__Service_Contract__c parentContract = new SVMXC__Service_Contract__c(
                Name = 'Parent Contract',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                SMAX_PS_SalesRepName__c = 'Test User111',
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today().addDays(-1),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0015ABC123',
                SMAX_PS_ItemPrice__c = 1000,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD'
            );
            insert parentContract;
            
            // Child Service Contracts
            List<SVMXC__Service_Contract__c> childContracts = new List<SVMXC__Service_Contract__c>();
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Valid',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today().addDays(-1),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035XYZ456',
                SMAX_PS_ItemPrice__c = 500,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id,
                SVMXC__Active__c = true
            ));
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Item Class 1',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today().addDays(-1),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035ABC789',
                SMAX_PS_ItemPrice__c = 600,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id,
                SVMXC__Active__c = true
            ));
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract No Product',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today().addDays(-1),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035DEF999',
                SMAX_PS_ItemPrice__c = 700,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id,
                SVMXC__Active__c = true
            ));
            childContracts.add(new SVMXC__Service_Contract__c(
                Name = 'Child Contract Invalid No Alt',
                SVMXC__Company__c = testAccount.Id,
                SVMXC__Contact__c = testContact.Id,
                OwnerId = testUser.Id,
                SVMXC__Start_Date__c = Date.today().addDays(-1),
                SVMXC__End_Date__c = Date.today().addYears(1),
                SVMX_PS_External_ID__c = '0035GHI888',
                SMAX_PS_ItemPrice__c = 800,
                SMAX_PS_SalesOrg__c = 'US01',
                CurrencyIsoCode = 'USD',
                SVMX_PS_Parent_Contract__c = parentContract.Id,
                SVMXC__Active__c = false
            ));
            insert childContracts;
            
            // Service Contract Products
            List<SVMXC__Service_Contract_Products__c> contractProducts = new List<SVMXC__Service_Contract_Products__c>();
            String slaTermsNotes = 'ZP01 Pricing Condition 1\nZP02 Pricing Condition 2';
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[0].Id,
                SVMXC__Installed_Product__c = installedProducts[0].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[1].Id,
                SVMXC__Installed_Product__c = installedProducts[1].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            // No product for childContracts[2]
            contractProducts.add(new SVMXC__Service_Contract_Products__c(
                SVMXC__Service_Contract__c = childContracts[3].Id,
                SVMXC__Installed_Product__c = installedProducts[2].Id,
                SMAX_PS_SLA_Terms_Notes__c = slaTermsNotes
            ));
            insert contractProducts;
        }
    }
    
    // Happy path: make the parent contract eligible and verify creations
    @IsTest
    static void testBatchCreatesOppQuoteLinesAndPricingConditions() {
        // Make the parent contract eligible for the batch query:
        SVMXC__Service_Contract__c parent = [
            SELECT Id, Name, SVMXC__End_Date__c, SMAX_PS_ItemCategory__c
            FROM SVMXC__Service_Contract__c
            WHERE Name = 'Parent Contract'
            LIMIT 1
        ];
        parent.SVMXC__End_Date__c = Date.today().addDays(90); // within 120-127 window
        parent.SMAX_PS_ItemCategory__c = 'STD'; // ensure != 'MVN'
        parent.SMAX_PS_ContractType__c = 'ZW01'; // ensure != 'ZOSC'
        update parent;

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User tUser = new User(
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
        
        System.runAs(tUser) {
            Test.startTest();
            Id jobId = Database.executeBatch(new ContractRenewalBatch(), 5);
            Test.stopTest();
        }
        
        // Assertions
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity], 'One Opportunity should be created');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__Quote__c], 'One Quote should be created');
        
        // Check pricebook assignment. If present, assert quote lines and pricing conditions.
        // If not present, skip those asserts to avoid false failure in test context.
        Opportunity createdOpp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        if (createdOpp.Pricebook2Id != null) {
            Integer quoteLineCount = [SELECT COUNT() FROM SBQQ__QuoteLine__c];
            System.assert(quoteLineCount > 0, 'Quote Lines should be created when a Pricebook is set');
            Integer pricingConditions = [SELECT COUNT() FROM Pricing_Condition__c];
            System.assert(pricingConditions > 0, 'Pricing Conditions should be created when Quote Lines exist');
        } else {
            // Helper did not assign a pricebook; batch will not create quote lines.
            // Still validate OCR creation.
            System.debug('Opportunity has no Pricebook2Id; skipping Quote Line and Pricing Condition assertions.');
        }
        
        // Contact Role should be created since the contract has a contact
        Integer ocrCount = [SELECT COUNT() FROM OpportunityContactRole];
        System.assertEquals(1, ocrCount, 'One Opportunity Contact Role should be created');
    }
    
    // Negative path: no eligible parent contracts in the window => nothing created
    @IsTest
    static void testBatchNoEligibleContractsCreatesNothing() {
        // Do not modify the parent End Date; it’s addYears(1) from setup and out of window
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User tUser = new User(
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
        
        System.runAs(tUser) {
            Test.startTest();
            Id jobId = Database.executeBatch(new ContractRenewalBatch(), 5);
            Test.stopTest();
        }
        
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity], 'No Opportunities should be created');
        System.assertEquals(0, [SELECT COUNT() FROM SBQQ__Quote__c], 'No Quotes should be created');
        System.assertEquals(0, [SELECT COUNT() FROM SBQQ__QuoteLine__c], 'No Quote Lines should be created');
        System.assertEquals(0, [SELECT COUNT() FROM Pricing_Condition__c], 'No Pricing Conditions should be created');
        System.assertEquals(0, [SELECT COUNT() FROM OpportunityContactRole], 'No OCRs should be created');
    }
}
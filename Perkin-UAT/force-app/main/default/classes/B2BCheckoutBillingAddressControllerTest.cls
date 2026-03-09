@isTest
public class B2BCheckoutBillingAddressControllerTest {

    @TestSetup static void makeData(){
        WebStore webStore = B2B_TestDataFactory.createWebstore('TestWebStore',true);

        Account account = B2B_TestDataFactory.createAccount('Test Account', true);
        Contact contact = B2B_TestDataFactory.createContact('Test Contact', account.Id, true);
        User user = B2B_TestDataFactory.createUser('test', 'test@gmail.com', contact.Id, true);

        User guestUser = B2B_TestDataFactory.createGuestUser('GuestTest', 'guesttest@gmail.com', contact.Id, true);
        Account tempAcc;
        System.runAs(guestUser) {
            tempAcc = B2B_TestDataFactory.createAccount('Test Account Guest', true);
        }

        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(account, true);

        WebCart cart = B2B_TestDataFactory.createCart(account.Id, user.Id, webStore.Id, cpa.Id, true);

        ContactPointAddress cpa1 = new ContactPointAddress(
            AddressType = 'Billing',
            ParentId = account.Id,
            Street = '123 Main St',
            City = 'TestCity',
            State = 'CA',
            PostalCode = '12345',
            Country = 'US',
            AddressFirstName = 'John',
            AddressLastName = 'Doe',
            Name = 'John Doe'
        );
        insert cpa1;

        ContactPointAddress cpa2 = new ContactPointAddress(
            AddressType = 'Billing',
            ParentId = tempAcc.Id,
            Street = '123 Main St',
            City = 'TestCity',
            State = 'CA',
            PostalCode = '12345',
            Country = 'US',
            AddressFirstName = 'John',
            AddressLastName = 'Doe',
            Name = 'John Doe'
        );
        insert cpa2;
    }

    @isTest
    static void testValidateAddress() {
        Test.setMock(HttpCalloutMock.class, new B2BCheckoutBillingAddressControllerMock());

        // Full AddressWrapper
        B2BCheckoutBillingAddressController.AddressWrapper address = new B2BCheckoutBillingAddressController.AddressWrapper();
        address.street = '123 Main St';
        address.subpremise = 'STE 200';
        address.city = 'New York';
        address.region = 'NY';
        address.postalCode = '10001';
        address.country = 'US';

        Test.startTest();
        B2BCheckoutBillingAddressController.AddressValidationResponse response = 
            B2BCheckoutBillingAddressController.validateAddress(address);
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    static void testValidateAddress_Invalid() {
        Test.setMock(HttpCalloutMock.class, new B2BCheckoutBillingAddressControllerMock());

        B2BCheckoutBillingAddressController.AddressWrapper address = new B2BCheckoutBillingAddressController.AddressWrapper();
        address.street = null;
        address.subpremise = null;
        address.city = null;
        address.region = null;
        address.postalCode = null;
        address.country = null;

        Test.startTest();
        B2BCheckoutBillingAddressController.AddressValidationResponse response = 
            B2BCheckoutBillingAddressController.validateAddress(address);
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    static void testUpdateBillingAddressOnCart() {
        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        User user = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];

        B2BCheckoutBillingAddressController.AddressWrapper address = new B2BCheckoutBillingAddressController.AddressWrapper();
        address.firstName = 'Test';
        address.lastName = 'Test';
        address.street = '456 Test St';
        address.city = 'San Francisco';
        address.region = 'CA';
        address.postalCode = '94107';
        address.country = 'US';

        Test.startTest();
        System.runAS(user) {
            B2BCheckoutBillingAddressController.updateBiilingAddressOnCart(address);
        }
        Test.stopTest();

        WebCart updatedCart = [SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                                FROM WebCart WHERE Id = :cart.Id LIMIT 1];
        System.assertEquals('456 Test St', updatedCart.BillingStreet);
        System.assertEquals('San Francisco', updatedCart.BillingCity);
    }

    @isTest
    static void testGetExistingBillingAddress() {
        WebCart cart = [
            SELECT Id, Billing_FirstName__c, Billing_LastName__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM WebCart 
            WHERE Name = 'Cart' 
            LIMIT 1
        ];

        cart.Billing_FirstName__c = 'John';
        cart.Billing_LastName__c = 'Doe';
        cart.BillingStreet = '789 Test Blvd';
        cart.BillingCity = 'Chicago';
        cart.BillingState = 'IL';
        cart.BillingPostalCode = '60616';
        cart.BillingCountry = 'US';
        update cart;

        Test.startTest();
        WebCart result = B2BCheckoutBillingAddressController.getExistingBillingAddress(cart.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('789 Test Blvd', result.BillingStreet);
    }

    @isTest
    static void testExceptionHandling() {
        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];

        B2BCheckoutBillingAddressController.AddressWrapper address = new B2BCheckoutBillingAddressController.AddressWrapper();

        Test.startTest();
        B2BCheckoutBillingAddressController.hasException = true;
        B2BCheckoutBillingAddressController.updateBiilingAddressOnCart(address);
        B2BCheckoutBillingAddressController.getExistingBillingAddress(cart.Id);
        Test.stopTest();
    }


    @isTest
    static void testGetBillingCpaExistHelper_MatchFound() {

        Id accountId = [SELECT Id FROM Account WHERE Name =: 'Test Account' LIMIT 1].Id;
        // Build mapParams
        Map<Object, Object> rawBillingAddress = new Map<Object, Object>{
            'street'     => '123 Main St',
            'city'       => 'TestCity',
            'region'     => 'CA',
            'postalCode' => '12345',
            'country'    => 'US',
            'firstName'  => 'John',
            'lastName'   => 'Doe'
        };

        Map<String, Object> inputParams = new Map<String, Object>{
            'accountId' => accountId,
            'billingAddress' => rawBillingAddress
        };

        // Call method
        Map<String, Object> result = B2BCheckoutBillingAddressController.getBillingCpaExist(inputParams);

        System.assertEquals(true, result.containsKey('isDuplicate'));
    }

     @isTest
    static void testGetExistingBillingAddressForTempAccount() {
        Account account = [SELECT Id, Name, Temp_eComm_Acct__c from Account WHERE Name =: 'Test Account Guest' LIMIT 1];
        System.debug('Account :: ' + account);

        WebCart cart = [
            SELECT Id, AccountId, Billing_FirstName__c, Billing_LastName__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM WebCart 
            WHERE Name = 'Cart' 
            LIMIT 1
        ];

        cart.Billing_FirstName__c = 'John';
        cart.Billing_LastName__c = 'Doe';
        cart.BillingStreet = '789 Test Blvd';
        cart.BillingCity = 'Chicago';
        cart.BillingState = 'IL';
        cart.BillingPostalCode = '60616';
        cart.BillingCountry = 'US';
        cart.AccountId = account.Id;
        update cart;

        Test.startTest();
        WebCart result = B2BCheckoutBillingAddressController.getExistingBillingAddress(cart.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('789 Test Blvd', result.BillingStreet);
    }
    
         @isTest
    static void testGetExistingOrders() {
        Account account = [SELECT Id, Name, Temp_eComm_Acct__c from Account WHERE Name =: 'Test Account Guest' LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('accountId', account.Id);
        Test.startTest();
        Map<String,Object> mapParamsRes = B2BCheckoutBillingAddressController.getExistingOrders(mapParams);
        Test.stopTest();

        System.assertNotEquals(null, mapParamsRes);
    }
}
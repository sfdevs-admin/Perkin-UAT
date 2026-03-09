/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 09-06-2025
 * @last modified by  : S.T
 * @TestClass         : B2BCheckoutBillingAddressControllerTest
**/
public class B2BCheckoutBillingAddressService {

    public static B2BCheckoutBillingAddressController.AddressValidationResponse validateAddress(String address) {
        List<B2B_Google_Address_Validation_API_Key__mdt> apiKey = B2B_Google_Address_Validation_API_Key__mdt.getAll().values();
        String payload = '{ "address": {"regionCode": "US", "addressLines": ' + address + '}}';
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:B2B_Google_Address_Validation_API?key='+apiKey[0].apiKey__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            String jsonResponse = response.getBody();
            System.debug('Address Validation Response: ' + jsonResponse);

            return parseAddressValidationResponse(jsonResponse);
        } 
        else {
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
            System.debug('Response Body: ' + response.getBody());

            return null;
        }
    }

    public static B2BCheckoutBillingAddressController.AddressValidationResponse parseAddressValidationResponse(String jsonResponse) {
        B2BCheckoutBillingAddressController.AddressValidationResponse addressValidationResponse = new B2BCheckoutBillingAddressController.AddressValidationResponse();
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);

        if (result != null && result.containsKey('result')) {
            Map<String, Object> resultObject = (Map<String, Object>)result.get('result');

            // Get Standardized Address From uspsData
            String standardizedAddressLine;
            String standardizedStreet = '';
            String standardizedSubpremise = '';
            String standardizedCityStateZipAddressLine;
            String standardizedCity;
            String standardizedState;
            String standardizedZipCode;

            if (resultObject != null && resultObject.containsKey('uspsData')) {
                Map<String, Object> uspsData = (Map<String, Object>)resultObject.get('uspsData');

                if (uspsData != null && uspsData.containsKey('standardizedAddress')) {
                    Map<String, Object> standardizedAddressFields = (Map<String, Object>) uspsData.get('standardizedAddress');
                    standardizedAddressLine = (String)standardizedAddressFields.get('firstAddressLine');
                    
                    //Split the firstAddressLine to display street and subpremise seperately
                    String[] addressLine = standardizedAddressLine.split(' ');
                    Boolean isSubpremise = false;
                    
                    for (Integer i = 0; i < addressLine.size(); i++) {
                        String word = addressLine[i];
                        if(!isSubpremise && word != 'STE' && word != 'APT' && word != 'UNIT' && word != '#') {
                            standardizedStreet += word + ' ';
                        }
                        else {
                            isSubpremise = true;
                            standardizedSubpremise += word + ' ';
                        }
                    }

                    standardizedCityStateZipAddressLine = (String)standardizedAddressFields.get('cityStateZipAddressLine');
                    standardizedCity = (String)standardizedAddressFields.get('city');
                    standardizedState = (String)standardizedAddressFields.get('state');
                    standardizedZipCode = (String)standardizedAddressFields.get('zipCode');
                    addressValidationResponse.address = standardizedAddressLine + ', ' +  standardizedCityStateZipAddressLine + ', ' + 'US';
                }
            }            

            if (resultObject != null && resultObject.containsKey('address')) {
                Map<String, Object> addressObject = (Map<String, Object>)resultObject.get('address');
                addressValidationResponse.isValid = true;

                if (addressObject != null && addressObject.containsKey('postalAddress')) {
                    Map<String, Object> postalAddress = (Map<String, Object>)addressObject.get('postalAddress');
                    if(postalAddress != null && postalAddress.containsKey('regionCode')) {
                        addressValidationResponse.country = (String) postalAddress.get('regionCode');
                    }
                }

                if (addressObject != null && addressObject.containsKey('addressComponents')) {
                    List<Object> addressComponents = (List<Object>)addressObject.get('addressComponents');

                    Set<String> unconfirmedAttributes = new Set<String>();

                    for (Object component : addressComponents) {
                        Map<String, Object> addressComponent = (Map<String, Object>)component;

                        if (addressComponent != null && addressComponent.containsKey('componentName')) {
                            Map<String, Object> componentName = (Map<String, Object>)addressComponent.get('componentName');

                            if (componentName != null) {
                                String text = (String)componentName.get('text');
                                String confirmationLevel = (String)addressComponent.get('confirmationLevel');
                                String componentType = (String)addressComponent.get('componentType');

                                if (text != null && confirmationLevel != null && componentType != null) {
                                    
                                    System.debug(componentType + ' - ' + text + ': ' + confirmationLevel);
                                
                                    Boolean replaced = addressComponent.containsKey('replaced') ? (Boolean)addressComponent.get('replaced') : false;
                                    System.debug('Replaced: ' + replaced);

                                    if (componentType == 'route') {
                                        addressValidationResponse.route = text;
                                    }
                                    else if (componentType == 'street_number') {
                                        addressValidationResponse.streetNumber = text;
                                    } 
                                    else if (componentType == 'post_box') {
                                        addressValidationResponse.streetNumber = text;
                                    }
                                    else if (componentType == 'subpremise') {
                                        addressValidationResponse.subpremise = standardizedSubpremise;
                                    }
                                    else if (componentType == 'locality') {
                                        addressValidationResponse.city = text;
                                    }
                                    else if (componentType == 'administrative_area_level_1') {
                                        addressValidationResponse.state = text;
                                    }
                                    else if (componentType == 'postal_code') {
                                        addressValidationResponse.postalCode = text;
                                    }
                                    if (addressValidationResponse.streetNumber == null ) {
                                        addressValidationResponse.street = addressValidationResponse.route;
                                    }
                                    else if (addressValidationResponse.route == null ) {
                                        addressValidationResponse.street = addressValidationResponse.streetNumber;
                                    }
                                    else {
                                        addressValidationResponse.street = addressValidationResponse.streetNumber + ' ' + addressValidationResponse.route;
                                    }

                                    if (!confirmationLevel.equals('CONFIRMED') && 
                                        (componentType != 'subpremise' || !confirmationLevel.equals('UNCONFIRMED_BUT_PLAUSIBLE'))) {
                                        String sfFieldName = mapGoogleUnconfirmedToSf((String)componentType);
                                        unconfirmedAttributes.add(sfFieldName);

                                        // Replace the addressValidationResponse var to correct text
                                        switch on componentType {
                                            when 'street_number', 'route', 'post_box' {
                                                addressValidationResponse.street = standardizedStreet;
                                            }
                                            when 'subpremise' {
                                                addressValidationResponse.subpremise = standardizedSubpremise;
                                            }
                                            when 'locality' {
                                                addressValidationResponse.city = standardizedCity;
                                            }
                                            when 'administrative_area_level_1' {
                                                addressValidationResponse.state = standardizedState;
                                            }
                                            when 'postal_code' {
                                                addressValidationResponse.postalCode = standardizedZipCode;
                                            }
                                            when else {
                                                System.debug('default');
                                            }
                                        }
                                    }
                                } 
                                else {
                                    System.debug('Text, confirmationLevel, or componentType is null');
                                }
                            } 
                            else {
                                System.debug('ComponentName is null');
                            }
                        } 
                        else {
                            System.debug('AddressComponent or ComponentName is null');
                        }
                    }

                    if (addressObject.containsKey('missingComponentTypes')) {
                        List<Object> missingComponentTypes = (List<Object>)addressObject.get('missingComponentTypes');
                        Set<String> missingComponentTypesString = new Set<String>();

                        for (Object missingComponent : missingComponentTypes) {
                            if (missingComponent instanceof String) {
                                String sfFieldName = mapGoogleUnconfirmedToSf((String)missingComponent);
                                missingComponentTypesString.add(sfFieldName);
                                if (sfFieldName != null) {
                                    addressValidationResponse.isValid = false;
                                }
                                
                            }
                        }

                        unconfirmedAttributes.addAll(missingComponentTypesString);
                    }
                    
                    addressValidationResponse.invalidFields = unconfirmedAttributes;
                    return addressValidationResponse;
                } 
                else {
                    System.debug('addressComponents not found in addressObject');
                }
            } 
            else {
                System.debug('address not found in resultObject');
            }
        } 
        else {
            System.debug('result not found in JSON response');
        }
        return null;
    }

    private static String mapGoogleUnconfirmedToSf(String line) {
        if (line == 'route') {
            return 'street';
        }
        else if (line == 'street_number') {
            return 'street';
        }
        else if (line == 'locality'){
            return 'city';
        }
        else if (line == 'administrative_area_level_1') {
            return 'province';
        }
        else if (line == 'country') {
            return 'country';
        }
        else if  (line == 'postal_code'){
            return 'postalCode';
        }
        return null;
    }

    public static void updateBiilingAddressOnCart(B2BCheckoutBillingAddressController.AddressWrapper address) {
        String userId = UserInfo.getUserId();
        List <WebCart> carts = [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            FROM WebCart 
            WHERE (Status = 'Checkout' OR Status = 'Active') 
            AND OwnerId = :userId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        if (!carts.isEmpty()) {
            WebCart currentCart = carts[0];
            currentCart.Billing_FirstName__c = address.firstName;
            currentCart.Billing_LastName__c = address.lastName;
            currentCart.BillingStreet = address.street;
            currentCart.BillingCity = address.city;
            currentCart.BillingState = address.region;
            currentCart.BillingPostalCode = address.postalCode;
            currentCart.BillingCountry = address.country;
            
            update currentCart;
        }
    }

    /** 
     * @description : Log payment exception after payment on Checkout Page.
     * @param : 
     * @return : Map<String,Object>
    **/
    public static Map<String,Object> logExceptionForPayment(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';

        if(mapParams != null && mapParams.containsKey('recordId') && mapParams.get('recordId') != null 
            && mapParams.containsKey('exceptionMsg') && mapParams.get('exceptionMsg') != null 
            && mapParams.containsKey('exceptionType') && mapParams.get('exceptionType') != null
            && mapParams.containsKey('category') && mapParams.get('category') != null 
            && mapParams.containsKey('subCategory') && mapParams.get('subCategory') != null 
        ) {
            
            
            Custom_Exception__c exc = new Custom_Exception__c();
            exc.Name = 'Checkout Exceptions';
            exc.Exception_Messages__c = (String) mapParams.get('exceptionMsg');
            exc.Exception_Type__c = (String) mapParams.get('exceptionType');
            exc.Category__c = (String) mapParams.get('category');
            exc.Sub_Category__c = (String) mapParams.get('subCategory');
            exc.Cart_Id__c = (Id) mapParams.get('recordId');
            if(mapParams.containsKey('requestJson')){
                exc.Request_JSON__c = (String) mapParams.get('requestJson');
            }
            insert exc;

            isSuccess = true;
        } else {
            message = 'Invalid or missing mapParams';
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        return mapParams;
    }


    // update the cart first with billing address from Account when Account is Temp_eComm_Acct__c == false
    public static WebCart getExistingBillingAddress(String cartId) {
        List<WebCart> carts = [
            SELECT Id, Billing_FirstName__c, Billing_LastName__c, BillingStreet, BillingCity,
                BillingState, BillingPostalCode, BillingCountry, AccountId, CreatedDate
            FROM WebCart
            WHERE Id = :cartId
            LIMIT 1
        ];

        if (carts.isEmpty()) {
            return null; // No cart found
        }

        WebCart cart = carts[0];

        if (cart.AccountId != null) {
            List<Account> accounts = [
                SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                    BillingCountry, Temp_eComm_Acct__c
                FROM Account
                WHERE Id = :cart.AccountId
                LIMIT 1
            ];

            if (!accounts.isEmpty()) {
                Account acc = accounts[0];

                if (acc.Temp_eComm_Acct__c == false) {
                    String firstName;
                    String lastName;

                    User usr = [
                        SELECT Contact.FirstName, Contact.LastName
                        FROM User
                        WHERE Id = :UserInfo.getUserId()
                        LIMIT 1
                    ];

                    if (String.isBlank(usr.Contact.FirstName) || String.isBlank(usr.Contact.LastName)) {
                        firstName = UserInfo.getFirstName();
                        lastName  = UserInfo.getLastName();
                    } else {
                        firstName = usr.Contact.FirstName;
                        lastName  = usr.Contact.LastName;
                    }

                    B2BCheckoutBillingAddressController.AddressWrapper addr = new B2BCheckoutBillingAddressController.AddressWrapper();
                    addr.street      = acc.BillingStreet;
                    addr.city        = acc.BillingCity;
                    addr.region      = acc.BillingState;
                    addr.postalCode  = acc.BillingPostalCode;
                    addr.country     = acc.BillingCountry;
                    addr.firstName   = firstName;
                    addr.lastName    = lastName;

                    updateBiilingAddressOnCart(addr);

                    carts = getUpdatedCart(cart.Id);
                    //  [
                    //     SELECT Id, Billing_FirstName__c, Billing_LastName__c, BillingStreet, BillingCity,
                    //         BillingState, BillingPostalCode, BillingCountry
                    //     FROM WebCart
                    //     WHERE Id = :cart.Id
                    //     LIMIT 1
                    // ];
                } else {
                    List<ContactPointAddress> existingAddresses = [
                        SELECT Id, Street, City, State, PostalCode, Country,
                            AddressFirstName, AddressLastName
                        FROM ContactPointAddress
                        WHERE AddressType = 'Billing' 
                            AND ParentId = :acc.Id 
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];

                    if (!existingAddresses.isEmpty()) {
                        ContactPointAddress billingAddr = existingAddresses[0];

                        B2BCheckoutBillingAddressController.AddressWrapper addr = new B2BCheckoutBillingAddressController.AddressWrapper();
                        addr.street      = billingAddr.Street;
                        addr.city        = billingAddr.City;
                        addr.region      = billingAddr.State;
                        addr.postalCode  = billingAddr.PostalCode;
                        addr.country     = billingAddr.Country;
                        addr.firstName   = billingAddr.AddressFirstName;
                        addr.lastName    = billingAddr.AddressLastName;

                        updateBiilingAddressOnCart(addr);
                        carts = getUpdatedCart(cart.Id);
                    }
                }
            }
        }

        return carts.isEmpty() ? null : carts[0];
    }

    // helper method to requery cart
    private static List<WebCart> getUpdatedCart(Id cartId) {
        return [
            SELECT Id, Billing_FirstName__c, Billing_LastName__c, BillingStreet, BillingCity,
                BillingState, BillingPostalCode, BillingCountry
            FROM WebCart
            WHERE Id = :cartId
            LIMIT 1
        ];
    }

    //validate billing CPA address is exist or not 
     public static Map<String, Object> getBillingCpaExistHelper(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        mapParams.put('isDuplicate', false); // default

        if (mapParams == null || !mapParams.containsKey('accountId') || !mapParams.containsKey('billingAddress')) {
            return mapParams;
        }

        Id accountId = (Id) mapParams.get('accountId');
        Object rawBillingAddress = mapParams.get('billingAddress');

        Map<String, Object> billingMapRaw = new Map<String, Object>();
        if (rawBillingAddress instanceof Map<Object, Object>) {
            Map<Object, Object> tempMap = (Map<Object, Object>) rawBillingAddress;
            for (Object key : tempMap.keySet()) {
                billingMapRaw.put(String.valueOf(key), tempMap.get(key));
            }
        }

        String street     = (String) billingMapRaw.get('street');
        String city       = (String) billingMapRaw.get('city');
        String state      = (String) billingMapRaw.get('region');
        String postalCode = (String) billingMapRaw.get('postalCode');
        String country    = (String) billingMapRaw.get('country');
        String firstName  = (String) billingMapRaw.get('firstName');
        String lastName   = (String) billingMapRaw.get('lastName');

        if (accountId == null) {
            return mapParams;
        }

        List<ContactPointAddress> existingAddresses = [
            SELECT Id, Street, City, State, PostalCode, Country, 
                   AddressFirstName, AddressLastName
            FROM ContactPointAddress
            WHERE AddressType = 'Billing' AND ParentId = :accountId
        ];

        if (existingAddresses.isEmpty()) {
            return mapParams; // nothing to compare
        }


        for (ContactPointAddress addr : existingAddresses) {
            if (
                stringEquals(addr.Street, street) &&
                stringEquals(addr.City, city) &&
                stringEquals(addr.State, state) &&
                stringEquals(addr.PostalCode, postalCode) &&
                stringEquals(addr.Country, country) &&
                stringEquals(addr.AddressFirstName, firstName) &&
                stringEquals(addr.AddressLastName, lastName)
            ) {
                mapParams.put('isDuplicate', true);
                mapParams.put('isSuccess', true);
                break;
            }

        }

        return mapParams;
    }
    private static Boolean stringEquals(String s1, String s2) {
        return String.isBlank(s1) && String.isBlank(s2) ? true
             : (s1 != null && s1.equalsIgnoreCase(s2?.trim()));
    }


    public static Map<String,Object> getExistingOrders(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        if(
            mapParams != null && mapParams.containsKey('accountId') && mapParams.get('accountId') != null 
        ) {
            Id accountId = (Id) mapParams.get('accountId');
            Id userId = UserInfo.getUserId();
            List<Order> existingOrderList = [ SELECT Id FROM Order WHERE AccountId = :accountId AND OwnerId = :userId ];
            mapParams.put('existingOrderList', existingOrderList);
            mapParams.put('existingOrderListSize', existingOrderList.size());
            isSuccess = true;
        } else {
            message = 'Invalid or missing mapParams';
        }

        mapParams.put('isSuccess', isSuccess);
        mapParams.put('msg', message);
        return mapParams;
    }
}
@isTest
private class BD_AddressGeoTimezone_UT {

	class MockHttpResponseGenerator implements HttpCalloutMock {
		// Implement this interface method
		public HttpResponse respond(HttpRequest req) {
			System.debug('Entered MockHttpResponseGenerator');
			// Optionally, only send a mock response for a specific endpoint and method.
			System.assertEquals('GET', req.getMethod());

			// Create a fake response
			System.debug('Endpoint for Request: ' + req.getEndpoint());
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"example":"test"}');
			if (req.getEndpoint().contains('callout:BD_GoogleMapsAPI/geocode/json')) {
				res.setBody('{\n' +
						'   "results" : [\n' +
						'      {\n' +
						'         "address_components" : [\n' +
						'            {\n' +
						'               "long_name" : "1600",\n' +
						'               "short_name" : "1600",\n' +
						'               "types" : [ "street_number" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "Amphitheatre Parkway",\n' +
						'               "short_name" : "Amphitheatre Pkwy",\n' +
						'               "types" : [ "route" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "Mountain View",\n' +
						'               "short_name" : "Mountain View",\n' +
						'               "types" : [ "locality", "political" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "Santa Clara County",\n' +
						'               "short_name" : "Santa Clara County",\n' +
						'               "types" : [ "administrative_area_level_2", "political" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "California",\n' +
						'               "short_name" : "CA",\n' +
						'               "types" : [ "administrative_area_level_1", "political" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "United States",\n' +
						'               "short_name" : "US",\n' +
						'               "types" : [ "country", "political" ]\n' +
						'            },\n' +
						'            {\n' +
						'               "long_name" : "94043",\n' +
						'               "short_name" : "94043",\n' +
						'               "types" : [ "postal_code" ]\n' +
						'            }\n' +
						'         ],\n' +
						'         "formatted_address" : "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",\n' +
						'         "geometry" : {\n' +
						'            "location" : {\n' +
						'               "lat" : 37.4237754,\n' +
						'               "lng" : -122.0853195\n' +
						'            },\n' +
						'            "location_type" : "ROOFTOP",\n' +
						'            "viewport" : {\n' +
						'               "northeast" : {\n' +
						'                  "lat" : 37.42512438029149,\n' +
						'                  "lng" : -122.0839705197085\n' +
						'               },\n' +
						'               "southwest" : {\n' +
						'                  "lat" : 37.42242641970849,\n' +
						'                  "lng" : -122.0866684802915\n' +
						'               }\n' +
						'            }\n' +
						'         },\n' +
						'         "place_id" : "ChIJVYBZP-Oxj4ARls-qJ_G3tgM",\n' +
						'         "plus_code" : {\n' +
						'            "compound_code" : "CWF7+GV Mountain View, CA, USA",\n' +
						'            "global_code" : "849VCWF7+GV"\n' +
						'         },\n' +
						'         "types" : [ "street_address" ]\n' +
						'      }\n' +
						'   ],\n' +
						'   "status" : "OK"\n' +
						'}');
			} else if (req.getEndpoint().contains('callout:BD_GoogleMapsAPI/timezone/json')) {
				res.setBody('{\n' +
						'   "dstOffset" : 3600,\n' +
						'   "rawOffset" : -28800,\n' +
						'   "status" : "OK",\n' +
						'   "timeZoneId" : "America/Los_Angeles",\n' +
						'   "timeZoneName" : "Pacific Daylight Time"\n' +
						'}');
			}

			res.setStatusCode(200);
			System.debug('Leaving MockHttpResponseGenerator');
			return res;
		}
	}

	@isTest static void testAddressBatch() {

		SVMXC__Site__c loc = new SVMXC__Site__c(Name = 'TstSite');
		loc.SVMXC__Street__c = '1600 Amphitheatre Parkway';
		loc.SVMXC__City__c = 'Mountain View';
		loc.SVMXC__State__c = 'CA';
		loc.SVMXC__Country__c = 'United States';
		//a.BillingCountryCode = 'USA';
		loc.SVMXC__Zip__c ='94043';
		insert loc;

		Test.startTest();

		BD_Address_i18n_Batch b = new BD_Address_i18n_Batch();
		b.execute(null);

		Test.stopTest();

		SVMXC__Site__c updatedLocation = [
				SELECT Id, Name, BD_Formatted_Address__c
				FROM SVMXC__Site__c
				WHERE Id = :loc.Id
		];

		System.assertNotEquals(null, updatedLocation.BD_Formatted_Address__c);
	}

	@isTest static void testGeocodeLocations() {

		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		System.debug('Finished call to setup Mock Callout');

		SVMXC__Site__c loc = new SVMXC__Site__c(Name = 'TstSite');
		loc.SVMXC__Street__c = '1600 Amphitheatre Parkway';
		loc.SVMXC__City__c = 'Mountain View';
		loc.SVMXC__State__c = 'CA';
		loc.SVMXC__Country__c = 'US';
		loc.SVMXC__Zip__c ='94043';
		insert loc;

		BD_Address_i18n.formatAddressTrigger(new List<SVMXC__Site__c> { loc }, null);
		update loc;

		Test.startTest();

		List<BD_AddressDefinition__mdt> defList = BD_Address_i18n.loadAddressDefinitions(loc);
		BD_GeoCode.geocodeLocations(defList[0], new List<SVMXC__Site__c> { loc });

		Test.stopTest();

		BD_Address_i18n.AddressFields af = BD_Address_i18n.loadAddressFields(loc);
		System.debug('Address Fields af: ' + af);
		String format = BD_Address_i18n.getRegionSpecificAddress(af);
		System.debug('format: ' + format);
		System.debug('getRegionSpecificAddressHTML: ' + BD_Address_i18n.getRegionSpecificAddressHTML(af));
		System.debug('getLatitudeFieldName: ' + BD_Address_i18n.getLatitudeFieldName(defList[0]));
		System.debug('getLongitudeFieldName: ' + BD_Address_i18n.getLongitudeFieldName(defList[0]));
		System.assertEquals(37.4237754, loc.SVMXC__Latitude__c);
		System.assertEquals(-122.0853195, loc.SVMXC__Longitude__c);
	}
	
	@isTest static void testGeoCodeBatch() {

		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		System.debug('Finished call to setup Mock Callout');

		SVMXC__Site__c loc = new SVMXC__Site__c(Name = 'TstSite');
		loc.SVMXC__Street__c = '1600 Amphitheatre Parkway';
		loc.SVMXC__City__c = 'Mountain View';
		loc.SVMXC__State__c = 'CA';
		loc.SVMXC__Country__c = 'US';
		loc.SVMXC__Zip__c ='94043';
		insert loc;

		BD_Address_i18n.formatAddressTrigger(new List<SVMXC__Site__c> { loc }, null);
		update loc;

		Test.startTest();

		BD_GeoCode_Batch b = new BD_GeoCode_Batch();
		b.execute(null);

		Test.stopTest();

		SVMXC__Site__c updatedLocation = [
				SELECT Id, Name, SVMXC__Longitude__c, SVMXC__Latitude__c
				FROM SVMXC__Site__c
				WHERE Id = :loc.Id
		];

		System.debug('Location Lat and Lng: ' + updatedLocation.SVMXC__Latitude__c + ', ' + updatedLocation.SVMXC__Longitude__c);
		System.assertEquals(37.4237754, updatedLocation.SVMXC__Latitude__c);
		System.assertEquals(-122.0853195, updatedLocation.SVMXC__Longitude__c);
	}

//	@isTest static void testgeocodeMethod() {
//
//		//String response = BD_GeoCode.geocodeJson('1600 Amphitheatre Parkway, Mountain View, CA');
//		//System.debug('geocodeJson: ' + response);
//		//if (true) return;
//
//		XMLDom dom = BD_GeoCode.geocode('1600 Amphitheatre Parkway, Mountain View, CA');
//
//		if ( dom == null ) {
//			// when testing, dom is null here, fill it in with a valid dom.
//			return;
//		}
//		System.debug( dom.toXmlString() );
//		System.assert ( dom.root.getValue('code') == '200' , ' bad return code getValue() ');
//
//		// we expect a 602 here
//		dom = BD_GeoCode.geocode('1600 a Parkway,  View, GA');
//		System.debug ( 'code is '   +dom.root.getValue('code'));
//		System.assert ( dom.root.getValue('code') == '602' , ' unexpected return code');
//
//	}
	
//	@isTest static void t3() {
//		string test_resp = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Response><name>Elm St. Chico CA null</name><Status><code>602</code><request>geocode</request></Status></Response></kml>';
//		string test_resp2 = '<?xml version="1.0" encoding="UTF-8"?><GeocodeResponse><status>OK</status><result><type>street_address</type><formatted_address>10609 Gretna Green Dr, Tampa, FL 33626, USA</formatted_address><geometry><location><lat>28.0548402</lat><lng>-82.6048508</lng></location><location_type>ROOFTOP</location_type>' +
//			'<viewport><southwest><lat>28.0534912</lat><lng>-82.6061998</lng></southwest><northeast><lat>28.0561892</lat><lng>-82.6035018</lng></northeast></viewport></geometry><place_id>ChIJK2q24f_qwogR0jaTE8i4udI</place_id></result></GeocodeResponse>';
//		//string test_resp2 = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0" ><Response ><name >1600 Amphitheatre Parkway, Mountain View, CA</name><Status ><code >200</code><request >geocode</request></Status><Placemark id="p1" ><address >1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA</address><Point ><coordinates >-122.085121,37.423088,0</coordinates></Point></Placemark></Response></kml>';
//		Account a = new Account();
//		List<BD_AddressDefinition__mdt> defList = BD_Address_i18n.loadAddressDefinitions(a);
//
//		BD_GeoCode.processGeocodeDom( new xmldom(test_resp), defList[0], a);
//		BD_GeoCode.processGeocodeDom( new xmldom(test_resp2), defList[0], a);
//	}
	
//	@isTest static void testTimezonePrinting()
//	{
//		String format = 'yyyy-MM-dd hh:mm:ss z';
//		Datetime dt = Datetime.now();
//		List<String> timezones = new List<String> { 'America/New_York', 'America/Los_Angeles' };
//		for (String tzId : timezones)
//		{
//			Timezone tz = Timezone.getTimeZone(tzId);
//			System.debug(tzId + ' is ' + tz.getDisplayName());
//			System.debug(tzId + ' = ' + dt.format(format, tzId));
//		}
//	}

//	@isTest static void testTimezoneLookup()
//	{
//		String latLng = '39.6034810,-119.6822510';
//		XMLDom dom = BD_Timezone.lookupTimezone(latLng);
//		if (dom == null)
//		{
//			// External lookups not allowed in Unit Test.. this will always be null
//			return;
//		}
//	}

//	@isTest static void testTimezoneResponseParsing()
//	{
//		String goodResponse = '<?xml version="1.0" encoding="UTF-8"?><TimeZoneResponse><status>OK</status><raw_offset>-28800.0000000</raw_offset><dst_offset>0.0000000</dst_offset><time_zone_id>America/Los_Angeles</time_zone_id><time_zone_name>Pacific Standard Time</time_zone_name></TimeZoneResponse>';
//		String badResponse = '<?xml version="1.0" encoding="UTF-8"?><TimeZoneResponse><status>REQUEST_DENIED</status><error_message>Invalid request. Invalid \'location\' parameter.</error_message></TimeZoneResponse>';
//
//		Account a = new Account();
//		List<BD_AddressDefinition__mdt> defList = BD_Address_i18n.loadAddressDefinitions(a);
//
//		BD_Timezone.processTimezoneDom( new xmldom(badResponse), defList[0], a);
//		BD_Timezone.processTimezoneDom( new xmldom(goodResponse), defList[0], a);
//
//		a.BillingLongitude = 1.00000;
//		a.BillingLatitude = 1.00000;
//		BD_Timezone.lookupTimezones(defList[0], new List<Account>{ a });
//	}

//	@isTest static void testTimezoneBatch() {
//
//		// Set mock callout class
//		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
//		System.debug('Finished call to setup Mock Callout');
//
//		SVMXC__Site__c loc = new SVMXC__Site__c(Name = 'TstSite');
//		loc.SVMXC__Street__c = '1600 Amphitheatre Parkway';
//		loc.SVMXC__City__c = 'Mountain View';
//		loc.SVMXC__State__c = 'CA';
//		loc.SVMXC__Country__c = 'United States';
//		//a.BillingCountryCode = 'USA';
//		loc.SVMXC__Zip__c ='94043';
//		loc.SVMXC__Longitude__c=1.00000;
//		loc.SVMXC__Latitude__c = 1.00000;
//		insert loc;
//
//		Test.startTest();
//
//		BD_Timezone_Batch b = new BD_Timezone_Batch();
//		b.execute(null);
//
//		Test.stopTest();
//
//		SVMXC__Site__c updatedLocation = [
//				SELECT Id, Name, BD_Timezone__c
//				FROM SVMXC__Site__c
//				WHERE Id = :loc.Id
//		];
//
//		System.debug('Location Timezone: ' + updatedLocation.BD_Timezone__c);
//		System.assertEquals('America/Los_Angeles', updatedLocation.BD_Timezone__c);
//	}

//	@IsTest static void testParseTimezone() {
//		String json = '{'+
//				'   \"dstOffset\" : 3600,'+
//				'   \"rawOffset\" : -28800,'+
//				'   \"status\" : \"OK\",'+
//				'   \"timeZoneId\" : \"America/Los_Angeles\",'+
//				'   \"timeZoneName\" : \"Pacific Daylight Time\"'+
//				'}';
//		BD_Timezone.DeserializeTimezoneResponse deserializeTimezoneResponse = new BD_Timezone.DeserializeTimezoneResponse();
//		BD_Timezone.DeserializeTimezoneResponse obj = deserializeTimezoneResponse.parse(json);
//		System.debug(obj);
//		System.assertEquals('America/Los_Angeles', obj.timeZoneId);
//	}

	@IsTest static void testParseMaps() {
		String json = '{'+
				'   \"results\" : ['+
				'      {'+
				'         \"address_components\" : ['+
				'            {'+
				'               \"long_name\" : \"640\",'+
				'               \"short_name\" : \"640\",'+
				'               \"types\" : [ \"street_number\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"26th Street Southeast\",'+
				'               \"short_name\" : \"26th St SE\",'+
				'               \"types\" : [ \"route\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"Paris\",'+
				'               \"short_name\" : \"Paris\",'+
				'               \"types\" : [ \"locality\", \"political\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"Lamar County\",'+
				'               \"short_name\" : \"Lamar County\",'+
				'               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"Texas\",'+
				'               \"short_name\" : \"TX\",'+
				'               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"United States\",'+
				'               \"short_name\" : \"US\",'+
				'               \"types\" : [ \"country\", \"political\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"75460\",'+
				'               \"short_name\" : \"75460\",'+
				'               \"types\" : [ \"postal_code\" ]'+
				'            },'+
				'            {'+
				'               \"long_name\" : \"6216\",'+
				'               \"short_name\" : \"6216\",'+
				'               \"types\" : [ \"postal_code_suffix\" ]'+
				'            }'+
				'         ],'+
				'         \"formatted_address\" : \"640 26th St SE, Paris, TX 75460, USA\",'+
				'         \"geometry\" : {'+
				'            \"location\" : {'+
				'               \"lat\" : 33.6556165,'+
				'               \"lng\" : -95.52707840000001'+
				'            },'+
				'            \"location_type\" : \"ROOFTOP\",'+
				'            \"viewport\" : {'+
				'               \"northeast\" : {'+
				'                  \"lat\" : 33.6569654802915,'+
				'                  \"lng\" : -95.52572941970851'+
				'               },'+
				'               \"southwest\" : {'+
				'                  \"lat\" : 33.6542675197085,'+
				'                  \"lng\" : -95.52842738029152'+
				'               }'+
				'            }'+
				'         },'+
				'         \"place_id\" : \"ChIJ04iVmmZYSoYRdMtagRIsNzw\",'+
				'         \"plus_code\" : {'+
				'            \"compound_code\" : \"MF4F+65 Paris, TX, USA\",'+
				'            \"global_code\" : \"8656MF4F+65\"'+
				'         },'+
				'         \"types\" : [ \"street_address\" ]'+
				'      }'+
				'   ],'+
				'   \"status\" : \"OK\"'+
				'}';
		BD_GeoCode.DeserializeMapsResponse deserializeMapsResponse = new BD_GeoCode.DeserializeMapsResponse();
		BD_GeoCode.DeserializeMapsResponse obj = deserializeMapsResponse.parse(json);
		System.assert(obj != null);
	}

	@IsTest static void testBD_Address_i18nAddressFields() {

		BD_Address_i18n.AddressFields oldAddressFields = new BD_Address_i18n.AddressFields();
		BD_Address_i18n.AddressFields newAddressFields = new BD_Address_i18n.AddressFields();

		oldAddressFields.address1 = '123 Test Lane';
		oldAddressFields.city = 'Dallas';
		oldAddressFields.stateOrProv = 'TX';

		Boolean result = oldAddressFields.isChanged(oldAddressFields);
		System.debug('AddressFields.isChanged result: ' + result);
		System.assertEquals(false, result);

		newAddressFields.address1 = '345 Test Lane';
		newAddressFields.city = 'Houston';
		newAddressFields.stateOrProv = 'TX';
		result = oldAddressFields.isChanged(newAddressFields);
		System.debug('AddressFields.isChanged result: ' + result);
		System.assertEquals(true, result);
	}

	@IsTest static void testBD_Address_i18nLoadAddressFields() {

		BD_AddressDefinition__mdt def = [
				SELECT  Id, DeveloperName, BD_Compound_Address_Field__c,
						BD_Compound_Address_Field__r.QualifiedApiName,
						BD_Address_Line_1_Field__r.QualifiedApiName,
						BD_Address_Line_2_Field__r.QualifiedApiName,
						BD_City_Field__r.QualifiedApiName,
						BD_State_Province_Field__r.QualifiedApiName,
						BD_Postal_Code__r.QualifiedApiName,
						BD_Country_Name_Field__r.QualifiedApiName,
						BD_Country_Code_Field__r.QualifiedApiName
				FROM BD_AddressDefinition__mdt
				WHERE BD_Address_SObject__r.QualifiedApiName = 'SVMXC__Site__c' LIMIT 1
		];
		System.debug('def: ' + def);

		SVMXC__Site__c sobj = new SVMXC__Site__c(
				Name = 'Test 123',
				SVMXC__Street__c = '123 Test Lane',
				SVMXC__City__c = 'Houston',
				SVMXC__State__c = 'TX',
				SVMXC__Zip__c = '77070',
				SVMXC__Country__c = 'US'
		);

		// Validate with valid BD_AddressDefinition_mdt
		BD_Address_i18n.AddressFields result = BD_Address_i18n.loadAddressFields(sobj, def);
		System.debug('result: ' + result);
		System.assertEquals('Houston', result.city);

		// Validate with invalid BD_AddressDefinition__mdt
		BD_AddressDefinition__mdt defNull = new BD_AddressDefinition__mdt();
		result = BD_Address_i18n.loadAddressFields(sobj, defNull);
		System.debug('result: ' + result);
		System.assertEquals(null, result.city);
	}

	@IsTest static void testBD_Address_i18nFormatAddressTrigger() {

		BD_AddressDefinition__mdt def = [SELECT Id, DeveloperName, BD_Compound_Address_Field__c,
			BD_Compound_Address_Field__r.QualifiedApiName, BD_Formatted_Address_Type__c FROM BD_AddressDefinition__mdt
			WHERE BD_Address_SObject__r.QualifiedApiName = 'SVMXC__Site__c' LIMIT 1];
		System.debug('def: ' + def);

		SVMXC__Site__c sobj = new SVMXC__Site__c(
				Name = 'Test 123',
				SVMXC__Street__c = '123 Test Lane',
				SVMXC__City__c = 'Houston',
				SVMXC__State__c = 'TX',
				SVMXC__Zip__c = '77070',
				SVMXC__Country__c = 'US'
		);
		insert sobj;

		List<SObject> sobjects = new List<SObject>{ sobj };
		Map<Id, SObject> oldMap = new Map<Id, SObject>();

		Test.startTest();

		// oldMap is null
		System.debug('Before formatAddressTrigger: ' + sobj);
		BD_Address_i18n.formatAddressTrigger(sobjects, null);
		System.debug('After formatAddressTrigger: ' + sobj);
		System.assertEquals('123 Test Lane, Houston, TX 77070, US', sobj.BD_Formatted_Address__c);

		// oldMap is not null
		oldMap.put(sobj.Id, sobj);
		System.debug('Before formatAddressTrigger: ' + sobj);
		BD_Address_i18n.formatAddressTrigger(sobjects, oldMap);
		System.debug('After formatAddressTrigger: ' + sobj);
		System.assertEquals('123 Test Lane, Houston, TX 77070, US', sobj.BD_Formatted_Address__c);

		// oldMap is different from new - NOTE: This does not work as you can't change the field values of a record and use them in for
		// the loadAddressFields method of the BD_Address_i18n class.
		SVMXC__Site__c sobj2 = [SELECT Id, SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c FROM SVMXC__Site__c WHERE Id = :sobj.Id];
		sobj2.SVMXC__Street__c = '345 Test Road';
		sobj2.SVMXC__City__c = 'Dallas';
		List<SVMXC__Site__c> sobjects2 = new List<SVMXC__Site__c>{ sobj2 };
		System.debug('Before formatAddressTrigger: ' + sobjects2);
		System.debug('Before formatAddressTrigger oldMap: ' + oldMap);

		// Custom Metadata record cannot be updated so we can't test HTML and Multi Line address formatting
		//def.BD_Formatted_Address_Type__c = 'HTML';
		//System.debug('def: ' + def);

		BD_Address_i18n.formatAddressTrigger(sobjects2, oldMap);
		System.debug('After formatAddressTrigger: ' + sobjects2);
		System.debug('After formatAddressTrigger oldMap: ' + oldMap);
		System.assertEquals('123 Test Lane, Houston, TX 77070, US', sobj.BD_Formatted_Address__c);

		Test.stopTest();
	}

	@IsTest static void testBD_Address_i18nGetRegionSpecificAddressFormat() {

		String countryCode = 'US';
		String regionSpecificAddressFormat = BD_Address_i18n.getRegionSpecificAddressFormat(countryCode);
		System.debug('regionSpecificAddressFormat: ' + regionSpecificAddressFormat);
		System.assertEquals('{Street};{City},{State}_{PostCode};{Country}', regionSpecificAddressFormat);
	}

	@IsTest static void testBD_Address_i18nGetLongitudeFieldName() {

		BD_AddressDefinition__mdt def = [SELECT
				Id, DeveloperName,
				BD_Formatted_Address_Type__c,
				BD_Compound_Address_Field__c,
				BD_GeoCode_Field__c,
				BD_Longitude_Field__r.QualifiedApiName,
				BD_Compound_Address_Field__r.QualifiedApiName,
				BD_GeoCode_Field__r.QualifiedApiName FROM BD_AddressDefinition__mdt
			WHERE BD_Address_SObject__r.QualifiedApiName = 'SVMXC__Site__c' LIMIT 1
		];
		System.debug('def: ' + def);

		String fieldName = BD_Address_i18n.getLongitudeFieldName(def);
		System.debug('getLongitudeFieldName: ' + fieldName);
		System.assertEquals('SVMXC__Longitude__c', fieldName);

		BD_AddressDefinition__mdt def2 = new BD_AddressDefinition__mdt(
				DeveloperName = 'Test Address Def 2',
				BD_Compound_Address_Field__c = null,
				BD_Address_Line_1_Field__c = 'SVMXC__Site__c.SVMXC__Street__c',
				BD_City_Field__c = 'SVMXC__Site__c.SVMXC__City__c',
				BD_State_Province_Field__c = 'SVMXC__Site__c.SVMXC__State__c',
				BD_Postal_Code__c = 'SVMXC__Site__c.SVMXC__Zip__c',
				BD_Country_Name_Field__c = 'SVMXC__Site__c.SVMXC__Country__c',
				BD_Longitude_Field__c = 'SVMXC__Site__c.SVMXC__Longitude__c',
				BD_Formatted_Address_Type__c = 'Single Line'
				//BD_Compound_Address_Field__r.QualifiedApiName = ''
		);

		System.debug('def2 Address Fields: ' + def2.BD_Address_Line_1_Field__c + def2.BD_City_Field__c
				+ def2.BD_State_Province_Field__c + def2.BD_Postal_Code__c + def2.BD_Country_Name_Field__c
				+ def2.BD_Formatted_Address_Type__c + def2.BD_Longitude_Field__c);
		//def.BD_Compound_Address_Field__r.QualifiedApiName = null;
		//System.debug('def2.BD_Compound_Address_Field__r.QualifiedApiName: ' + def2.BD_Compound_Address_Field__r.QualifiedApiName);
		fieldName = BD_Address_i18n.getLongitudeFieldName(def2);
		System.debug('getLongitudeFieldName: ' + fieldName);
		System.assertEquals(null, fieldName);
	}

	@IsTest static void testBD_Address_i18nGetLatitudeFieldName() {

		BD_AddressDefinition__mdt def = [SELECT
				Id, DeveloperName,
				BD_Formatted_Address_Type__c,
				BD_Compound_Address_Field__c,
				BD_GeoCode_Field__c,
				BD_Latitude_Field__r.QualifiedApiName,
				BD_Compound_Address_Field__r.QualifiedApiName,
				BD_GeoCode_Field__r.QualifiedApiName FROM BD_AddressDefinition__mdt
			WHERE BD_Address_SObject__r.QualifiedApiName = 'SVMXC__Site__c' LIMIT 1
		];
		System.debug('def: ' + def);

		String fieldName = BD_Address_i18n.getLatitudeFieldName(def);
		System.debug('getLatitudeFieldName: ' + fieldName);
		System.assertEquals('SVMXC__Latitude__c', fieldName);

		BD_AddressDefinition__mdt def2 = new BD_AddressDefinition__mdt(
				DeveloperName = 'Test Address Def 2',
				//BD_Compound_Address_Field__c = 'Account.BillingAddress',
				BD_Formatted_Address_Type__c = 'Single Line',
				BD_Compound_Address_Field__c = null,
				BD_Address_Line_1_Field__c = 'SVMXC__Site__c.SVMXC__Street__c',
				BD_City_Field__c = 'SVMXC__Site__c.SVMXC__City__c',
				BD_State_Province_Field__c = 'SVMXC__Site__c.SVMXC__State__c',
				BD_Postal_Code__c = 'SVMXC__Site__c.SVMXC__Zip__c',
				BD_Country_Name_Field__c = 'SVMXC__Site__c.SVMXC__Country__c',
				BD_Longitude_Field__c = 'SVMXC__Site__c.SVMXC__Latitude__c'
				//BD_Compound_Address_Field__r.QualifiedApiName = ''
		);

		System.debug('def2 Address Fields: ' + def2.BD_Address_Line_1_Field__c + def2.BD_City_Field__c
				+ def2.BD_State_Province_Field__c + def2.BD_Postal_Code__c + def2.BD_Country_Name_Field__c
				+ def2.BD_Formatted_Address_Type__c + def2.BD_Longitude_Field__c);
		//def.BD_Compound_Address_Field__r.QualifiedApiName = null;
		System.debug('def2.BD_Address_Line_1_Field__c.QualifiedApiName: ' + def2.BD_Address_Line_1_Field__c);
		fieldName = BD_Address_i18n.getLatitudeFieldName(def2);
		System.debug('getLatitudeFieldName: ' + fieldName);
		System.assertEquals(null, fieldName);
	}
}
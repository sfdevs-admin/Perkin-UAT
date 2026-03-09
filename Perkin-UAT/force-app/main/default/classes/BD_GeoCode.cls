global class BD_GeoCode {

	// See https://cloud.google.com/maps-platform/pricing

	// https://developers.google.com/maps/documentation/geocoding/overview?hl=en_US
	//private static final string serviceUrl = 'https://maps.googleapis.com/maps/api/geocode/xml';
	//private static final String serviceUrl = 'callout:BD_GoogleMapsAPI/geocode/xml';
	private static final String serviceUrlJson = 'callout:BD_GoogleMapsAPI/geocode/json';

	public static void geocodeLocations(BD_AddressDefinition__mdt def, List<SObject> sobjects) {

		//handle group by address setting to reduce API calls
		if (def.BD_Group_By_for_Geolocation__c == true) {
			Map<String, List<SObject>> addressObjectMap = new Map<String, List<SObject>>();
			String latField = BD_Address_i18n.getLatitudeFieldName(def);
			String lngField = BD_Address_i18n.getLongitudeFieldName(def);

			BD_AddressDefinition__mdt parentDef = null;
			Decimal parentOrdinal = (def.BD_Ordinal__c == null ? null : def.BD_Ordinal__c - 1);
			if (parentOrdinal != null && parentOrdinal > 0) {
				List<BD_AddressDefinition__mdt> parentMDTList = [SELECT Id, BD_Ordinal__c,
						BD_Compound_Address_Field__r.QualifiedApiName,
						BD_Formatted_Address_Field__r.QualifiedApiName,
						BD_GeoCode_Field__r.QualifiedApiName,
						BD_Longitude_Field__r.QualifiedApiName,
						BD_Latitude_Field__r.QualifiedApiName,
						BD_Address_SObject__r.QualifiedApiName
					FROM BD_AddressDefinition__mdt WHERE BD_Ordinal__c = :parentOrdinal LIMIT 1];
				parentDef = (parentMDTList.isEmpty() ? null : parentMDTList[0]);
			}

			for (SObject sobj : sobjects) {
				String adr = (String) sobj.get(def.BD_Formatted_Address_Field__r.QualifiedApiName);
				if (adr != null && !adr.trim().startsWith(','))
				{
					if (!addressObjectMap.containsKey(adr)) {
						addressObjectMap.put(adr, new List<SObject>());
					}
					addressObjectMap.get(adr).add(sobj);
				}
			}

			for (String formattedAddress: addressObjectMap.keySet())
			{
				if (String.isBlank(formattedAddress)) {
					System.debug('Skipping BLANK address:'+formattedAddress);
					continue;
				}

				//check if geocoded address already exists in db
				Location geocode = findExistingGeocodedAddress(def, formattedAddress);
				if (geocode == null && parentDef != null) {
					geocode = findExistingGeocodedAddress(parentDef, formattedAddress);
				}

				if (geocode == null) {
					String json = geocodeJson(formattedAddress);
					geocode = processGeocodeJson(json, def, null);
				}

				if (geocode != null) {
					System.debug('address:'+formattedAddress+' | geoCode: '+geocode.lat+'|'+geocode.lng);
					Decimal lat = Decimal.valueOf(geocode.lat);
					Decimal lng = Decimal.valueOf(geocode.lng);
					List<SObject> sobjList = addressObjectMap.get(formattedAddress);
					for (SObject sobj : sobjList) {
						sobj.put(latField, lat);
						sobj.put(lngField, lng);
					}
				}
			}
		} else {
			// Not grouping by Formatted Address... call geocode service for each object
			for (SObject sobj : sobjects) {
				BD_Address_i18n.AddressFields fields = BD_Address_i18n.loadAddressFields(sobj, def);
				String adr = BD_Address_i18n.getRegionSpecificAddressOneLine(fields);

				// Changed calls to use JSON instead of XML
				//XMLDom dom = geocode(adr);
				//processGeocodeDom(dom, def, sobj);
				String json = geocodeJson(adr);
				processGeocodeJson(json, def, sobj);
			}
		}

		Database.SaveResult[] results = Database.update(sobjects, false);
		for (Integer i = 0; i < results.size(); ++i) {
			Database.SaveResult sr = results[i];
			SObject sobj = sobjects.get(i);
			if (! sr.isSuccess()) {
				System.debug('Error updating SObject for GeoCode lookup: ' + sobj.get('Id') + ' -- ' + sr.getErrors());
			}
		}
	}

   /*
	the call may return one of these  Constants
	Constants   Description
	G_GEO_SUCCESS (200)     No errors occurred; the address was successfully parsed and its geocode has been returned. (Since 2.55)
	G_GEO_BAD_REQUEST (400)     A directions request could not be successfully parsed. (Since 2.81)
	G_GEO_SERVER_ERROR (500)    A geocoding or directions request could not be successfully processed, yet the exact reason for the failure is not known. (Since 2.55)
	G_GEO_MISSING_QUERY (601)   The HTTP q parameter was either missing or had no value. For geocoding requests, this means that an empty address was specified as input. For directions requests, this means that no query was specified in the input. (Since 2.81)
	G_GEO_MISSING_ADDRESS (601)     Synonym for G_GEO_MISSING_QUERY. (Since 2.55)
	G_GEO_UNKNOWN_ADDRESS (602)     No corresponding geographic location could be found for the specified address. This may be due to the fact that the address is relatively new, or it may be incorrect. (Since 2.55)
	G_GEO_UNAVAILABLE_ADDRESS (603)     The geocode for the given address or the route for the given directions query cannot be returned due to legal or contractual reasons. (Since 2.55)
	G_GEO_UNKNOWN_DIRECTIONS (604)  The GDirections object could not compute directions between the points mentioned in the query. This is usually because there is no route available between the two points, or because we do not have data for routing in that region. (Since 2.81)
	G_GEO_BAD_KEY (610)     The given key is either invalid or does not match the domain for which it was given. (Since 2.55)
	G_GEO_TOO_MANY_QUERIES (620)    The given key has gone over the requests limit in the 24 hour period. (Since 2.55)
	*/
//	public static XMLDom geocode(String addr)
//	{
//		BD_Google_API_Config__c config = BD_Google_API_Config__c.getInstance('GeoCode');
//		if((!Test.isRunningTest()) && (config==null || config.BD_API_Key__c==null)) return null;
//		String key = (config == null) ? null : config.BD_API_Key__c;
//		System.debug('key:'+key);
//
//		HttpRequest req = new HttpRequest();
//		String url = serviceUrl+'?address=' + EncodingUtil.urlEncode(addr,'UTF-8')+'&key='+key;
//		System.debug('~~ Google GeoCode url is ' + url);
//		req.setEndpoint( url );
//		req.setMethod('GET');
//
//		XMLDom dom = null;
//		try {
//			Http http = new Http();
//			HttpResponse response = (Test.isRunningTest()) ? new HttpResponse() : http.send(req);
//
//			if (response.getStatusCode() != 200 ) {
//				dumpResponse(response);
//			} else {
//				System.debug('Success response: ' + response.getBody());
//				dom = new XMLDom( response.getBody() );
//			}
//		} catch( System.Exception e) {
//			System.debug('ERROR: '+ e);
//
//		}
//
//		return dom;
//	}

	public static String geocodeJson(String addr)
	{
		BD_Google_API_Config__c config = BD_Google_API_Config__c.getInstance('GeoCode');
		if((!Test.isRunningTest()) && (config==null || config.BD_API_Key__c==null)) return null;
		String key = (config == null) ? null : config.BD_API_Key__c;
		System.debug('key:'+key);

		HttpRequest req = new HttpRequest();
		String url = serviceUrlJson+'?address=' + EncodingUtil.urlEncode(addr,'UTF-8')+'&key='+key;
		System.debug('~~ Google GeoCode url is ' + url);
		req.setEndpoint( url );
		req.setMethod('GET');

		String resp = null;
		try {
			Http http = new Http();
			//HttpResponse response = (Test.isRunningTest()) ? new HttpResponse() : http.send(req);
			HttpResponse response = http.send(req);

			if (response.getStatusCode() != 200 ) {
				dumpResponse(response);
			} else {
				resp = response.getBody();
				System.debug('Success response: ' + resp);
			}
		} catch( System.Exception e) {
			System.debug('ERROR: '+ e);

		}

		return resp;
	}

	private static void dumpResponse(HttpResponse response) { 
		System.debug('GEOCODE ERROR: Could not parse or locate address. STATUS:' + response.getStatus() + 
			' STATUS_CODE:' + response.getStatusCode() + ' BODY: ' + response.getBody());
	}

//	/* given a DOM, look at the code and store the values or error found */
//	public static void processGeocodeDom(XMLDom dom, BD_AddressDefinition__mdt def, SObject sobj) {
//		// GeoCode_Field__r.QualifiedApiName,
//
//		if (dom != null) {
//			if (dom.getElementsByTagName('status')[0].nodeValue == 'OK' )  {
//				String latField = BD_Address_i18n.getLatitudeFieldName(def);
//				String lngField = BD_Address_i18n.getLongitudeFieldName(def);
//				sobj.put(latField, Decimal.valueof(dom.getElementsByTagName('lat')[0].nodeValue));
//				sobj.put(lngField, Decimal.valueof(dom.getElementsByTagName('lng')[0].nodeValue));
//			} else {
//				//a.KA_Geocoding_Failed__c = true;
//			}
//		} else {
//			//a.KA_Geocoding_Failed__c = true;
//		}
//	}

	/* given a JSON String, look at the status and store the values or error found */
	public static Location processGeocodeJson(String jsonResponse, BD_AddressDefinition__mdt def, SObject sobj) {
		// GeoCode_Field__r.QualifiedApiName,
		Location result = null;
		if (jsonResponse != null) {

			// Deserialize the JSON string into collections of primitive data types.
			//BD_DeserializeMapsResponse resp = BD_DeserializeMapsResponse.parse(jsonResponse);
			DeserializeMapsResponse deserializeMapsResponse = new DeserializeMapsResponse();
			DeserializeMapsResponse resp = deserializeMapsResponse.parse(jsonResponse);

			// Get the values in the lat, lng, and status keys
			System.debug('parsed: ' + resp);
			String status = resp.status;
			System.debug('status: ' + status);

			if (status == 'OK' && resp.results != null && !resp.results.isEmpty()) {
				System.debug('size: ' + resp.results.size());
				result = resp.results[0].geometry.location;

				if (sobj != null) {
					String latField = BD_Address_i18n.getLatitudeFieldName(def);
					String lngField = BD_Address_i18n.getLongitudeFieldName(def);
					sobj.put(latField, result.lat);
					sobj.put(lngField, result.lng);
				}
			}
		}
		return result;
	}

	public static Location findExistingGeocodedAddress(BD_AddressDefinition__mdt addressDef, String formattedAddress)
	{
		Location loc = null;
		String latField = BD_Address_i18n.getLatitudeFieldName(addressDef);
		String lngField = BD_Address_i18n.getLongitudeFieldName(addressDef);

		if(latField!=null && lngField!=null)
		{
			String query = 'SELECT ' + addressDef.BD_Formatted_Address_Field__r.QualifiedApiName + ', ' + lngField + ', ' + latField
			+ ' FROM ' + addressDef.BD_Address_SObject__r.QualifiedApiName
			+ ' WHERE (' + latField + ' != null AND ' + latField + ' != 0.0)'
			+ ' AND (' + lngField + ' != null AND ' + lngField + ' != 0.0) '
			+ 'AND ' + addressDef.BD_Formatted_Address_Field__r.QualifiedApiName + ' = :formattedAddress LIMIT 1';

			Database.QueryLocator q = Database.getQueryLocator(query);
			Database.QueryLocatorIterator it = q.iterator();

			while (it.hasNext()) {
				SObject a = (SObject) it.next();
				loc = new Location();
				loc.lat=(Double) a.get(latField);
				loc.lng=(Double) a.get(lngField);
			}
		}
		return loc;
	}
/*
{
   "results" : [
      {
         "address_components" : [
            {
               "long_name" : "1600",
               "short_name" : "1600",
               "types" : [ "street_number" ]
            },
            {
               "long_name" : "Amphitheatre Pkwy",
               "short_name" : "Amphitheatre Pkwy",
               "types" : [ "route" ]
            },
            {
               "long_name" : "Mountain View",
               "short_name" : "Mountain View",
               "types" : [ "locality", "political" ]
            },
            {
               "long_name" : "Santa Clara County",
               "short_name" : "Santa Clara County",
               "types" : [ "administrative_area_level_2", "political" ]
            },
            {
               "long_name" : "California",
               "short_name" : "CA",
               "types" : [ "administrative_area_level_1", "political" ]
            },
            {
               "long_name" : "United States",
               "short_name" : "US",
               "types" : [ "country", "political" ]
            },
            {
               "long_name" : "94043",
               "short_name" : "94043",
               "types" : [ "postal_code" ]
            }
         ],
         "formatted_address" : "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA",
         "geometry" : {
            "location" : {
               "lat" : 37.4224764,
               "lng" : -122.0842499
            },
            "location_type" : "ROOFTOP",
            "viewport" : {
               "northeast" : {
                  "lat" : 37.4238253802915,
                  "lng" : -122.0829009197085
               },
               "southwest" : {
                  "lat" : 37.4211274197085,
                  "lng" : -122.0855988802915
               }
            }
         },
         "place_id" : "ChIJ2eUgeAK6j4ARbn5u_wAGqWA",
         "plus_code": {
            "compound_code": "CWC8+W5 Mountain View, California, United States",
            "global_code": "849VCWC8+W5"
         },
         "types" : [ "street_address" ]
      }
   ],
   "status" : "OK"
}
 */

	// Classes used to Deserialize the JSON from Google Maps
	public class Address_components {
		public String long_name;
		public String short_name;
		public List<String> types;
	}

	public class Geometry {
		public Location location;
		public String location_type;
		public Viewport viewport;
	}

	public class Plus_code {
		public String compound_code;
		public String global_code;
	}

	public class Results {
		public List<Address_components> address_components;
		public String formatted_address;
		public Geometry geometry;
		public String place_id;
		public Plus_code plus_code;
		public List<String> types;
	}

	public class Viewport {
		public Location northeast;
		public Location southwest;
	}

	public class Location {
		public Double lat;
		public Double lng;
	}

	public class DeserializeMapsResponse {

		public List<Results> results;
		public String status;

		//constructor
		public DeserializeMapsResponse()
		{
		}

		public DeserializeMapsResponse parse(String json) {
			return (DeserializeMapsResponse) System.JSON.deserialize(json, DeserializeMapsResponse.class);
		}
	}

}
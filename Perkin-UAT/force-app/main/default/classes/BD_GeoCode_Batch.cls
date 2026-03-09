global class BD_GeoCode_Batch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {
	public BD_GeoCode_Batch() {
		
	}

	// **** Schedulable members
	global void execute(SchedulableContext ctx) {

		// Find all Address Definitions that enabled "Calculate GeoLocation".. start a batch for each.
		List<BD_AddressDefinition__mdt> defList = [SELECT Id, 
			BD_Compound_Address_Field__r.QualifiedApiName,
			BD_Address_Line_1_Field__r.QualifiedApiName, 
			BD_Address_Line_2_Field__r.QualifiedApiName, 
			BD_Address_SObject__r.QualifiedApiName, 
			BD_City_Field__r.QualifiedApiName, 
			BD_Country_Code_Field__r.QualifiedApiName, 
			BD_Country_Name_Field__r.QualifiedApiName, 
			BD_Postal_Code__r.QualifiedApiName, 
			BD_State_Province_Field__r.QualifiedApiName, 
			// Geo Location Fields
			BD_Calculate_Geo_Location__c, 
			BD_GeoCode_Field__r.QualifiedApiName,
			BD_Latitude_Field__r.QualifiedApiName, 
			BD_Longitude_Field__r.QualifiedApiName, 
			// Timezone Fields
			BD_Calculate_Timezone__c, 
			BD_Timezone_Field__r.QualifiedApiName,
			// Formatted Address Fields
			BD_Calculate_Formatted_Address__c, 
			BD_Formatted_Address_Field__r.QualifiedApiName, 
			BD_Formatted_Address_Type__c,
			BD_Group_By_for_Geolocation__c,
			BD_Ordinal__c
			FROM BD_AddressDefinition__mdt
			WHERE BD_Calculate_Geo_Location__c = TRUE
			ORDER BY BD_Ordinal__c ASC];
			System.debug('defListSize: '+defList.size());
		if (defList.isEmpty()) {
			return;
		}

		BD_GeoCode_Batch b = new BD_GeoCode_Batch(defList); 
		Database.executeBatch(b, 25);
	}

	private BD_AddressDefinition__mdt def;
	private List<BD_AddressDefinition__mdt> remainingDefs;

	private BD_GeoCode_Batch(List<BD_AddressDefinition__mdt> all)
	{
		this.def = all.remove(0);
		this.remainingDefs = new List<BD_AddressDefinition__mdt>(all);
	}

	// **** Database.Batchable<sObject> members
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		//KA_BD_Google_API_Config__c config = KA_BD_Google_API_Config__c.getInstance('GeoCode');
		//Integer max = (config == null || config.KA_Max_Calls_Per_Day__c == null) ? 
		//	2500 : config.KA_Max_Calls_Per_Day__c.intValue();
		System.debug('def: '+def);
		String addressFields = '';
		if (def.BD_Compound_Address_Field__r.QualifiedApiName != null)
		{
			String prefix = def.BD_Compound_Address_Field__r.QualifiedApiName.replace('Address', '');
			addressFields = prefix + 'Street, ' + prefix + 'City, ' + prefix + 'State, ' +
				prefix + 'PostalCode, ' + prefix + 'Country, ';// + prefix + 'CountryCode, ';
		}
		else
		{
			addressFields = def.BD_Address_Line_1_Field__r.QualifiedApiName + ', ';
			if (String.isNotBlank(def.BD_Address_Line_2_Field__r.QualifiedApiName))
				addressFields += def.BD_Address_Line_2_Field__r.QualifiedApiName + ', ';

			// Added these all to one line for code coverage
			addressFields += def.BD_City_Field__r.QualifiedApiName + ', ' + def.BD_State_Province_Field__r.QualifiedApiName + ', ' + def.BD_Postal_Code__r.QualifiedApiName + ', ' + def.BD_Country_Name_Field__r.QualifiedApiName + ', ';
			if (def.BD_Country_Name_Field__r.QualifiedApiName != def.BD_Country_Code_Field__r.QualifiedApiName) {
				addressFields += def.BD_Country_Code_Field__r.QualifiedApiName + ', ';
			}
		}

		String andOrderBy = '';
		if (def.BD_Group_By_for_Geolocation__c) {
			String formattedAddrField = def.BD_Formatted_Address_Field__r.QualifiedApiName;
			addressFields += formattedAddrField + ', ';
			andOrderBy = ' AND ' + formattedAddrField + ' != null ORDER BY ' + formattedAddrField;
		}

		String lngField = BD_Address_i18n.getLongitudeFieldName(def);
		String latField = BD_Address_i18n.getLatitudeFieldName(def);

		// create dynamic soql based on "def"
		String query = 'SELECT Id, ' + addressFields + lngField + ', ' + latField 
			+ ' FROM ' + def.BD_Address_SObject__r.QualifiedApiName
			+ ' WHERE (' + latField + ' = null OR ' + latField + ' = 0.0)'
			+ ' AND (' + lngField + ' = null OR ' + lngField + ' = 0.0)'
			+ andOrderBy;
		System.debug('GEO_CODE SOQL: ' + query);
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
		BD_GeoCode.geocodeLocations(this.def, scope);
	}
	
	global void finish(Database.BatchableContext BC) 
	{
		// If remainingDefs is not empty.. execute self again with remaining..
		if (!this.remainingDefs.isEmpty())
		{
			BD_GeoCode_Batch b = new BD_GeoCode_Batch(this.remainingDefs);
			Database.executeBatch(b, 25);
		}
		else // If it is empty, start Timezone.. (PKI does not need Timezone)
		{
//			BD_Timezone_Batch timezone = new BD_Timezone_Batch();
//			timezone.execute(null); // mimic the Schedulable method
		}
	}
	
}
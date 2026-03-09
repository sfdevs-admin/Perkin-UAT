/**
 * Created by sethh on 10/19/2020.
 */

global class BD_Address_i18n_Batch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {

	public BD_Address_i18n_Batch(){}

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
				BD_Group_By_for_Geolocation__c
			FROM BD_AddressDefinition__mdt
			WHERE BD_Calculate_Formatted_Address__c = TRUE
			ORDER BY BD_Ordinal__c ASC];
		System.debug('defListSize: '+defList.size());
		if (defList.isEmpty()) {
			return;
		}

		BD_Address_i18n_Batch b = new BD_Address_i18n_Batch(defList);
		Database.executeBatch(b, 200);
	}

	private BD_AddressDefinition__mdt def;
	private List<BD_AddressDefinition__mdt> remainingDefs;

	private BD_Address_i18n_Batch(List<BD_AddressDefinition__mdt> all)
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

		String formattedAddressField = def.BD_Formatted_Address_Field__r.QualifiedApiName;
		addressFields += formattedAddressField;

		// create dynamic soql based on "def"
		String query = 'SELECT Id, ' + addressFields
				+ ' FROM ' + def.BD_Address_SObject__r.QualifiedApiName
				+ ' WHERE ' + formattedAddressField + ' = null';
		System.debug('ADDRESS POPULATE SOQL: ' + query);
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<SObject> scope)
	{
		BD_Address_i18n.formatAddressTrigger(scope,null);
		update scope;
	}

	global void finish(Database.BatchableContext BC)
	{
		// If remainingDefs is not empty.. execute self again with remaining..
		if (!this.remainingDefs.isEmpty())
		{
			BD_Address_i18n_Batch b = new BD_Address_i18n_Batch(this.remainingDefs);
			Database.executeBatch(b, 200);
		}
		else // If it is empty, start Timezone..
		{
			BD_GeoCode_Batch geoCodeBatch = new BD_GeoCode_Batch();
			geoCodeBatch.execute(null); // mimic the Schedulable method
		}
	}
}
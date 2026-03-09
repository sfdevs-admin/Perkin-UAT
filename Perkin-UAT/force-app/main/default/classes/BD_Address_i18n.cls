global without sharing class BD_Address_i18n {
	public BD_Address_i18n() {
	}

	public class AddressFields
	{
		public String name, address1, address2, city, stateOrProv, postalCode, country, countryCode;

		public Boolean isChanged(AddressFields old)
		{
			return (this.name != old.name) 
				|| (this.address1 != old.address1) 
				|| (this.address2 != old.address2) 
				|| (this.city != old.city) 
				|| (this.stateOrProv != old.stateOrProv) 
				|| (this.postalCode != old.postalCode) 
				|| (this.country != old.country) 
				|| (this.countryCode != old.countryCode);
		}
	}

	/**
		REGIONAL ADDRESS FORMATS
	*/
	global static Map<String, BD_RegionalAddressFormat__mdt> countryMap = new Map<String, BD_RegionalAddressFormat__mdt>();

	@TestVisible
	private static String getRegionSpecificAddressFormat(String countryCode)
	{
		BD_RegionalAddressFormat__mdt raf = null;
		if (countryCode != null)
		{
			if (countryMap.containsKey(countryCode))
			{
				raf = countryMap.get(countryCode);
			}
			else
			{
				List<BD_RegionalAddressFormat__mdt> rafList = [SELECT Id, BD_Address_Format__c, BD_Countries__c 
					FROM BD_RegionalAddressFormat__mdt];
				for (BD_RegionalAddressFormat__mdt r : rafList)
				{
					if (r.BD_Countries__c.contains(countryCode))
					{
						countryMap.put(countryCode, r);
						raf = r;
						break;
					}
				}
			}
		}

		String format = null;
		if (raf == null)
		{
			// Should we throw an Exception?
			System.debug('!!! Could not find a Regional Address Format for CountryCode: ' + countryCode);
			format = '{Street};{City},{State}_{PostCode};{Country}'; // DEFAULT FORMAT..
		}
		else
		{
			format = raf.BD_Address_Format__c;
		}
		return format;
	}

	private static String replaceToken(String format, String token, String value)
	{
		value = (value == null) ? '' : value;
		return format.replace('{' + token + '}', value);
	}

    private static String replaceAddressTokens(String format, AddressFields af)
    {
    	format = replaceToken(format, 'Street', af.address1);
    	format = replaceToken(format, 'Street2', af.address2);
    	format = replaceToken(format, 'City', af.city);
    	format = replaceToken(format, 'State', af.stateOrProv);
    	format = replaceToken(format, 'PostCode', af.postalCode);
    	format = replaceToken(format, 'Country', af.country);
    	format = replaceToken(format, 'Building', '');
    	format = replaceToken(format, 'Complement', '');
    	format = replaceToken(format, 'County', '');
    	format = replaceToken(format, 'District', '');
    	format = replaceToken(format, 'Number', '');
    	return format;
    }

    public static String getRegionSpecificAddress(AddressFields af)
	{
		String format = getRegionSpecificAddressFormat(af.countryCode);
		if (af.name != null)
			format = af.name + ';' + format;

		String value = format.replace(';', '\n').replace('_', ' ');
		return replaceAddressTokens(value, af);
	}

    public static String getRegionSpecificAddressOneLine(AddressFields af)
	{
		String format = getRegionSpecificAddressFormat(af.countryCode);
		if (af.name != null)
			format = af.name + ',' + format;

		String value = format.replace(';', ',').replace(',', ', ').replace('_', ' ');
		String result = replaceAddressTokens(value, af);
		// Clean empty values and leading/trailing commas
		result = result.replaceAll('^,','').replaceAll('\\s+,','').replaceAll(',\\s*$','').trim();
		return result;
	}

    public static String getRegionSpecificAddressHTML(AddressFields af)
	{
		String format = getRegionSpecificAddressFormat(af.countryCode);
		if (af.name != null)
			format = af.name + ';' + format;

		String value = '<p>' + format.replace(';', '</p><p>').replace('_', ' ') + '</p>';
		return replaceAddressTokens(value, af);
	}

	public static List<BD_AddressDefinition__mdt> loadAddressDefinitions(SObject sobj)
	{
		Schema.SObjectType stype = sobj.getSObjectType();
		String typeName = stype.getDescribe().getName();
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
			WHERE BD_Address_SObject__r.QualifiedApiName = :typeName
			ORDER BY BD_Ordinal__c ASC];
		return defList;
	}

	public static AddressFields loadAddressFields(SObject sobj)
	{
		List<BD_AddressDefinition__mdt> defList = loadAddressDefinitions(sobj);
		if (defList.isEmpty())
			return null;

		BD_AddressDefinition__mdt def = defList[0];
		return loadAddressFields(sobj, def);
	}

	public static AddressFields loadAddressFields(SObject sobj, BD_AddressDefinition__mdt def)
	{
		System.debug('Loading Address Field.. SObject = ' + sobj + ', AddressDefinition = ' + def);

		AddressFields result = new AddressFields();
		if (def.BD_Compound_Address_Field__r.QualifiedApiName != null)
		{
			String prefix = def.BD_Compound_Address_Field__r.QualifiedApiName.replace('Address', '');
			result.address1 = safeGet(sobj, prefix + 'Street');
			result.address2 = null;
			result.city = safeGet(sobj, prefix + 'City');
			result.stateOrProv = safeGet(sobj, prefix + 'State');
			result.postalCode = safeGet(sobj, prefix + 'PostalCode');
			result.country = safeGet(sobj, prefix + 'Country');
			result.countryCode = safeGet(sobj, prefix + 'CountryCode');
		}
		else
		{
			result.address1 = safeGet(sobj, def.BD_Address_Line_1_Field__r.QualifiedApiName);
			result.address2 = safeGet(sobj, def.BD_Address_Line_2_Field__r.QualifiedApiName);
			result.city = safeGet(sobj, def.BD_City_Field__r.QualifiedApiName);
			result.stateOrProv = safeGet(sobj, def.BD_State_Province_Field__r.QualifiedApiName);
			result.postalCode = safeGet(sobj, def.BD_Postal_Code__r.QualifiedApiName);
			result.country = safeGet(sobj, def.BD_Country_Name_Field__r.QualifiedApiName);
			result.countryCode = safeGet(sobj, def.BD_Country_Code_Field__r.QualifiedApiName);
		}
		return result;
	}

	private static String safeGet(SObject sobj, String fieldName)
	{
		if (fieldName == null || fieldName.length() == 0)
			return null;
		try { 
			Object result = sobj.get(fieldName);  
			return (result == null) ? null : '' + result; 
		} catch (Exception e) { return null; }
	}

	/**
	 *  Fills in the "Formatted Address Field" on all "Address Definition" that are configured.
	 *  Should be called from the Before Insert / Update triggers.
	 */
	public static void formatAddressTrigger(List<SObject> sobjects, Map<Id, SObject> oldMap)
	{
		if (sobjects.isEmpty())
			return;

		List<BD_AddressDefinition__mdt> defList = loadAddressDefinitions(sobjects[0]);
		for (BD_AddressDefinition__mdt def : defList)
		{
			if (def.BD_Calculate_Formatted_Address__c != null && String.isNotBlank(def.BD_Formatted_Address_Field__r.QualifiedApiName))
			{
				for (SObject sobj : sobjects)
				{
					AddressFields fields = null;
					SObject old = (oldMap == null) ? null : oldMap.get((Id)sobj.get('Id'));
					String formattedValue = safeGet(sobj, def.BD_Formatted_Address_Field__r.QualifiedApiName);
					if (old == null || String.isBlank(formattedValue))
					{
						// It definately needs to be filled in.
						fields = loadAddressFields(sobj, def);
					}
					else if (old != null)
					{
						// Only needs to be updated if Address Fields changed
						AddressFields newFields = loadAddressFields(sobj, def);
						AddressFields oldFields = loadAddressFields(old, def);
						if (newFields.isChanged(oldFields))
						{
							fields = newFields;
						}
					}

					if (fields != null)
					{
						if (def.BD_Formatted_Address_Type__c == 'HTML') {
							sobj.put(def.BD_Formatted_Address_Field__r.QualifiedApiName, getRegionSpecificAddressHTML(fields));
						} else if (def.BD_Formatted_Address_Type__c == 'Multi Line') {
							sobj.put(def.BD_Formatted_Address_Field__r.QualifiedApiName, getRegionSpecificAddress(fields));
						} else {
							sobj.put(def.BD_Formatted_Address_Field__r.QualifiedApiName, getRegionSpecificAddressOneLine(fields));
						}

						// Blank out the Geo-Codes so the Geo-Coding batch will recalculate
						if (def.BD_Calculate_Geo_Location__c == true) {
							String latField = BD_Address_i18n.getLatitudeFieldName(def);
							String lngField = BD_Address_i18n.getLongitudeFieldName(def);
							if (latField != null && lngField != null) {
								sobj.put(latField, null);
								sobj.put(lngField, null);
							}
						}
					}
				}
			}
		}
	}

	public static String getLongitudeFieldName(BD_AddressDefinition__mdt def)
	{
		if (String.isNotBlank(def.BD_Compound_Address_Field__r.QualifiedApiName))
		{
			return def.BD_Compound_Address_Field__r.QualifiedApiName.replace('Address', '') + 'Longitude';
		}
		else if (String.isNotBlank(def.BD_GeoCode_Field__r.QualifiedApiName))
		{
			return def.BD_GeoCode_Field__r.QualifiedApiName.replace('__c', '__Longitude__s');
		}
		return def.BD_Longitude_Field__r.QualifiedApiName;
	}

	public static String getLatitudeFieldName(BD_AddressDefinition__mdt def)
	{
		if (String.isNotBlank(def.BD_Compound_Address_Field__r.QualifiedApiName))
		{
			return def.BD_Compound_Address_Field__r.QualifiedApiName.replace('Address', '') + 'Latitude';
		}
		else if (String.isNotBlank(def.BD_GeoCode_Field__r.QualifiedApiName))
		{
			return def.BD_GeoCode_Field__r.QualifiedApiName.replace('__c', '__Latitude__s');
		}
		return def.BD_Latitude_Field__r.QualifiedApiName;
	}
}
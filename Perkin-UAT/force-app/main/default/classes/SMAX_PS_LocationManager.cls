/**
 *  Apex Class for Location [SVMXC__Site__c] Business Logic.
 *  2017-07-03      Frank VanLoon       Initial creation, for Location Integration.
 *  2017-11-02      Frank VanLoon       Refactored Customer-Master Lookups / Functions to Accounts
 */
public with sharing class SMAX_PS_LocationManager {
	private SMAX_PS_LocationManager() {
	}

	/*
		Used for Inbound Location Integration from SAP.
		Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
		If Customer lookups are not populated, or if the external ids changed, this code will attempt to lookup and fill them in.
	 */
	public static void lookupLocationCustomers(List<SVMXC__Site__c> locations, Map<Id, SVMXC__Site__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('LookupLocationCustomers', 'If Customer lookups are not populated, or if the external ids changed, this code will attempt to lookup and fill them in.'))	return;

		Map<String, RecordType> locRecTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__Site__c');
		RecordType storageRecType = locRecTypeMap.get('SMAX_PS_Storage_Location');
		Id storageRecTypeId = (storageRecType == null) ? null :storageRecType.Id;

		// STEP 0: Copy the SVMX_PS_External_ID__c to the SMAX_PS_SoldToExtID__c if blank
		for (SVMXC__Site__c loc : locations)
		{
			if (loc.RecordTypeId == storageRecTypeId)
			{
				// SVMXINT-629 Storage Location - Alternative Customer
				if (loc.SMAX_PS_AltCustomerNumber__c != null && String.isNotBlank(loc.SMAX_PS_AltCustomerNumber__c))
				{
					loc.SMAX_PS_SoldToExtID__c = loc.SMAX_PS_AltCustomerNumber__c;
				}
				else
				{
					loc.SMAX_PS_SoldToExtID__c = loc.SVMX_PS_External_ID__c;
					// ITSVMX-1084 Hard-Code an 'E' prefix for '1US2' Storage Location Accounts
					if (loc.SMAX_PS_SoldToExtID__c != null && loc.SMAX_PS_SoldToExtID__c.startsWith('1US2')) {
						loc.SMAX_PS_SoldToExtID__c = 'E' + loc.SMAX_PS_SoldToExtID__c;
					}
				}
			}
		}

		// STEP 1: Collect all External Ids and Locations that need to be looked up (SoldTo, Account, Parent)
		Set<String> accountExtIds = new Set<String>();
		Set<String> contactExtIds = new Set<String>();
		Set<String> parentExtIds = new Set<String>();

		List<SVMXC__Site__c> updateSoldTo = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updateContact = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updateParent = new List<SVMXC__Site__c>();
		for (SVMXC__Site__c loc : locations)
		{
			SVMXC__Site__c old = (oldMap == null) ? null : oldMap.get(loc.Id);

			// Account: SMAX_PS_SoldToExtID__c --> SVMXC__Account__c
			if (String.isNotEmpty(loc.SMAX_PS_SoldToExtID__c) && (loc.SVMXC__Account__c == null || 
				(old != null && loc.SMAX_PS_SoldToExtID__c != old.SMAX_PS_SoldToExtID__c)) )
			{
				accountExtIds.add(loc.SMAX_PS_SoldToExtID__c);
				updateSoldTo.add(loc);
			}

			// Contact : SMAX_PS_ContactExtId__c --> SMAX_PS_Contact__c
			if (String.isNotEmpty(loc.SMAX_PS_ContactExtId__c) && (loc.SMAX_PS_Contact__c == null || 
				(old != null && loc.SMAX_PS_ContactExtId__c != old.SMAX_PS_ContactExtId__c)) )
			{
				contactExtIds.add(loc.SMAX_PS_ContactExtId__c);
				updateContact.add(loc);
			}

			if (String.isNotEmpty(loc.SMAX_PS_ParentExtID__c) && (loc.SVMXC__Parent__c == null ||
				(old != null && loc.SMAX_PS_ParentExtID__c != old.SMAX_PS_ParentExtID__c)) )
			{
				parentExtIds.add(loc.SMAX_PS_ParentExtID__c);
				updateParent.add(loc);
			}
		}
	
		// STEP 2: Lookup Accounts, Partner Sites & Contacts by their External Ids
		Map<String, Account> accountMap = new Map<String, Account>();
		if (!accountExtIds.isEmpty())
		{
			for (Account acct : [SELECT Id, Name, PKI_SAP_Customer_Number__c,
				(SELECT Id, PKI_SAP_Target_Account_Number__c, PKI_SAP_Partner_Type__c, 
					PKI_SAP_Partner_Type_Name__c FROM SourceAccountFunctions__r) 
				FROM Account WHERE PKI_SAP_Customer_Number__c IN :accountExtIds])
			{
				accountMap.put(acct.PKI_SAP_Customer_Number__c, acct);
			}
		}

		Map<String, Contact> contactMap = new Map<String, Contact>();
		if (!contactExtIds.isEmpty())
		{
			for (Contact c : [SELECT Id, FirstName, LastName, PKI_SAP_Contact_ID__c 
				FROM Contact WHERE PKI_SAP_Contact_ID__c IN :contactExtIds])
			{
				contactMap.put(c.PKI_SAP_Contact_ID__c, c);
			}
		}

		Map<String, SVMXC__Site__c> parentMap = new Map<String, SVMXC__Site__c>();
		if (!parentExtIds.isEmpty())
		{
			for (SVMXC__Site__c loc : [SELECT Id, SVMX_PS_External_ID__c 
				FROM SVMXC__Site__c WHERE SVMX_PS_External_ID__c IN :parentExtIds])
			{
				parentMap.put(loc.SVMX_PS_External_ID__c, loc);
			}
		}

		// STEP 3: Fill in the Account / Contact / Parent lookups if found
		for (SVMXC__Site__c loc : updateSoldTo)
		{
			Account acct = accountMap.get(loc.SMAX_PS_SoldToExtID__c);
			loc.SVMXC__Account__c = (acct != null) ? acct.Id : null;

			// For Storage Locations, fill in Partner Site External Ids
			if (acct != null && loc.RecordTypeId == storageRecTypeId)
			{
				Account_Function__c billTo = findFunctionByName(acct.SourceAccountFunctions__r, 'Bill To');
				if (billTo != null)
				{
					loc.SMAX_PS_BillToExtID__c = billTo.PKI_SAP_Target_Account_Number__c;
				}

				Account_Function__c payer = findFunctionByName(acct.SourceAccountFunctions__r, 'Payer');
				if (payer != null)
				{
					loc.SMAX_PS_PayerExtId__c = payer.PKI_SAP_Target_Account_Number__c;
				}

				Account_Function__c shipTo = findFunctionByName(acct.SourceAccountFunctions__r, 'Ship To');
				if (shipTo != null)
				{
					loc.SMAX_PS_ShipToExtID__c = shipTo.PKI_SAP_Target_Account_Number__c;
				}
			}
		}

		for (SVMXC__Site__c loc : updateContact)
		{
			Contact c = contactMap.get(loc.SMAX_PS_ContactExtId__c);
			loc.SMAX_PS_Contact__c = (c != null) ? c.Id : null;
		}

		for (SVMXC__Site__c loc : updateParent)
		{
			SVMXC__Site__c parent = parentMap.get(loc.SMAX_PS_ParentExtID__c);
			loc.SVMXC__Parent__c = (parent != null) ? parent.Id : null;
		}

		// STEP 4: Collect all External Ids and Locations that need to be looked up (Accounts)
		Set<String> partnerAcctExtIds = new Set<String>();

		List<SVMXC__Site__c> updateBillTo = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updatePayer = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updateShipTo = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updateLocalBillTo = new List<SVMXC__Site__c>();
		List<SVMXC__Site__c> updateLocalShipTo = new List<SVMXC__Site__c>();
		for (SVMXC__Site__c loc : locations)
		{
			SVMXC__Site__c old = (oldMap == null) ? null : oldMap.get(loc.Id);

			// SMAX_PS_BillToExtID__c --> SMAX_PS_BillTo__c
			if (String.isNotEmpty(loc.SMAX_PS_BillToExtID__c) && (loc.SMAX_PS_BillTo__c == null || 
				(old != null && loc.SMAX_PS_BillToExtID__c != old.SMAX_PS_BillToExtID__c)) )
			{
				partnerAcctExtIds.add(loc.SMAX_PS_BillToExtID__c);
				updateBillTo.add(loc);
			}

			// SMAX_PS_PayerExtId__c --> SMAX_PS_Payer__c
			if (String.isNotEmpty(loc.SMAX_PS_PayerExtId__c) && (loc.SMAX_PS_Payer__c == null || 
				(old != null && loc.SMAX_PS_PayerExtId__c != old.SMAX_PS_PayerExtId__c)) )
			{
				partnerAcctExtIds.add(loc.SMAX_PS_PayerExtId__c);
				updatePayer.add(loc);
			}
	
			// SMAX_PS_ShipToExtID__c --> SMAX_PS_ShipTo__c
			if (String.isNotEmpty(loc.SMAX_PS_ShipToExtID__c) && (loc.SMAX_PS_ShipTo__c == null || 
				(old != null && loc.SMAX_PS_ShipToExtID__c != old.SMAX_PS_ShipToExtID__c)) )
			{
				partnerAcctExtIds.add(loc.SMAX_PS_ShipToExtID__c);
				updateShipTo.add(loc);
			}

			// SVMXINT-623 Local Language Partners on Location
			// SMAX_PS_LL_BillToExtID__c --> SMAX_PS_LL_BillTo__c
			if (String.isNotEmpty(loc.SMAX_PS_LL_BillToExtID__c) && (loc.SMAX_PS_LL_BillTo__c == null ||
					(old != null && loc.SMAX_PS_LL_BillToExtID__c != old.SMAX_PS_LL_BillToExtID__c)) )
			{
				partnerAcctExtIds.add(loc.SMAX_PS_LL_BillToExtID__c);
				updateLocalBillTo.add(loc);
			}

			// SMAX_PS_LL_ShipToExtID__c --> SMAX_PS_LL_ShipTo__c
			if (String.isNotEmpty(loc.SMAX_PS_LL_ShipToExtID__c) && (loc.SMAX_PS_LL_ShipTo__c == null ||
					(old != null && loc.SMAX_PS_LL_ShipToExtID__c != old.SMAX_PS_LL_ShipToExtID__c)) )
			{
				partnerAcctExtIds.add(loc.SMAX_PS_LL_ShipToExtID__c);
				updateLocalShipTo.add(loc);
			}
		}

		// STEP 5: Lookup Partner Accounts by their External Ids
		Map<String, Account> partnerAcctMap = new Map<String, Account>();
		if (!partnerAcctExtIds.isEmpty())
		{
			for (Account acct : [SELECT Id, Name, PKI_SAP_Customer_Number__c 
				FROM Account WHERE PKI_SAP_Customer_Number__c IN :partnerAcctExtIds])
			{
				partnerAcctMap.put(acct.PKI_SAP_Customer_Number__c, acct);
			}
		}

		for (SVMXC__Site__c loc : updateBillTo)
		{
			Account acct = partnerAcctMap.get(loc.SMAX_PS_BillToExtID__c);
			loc.SMAX_PS_BillTo__c = (acct != null) ? acct.Id : null;
		}

		for (SVMXC__Site__c loc : updatePayer)
		{
			Account acct = partnerAcctMap.get(loc.SMAX_PS_PayerExtId__c);
			loc.SMAX_PS_Payer__c = (acct != null) ? acct.Id : null;
		}

		for (SVMXC__Site__c loc : updateShipTo)
		{
			Account acct = partnerAcctMap.get(loc.SMAX_PS_ShipToExtID__c);
			loc.SMAX_PS_ShipTo__c = (acct != null) ? acct.Id : null;
		}

		// SVMXINT-623 Local Language Partners on Location
		for (SVMXC__Site__c loc : updateLocalBillTo)
		{
			Account acct = partnerAcctMap.get(loc.SMAX_PS_LL_BillToExtID__c);
			loc.SMAX_PS_LL_BillTo__c = (acct != null) ? acct.Id : null;
		}

		for (SVMXC__Site__c loc : updateLocalShipTo)
		{
			Account acct = partnerAcctMap.get(loc.SMAX_PS_LL_ShipToExtID__c);
			loc.SMAX_PS_LL_ShipTo__c = (acct != null) ? acct.Id : null;
		}
	}

	/**
	 *  SVMXCFG-401 - Set the Address Fields for Storage Location by copying from the ShipTo Account
	 *  Must be called in a before insert/update trigger, AFTER the lookupLocationCustomers method.
	 */
	public static void lookupStorageAddress(List<SVMXC__Site__c> locations, Map<Id, SVMXC__Site__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Location Storage Address', 'If Storage Location, copy the Address fields from the Ship To Location Account.'))	return;

		Id storageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;

		Set<Id> acctIds = new Set<Id>();
		List<SVMXC__Site__c> locsToUpdate = new List<SVMXC__Site__c>();
		for (SVMXC__Site__c loc : locations)
		{
			SVMXC__Site__c old = (oldMap == null) ? null : oldMap.get(loc.Id);
			if (loc.RecordTypeId == storageRecTypeId && loc.SMAX_PS_ShipTo__c != null 
				&& (old == null || loc.SMAX_PS_ShipTo__c != old.SMAX_PS_ShipTo__c || loc.SVMXC__Street__c == null))
			{
				locsToUpdate.add(loc);
				acctIds.add(loc.SMAX_PS_ShipTo__c);
			}
		}

		Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name,
			PKI_SAP_Street__c, PKI_SAP_City__c, PKI_SAP_Region__c, PKI_SAP_Postal_Code__c, PKI_SAP_Country_Code__c
			FROM Account WHERE Id IN :acctIds]);

		for (SVMXC__Site__c loc : locsToUpdate)
		{
			Account acct = acctMap.get(loc.SMAX_PS_ShipTo__c);
			if (acct != null)
			{
				loc.SVMXC__Street__c = acct.PKI_SAP_Street__c;
				loc.SVMXC__City__c = acct.PKI_SAP_City__c;
				loc.SVMXC__State__c = acct.PKI_SAP_Region__c;
				loc.SVMXC__Zip__c = acct.PKI_SAP_Postal_Code__c;
				loc.SVMXC__Country__c = acct.PKI_SAP_Country_Code__c;
			}
		}
	}

	public static void updateStorageAddress(List<Account> accounts, Map<Id, Account> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Storage Address Updates', 'If Account is related to a Storage Location, copy the Address fields when Account is updated.')) return;

		Map<Id, Account> acctMap = new Map<Id, Account>();
		for (Account account : accounts)
		{
			acctMap.put(account.Id, account);
		}

		Id storageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;

		List<SVMXC__Site__c> storageLocs = [SELECT Id, Name, SMAX_PS_ShipTo__c,
			SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c
			FROM SVMXC__Site__c WHERE RecordTypeId = :storageRecTypeId
			AND SMAX_PS_ShipTo__c IN :acctMap.keySet()];
		if (storageLocs.isEmpty()) return;

		for (SVMXC__Site__c	loc : storageLocs)
		{
			Account acct = acctMap.get(loc.SMAX_PS_ShipTo__c);
			if (acct != null)
			{
				loc.SVMXC__Street__c = acct.PKI_SAP_Street__c;
				loc.SVMXC__City__c = acct.PKI_SAP_City__c;
				loc.SVMXC__State__c = acct.PKI_SAP_Region__c;
				loc.SVMXC__Zip__c = acct.PKI_SAP_Postal_Code__c;
				loc.SVMXC__Country__c = acct.PKI_SAP_Country_Code__c;
			}
		}

		Database.update(storageLocs, false);
		// TODO: Could collect the errors and log them somewhere..
	}

	/*
		Used for Inbound Location Integration from SAP.
		Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
		If Geography lookup is not populated, or if the Location Code changed, this code will attempt to lookup and fill it in.
	 */
	public static void lookupLocationGeography(List<SVMXC__Site__c> locations, Map<Id, SVMXC__Site__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('lookupLocationGeography', 'If Geography lookup is not populated, or if the Location Code changed, this code will attempt to lookup and fill it in.'))	return;

		// STEP 1: Copy the SVMX_PS_External_ID__c to the SMAX_PS_SoldToExtID__c if blank
		List<SVMXC__Site__c> locsToUpdate = new List<SVMXC__Site__c>();
		Set<String> locationCodes = new Set<String>();
		for (SVMXC__Site__c loc : locations)
		{
			SVMXC__Site__c old = (oldMap == null) ? null : oldMap.get(loc.Id);
			if (loc.SMAX_PS_LocationCode__c != null && (loc.SMAX_PS_Geography__c == null 
				|| (old != null && loc.SMAX_PS_LocationCode__c != old.SMAX_PS_LocationCode__c)))
			{
				locsToUpdate.add(loc);
				locationCodes.add(loc.SMAX_PS_LocationCode__c);
			}
		}

		if (locationCodes.isEmpty()) return;

		// STEP 2: Lookup Geography by Location Codes
		Map<String, SMAX_PS_Geography__c> geoMap = new Map<String, SMAX_PS_Geography__c>();
		for (SMAX_PS_Geography__c geo : [SELECT Id, SMAX_PS_LocationCode__c FROM SMAX_PS_Geography__c 
			WHERE SMAX_PS_LocationCode__c IN :locationCodes])
		{
			geoMap.put(geo.SMAX_PS_LocationCode__c, geo);
		}

		// STEP 3: Fill in Location->Geography Lookup
		Id storageLocationRecordTypeId = Schema.SObjectType.SVMXC__Site__c.getRecordTypeInfosByDeveloperName().get('SMAX_PS_Storage_Location').getRecordTypeId();
		Set<String> newLocCode = new Set<String>();
		List<SVMXC__Site__c> locsThatNeedGeos = new List<SVMXC__Site__c>();
		for (SVMXC__Site__c loc : locsToUpdate)
		{
			String locCode = loc.SMAX_PS_LocationCode__c;
			if (geoMap.containsKey(locCode))
			{
				SMAX_PS_Geography__c geo = geoMap.get(locCode);
				loc.SMAX_PS_Geography__c = geo.Id;
			} else
			{
				// 2/25/21 tony - Don't create a new Geography record for a Storage Location
				if (loc.RecordTypeId != storageLocationRecordTypeId) {
					// No Geography record exists for this locCode so we will need to create one
					locsThatNeedGeos.add(loc);
					newLocCode.add(locCode);
				}
			}
		}

		if (newLocCode.isEmpty()) return;

		// 1/14/21 tony - ITSVMX-220 Geography Data Enhancements
		// STEP 4: Create a new Geography records for each new locCode
		Map<String, SMAX_PS_Geography__c> newLocCodeToGeoMap = new Map<String, SMAX_PS_Geography__c>();
		for (String locCode : newLocCode)
		{
			SMAX_PS_Geography__c geo = new SMAX_PS_Geography__c();
			geo.SMAX_PS_LocationCode__c = locCode;
			geo.Name = locCode;
			newLocCodeToGeoMap.put(locCode, geo);
		}
		insert newLocCodeToGeoMap.values();

		// STEP 5: Fill in Location->Geography Lookup for the new Geography records
		for (SVMXC__Site__c loc : locsThatNeedGeos)
		{
			SMAX_PS_Geography__c geo = newLocCodeToGeoMap.get(loc.SMAX_PS_LocationCode__c);
			loc.SMAX_PS_Geography__c = geo.Id;
		}
	}

	private static Account_Function__c findFunctionByName(List<Account_Function__c> functions, String name)
	{
		if (!SMAX_PS_Utility.isActive('Find Function By Name', 'Finds the function by the SAP Partner Type Name.')) return null;

		for (Account_Function__c function : functions)
		{
			if (function.PKI_SAP_Partner_Type_Name__c != null && function.PKI_SAP_Partner_Type_Name__c.contains(name)) return function;
		}
		return null;
	}
	
	// Added by Veerendra 2017-08-14
	// Updated by Frank, for SVMXCFG-408
	public static void updateIPAddressFieldsWhenLocAdrChanged(List<SVMXC__Site__c> newLocList, Map<Id, SVMXC__Site__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update IP Address Fields', 'Update Address fields in IP when the location address is changed.')) return;

		Set<Id> locIds = new Set<Id>();
		List<SVMXC__Site__c> locsToUpdate = new List<SVMXC__Site__c>();
		for (SVMXC__Site__c loc : newLocList)
		{
			SVMXC__Site__c old = (oldMap == null) ? null : oldMap.get(loc.Id);
			if (old != null && 
				(loc.SVMXC__Street__c != old.SVMXC__Street__c 
					|| loc.SVMXC__City__c != old.SVMXC__City__c
					|| loc.SVMXC__State__c != old.SVMXC__State__c
					|| loc.SVMXC__Zip__c != old.SVMXC__Zip__c
					|| loc.SVMXC__Country__c != old.SVMXC__Country__c))
			{
				locsToUpdate.add(loc);
				locIds.add(loc.Id);
			}
		}

		if (locsToUpdate.isEmpty()) return;

		List<SVMXC__Installed_Product__c> ipListForUpdate = new List<SVMXC__Installed_Product__c>();
		Map<Id, List<SVMXC__Installed_Product__c>> ipLocMap = new Map<Id, List<SVMXC__Installed_Product__c>>();
		List<SVMXC__Installed_Product__c> ipList = [SELECT Id, Name, SVMXC__Site__c 
			FROM SVMXC__Installed_Product__c WHERE SVMXC__Site__c IN :locIds];
		for (SVMXC__Installed_Product__c ip : ipList) 
		{
			List<SVMXC__Installed_Product__c> listIP = new List<SVMXC__Installed_Product__c>();
			if(ipLocMap.containsKey(ip.SVMXC__Site__c))
			{
				listIP = ipLocMap.get(ip.SVMXC__Site__c);
			}
			listIP.add(ip);
			ipLocMap.put(ip.SVMXC__Site__c, listIP);
		}

		for (SVMXC__Site__c loc : locsToUpdate) 
		{
			if (ipLocMap.containsKey(loc.Id))
			{
				List<SVMXC__Installed_Product__c> listIP = ipLocMap.get(loc.Id);
				for (SVMXC__Installed_Product__c ip : listIP) 
				{
					ip.SVMXC__Street__c = loc.SVMXC__Street__c;
					ip.SVMXC__City__c = loc.SVMXC__City__c;
					ip.SVMXC__State__c = loc.SVMXC__State__c;
					ip.SVMXC__Zip__c = loc.SVMXC__Zip__c;
					ip.SVMXC__Country__c = loc.SVMXC__Country__c;
					ipListForUpdate.add(ip);
				}
			}
		}

		if (!ipListForUpdate.isEmpty()) update ipListForUpdate;
	}
}
/**
 * Created by frankvanloon on 2019-02-18.
 */

global class SMAX_PS_WorkOrder_LocalLangFixBatch implements Database.Batchable<SObject>
{
	/** Database.Batchable methods **/
	global List<String> SALES_ORGS = new List<String>();
	global Integer NUM_DAYS;

	public SMAX_PS_WorkOrder_LocalLangFixBatch(List<String> salesOrgs, Integer numDays)
	{
		SALES_ORGS = salesOrgs;
		NUM_DAYS = numDays;
	}

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		Date START_DATE = Date.today().addDays(-3);

		return Database.getQueryLocator([SELECT Id, Name, SVMXC__Order_Status__c,
				SVMXC__Component__c, SVMXC__Site__c,
				SMAX_PS_Local_Language_Bill_To_Account__c, SMAX_PS_LocalLanguageBillTo__c,
				SMAX_PS_Local_Language_Bill_To_Street__c, SMAX_PS_Local_Lang_Bill_To_Addr_Long__c,
				SMAX_PS_Local_Language_Ship_To_Account__c, SMAX_PS_LocalLanguageShipTo__c,
				SMAX_PS_Local_Language_Ship_To_Street__c, SMAX_PS_Local_Lang_Ship_To_Addr_Long__c
			FROM SVMXC__Service_Order__c
			WHERE SMAX_PS_SalesOrg__c IN :SALES_ORGS AND CreatedDate >= :START_DATE
			AND SMAX_PS_Local_Language_Ship_To_Account__c = null AND SMAX_PS_Local_Language_Bill_To_Account__c = null]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> workOrders)
	{
		Set<Id> ipIds = new Set<Id>();
		Set<Id> locIds = new Set<Id>();
		for (SVMXC__Service_Order__c wo : workOrders)
		{
			if (wo.SVMXC__Component__c != null)
				ipIds.add(wo.SVMXC__Component__c);
			if (wo.SVMXC__Site__c != null)
				locIds.add(wo.SVMXC__Site__c);
		}

		Map<Id, SVMXC__Installed_Product__c> ipMap = null;
		if (!ipIds.isEmpty())
		{
			ipMap = new Map<Id, SVMXC__Installed_Product__c>([SELECT Id, Name, SMAX_PS_ModelSeries__c, SVMXC__Site__c,
					SVMXC__Preferred_Technician__c, SMAX_PS_CatalogProfile__c, SMAX_PS_ModelNumber__c, SMAX_PS_IsMedicalDevice__c,
					SMAX_PS_Technical_ID_Number__c, SMAX_PS_ThirdPartyVendorName__c, SMAX_PS_Field_Notes__c,
					SVMXC__Product__c, SVMXC__Product__r.SMAX_PS_Super_Business_Unit__c,
					SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
					SMAX_PS_SoldTo_Account__r.ShippingStreet, SMAX_PS_SoldTo_Account__r.ShippingCity, SMAX_PS_SoldTo_Account__r.ShippingState,
					SMAX_PS_SoldTo_Account__r.ShippingPostalCode, SMAX_PS_SoldTo_Account__r.ShippingCountry,
					SMAX_PS_System_ID__c, SVMXC__Asset_Tag__c, SMAX_PS_Equipment_ID__c,
					SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Platform_Id__c, SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Customer_Id__c,
					SMAX_PS_LL_BillTo_Account__c, SMAX_PS_LL_BillTo_Account__r.Name,
					SMAX_PS_LL_BillTo_Account__r.ShippingStreet, SMAX_PS_LL_BillTo_Account__r.ShippingCity, SMAX_PS_LL_BillTo_Account__r.ShippingState,
					SMAX_PS_LL_BillTo_Account__r.ShippingPostalCode, SMAX_PS_LL_BillTo_Account__r.ShippingCountry,
					SMAX_PS_LL_ShipTo_Account__c, SMAX_PS_LL_ShipTo_Account__r.Name,
					SMAX_PS_LL_ShipTo_Account__r.ShippingStreet, SMAX_PS_LL_ShipTo_Account__r.ShippingCity, SMAX_PS_LL_ShipTo_Account__r.ShippingState,
					SMAX_PS_LL_ShipTo_Account__r.ShippingPostalCode, SMAX_PS_LL_ShipTo_Account__r.ShippingCountry
			FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds]);
		}

		Map<Id, SVMXC__Site__c> locMap = null;
		if (!locIds.isEmpty())
		{
			locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SMAX_PS_LocationCode__c, SMAX_PS_Geography__r.Name,
					SVMXC__Account__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c, SMAX_PS_MaintenancePlant__c,
					SMAX_PS_SalesOrg__c, CurrencyIsoCode, SVMX_PS_Location_Notes__c,
					SVMXC__Account__r.ShippingStreet, SVMXC__Account__r.ShippingCity, SVMXC__Account__r.ShippingState,
					SVMXC__Account__r.ShippingPostalCode, SVMXC__Account__r.ShippingCountry,
					SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Country__c, SVMXC__Zip__c,
					SMAX_PS_Payer__r.PKI_SAP_EInvoice_Platform_Id__c, SMAX_PS_Payer__r.PKI_SAP_EInvoice_Customer_Id__c,
					SMAX_PS_LL_BillTo__c, SMAX_PS_LL_BillTo__r.Name,
					SMAX_PS_LL_BillTo__r.ShippingStreet, SMAX_PS_LL_BillTo__r.ShippingCity, SMAX_PS_LL_BillTo__r.ShippingState,
					SMAX_PS_LL_BillTo__r.ShippingPostalCode, SMAX_PS_LL_BillTo__r.ShippingCountry,
					SMAX_PS_LL_ShipTo__c, SMAX_PS_LL_ShipTo__r.Name,
					SMAX_PS_LL_ShipTo__r.ShippingStreet, SMAX_PS_LL_ShipTo__r.ShippingCity, SMAX_PS_LL_ShipTo__r.ShippingState,
					SMAX_PS_LL_ShipTo__r.ShippingPostalCode, SMAX_PS_LL_ShipTo__r.ShippingCountry
			FROM SVMXC__Site__c WHERE Id IN :locIds]);
		}

		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : workOrders)
		{
			SVMXC__Installed_Product__c ip = ipMap.get(wo.SVMXC__Component__c);
			if (ip != null)
			{
				// SVMXCFG-903 Copy Local Language Accounts to WO
				if (ip.SMAX_PS_LL_BillTo_Account__c != null)
				{
					wo.SMAX_PS_Local_Language_Bill_To_Account__c = ip.SMAX_PS_LL_BillTo_Account__c;
					wo.SMAX_PS_LocalLanguageBillTo__c = ip.SMAX_PS_LL_BillTo_Account__r.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.SMAX_PS_Local_Language_Bill_To_Street__c = ip.SMAX_PS_LL_BillTo_Account__r.ShippingStreet;
					wo.SMAX_PS_Local_Lang_Bill_To_Addr_Long__c = ip.SMAX_PS_LL_BillTo_Account__r.ShippingCity
							+ ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingState
							+ ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingPostalCode
							+ ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingCountry;
					woMap.put(wo.Id, wo);
				}
				if (ip.SMAX_PS_LL_ShipTo_Account__c != null)
				{
					wo.SMAX_PS_Local_Language_Ship_To_Account__c = ip.SMAX_PS_LL_ShipTo_Account__c;
					wo.SMAX_PS_LocalLanguageShipTo__c = ip.SMAX_PS_LL_ShipTo_Account__r.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.SMAX_PS_Local_Language_Ship_To_Street__c = ip.SMAX_PS_LL_ShipTo_Account__r.ShippingStreet;
					wo.SMAX_PS_Local_Lang_Ship_To_Addr_Long__c = ip.SMAX_PS_LL_ShipTo_Account__r.ShippingCity
							+ ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingState
							+ ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingPostalCode
							+ ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingCountry;
					woMap.put(wo.Id, wo);
				}
			}

			SVMXC__Site__c loc = locMap.get(wo.SVMXC__Site__c);
			if (loc != null)
			{
				// SVMXCFG-903 Copy Local Language Accounts to WO
				if (wo.SMAX_PS_Local_Language_Bill_To_Account__c == null && loc.SMAX_PS_LL_BillTo__c != null)
				{
					wo.SMAX_PS_Local_Language_Bill_To_Account__c = loc.SMAX_PS_LL_BillTo__c;
					wo.SMAX_PS_LocalLanguageBillTo__c = loc.SMAX_PS_LL_BillTo__r.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.SMAX_PS_Local_Language_Bill_To_Street__c = loc.SMAX_PS_LL_BillTo__r.ShippingStreet;
					wo.SMAX_PS_Local_Lang_Bill_To_Addr_Long__c = loc.SMAX_PS_LL_BillTo__r.ShippingCity
							+ ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingState
							+ ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingPostalCode
							+ ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingCountry;
					woMap.put(wo.Id, wo);
				}
				if (wo.SMAX_PS_Local_Language_Ship_To_Account__c == null && loc.SMAX_PS_LL_ShipTo__c != null)
				{
					wo.SMAX_PS_Local_Language_Ship_To_Account__c = loc.SMAX_PS_LL_ShipTo__c;
					wo.SMAX_PS_LocalLanguageShipTo__c = loc.SMAX_PS_LL_ShipTo__r.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.SMAX_PS_Local_Language_Ship_To_Street__c = loc.SMAX_PS_LL_ShipTo__r.ShippingStreet;
					wo.SMAX_PS_Local_Lang_Ship_To_Addr_Long__c = loc.SMAX_PS_LL_ShipTo__r.ShippingCity
							+ ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingState
							+ ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingPostalCode
							+ ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingCountry;
					woMap.put(wo.Id, wo);
				}
			}
		}

		if (woMap.isEmpty())
			return;

		List<SVMXC__Service_Order__c> woToUpdate = woMap.values();
		Database.SaveResult[] results = Database.update(woToUpdate, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Service_Order__c wo = woToUpdate[i];
				System.debug('Error updating Work Order: ' + wo.Id + ' with Local Language fields: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
		}
	}

	global void finish(Database.BatchableContext BC)
	{
	}
}
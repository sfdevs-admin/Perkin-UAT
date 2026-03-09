/**
 *  Apex Class for Batch updating Function [Function__c] to Account / Partner Site Lookups.
 *  2017-07-13		Venkata Kalidindi		Initial creation, refactored from UpdateSOJAutomated.
 */
global class SAP_SOJ_UpdateAccountSalesOrg_Batch implements Database.Batchable<sObject>, Schedulable 
{
	
	global SAP_SOJ_UpdateAccountSalesOrg_Batch() 
	{
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SAP_SOJ_UpdateAccountSalesOrg_Batch btch = new SAP_SOJ_UpdateAccountSalesOrg_Batch();
		Database.executeBatch(btch, 25);
	}

	/** Database.Batchable methods **/
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id, PKI_SAP_Customer_Number__c, PKI_SAP_Sales_Org__c,Related_Accounts__c,Related_Sales_Orgs__c FROM SalesOrgJunction__c
                                                WHERE (Related_Accounts__r.Name = 'Default for SAP Integration' OR Related_Sales_Orgs__r.Name = 'Default') 
                                                AND (Date_Lookups_Last_Modified__c > LAST_N_DAYS:2 OR Date_Lookups_Last_Modified__c = null)]);
	}

	global void execute(Database.BatchableContext BC, List<SalesOrgJunction__c> salesOrgJunctions)
	{
		Set<String> soldToIds = new Set<String>();
		Set<String> salesOrgIds = new Set<String>();
		for (SalesOrgJunction__c salesOrgJunction : salesOrgJunctions)
		{
			soldToIds.add(salesOrgJunction.PKI_SAP_Customer_Number__c);
			salesOrgIds.add(salesOrgJunction.PKI_SAP_Sales_Org__c);
		}
			
		Map<String, Account> accountMap = new Map<String, Account>();
		if (!soldToIds.isEmpty())
		{
			for (Account acct : [SELECT Id, PKI_SAP_Customer_Number__c 
				FROM Account WHERE PKI_SAP_Customer_Number__c IN :soldToIds])
			{
				accountMap.put(acct.PKI_SAP_Customer_Number__c, acct);
			}
		}

		Map<String, SalesOrg__c> salesOrgMap = new Map<String, SalesOrg__c>();
		if (!salesOrgIds.isEmpty())
		{
			for (SalesOrg__c salesorg : [SELECT Id, PKISAPSalesOrg__c 
                                                 FROM SalesOrg__c WHERE PKISAPSalesOrg__c IN :salesOrgIds])
			{
				salesOrgMap.put(salesorg.PKISAPSalesOrg__c, salesorg);
			}
		}

		List<SalesOrgJunction__c> sojToUpdate = new List<SalesOrgJunction__c>();
		for (SalesOrgJunction__c salesOrgJunction : salesOrgJunctions)
		{
			Boolean updated = false;
			if (salesOrgJunction.PKI_SAP_Customer_Number__c != null && accountMap.containsKey(salesOrgJunction.PKI_SAP_Customer_Number__c))
			{
				Account acct = accountMap.get(salesOrgJunction.PKI_SAP_Customer_Number__c);
				if (salesOrgJunction.Related_Accounts__c != acct.Id)
				{
					salesOrgJunction.Related_Accounts__c = acct.Id;
					updated = true;
				}
			}
			if (salesOrgJunction.PKI_SAP_Sales_Org__c != null && salesOrgMap.containsKey(salesOrgJunction.PKI_SAP_Sales_Org__c))
			{
				SalesOrg__c site = salesOrgMap.get(salesOrgJunction.PKI_SAP_Sales_Org__c);
				if (salesOrgJunction.Related_Sales_Orgs__c != site.Id)
				{
					salesOrgJunction.Related_Sales_Orgs__c = site.Id;
					updated = true;
				}
			}

			if (updated)
			{
				//function.Date_Lookups_Last_Modified__c = System.today();
				sojToUpdate.add(salesOrgJunction);
			}
		}

		if (sojToUpdate.isEmpty())
			return;

		Database.SaveResult[] results = Database.update(sojToUpdate, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SalesOrgJunction__c soj = sojToUpdate[i];
				System.debug('Error updating soj: ' + soj.Id + ' with Lookups: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
            
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
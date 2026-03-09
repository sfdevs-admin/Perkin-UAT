/**
 *  Apex Class for Batch updating Function [Function__c] to Account / Partner Site Lookups.
 *  2017-07-07		Frank VanLoon,Venkata Kalidindi		Initial creation, refactored from UpdateFunctionsAutomated.
 *  2017-11-02		Frank VanLoon		Refactored Customer-Master Lookups / Functions to Accounts
 */
global class SAP_Functions_UpdateAccountPS_Batch implements Database.Batchable<sObject>, Schedulable 
{
	
	global SAP_Functions_UpdateAccountPS_Batch() 
	{
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SAP_Functions_UpdateAccountPS_Batch btch = new SAP_Functions_UpdateAccountPS_Batch();
		Database.executeBatch(btch, 25);
	}

	/** Database.Batchable methods **/
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(
			[SELECT Id, PKI_SAP_Source_Account_Number__c, PKI_SAP_Target_Account_Number__c,
				Source_Account__c, Target_Account__c
				FROM Account_Function__c 
				WHERE Target_Account__c = null OR (Source_Account__r.Name = 'Default for SAP Integration' OR Target_Account__r.Name = 'Default for SAP Integration') 
			//AND (Date_Lookups_Last_Modified__c > LAST_N_DAYS:2 OR Date_Lookups_Last_Modified__c = null)
			]);
	}

	global void execute(Database.BatchableContext BC, List<Account_Function__c> functions)
	{
		List<Account_Function__c> functionsToUpdate = SAP_AccountFunctions.lookupAccounts(functions, null);

		//Set<String> accountIds = new Set<String>();
		//for (Account_Function__c function : functions)
		//{
		//	accountIds.add(function.PKI_SAP_Source_Account_Number__c);
		//	accountIds.add(function.PKI_SAP_Target_Account_Number__c);
		//}
			
		//Map<String, Account> accountMap = new Map<String, Account>();
		//if (!accountIds.isEmpty())
		//{
		//	for (Account acct : [SELECT Id, PKI_SAP_Customer_Number__c 
		//		FROM Account WHERE PKI_SAP_Customer_Number__c IN :accountIds])
		//	{
		//		accountMap.put(acct.PKI_SAP_Customer_Number__c, acct);
		//	}
		//}

		//List<Account_Function__c> functionsToUpdate = new List<Account_Function__c>();
		//for (Account_Function__c function : functions)
		//{
		//	Boolean updated = false;
		//	if (function.PKI_SAP_Source_Account_Number__c != null && accountMap.containsKey(function.PKI_SAP_Source_Account_Number__c))
		//	{
		//		Account acct = accountMap.get(function.PKI_SAP_Source_Account_Number__c);
		//		if (function.Source_Account__c != acct.Id)
		//		{
		//			function.Source_Account__c = acct.Id;
		//			updated = true;
		//		}
		//	}
		//	if (function.PKI_SAP_Target_Account_Number__c != null && accountMap.containsKey(function.PKI_SAP_Target_Account_Number__c))
		//	{
		//		Account acct = accountMap.get(function.PKI_SAP_Target_Account_Number__c);
		//		if (function.Target_Account__c != acct.Id)
		//		{
		//			function.Target_Account__c = acct.Id;
		//			updated = true;
		//		}
		//	}

		//	if (updated)
		//	{
		//		function.Date_Lookups_Last_Modified__c = System.today();
		//		functionsToUpdate.add(function);
		//	}
		//}

		if (functionsToUpdate.isEmpty())
			return;

		Database.SaveResult[] results = Database.update(functionsToUpdate, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				Account_Function__c function = functionsToUpdate[i];
				System.debug('Error updating Function: ' + function.Id + ' with Customer Lookups: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
            else
            {
                //System.debug('Successfully updated the function Function ID: ' + result.getId());

            }
		}
		
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
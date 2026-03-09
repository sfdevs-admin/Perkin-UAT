public with sharing class SAP_AccountFunctions {
	private SAP_AccountFunctions() { }

	private static Boolean HAS_RUN_LOOKUP_ACCOUNTS = false;

	public static List<Account_Function__c> lookupAccounts(List<Account_Function__c> functions, Map<Id, Account_Function__c> oldMap)
	{
		if (HAS_RUN_LOOKUP_ACCOUNTS)
			return new List<Account_Function__c>();
		HAS_RUN_LOOKUP_ACCOUNTS = true;

		Set<String> accountIds = new Set<String>();
		for (Account_Function__c function : functions)
		{
			accountIds.add(function.PKI_SAP_Source_Account_Number__c);
			accountIds.add(function.PKI_SAP_Target_Account_Number__c);
		}
			
		Map<String, Account> accountMap = new Map<String, Account>();
		if (!accountIds.isEmpty())
		{
			for (Account acct : [SELECT Id, PKI_SAP_Customer_Number__c 
				FROM Account WHERE PKI_SAP_Customer_Number__c IN :accountIds])
			{
				accountMap.put(acct.PKI_SAP_Customer_Number__c, acct);
			}
		}

		List<Account_Function__c> functionsToUpdate = new List<Account_Function__c>();
		for (Account_Function__c function : functions)
		{
			Boolean updated = false;
			if (function.PKI_SAP_Source_Account_Number__c != null && accountMap.containsKey(function.PKI_SAP_Source_Account_Number__c))
			{
				Account acct = accountMap.get(function.PKI_SAP_Source_Account_Number__c);
				if (function.Source_Account__c != acct.Id)
				{
					function.Source_Account__c = acct.Id;
					updated = true;
				}
			}
			if (function.PKI_SAP_Target_Account_Number__c != null && accountMap.containsKey(function.PKI_SAP_Target_Account_Number__c))
			{
				Account acct = accountMap.get(function.PKI_SAP_Target_Account_Number__c);
				if (function.Target_Account__c != acct.Id)
				{
					function.Target_Account__c = acct.Id;
					updated = true;
				}
			}

			if (updated)
			{
				function.Date_Lookups_Last_Modified__c = System.today();
				functionsToUpdate.add(function);
			}
		}

		return functionsToUpdate;
	}
}
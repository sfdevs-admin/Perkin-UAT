/**
 *  Apex Class for Batch updating Account to Parent Account Lookups.
 *  2017-07-08		Frank VanLoon,Venkata Kalidindi		Initial creation, refactored from UpdateParentAutomated.
 */
global class SAP_Account_UpdateParent_Batch implements Database.Batchable<sObject>, Schedulable 
{
	
	global SAP_Account_UpdateParent_Batch() 
	{
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SAP_Account_UpdateParent_Batch btch = new SAP_Account_UpdateParent_Batch();
		Database.executeBatch(btch, 25);
	}

	/** Database.Batchable methods **/
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id, PKI_SAP_Customer_Base_Number__c 
			FROM Account WHERE RecordType.Name = 'Customer' 
			AND PKI_SAP_Customer_Base_Number__c != '' AND ParentId = null]);
			//AND (Date_Parent_Last_Modified__c > LAST_N_DAYS:2 OR Date_Parent_Last_Modified__c = null)]);
	}

	global void execute(Database.BatchableContext BC, List<Account> accounts)
	{
		Set<String> accountIds = new Set<String>();
		for(Account acct: accounts) 
		{
			accountIds.add(acct.PKI_SAP_Customer_Base_Number__c);
		}

		Map<String, Account> parentAccountMap = new Map<String, Account>();
		// REMOVED:  Account.PKI_SAP_Function__c = 'Hierarchy' AND 
		for(Account parentAcct : [SELECT Id, PKI_SAP_Customer_Number__c FROM Account 
			WHERE Account.PKI_SAP_Customer_Number__c IN :accountIds])
		{
			parentAccountMap.put(parentAcct.PKI_SAP_Customer_Number__c, parentAcct);
		}

		List<Account> accountsToUpdate = new List<Account>();
		for(Account acct : accounts)
		{
			String acctId = acct.PKI_SAP_Customer_Base_Number__c;
			Account parentAcct = (parentAccountMap.containsKey(acctId)) ? parentAccountMap.get(acctId) : null;
			if (parentAcct != null)
			{
				acct.ParentId = parentAcct.Id;
				acct.Date_Parent_Last_Modified__c = System.today();
				accountsToUpdate.add(acct);
			}
		}
        System.debug('Ready to Update');
		if (accountsToUpdate.isEmpty())
			return;

		Database.SaveResult[] results = Database.update(accountsToUpdate, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			Account acct = accountsToUpdate[i];
            if (!result.isSuccess())
			{
				
				System.debug('Error updating Account: ' + acct.Id + ' with Parent Account Lookup: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
            else
            {
                System.debug('Success updating Account: ' + acct.Id);
            }
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
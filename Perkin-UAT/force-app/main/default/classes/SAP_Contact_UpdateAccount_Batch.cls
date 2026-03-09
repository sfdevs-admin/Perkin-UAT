/**
 *  Apex Class for Batch updating Account on the SAP Contact.
 *  2017-07-08		Venkata	Initial creation, refactored from UpdateSAPContactAccountId.
 */
global class SAP_Contact_UpdateAccount_Batch implements Database.Batchable<sObject>, Schedulable 
{
	
	global SAP_Contact_UpdateAccount_Batch() 
	{
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SAP_Contact_UpdateAccount_Batch btch = new SAP_Contact_UpdateAccount_Batch();
		Database.executeBatch(btch, 25);
	}

	/** Database.Batchable methods **/
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id, PKI_SAP_Customer_Number__c,AccountId FROM Contact WHERE 
                                           PKI_SAP_Customer_Number__c != '' AND AccountId = null]); 
                                          //AND LastModifiedDate >= LAST_N_DAYS:2]);
	}

	global void execute(Database.BatchableContext BC, List<Contact> contacts)
	{
		Set<String> contactIds = new Set<String>();
		for(Contact c: contacts) 
		{
			contactIds.add(c.PKI_SAP_Customer_Number__c);
		}

		Map<String, Account> parentAccountMap = new Map<String, Account>();
		for(Account parentAcct : [SELECT Id, PKI_SAP_Customer_Number__c FROM Account 
			WHERE PKI_SAP_Customer_Number__c IN :contactIds])
		{
			parentAccountMap.put(parentAcct.PKI_SAP_Customer_Number__c, parentAcct);
		}

		List<Contact> contactsToUpdate = new List<Contact>();
		for(Contact c : contacts)
		{
			String acctId = c.PKI_SAP_Customer_Number__c;
			Account parentAcct = (parentAccountMap.containsKey(acctId)) ? parentAccountMap.get(acctId) : null;
			if (parentAcct != null)
			{
				c.AccountId = parentAcct.Id;
				//c.Date_Parent_Last_Modified__c = System.today();
				contactsToUpdate.add(c);
			}
		}

		if (contactsToUpdate.isEmpty())
			return;

		Database.SaveResult[] results = Database.update(contactsToUpdate, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				Contact c = contactsToUpdate[i];
				System.debug('Error updating Contact: ' + c.Id + ' with Account Lookup: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
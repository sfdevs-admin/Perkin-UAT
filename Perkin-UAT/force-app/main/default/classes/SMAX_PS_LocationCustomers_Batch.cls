/**
 *  Apex Class for Batch updating Location [SVMXC__Site__c] to Customer Lookups.
 *  2017-07-05		Frank VanLoon		Initial creation, for Location Integration.
 */
global class SMAX_PS_LocationCustomers_Batch implements Database.Batchable<SObject>, Schedulable
{
	global SMAX_PS_LocationCustomers_Batch() { }

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_LocationCustomers_Batch btch = new SMAX_PS_LocationCustomers_Batch();
		Database.executeBatch(btch);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		return Database.getQueryLocator([SELECT Id, RecordTypeId, SVMX_PS_External_ID__c, 
			SMAX_PS_ParentExtID__c, SVMXC__Parent__c,
			SMAX_PS_SoldToExtID__c, SVMXC__Account__c,
			SMAX_PS_BillToExtID__c, SMAX_PS_BillTo__c,
			SMAX_PS_PayerExtId__c, SMAX_PS_Payer__c,
			SMAX_PS_ShipToExtID__c, SMAX_PS_ShipTo__c,
			SMAX_PS_LL_BillToExtID__c, SMAX_PS_LL_BillTo__c,
			SMAX_PS_LL_ShipToExtID__c, SMAX_PS_LL_ShipTo__c,
			SMAX_PS_ContactExtId__c, SMAX_PS_Contact__c,
			SMAX_PS_AltCustomerNumber__c
			FROM SVMXC__Site__c 
			WHERE (SMAX_PS_ParentExtID__c != null AND SVMXC__Parent__c = null) 
			OR (SMAX_PS_SoldToExtID__c != null AND SVMXC__Account__c = null)
			OR (SMAX_PS_BillToExtID__c != null AND SMAX_PS_BillTo__c = null)
			OR (SMAX_PS_PayerExtId__c != null AND SMAX_PS_Payer__c = null)
			OR (SMAX_PS_ShipToExtID__c != null AND SMAX_PS_ShipTo__c = null)
			OR (SMAX_PS_LL_BillToExtID__c != null AND SMAX_PS_LL_BillTo__c = null)
			OR (SMAX_PS_LL_ShipToExtID__c != null AND SMAX_PS_LL_ShipTo__c = null)
			OR (SMAX_PS_ContactExtId__c != null AND SMAX_PS_Contact__c = null)
		]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Site__c> locations) 
	{
		SMAX_PS_LocationManager.lookupLocationCustomers(locations, null);

		Database.SaveResult[] results = Database.update(locations, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Site__c location = locations[i];
				System.debug('Error updating Location: ' + location.Id + ' with Customer Lookups: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) 
	{
	}	

}
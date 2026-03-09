// SVMXCFG-711 Ensure IP address is synced with Location address

global class SMAX_PS_InstalledProductAddresses_Batch implements Database.Batchable<sObject>, Schedulable 
{
	global SMAX_PS_InstalledProductAddresses_Batch() {}

	global void execute(SchedulableContext ctx){
		SMAX_PS_InstalledProductAddresses_Batch btch = new SMAX_PS_InstalledProductAddresses_Batch();
		Database.executeBatch(btch);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id, SMAX_PS_IsAddress_OutOfSync__c, SVMXC__Site__c
										FROM SVMXC__Installed_Product__c
										WHERE SVMXC__Site__c != null 
										AND SMAX_PS_IsAddress_OutOfSync__c = true
										]);
	}

   	global void execute(Database.BatchableContext BC, List<SVMXC__Installed_Product__c> ipList) {

		SMAX_PS_InstalledProductManager.updateIPAddressFields(ipList, null);

		Database.SaveResult[] results = Database.update(ipList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Installed_Product__c ip = ipList[i];
				System.debug('Error updating IP: ' + ip.Id + ' with Location address lookups: ' + result.getErrors());
			}
		}
	}
	
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
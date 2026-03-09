global class SMAX_PS_StorageLocationAddr_Batch implements Database.Batchable<SObject>, Schedulable
{
	global SMAX_PS_StorageLocationAddr_Batch() { }

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_StorageLocationAddr_Batch btch = new SMAX_PS_StorageLocationAddr_Batch();
		Database.executeBatch(btch);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		Id storageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Site__c', 'SMAX_PS_Storage_Location').Id;

		return Database.getQueryLocator([SELECT Id, RecordTypeId, SMAX_PS_ShipTo__c, 
			SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c
			FROM SVMXC__Site__c 
			WHERE RecordTypeId = :storageRecTypeId AND SMAX_PS_ShipTo__c != null
		]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Site__c> locations) 
	{
		SMAX_PS_LocationManager.lookupStorageAddress(locations, null);

		Database.SaveResult[] results = Database.update(locations, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Site__c location = locations[i];
				System.debug('Error updating Location: ' + location.Id + ' with ShipTo Address: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) 
	{
	}	

}
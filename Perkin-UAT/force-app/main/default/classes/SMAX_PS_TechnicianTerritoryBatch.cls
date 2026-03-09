/**
 * Created by frankvanloon on 1/18/21.
 */

global class SMAX_PS_TechnicianTerritoryBatch implements Database.Batchable<SObject>, Schedulable {

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_TechnicianTerritoryBatch btch = new SMAX_PS_TechnicianTerritoryBatch();
		Database.executeBatch(btch, 20);
	}

	/* Database.Batchable methods */

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator([SELECT Id, Name, SVMXC__Service_Territory__c
			FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Service_Territory__c = NULL]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Group_Members__c> techs)
	{
		List<SVMXC__Service_Group_Members__c> updates = new List<SVMXC__Service_Group_Members__c>();
		for (SVMXC__Service_Group_Members__c tech : techs) {
			Id territoryId = SMAX_PS_TechnicianManager.recommendTerritory(tech);
			if (territoryId != null) {
				tech.SVMXC__Service_Territory__c = territoryId;
				updates.add(tech);
			}
		}

		if (updates.isEmpty()) {
			return;
		}

		Database.SaveResult[] results = Database.update(updates, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Service_Group_Members__c tech = techs[i];
				System.debug('Error updating Technician: ' + tech.Id + ' with Recommended Territory: ' + result.getErrors());
			}
		}
	}

	global void finish(Database.BatchableContext BC)
	{
	}
}
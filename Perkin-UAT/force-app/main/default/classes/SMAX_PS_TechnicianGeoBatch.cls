global class SMAX_PS_TechnicianGeoBatch implements Database.Batchable<SObject>, Schedulable {
	
	global SMAX_PS_TechnicianGeoBatch() { }
	
	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_TechnicianGeoBatch btch = new SMAX_PS_TechnicianGeoBatch();
		Database.executeBatch(btch);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		return Database.getQueryLocator([SELECT Id, Name,
			SMAX_PS_Technician_Geographies__c
			FROM SVMXC__Service_Group_Members__c]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Group_Members__c> techs) 
	{
		SMAX_PS_TechnicianManager.updateTechnicianGeographies(techs);

		Database.SaveResult[] results = Database.update(techs, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			if (!result.isSuccess())
			{
				SVMXC__Service_Group_Members__c tech = techs[i];
				System.debug('Error updating Technician: ' + tech.Id + ' with Geographies: ' + result.getErrors());
				// TODO: Replace with insert into Error Log
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) 
	{
	}
	
}
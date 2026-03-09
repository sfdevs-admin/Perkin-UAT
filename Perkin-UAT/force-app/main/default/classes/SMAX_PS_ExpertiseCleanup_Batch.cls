/**
 * Created by frankvanloon on 7/8/21.
 *
 * Updates:
 * 11/30/2022	tony	ITSVMX-1057 Expertise Management Dashboard Updates - Create Experience records for all existing Expertise records
 *
 */
global class SMAX_PS_ExpertiseCleanup_Batch implements Database.Batchable<SObject>, Schedulable {

	// For scheduling only
	global SMAX_PS_ExpertiseCleanup_Batch() {
	}

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_ExpertiseCleanup_Batch batch = new SMAX_PS_ExpertiseCleanup_Batch();
		Database.executeBatch(batch, 10);
	}

	// Database.Batchable methods

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		System.debug('Starting: SMAX_PS_ExpertiseCleanup_Batch');

		// Query Technicians
		return Database.getQueryLocator([SELECT Id, Name FROM SVMXC__Service_Group_Members__c]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Group_Members__c> techs)
	{
		Set<Id> techIds = new Set<Id>();
		for (SVMXC__Service_Group_Members__c tech : techs) {
			techIds.add(tech.Id);
		}

		// Lookup Experience for Tech, map by key
		List<BD_Experience__c> experienceToDelete = new List<BD_Experience__c>();
		Map<String, BD_Experience__c> experienceMap = new Map<String, BD_Experience__c>();
		List<BD_Experience__c> allExperienceList = [
				SELECT Id, BD_Technician__c, BD_External_Key__c, BD_Related_Skill__c, SMAX_PS_Worked_Activity_Types__c
				FROM BD_Experience__c
				WHERE BD_Technician__c IN :techIds
				LIMIT 10000];

		for (BD_Experience__c experience :allExperienceList) {
			String experienceId = experience.BD_Technician__c + '-' + experience.BD_Related_Skill__c;

			if (experience.BD_Related_Skill__c == null || experience.BD_Technician__c == null || experienceMap.containsKey(experienceId)) {
				// Found an invalid or duplicate Experience.. delete it
				experienceToDelete.add(experience);
			} else {
				// Found a valid one.. update the External Id
				experience.BD_External_Key__c = experienceId;
				experienceMap.put(experienceId, experience);
			}
		}

		if (!experienceToDelete.isEmpty()) {
			delete experienceToDelete;
		}

		List<SVMXC__Service_Group_Skills__c> expToDelete = new List<SVMXC__Service_Group_Skills__c>();
		Map<String, SVMXC__Service_Group_Skills__c> expMap = new Map<String, SVMXC__Service_Group_Skills__c>();
		List<SVMXC__Service_Group_Skills__c> allExpertise = [SELECT Id, Name,
				SVMXC__Group_Member__c, SVMXC__Skill__c, SVMX_PS_Expertise_External_ID__c
			FROM SVMXC__Service_Group_Skills__c
			WHERE SVMXC__Group_Member__c IN :techIds
			ORDER BY SVMXC__Group_Member__c LIMIT 10000];
		for (SVMXC__Service_Group_Skills__c expertise : allExpertise) {
			String extId = expertise.SVMXC__Group_Member__c + '-' + expertise.SVMXC__Skill__c;
			if (expertise.SVMXC__Skill__c == null || expertise.SVMXC__Group_Member__c == null || expMap.containsKey(extId)) {
				// Found an invalid or duplicate Expertise.. delete it
				expToDelete.add(expertise);
			} else {
				// Found a valid one.. update the External Id
				expertise.SVMX_PS_Expertise_External_ID__c = extId;
				expMap.put(extId, expertise);

				// Create an Experience if one doesn't exist
				if (experienceMap.get(extId) == null) {
					BD_Experience__c experience = new BD_Experience__c();
					experience.BD_External_Key__c = extId;
					experience.BD_Technician__c = expertise.SVMXC__Group_Member__c;
					experience.BD_Related_Skill__c = expertise.SVMXC__Skill__c;
					experience.BD_Related_Expertise__c = expertise.Id;
					experienceMap.put(extId, experience);
				}
			}
		}

		if (!expToDelete.isEmpty()) {
			delete expToDelete;
		}

		if (!expMap.isEmpty()) {
			update expMap.values();
		}

		// Insert Experience if any
		if (!experienceMap.isEmpty()) {
			upsert experienceMap.values();
		}
	}

	global void finish(Database.BatchableContext BC) {
		System.debug('Finishing: SMAX_PS_ExpertiseCleanup_Batch');
		if (!Test.isRunningTest()) {
			SMAX_PS_ExpertiseTrainExperience_Batch next = new SMAX_PS_ExpertiseTrainExperience_Batch();
			next.execute(null); // mimic the Schedulable method
		}
	}
}
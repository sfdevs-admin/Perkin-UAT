public with sharing class SMAX_PS_TechnicianManager {

	private SMAX_PS_TechnicianManager() { }

	public static void updateTechnicianLocations(List<SVMXC__Service_Group_Members__c> techList, Map<Id, SVMXC__Service_Group_Members__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Technician Locations', 'Update Technicians Inventory Location.'))
		{
			return;
		}

		Set<String> locExtIds = new Set<String>();
		List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
		for (SVMXC__Service_Group_Members__c tech : techList)
		{
			SVMXC__Service_Group_Members__c old = (oldMap == null) ? null : oldMap.get(tech.Id);
			if (String.isNotEmpty(tech.SMAX_PS_Plant__c) && String.isNotEmpty(tech.SMAX_PS_LocationCode__c)
				&& (old == null || tech.SVMXC__Inventory_Location__c == null
					|| tech.SVMXC__Salesforce_User__c != old.SVMXC__Salesforce_User__c
					|| tech.SMAX_PS_Plant__c != old.SMAX_PS_Plant__c
					|| tech.SMAX_PS_LocationCode__c != old.SMAX_PS_LocationCode__c))
			{
				techsToUpdate.add(tech);
				locExtIds.add(getLocExtId(tech));
			}
		}

		if (locExtIds.isEmpty())
		{
			return;
		}

		// Lookup Locations (do we need to filter by RecordType?)
		Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
		for (SVMXC__Site__c loc : [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Service_Engineer__c 
			FROM SVMXC__Site__c WHERE SVMX_PS_External_ID__c IN :locExtIds])
		{
			locMap.put(loc.SVMX_PS_External_ID__c, loc);
		}

		// Match Techs to Locations, update both objects
		Map<Id, SVMXC__Site__c> locsToUpdate = new Map<Id, SVMXC__Site__c>();
		for (SVMXC__Service_Group_Members__c tech : techsToUpdate)
		{
			String locExtId = getLocExtId(tech);
			if (locMap.containsKey(locExtId))
			{
				SVMXC__Site__c loc = locMap.get(locExtId);
				loc.SVMXC__Service_Engineer__c = tech.SVMXC__Salesforce_User__c;
				locsToUpdate.put(loc.Id, loc);

				tech.SVMXC__Inventory_Location__c = loc.Id;
			}
		}

		if (!locsToUpdate.isEmpty())
		{
			update locsToUpdate.values();
		}
	}

	private static String getLocExtId(SVMXC__Service_Group_Members__c tech)
	{
		return tech.SMAX_PS_Plant__c + tech.SMAX_PS_LocationCode__c;
	}

	public static void onTechnicianGeographies(List<SMAX_PS_Geography_Technician__c> geoTechList)
	{
		Set<Id> techIds = new Set<Id>();
		for (SMAX_PS_Geography_Technician__c geoTech : geoTechList)
		{
			techIds.add(geoTech.SMAX_PS_Technician__c);
		}

		List<SVMXC__Service_Group_Members__c> techs = [SELECT Id, Name, SMAX_PS_Technician_Geographies__c,
				SMAX_PS_Technician_Geographies_2__c,
				SMAX_PS_Technician_Geographies_3__c,
				SMAX_PS_Technician_Geographies_4__c
			FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds];

		updateTechnicianGeographies(techs);
		update techs;
	}

	// Added for JIRA: SVMXCFG-403
	public static void updateTechnicianGeographies(List<SVMXC__Service_Group_Members__c> techList)
	{
		if (!SMAX_PS_Utility.isActive('Update Technician Geographies', 'Update Technician Geographies list.'))
		{
			return;
		}

		Set<Id> techIds = new Set<Id>();
		for (SVMXC__Service_Group_Members__c tech : techList)
		{
			techIds.add(tech.Id);
		}

		Map<Id, List<String>> techGeoMap = new Map<Id, List<String>>();
		for (SMAX_PS_Geography_Technician__c geoTech : [SELECT Id, Name, SMAX_PS_Technician__c, SMAX_PS_Location__c,
				SMAX_PS_Geography__r.SMAX_PS_LocationCode__c
			FROM SMAX_PS_Geography_Technician__c WHERE SMAX_PS_Technician__c IN :techIds])
		{
			System.debug('geoTech: [' + geoTech + ']'); //TODO Remove after testing
			Id techId = geoTech.SMAX_PS_Technician__c;
			if (!techGeoMap.containsKey(techId))
			{
				techGeoMap.put(techId, new List<String>());
			}
			String locCode = (String.isBlank(geoTech.SMAX_PS_Location__c)) ?
					geoTech.SMAX_PS_Geography__r.SMAX_PS_LocationCode__c : geoTech.SMAX_PS_Location__c;
			if (locCode != null) {
				techGeoMap.get(techId).add(locCode);
			}
    	}

		List<String> geoTechFields = new List<String> {
			'SMAX_PS_Technician_Geographies__c', 'SMAX_PS_Technician_Geographies_2__c',
			'SMAX_PS_Technician_Geographies_3__c', 'SMAX_PS_Technician_Geographies_4__c' };
		String lastField = geoTechFields.get(geoTechFields.size()-1);
		for (SVMXC__Service_Group_Members__c tech : techList)
		{
			for (String geoTechField : geoTechFields) {
				tech.put(geoTechField, '');
			}
//			tech.SMAX_PS_Technician_Geographies__c = '';
//			tech.SMAX_PS_Technician_Geographies_2__c = '';

			List<String> geoList = techGeoMap.get(tech.Id);
			if (geoList != null && !geoList.isEmpty())
			{
				System.debug('geoList: [' + geoList + ']'); //TODO Remove after testing
				// SVMXCFG-1136 additional logic for "Tech Geo 2" field
				//tech.SMAX_PS_Technician_Geographies__c = ('' + geoList).replace('(', '').replace(')', '');
				for (String geo : geoList)
				{
					for (String geoTechField : geoTechFields) {
						String geoTechValue = (String) tech.get(geoTechField);
						System.debug('geo: [' + geo + ']  geoTechField: [' + geoTechField + ']  geoTechValue: ['  + geoTechValue + ']');  //TODO Remove after testing
						if (String.isBlank(geoTechValue))
						{
							tech.put(geoTechField, geo);
							break;
						}
						else if (geoTechValue.length() + 2 + geo.length() < 255)
						{
							tech.put(geoTechField, geoTechValue + ', ' + geo);
							break;
						}
						else if (geoTechField == lastField) {
							// Overflow...
							geoTechValue += geoTechValue + ', ' + geo;
							tech.put(geoTechField, geoTechValue.abbreviate(255));
						}
					}
        //    *****Commented code for ITSVMX-139 Geo3 and Geo4 fields
        // if (String.isBlank(tech.SMAX_PS_Technician_Geographies__c))
        //   {
        //     tech.SMAX_PS_Technician_Geographies__c = geo;
        //   }
        //   else if (tech.SMAX_PS_Technician_Geographies__c.length() + 2 + geo.length() < 255)
        //   {
        //     tech.SMAX_PS_Technician_Geographies__c += ', ' + geo;
        //   }
        //   else
        //   {
        //     if (String.isBlank(tech.SMAX_PS_Technician_Geographies_2__c))
        //     {
        //       tech.SMAX_PS_Technician_Geographies_2__c = geo;
        //     }
        //     else
        //     {
        //       tech.SMAX_PS_Technician_Geographies_2__c += ', ' + geo;
        //       if (tech.SMAX_PS_Technician_Geographies_2__c.length() > 255)
        //       {
        //         tech.SMAX_PS_Technician_Geographies_2__c = tech.SMAX_PS_Technician_Geographies_2__c.abbreviate(255);
        //         break;
        //       }
        //     } 
        //   *****End of commented code for ITSVMX-139 

				}
			}
		}
	}

	// ITSFDC-509 Update the Depot Queue Id from the Depot Queue Name
	public static void updateDepotQueues(List<SVMXC__Service_Group_Members__c> techList, Map<Id, SVMXC__Service_Group_Members__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Depot Queues', 'Update Technician Depot Queues'))
		{
			return;
		}

		Set<String> queueNames = new Set<String>();
		List<SVMXC__Service_Group_Members__c> techsToUpdate = new List<SVMXC__Service_Group_Members__c>();
		for (SVMXC__Service_Group_Members__c tech : techList)
		{
			SVMXC__Service_Group_Members__c old = (oldMap == null) ? null : oldMap.get(tech.Id);
			if (tech.BD_Depot_Queue_Name__c != null && (old == null || old.BD_Depot_Queue_Name__c != tech.BD_Depot_Queue_Name__c))
			{
				queueNames.add(tech.BD_Depot_Queue_Name__c);
				techsToUpdate.add(tech);
			}
		}

		if (queueNames.isEmpty())
		{
			return;
		}

		Map<String, Group> queueMap = new Map<String, Group>();
		List<Group> queues = [SELECT Id, Name, DeveloperName
			FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames];
		for (Group q : queues)
		{
			queueMap.put(q.DeveloperName, q);
		}

		// ITSVMX-35 Only allow this Queue Lookup if one of the valid "Queue" Roles
		Set<String> queueRoles = new Set<String> { 'Depot Queue', 'Work Order Queue' };
		for (SVMXC__Service_Group_Members__c tech : techsToUpdate)
		{
			Group q = queueMap.get(tech.BD_Depot_Queue_Name__c);
			if (q != null)
			{
				if (queueRoles.contains(tech.SVMXC__Role__c))
				{
					tech.BD_Depot_Queue_Id__c = q.Id;
				}
				else
				{
					tech.addError('Please set the Technician Role to one of the "Queue" values.');
				}
			}
			else
			{
				tech.addError('Could not find Queue with name: ' + tech.BD_Depot_Queue_Name__c);
			}
		}
	}

	// ITSVMX-220 Validate change to Geographies using Territory lookup(s)
	public static void validateTechnicianGeographies(List<SVMXC__Service_Group_Members__c> techList, Map<Id, SVMXC__Service_Group_Members__c> oldMap) {
		if (!SMAX_PS_Utility.isActive('TechValidateTerritoryGeos', 'Validate Technician Geographies to the Territory.')) {
			return;
		}

		Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>();
		for (SVMXC__Service_Group_Members__c tech : techList) {
			SVMXC__Service_Group_Members__c old = (oldMap == null) ? null : oldMap.get(tech.Id);
			// ITSVMX-547 Do not try to validate Geographies if th eTerritory is NOT set
			if (tech.SVMXC__Service_Territory__c == null) {
				continue;
			}

			if (tech.SVMXC__Service_Territory__c != old.SVMXC__Service_Territory__c
				|| tech.SMAX_PS_Technician_Geographies__c != old.SMAX_PS_Technician_Geographies__c
				|| tech.SMAX_PS_Technician_Geographies_2__c != old.SMAX_PS_Technician_Geographies_2__c
				|| tech.SMAX_PS_Technician_Geographies_3__c != old.SMAX_PS_Technician_Geographies_3__c
				|| tech.SMAX_PS_Technician_Geographies_4__c != old.SMAX_PS_Technician_Geographies_4__c)
			{
				techMap.put(tech.Id, tech);
			}
		}

		if (techMap.isEmpty()) {
			return;
		}

		for (SMAX_PS_Geography_Technician__c geoTech : [
				SELECT Id, Name, SMAX_PS_Technician__c, SMAX_PS_Location__c,
						SMAX_PS_Geography__r.BD_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
				FROM SMAX_PS_Geography_Technician__c
				WHERE SMAX_PS_Technician__c IN :techMap.keySet()])
		{
			Id techId = geoTech.SMAX_PS_Technician__c;

			// ITSVMX-220 Validate change to Geographies using Territory lookup(s)
			SVMXC__Service_Group_Members__c tech = techMap.get(techId);
			Id techTerritoryId = tech.SVMXC__Service_Territory__c;
			Id geoTerritoryId = geoTech.SMAX_PS_Geography__r?.BD_Territory__c;
			if (techTerritoryId != null && geoTerritoryId != null) {
				// Both are populated.. must match or inherit
				Id geoTerritory2 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__c;
				Id geoTerritory3 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
				Id geoTerritory4 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
				if (techTerritoryId != geoTerritoryId && techTerritoryId != geoTerritory2
						&& techTerritoryId != geoTerritory3 && techTerritoryId != geoTerritory4) {
					String errorMsg = 'Illegal Territory / Geography Assignment: ' + geoTech.SMAX_PS_Location__c;
					System.debug(errorMsg);
					tech.addError(errorMsg);
					continue;
				}
			}
		}
	}

	/**
	 * Based on the Technician-Geography records, find the best fit Territory (lowest in the Tree)
	 * @param tech Technician
	 * @return Territory Id of the best-fit Territory for the Technician's Geographies
	 */
	public static Id recommendTerritory(SVMXC__Service_Group_Members__c tech) {
		Set<Id> level1 = new Set<Id>();
		Set<Id> level2 = new Set<Id>();
		Set<Id> level3 = new Set<Id>();
		Set<Id> level4 = new Set<Id>();
		for (SMAX_PS_Geography_Technician__c geoTech : [
				SELECT Id, Name, SMAX_PS_Technician__c, SMAX_PS_Location__c,
						SMAX_PS_Geography__r.BD_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
				FROM SMAX_PS_Geography_Technician__c
				WHERE SMAX_PS_Technician__c = :tech.Id])
		{
			Id geoTerritory1 = geoTech.SMAX_PS_Geography__r?.BD_Territory__c;
			if (geoTerritory1 != null) {
				level1.add(geoTerritory1);
			}
			Id geoTerritory2 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__c;
			if (geoTerritory2 != null) {
				level2.add(geoTerritory2);
			}
			Id geoTerritory3 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
			if (geoTerritory3 != null) {
				level3.add(geoTerritory3);
			}
			Id geoTerritory4 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
			if (geoTerritory4 != null) {
				level4.add(geoTerritory4);
			}
		}

		Id result = null;
		if (level1.size() == 1) {
			result = (Id) level1.iterator().next();
		} else if (level2.size() == 1) {
			result = (Id) level2.iterator().next();
		} else if (level3.size() == 1) {
			result = (Id) level3.iterator().next();
		} else if (level4.size() == 1) {
			result = (Id) level4.iterator().next();
		}
		return result;
	}

}
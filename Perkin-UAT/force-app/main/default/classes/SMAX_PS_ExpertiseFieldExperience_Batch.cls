/**
 * Created by tony on 4/6/21.
 */

global without sharing class SMAX_PS_ExpertiseFieldExperience_Batch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    public class FieldScoreRange {
        public Integer fieldScore { get; set; }
        public Integer workMin { get; set; }
        public Integer workMax { get; set; }

        public FieldScoreRange(Integer score, Integer min, Integer max)
        {
            this.fieldScore = score;
            this.workMin = min;
            this.workMax = max;
        }
    }

    public class WorkScore {
        public Integer workScore { get; set; }
        public Integer minMonths { get; set; }
        public Integer maxMonths { get; set; }
        public List<String> orderTypes { get; set;}

        public WorkScore(Integer score, Integer min, Integer max, List<String> orderTypes)
        {
            this.workScore = score;
            this.minMonths = min;
            this.maxMonths = max;
            this.orderTypes = orderTypes;
        }
    }

    // Used across all batches
    public List<WorkScore> workScoreList = new List<WorkScore>();
    public List<FieldScoreRange> fieldScoreRangeList = new List<FieldScoreRange>();
    public Map<String, String> skillNameToIdMap = new Map<String, String>();
    Datetime oldestDateTime = Datetime.now();

    // For scheduling only
    global SMAX_PS_ExpertiseFieldExperience_Batch() {
    }

    global void execute(SchedulableContext ctx) {

        SMAX_PS_ExpertiseFieldExperience_Batch batch = new SMAX_PS_ExpertiseFieldExperience_Batch();
        Database.executeBatch(batch, 10);
    }

    // Database.Batchable methods

    global Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug('Starting: SMAX_PS_ExpertiseFieldExperience_Batch');

        //Datetime dt = (Test.isRunningTest()) ? Datetime.now() : Datetime.now().addYears(-previousYears);
        Map<String, SMAX_PS_Experience_Setting__mdt> experienceMdtMap = SMAX_PS_Experience_Setting__mdt.getAll();
        for(String experienceMdtKey : experienceMdtMap.keySet()) {

            //System.debug('Experience MDT: ' + experienceMdtMap.get(experienceMdt));
            SMAX_PS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);

            if (experienceSetting.SMAX_PS_Type__c == 'Field') {
                FieldScoreRange fieldScoreRange = new FieldScoreRange((Integer) experienceSetting?.SMAX_PS_Score__c,
                        (Integer) experienceSetting?.SMAX_PS_Work_Minimum__c, (Integer) experienceSetting?.SMAX_PS_Work_Maximum__c);
                fieldScoreRangeList.add(fieldScoreRange);

            } else if (experienceSetting.SMAX_PS_Type__c == 'Work') {

                List<String> lstOrderTypes = new List<String>();
                for (String orderType : experienceSetting?.SMAX_PS_Order_Types__c.split(',')) {
                    lstOrderTypes.add(orderType.trim());
                }
                System.debug('lstOrderTypes: ' + lstOrderTypes);

                WorkScore workScore = new WorkScore(
                        (Integer) experienceSetting?.SMAX_PS_Score__c,
                        (Integer) experienceSetting?.SMAX_PS_Minimum_Months__c,
                        (Integer) experienceSetting?.SMAX_PS_Maximum_Months__c,
                        lstOrderTypes);
                workScoreList.add(workScore);
            }
        }
        System.debug('fieldScoreRangeList: ' + fieldScoreRangeList);
        System.debug('workScoreList: ' + workScoreList);

        // Get the oldest work score date to use later
        for (WorkScore ws :workScoreList) {
            Datetime wsMaxMonthsDateTime = Datetime.now().addMonths(-ws.maxMonths);
            if (oldestDateTime > wsMaxMonthsDateTime ) {
                oldestDateTime = wsMaxMonthsDateTime;
            }
        }

        // Query Technicians
        return Database.getQueryLocator([SELECT Id, Name FROM SVMXC__Service_Group_Members__c]);
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Group_Members__c> techs) {

        System.debug('Executing: SMAX_PS_ExpertiseFieldExperience_Batch');

        // Get the list of tech Ids
        Set<Id> techIds = new Set<Id>();
        for (SVMXC__Service_Group_Members__c tech :techs) {
            techIds.add(tech.Id);
        }
        System.debug('techIds: ' + techIds.size() + '  :' + techIds);

        // Query Work Orders for these Technicians
        List<SVMXC__Service_Order__c> woList = [
                SELECT  Id, Name, SVMXC__Order_Status__c, SVMXC__Completed_Date_Time__c,
                        SVMXC__Group_Member__c, SVMXC__Skill__c, SMAX_PS_ModelSeries__c, SVMXC__Order_Type__c
                FROM SVMXC__Service_Order__c
                WHERE SVMXC__Group_Member__c IN :techIds
                AND SMAX_PS_ModelSeries__c != NULL
                AND SVMXC__Completed_Date_Time__c >= :oldestDateTime
                ORDER BY SVMXC__Group_Member__c, SMAX_PS_ModelSeries__c, SVMXC__Order_Type__c
        ];
        System.debug('woList.size(): ' + woList.size());

        // Create a map of Skill Name to Ids
        Set<String> skillNames = new Set<String>();
        for (SVMXC__Service_Order__c wo : woList) {
            skillNames.add(wo.SMAX_PS_ModelSeries__c);
            System.debug('Adding ' + wo.Name + ' wo.SMAX_PS_ModelSeries__c: ' + wo.SMAX_PS_ModelSeries__c);
        }
        System.debug('skillNames: ' + skillNames);

        List<SVMXC__Skill__c> skills = [
                SELECT Id, Name FROM SVMXC__Skill__c
                WHERE Name IN :skillNames
        ];
        System.debug('skills: ' + skills.size() + '  ' + skills);

        for (SVMXC__Skill__c skill :skills) {
            skillNameToIdMap.put(skill.Name, skill.Id);
        }
        System.debug('skillNameToIdMap: ' + skillNameToIdMap.size() + '  ' + skillNameToIdMap);


        List<BD_Experience__c> experienceList = new List<BD_Experience__c>();
        Map<String, Integer> techSkillWorkTotalMap = new Map<String, Integer>();

        // Collect the "Skill Activity Types" worked for each key
        Map<String, Set<String>> techSkillActivityTypes = new Map<String, Set<String>>();

        for (SVMXC__Service_Order__c wo : woList)
        {
            // Create a Tech+Skill Map from each Work Order with a running total score
            if (wo.SVMXC__Group_Member__c != null && wo.SMAX_PS_ModelSeries__c != null && skillNameToIdMap.get(wo.SMAX_PS_ModelSeries__c) != null) {
                String externalId = wo.SVMXC__Group_Member__c + '-' + skillNameToIdMap.get(wo.SMAX_PS_ModelSeries__c);
                System.debug('Tech-Skill: ' + externalId + '  Order Type: ' + wo.SVMXC__Order_Type__c);

                for (WorkScore ws :workScoreList) {
                    Datetime startDT = Datetime.now().addMonths(-ws.maxMonths);
                    Datetime endDT = Datetime.now().addMonths(-ws.minMonths);

                    if (wo.SVMXC__Completed_Date_Time__c >= startDT && wo.SVMXC__Completed_Date_Time__c <= endDT
                            && ws.orderTypes.contains(wo.SVMXC__Order_Type__c)) {
                        System.debug('workScore: ' + ws.workScore);

                        // Convert each WO Order Type into a Skill Activity Type.. add to techSkillActivityTypes
                        String actType = SMAX_PS_ExperienceManager.lookupSkillActivityType(wo.SVMXC__Order_Type__c);
                        if (actType != null) {
                            if (!techSkillActivityTypes.containsKey(externalId)) {
                                techSkillActivityTypes.put(externalId, new Set<String>());
                            }
                            techSkillActivityTypes.get(externalId).add(actType);
                        }

                        if (techSkillWorkTotalMap.get(externalId) == null) {
                            techSkillWorkTotalMap.put(externalId, ws.workScore);
                            System.debug('Added NEW entry to techSkillWorkTotalMap');
                        } else {
                            techSkillWorkTotalMap.put(externalId, techSkillWorkTotalMap.get(externalId) + ws.workScore);
                            System.debug('Updated EXISTING entry to techSkillWorkTotalMap');
                        }
                    }
                }
            }
        }

        // Query any existing Experience records where External Id matches the tech-skill values of the completedTrainingWithTrainedSkillsList
        Set<String> experienceExtIds = techSkillWorkTotalMap.keySet();
        List<BD_Experience__c> existingExperienceList = [
                SELECT Id, BD_External_Key__c, SMAX_PS_Worked_Activity_Types__c
                FROM BD_Experience__c
                WHERE BD_External_Key__c IN :experienceExtIds
        ];

        // Create a Map of Experience Ext Ids to Activity Type so we can use it for comparison later
        Map<String, String> expExtIdToActivityTypeMap = new Map<String, String>();
        for (BD_Experience__c exp :existingExperienceList) {
            expExtIdToActivityTypeMap.put(exp.BD_External_Key__c, exp.SMAX_PS_Worked_Activity_Types__c);
        }
        System.debug('expExtIdToActivityTypeMap: ' + expExtIdToActivityTypeMap);

        for (String extId :techSkillWorkTotalMap.keySet()) {
            BD_Experience__c experience = new BD_Experience__c();
            experience.BD_External_Key__c = extId;
            experience.BD_Work_Total__c = techSkillWorkTotalMap.get(extId);
            experience.BD_Technician__c = extId.substringBefore('-');
            experience.BD_Related_Skill__c = extId.substringAfter('-');
            // Set the Worked Activity Types (additive with previous values)
            Set<String> previousActivityTypeList = SMAX_PS_ExperienceManager.splitValues(expExtIdToActivityTypeMap.get(extId));
            Set<String> trainedActivityTypeList = techSkillActivityTypes.get(extId);
            String combinedActivityTypeString =
                    SMAX_PS_ExperienceManager.combineActivityTypes(previousActivityTypeList, trainedActivityTypeList);
            System.debug('combinedActivityTypeString: ' + combinedActivityTypeString);
            experience.SMAX_PS_Worked_Activity_Types__c = combinedActivityTypeString;

            System.debug('experience.BD_Technician__c: ' + experience.BD_Technician__c);

            // Find the Field Score Range for this Work Total
            for (FieldScoreRange fieldScoreRange :fieldScoreRangeList) {

                if (experience.BD_Work_Total__c >= fieldScoreRange?.workMin &&
                        (fieldScoreRange.workMax == null || experience.BD_Work_Total__c < fieldScoreRange.workMax)) {
                    experience.BD_Field_Score__c = fieldScoreRange.fieldScore;
                    System.debug('Found a Match for the fieldScoreRange: ' + fieldScoreRange.fieldScore);
                    break; // We found the match so break out of the loop
                }
            }

            experienceList.add(experience);
        }

        System.debug('techSkillWorkTotalMap: ' + techSkillWorkTotalMap + '  size: ' + techSkillWorkTotalMap.size());

        // Create the new or update the old Experience records
        if (!experienceList.isEmpty())
        {
            System.debug('Upserting Experience records: ' + experienceList + '  size: ' + experienceList.size());
            upsert experienceList BD_External_Key__c;
        }

        // Zero out the expired Experience records for these Technicians (ones without recent Work scores)
        List<BD_Experience__c> expired = [SELECT Id, BD_Work_Total__c, BD_Field_Score__c
            FROM BD_Experience__c WHERE BD_Technician__c IN :techIds
                AND BD_External_Key__c NOT IN :techSkillWorkTotalMap.keySet()];
        if (expired.isEmpty()) {
            return;
        }

        for (BD_Experience__c e : expired) {
            e.BD_Work_Total__c = 0;
            e.BD_Field_Score__c = 0;
        }
        update expired;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finishing: SMAX_PS_ExpertiseFieldExperience_Batch');
    }
}
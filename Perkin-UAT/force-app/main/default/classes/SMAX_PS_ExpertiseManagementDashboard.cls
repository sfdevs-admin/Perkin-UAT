/**
 * This class encapsulates all of the Wired Services needed for the Expertise Management Dashboard LWC
 * Created by tony on 4/16/21.
 *
 * Updates:
 * 11/30/2022   tony    ITSVMX-1057 Expertise Management Dashboard Updates - Display more search results
 *
 */

public with sharing class SMAX_PS_ExpertiseManagementDashboard {

    @AuraEnabled(Cacheable=true)
    public static List<BD_CustomLookupService.LookupSearchResult> searchTechSkills(String searchTerm, List<String> selectedIds)
    {
        // 11/30/2022 ITSVMX-1057 Expertise Management Dashboard Updates - Display more search results
        //final Integer MAX_RESULTS = 10;
        final Integer MAX_RESULTS = 36;

        // Prepare query parameters
        searchTerm += '*';

        // Execute SOSL search query
        List<List<SObject>> searchResults = [
                FIND :searchTerm
                IN ALL FIELDS
                        RETURNING
                        SVMXC__Service_Group_Members__c(Id, Name, SMAX_PS_Work_Center__c, SMAX_PS_Plant__c WHERE id NOT IN :selectedIds),
                        SVMXC__Skill__c(Id, Name, SVMXC__Skill_Area__c, SVMXC__Active__c WHERE id NOT IN :selectedIds AND SVMXC__Active__c = TRUE),
                        SVMXC__Territory__c(Id, Name, BD_Type__c WHERE Id NOT IN :selectedIds)
                LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<BD_CustomLookupService.LookupSearchResult> results = new List<BD_CustomLookupService.LookupSearchResult>();

        // Extract Technicians
        SVMXC__Service_Group_Members__c[] techs = (List<SVMXC__Service_Group_Members__c>) searchResults[0];
//        SVMXC__Service_Group_Members__c[] techs = (List<SVMXC__Service_Group_Members__c>) searchResults[2];
        for (SVMXC__Service_Group_Members__c tech : techs) {
            results.add(new BD_CustomLookupService.LookupSearchResult(tech.Id, 'SVMXC__Service_Group_Members__c',
                    'custom:custom15', tech.Name, 'Technician: ' + tech.SMAX_PS_Work_Center__c)
            );
        }

        // Extract Skills
        SVMXC__Skill__c[] skills = (List<SVMXC__Skill__c>) searchResults[1];
        for (SVMXC__Skill__c skill : skills) {
            results.add(new BD_CustomLookupService.LookupSearchResult(skill.Id, 'SVMXC__Skill__c',
                    'custom:custom19', skill.Name, 'Skill: ' + skill.SVMXC__Skill_Area__c)
            );
        }

        // Extract Territories & convert them into LookupSearchResult
        SVMXC__Territory__c[] territories = (List<SVMXC__Territory__c>) searchResults[2];
        for (SVMXC__Territory__c territory : territories) {
            results.add(new BD_CustomLookupService.LookupSearchResult(territory.Id, 'SVMXC__Territory__c',
                    'custom:custom78', territory.Name, 'Type: ' + territory.BD_Type__c)
            );
        }

        // Optionally sort all results on title
        results.sort();

        return results;
    }

    public class TechSkillHierarchyWrapper {

        @AuraEnabled public String key{get;set;}
        @AuraEnabled public String keyUrl{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String techName{get;set;}
        @AuraEnabled public String territory{get;set;}
        @AuraEnabled public String expertiseId{get;set;}
        @AuraEnabled public String expertiseUrl{get;set;}
        @AuraEnabled public Integer trainingScore{get;set;}
        @AuraEnabled public String trainingSummary{get;set;}
        //@AuraEnabled public Integer trainingReport{get;set;}
        @AuraEnabled public Integer fieldScore{get;set;}
        @AuraEnabled public String fieldSummary{get;set;}
        //@AuraEnabled public Integer fieldReport{get;set;}
        @AuraEnabled public Integer finalScore{get;set;}
        @AuraEnabled public Integer expertiseScore{get;set;}
        @AuraEnabled public Boolean expertiseExists{get;set;}
        @AuraEnabled public String recommendedAction{get;set;}
        @AuraEnabled public String expertiseActivityType{get;set;}
        @AuraEnabled public String experienceActivityType{get;set;}
        @AuraEnabled public Boolean expanded{get;set;}
        @AuraEnabled public Boolean disableCreate{get;set;}
        @AuraEnabled public Boolean disableRemove{get;set;}
        @AuraEnabled public Boolean disableReport{get;set;}
        @AuraEnabled public String lastModified{get;set;}
        @AuraEnabled public List<TechSkillHierarchyWrapper> items{get;set;}

        public TechSkillHierarchyWrapper(BD_Experience__c experience, Boolean isParent) {

            if (isParent) {
                key = experience.BD_Technician__c;
                keyUrl = '/' + experience.BD_Technician__c;
                name = experience.BD_Technician__r.Name;
//                territory = experience.BD_Technician__r.SVMXC__Service_Territory__r.BD_Qualified_Name__c;
                territory = experience.BD_Technician__r.SVMXC__Service_Territory__r.Name;
                expanded = true;
                disableCreate = true;
                disableRemove = true;
                disableReport = true;
                this.items = new List<TechSkillHierarchyWrapper>();
            } else {
                key = experience.BD_External_Key__c;
                keyUrl = '/' + experience.Id;
                name = experience.BD_Related_Skill__r.Name;
                techName = experience.BD_Technician__r.Name;
                trainingScore = (Integer) experience.BD_Training_Score__c;
                fieldScore = (Integer) experience.BD_Field_Score__c;
                finalScore = (Integer) experience.BD_Final_Score__c;
                recommendedAction = experience.BD_Recommended_Action__c;
                experienceActivityType = experience.SMAX_PS_Trained_Activity_Types__c;
                trainingSummary = (trainingScore == null ? 0 : trainingScore)
                        + (String.isBlank(experience.SMAX_PS_Trained_Activity_Types__c)
                        ? '' : ' [' + experience.SMAX_PS_Trained_Activity_Types__c + ']');
                fieldSummary = (fieldScore == null ? 0 : fieldScore)
                        + (String.isBlank(experience.SMAX_PS_Worked_Activity_Types__c)
                        ? '' : ' [' + experience.SMAX_PS_Worked_Activity_Types__c + ']');

                expertiseId = experience.BD_Related_Expertise__c;
                if (expertiseId != null) {
                    expertiseExists = true;
                    expertiseUrl = '/' + expertiseId;

                    SVMXC__Service_Group_Skills__c expertise = experience.BD_Related_Expertise__r;
                    expertiseScore = (Integer) expertise.SVMXC__Skill_Level__c;
                    this.lastModified = expertise.LastModifiedBy?.Name + expertise.LastModifiedDate.format(' yyyy-MM-dd h:m a');
                    expertiseActivityType = expertise.SMAX_PS_Activity_Type__c;

                } else {
                    expertiseExists = false;
                }

                disableReport = false;
                if (expertiseId == null || expertiseId == '') {
                    disableCreate = false;
                    disableRemove = true;
                } else {
                    disableCreate = true;
                    disableRemove = false;
                }
            }
        }
    }

    // Get the tree for the provided list of Ids
    @AuraEnabled(Cacheable=false)
    public static List<TechSkillHierarchyWrapper> buildTechSkillsTableFromSearch(
            List<String> techSkillIds, Decimal rangeMin, Decimal rangeMax, List<String> rangeTypes, List<String> recommendedActions) {

        // Separate Technician and Skill Ids into different Sets
        Set<Id> techIds = new Set<Id>();
        Set<Id> skillIds = new Set<Id>();
        Set<Id> terrIds = new Set<Id>();
        Set<Id> parentAndChildTerrIds = new Set<Id>();
        String techPrefix = SVMXC__Service_Group_Members__c.SObjectType.getDescribe().getKeyPrefix();
        String skillPrefix = SVMXC__Skill__c.SObjectType.getDescribe().getKeyPrefix();
        String terrPrefix = SVMXC__Territory__c.SObjectType.getDescribe().getKeyPrefix();

        for (String techSkillId :techSkillIds) {
            if (techSkillId.startsWith(techPrefix)) {
                techIds.add(techSkillId);
            } else if (techSkillId.startsWith(skillPrefix)) {
                skillIds.add(techSkillId);
            } else if (techSkillId.startsWith(terrPrefix)) {
                terrIds.add(techSkillId);
            }
        }
        System.debug('techSkillIds: ' + techSkillIds);
        System.debug('techIds: ' + techIds);
        System.debug('skillIds: ' + skillIds);
        System.debug('terrIds: ' + terrIds);

        List<SVMXC__Territory__c> parentAndChildTerritories = [
                SELECT  Id, SVMXC__Parent_Territory__c, SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                        SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                        SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
                FROM SVMXC__Territory__c
                WHERE Id IN :terrIds
                OR SVMXC__Parent_Territory__c IN :terrIds
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c IN :terrIds
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c IN :terrIds
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c IN :terrIds
        ];

        for (SVMXC__Territory__c territory :parentAndChildTerritories) {
                parentAndChildTerrIds.add(territory.Id);
        }
        System.debug('parentAndChildTerrIds: ' + parentAndChildTerrIds);

        // Create WHERE clause that will match what we are searching for
        String whereClause = '';

        if (techIds.size() > 0 || skillIds.size() > 0 || terrIds.size() > 0) {
            whereClause = ' WHERE (';
            if (techIds.size() > 0 && terrIds.size() > 0) {
                whereClause = whereClause + '(BD_Technician__c IN :techIds OR BD_Technician__r.SVMXC__Service_Territory__c IN :parentAndChildTerrIds) AND ';
            } else if (techIds.size() > 0 && terrIds.size() == 0) {
                whereClause = whereClause + 'BD_Technician__c IN :techIds AND ';
            }

            if (terrIds.size() > 0 && techIds.size() == 0) {
                whereClause = whereClause + 'BD_Technician__r.SVMXC__Service_Territory__c IN :parentAndChildTerrIds AND ';
            }

            if (skillIds.size() > 0) {
                whereClause = whereClause + 'BD_Related_Skill__c IN :skillIds AND ';
            }

            // remove the last ending AND
            whereClause = whereClause.substringBeforeLast(' AND ');
            // add ending parenthesis
            whereClause = whereClause + ')';
        }

        // Add the Filtering by Range Types and Values (training, field, expertise)
        System.debug('rangeTypes: ' + rangeTypes.size() + '  :' + rangeTypes);
        String trainingClause = '(BD_Training_Score__c >= :rangeMin AND BD_Training_Score__c <= :rangeMax)';
        String fieldClause = '(BD_Field_Score__c >= :rangeMin AND BD_Field_Score__c <= :rangeMax)';
        String expertiseClause = '(BD_Related_Expertise__r.SVMXC__Skill_Level__c >= :rangeMin AND BD_Related_Expertise__r.SVMXC__Skill_Level__c <= :rangeMax)';

        if (rangeTypes.size() > 0) {

            if (whereClause == '') {
                whereClause = ' WHERE (';
            } else {
                whereClause = whereClause + ' AND (';
            }

            for (String rangeType :rangeTypes) {
                if (rangeType == 'training') {
                    whereClause = whereClause + trainingClause + ' OR ';
                } else if (rangeType == 'field') {
                    whereClause = whereClause + fieldClause + ' OR ';
                } else if (rangeType == 'expertise') {
                    whereClause = whereClause + expertiseClause + ' OR ';
                }
            }

            // remove the last ending OR
            whereClause = whereClause.substringBeforeLast(' OR ');
            // add ending parenthesis
            whereClause = whereClause + ')';
        }

        if (recommendedActions.size() > 0) {
            if (whereClause == '') {
                whereClause = ' WHERE (';
            } else {
                whereClause = whereClause + ' AND (';
            }

            whereClause += 'BD_Recommended_Action__c IN :recommendedActions)';
        }

        String queryString = 'SELECT Id, BD_External_Key__c, BD_Technician__c, BD_Related_Skill__c, BD_Final_Score__c,' +
                'BD_Training_Score__c, BD_Field_Score__c, BD_Related_Expertise__c, BD_Related_Expertise__r.SVMXC__Skill_Level__c, ' +
                'BD_Technician__r.Name, BD_Technician__r.SVMXC__Service_Territory__c, BD_Technician__r.SVMXC__Service_Territory__r.Name, ' +
                'BD_Technician__r.SVMXC__Service_Territory__r.BD_Qualified_Name__c, BD_Related_Skill__r.Name, ' +
                'SMAX_PS_Trained_Activity_Types__c, SMAX_PS_Worked_Activity_Types__c, BD_Related_Expertise__r.SMAX_PS_Activity_Type__c, ' +
                'BD_Related_Expertise__r.LastModifiedBy.Name, BD_Related_Expertise__r.LastModifiedDate, BD_Recommended_Action__c ' +
                'FROM BD_Experience__c ' +
                whereClause + ' ORDER BY BD_Technician__c, BD_Related_Skill__c';

        System.debug('whereClause: ' + whereClause);
        System.debug('queryString: ' + queryString);
        List<BD_Experience__c> experienceList = Database.query(queryString);
        System.debug('experienceList: ' + experienceList.size() + '  '  + experienceList);

        String tempTechId = null;
        TechSkillHierarchyWrapper tempTechSkill;
        List<TechSkillHierarchyWrapper> techSkillList = new List<TechSkillHierarchyWrapper>();
        for (BD_Experience__c experience :experienceList) {

//            Integer expertiseScore = (Integer)expertiseIdToExpertiseMap.get(experience.BD_Related_Expertise__c)?.SVMXC__Skill_Level__c;

            // Add a new Parent
            System.debug('tempTechId: ' + tempTechId + '   experience.BD_Technician__c: ' + experience.BD_Technician__c);
            if (tempTechId != experience.BD_Technician__c && experience.BD_External_Key__c != null) {
                System.debug('Creating a new Parent TechSkillHierarchyWrapper');
                tempTechId = experience.BD_Technician__c;
                TechSkillHierarchyWrapper techSkill = new TechSkillHierarchyWrapper(experience, true);
                techSkillList.add(techSkill);
                tempTechSkill = techSkill;

                // Also add this as child record of the parent
                TechSkillHierarchyWrapper techSkillChild = new TechSkillHierarchyWrapper(
                        experience, false);
                techSkill.items.add(techSkillChild);

            } else if (experience.BD_External_Key__c != null) {

                // Add this as child record of the current parent
                System.debug('Creating a new Child TechSkillHierarchyWrapper');
                TechSkillHierarchyWrapper techSkillChild = new TechSkillHierarchyWrapper(
                        experience, false);
                tempTechSkill.items.add(techSkillChild);
            }
        }

        System.debug('techSkillList: ' + techSkillList);
        return techSkillList;
    }

    @AuraEnabled
    public static String removeExpertise(String techSkillKey, String expertiseId) {
        BD_Experience__c experience = [
                SELECT Id, BD_Related_Expertise__c, BD_Expertise_Removed__c
                FROM BD_Experience__c
                WHERE BD_External_Key__c = :techSkillKey
                LIMIT 1
        ];

        List<SVMXC__Service_Group_Skills__c> expertiseList = [
                SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Skill__c, SVMXC__Skill_Level__c
                FROM SVMXC__Service_Group_Skills__c
                WHERE Id = :expertiseId
        ];

        System.debug('About to Delete: ' + expertiseList);
        delete expertiseList;

        experience.BD_Related_Expertise__c = null;
        experience.BD_Expertise_Removed__c = true;
        update experience;

        return 'Deleted the Expertise';
    }

    @AuraEnabled
    public static String createExpertise( String techSkillKey, Integer skillLevel) {

        if (techSkillKey.length() > 30) {

            String techId = techSkillKey.substringBefore('-');
            String skillId = techSkillKey.substringAfter('-');

            // Get Service Group Team as it is a required field for Expertise
            SVMXC__Service_Group_Members__c tech = [
                    SELECT Id, SVMXC__Service_Group__c
                    FROM SVMXC__Service_Group_Members__c
                    WHERE Id = :techId
            ];

            // Check to see if the Expertise record exists already
            List<SVMXC__Service_Group_Skills__c> expertiseList = [
                    SELECT Id, SVMXC__Skill_Level__c, SVMXC__Service_Group__c, SVMX_PS_Expertise_External_ID__c
                    FROM SVMXC__Service_Group_Skills__c
                    WHERE SVMX_PS_Expertise_External_ID__c = :techSkillKey
            ];
            SVMXC__Service_Group_Skills__c expertise = (expertiseList.isEmpty()) ? null : expertiseList[0];
            if (expertise == null) {
                expertise = new SVMXC__Service_Group_Skills__c();
                expertise.SVMXC__Group_Member__c = techId;
                expertise.SVMXC__Skill__c = skillId;
                expertise.SVMX_PS_Expertise_External_ID__c = techSkillKey;
            }
            expertise.SVMXC__Skill_Level__c = skillLevel;
            expertise.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
            upsert expertise;


            // Update the Experience record with the new Expertise Id
            BD_Experience__c experience = [
                    SELECT Id, BD_Related_Expertise__c, BD_Expertise_Removed__c
                    FROM BD_Experience__c
                    WHERE BD_External_Key__c = :techSkillKey
                    LIMIT 1
            ];

            experience.BD_Related_Expertise__c = expertise.Id;
            experience.BD_Expertise_Removed__c = false;
            update experience;

            return 'Created the Expertise';
        }

        return 'Error: You can only create a new Expertise from a skill line.';
    }

    @AuraEnabled(Cacheable=true)
    public static Id getReportId(String reportType) {

        System.debug(' --  reportType: ' + reportType);

        // return the Training Experience or Field Experience report id
        if (reportType == 'trainingReport') {
            System.debug(' --  querying Expertise_Mgmt_Training_Experience_oWw');
            return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Training_Experience_oWw'].Id;
//            System.debug(' --  querying Expertise_Mgmt_Tech_and_Field_Exp_zpU');
//            return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Tech_and_Field_Exp_zpU'].Id;
        } else if (reportType == 'fieldReport') {
            System.debug(' --  querying Expertise_Mgmt_Field_Experience_wJw');
            return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Field_Experience_wJw'].Id;
        } else {
            return null;
        }
    }

    public class comboBoxResult {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public comboBoxResult(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> getRecommendedActions() {
        List<comboBoxResult> statuses = new List<comboBoxResult>();
        Schema.DescribeFieldResult fieldResult = BD_Experience__c.BD_Recommended_Action__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            statuses.add(new comboBoxResult(pickListVal.getLabel(), pickListVal.getValue()));
        }
        return statuses;
    }

}
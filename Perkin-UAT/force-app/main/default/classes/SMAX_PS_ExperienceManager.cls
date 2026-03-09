/**
 * Created by tony on 4/13/21.
 */

public with sharing class SMAX_PS_ExperienceManager {

    // Called from beforeInsert and beforeUpdate
    public static void updateFinalScore(List<BD_Experience__c> newList, Map<Id, BD_Experience__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Final Score', 'Update the Final Score in Experience.')) {
            return;
        }

        Map<String, Integer> scoresToFinalMap = new Map<String, Integer>();

        Map<String, SMAX_PS_Experience_Setting__mdt> experienceMdtMap = SMAX_PS_Experience_Setting__mdt.getAll();
        for(String experienceMdtKey : experienceMdtMap.keySet()) {

            //System.debug('Experience MDT: ' + experienceMdtMap.get(experienceMdt));
            SMAX_PS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);

            if (experienceSetting.SMAX_PS_Type__c == 'Final') {

                scoresToFinalMap.put((Integer) experienceSetting.SMAX_PS_Field_Score__c + '-' + (Integer) experienceSetting.SMAX_PS_Training_Score__c,
                        (Integer) experienceSetting.SMAX_PS_Score__c);
            }
        }
        System.debug('scoresToFinalMap: ' + scoresToFinalMap);

        if (scoresToFinalMap.size() == 0) {
            System.debug('No Experience Setting Custom Metadata Types have been set up for the "Final" type.');
            return;
        }

        Map<Id, SVMXC__Service_Group_Skills__c> allExpertise = new Map<Id, SVMXC__Service_Group_Skills__c>();
        Map<Id, BD_Experience__c> expertiseExperienceMap = new Map<Id, BD_Experience__c>();
        Map<String, BD_Experience__c> expExtIdMap = new Map<String, BD_Experience__c>();

        for (BD_Experience__c exp : newList) {

            Integer fieldScore = (exp.BD_Field_Score__c == null) ? 0 : (Integer) exp.BD_Field_Score__c;
            Integer trainingScore = (exp.BD_Training_Score__c == null) ? 0 : (Integer) exp.BD_Training_Score__c;

            System.debug('exp.BD_Field_Score__c: [' + exp.BD_Field_Score__c
                    + ']  exp.BD_Training_Score__c: [' + exp.BD_Training_Score__c + ']');
            BD_Experience__c old = (oldMap == null) ? null : oldMap.get(exp.Id);
            if (old == null || exp.BD_Related_Expertise__c == null ||
                (old.BD_Field_Score__c != exp.BD_Field_Score__c
                    || old.BD_Training_Score__c != exp.BD_Training_Score__c
                    || old.SMAX_PS_Trained_Activity_Types__c != exp.SMAX_PS_Trained_Activity_Types__c
                    || old.SMAX_PS_Worked_Activity_Types__c != exp.SMAX_PS_Worked_Activity_Types__c
                    || old.BD_Related_Expertise__c != exp.BD_Related_Expertise__c))
            {
                exp.BD_Final_Score__c = scoresToFinalMap.get(fieldScore + '-' + trainingScore);
                System.debug('exp.BD_Final_Score__c: ' + exp.BD_Final_Score__c);
                if (exp.BD_Related_Expertise__c != null) {
                    expertiseExperienceMap.put(exp.BD_Related_Expertise__c, exp);
                } else {
                    // ITSVMX-531: Try to link the Expertise (if it exists)...
                    expExtIdMap.put(exp.BD_External_Key__c, exp);
                }
            }
        }

        // Try to link existing Expertise records when not already linked...
        if (!expExtIdMap.isEmpty()) {
            List<SVMXC__Service_Group_Skills__c> existingExpertiseList = [
                    SELECT Id, SVMXC__Skill_Level__c, SMAX_PS_Activity_Type__c, SVMX_PS_Expertise_External_ID__c
                    FROM SVMXC__Service_Group_Skills__c
                    WHERE SVMX_PS_Expertise_External_ID__c IN :expExtIdMap.keySet()
            ];
            System.debug('existingExpertiseList: ' + existingExpertiseList.size() + '  :' + existingExpertiseList);

            if (!existingExpertiseList.isEmpty()) {
                for (SVMXC__Service_Group_Skills__c expertise : existingExpertiseList) {
                    BD_Experience__c exp = expExtIdMap.get(expertise.SVMX_PS_Expertise_External_ID__c);
                    exp.BD_Related_Expertise__c = expertise.Id;
                    mapExperienceToExpertise(exp, expertise);

                    allExpertise.put(expertise.Id, expertise);
                }
                update existingExpertiseList;
            }

            // Should we auto-create the Expertise?
            Map<String, BD_Experience__c> expToCreateMap = new Map<String, BD_Experience__c>();
            Set<Id> techIds = new Set<Id>();
            for (BD_Experience__c exp : expExtIdMap.values()) {
                if (exp.BD_Related_Expertise__c == null && exp.BD_Training_Score__c != null && exp.BD_Training_Score__c > 0
                        && exp.BD_Expertise_Removed__c == false) {
                    expToCreateMap.put(exp.BD_External_Key__c, exp);
                    techIds.add(exp.BD_Technician__c);
                }
            }

            // ITSVMX-531: Auto-Create Expertise...
            if (!expToCreateMap.isEmpty()) {
                Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
                    [SELECT Id, Name, SVMXC__Service_Group__c
                        FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);

                List<SVMXC__Service_Group_Skills__c> newExpertise = new List<SVMXC__Service_Group_Skills__c>();
                for (BD_Experience__c exp : expToCreateMap.values()) {
                    SVMXC__Service_Group_Skills__c expertise = new SVMXC__Service_Group_Skills__c();
                    expertise.SVMXC__Group_Member__c = exp.BD_Technician__c;
                    SVMXC__Service_Group_Members__c tech = techMap.get(exp.BD_Technician__c);
                    if (tech != null) {
                        expertise.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
                    }
                    expertise.SVMXC__Skill__c = exp.BD_Related_Skill__c;
                    expertise.SVMX_PS_Expertise_External_ID__c = exp.BD_External_Key__c;
                    mapExperienceToExpertise(exp, expertise);
                    newExpertise.add(expertise);
                }

                insert newExpertise;

                for (SVMXC__Service_Group_Skills__c expertise : newExpertise) {
                    BD_Experience__c exp = expToCreateMap.get(expertise.SVMX_PS_Expertise_External_ID__c);
                    exp.BD_Related_Expertise__c = expertise.Id;

                    allExpertise.put(expertise.Id, expertise);
                }
            }
        }

        // Update any pre-associated Expertise records Skill Level values with the Final Score
        if (!expertiseExperienceMap.isEmpty()) {
            List<SVMXC__Service_Group_Skills__c> updateExpertiseList = [
                    SELECT Id, SVMXC__Skill_Level__c, SMAX_PS_Activity_Type__c
                    FROM SVMXC__Service_Group_Skills__c
                    WHERE Id IN: expertiseExperienceMap.keySet()
            ];
            System.debug('updateExpertiseList: ' + updateExpertiseList.size() + '  :' + updateExpertiseList);

            for (SVMXC__Service_Group_Skills__c expertise :updateExpertiseList) {
                BD_Experience__c exp  = expertiseExperienceMap.get(expertise.Id);
                mapExperienceToExpertise(exp, expertise);

                allExpertise.put(expertise.Id, expertise);
            }
            update updateExpertiseList;
        }

        // Update Recommendations (always)...
        for (BD_Experience__c exp : newList) {
            SVMXC__Service_Group_Skills__c expertise = (exp.BD_Related_Expertise__c == null)
                    ? null : allExpertise.get(exp.BD_Related_Expertise__c);
            exp.BD_Recommended_Action__c = recommendAction(exp, expertise);
        }
    }

    private static void mapExperienceToExpertise(BD_Experience__c exp, SVMXC__Service_Group_Skills__c expertise) {
        expertise.SVMXC__Skill_Level__c = exp.BD_Final_Score__c;

        String trainedActTypes = (exp.SMAX_PS_Trained_Activity_Types__c == null) ? '' : exp.SMAX_PS_Trained_Activity_Types__c;
        Set<String> trainedActivityTypeList = new Set<String>(trainedActTypes.split(';'));
        String workedActTypes = (exp.SMAX_PS_Worked_Activity_Types__c == null) ? '' : exp.SMAX_PS_Worked_Activity_Types__c;
        Set<String> workedActivityTypeList = new Set<String>(workedActTypes.split(';'));
        expertise.SMAX_PS_Activity_Type__c = combineActivityTypes(trainedActivityTypeList, workedActivityTypeList);
    }

    private static String recommendAction(BD_Experience__c exp, SVMXC__Service_Group_Skills__c expertise) {
        if (exp.BD_Final_Score__c >= 3 && exp.BD_Related_Expertise__c == null) {
            return 'Create Expertise';
        } else if (exp.BD_Final_Score__c <= 1 && exp.BD_Related_Expertise__c != null) {
            return 'Remove Expertise';
        } else if (expertise != null) {
            // Determine if Activity Types need to be synced.. if so, set to: 'Update Activity Types'
        }
        return 'None';
    }

    private static Map<String, List<String>> actTypeMap = new Map<String, List<String>>();

    /*
        Lookup the "Skill Activity Type" (PM, OQ, REP) from the WO Order Type
        NOTE: It is very possible that this will return null, as there are many values that do not map
        ITSVMX-531 Needed for the "Worked Activity Types"
     */
    public static String lookupSkillActivityType(String orderType) {

        if (actTypeMap.isEmpty()) {
            Map<String, SMAX_PS_Experience_Setting__mdt> experienceMdtMap = SMAX_PS_Experience_Setting__mdt.getAll();
            for(String key : experienceMdtMap.keySet()) {
                SMAX_PS_Experience_Setting__mdt expMeta = experienceMdtMap.get(key);
                if (expMeta.SMAX_PS_Type__c == 'ActivityType') {
                    String actType = expMeta.DeveloperName.replace('ActivityType_', ''); // REP, PM, OQ
                    List<String> lstOrderTypes = new List<String>();
                    for (String ordType : expMeta?.SMAX_PS_Order_Types__c.split(',')) {
                        lstOrderTypes.add(ordType.trim());
                    }
                    actTypeMap.put(actType, lstOrderTypes);
                }
            }
        }

        for (String actType : actTypeMap.keySet()) {
            List<String> orderTypes = actTypeMap.get(actType);
            if (orderTypes.contains(orderType)) {
                return actType;
            }
        }

        return null;
    }

    public static String combineActivityTypes(Set<String> set1, Set<String> set2) {
        Set<String> combinedSet = new Set<String>(set1);

        // 9/21/21 Tony - fixed production issue where set2 is returned with a null value but not handled
        if (set2 != null) {
            combinedSet.addAll(set2);
        }

        String result = '';
        for (String activityType : combinedSet) {
            result = result + activityType + ';';
        }
        if (result.contains(';')) {
            result = result.substringBeforeLast(';');
        }
        return result;
    }

    public static Set<String> splitValues(String val)
    {
        return (val == null) ? new Set<String>() : new Set<String>(val.split(';'));
    }
}
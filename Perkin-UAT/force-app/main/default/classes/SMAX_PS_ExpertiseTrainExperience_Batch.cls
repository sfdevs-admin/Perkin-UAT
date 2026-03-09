/**
 * Created by tony on 4/12/21.
 */

global class SMAX_PS_ExpertiseTrainExperience_Batch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    public class TrainingScoreRange {
        public Integer trainingScore { get; set; }
        public Integer minMonths { get; set; }
        public Integer maxMonths { get; set; }

        public TrainingScoreRange(Integer score, Integer min, Integer max) {
            this.trainingScore = score;
            this.minMonths = min;
            this.maxMonths = max;
        }
    }

    public class CompletedTrainingWithTrainedSkills {
        public String trainingCourseId { get; set; }
        public String trainingCourseName { get; set; }
        public String technicianId { get; set; }
        public String technicianName { get; set; }
        public Date completionDate { get; set; }
        public String skillId { get; set; }
        public String skillName { get; set; }
        public String activityType { get; set; }

        public CompletedTrainingWithTrainedSkills(String trainingCourseId, String trainingCourseName, String technicianId,
                String technicianName, Date completionDate, String skillId, String skillName, String activityType) {

            this.trainingCourseId = trainingCourseId;
            this.trainingCourseName = trainingCourseName;
            this.technicianId = technicianId;
            this.technicianName = technicianName;
            this.completionDate = completionDate;
            this.skillId = skillId;
            this.skillName = skillName;
            this.activityType = activityType;
        }
    }

    public List<TrainingScoreRange> trainingScoreRangeList = new List<TrainingScoreRange>();
    public Date startDate;
    public Date endDate;

    // For scheduling only
    global SMAX_PS_ExpertiseTrainExperience_Batch() {
    }

    global void execute(SchedulableContext ctx) {

        SMAX_PS_ExpertiseTrainExperience_Batch batch = new SMAX_PS_ExpertiseTrainExperience_Batch();
        Database.executeBatch(batch, 10);
    }

    // Database.Batchable methods

    global Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug('Starting: SMAX_PS_ExpertiseTrainExperience_Batch');

        Map<String, SMAX_PS_Experience_Setting__mdt> experienceMdtMap = SMAX_PS_Experience_Setting__mdt.getAll();
        for(String experienceMdtKey : experienceMdtMap.keySet()) {
            SMAX_PS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);
            if (experienceSetting.SMAX_PS_Type__c == 'Training') {

                TrainingScoreRange trainingScoreRange = new TrainingScoreRange((Integer) experienceSetting?.SMAX_PS_Score__c,
                        (Integer) experienceSetting?.SMAX_PS_Minimum_Months__c, (Integer) experienceSetting?.SMAX_PS_Maximum_Months__c);
                trainingScoreRangeList.add(trainingScoreRange);
            }
        }
        System.debug('trainingScoreRangeList: ' + trainingScoreRangeList);

        // Build Completed Training List query locator
        for (TrainingScoreRange tsr :trainingScoreRangeList) {
            Date startDT = Date.today().addMonths(-tsr.maxMonths);
            Date endDT = Date.today().addMonths(-tsr.minMonths);
            System.debug('startDT: ' + startDT + '  endDT: ' + endDT + '  tsr.trainingScore: ' + tsr.trainingScore);
            if (this.startDate == null || this.startDate > startDT) {
                this.startDate = startDT;
            }
            if (this.endDate == null || this.endDate < endDT) {
                this.endDate = endDT;
            }
        }
        System.debug('Found Start Date = ' + this.startDate + ', and End Date = ' + this.endDate);

        // Query Technicians
        return Database.getQueryLocator([SELECT Id, Name FROM SVMXC__Service_Group_Members__c]);
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Group_Members__c> techs) {

        // Get the list of tech Ids
        Set<Id> techIds = new Set<Id>();
        for (SVMXC__Service_Group_Members__c tech :techs) {
            techIds.add(tech.Id);
        }
        System.debug('techIds: ' + techIds.size() + '  :' + techIds);

        // Find Completed Training for these Technicians...
        List<BD_Completed_Training__c> completedTrainingList = [SELECT Id, Name, BD_Completion_Date__c,
                BD_Training_Course__c, BD_Training_Course__r.Name, BD_Training_Course__r.SMAX_PS_Activity_Type__c,
                BD_Related_Technician__c, BD_Related_Technician__r.Name
            FROM BD_Completed_Training__c
            WHERE BD_Related_Technician__c IN :techIds
                AND BD_Completion_Date__c >= :startDate AND BD_Completion_Date__c <= :endDate
            ORDER BY BD_Related_Technician__c, BD_Training_Course__c, BD_Completion_Date__c DESC];

        System.debug('Executing: SMAX_PS_ExpertiseTrainExperience_Batch');
        System.debug('completedTrainingList: ' + completedTrainingList);

        // Iterate through completedTrainingList to get the set of Training Course Ids
        Set<Id> trainingCourseIds = new Set<Id>();
        for (BD_Completed_Training__c completedTraining :completedTrainingList) {
            trainingCourseIds.add(completedTraining.BD_Training_Course__c);
        }

        // Retrieve the list of trained skills filtered by valid training course Ids
        List<BD_Trained_Skill__c> trainedSKillList = new List<BD_Trained_Skill__c>([
                SELECT BD_Skill__c, BD_Skill__r.Name, BD_Related_Training_Course__c, BD_Related_Training_Course__r.Name
                FROM BD_Trained_Skill__c
                WHERE BD_Related_Training_Course__c IN :trainingCourseIds
        ]);
        System.debug('trainedSKillList: ' + trainedSKillList);

        // Build the list of completed training with the trained skills
        List<CompletedTrainingWithTrainedSkills> completedTrainingWithTrainedSkillsList = new List<CompletedTrainingWithTrainedSkills>();
        Map<String, Boolean> newerCompletedTrainingExists = new Map<String, Boolean>();
        for (BD_Completed_Training__c completedTraining :completedTrainingList) {
            for (BD_Trained_Skill__c trainedSkill :trainedSKillList) {
                if (completedTraining.BD_Training_Course__c == trainedSkill.BD_Related_Training_Course__c) {
                    String extId = completedTraining.BD_Related_Technician__c + '-' + trainedSkill.BD_Skill__c;
                    if (newerCompletedTrainingExists.get(extId) != true) {
                        newerCompletedTrainingExists.put(extId, true);

                        System.debug('Adding CompletedTrainingWithTrainedSkills');
                        CompletedTrainingWithTrainedSkills completedTrainingWithSkills = new CompletedTrainingWithTrainedSkills(
                                completedTraining.BD_Training_Course__c, completedTraining.BD_Training_Course__r.Name,
                                completedTraining.BD_Related_Technician__c, completedTraining.BD_Related_Technician__r.Name,
                                completedTraining.BD_Completion_Date__c, trainedSkill.BD_Skill__c, trainedSkill.BD_Skill__r.Name,
                                completedTraining.BD_Training_Course__r.SMAX_PS_Activity_Type__c);

                        completedTrainingWithTrainedSkillsList.add(completedTrainingWithSkills);
                    } else {
                        System.debug('A newer Trained Skill for this Technician was already found');
                    }
                }
            }
        }

        System.debug('completedTrainingWithTrainedSkillsList: ' + completedTrainingWithTrainedSkillsList);

        // Get the list of Exteral Ids for the the Experience records
        Set<String> experienceExtIds = new Set<String>();
        for (CompletedTrainingWithTrainedSkills compTrainWithTrainSkills :completedTrainingWithTrainedSkillsList) {
            experienceExtIds.add(compTrainWithTrainSkills.technicianId + '-' + compTrainWithTrainSkills.skillId);
        }
        System.debug('experienceExtIds: ' + experienceExtIds);

        // Query any existing Experience records where External Id matches the tech-skill values of the completedTrainingWithTrainedSkillsList
        List<BD_Experience__c> existingExperienceList = [
                SELECT Id, BD_External_Key__c, SMAX_PS_Trained_Activity_Types__c
                FROM BD_Experience__c
                WHERE BD_External_Key__c IN :experienceExtIds
        ];

        // Create a Map of Experience Ext Ids to Activity Type so we can use it for comparison later
        Map<String, String> expExtIdToActivityTypeMap = new Map<String, String>();
        for (BD_Experience__c exp :existingExperienceList) {
            expExtIdToActivityTypeMap.put(exp.BD_External_Key__c, exp.SMAX_PS_Trained_Activity_Types__c);
        }
        System.debug('expExtIdToActivityTypeMap: ' + expExtIdToActivityTypeMap);

        // Create the list of Experience records that will need to be inserted/updated
        List<BD_Experience__c> experienceList = new List<BD_Experience__c>();
        for (CompletedTrainingWithTrainedSkills completedTrainingWithTrainedSkills :completedTrainingWithTrainedSkillsList) {
            BD_Experience__c experience = new BD_Experience__c();
            String extId = completedTrainingWithTrainedSkills.technicianId + '-' + completedTrainingWithTrainedSkills.skillId;
            experience.BD_External_Key__c = extId;
            experience.BD_Related_Skill__c = completedTrainingWithTrainedSkills.skillId;
            experience.BD_Technician__c = completedTrainingWithTrainedSkills.technicianId;

            // Get the Union of the Training Activity Types and the Experience Activity Types
            Set<String> previousActivityTypeList = SMAX_PS_ExperienceManager.splitValues(expExtIdToActivityTypeMap.get(extId));
            Set<String> trainedActivityTypeList = SMAX_PS_ExperienceManager.splitValues(completedTrainingWithTrainedSkills.activityType);
            System.debug('previousActivityTypeList: ' + previousActivityTypeList);
            System.debug('trainedActivityTypeList: ' + trainedActivityTypeList);

            String combinedActivityTypeString =
                    SMAX_PS_ExperienceManager.combineActivityTypes(previousActivityTypeList, trainedActivityTypeList);
            System.debug('combinedActivityTypeString: ' + combinedActivityTypeString);
            experience.SMAX_PS_Trained_Activity_Types__c = combinedActivityTypeString;

            System.debug('experience technician ID: ' + experience.BD_Technician__c);

            // Find the Training Score Range for these Completed Trainings
            for (TrainingScoreRange trainingScoreRange :trainingScoreRangeList) {
                Date startDT = Date.today().addMonths(-trainingScoreRange?.maxMonths);
                Date endDT = Date.today().addMonths(-trainingScoreRange?.minMonths);

                if (completedTrainingWithTrainedSkills.completionDate < endDT &&
                        (startDT == null || completedTrainingWithTrainedSkills.completionDate > startDT)) {
                    experience.BD_Training_Score__c = trainingScoreRange.trainingScore;
                    System.debug('Found a Match for the trainingScoreRange: ' + trainingScoreRange.trainingScore);
                    break; // We found the match so break out of the loop
                }
            }

            experienceList.add(experience);
        }
        System.debug('experienceList: ' + experienceList.size() + '  :' + experienceList);

        // Create the new or update the old Experience records
        if (!experienceList.isEmpty())
        {
            System.debug('Upserting Experience records: ' + experienceList + '  size: ' + experienceList.size());
            upsert experienceList BD_External_Key__c;
        }

        // Zero out the expired Experience records for these Technicians (ones without recent Work scores)
        List<BD_Experience__c> expired = [SELECT Id, BD_Training_Score__c
            FROM BD_Experience__c WHERE BD_Technician__c IN :techIds
                AND BD_External_Key__c NOT IN :experienceExtIds];
        if (expired.isEmpty()) {
            return;
        }

        for (BD_Experience__c e : expired) {
            e.BD_Training_Score__c = 0;
        }
        update expired;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finishing: SMAX_PS_ExpertiseTrainExperience_Batch');
        if (!Test.isRunningTest()) {
            SMAX_PS_ExpertiseFieldExperience_Batch next = new SMAX_PS_ExpertiseFieldExperience_Batch();
            next.execute(null); // mimic the Schedulable method
        }
    }
}
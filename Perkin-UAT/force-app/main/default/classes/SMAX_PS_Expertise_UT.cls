/**
 * Created by tony on 5/19/21.
 *
 * Updates:
 * 11/30/2022   tony    ITSVMX-1057 Expertise Management Dashboard Updates - Create Experience records for all existing Expertise records
 *
 */

@IsTest
private class SMAX_PS_Expertise_UT {
    @IsTest
    static void testExpertiseManagementDashboard() {

        // create test data
        User user1 = SMAX_PS_TestDataFactory.createTestUser('usr1');
        User user2 = SMAX_PS_TestDataFactory.createTestUser('usr2');

        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('Team2', user2, 'Tech2', 'US10', 'LOC234', 'WC234');

        SVMXC__Skill__c skill1 = SMAX_PS_TestDataFactory.createTestSkill('SK123');
        SVMXC__Skill__c skill2 = SMAX_PS_TestDataFactory.createTestSkill('SK234');

        SVMXC__Territory__c terr1 = SMAX_PS_TestDataFactory.createTestTerritory('North America', 'Territory', null);
        SVMXC__Territory__c terr2 = SMAX_PS_TestDataFactory.createTestTerritory('United States', 'Sub Territory', terr1.Id);

        BD_Experience__c experience1 = SMAX_PS_TestDataFactory.createTestExperience(tech1.Id, skill1.Id, 1, 5);
        BD_Experience__c experience2 = SMAX_PS_TestDataFactory.createTestExperience(tech1.Id, skill2.Id, null, 1);

        // since a SOSL query is used by the searchTechSkills method we have to setup a fixed search result
        Id [] fixedSearchResults= new Id[3];
        fixedSearchResults[0] = tech1.Id;
        fixedSearchResults[1] = terr1.Id;
        fixedSearchResults[2] = skill1.Id;
        //Required so SOSL will fire in Unit Tests Properly
        Test.setFixedSearchResults(fixedSearchResults);


        // test dashboard functions
        Test.startTest();
        List<BD_CustomLookupService.LookupSearchResult> searchTechSkills1 = SMAX_PS_ExpertiseManagementDashboard.searchTechSkills('Tech1', new List<String>{terr1.Id, skill1.Id});
        System.debug('searchTechSkills1: ' + searchTechSkills1);
        System.assertEquals(1, searchTechSkills1.size(), 'Failed to find Tech1 technician');

        List<BD_CustomLookupService.LookupSearchResult> searchTechSkills2 = SMAX_PS_ExpertiseManagementDashboard.searchTechSkills('North Am', new List<String>{tech1.Id, skill1.Id});
        System.debug('searchTechSkills2: ' + searchTechSkills2);
        System.assertEquals(1, searchTechSkills2.size(), 'Failed to find "North Am" territory');

        List<BD_CustomLookupService.LookupSearchResult> searchTechSkills3 = SMAX_PS_ExpertiseManagementDashboard.searchTechSkills('SK12', new List<String>{tech1.Id, terr1.Id});
        System.debug('searchTechSkills3: ' + searchTechSkills3);
        System.assertEquals(1, searchTechSkills3.size(), 'Failed to find "SK12" skill');

        List<SMAX_PS_ExpertiseManagementDashboard.TechSkillHierarchyWrapper> buildTechSkillsTableFromSearch =
                SMAX_PS_ExpertiseManagementDashboard.buildTechSkillsTableFromSearch(
                new List<String>{tech1.Id, terr1.Id, skill1.Id}, 0.0, 5.0, new List<String>{'training', 'field', 'expertise'}, new List<String>());
        System.debug('buildTechSkillsTableFromSearch: ' + buildTechSkillsTableFromSearch);
        System.assertEquals(1, buildTechSkillsTableFromSearch.size(), 'Failed to build the tech skills table');

        String techSkillKey = tech1.Id + '-' + skill1.Id;
        String createExpertise = SMAX_PS_ExpertiseManagementDashboard.createExpertise(techSkillKey, 4);
        List<SVMXC__Service_Group_Skills__c> expertiseList1 = [SELECT Id FROM SVMXC__Service_Group_Skills__c];
        System.debug('expertiseList1: ' + expertiseList1);
        System.debug('createExpertise: ' + createExpertise);
        System.assertEquals('Created the Expertise', createExpertise, 'Failed to create expertise record');

        String createExpertise2 = SMAX_PS_ExpertiseManagementDashboard.createExpertise( techSkillKey, 3);
        List<SVMXC__Service_Group_Skills__c> expertiseList2 = [SELECT Id FROM SVMXC__Service_Group_Skills__c];
        System.debug('expertiseList2: ' + expertiseList2);
        System.debug('createExpertise2: ' + createExpertise2);
        System.assertEquals('Created the Expertise', createExpertise2, 'Failed to update expertise record');

        List<BD_Experience__c> experienceList1 = [SELECT Id, BD_Final_Score__c FROM BD_Experience__c WHERE Id = :experience1.Id];
        experience1.BD_Field_Score__c = 2;
        experience1.BD_Related_Expertise__c = expertiseList2[0].Id;
        update experience1;
        List<BD_Experience__c> experienceList2 = [SELECT Id, BD_Final_Score__c FROM BD_Experience__c WHERE Id = :experience1.Id];
        System.assertNotEquals(experienceList1[0].BD_Final_Score__c, experienceList2[0].BD_Final_Score__c, 'Failed to update experience Final Score');

        String removeExpertise = SMAX_PS_ExpertiseManagementDashboard.removeExpertise(techSkillKey, expertiseList1[0].Id);
        System.debug('removeExpertise: ' + removeExpertise);
        System.assertEquals('Deleted the Expertise', removeExpertise, 'Failed to delete expertise record');

        // added for coverage of trigger handler events that have not code
        delete experience1;

        Test.stopTest();
    }

    @IsTest(SeeAllData=true)
    static void testGetReportId() {

        // Need to check these in a separate method with SeeAllData=True to check if the reports actually exist
        Id getReportId1 = SMAX_PS_ExpertiseManagementDashboard.getReportId('trainingReport');
        System.assert(getReportId1 != null, 'Expertise_Mgmt_Tech_and_Field_Exp_zpU report does not exist');

        Id getReportId2 = SMAX_PS_ExpertiseManagementDashboard.getReportId('fieldReport');
        System.assert(getReportId1 != null, 'Expertise_Mgmt_Field_Experience_wJw report does not exist');
    }

    // Test class for SMAX_PS_ExpertiseFieldExperience_Batch
    @IsTest
    static void testExpertiseFieldExperience_Batch() {

        // create test data
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Mystery Machine Inc', 'ACC123','US');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('Scooby Snacks', 'PRD123','PL12');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        User user1 = SMAX_PS_TestDataFactory.createTestUser('usr1');
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        SVMXC__Skill__c skill1 = SMAX_PS_TestDataFactory.createTestSkill('SK123');

        SVMXC__Service_Order__c wo1 = SMAX_PS_TestDataFactory.createWO(ip,cont);
        wo1.SVMXC__Completed_Date_Time__c = Datetime.now().addMonths(-1);
        wo1.SVMXC__Group_Member__c = tech1.Id;
        wo1.SMAX_PS_ModelSeries__c = skill1.Name;
        wo1.SVMXC__Skill__c = skill1.Id;
        update wo1;

        /*SVMXC__Service_Order__c wo2 = SMAX_PS_TestDataFactory.createWO(ip,cont);
        wo2.SVMXC__Completed_Date_Time__c = Datetime.now().addMonths(-11);
        wo2.SVMXC__Group_Member__c = tech1.Id;
        wo2.SMAX_PS_ModelSeries__c = skill1.Name;
        wo2.SVMXC__Skill__c = skill1.Id;
        update wo2;*/


        Test.startTest();

        // run batch job
        SMAX_PS_ExpertiseFieldExperience_Batch batch = new SMAX_PS_ExpertiseFieldExperience_Batch();
        Database.executeBatch(batch);

        Test.stopTest();

        // assert experience records for field scores were correctly inserted/updated
        /*List<BD_Experience__c> experienceList = [SELECT Id, BD_External_Key__c, BD_Work_Total__c, BD_Field_Score__c, BD_Training_Score__c, BD_Final_Score__c
        FROM BD_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assert(experienceList[0].BD_Work_Total__c > 0, 'Work Total was not updated');*/
    }

    // Test class for SMAX_PS_ExpertiseTrainExperience_Batch
    @IsTest
    static void testExpertiseTrainExperience_Batch() {

        // create test data
        User user1 = SMAX_PS_TestDataFactory.createTestUser('usr1');
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        BD_Training_Course__c trainingCourse1 = SMAX_PS_TestDataFactory.createTestTrainingCourse('TrainingCourse1', 'ALL');
        BD_Completed_Training__c completedTraining1 = SMAX_PS_TestDataFactory.createTestCompletedTraining(tech1.Id, trainingCourse1.Id, Date.today().addMonths(-1));
        SVMXC__Skill__c skill1 = SMAX_PS_TestDataFactory.createTestSkill('SK123');
        BD_Trained_Skill__c trainedSkill1 = SMAX_PS_TestDataFactory.createTestTrainedSkill(skill1.Id, trainingCourse1.Id);


        Test.startTest();

        // run batch job
        SMAX_PS_ExpertiseTrainExperience_Batch batch = new SMAX_PS_ExpertiseTrainExperience_Batch();
        Database.executeBatch(batch);

        Test.stopTest();

        // assert experience records for training scores were correctly inserted/updated
        List<BD_Experience__c> experienceList = [SELECT Id, BD_External_Key__c, BD_Work_Total__c, BD_Field_Score__c, BD_Training_Score__c, BD_Final_Score__c
        FROM BD_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assert(experienceList[0].BD_Training_Score__c > 0, 'Training Score was not updated');
    }

    // 11/30/2022 ITSVMX-1057 Expertise Management Dashboard Updates - Create Experience records for all existing Expertise records
    @IsTest
    static void testExpertiseCleanup_Batch() {

        // create test data
        User user1 = SMAX_PS_TestDataFactory.createTestUser('usr1');
        SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        SVMXC__Skill__c skill1 = SMAX_PS_TestDataFactory.createTestSkill('SK123');
        SVMXC__Skill__c skill2 = SMAX_PS_TestDataFactory.createTestSkill('SK234');

        SVMXC__Service_Group_Skills__c exp1 = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill1);
        SVMXC__Service_Group_Skills__c exp1a = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill1);
        SVMXC__Service_Group_Skills__c exp2 = SMAX_PS_TestDataFactory.createTestExpertise(tech1, skill2);

        BD_Experience__c experience1 = SMAX_PS_TestDataFactory.createTestExperience(tech1.Id, null, 10, 5);

        Test.startTest();

        // run batch job
        new SMAX_PS_ExpertiseCleanup_Batch().execute(null);

        Test.stopTest();

        // assert experience records for training scores were correctly inserted/updated
        List<SVMXC__Service_Group_Skills__c> expertiseList = [SELECT Id, Name, SVMX_PS_Expertise_External_ID__c
            FROM SVMXC__Service_Group_Skills__c];
        System.debug('expertiseList: ' + expertiseList);
        System.assertEquals(2, expertiseList.size());

        for (SVMXC__Service_Group_Skills__c exp : expertiseList) {
            System.assertNotEquals(null, exp.SVMX_PS_Expertise_External_ID__c);
        }

        List<BD_Experience__c> experienceList = [SELECT Id, Name, BD_External_Key__c FROM BD_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assertEquals(2, experienceList.size());
    }
}
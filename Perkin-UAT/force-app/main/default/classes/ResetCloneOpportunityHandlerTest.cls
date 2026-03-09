/**************************************************************************************
* Class Name: ResetCloneOpportunityHandlerTest
* Created by: PwC/Amiya Das
* Date Created: Mar 01, 2021
* Date Modified: Mar 03, 2021
* Comment: This class used as test class for 'ResetCloneOpportunityHandler'
* *************************************************************************************/
@isTest
public class ResetCloneOpportunityHandlerTest {

   public static testmethod void testGetCloneOpportunity(){

   Id PKIRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();

   test.startTest();

   // Create test data for opportunity
   Opportunity opp1 = new Opportunity(Name='testopp1', CloseDate = System.today(), StageName = 'Stage 1 - Create/Plan',
                                       RecordTypeId = PKIRT, ForecastCategoryName = 'Omitted');
   insert opp1; 

   // cloning the opportunity
   Opportunity oppClone1 = opp1.clone(false, false, false, false);
   // inserting cloned opportunity
   insert oppClone1;
   
   test.stopTest();

    

   }

   public static testmethod void testGetCloneOppForLDRProf(){

   test.startTest();

   // inserting user with Profile as 'LDR Demand Gen'
    Profile p = [select id from profile where name='LDR Demand Gen'];

   User u = new User(alias = 'test123', email='test123@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='test123@noemail.com.pkinew.pkifull1');
   insert u; 

   // Cloning opportunity in LDR user's context
   system.runAs(u){

   Id PKIRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();

   

   // Create test data for opportunity
    Opportunity opp2 = new Opportunity(Name='testopp1', CloseDate = System.today(), StageName = 'Zero Stage',
                                       RecordTypeId = PKIRT, ForecastCategoryName = 'Omitted',
                                       Solution_Area_of_Interest__c = 'Air');
   insert opp2; 

   // cloning the opportunity
   Opportunity oppClone2 = opp2.clone(false, false, false, false);
   // inserting cloned opportunity
   insert oppClone2;
   
   }
      
   test.stopTest();

   }

}
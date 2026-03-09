/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Title           : Test_Handler_PopulateApproverOpportunity
Author          : Lister Technologies
Description     : This is a test Class to check the functionalities of 
class Handler_PopulateApproverOnOpportunity and 
Trigger VRTaskTrigger.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
@isTest
public class Test_Handler_PopulateApproverOpportunity {
    
    static Profile testprofile = new Profile();
    static UserRole testRole = new UserRole();
    static User testUser = new User();
    static Account testAccount  = new Account();
    static Opportunity testOpp = new Opportunity();
    static Task testTask = new Task();
    static Pre_sales_TechnicalSupport_Request_Table__c testTechSupportReq = new Pre_sales_TechnicalSupport_Request_Table__c();
    static Pre_sales_TechnicalSupport_Request_Table__c testTechSupportReq2 = new Pre_sales_TechnicalSupport_Request_Table__c();
    
    
    static TestMethod void myUnitTest1(){
        Profile testPf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        testRole.Name = 'Test Role#2018';
        insert testRole;
        
        testUser.Username = 'Test_User_2018@gmail.com';
        testUser.FirstName = 'Test User';
        testUser.LastName = '01';
        testUser.Alias = 'TU';
        testUser.Email = 'testUser2018@gmail.com';
        testUser.CommunityNickname = 'tU01';
        testUser.UserRoleId = testRole.id;
        testUser.ProfileId = testPf.Id;
        testUser.Business__c = 'Corp IT';
        testUser.Territory__c = 'AMERICAS';
        testUser.Region__c = 'AMERICAS';
        testUser.TimeZoneSidKey = 'America/New_York';
        testUser.LocaleSidKey = 'en_US';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.CurrencyIsoCode = 'USD';
        testUser.EmailEncodingKey = 'ISO-8859-1';           
        Database.insert(testUser);
        
        /*
* To differentiate Setup object Insertion from a NonSetup Object Insertion As
* Salesforce restricts DML operations so that both kinds of objects can't be manipulated in the same context.
*/
        System.runAs ( testUser )
        {
            RecordType RecTypeAcc = [select Id, Name from RecordType where sObjectType = 'Account' AND Name = 'Prospect'];
            RecordType RecTypeOpp = [select Id, Name from RecordType where sObjectType = 'Opportunity' AND (DeveloperName = 'PKI_Americas_SPI') limit 1];
            
            testTechSupportReq.Name = 'Test Territory Name';
            testTechSupportReq.Sale_Rep__c = testUser.Id;
            testTechSupportReq.Sales_Leader__c = testUser.Id;
            testTechSupportReq.Specialist_Leader__c = testUser.Id;
            Database.insert(testTechSupportReq);
            
            testAccount.RecordTypeId = RecTypeAcc.Id;
            testAccount.Name = 'Test Account';
            testAccount.CurrencyIsoCode = 'USD';
            testAccount.BillingStreet ='1234';
            testAccount.BillingCity='Boston';
            testAccount.BillingState='MA';
            testAccount.BillingCountry='US';
            testAccount.ShippingStreet ='1234';
            testAccount.ShippingCity='Boston';
            testAccount.ShippingState='MA';
            testAccount.ShippingCountry='US';
            Database.insert(testAccount);           
            
            testOpp.RecordTypeId = RecTypeOpp.Id;
            testOpp.Name = 'Test Populate Approver Opportunity';
            testOpp.AccountId = testAccount.Id;
            testOpp.Type = 'Instrument';
            testOpp.Funding__c = 'Funded';
            testOpp.StageName = 'Stage 2 - Needs Analysis';
            testOpp.CloseDate = Date.parse('5/30/2017');
            testOpp.LST_Themes__c = 'Biomakers';
            testOpp.CurrencyIsoCode = 'USD';
            testOpp.EH_Customer_Type__c = 'Commercial';
            testOPP.EH_Global_Campaign__c = 'Industrial Materials';
            testOpp.Shipping_Terms__c = 'FOB Factory';
            testOpp.Solution_Area_of_Interest__c='Energy';
            Database.insert(testOpp);
            
            testTechSupportReq2.Name = 'Test Territory Name';
            testTechSupportReq2.Sale_Rep__c = testUser.Id;
            testTechSupportReq2.Sales_Leader__c = testUser.Id;
            testTechSupportReq2.Specialist_Leader__c = testUser.Id;
            Database.insert(testTechSupportReq2);
            
            testTask.WhatId = testOpp.Id;
            testTask.Assigned_Specialist__c = UserInfo.getUserId();
            testTask.Subject = 'Appointment';
            testTask.ActivityDate = Date.parse('5/30/2017');
            testTask.Type = 'Email Communication';
            testTask.Status = 'Not Started';
            testTask.Priority = 'Normal';
            testTask.Event_Category__c = 'Presales';
            Database.insert(testTask);
            testTask.Event_Category__c = 'Postsales';
            Database.update(testTask);
            testTask.Event_Category__c = 'Presales';
            Database.update(testTask);
            
            //List<Task> testTaskList = new List<Task>();
            //testTaskList.add(testTask);
            
            //Handler_PopulateApproverOnOpportunity testObject = new Handler_PopulateApproverOnOpportunity(testTaskList);
            //testObject.updateLeaders();
        }
    }
}
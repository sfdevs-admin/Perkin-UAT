/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Title           : Test_Handler_PopulateRequestStatusOnTask
Author          : Lister Technologies
Description     : This is a test Class to check the functionalities of 
                  class Handler_PopulateRequestStatusOnTask and 
                  Trigger VROpportunityTrigger.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
@isTest
public class Test_Handler_PopulateRequestStatusOnTask {
    static Account testAccount  = new Account();
    static Opportunity testOpp = new Opportunity();
    static Task testTask1 = new Task();
    static Task testTask2 = new Task();

    static {
        RecordType RecTypeAcc = [select Id, Name from RecordType where sObjectType = 'Account' AND Name = 'Prospect'];
        //There is no longer this record type hence removed
        RecordType RecTypeOpp = [select Id, Name from RecordType where sObjectType = 'Opportunity' AND (DeveloperName = 'PKI_Americas_SPI') limit 1];

        testAccount.RecordTypeId = RecTypeAcc.Id;
        testAccount.Name = 'Test Account';
        testAccount.CurrencyIsoCode = 'USD';
        testAccount.ShippingCity = 'Test City';
        testAccount.ShippingCountry = 'IN';
        testAccount.ShippingState = 'Test State';
        testAccount.ShippingStreet = 'Test Street';
        testAccount.ShippingPostalCode = '123467';
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
        
        testTask1.WhatId = testOpp.Id;
        testTask1.Assigned_Specialist__c = UserInfo.getUserId();
        testTask1.Subject = 'Appointment';
        testTask1.ActivityDate = Date.parse('5/30/2017');
        testTask1.Type = 'Email Communication';
        testTask1.Status = 'Not Started';
        testTask1.Priority = 'Normal';
        testTask1.Event_Category__c = 'Presales';
        Database.insert(testTask1);

        testTask2.WhatId = testOpp.Id;
        testTask2.Assigned_Specialist__c = UserInfo.getUserId();
        testTask2.Subject = 'Appointment';
        testTask2.ActivityDate = Date.parse('5/30/2017');
        testTask2.Type = 'Email Communication';
        testTask2.Status = 'Not Started';
        testTask2.Priority = 'Normal';
        testTask2.Event_Category__c = 'Presales';                       
    }
    
    static testMethod void unitTest1(){
        testOpp.Status_of_the_Request__c = 'Rejected by Sales Leader';
        Database.update(testOpp);

        Database.insert(testTask2);
        testOpp.Status_of_the_Request__c = 'Rejected by Specialist Leader';
        Database.update(testOpp);
    }
}
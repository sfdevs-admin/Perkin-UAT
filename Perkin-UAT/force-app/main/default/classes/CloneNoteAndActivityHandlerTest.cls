@isTest
public class CloneNoteAndActivityHandlerTest 
{   
    @testSetup
    static void makeData()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Origin = 'Email';
        objCase.Subject = 'Case Priority1';
        objCase.Reason = 'Installation';
        objCase.Status = 'New';
        objCase.Priority = 'High';
        objCase.RecordTypeId=system.label.Case_Record_Type_Id;
        insert objCase;
        
        Case objCase1 = new Case();
        objCase1.AccountId = acc.id;
        objCase1.Origin = 'Email';
        objCase1.Subject = 'Case Priority2';
        objCase1.Reason = 'Installation';
        objCase1.Status = 'New';
        objCase1.Priority = 'Medium';
        objCase1.Cloning_From__c = objCase.Id;
        objCase1.RecordTypeId=system.label.Case_Record_Type_Id;
        insert objCase1;
        
        Event eve = new Event();
        eve.ActivityDate = system.today() + 2;
        eve.DurationInMinutes = 0;
        eve.EndDateTime = system.today() + 2;
        eve.StartDateTime = system.today() + 2;
        eve.WhatId = objCase.Id;
        insert eve;
        
        Task tk = new Task();
        tk.ActivityDate = system.today() + 2;
        tk.WhatId = objCase.Id;
        insert tk;
        
        EmailMessage em = new EmailMessage();
     // em.FirstOpenedDate= system.today() + 2;
        em.ParentId = objCase.Id;
        insert em; 
    }
    
    @isTest
    static void cloneNotesActivityTest()
    {
        test.startTest();
        Account acc= [select id,Name from Account where Name = 'Test Account'];
        
        Case CaseList = [select id, CaseNumber, AccountId, Origin, Reason, Status, Priority, Cloning_From__c from Case where AccountID =: acc.Id and Cloning_From__c != null];
        
        Case ClonedCase = CaseList.Clone();
        insert ClonedCase;
        
        system.assertNotEquals(null, ClonedCase);
        test.stopTest();
    }
     
     @isTest
     static void validateData()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
      list<Case> lstCase = new list<case>();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Origin = 'Email';
        objCase.Subject = 'Case Priority3';
        objCase.Reason = 'Installation';
        objCase.Status = 'New';
        objCase.Priority = 'High';
        objCase.RecordTypeId=system.label.Case_Record_Type_Id;
        lstCase.add(objCase);
        
        Case objCase1 = new Case();
        objCase1.AccountId = acc.id;
        objCase1.Origin = 'Email';
        objCase1.Subject = 'Case Priority4';
        objCase1.Reason = 'Installation';
        objCase1.Status = 'New';
        objCase1.Priority = 'Medium';
        objCase1.RecordTypeId=system.label.Case_Record_Type_Id;
        lstCase.add(objCase1);
        insert lstCase;
    }
}
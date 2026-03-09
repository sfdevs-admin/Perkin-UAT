@isTest
public class CaseMergeControllerTest{
    static testMethod void searchTaskTestMethod(){
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
        Lead leadinsert = new Lead(LastName = 'Test User',
                                   Company = 'Test Company',
                                   Phone = '8005551212',
                                   Fax = '8005551212',
                                   Email = 'sumit.shingavi@cloudsherpas.com',
                                   Street = '123 Main Street',
                                   City = 'Pleasantville',
                                   State = 'New Jersey',
                                   PostalCode = '66666',
                                   Country = 'US',
                                   Status = 'New',INF_Related_case__c=casetoinsert.Id);
        
        insert leadinsert;
        CaseComment casecomment = CT_TestDataSetupUtility.createTestCaseComment(casetoinsert.id,'test');
        insert casecomment;
        EmailMessage em = new EmailMessage (Subject='test',ccAddress='test@perkinelmer.com.pkisbxfull.full;',MessageDate=Date.Today(),TextBody='test',HtmlBody='test',Incoming = true,Status ='3',Parentid=casetoinsert.id);
        insert em;
        Attachment att = new Attachment(Name='test',Body=Blob.valueof('test'),Parentid=casetoinsert.id);
        insert att;
        
        INF_Bugs_Suggestions__c bugs = new INF_Bugs_Suggestions__c (Bug__c='test',INF_Bug_Number__c='test',INF_Title__c='test',INF_Type__c='Bug',INF_Case__c =casetoinsert.id);
        insert bugs;
        
        Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
        insert taskcall;
        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
        insert taskemail;
        
        INF_Case_Survey__c  survey = new INF_Case_Survey__c(INF_Recently_Created_Survey__c=true,INF_Support_Sat_Bin__c='test',INF_Support_sat_Comments__c='test',INF_Support_Sat_No__c=true,Case__c=casetoinsert.id);
        insert survey;
        
        Case casetoinsert1 = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert1;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/MergeCase?id='+casetoinsert1.Id));
        CaseMergeController jpc = new CaseMergeController(new ApexPages.StandardController(casetoinsert1));
        jpc.mrgCase.ParentId = casetoinsert.id;
        jpc.mergecase();
        jpc.cancel();
        Test.stopTest();
    }
    
    static testMethod void searchTaskTestMethod1(){
        
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
        
        Lead leadinsert = new Lead( LastName = 'Test User',
                                   Company = 'Test Company',
                                   Phone = '8005551212',
                                   Fax = '8005551212',
                                   Email = 'sumit.shingavi@cloudsherpas.com',
                                   Street = '123 Main Street',
                                   City = 'Pleasantville',
                                   State = 'New Jersey',
                                   PostalCode = '66666',
                                   Country = 'US',
                                   Status = 'New',INF_Related_case__c=casetoinsert.Id);
        
        insert leadinsert;
        Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
        insert taskcall;
        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
        insert taskemail;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/CaseEditPage?id='+casetoinsert.Id));
        CaseEditController jpc = new CaseEditController(new ApexPages.StandardController(casetoinsert));
        jpc.cancel();
        jpc.save();
        jpc.getCase();
        Test.stopTest();
    }
    
    static testMethod void searchTaskTestMethod2(){
        
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
        
        Lead leadinsert = new Lead( LastName = 'Test User',
                                   Company = 'Test Company',
                                   Phone = '8005551212',
                                   Fax = '8005551212',
                                   Email = 'sumit.shingavi@cloudsherpas.com',
                                   Street = '123 Main Street',
                                   City = 'Pleasantville',
                                   State = 'New Jersey',
                                   PostalCode = '66666',
                                   Country = 'US',
                                   Status = 'New',INF_Related_case__c=casetoinsert.Id);
        
        insert leadinsert;
        INF_Application__c app = new INF_Application__c(Name='test',INF_Product_Group__c='CBOE',INF_Product_Line__c ='test',INF_BL__c='test');
        insert app;
        INF_Case_Application__c caseapp = new INF_Case_Application__c(Application__c=app.id,Case__c = casetoinsert.id);
        insert caseapp;
        
        Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
        insert taskcall;
        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
        insert taskemail;
        Set<Id> caseids = new Set<Id>();
        caseids.add(casetoinsert.id);
        delete caseapp;
    }
    
    static testMethod void searchTaskTestMethod4(){
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
        
        Lead leadinsert = new Lead( LastName = 'Test User',
                                   Company = 'Test Company',
                                   Phone = '8005551212',
                                   Fax = '8005551212',
                                   Email = 'sumit.shingavi@cloudsherpas.com',
                                   Street = '123 Main Street',
                                   City = 'Pleasantville',
                                   State = 'New Jersey',
                                   PostalCode = '66666',
                                   Country = 'US',
                                   Status = 'New',INF_Related_case__c=casetoinsert.Id);
        
        insert leadinsert;
        
        Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
        insert taskcall;
        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
        insert taskemail;
        casetoinsert.RecordTypeId = caseRecordTypeId;
        update casetoinsert;
        EmailMessage em = new EmailMessage (Subject='test',MessageDate=Date.Today(),TextBody='test',HtmlBody='test',Incoming = false,Status ='3',Parentid=casetoinsert.id);
        insert em;
    }
    
    static testMethod void searchTaskTestMethod21(){
        
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Contact con1 = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test1@test.com');
        insert con1;
        
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
        
        Lead leadinsert = new Lead( LastName = 'Test User',
                                   Company = 'Test Company',
                                   Phone = '8005551212',
                                   Fax = '8005551212',
                                   Email = 'sumit.shingavi@cloudsherpas.com',
                                   Street = '123 Main Street',
                                   City = 'Pleasantville',
                                   State = 'New Jersey',
                                   PostalCode = '66666',
                                   Country = 'US',
                                   Status = 'New',INF_Related_case__c=casetoinsert.Id);
        
        insert leadinsert;
        
        Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
        insert taskcall;
        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
        insert taskemail;
        
        con1.INF_Tech_Contact__c =TRUE;
        update con1;
        INFEnvironmentalData__c env = new INFEnvironmentalData__c(Name='test',Account__c=acc.id);
        insert env;
        EmailTemplate emtemp = [select id from EmailTemplate where isActive = TRUE LIMIT 1];    
        SendMassEmail.SendEmail(String.Valueof(con1.id),emtemp.id);
    }
}
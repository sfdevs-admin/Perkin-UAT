@isTest
public class InternalCaseViewControllerTest{
    static testMethod void searchTaskTestMethod(){
      
    Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
    insert acc;
    Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
    insert con;
    Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
    insert casetoinsert;
    CaseComment casecomment = CT_TestDataSetupUtility.createTestCaseComment(casetoinsert.id,'test');
    insert casecomment;
    EmailMessage em = new EmailMessage (Subject='test',MessageDate=Date.Today(),TextBody='test',HtmlBody='test',Incoming = true,Status ='3',Parentid=casetoinsert.id);
   // insert em;

    EmailMessage em1 = new EmailMessage (Subject='test',MessageDate=Date.Today(),Incoming = false,Status ='3',Parentid=casetoinsert.id);
    em1.HtmlBody = 'Hi\nThis is an automatically generated email. We have received no response to our last email over the past week. This case will automatically close in 3 business days unless you have any further updates, questions or concerns. \nBest Regards,';
    em1.HtmlBody =  em1.HtmlBody + 'PerkinElmer Support \n on launch of Inventory, when we try to log in with the default password, we have the following message\n"Application error: Format of the initialization string does not conform to specification starting at index 113\n"';
    em1.HtmlBody = em1.HtmlBody + 'after that, we are unable to start the program.Customer Information:×××FirstName×philippe××LastName×francois××Organization× ××Email×philippe.francois@mil.be×××Case Data:×××Application×Inventory Enterprise××ApplicationVersion×V12.0××SerialNumber× 091-206675-0942××OperatingSystem×Windows XP××Browser×Firefox 32.x+××MS-Office×2007××Priority×Critical××Title×Error message on launch××Origin×Portal×××';
    em1.HtmlBody =  em1.HtmlBody + 'On Thu, Feb 18, 2016 at 5:10 PM, E-commerce <ecommercealias@gmail.com> wrote: \nPerkinElmer Support \n on launch of Inventory, when we try to log in with the default password, we have the following message\n"Application error: Format of the initialization string does not conform to specification starting at index 113\n"';

    EmailMessage em2 = new EmailMessage (Subject='test',MessageDate=Date.Today(),Incoming = false,Status ='3',Parentid=casetoinsert.id);
    em2.TextBody = 'Hi\nThis is an automatically generated email. We have received no response to our last email over the past week. This case will automatically close in 3 business days unless you have any further updates, questions or concerns. \nBest Regards,';
    em2.TextBody =  em2.TextBody + 'On Thu, Feb 18, 2016 at 5:10 PM, E-commerce <ecommercealias@gmail.com> wrote: \nPerkinElmer Support \n on launch of Inventory, when we try to log in with the default password, we have the following message\n"Application error: Format of the initialization string does not conform to specification starting at index 113\n"';
    em2.TextBody = em2.TextBody + 'after that, we are unable to start the program.Customer Information:×××FirstName×philippe××LastName×francois××Organization× ××Email×philippe.francois@mil.be×××Case Data:×××Application×Inventory Enterprise××ApplicationVersion×V12.0××SerialNumber× 091-206675-0942××OperatingSystem×Windows XP××Browser×Firefox 32.x+××MS-Office×2007××Priority×Critical××Title×Error message on launch××Origin×Portal×××';
    em2.TextBody = em2.TextBody + '--------------- Original Message ---------------\nFrom: test tset [testlisterpki@gmail.com]\nSent: 2/18/2016 6:41 AM\nTo: ecommercealias@gmail.com\nSubject: Re: Sandbox: Test EmaIL [ ]\nTest Reply Email -  1';
        

    insert new List<EmailMessage>{em,em1,em2};

    Attachment att = new Attachment(Name='test',Body=Blob.valueof('test'),Parentid=casetoinsert.id);
    insert att;
    Task taskcall = new Task(Subject='test',Description='test',Type ='Phone Call',Status ='Completed',WhatId =casetoinsert.id );
    insert taskcall;
    Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',WhatId =casetoinsert.id );
    insert taskemail;
     Test.startTest();
     Test.setCurrentPage(new PageReference('/apex/InternalCaseView?id='+casetoinsert.Id));
     InternalCaseViewController jpc = new InternalCaseViewController(new ApexPages.StandardController(casetoinsert));
     jpc.buildTimeLine();
     Test.stopTest();
   }  
}
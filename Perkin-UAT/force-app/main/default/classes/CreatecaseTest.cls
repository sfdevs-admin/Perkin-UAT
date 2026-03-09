@isTest
private class CreatecaseTest{
    static testMethod void myTest() {
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;        
        Task taskemail = new Task(Subject='test',Description='test',Type ='Email',Status ='Completed',Whoid =con.id);
        insert taskemail;
        System.debug('$$$$$'+taskemail);
        System.debug('$$$$$'+taskemail.Id);
        System.debug('$$$$$'+casetoinsert);
        System.debug('$$$$$'+casetoinsert.Id);
        CreateCase.createcaserecord(taskemail.id);
        CreateCase.createleadrecord(casetoinsert.id);
        
      }
}
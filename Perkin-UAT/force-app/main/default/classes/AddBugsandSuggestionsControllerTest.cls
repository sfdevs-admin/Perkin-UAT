@isTest
public class AddBugsandSuggestionsControllerTest{
    /*static testMethod void AddBugsandSuggestionsController(){
      
    Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
    insert acc;
    Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
    insert con;
    Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
    insert casetoinsert;
    INF_Bugs_Suggestions__c emp = new INF_Bugs_Suggestions__c(INF_Case__c  = casetoinsert.id, Bug__c = 'xxxx-12: This is a test',INF_Type__c='Bug');

     Test.startTest();
     PageReference pr = page.AddBugsandSuggestions;
     Test.setCurrentPage(pr);
     Apexpages.currentPage().getParameters().put('id',casetoinsert.Id);
     AddBugsandSuggestionsController jpc = new AddBugsandSuggestionsController(new ApexPages.StandardController(casetoinsert));
     AddBugsandSuggestionsController.Accountwrapper empW = new AddBugsandSuggestionsController.Accountwrapper(emp);           
     jpc.addRow();
     jpc.saving();
     jpc.Goback();
   //  jpc.removingRow();
     Test.stopTest();
    }*/
    
    static testMethod void AddBugsandSuggestionsController1(){
      
   // Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
    
    Account acc = new Account(Name = 'TEST',
            Phone = '77778',
            Industry = 'Test', 
            BillingStreet = 'Green Street', 
            BillingCity = 'NY',
            BillingState = 'CA', 
            BillingPostalCode = '95123', 
            BillingCountry = 'US', 
            Type = 'Vendor', 
            Website = 'www.xyz.com',
            ShippingCountry = 'US',
            ShippingStreet = 'Green Street', 
            ShippingCity = 'NY',
            ShippingState = 'CA', 
            ShippingPostalCode = '95123'
            );
    
    insert acc;
    Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
    insert con;
    Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
    insert casetoinsert;
    system.debug('******* Case data'+ casetoinsert);
    INF_Bugs_Suggestions__c emp = new INF_Bugs_Suggestions__c(INF_Case__c  = casetoinsert.id, Bug__c = 'CSBR-1234 - Testing now',INF_Type__c='Bug');
    insert emp;
    system.debug('******* Case data'+ emp);
    
     Test.startTest();
     PageReference pr = page.AddBugsandSuggestions;
     Test.setCurrentPage(pr);
     Apexpages.currentPage().getParameters().put('id',casetoinsert.Id);
     AddBugsandSuggestionsController jp = new AddBugsandSuggestionsController(new ApexPages.StandardController(casetoinsert));
     AddBugsandSuggestionsController.Accountwrapper empW = new AddBugsandSuggestionsController.Accountwrapper(emp);
     Apexpages.currentPage().getParameters().put('index', String.valueOf(jp.accountwrapperList[0].counterWrap));              
     jp.addRow();
     jp.saving();
     jp.Goback();
    // system.debug('******* Case data'+ jp);
     jp.removingRow();
     Test.stopTest();
    }
}
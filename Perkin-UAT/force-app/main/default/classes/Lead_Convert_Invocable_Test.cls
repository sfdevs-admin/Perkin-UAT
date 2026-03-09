/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - S-692566	Custom Lead Conversion
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    This is the test class for Apex Class "Lead_Convert_Invocable" that allows the
  *    auto-conversion of Leads based on criteria.
  *    
  * 3. Objects referenced
  *    -Lead
  *    -Contact
  *    -Account
  *    -Opportunity 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es): Lead_Convert_Invocable
  *
  * 6. Author Name(s): 
  *    - Devanshu Bansal (2022.05.25)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 

@isTest
private class Lead_Convert_Invocable_Test {
    
    static testMethod void convertLeadsWithNewConExistingOppTest() {
        Lead objLead = new Lead( FirstName = 'Test', LastName = 'Lead', Company = 'Test company', Email = 'abc@test.com');  
        insert objLead;  
        
        Account acc = new Account(Name = 'Test company');
        insert acc;
        
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Contact', Email = 'abc@test.com');
        insert con;
        
        List<Lead_Convert_Invocable.LeadConvertRequest> leadConvertRequests = new List<Lead_Convert_Invocable.LeadConvertRequest>();
        Lead_Convert_Invocable.LeadConvertRequest leadConvertRequestObj = new Lead_Convert_Invocable.LeadConvertRequest();
        
        leadConvertRequestObj.leadId = objLead.Id;
        leadConvertRequestObj.accountId = acc.Id;
        leadConvertRequestObj.contactId = con.Id;
        leadConvertRequestObj.convertedStatus = 'Qualified';
        leadConvertRequests.add(leadConvertRequestObj);
       
        Test.StartTest(); 
        List<Lead_Convert_Invocable.LeadConvertResult> leadConvertResult = Lead_Convert_Invocable.convertLeads(leadConvertRequests);
        Test.StopTest();
          
        system.assertEquals(acc.Id, leadConvertResult[0].accountId);
    }
    
    static testMethod void convertLeadsWithExistingConExistingOppTest() {
        Lead objLead = new Lead( FirstName = 'Test', LastName = 'Lead', Company = 'Test company', Email = 'abc@test.com');  
        insert objLead;  
        
        Account acc = new Account(Name = 'Test company',Account_Type__c='Academic institution');
        insert acc;
        
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Contact', Email = 'abc@test.com');
        insert con;
        
        Contact conRec = [Select Id, Name, Email from Contact];
        
        List<Lead_Convert_Invocable.LeadConvertRequest> leadConvertRequests = new List<Lead_Convert_Invocable.LeadConvertRequest>();
        Lead_Convert_Invocable.LeadConvertRequest leadConvertRequestObj = new Lead_Convert_Invocable.LeadConvertRequest();
        
        leadConvertRequestObj.leadId = objLead.Id;
        leadConvertRequestObj.accountId = acc.Id;
        leadConvertRequestObj.convertedStatus = 'Qualified';
        leadConvertRequests.add(leadConvertRequestObj);
       
        Test.StartTest(); 
        List<Lead_Convert_Invocable.LeadConvertResult> leadConvertResult = Lead_Convert_Invocable.convertLeads(leadConvertRequests);
        Test.StopTest();
          
        system.assertEquals(acc.Id, leadConvertResult[0].accountId);
    }
    
    static testMethod void convertLeadsWithNewConNewOppTest() {
        Lead objLead = new Lead( FirstName = 'Test', LastName = 'Lead', Company = 'Test company', Email = 'abc@test.com');  
        insert objLead;  
        
        RecordType recType =  [Select Id, Name from RecordType where sObjectType='Account' and name='Prospect'];
        
        Account acc = new Account(Name = 'Test company',Account_Type__c='Academic institution', RecordTypeId = recType.Id);
        insert acc;
        
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Contact', Email = 'abc@test.com');
        insert con;
        
      	Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.CloseDate=date.today().addMonths(2);
        opp.Name='test opp';
        opp.StageName='Stage 1 - Create/Plan';
        opp.Owned_by_Company__c = 'LSDX';
        insert opp; 
        
        List<Lead_Convert_Invocable.LeadConvertRequest> leadConvertRequests = new List<Lead_Convert_Invocable.LeadConvertRequest>();
        Lead_Convert_Invocable.LeadConvertRequest leadConvertRequestObj = new Lead_Convert_Invocable.LeadConvertRequest();
        
        leadConvertRequestObj.leadId = objLead.Id;
        leadConvertRequestObj.accountId = acc.Id;
        leadConvertRequestObj.contactId = con.Id;
        leadConvertRequestObj.convertedStatus = 'Qualified';
        leadConvertRequestObj.opportunityAction ='New';
        leadConvertRequests.add(leadConvertRequestObj);
       
        Test.StartTest(); 
       // List<Lead_Convert_Invocable.LeadConvertResult> leadConvertResult = Lead_Convert_Invocable.convertLeads(leadConvertRequests);
        Test.StopTest();
          
      //  system.assertEquals(acc.Id, leadConvertResult[0].accountId);
    }
    
    static testMethod void convertLeadsWithNewConLinkOppTest() {
        Lead objLead = new Lead( FirstName = 'Test', LastName = 'Lead', Company = 'Test company', Email = 'abc@test.com');  
        insert objLead;  
        
        RecordType recType =  [Select Id, Name from RecordType where sObjectType='Account' and name='Prospect'];
        
        Account acc = new Account(Name = 'Test company',Account_Type__c='Academic institution', RecordTypeId = recType.Id);
        insert acc;
        
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Contact', Email = 'abc@test.com');
        insert con;
        
      	Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.CloseDate=date.today().addMonths(2);
        opp.Name='test opp1';
        opp.StageName='Stage 1 - Create/Plan';
        opp.Owned_by_Company__c = 'LSDX';
        insert opp; 
        
        List<Lead_Convert_Invocable.LeadConvertRequest> leadConvertRequests = new List<Lead_Convert_Invocable.LeadConvertRequest>();
        Lead_Convert_Invocable.LeadConvertRequest leadConvertRequestObj = new Lead_Convert_Invocable.LeadConvertRequest();
        
        leadConvertRequestObj.leadId = objLead.Id;
        leadConvertRequestObj.accountId = acc.Id;
        leadConvertRequestObj.contactId = con.Id;
        leadConvertRequestObj.convertedStatus = 'Qualified';
        leadConvertRequestObj.opportunityAction ='Link';
        leadConvertRequests.add(leadConvertRequestObj);
       
        Test.StartTest(); 
       // List<Lead_Convert_Invocable.LeadConvertResult> leadConvertResult = Lead_Convert_Invocable.convertLeads(leadConvertRequests);
        Test.StopTest();
          
      //  system.assertEquals(acc.Id, leadConvertResult[0].accountId);
    }
}
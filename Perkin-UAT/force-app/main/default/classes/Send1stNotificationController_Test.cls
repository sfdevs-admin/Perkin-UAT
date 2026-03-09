@isTest
public class Send1stNotificationController_Test {
    
    static testmethod void validateOpportunityTest(){
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.ShippingStreet = 'Test Street';
        acct.ShippingState = 'Test State';
        acct.ShippingCity = 'Test City';
        acct.ShippingCountry = 'US';
        acct.ShippingPostalCode = '0111';     
        insert acct;
        
        Contact con = new Contact();
        con.Email = 'TestContact@testemail.com';
        con.LastName = 'Test LName';
        insert con;
        
        Id InformaticsOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
        List<id> oppIds = new List<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity informaticsOpp = new Opportunity();
        informaticsOpp.Name = 'Test Informatics Opp';
        informaticsOpp.RecordTypeID = InformaticsOppRT;
        informaticsOpp.Strategic_Market_INF__c = 'Life Sciences Research';
        informaticsOpp.Type = 'Renewal';
        informaticsOpp.CloseDate = System.Today() + 365;
        informaticsOpp.StageName = 'Stage 5 - Negotiation';
        informaticsOpp.Primary_Contact__c = con.Id;
        informaticsOpp.Account = acct;
        informaticsOpp.Quote_Document_Name__c = 'Q-17509-20190703-1054';
        informaticsOpp.Application__c = 'Chemicals & Mining';
        informaticsOpp.Application_Market__c = 'Applied';
        informaticsOpp.Application_Segment__c = 'Informatics';
        informaticsOpp.Quote_Document_ID__c ='015780000008zV2AAI';
        insert informaticsOpp;
        
        // Create Email Template (Fixes List Index Error)
        EmailTemplate emailTemplate = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Informatics_Contract_Renewal_Quotation_Template_1st_Notice_Custom',
            Subject = 'Test Subject',
            HtmlValue = '<html><body>Test Email</body></html>',
            FolderId = UserInfo.getUserId() );
           
        //insert emailTemplate;
        Test.startTest();
        String result = Send1stNotificationController.validateOpportunity(informaticsOpp.Id);
        Test.stopTest();

        System.debug('Result: ' + result);
        //Send1stNotificationController.validateOpportunity(informaticsOpp.Id);
    }
}
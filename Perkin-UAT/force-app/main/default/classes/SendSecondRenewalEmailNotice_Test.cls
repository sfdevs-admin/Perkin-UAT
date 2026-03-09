@isTest
public class SendSecondRenewalEmailNotice_Test {
    /*
    Test Method for SendSecondRenewalEmailNotice method sendSecondEmail
    Send second email notice 30 days before Quote Start Date 
    */
    
    private static testMethod void sendSecondEmail() {
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testPerkinElmer.com');
        //insert u;
        
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.ShippingStreet = 'Test Street';
        acct.ShippingState = 'Test State';
        acct.ShippingCity = 'Test City';
        acct.ShippingCountry = 'US';
        acct.ShippingPostalCode = '0111';     
        insert acct;
        
        Contact con = new Contact();
        con.Email = '';
        con.LastName = 'Test LName';
        insert con;
        
        Id InformaticsOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
        List<id> oppIds = new List<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity informaticsOpp = new Opportunity();
        informaticsOpp.Name = 'Test Informatics Opp';
        informaticsOpp.RecordTypeID = InformaticsOppRT;
        informaticsOpp.Strategic_Market_INF__c = 'Life Sciences Research';
        informaticsOpp.Type = 'New Products';
        informaticsOpp.CloseDate = System.Today() + 365;
        informaticsOpp.StageName = 'Stage 1 - Create/Plan';
        informaticsOpp.Primary_Contact__c = con.Id;
        informaticsOpp.Account = acct;
        informaticsOpp.Quote_Document_Name__c = 'Q-17509-20190703-1054';
        informaticsOpp.Send_Final_Email_Notice__c = true;
        insert informaticsOpp;
        oppIds.add(informaticsOpp.Id);
        oppList.add(informaticsOpp);
        
        String quoteDocName = oppList[0].Quote_Document_Name__c + '.pdf';
        
        Attachment att = new Attachment();
        Blob b = Blob.valueOf('Test Data');
        att.Body = b;
        att.Name = quoteDocName;
        att.ParentId = oppList[0].Id;
        insert att;
        
        Attachment attList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =: oppList[0].Id AND Name =: quoteDocName];
        
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.body = attList.Body;
        fileAttachment.contenttype = attList.ContentType;
        fileAttachment.filename = attList.Name;
        fileAttachment.inline = false;       
        fileAttachments.add(fileAttachment);
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { oppList[0].Opportunity_Primary_Contact_Email_INF__c };
        message.optOutPolicy = 'FILTER';
        message.setTemplateId('00X29000000EYj5');
        message.setTargetObjectId(oppList[0].Primary_Contact__c);
        message.setWhatId(oppList[0].Id);
        message.setCcAddresses(new String[] { 'renewalemailservice@2twn2xgu3it8axgsy5qq9n93groykgejkalxz8verri6nbzp4x.29-wzueaa.cs19.apex.sandbox.salesforce.com' });
        
        Test.StartTest();
        SendSecondRenewalEmailNotice.sendSecondEmail(oppIds);
        Integer invocations = Limits.getEmailInvocations();
        
        SendSecondRenewalEmailNotice.sendSecondEmail(new list<Id> {att.Id});  
        //System.assertEquals(1, invocations, 'An email has not been sent');
        
        Test.stopTest();         
        
    }
    /*
    Test Method for SendFinalRenewalEmailNotice method sendFinalEmail
    Send final email notice 7 days before Quote Start Date  
    */
    private static testMethod void sendFinalEmail() {
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testPerkinElmer.com');
        //insert u;
        
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.ShippingStreet = 'Test Street';
        acct.ShippingState = 'Test State';
        acct.ShippingCity = 'Test City';
        acct.ShippingCountry = 'US';
        acct.ShippingPostalCode = '0111';     
        insert acct;
        
        Contact con = new Contact();
        con.Email = '';
        con.LastName = 'Test LName';
        insert con;
        
        Id InformaticsOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
        List<id> oppIds = new List<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity informaticsOpp = new Opportunity();
        informaticsOpp.Name = 'Test Informatics Opp';
        informaticsOpp.RecordTypeID = InformaticsOppRT;
        informaticsOpp.Strategic_Market_INF__c = 'Life Sciences Research';
        informaticsOpp.Type = 'New Products';
        informaticsOpp.CloseDate = System.Today() + 365;
        informaticsOpp.StageName = 'Stage 1 - Create/Plan';
        informaticsOpp.Primary_Contact__c = con.Id;
        informaticsOpp.Account = acct;
        informaticsOpp.Quote_Document_Name__c = 'Q-17509-20190703-1054';
        informaticsOpp.Send_Final_Email_Notice__c = true;
        insert informaticsOpp;
        oppIds.add(informaticsOpp.Id);
        oppList.add(informaticsOpp);
        
        String quoteDocName = oppList[0].Quote_Document_Name__c + '.pdf';
        
        Attachment att = new Attachment();
        Blob b = Blob.valueOf('Test Data');
        att.Body = b;
        att.Name = quoteDocName;
        att.ParentId = oppList[0].Id;
        insert att;
        
        Attachment attList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =: oppList[0].Id AND Name =: quoteDocName];
        
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.body = attList.Body;
        fileAttachment.contenttype = attList.ContentType;
        fileAttachment.filename = attList.Name;
        fileAttachment.inline = false;       
        fileAttachments.add(fileAttachment);
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { oppList[0].Opportunity_Primary_Contact_Email_INF__c };
            message.optOutPolicy = 'FILTER';
        message.setTemplateId('00X29000000EYjA');
        message.setTargetObjectId(oppList[0].Primary_Contact__c);
        message.setWhatId(oppList[0].Id);
        message.setCcAddresses(new String[] { 'renewalemailservice@2twn2xgu3it8axgsy5qq9n93groykgejkalxz8verri6nbzp4x.29-wzueaa.cs19.apex.sandbox.salesforce.com' });
        
        Test.StartTest();
        SendFinalRenewalEmailNotice.sendFinalEmail(oppIds);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        
    }
    
    
}
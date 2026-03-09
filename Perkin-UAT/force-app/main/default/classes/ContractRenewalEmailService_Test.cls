@isTest
public class ContractRenewalEmailService_Test {
/*
Test Method for ContractRenewalEmailService method handleInboundEmail
Inbound Email Handler --> Captures customer responses
*/
    
    public static testMethod void captureInboundEmail() {
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
        informaticsOpp.Type = 'New Products';
        informaticsOpp.CloseDate = System.Today() + 365;
        informaticsOpp.StageName = 'Stage 1 - Create/Plan';
        informaticsOpp.Primary_Contact__c = con.Id;
        informaticsOpp.Account = acct;
        informaticsOpp.Quote_Document_Name__c = 'Q-17509-20190703-1054';
        
        insert informaticsOpp;
        oppIds.add(informaticsOpp.Id);
        oppList.add(informaticsOpp);
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        String subject = 'Re: Sandbox: PerkinElmer Informatics Contract Renewal Quotation - 1st Notice (' + informaticsOpp.Id + ')';
        String subjectReply = 'Re: ';
        List<String> ccAddress = new List<String>();
        ccAddress.add('TestContact1@testemail.com');
        ccAddress.add('TestContact2@testemail.com'); 
        
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();        
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        
        email.fromAddress = 'TestContact@testemail.com';
        email.htmlBody = 'Test Text Body';
        email.fromName = 'Test Name';
        email.plainTextBody = '';     
        email.subject = subject;
        email.ccAddresses = ccAddress;
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        String oppId = subject.substringBetween('(', ')');
        
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.status = '0'; // email was sent
        emailMessage.relatedToId = oppId; // related to record e.g. an opportunity
        emailMessage.fromAddress = email.fromAddress; // from address
        emailMessage.fromName = email.fromName; // from name
        emailMessage.subject = email.subject; // email subject
        emailMessage.htmlBody = email.htmlBody; // email body
        emailMessage.ccAddress = String.join(email.ccAddresses, ';');
        
        Opportunity opp = [SELECT Id, Customer_Responded__c FROM Opportunity WHERE Id =: oppId];
        
        if(emailMessage.subject.contains(subjectReply)){
            insert emailMessage; // insert  
        }
        if(emailMessage.subject.contains(subjectReply)){
            opp.Customer_Responded__c = true;
        }
        update informaticsOpp;
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        Test.StartTest();
        ContractRenewalEmailService newEmail = new ContractRenewalEmailService();
        newEmail.handleInboundEmail(email, envelope);
        Test.stopTest();
        System.assertEquals(result.success ,true);
        
    }
}
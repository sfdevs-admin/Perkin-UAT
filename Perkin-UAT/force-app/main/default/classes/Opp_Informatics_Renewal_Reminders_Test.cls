@isTest
public class Opp_Informatics_Renewal_Reminders_Test {

     /*
    Test Method for Opp_Informatics_Renewal_Reminders method sendRenewalNotice
    */
    private static testmethod void sendRenewalNoticeTest1() {
        //To Skip Triggers
        //SBQQ.TriggerControl.disable();
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testPerkinElmer.com');
        insert u;
        
        //To skip validation on Accout creation
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name Like '%C_PERM_9200_Allow_Creating_Account%'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        system.runAs(u){
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
            //second notice
            List<String> oppIds1 = new List<String>();
            List<Opportunity> oppList1 = new List<Opportunity>();

            Opportunity informaticsOpp1 = new Opportunity();
            informaticsOpp1.Name = 'Test Informatics Opp1';
            informaticsOpp1.RecordTypeID = InformaticsOppRT;
            informaticsOpp1.Strategic_Market_INF__c = 'Life Sciences Research';
            informaticsOpp1.Type = 'New Products';
            informaticsOpp1.CloseDate = System.Today() + 365;
            informaticsOpp1.StageName = 'Stage 5 - Negotiation';
            informaticsOpp1.Application__c ='Chemicals & Mining';
            informaticsOpp1.Application_Market__c='Applied';
            informaticsOpp1.Application_Segment__c='Informatics';
            informaticsOpp1.Primary_Contact__c = con.Id;
            informaticsOpp1.Account = acct;
            informaticsOpp1.Quote_Document_Name__c = 'Q-17509-20190703-1054';
            informaticsOpp1.First_Email_Sent_Date__c= System.Today()-7;
            informaticsOpp1.Send_2nd_Email_Notice__c= True;
            informaticsOpp1.Customer_Responded__c = False;
            informaticsOpp1.OwnerId = u.Id;
            insert informaticsOpp1;
            //oppIds1.add(informaticsOpp1.fxRenewalAction__c);
            oppList1.add(informaticsOpp1);
            System.debug('----Opportunity1Id--'+informaticsOpp1.Id);
            
            String fxRenewalAction1 = 'Send 2-'+informaticsOpp1.Id;
            oppIds1.add(fxRenewalAction1);
            
            /*SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
            quote1.SBQQ__Primary__c =true;
            quote1.Quote_Name__c='Testquote1';
            quote1.SBQQ__StartDate__c=System.today()+25;
            quote1.SBQQ__Opportunity2__c=informaticsOpp1.Id;
            quote1.SBQQ__Account__c=acct.Id;
            quote1.SBQQ__PricebookId__c = Test.getStandardPricebookId();
            quote1.currencyISOCode ='USD';
            quote1.SBQQ__BillingCity__c = 'Dallas';
            quote1.SBQQ__BillingCountry__c = 'US';
            quote1.SBQQ__BillingName__c = 'TESTER';
            quote1.SBQQ__BillingPostalCode__c = '75226';
            quote1.SBQQ__BillingState__c =  'TX';
            quote1.SBQQ__BillingStreet__c = '123 Test Road';
            quote1.SBQQ__ShippingCity__c = 'Dallas';
            quote1.SBQQ__ShippingCountry__c = 'US';
            quote1.SBQQ__ShippingName__c = 'TESTER';
            quote1.SBQQ__ShippingPostalCode__c =  '75226';
            quote1.SBQQ__ShippingState__c =  'TX';
            quote1.SBQQ__ShippingStreet__c ='123 Test Road';
            quote1.SBQQ__BillingFrequency__c = 'Annual';
            insert quote1;
            System.debug('----QuoteId1---'+quote1.Id);*/
           
            System.debug('------------fxRecordTypeDevName__c----'+informaticsOpp1.fxRecordTypeDevName__c+'---StageNumber__c---'+informaticsOpp1.StageNumber__c+'--First_Email_Sent_Date__c--'+informaticsOpp1.First_Email_Sent_Date__c+'----Send_2nd_Email_Notice__c---'+informaticsOpp1.Send_2nd_Email_Notice__c+'-----Second Email Send Date----'+informaticsOpp1.Second_Email_Sent_Date__c+'-----Quote_StartDate__c----'/*+informaticsOpp1.Quote_StartDate__c+'----fxRenewalAction__c--'+informaticsOpp1.fxRenewalAction__c*/);
         
            
            
            
            String quoteDocName = oppList1[0].Quote_Document_Name__c + '.pdf';
           
            Attachment att = new Attachment();
            Blob b = Blob.valueOf('Test Data');
            att.Body = b;
            att.Name = quoteDocName;
            att.ParentId = oppList1[0].Id;
            insert att;
            

            Attachment attList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =: oppList1[0].Id AND Name =: quoteDocName];
            OrgWideEmailAddress[] renewalNoticeSender = [select Id from OrgWideEmailAddress where DisplayName = 'Informatics Order'];
            
            String[] emailIds2 = new String[]{};
            emailIds2.add(System.Label.RenewalEmailService);
            emailIds2.add(oppList1[0].owner.Email);

            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.body = attList.Body;
            fileAttachment.contenttype = attList.ContentType;
            fileAttachment.filename = attList.Name;
            fileAttachment.inline = false;       
            fileAttachments.add(fileAttachment);
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(renewalNoticeSender.get(0).Id);
            message.toAddresses = new String[] { oppList1[0].Opportunity_Primary_Contact_Email_INF__c };
            message.optOutPolicy = 'FILTER';
            message.setTemplateId('00X29000000EYj5');
            message.setTargetObjectId(oppList1[0].Primary_Contact__c);
            message.setWhatId(oppList1[0].Id);
            message.setCcAddresses(emailIds2);
            
            Test.StartTest();
            Opp_Informatics_Renewal_Reminders.sendRenewalNotice(oppIds1); //To cover second emailnotice
            Test.StopTest();

            
            //System.assertEquals(1, invocations, 'An email has not been sent'); 
            
        }
    }
    
    private static testmethod void sendRenewalNoticeTest2() {
        //To Skip Triggers
        //SBQQ.TriggerControl.disable();
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testPerkinElmer.com');
        insert u;
        
        //To skip validation on Accout creation
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name Like '%C_PERM_9200_Allow_Creating_Account%'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        system.runAs(u){
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

            //final notice
            List<String> oppIds2 = new List<String>();
            List<Opportunity> oppList2 = new List<Opportunity>();
            Opportunity informaticsOpp2 = new Opportunity();
            informaticsOpp2.Name = 'Test Informatics Opp2';
            informaticsOpp2.RecordTypeID = InformaticsOppRT;
            informaticsOpp2.Strategic_Market_INF__c = 'Life Sciences Research';
            informaticsOpp2.Type = 'New Products';
            informaticsOpp2.CloseDate = System.Today() + 365;
            informaticsOpp2.StageName = 'Stage 5 - Negotiation';
            informaticsOpp2.Application__c ='Chemicals & Mining';
            informaticsOpp2.Application_Market__c='Applied';
            informaticsOpp2.Application_Segment__c='Informatics';
            informaticsOpp2.Primary_Contact__c = con.Id;
            informaticsOpp2.Account = acct;
            informaticsOpp2.Quote_Document_Name__c = 'Q-17509-20190703-1054';
            informaticsOpp2.First_Email_Sent_Date__c= System.Today()-30;
            informaticsOpp2.Send_2nd_Email_Notice__c= True;
            informaticsOpp2.Second_Email_Sent_Date__c =  System.Today()-10;
            informaticsOpp2.Send_Final_Email_Notice__c = True;
            informaticsOpp2.OwnerId = u.Id;
            
            
            insert informaticsOpp2;
            //oppIds2.add(informaticsOpp2.fxRenewalAction__c);
            oppList2.add(informaticsOpp2);
            String fxRenewalAction2 = 'Send 3-'+informaticsOpp2.Id;
            oppIds2.add(fxRenewalAction2);
        
            
            
            /*SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
            quote2.SBQQ__Primary__c =true;
            quote2.Quote_Name__c='TestQuote2';
            quote2.SBQQ__StartDate__c=System.today()+6;
            quote2.SBQQ__Opportunity2__c=informaticsOpp2.Id;
            quote2.SBQQ__Account__c=acct.Id;
            quote2.SBQQ__PricebookId__c = Test.getStandardPricebookId();
            quote2.currencyISOCode ='USD';
            quote2.SBQQ__BillingCity__c = 'Dallas';
            quote2.SBQQ__BillingCountry__c = 'US';
            quote2.SBQQ__BillingName__c = 'TESTER';
            quote2.SBQQ__BillingPostalCode__c = '75226';
            quote2.SBQQ__BillingState__c =  'TX';
            quote2.SBQQ__BillingStreet__c = '123 Test Road';
            quote2.SBQQ__ShippingCity__c = 'Dallas';
            quote2.SBQQ__ShippingCountry__c = 'US';
            quote2.SBQQ__ShippingName__c = 'TESTER';
            quote2.SBQQ__ShippingPostalCode__c =  '75226';
            quote2.SBQQ__ShippingState__c =  'TX';
            quote2.SBQQ__ShippingStreet__c ='123 Test Road';
            quote2.SBQQ__BillingFrequency__c = 'Annual';
            insert quote2;*/
                    
            
            //closed opportunity
            List<String> oppIds3 = new List<String>();
            List<Opportunity> oppList3 = new List<Opportunity>();
            Opportunity informaticsOpp3 = new Opportunity();
            informaticsOpp3.Name = 'Test Informatics Opp3';
            informaticsOpp3.RecordTypeID = InformaticsOppRT;
            informaticsOpp3.Strategic_Market_INF__c = 'Life Sciences Research';
            informaticsOpp3.Type = 'New Products';
            informaticsOpp3.CloseDate = System.Today() + 365;
            informaticsOpp3.StageName = 'Stage 5 - Negotiation';
            informaticsOpp3.Application__c ='Chemicals & Mining';
            informaticsOpp3.Application_Market__c='Applied';
            informaticsOpp3.Application_Segment__c='Informatics';
            informaticsOpp3.Primary_Contact__c = con.Id;
            informaticsOpp3.Account = acct;
            informaticsOpp3.Quote_Document_Name__c = 'Q-17509-20190703-1054';
            informaticsOpp3.First_Email_Sent_Date__c= System.Today()-30;
            informaticsOpp3.Send_2nd_Email_Notice__c= True;
            informaticsOpp3.Second_Email_Sent_Date__c =  System.Today()-10;
            informaticsOpp3.Send_Final_Email_Notice__c = True;
            informaticsOpp3.Third_Email_Sent_Date__c = System.Today()-8;
            informaticsOpp3.OwnerId = u.Id;
                      
            insert informaticsOpp3;
            
            //oppIds3.add(informaticsOpp3.fxRenewalAction__c);
            oppList3.add(informaticsOpp3);
            String fxRenewalAction3 = 'Lost-'+informaticsOpp2.Id;
            oppIds3.add(fxRenewalAction3);

            /*SBQQ__Quote__c quote3 = new SBQQ__Quote__c();
            quote3.SBQQ__Primary__c =true;
            quote3.Quote_Name__c='Testquote3';
            quote3.SBQQ__StartDate__c=System.today()-7;
            quote3.SBQQ__Opportunity2__c=informaticsOpp3.Id;
            quote3.SBQQ__Account__c=acct.Id;
            quote3.SBQQ__PricebookId__c = Test.getStandardPricebookId();
            quote3.currencyISOCode ='USD';
            quote3.SBQQ__BillingCity__c = 'Dallas';
            quote3.SBQQ__BillingCountry__c = 'US';
            quote3.SBQQ__BillingName__c = 'TESTER';
            quote3.SBQQ__BillingPostalCode__c = '75226';
            quote3.SBQQ__BillingState__c =  'TX';
            quote3.SBQQ__BillingStreet__c = '123 Test Road';
            quote3.SBQQ__ShippingCity__c = 'Dallas';
            quote3.SBQQ__ShippingCountry__c = 'US';
            quote3.SBQQ__ShippingName__c = 'TESTER';
            quote3.SBQQ__ShippingPostalCode__c =  '75226';
            quote3.SBQQ__ShippingState__c =  'TX';
            quote3.SBQQ__ShippingStreet__c ='123 Test Road';
            quote3.SBQQ__BillingFrequency__c = 'Annual';
            insert quote3;*/
  
            
            String quoteDocName = oppList2[0].Quote_Document_Name__c + '.pdf';
           
            Attachment att = new Attachment();
            Blob b = Blob.valueOf('Test Data');
            att.Body = b;
            att.Name = quoteDocName;
            att.ParentId = oppList2[0].Id;
            insert att;
            
            String[] emailIds = new String[]{};
            emailIds.add(System.Label.RenewalEmailService);
            emailIds.add(oppList2[0].owner.Email);
            
            Attachment attList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =: oppList2[0].Id AND Name =: quoteDocName];
            OrgWideEmailAddress[] renewalNoticeSender = [select Id from OrgWideEmailAddress where DisplayName = 'Informatics Order'];

            
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.body = attList.Body;
            fileAttachment.contenttype = attList.ContentType;
            fileAttachment.filename = attList.Name;
            fileAttachment.inline = false;       
            fileAttachments.add(fileAttachment);
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(renewalNoticeSender.get(0).Id);
            message.toAddresses = new String[] { oppList2[0].Opportunity_Primary_Contact_Email_INF__c };
            message.optOutPolicy = 'FILTER';
            message.setTemplateId('00X29000000EYj5');
            message.setTargetObjectId(oppList2[0].Primary_Contact__c);
            message.setWhatId(oppList2[0].Id);
            message.setCcAddresses(emailIds);
            
            Test.StartTest();
            Opp_Informatics_Renewal_Reminders.sendRenewalNotice(oppIds2); //To cover third emailnotice
            Test.StopTest();

            
        }
    }
    
        private static testmethod void sendRenewalNoticeTest3() {
        //To Skip Triggers
        //SBQQ.TriggerControl.disable();
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testPerkinElmer.com');
        insert u;
        
        //To skip validation on Accout creation
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name Like '%C_PERM_9200_Allow_Creating_Account%'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        system.runAs(u){
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
                    
            
            //closed opportunity
            List<String> oppIds3 = new List<String>();
            List<Opportunity> oppList3 = new List<Opportunity>();
            Opportunity informaticsOpp3 = new Opportunity();
            informaticsOpp3.Name = 'Test Informatics Opp3';
            informaticsOpp3.RecordTypeID = InformaticsOppRT;
            informaticsOpp3.Strategic_Market_INF__c = 'Life Sciences Research';
            informaticsOpp3.Type = 'New Products';
            informaticsOpp3.CloseDate = System.Today() + 365;
            informaticsOpp3.StageName = 'Stage 5 - Negotiation';
            informaticsOpp3.Application__c ='Chemicals & Mining';
            informaticsOpp3.Application_Market__c='Applied';
            informaticsOpp3.Application_Segment__c='Informatics';
            informaticsOpp3.Primary_Contact__c = con.Id;
            informaticsOpp3.Account = acct;
            informaticsOpp3.Quote_Document_Name__c = 'Q-17509-20190703-1054';
            informaticsOpp3.First_Email_Sent_Date__c= System.Today()-30;
            informaticsOpp3.Send_2nd_Email_Notice__c= True;
            informaticsOpp3.Second_Email_Sent_Date__c =  System.Today()-10;
            informaticsOpp3.Send_Final_Email_Notice__c = True;
            informaticsOpp3.Third_Email_Sent_Date__c = System.Today()-8;
                      
            insert informaticsOpp3;
            
            //oppIds3.add(informaticsOpp3.fxRenewalAction__c);
            oppList3.add(informaticsOpp3);
            String fxRenewalAction3 = 'Lost-'+informaticsOpp3.Id;
            oppIds3.add(fxRenewalAction3);

            /*SBQQ__Quote__c quote3 = new SBQQ__Quote__c();
            quote3.SBQQ__Primary__c =true;
            quote3.Quote_Name__c='Testquote3';
            quote3.SBQQ__StartDate__c=System.today()-7;
            quote3.SBQQ__Opportunity2__c=informaticsOpp3.Id;
            quote3.SBQQ__Account__c=acct.Id;
            quote3.SBQQ__PricebookId__c = Test.getStandardPricebookId();
            quote3.currencyISOCode ='USD';
            quote3.SBQQ__BillingCity__c = 'Dallas';
            quote3.SBQQ__BillingCountry__c = 'US';
            quote3.SBQQ__BillingName__c = 'TESTER';
            quote3.SBQQ__BillingPostalCode__c = '75226';
            quote3.SBQQ__BillingState__c =  'TX';
            quote3.SBQQ__BillingStreet__c = '123 Test Road';
            quote3.SBQQ__ShippingCity__c = 'Dallas';
            quote3.SBQQ__ShippingCountry__c = 'US';
            quote3.SBQQ__ShippingName__c = 'TESTER';
            quote3.SBQQ__ShippingPostalCode__c =  '75226';
            quote3.SBQQ__ShippingState__c =  'TX';
            quote3.SBQQ__ShippingStreet__c ='123 Test Road';
            quote3.SBQQ__BillingFrequency__c = 'Annual';
            insert quote3;*/
          
            Test.StartTest();
            Opp_Informatics_Renewal_Reminders.sendRenewalNotice(oppIds3); //To cover closed opportunity
            Test.StopTest();

            
        }
    }
    
    
}
@isTest
public class Batch_ContractRenewalNoticeFails_Test {
    public static testmethod void batchRenewalFailTest(){
        Id INFORMATICS_RECORDTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Informatics').getRecordTypeId();
        
        Account acc = new Account();
        acc.name = 'Test Account';
        acc.ShippingCity = 'test city';
        acc.ShippingCountry = 'US';
        acc.ShippingPostalCode = '12345678';
        acc.ShippingState = 'AX';
        acc.ShippingStreet = 'Test Street';
        insert acc;
        
        Opportunity opprt = new Opportunity(Name='TestOpprt',AccountId=acc.id,Strategic_Market_INF__c='Life Sciences Research', recordtypeId = INFORMATICS_RECORDTYPEID, Application__c = 'Materials', Application_Segment__c = 'Informatics', Application_Market__c = 'Applied'
                                            ,Type='New Products',CloseDate=System.today() + 120,StageName='Stage 5 - Negotiation',Pricebook2Id = Test.getStandardPricebookId(), currencyISOCode ='USD',CountofRenewalProducts__c = 1,First_Email_Sent_Date__c= system.today().addDays(-45), Second_Email_Sent_Date__c= system.today(), Third_Email_Sent_Date__c=system.today());
        insert opprt;
        
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        EmailMessage emailMessage = new EmailMessage(); 
        emailMessage.status = '3'; // email was sent 
        emailMessage.fromName = 'Magulan Duraipandian'; // from name 
        emailMessage.subject = 'PerkinElmer Informatics Contract Renewal Quotation - 2nd Notice'; // email subject 
        emailMessage.htmlBody = '<html><body><b>Hello</b></body></html>'; // email body 
        emailMessage.RelatedToId = opprt.Id; 
        emailMessages.add(emailMessage); // insert 
        
        EmailMessage emailMessage2 = new EmailMessage(); 
        emailMessage2.status = '3'; // email was sent 
        emailMessage2.fromName = 'Magulan Duraipandian'; // from name 
        emailMessage2.subject = 'PerkinElmer Informatics Contract Renewal Quotation - Final Notice'; // email subject 
        emailMessage2.htmlBody = '<html><body><b>Hello</b></body></html>'; // email body 
        emailMessage2.RelatedToId = opprt.Id; 
        emailMessages.add(emailMessage2);
	
        if(!emailMessages.isEmpty()){
            insert emailMessages;
        }   
        
        Batch_ContractRenewalNoticeFails testBatch = new Batch_ContractRenewalNoticeFails();
		database.executeBatch(testBatch);
    }
    
    public static testmethod void testAutoActivateOrderSchedular(){
        Test.startTest();
            Schedule_ContractRenewalNoticeFails schedularClass = new Schedule_ContractRenewalNoticeFails();
            String schedularTime = '0 0 0,2,4,6,8,10,12,14,16,18,20,22 * * ? * *'; 
            system.schedule('Auto Activate Order1', schedularTime, schedularClass); 
        Test.stopTest();
    }
}
/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ITSFDC-INC0309630
 
  *
  * 2. Description - Used to send 2nd and Final Email Notice Email notice and closed lost .Calls from mass action
  *
  *
  *
  * 3. Objects referenced
  *    -Attachment
  *    -EmailTemplate
  *    -Opportunity
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  * 
  * 5. Dependant Class(es):
  *  
  *
  * 6. Test Class Name: Opp_Informatics_Renewal_Reminders_Test
  *
  * 7. Is @Invocable (Yes or No):  Yes
  *
  * 8. Author Name(s): 
  *    - (Lister) Gowsikkannan & Updated Date(2022.08.12)
  *    - (Lister) Gowsikkannan & Updated Date(2022.08.15)
  *    - (Lister) Gowsikkannan & Updated Date(2022.10.25)

  *
*************************************************************/ 


global without sharing class Opp_Informatics_Renewal_Reminders{


   @InvocableMethod(label='INF Send Renewal Reminder' description='Batch renewal Email send parameter as List<String> as fxRenewalAction__c field' category='Opportunity')
    
    //pass input as List<String> because invocable only support List

    public static void sendRenewalNotice(List<String> oppIdActionList){
        
            String oppIdAction = oppIdActionList[0];
        System.debug('oppIdAction'+oppIdAction);
            String delimiter = '-';
            String Action = oppIdAction.substringBefore(delimiter);
            String oppId = oppIdAction.substringAfter(delimiter);
        
            //geting opportunity to get. Here I added extra condition Name Like 'GKTest' Plee create record with GKTest to test. verify primary contact's Email address.
            List<Opportunity> opp = new List<Opportunity> ([SELECT Id,Name,First_Email_Sent_Date__c,Send_2nd_Email_Notice__c,Send_Final_Email_Notice__c,Customer_Responded__c,StageName,fxRecordTypeDevName__c,Second_Email_Sent_Date__c,Opportunity_Primary_Contact_Email_INF__c, Quote_Document_ID__c, Quote_Document_Name__c, Primary_Contact__c/*,Quote_StartDate__c*/,Third_Email_Sent_Date__c,owner.email,ownerId FROM Opportunity WHERE Id = :oppId LIMIT 1]);
        
        //To add renewalService Email in CC of mail.
        String[] emailIds = new String[]{};
        emailIds.add(System.Label.RenewalEmailService);
        emailIds.add(opp[0].owner.Email);

        List<EmailTemplate> EmailTemplateRec = new List<EmailTemplate>();
        //only for Email notice
        system.debug('----Action----'+Action);
        if(Action == 'Send 2' || Action == 'Send 3')
        {   
            
            if(Action == 'Send 2'){
                system.debug('----Send 2----'+Action);
                opp[0].Second_Email_Sent_Date__c = system.today();
               List<EmailTemplate> EmailTemplateRecSecond = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName ='Informatics_Contract_Renewal_Quotation_Template_2nd_Notice' LIMIT 1];
               EmailTemplateRec.add(EmailTemplateRecSecond[0]);  
            }
            
            if(Action == 'Send 3'){
                system.debug('----Send 3----'+Action);
                opp[0].Third_Email_Sent_Date__c = system.today();
                List<EmailTemplate> EmailTemplateRecThird = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName ='Informatics_Contract_Renewal_Quotation_Template_3rd_Notice' LIMIT 1];
                EmailTemplateRec.add(EmailTemplateRecThird[0]);                
            }
            
            //geting right Quote Document related to opportunity
            String QuoteDocumentName = opp[0].Quote_Document_Name__c+'.pdf';
                        
            List<Attachment> att = new List<Attachment>([SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =:oppId AND Name = :QuoteDocumentName ORDER By Createddate Desc LIMIT 1]);     
            system.debug('----Attachemnt---'+att);
                List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
                List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
                Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
                fileAttachment.body = att[0].Body;
                fileAttachment.contenttype = att[0].ContentType;
                fileAttachment.filename = att[0].Name;
                fileAttachment.inline = false;
                fileAttachments.add(fileAttachment);
                //get from address from Organization-Wide Addresses
                OrgWideEmailAddress[] renewalNoticeSender = [select Id from OrgWideEmailAddress where DisplayName = 'Informatics Order'];

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setOrgWideEmailAddressId(renewalNoticeSender.get(0).Id);
                message.toAddresses = new String[] {opp[0].Opportunity_Primary_Contact_Email_INF__c};
                message.optOutPolicy = 'FILTER';
                message.setTemplateId(EmailTemplateRec[0].Id);
                message.setTargetObjectId(opp[0].Primary_Contact__c);
                message.setWhatId(opp[0].Id);
                message.setFileAttachments(fileAttachments);
                message.setCcAddresses(emailIds); 
                messageList.add(message);
            
            //to send Email alert for second or final notice
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messageList, false);
                System.debug('----EmailResult--');
            
            //Capture Error log in SFDC_LOG__c
                     for (Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Send email message failed.');
                        List<SFDC_LOG__c> errorLogList = new List<SFDC_LOG__c>();
                        for (Messaging.SendEmailError error : result.getErrors()) {
                            SFDC_LOG__c errorLog = new SFDC_LOG__c ();
                            errorLog.Source_Type__c = 'APEX' ;
                            errorLog.Message_Long__c = error.getMessage();
                            errorLog.Log_Type__c = 'CPQ Logs';
                            errorLog.Running_User__c = userinfo.getUserId();
                            errorLog.Source_Name__c = 'Contract Renewal Reminder' ;
                            errorLogList.add(errorLog);
                                                                                                                
                            System.debug(error.getFields());
                            System.debug(error.getMessage());
                            System.debug(error.getStatusCode());
                            System.debug(error.getTargetObjectId());
                        }
                        if(!errorLogList.isEmpty() )
                            insert errorLogList;
                    }
                    else {
                        System.debug('The email was sent successfully.');
                    }
                }
            //Set sent date
            update opp[0];
        }
        if(Action=='Lost'){
                opp[0].Closed_Reason__c = 'No response';
                opp[0].Reason_Lost_Detail__c = 'No Response';
                opp[0].StageName = 'Closed Lost';
                opp[0].CloseDate = system.today();
                Update opp[0];
        }
        
        
        
        
        
   }
public class Requests {
  @InvocableVariable(label='Records for Opportunity' description='Input Opportunity' required=true)
  public List<String> inputCollection;
  }

}
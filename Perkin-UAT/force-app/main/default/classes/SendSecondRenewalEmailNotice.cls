public class SendSecondRenewalEmailNotice {
    
    /* This method is used to send the second email notice as a reminder to the renwal opportunity's primary contact
    ** for contract renewal.
    */
    @InvocableMethod 
    public static void sendSecondEmail(List<Id> secondEmailOppIds) {  
        try{
            Map<Id, Id> opportunityIdByContactId = new Map<Id, Id>();        
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> notified2ndNoticeOpp = new Set<Id>();
            
            List<Opportunity> oppList = [SELECT Id, Opportunity_Primary_Contact_Email_INF__c, Quote_Document_ID__c,  Owner.Email, Quote_Document_Name__c, Primary_Contact__c, Send_Final_Email_Notice__c FROM Opportunity WHERE Id IN : secondEmailOppIds];
            // Iterating the opportunity and creating a map which holds opportunity record id by opportunity's primary contact id.
            for(Opportunity oppRec: oppList){
                opportunityIdByContactId.put(oppRec.Primary_Contact__c, oppRec.Id);
            }
            
            //Iterating over the opportunity task and creating a set which holds 2nd notice sent email activity record id.
            For(Task taskRec: [SELECT Id, Subject, WhatId from task where WhatId IN : secondEmailOppIds AND subject like '%2nd Notice%']){
                notified2ndNoticeOpp.add(taskRec.WhatId);
            }
            String quoteDocName = oppList[0].Quote_Document_Name__c + '.pdf';
            
            Attachment att = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =: oppList[0].Id AND Name =: quoteDocName LIMIT 1];
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.body = att.Body;
            fileAttachment.contenttype = att.ContentType;
            fileAttachment.filename = att.Name;
            fileAttachment.inline = false;
            fileAttachments.add(fileAttachment);
            
            String emailTemplateName = 'Informatics_Contract_Renewal_Quotation_Template_2nd_Notice_Custom';

            String[] emailIds = new String[]{};
            emailIds.add(System.Label.RenewalEmailService);
            
            EmailTemplate emailTemplate = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = :emailTemplateName LIMIT 1];
            Map<Messaging.SingleEmailMessage, Opportunity> msgToTaskMap = new Map<Messaging.SingleEmailMessage, Opportunity>();
            
            //Iterating the current opportunity and if second notice is not sent before. It will create email message to send the 
            // second notice.
            for (Opportunity opportunity : oppList) {
                if(!notified2ndNoticeOpp.contains(opportunity.Id)){
                    emailIds.add(opportunity.Owner.Email);
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.toAddresses = new String[] {oppList[0].Opportunity_Primary_Contact_Email_INF__c};
                    message.optOutPolicy = 'FILTER';
                    message.setTemplateId(emailTemplate.Id);
                    message.setTargetObjectId(oppList[0].Primary_Contact__c);
                    message.setWhatId(oppList[0].Id);
                    message.setFileAttachments(fileAttachments);
                    message.setCcAddresses(emailIds);
                    msgToTaskMap.put(message, opportunity);
                }
            }
            
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>(msgToTaskMap.keySet());
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages, false); // Set allOrNothing parameter to true to allow delivery of emails without errors.
            system.debug('@@results= '+results);
            
            //Calling another method which is used to reschedulepending Automation.
            if(oppList[0].Send_Final_Email_Notice__c){
                SendSecondRenewalEmailNotice.reschedulePendingAutomation(oppList[0].Id);
            }
            
            Map<String, String> errorMessageById = new Map<String, String>();
            List<SFDC_LOG__c> logsToInsert = new List<SFDC_LOG__c>();

            // Iterating over the send email results and creating the SFDC Log for the failed email notice.
            for (Messaging.SendEmailResult result : results) {
                System.debug('Send email message failed.'+result.isSuccess());
                if (!result.isSuccess()) {
                    System.debug('Send email message failed.');
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug(error.getFields());
                        System.debug(error.getMessage());
                        System.debug(error.getStatusCode());
                        System.debug(error.getTargetObjectId());
                        // Creating debug logs.
                        SFDC_LOG__c newLog = new SFDC_LOG__c();
                        newLog.Log_Type__c = 'CPQ Logs';
                        newLog.Message_Long__c = 'Record ID: '+error.getTargetObjectId() +'</br> '+error.getMessage();
                        newLog.Running_User__c = UserInfo.getUserName();
                        newLog.Source_Name__c = 'Renewal 2nd Notice failed';
                        newLog.Source_Type__c = 'APEX';
                        logsToInsert.add(newLog);
                        errorMessageById.put(error.getTargetObjectId(), error.getMessage());
                    }
                }
                else {
                    System.debug('The email was sent successfully.');
                }
            }
            
            if(logsToInsert.isEmpty()){
                insert logsToInsert;
            } 
            
            //Here we are sending the email to IT team if any email notice is not triggered.
            if(!errorMessageById.isEmpty()){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {'jakin.p@listertechnologies.com', 'divya.v@listertechnologies.com'};
                    String emailBody = 'Hi Team</br></br>';
                emailBody += 'Please review the 2nd notice failed results.</br></br>';
                emailBody += '<table><thead><tr><th>Opportunity Id</th><th>Error Message</th></tr></thead>';
                emailBody += '<tbody>';
                for(String oppId: errorMessageById.keySet()){
                    emailBody +='<tr><td>'+opportunityIdByContactId.get(oppId)+'</td><td>'+errorMessageById.get(oppId)+'</td></tr>';
                }
                emailBody += '</tbody></table>';
                emailBody += '</br></br>';
                emailBody += 'Thanks </br>';
                mail.setToAddresses(toAddresses);
                mail.setSubject('Renewal Batch Second Notice Failed Records.');
                mail.setHtmlBody(emailBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            }
        } catch(exception e){

            system.debug('Error= '+e.getMessage()+' '+e.getLineNumber());
            SFDC_LOG__c newLog = new SFDC_LOG__c();
            newLog.Log_Type__c = 'CPQ Logs';
            newLog.Message_Long__c = 'RecordId: '+secondEmailOppIds[0]+' Error: '+e.getMessage() +' at line: '+e.getLineNumber();
            newLog.Running_User__c = UserInfo.getUserName();
            newLog.Source_Name__c = 'Renewal 2nd Notice failed';
            newLog.Source_Type__c = 'APEX';
            insert newLog;
        }
    }

    /* This method is used to reschedule the pending automation, Which is required for contract renewal process. */
    @future
    Public static void reschedulePendingAutomation(String opportunityRecordId){
        Opportunity opportunityRecord = [Select Id, Send_Final_Email_Notice__c, First_Email_Sent_Date__c /*, Quote_StartDate__c , SBQQ__PrimaryQuote__r.Earliest_Start_Date__c */ From Opportunity Where Id=: opportunityRecordId];
        
        Date firstEmailSentDate = opportunityRecord.First_Email_Sent_Date__c;
        
        opportunityRecord.Send_Final_Email_Notice__c = false;
        /*if(opportunityRecord.Quote_StartDate__c != opportunityRecord.SBQQ__PrimaryQuote__r.Earliest_Start_Date__c) */ {
            opportunityRecord.First_Email_Sent_Date__c = null;
        }        
        update opportunityRecord;

        /*if(opportunityRecord.Quote_StartDate__c != opportunityRecord.SBQQ__PrimaryQuote__r.Earliest_Start_Date__c)*/{
            opportunityRecord.First_Email_Sent_Date__c = firstEmailSentDate;
            update opportunityRecord;
        }
        
        opportunityRecord.Send_Final_Email_Notice__c = true;
        update opportunityRecord;
    }
}
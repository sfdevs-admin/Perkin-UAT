/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ITSFDC-4688
  *    - ITSFDC-5091
  *
  * 2. Description - This Class is used to send the 1st notification to opportunity's primary contact
  *                 to give reminder for contract renewal.
  *
  * 3. Objects referenced
  *    -Opportunity
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 6. Test Class Name: Send1stNotificationController_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    Created By Jakin (12/14/2021)
*************************************************************/ 

public class Send1stNotificationController {

    /* This method is validating the opportunity whether it applicable to send the 1st notice for renewal or not if it's not applicable it will show
    ** the error message to user
    */
    @AuraEnabled
    public static string validateOpportunity(String opportunityId){
        
        String errorMessage = '';
        Opportunity opp = [SELECT Id, Quote_Document_ID__c,PrimaryContactID__c, Owner.Email, StageName, Type From opportunity WHERE ID=: opportunityId];
        List<EmailTemplate> emailteTemplates = [SELECT Id from EmailTemplate WHERE Developername='Informatics_Contract_Renewal_Quotation_Template_1st_Notice_Custom'];
        
        // Checking if opportunity type is not renewal and stage is not Stage 5 then validation message display to end user and not allow to send the 1st notice.
        if(opp.Type != 'Renewal' || opp.StageName != 'Stage 5 - Negotiation'){
            return 'Opportunity type should be Renewal and it must be in Stage 5 - Negotiation stage.';
        }
        
        // Checking if opportunity does not have primary contact, Validation message display to end user and not allow to send the 1st notice.
        if(String.isBlank(opp.PrimaryContactID__c)){
        	return 'Please select the primary contact to send the 1st notice.';  
        }
        
        // Checking if quote document is not generated then validation message display to end user and not allow to send the 1st notice.
        if(String.isBlank(opp.Quote_Document_ID__c)){
            return 'Quote Document is not generated, Please generate Quote doucument to send 1st notice.';
        }
        
        // If 1st notice is already sent, Sales user not able to send the 1st notice again.
        List<Task> tasks = [SELECT Id, Subject, WhatId from task where WhatId=: opportunityId AND subject like '%1st Notice%'];
        if(tasks != null && tasks.size() > 0){
            return '1st notice already sent to the customer kindly wait for the response.';
        }

        string emailIds = System.Label.RenewalEmailService;
        emailIds += ','+opp.Owner.Email;

        // Preparing the URL to send the 1st notice with prepopulate values.
        String url ='/_ui/core/email/author/EmailAuthor?p3_lkid='+opportunityId;
        url +='&template_id='+emailteTemplates[0].Id;
        url +='&p4='+emailIds;
        if(opp.PrimaryContactID__c != null){
            url +='&p2_lkid='+opp.PrimaryContactID__c;
        }
        if(opp.Quote_Document_ID__c != null){
         	url +='&doc_id='+opp.Quote_Document_ID__c;   
        }        
        url +='&retURL='+opportunityId;
        return url;
    }
}
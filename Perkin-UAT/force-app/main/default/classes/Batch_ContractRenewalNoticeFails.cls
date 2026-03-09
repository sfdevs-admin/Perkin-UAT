public class Batch_ContractRenewalNoticeFails implements Database.Batchable<SObject>, Database.stateful{
    
    public Database.QueryLocator  start(Database.BatchableContext bc) {
        //Getting all the orders which are created today
        String query = 'Select Id, INF_Contains_second_notice__c, INF_Contains_final_notice__c  From Opportunity WHERE Opportunity.RecordType.DeveloperName = \'Informatics\' AND Opportunity.StageName = \'Stage 5 - Negotiation\' AND First_Email_Sent_Date__c != null AND (INF_Contains_second_notice__c = false OR INF_Contains_final_notice__c =false) AND (Second_Email_Sent_Date__c = today OR Second_Email_Sent_Date__c = Yesterday OR Third_Email_Sent_Date__c = today OR Third_Email_Sent_Date__c = Yesterday)';
        system.debug('@@query= '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        system.debug('@@opportunities= '+opportunities.size());
        List<Opportunity> opportunityToUpdate = new List<Opportunity>();
        Map<Id, Boolean> secondNoticeFailedById = new Map<Id, Boolean>();
        Map<Id, Boolean> finalNoticeFailedById = new Map<Id, Boolean>();
        For(EmailMessage emailMessageRec: [SELECT Id, RelatedToId, Subject From EmailMessage Where RelatedToId IN :opportunities AND Subject like '%Contract Renewal Quotation%' ]){
            if(emailMessageRec.Subject.contains('2nd Notice')){
                secondNoticeFailedById.put(emailMessageRec.RelatedToId, true);
            } else if(emailMessageRec.Subject.contains('Final Notice')){
                finalNoticeFailedById.put(emailMessageRec.RelatedToId, true);
            } 
        }
        
        for(Opportunity oppotunityRec: opportunities){
            Boolean isAdded = false;
            if(secondNoticeFailedById.get(oppotunityRec.Id) != null){
                oppotunityRec.INF_Contains_second_notice__c = secondNoticeFailedById.get(oppotunityRec.Id);
                opportunityToUpdate.add(oppotunityRec);
                isAdded =true;
            }
            
            if(finalNoticeFailedById.get(oppotunityRec.Id) != null){
                oppotunityRec.INF_Contains_final_notice__c = finalNoticeFailedById.get(oppotunityRec.Id);
                if(!isAdded){
                    opportunityToUpdate.add(oppotunityRec);
                }
            }            
        }

        if(!opportunityToUpdate.isEmpty()){
            Database.SaveResult[] results =  Database.update(opportunityToUpdate, false);
            for(Database.SaveResult sr : results){
                if (!sr.isSuccess() || test.isRunningTest()) {
                    List<SFDC_LOG__c> logsToInsert= new List<SFDC_LOG__c>();
                    for(Database.Error err : sr.getErrors()) {
                        system.debug('@@error= '+sr.getErrors());
                        SFDC_LOG__c newLog = new SFDC_LOG__c();
                        newLog.Log_Type__c = 'CPQ Logs';
                        newLog.Message_Long__c = 'Record ID: '+sr.getId() +'</br> '+err.getMessage();
                        newLog.Running_User__c = UserInfo.getUserName();
                        newLog.Source_Name__c = 'Contract Renewal Fails';
                        newLog.Source_Type__c = 'APEX';
                        logsToInsert.add(newLog);
                    }
                    
                    if(!logsToInsert.isEmpty()){
                        insert logsToInsert;
                    }
                }
            } 
        } 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}
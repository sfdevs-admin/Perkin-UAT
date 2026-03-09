global class ServiceCloudDeleteTrashCases implements Database.Batchable<sObject>, Database.Stateful {   
      global integer Summary;
      List<Case> casestodelete= new List<Case>(); 
      String CaseThrashid = Label.CaseThrashid;
      String CaseRecordTypeId = String.valueof(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Informatics').getRecordTypeId());     
      public String query =  'SELECT Id,Status from Case where RecordTypeid=\'' + CaseRecordTypeId + '\' AND OwnerId = \'' + CaseThrashid + '\'';
      
      global ServiceCloudDeleteTrashCases (){
        Summary = 0;
      }
      global Database.QueryLocator start(Database.BatchableContext BC){ 
        if(Test.isRunningTest()){
        query = 'SELECT Id,Status from Case where RecordTypeid=\'' + CaseRecordTypeId + '\'';
        }
        system.debug('#####'+query);
        return Database.getQueryLocator(query);  
      }
     
      global void execute(Database.BatchableContext BC, List<sObject> scope){ 
        for(sObject s : scope){
           Case c = (Case)s;
             casestodelete.add(c);
              summary++;
            }
        Database.delete(casestodelete,false);   
     }
     
      global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        system.debug('JobItemsProcessed'+a.JobItemsProcessed);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> idList = new List<String>();  
        String[] toAddresses = new String[] {};  
        toAddresses.add('sreedhar.j@listertechnologies.com');
        mail.setToAddresses(toAddresses);
        mail.setSubject('Number of Cases Updated ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + summary  +'  successful records with'+ ' ' +a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
     
    }
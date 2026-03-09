global class BatchDeleteTrashCases implements Database.Batchable<sObject>, Database.Stateful {   
    global integer Summary;
    List<Case> casestodelete= new List<Case>(); 
    String CaseThrashid = Label.CaseThrashid;
    public String query;
    public date lastMod;
    
     global BatchDeleteTrashCases (){
        Summary = 0;
      }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        lastMod = system.today() - 15;
        query =  'SELECT Id,Status,LastModifiedDate from Case where OwnerId = \'' + CaseThrashid + '\'';
        
        system.debug('QUERY **'+query);
        if(!Test.isRunningTest())
            query = query+' AND LastModifiedDate < :lastMod' ;
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> casesLst){ 
        for(Case  cases: casesLst){
            
            casestodelete.add(cases);
            Summary++;
        }
        Database.delete(casestodelete,false);   
    }
    
    global void finish(Database.BatchableContext BC){
         AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> idList = new List<String>();  
        String[] toAddresses = new String[] {};  
        toAddresses.add('shashi.puttaswamy@perkinelmer.com');
        mail.setToAddresses(toAddresses);
        mail.saveAsActivity = false;
        mail.setSubject('Number of Cases Updated ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + Summary  +'  successful records with'+ ' ' +a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
}
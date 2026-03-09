global class LeadAssignmentRule_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    /* Description - Database.QueryLocator start is on line 9 or whole batch will terminate.
    *  We limit it to one, so it doesn't run through the whole table
    */   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name FROM User LIMIT 1';
        return Database.getQueryLocator(query);         
    }
    
    /*Description - execute is on line 12 runs only when line 8, return a record*/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // LeadAssignmentRule_Calculations is a separate Apex class that pulls assignment rule using metadata api
        // and update Lead_Assignment_Rules__c field with count on user record.
        LeadAssignmentRule_Calculations.getAssignmentRule();        
    }
    
    /*Description - finish is on line 23 where we check if the job needs to be run only once, we abort it from backend 
    *  to prevent the error message running again later 
    * exceptionMessage: System.AsyncException: The Apex job named "Lead Assignment Rule Immediate Calculation" is already 
    * scheduled for execution.
    */
    global void finish(Database.BatchableContext BC) {           
        CronTrigger  con = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType,NextFireTime FROM CronTrigger 
                            WHERE CronJobDetail.Name ='Lead Assignment Rule Immediate Calculation'
                            ORDER BY CreatedDate desc LIMIT 1];
        //then use the active job id and abort it
        System.abortJob(con.id);        
    }
    
    /* Description - scheduledBatchable on line 35, is used to schedule the feature to Lead assignment pull and update 
     * count on user record
     * This gets called only one time when we want to schedule it from Anonymous Block for running daily at 5pm.
     */
    global class scheduledBatchable implements Schedulable {
        global void execute(SchedulableContext sc) {
            // line 38 is to invoke LeadAssignmentRule_Batch class when we are scheduling it to run at 5pm daily
            Database.executeBatch(new LeadAssignmentRule_Batch());
        }
    }
}
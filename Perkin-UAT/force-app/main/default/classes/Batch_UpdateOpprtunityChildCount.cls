/*
 This Batch Class will be used to Update the Child Opportunity count on the master opportunity
TEST CLASS : Test_OpportunityRollUp
 */
public class Batch_UpdateOpprtunityChildCount  implements Database.Batchable<SObject> {
    
    public Database.QueryLocator  start(Database.BatchableContext bc) {
        
        String query ='SELECT Id,Originating_Opportunity_INF__c FROM Opportunity Where Originating_Opportunity_INF__c !=\'\' and recordtype.developerName=\'Informatics\'  and Booked_Date_INF__c >= 2015-01-01 ';
        if(Test.isRunningTest()){
            query += ' Limit 10';
        }
        return  Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Opportunity> OpprtLst){
      
        OpportunityChildCountHandler.updateChildCount(OpprtLst,null,null,false);
    }    
    public void finish(Database.BatchableContext bc){
        
    }   
}
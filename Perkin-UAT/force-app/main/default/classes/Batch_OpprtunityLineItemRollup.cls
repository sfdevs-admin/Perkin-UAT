/*
This Batch Class will be used to Update the service product count,renewal product count and sum of Renewal Product
for the Opportunity
TEST CLASS : Test_OpportunityRollUp
*/
public class Batch_OpprtunityLineItemRollup implements Database.Batchable<SObject>,Database.stateful {

 public Database.QueryLocator  start(Database.BatchableContext bc) {
        
     //String query ='SELECT Id,OpportunityId FROM OpportunityLineItem Where OpportunityId !=\'\' and isRenewable__c=TRUE and opportunity.recordtype.developerName=\'Informatics\' and Opportunity.Booked_Date_INF__c >= 2015-01-01';
     String query ='SELECT Id,OpportunityId FROM OpportunityLineItem Where OpportunityId !=\'\' and opportunity.recordtype.developerName=\'Informatics\' and Opportunity.Booked_Date_INF__c >= 2015-01-01';
   
     if(Test.isRunningTest()){
            query += ' Limit 10';
        }
        return  Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<OpportunityLineItem> opprtLineList){
        OpportunityLineItemRollupHandler.updateRollupCount(opprtLineList,null,null,false);
        
    }    
    public void finish(Database.BatchableContext bc){
        

    }   
    
}
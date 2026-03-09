/*
This Batch Class will be used to Update the order Count for the Opportunity
TEST CLASS : Test_OpportunityRollUp
*/
public class Batch_UpdateOpprtunityOrderCount implements Database.Batchable<SObject>{
    
    public Database.QueryLocator  start(Database.BatchableContext bc) {
        
        //String query ='SELECT Id,OpportunityId FROM Order Where OpportunityId !=\'\' /*AND SBQQ__Contracted__c=True*/ And opportunity.recordtype.developerName=\'Informatics\'  and Opportunity.Booked_Date_INF__c >= 2015-01-01';
        String query ='SELECT Id,OpportunityId FROM Order Where OpportunityId !=\'\' And opportunity.recordtype.developerName=\'Informatics\'  and Opportunity.Booked_Date_INF__c >= 2015-01-01';

        if(Test.isRunningTest()){
            query += ' Limit 10';
        }
        return  Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Order> orderList){
        
        OpportunityOrderRollUpHandler.updateOrderCount(orderList,null,null,false);
        
    }    
    public void finish(Database.BatchableContext bc){
        
    }   
    
}
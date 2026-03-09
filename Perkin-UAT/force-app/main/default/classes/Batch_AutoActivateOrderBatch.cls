/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    
  *
  * 2. Description - Batch to auto activate the order if it's missed through the workflow.
  *
  * 3. Objects referenced
  *    -Order
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - none
  *
  * 6. Test Class Name: Batch_AutoActivateOrderBatch_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Jakin Prajapati (2021.11.17)
  *
*************************************************************/ 
public class Batch_AutoActivateOrderBatch implements Database.Batchable<Sobject>, Database.stateful{
    public Database.QueryLocator start(Database.BatchableContext bc) {
      String query = 'SELECT Id,Status, SBQQ__Contracted__c from order where status =\'Draft\' AND OpportunityID != null AND Opportunity.RecordType.DeveloperName = \'Informatics\'';
      if(!Test.isRunningTest()){
        query += ' AND CreatedDate = Yesterday';
      }
      return Database.getQueryLocator(query);        
    }
    
    public void execute(Database.BatchableContext bc, List<Order> orders){
      system.debug('@@orders= '+orders);
      List<Order> ordersToUpdate = new List<Order>();
      For(Order orderRecord : orders){
        orderRecord.Status = 'Activated';
        //orderRecord.SBQQ__Contracted__c = true;
        ordersToUpdate.add(orderRecord);
      }
      update ordersToUpdate;
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}
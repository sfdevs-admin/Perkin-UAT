/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    
  *
  * 2. Description - This is the scheduler class for batch Batch_AutoActivateOrderBatch 
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
  * 6. Test Class Name: 
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Jakin Prajapati (2021.11.17)
  *
*************************************************************/ 
global class Batch_AutoActivateOrderBatch_Scheduler implements schedulable{
	global void execute(Schedulablecontext Batch_AutoActivateOrderBatch){
        Batch_AutoActivateOrderBatch batchJob = new Batch_AutoActivateOrderBatch();
        Database.executeBatch(batchJob,1);
    }
}
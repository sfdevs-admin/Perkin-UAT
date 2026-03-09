/* This Class was designed to be used for Mass Action Scheduler in 
   order to be able to Run the 'LeadAssignmentRule_Batch' on demand
   from the Front End by Admin Team users.
   Do not alter/delete without first looking at Mass Action Scheduler. 
*/

global class LeadAssignmentRule_Scheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadAssignmentRule_Batch());
    }
}
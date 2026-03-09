global class SchedulerClassToDeleteTrashCases implements Schedulable{
   global void execute(SchedulableContext sc) {
      BatchDeleteTrashCases b = new BatchDeleteTrashCases(); 
      database.executebatch(b);
   }
}
global class scheduledeDeleteTrashCases implements Schedulable{
   global void execute(SchedulableContext sc) {
      ServiceCloudDeleteTrashCases  b = new ServiceCloudDeleteTrashCases (); 
      database.executebatch(b);
   }
}
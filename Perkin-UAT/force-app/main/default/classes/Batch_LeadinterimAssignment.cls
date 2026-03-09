public class Batch_LeadinterimAssignment implements Schedulable{
    public void execute(SchedulableContext SC){
        LeadinterimAssignment FOC = new LeadinterimAssignment();
        if(test.isRunningTest())
            database.executeBatch(FOC,1);
        else
        database.executeBatch(FOC,200);
    }
}
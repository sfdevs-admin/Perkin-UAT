/*
 To Schedule Batch_FreezeUsers_NoActivity batch class, to freeze the users
 who do not have login activity for more than the no of days mentioned in custom setting.
*/

public class Scheduler_FreezeUsers_NoActivity implements Schedulable{
    
    public void execute(SchedulableContext sc)
    {
        Id jobId=Database.executeBatch(new Batch_FreezeUsers_NoActivity());
    }

}
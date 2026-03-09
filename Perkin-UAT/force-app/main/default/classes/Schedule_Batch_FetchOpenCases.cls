public class Schedule_Batch_FetchOpenCases implements Schedulable{
    public void execute(SchedulableContext SC){
        Batch_FetchOpenCases FOC = new Batch_FetchOpenCases();
        if(test.isRunningTest())
            database.executeBatch(FOC,1);
        else
        database.executeBatch(FOC,200);
    }
}
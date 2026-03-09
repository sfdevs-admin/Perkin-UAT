public class Schedule_Batch_DeletePast3MonthsData implements Schedulable{
    public void execute(SchedulableContext SC)
        {
            Batch_DeletePast3MonthsData DPD = new Batch_DeletePast3MonthsData();
            if(test.isRunningTest())
                Database.executeBatch(DPD,1);
            else
            Database.executeBatch(DPD,200);
        }

}
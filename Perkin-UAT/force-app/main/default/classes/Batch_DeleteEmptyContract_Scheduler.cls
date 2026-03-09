global class Batch_DeleteEmptyContract_Scheduler implements Schedulable{
    global void execute(Schedulablecontext Batch_DeleteEmptyContract_Scheduler){
        Batch_DeleteEmptyContract batchJob = new Batch_DeleteEmptyContract();
        Database.executeBatch(batchJob,50);
    }
}
global class ScheduleBatchToUpdatePriceBookEntryCode implements Schedulable {
  
    global void execute(SchedulableContext SC) {
        //Initiate the batch class
        BatchToUpdatePriceBookEntryCode obj = new BatchToUpdatePriceBookEntryCode();
        Database.executeBatch(obj, 2000);
    }

}
global class ScheduleBatchertoUpdateDup implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchertoUpdateDuplicateRecords b = new BatchertoUpdateDuplicateRecords();
        database.executebatch(b);
    }
}
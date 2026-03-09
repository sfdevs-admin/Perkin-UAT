public class BD_PriceBookEntryValidity implements Database.Batchable<SObject>, Schedulable {
  
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, IsActive, BD_Valid_To__c ' +
                       'FROM PricebookEntry ' +
                       'WHERE IsActive = TRUE ' +
                       'AND BD_Valid_To__c < TODAY';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PricebookEntry> scope) {
        List<PricebookEntry> entriesToUpdate = new List<PricebookEntry>();
        System.debug('Number of entries to update:  '+ scope.size());
        
        for(PricebookEntry entry : scope) {
            entry.IsActive = false;
            entriesToUpdate.add(entry);
        }
        
        if(!entriesToUpdate.isEmpty()) {
            Database.update(entriesToUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Add any future logic here
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BD_PriceBookEntryValidity(), 2000);
    }
}
global class MassActionLogDeletionBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Calculate the date 7 days ago
        Date sevenDaysAgo = Date.today().addDays(-7);
        
        // SOQL to retrieve all dca_mass_action__Mass_Action_Log__c records older than 7 days, sorted by Id
        return Database.getQueryLocator([
            SELECT Id 
            FROM dca_mass_action__Mass_Action_Log__c 
            WHERE CreatedDate < :sevenDaysAgo 
            ORDER BY Id
        ]);
    }

    global void execute(Database.BatchableContext BC, List<dca_mass_action__Mass_Action_Log__c> scope) {
        // Delete the current batch of records
        try {
            delete scope;
        } catch (DmlException e) {
            // Handle exceptions (e.g., logging or custom handling)
            System.debug('Failed to delete records: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optionally, do something after all batches are processed
        System.debug('Batch processing completed.');
    }
}
global class BatcherAccountSynchronizeField implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query='';
        query='Select Id from Account';  
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        
        /*for(Account iterable : scope)
        {
            iterable.DSE__DS_Synchronize__c = false;
        }*/
        
        update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        
        system.debug('updated the accounts');
        
    }

    
}
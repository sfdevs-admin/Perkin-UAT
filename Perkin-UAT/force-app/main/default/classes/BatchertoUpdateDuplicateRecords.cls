global class BatchertoUpdateDuplicateRecords implements Database.Batchable<sObject>{
    String Query='';
    global BatchertoUpdateDuplicateRecords(){
        Query = 'Select id from DSE__DS_DuplicateBean__c';
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(Query);
    }
     global void execute(Database.BatchableContext BC, List<sObject> scope){
        /*for(DSE__DS_DuplicateBean__c s : scope){
             s.DSE__DS_Toggle_Master__c = false;
            s.DSE__DS_No_Duplicate__c = true;
        }
        system.debug('scope1' + scope);
        if(scope.size()>0){
            try
            {
                update scope;
            }
            catch(Exception e)
                {
                    system.debug('Exception ' + e.getMessage());
                }
        }*/
    }
     global void finish(Database.BatchableContext bc){
        
    }   
}
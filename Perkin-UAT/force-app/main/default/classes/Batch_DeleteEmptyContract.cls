global class Batch_DeleteEmptyContract implements Database.Batchable<SObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        String RecType = 'Accountwide Contract';
        String query = 'SELECT Id FROM Contract WHERE Id NOT IN (SELECT SBQQ__Contract__c FROM SBQQ__Subscription__c) AND RecordType.Name =:Rectype AND CreatedDate = today AND Master_Contract__c = NUll';
        return Database.getQueryLocator(query);
    }
	global void execute(Database.BatchableContext BC, List<SObject> scope){
        if(scope != NULL && !scope.isEmpty()){
            delete scope;
        }
    }
	global void finish(Database.BatchableContext BC){}
}
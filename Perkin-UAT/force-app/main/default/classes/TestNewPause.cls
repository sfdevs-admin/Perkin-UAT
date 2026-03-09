global class TestNewPause implements Database.Batchable<SObject>,Database.Stateful,Schedulable{
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(
        	'SELECT Id, Status FROM SVMXC__Service_Order__c Where Id=\'a31Ps000000xJt3IAE\' '
        );
    }
    global void execute(Database.BatchableContext bc, List<SVMXC__Service_Order__c> scope){
        for(SVMXC__Service_Order__c wo:scope){
            wo.SVMX_PS_Problem_Summary__c = 'TestPSSSSS';
            update wo;
        }
    }
    
    global void execute(SchedulableContext ctx){
      String soql = 'SELECT Id, Name FROM Account';
      TestNewPause batch = new TestNewPause();
      Database.executebatch(batch, 200);
    }
    global void finish(Database.BatchableContext bc){
        
    }

}
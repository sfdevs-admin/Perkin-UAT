global class Schedule_BatchSendEmail implements Schedulable{
    
    global void execute(SchedulableContext sc){
        List<Send_Mail_Settings__c> sm = [SELECT Schedule_send_mail__c from Send_Mail_Settings__c];
        if(sm!=null){
            if(sm.get(0).Schedule_send_mail__c){
                BatchSendMail batchSendEmailObj = new BatchSendMail();
                database.executebatch(batchSendEmailObj,10);
            }
        }
    }
}
global class BatchEmailValidate implements Database.Batchable<sObject>{ 
global Database.QueryLocator start(Database.BatchableContext BC)
{

String query =  'select Id, Email from Contact';
return Database.getQueryLocator(query);
}
global void execute(Database.BatchableContext BC, List<Contact> scope)
    {  
        list<contact> con=new list<contact>();
        for(contact cont:scope){
        if(cont.email!=null){
        cont.Email_Test__c=cont.email;
        }
         con.add(cont);
        } 
        database.update(con,false);
        }
global void finish(Database.BatchableContext BC)
{
}
}
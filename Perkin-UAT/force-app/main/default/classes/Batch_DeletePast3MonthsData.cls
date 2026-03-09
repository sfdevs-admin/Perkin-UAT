public class Batch_DeletePast3MonthsData implements Database.Batchable<sObject>
{
    String queryStr;
    List<Cases_snapshot__c> DataToDelete = new List<Cases_snapshot__c>();
     Date threeMonthsAgo = Date.today().addDays(-91);
    
    public Batch_DeletePast3MonthsData()
        {
            queryStr = 'Select id from Cases_snapshot__c where createddate <=:threeMonthsAgo';
            system.debug('date field is '+threeMonthsAgo);
        }
    
    public Database.QueryLocator start(Database.BatchableContext BC)
    {         
        return Database.getQueryLocator(queryStr);
    }
    
    public void execute(Database.BatchableContext BC,List<Cases_snapshot__c> scope)
     {
         For(Cases_snapshot__c cs : scope)
         {
             DataToDelete.add(cs);
         }
         
         if(DataToDelete.size()>0)
             {
                 delete DataToDelete;
             }
     }
    
    public void finish(Database.BatchableContext BC)
    {
        
    }
}
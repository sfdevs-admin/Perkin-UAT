global class BatchDuplAccounts_IgnoreDuplSetToTrue implements Database.Batchable<sObject>
{
    global final String query;
        
    global BatchDuplAccounts_IgnoreDuplSetToTrue()
    {
        query = 'SELECT Id FROM DSE__DS_Duplicates__c';
    }
       
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
      
    //Execute Logic
    global void execute(Database.BatchableContext BC, List<sObject>scope)
    {
        //Logic to be Executed batch wise      
        //List<DSE__DS_Duplicates__c> duplicateAccList = (List<DSE__DS_Duplicates__c>) scope;
        
        /*for(DSE__DS_Duplicates__c da : duplicateAccList)
        {
            da.DSE__DS_Ignore_Duplicate__c = true;
            da.Do_you_want_to_Ignore_Duplicates__c = true;
        }*/
        
        //if(duplicateAccList!=null && duplicateAccList.size()>0)
        //{
            //update duplicateAccList;
        //}
        
    }
    
    global void finish(Database.BatchableContext BC)
    {
       // Logic to be Executed at finish
        
    }

}
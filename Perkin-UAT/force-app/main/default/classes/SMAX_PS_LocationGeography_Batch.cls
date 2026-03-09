/**
 *  Apex Class for Batch updating Location [SVMXC__Site__c] to Geography Lookups.
 *  2017-11-28      Frank VanLoon       Initial creation, for Location Integration / Auto-Assignment.
 */
global class SMAX_PS_LocationGeography_Batch implements Database.Batchable<SObject>, Schedulable
{
    global SMAX_PS_LocationGeography_Batch() { }

    /** Schedulable methods **/

    global void execute(SchedulableContext ctx)
    {
        SMAX_PS_LocationGeography_Batch btch = new SMAX_PS_LocationGeography_Batch();
        Database.executeBatch(btch);
    }

    /** Database.Batchable methods **/

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String query =  null;
        query= 'SELECT Id, SMAX_PS_LocationCode__c, SMAX_PS_Geography__c FROM SVMXC__Site__c  WHERE (SMAX_PS_LocationCode__c != null AND SMAX_PS_Geography__c = null';
        if(Test.isRunningTest())
            query = 'SELECT Id, SMAX_PS_LocationCode__c, SMAX_PS_Geography__c FROM SVMXC__Site__c';
           
        return Database.getQueryLocator(query ); 
    
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Site__c> locations) 
    {
        SMAX_PS_LocationManager.lookupLocationGeography(locations, null);

        Database.SaveResult[] results = Database.update(locations, false);
        for (Integer i = 0; i < results.size(); i++)
        {
            Database.SaveResult result = results[i];
            if (!result.isSuccess())
            {
                SVMXC__Site__c location = locations[i];
                System.debug('Error updating Location: ' + location.Id + ' with Geography Lookup: ' + result.getErrors());
                // TODO: Replace with insert into Error Log
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) 
    {
    }   

}
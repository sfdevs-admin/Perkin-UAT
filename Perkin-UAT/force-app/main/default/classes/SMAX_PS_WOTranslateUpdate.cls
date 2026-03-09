global class SMAX_PS_WOTranslateUpdate implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([SELECT ID, Name, SVMXC__Order_Status__c, 
           SMAX_PS_Translation__c, SVMXC__Country__c ,SMAX_PS_Owned_By_Company__c
           FROM SVMXC__Service_Order__c 
           WHERE SVMXC__Order_Status__c IN ('On Hold - Credit', 'Assigned', 'Technician Accepted', 'Technician Rejected', 'Open', 'Requires Revisit', 'Work Complete - Error', 'Initializing') 
           AND SMAX_PS_Translation__c ='']);
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope)
    {
        SMAX_PS_WorkOrderManager.lookupTranslation(scope, null);
        Database.update(scope, false);
    }

    global void finish(Database.BatchableContext BC)
    {
    }
}
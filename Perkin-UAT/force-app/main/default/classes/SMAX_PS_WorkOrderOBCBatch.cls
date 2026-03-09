/*********************************************************************************************************************
 * CLASS: SMAX_PS_WorkOrderOBCBatch
 * @description: Batch class that will update the Work Order Owned By Company if missed through default engine logic by 
 *               looking at related Installed Product records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/11/15   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_WorkOrderOBCBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all Work Orders with a BLANK Owned By Company and a related IP record that has the Owned By Company populated
        return Database.getQueryLocator([SELECT Id, recordTypeId, Name, SVMXC__Component__c, SMAX_PS_SalesOrg__c, SMAX_PS_SAP_Maintenance_Plant__c, SVMXC__Group_Member__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Service_Order__c WHERE SMAX_PS_Owned_By_Company__c = '' ORDER BY Name DESC LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000)
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope){

        SMAX_PS_Utility.SVC_REGISTER_SINGLETON = 'Update Sobject Owned By Company';
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(scope, null);
        Database.update(scope, false);

//        Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
//        Set<Id> ipIds = new Set<Id>();
        // SCOPE Loop START
//        for(SVMXC__Service_Order__c wo : scope){
//            // add already filtered Ids from query to Set
//            ipIds.add(wo.SVMXC__Component__c);
//        }
//        // SCOPE Loop END
//
//        if(ipIds.size() > 0){
//
//            // populate Installed Products Map
//            for(SVMXC__Installed_Product__c ip :
//                [SELECT Id,
//                        SMAX_PS_Owned_By_Company__c,
//                        SMAX_PS_SalesOrg__c,
//                        SMAX_PS_MaintenancePlant__c,
//                        SMAX_PS_Owned_By_Company_Decided_By__c
//                   FROM SVMXC__Installed_Product__c
//                  WHERE Id IN :ipIds]){
//                    ipMap.put(ip.Id, ip);
//            }
//
//            if(ipMap.size() > 0){
//
//                // SCOPE Loop START
//                for(SVMXC__Service_Order__c wo : scope){
//
//                    if(ipMap.keyset().contains(wo.SVMXC__Component__c)){
//                        wo.SMAX_PS_SAP_Maintenance_Plant__c = ipMap.get(wo.SVMXC__Component__c).SMAX_PS_MaintenancePlant__c;
//                        wo.SMAX_PS_SalesOrg__c = ipMap.get(wo.SVMXC__Component__c).SMAX_PS_SalesOrg__c;
//                    }
//                }
//                // SCOPE Loop END
//
//                update scope;
//            }
//        }
    }

    global void finish(Database.BatchableContext BC){
//        startRecurringSchedule();
    }

    public static void startRecurringSchedule() {

        if (!Test.isRunningTest()) {
            System.scheduleBatch(new SMAX_PS_WorkOrderOBCBatch(), 'SVMX Work Order OwnedBy (Recurring)', 5, 100);
        }
    }

    global void execute(SchedulableContext sc){
        SMAX_PS_WorkOrderOBCBatch batch = new SMAX_PS_WorkOrderOBCBatch();
        Database.executeBatch(batch, 100);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Work Order Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_WorkOrderOBCBatch());
    }


}
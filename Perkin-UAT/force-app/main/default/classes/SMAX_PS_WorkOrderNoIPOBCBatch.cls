/*********************************************************************************************************************
 * CLASS: SMAX_PS_WorkOrderNoIPOBCBatch
 * @description: Batch class that will update the Work Order Owned By Company if missed through default engine logic by 
 *               looking at related Installed Product records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/12/01   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_WorkOrderNoIPOBCBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all Work Orders with a BLANK Owned By Company and a related Technician record that has the Owned By Company populated
        return Database.getQueryLocator([SELECT Id, SVMXC__Component__c, SMAX_PS_SalesOrg__c, SMAX_PS_SAP_Maintenance_Plant__c, SVMXC__Group_Member__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Service_Order__c WHERE SMAX_PS_Owned_By_Company__c = '' AND SVMXC__Component__c = '' AND SVMXC__Group_Member__c != '' LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000) 
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope){

        Map<String, SVMXC__Service_Group_Members__c> techMap = new Map<String, SVMXC__Service_Group_Members__c>();
        Set<Id> techIds = new Set<Id>();

        // SCOPE Loop START
        for(SVMXC__Service_Order__c wo : scope){
            // add already filtered Ids from query to Set
            techIds.add(wo.SVMXC__Group_Member__c);
        }
        // SCOPE Loop END

        if(techIds.size() > 0){

            // populate Installed Products Map
            for(SVMXC__Service_Group_Members__c te : 
                [SELECT Id,
                        SMAX_PS_Plant__c
                   FROM SVMXC__Service_Group_Members__c
                  WHERE Id IN :techIds]){
                    techMap.put(te.Id, te);          
            }

            if(techMap.size() > 0){

                // SCOPE Loop START
                for(SVMXC__Service_Order__c wo : scope){

                    if(techMap.keyset().contains(wo.SVMXC__Group_Member__c)){
                        wo.SMAX_PS_SAP_Maintenance_Plant__c = techMap.get(wo.SVMXC__Group_Member__c).SMAX_PS_Plant__c;
                    }
                }
                // SCOPE Loop END

                update scope;
            }
        }
    }

    global void finish(Database.BatchableContext BC){

    }

    global void execute(SchedulableContext sc){

        SMAX_PS_WorkOrderNoIPOBCBatch batch = new SMAX_PS_WorkOrderNoIPOBCBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Work Order (NO IP) Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_WorkOrderNoIPOBCBatch());
    }
}
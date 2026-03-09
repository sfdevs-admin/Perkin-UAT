/*********************************************************************************************************************
 * CLASS: SMAX_PS_PartsOrderOBCBatch
 * @description: Batch class that will update the Parts Order Owned By Company if missed through default engine logic by 
 *               looking at related Location (Destination) records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/12/05   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_PartsOrderOBCBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all Parts Orders with a BLANK Owned By Company and a related Location (Destination) record that has the Owned By Company populated
        return Database.getQueryLocator([SELECT Id, SMAX_PS_SalesOrg__c, BD_Maintenance_Plant__c, SVMXC__Destination_Location__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__RMA_Shipment_Order__c WHERE SMAX_PS_Owned_By_Company__c = '' AND SVMXC__Destination_Location__c != '' LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000) 
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__RMA_Shipment_Order__c> scope){

        Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
        Set<Id> locIds = new Set<Id>();

        // SCOPE Loop START
        for(SVMXC__RMA_Shipment_Order__c po : scope){
            // add already filtered Ids from query to Set
            locIds.add(po.SVMXC__Destination_Location__c);
        }
        // SCOPE Loop END

        if(locIds.size() > 0){

            // populate Location Map
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_MaintenancePlant__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds]){
                    locMap.put(loc.Id, loc);          
            }

            if(locMap.size() > 0){

                // SCOPE Loop START
                for(SVMXC__RMA_Shipment_Order__c po : scope){

                    if(locMap.keyset().contains(po.SVMXC__Destination_Location__c)){
                        po.SMAX_PS_SalesOrg__c = (String.IsBlank(po.SMAX_PS_SalesOrg__c) ? locMap.get(po.SVMXC__Destination_Location__c).SMAX_PS_SalesOrg__c : po.SMAX_PS_SalesOrg__c);
                        po.BD_Maintenance_Plant__c = (String.IsBlank(po.BD_Maintenance_Plant__c) ? locMap.get(po.SVMXC__Destination_Location__c).SMAX_PS_MaintenancePlant__c : po.BD_Maintenance_Plant__c);
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

        SMAX_PS_PartsOrderOBCBatch batch = new SMAX_PS_PartsOrderOBCBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Parts Order Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_PartsOrderOBCBatch());
    }
}
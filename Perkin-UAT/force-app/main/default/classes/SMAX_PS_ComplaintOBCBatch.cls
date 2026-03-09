/*********************************************************************************************************************
 * CLASS: SMAX_PS_ComplaintOBCBatch
 * @description: Batch class that will update the Complaint Owned By Company if missed through default engine logic by 
 *               looking at Installed Product related records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/11/16   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_ComplaintOBCBatch implements Database.Batchable<SObject>, Schedulable  {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all Complaints with a BLANK Owned By Company and a related IP record regardless if Owned By Company is populated
        return Database.getQueryLocator([SELECT Id, SMAX_PS_WorkOrder__c, SMAX_PS_InstalledProduct__c, SMAX_PS_Plant__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SMAX_PS_Complaint__c WHERE SMAX_PS_Owned_By_Company__c = '' LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000) 
    }

    global void execute(Database.BatchableContext BC, List<SMAX_PS_Complaint__c> scope){

        Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
        Map<String, SVMXC__Service_Order__c> woMap = new Map<String, SVMXC__Service_Order__c>();
        Set<Id> ipIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();

        // SCOPE Loop START
        for(SMAX_PS_Complaint__c cp : scope){
            // check for non-blank related IPs
            if(String.IsNotBlank(cp.SMAX_PS_InstalledProduct__c)){
                ipIds.add(cp.SMAX_PS_InstalledProduct__c);
            }
            // check for non-blank related WOs
            if(String.IsNotBlank(cp.SMAX_PS_WorkOrder__c)){
                woIds.add(cp.SMAX_PS_WorkOrder__c);
            }
        }
        // SCOPE Loop END

        

        // populate IP Map
        if(ipIds.size() > 0){
            for(SVMXC__Installed_Product__c ip : 
                [SELECT Id,
                        SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Installed_Product__c
                WHERE Id IN :ipIds]){
                    ipMap.put(ip.Id, ip);          
            }
        }
        if(woIds.size() > 0){

            // populate Work Orders Map
            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_SAP_Maintenance_Plant__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds]){
                    woMap.put(wo.Id, wo);          
            }
        }

        // SCOPE Loop START
        for(SMAX_PS_Complaint__c cp : scope){

            if(String.IsBlank(cp.SMAX_PS_Plant__c)){
                if(ipMap.keySet().contains(cp.SMAX_PS_InstalledProduct__c) && String.IsNotBlank(ipMap.get(cp.SMAX_PS_InstalledProduct__c).SMAX_PS_MaintenancePlant__c)){
                    cp.SMAX_PS_Plant__c = ipMap.get(cp.SMAX_PS_InstalledProduct__c).SMAX_PS_MaintenancePlant__c;
                }
                else if(woMap.keySet().contains(cp.SMAX_PS_WorkOrder__c) && String.IsNotBlank(woMap.get(cp.SMAX_PS_WorkOrder__c).SMAX_PS_SAP_Maintenance_Plant__c)){
                    cp.SMAX_PS_Plant__c = woMap.get(cp.SMAX_PS_WorkOrder__c).SMAX_PS_SAP_Maintenance_Plant__c;
                }
            }
        }
        // SCOPE Loop END

        update scope;
    }

    global void finish(Database.BatchableContext BC){

    }

    global void execute(SchedulableContext sc){

        SMAX_PS_ComplaintOBCBatch batch = new SMAX_PS_ComplaintOBCBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Complaint Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_ComplaintOBCBatch());
    }
    
}
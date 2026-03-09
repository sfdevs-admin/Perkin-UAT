/*********************************************************************************************************************
 * CLASS: SMAX_PS_InstalledProdOBCBatch
 * @description: Batch class that will update the Installed Product Owned By Company if missed through default engine logic by 
 *               looking at related Location records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/11/16   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_InstalledProdOBCBatch implements Database.Batchable<SObject>, Schedulable  {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all IPs with a BLANK Owned By Company and a related Location record that has the Owned By Company populated
        return Database.getQueryLocator([SELECT Id, SVMXC__Site__c, SMAX_PS_SalesOrg__c, SMAX_PS_MaintenancePlant__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Installed_Product__c WHERE SVMXC__Site__r.SMAX_PS_Owned_By_Company__c != '' AND
            SMAX_PS_Owned_By_Company__c = '' LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000) 
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Installed_Product__c> scope){

        Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
        Set<Id> locIds = new Set<Id>();

        // SCOPE Loop START
        for(SVMXC__Installed_Product__c ip : scope){
            // add already filtered Ids from query to Set
            locIds.add(ip.SVMXC__Site__c);
        }
        // SCOPE Loop END

        if(locIds.size() > 0){

            // populate Locations Map
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds]){
                    locMap.put(loc.Id, loc);          
            }

            if(locMap.size() > 0){

                // SCOPE Loop START
                for(SVMXC__Installed_Product__c ip : scope){

                    if(locMap.keyset().contains(ip.SVMXC__Site__c)){
                        ip.SMAX_PS_MaintenancePlant__c = locMap.get(ip.SVMXC__Site__c).SMAX_PS_MaintenancePlant__c;
                        ip.SMAX_PS_SalesOrg__c = locMap.get(ip.SVMXC__Site__c).SMAX_PS_SalesOrg__c;
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

        SMAX_PS_InstalledProdOBCBatch batch = new SMAX_PS_InstalledProdOBCBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('IP Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_InstalledProdOBCBatch());
    }
    
}
/*********************************************************************************************************************
 * CLASS: SMAX_PS_WorkOrderPrevCompanyBatch
 * @description Batch class that will update the Work Order Previous Owned by Company field
 * @author Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/11/03   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_WorkOrderPrevCompanyBatch implements Database.Batchable<SObject>, Schedulable {

    private String query = 'SELECT Id, SVMXC__Component__c, SMAX_PS_Previous_Owned_by_Company__c FROM SVMXC__Service_Order__c WHERE SVMXC__Component__c != NULL ';

    public SMAX_PS_WorkOrderPrevCompanyBatch() {
        query += 'AND SMAX_PS_Previous_Owned_by_Company__c = \'\'';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        //return Database.getQueryLocator(query); // I think a "compiled" query might be faster..
        return Database.getQueryLocator([SELECT Id, SVMXC__Component__c, SMAX_PS_Previous_Owned_by_Company__c
            FROM SVMXC__Service_Order__c WHERE SVMXC__Component__c != NULL
                AND SMAX_PS_Previous_Owned_by_Company__c = ''
            LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000)
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope){

        Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
        Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> obcCodesMap = new Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt>();
        Set<Id> ipIds = new Set<Id>();

        // SCOPE Loop START
        for(SVMXC__Service_Order__c wo : scope){

            // add already filtered Ids from query to Set
            ipIds.add(wo.SVMXC__Component__c);
        }
        // SCOPE Loop END

        if(ipIds.size() > 0){

            // populate Owned by Company Codes Mapping
            for(SMAX_PS_OwnedByCompany_Mapping__mdt obcMapping :
                [SELECT Id,
                        Label,
                        SMAX_PS_Company_Code__c, 
                        SMAX_PS_Country__c, 
                        SMAX_PS_Mapping_Key__c, 
                        SMAX_PS_Owned_By_Company__c, 
                        SMAX_PS_Sales_Org__c, 
                        SMAX_PS_Service_Plant__c 
                FROM SMAX_PS_OwnedByCompany_Mapping__mdt]){
                    obcCodesMap.put(obcMapping.SMAX_PS_Service_Plant__c, obcMapping);
            }

            // populate Installed Products Map
            for(SVMXC__Installed_Product__c ip : 
                [SELECT Id,
                        SMAX_PS_Previous_Plant__c
                   FROM SVMXC__Installed_Product__c
                  WHERE Id IN :ipIds AND
                        SMAX_PS_Previous_Plant__c != '']){
                    ipMap.put(ip.Id, ip);          
            }

            if(ipMap.size() > 0){

                // SCOPE Loop START
                for(SVMXC__Service_Order__c wo : scope){

                    if(ipMap.keyset().contains(wo.SVMXC__Component__c) && obcCodesMap.keySet().contains(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_Previous_Plant__c)){
                        wo.SMAX_PS_Previous_Owned_by_Company__c = obcCodesMap.get(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_Previous_Plant__c).SMAX_PS_Owned_By_Company__c;
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

        SMAX_PS_WorkOrderPrevCompanyBatch batch = new SMAX_PS_WorkOrderPrevCompanyBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Work Order Previous Company Batch ' + system.today().format(), sch, new SMAX_PS_WorkOrderPrevCompanyBatch());
    }
}
/*********************************************************************************************************************
 * CLASS: SMAX_PS_StockTransferOBCBatch
 * @description: Batch class that will update the Stock Transfer Owned By Company if missed through default engine logic by 
 *               looking at related Location records
 *      @author: Eugene Ross
 * <-----CHANGE LOG----->
 * 2022/11/23   Eugene Ross     Initial creation - Polaris Project
 *
 *********************************************************************************************************************/
global class SMAX_PS_StockTransferOBCBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        // return all IPs with a BLANK Owned By Company and a related Location record that has the Owned By Company populated
        return Database.getQueryLocator([SELECT Id, SMAX_PS_Company_Code__c, SVMXC__Source_Location__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Stock_Transfer__c WHERE SMAX_PS_Owned_By_Company__c = '' LIMIT 100000]); // Limit to 100,000 (max query locator is 110,000) 
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Stock_Transfer__c> scope){

        Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
        Set<Id> locIds = new Set<Id>();

        // SCOPE Loop START
        for(SVMXC__Stock_Transfer__c st : scope){
            if(String.IsNotBlank(st.SVMXC__Source_Location__c)){
                locIds.add(st.SVMXC__Source_Location__c);
            }
        }
        // SCOPE Loop END

        if(locIds.size() > 0){

            // populate Locations Map
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds]){
                    locMap.put(loc.Id, loc);          
            }

            if(locMap.size() > 0){

                // SCOPE Loop START
                for(SVMXC__Stock_Transfer__c st : scope){

                    if(locMap.keyset().contains(st.SVMXC__Source_Location__c)){
                        st.SMAX_PS_Company_Code__c = locMap.get(st.SVMXC__Source_Location__c).SMAX_PS_SalesOrg__c;
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

        SMAX_PS_StockTransferOBCBatch batch = new SMAX_PS_StockTransferOBCBatch();
        Database.executeBatch(batch, 50);
    }

    public static void setupSchedule(){

        String sch = '0 0 21 ? * * *'; // everyday at 9PM
        system.schedule('Stock Transfer Owned By Company Batch ' + system.today().format(), sch, new SMAX_PS_StockTransferOBCBatch());
    }
}
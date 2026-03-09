public class APX_MergeContractsController {
    @AuraEnabled
    public static List<Contract> getContractList(Id accId) {
        List<Contract> contrctList = [Select Id,Account.Name,ContractNumber,StartDate,EndDate,Status /*,INF_OrderNum__c,Opportunity_Name__c,
                                     Quote_number__c,SBQQ__Quote__c*/,Master_Contract_checkbox__c/*,Contract_s_renewal_stage__c*/ From Contract Where AccountId=:accId and Status='Activated' AND EndDate>=today];
        
        //System.debug('ContractList Size '+ contrctList.size());
        if( contrctList.size() == 0 ) {
            throw new AuraHandledException('No Active Contracts for the selected Quote.');
        }
        return contrctList;
    }
    @AuraEnabled
    public static List<Contract> getChildContractList(Contract masterCon, Id accId) {
        List<Contract> childConList = [SELECT Id,AccountId,ContractNumber,StartDate,EndDate,Status,/*INF_OrderNum__c,Opportunity_Name__c,*/
                                       /*Quote_number__c,SBQQ__Quote__c,*/Master_Contract_checkbox__c FROM Contract WHERE Id !=: masterCon.Id AND AccountId=:accId AND Status='Activated' AND EndDate>=today];
       
        //System.debug('child ContractList '+ childConList);
        if( childConList.size() == 0 ) {
            throw new AuraHandledException('There is only one contract to the Account');
        }
        return childConList;
    }/*
    @AuraEnabled
    public static List<SBQQ__Subscription__c> getSubscriptionList(Contract masterCon, List<Contract> childConList){
        Set<Id> conIds = new Set<Id>();
        for(Contract con : childConList){
            conIds.add(con.Id);
        }
        conIds.add(masterCon.Id);
        List<SBQQ__Subscription__c> subList = [SELECT Id,SBQQ__Contract__r.ContractNumber,Name,SBQQ__ProductName__c,SBQQ__Product__r.ProductCode,
                                               SBQQ__StartDate__c,SBQQ__EndDate__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN:conIds ORDER BY SBQQ__Contract__r.ContractNumber];
        system.debug('subList size-->'+subList.size());
        return subList;
    }*/
    @AuraEnabled
    public static void mergeMasterContract(List<Contract> childConList,Contract masterCon){
        Profile prof = [SELECT Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        Set<Id> conIds = new Set<Id>();
        Set<String> oppId = new Set<String>();
        List<Contract> updateChildCon = new List<Contract>();
        Date startDate = masterCon.StartDate;
        system.debug('startDate'+startDate);
        Date endDate = masterCon.EndDate;
        
        //if profile is sys admin or inf op then merge will happen with different end dates else merge will happen only for same end dates
        system.debug('Profile Name= '+prof.Name);
        if(prof.Name != 'Informatics Operations' && prof.Name != 'System Administrator'){
            for(Contract con : childConList){
                if(masterCon.EndDate == con.EndDate){
                    conIds.add(con.Id);
                    con.Status = 'Merged';
                    con.Master_Contract__c = masterCon.Id;
                    //oppId.add(con.SBQQ__RenewalOpportunity__c);
                    updateChildCon.add(con);
                }else{
                    throw new AuraHandledException('Master Contract and Child Contracts end date are not matching');
                }
            }
        }else{
            for(Contract con : childConList){
                conIds.add(con.Id);
                con.Status = 'Merged';
                con.Master_Contract__c = masterCon.Id;
                //oppId.add(con.SBQQ__RenewalOpportunity__c);
                updateChildCon.add(con);
            }
        }
        
        
        //get the list of subscriptions from child contracts
       /* List<SBQQ__Subscription__c> subsList = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN: conIds];
        List<SBQQ__Subscription__c> subsListToUpdate = new List<SBQQ__Subscription__c>();
        
        //update the subscription to master contract
        if(subsList != NULL && !subsList.isEmpty()){
            for(SBQQ__Subscription__c sub : subsList){
                sub.SBQQ__Contract__c = masterCon.Id;
                subsListToUpdate.add(sub);
            }
        }
        if(subsListToUpdate != NULL && !subsListToUpdate.isEmpty()){
            update subsListToUpdate;
        } */
        
        
        if(updateChildCon != NULL && !updateChildCon.isEmpty()){
            update updateChildCon;
        }
        
            //Uncheck Renewal quoted on master contract
            //masterCon.SBQQ__RenewalQuoted__c = FALSE;
            masterCon.Master_Contract_checkbox__c = TRUE;
            masterCon.StartDate = startDate;
            masterCon.EndDate = endDate;
            update masterCon;
        
    }
}
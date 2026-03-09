public class OpportunityContractRollUpHandler {
    
    public static void updateContractCount(List<Contract> contractLst,Map<Id,Contract> oldContract,Map<id,Contract> newContract,Boolean isUpdate)
    {
        List<Custom_Exception__c> excList = new List<Custom_Exception__c>();
        Map<Id,Double> OpprtcontractCount= new Map<Id,Double>();
        Set<Id> OpprtIds = new Set<Id>();
        if(isUpdate == true)
        {
            contractLst=validateToUpdateContractCount(oldContract,newContract);
        }
        for(Contract contr : contractLst )
        {
            /*if(contr.SBQQ__Opportunity__c != null )
            {
                OpprtIds.add(contr.SBQQ__Opportunity__c);
            }*/
        }
        if(null !=OpprtIds && OpprtIds.size() > 0 )
        {
            List<AggregateResult> agrResult = 
                [Select /*SBQQ__Opportunity__c,*/Count(Id) contractCount From Contract /*Where SBQQ__Opportunity__c IN :OpprtIds AND SBQQ__ActiveContract__c > 0 Group By SBQQ__Opportunity__c*/];
            
            for(AggregateResult ar : agrResult)
            {
                /*OpprtcontractCount.put((Id)ar.get('SBQQ__Opportunity__c'),(Decimal)ar.get('contractCount'));*/
            }
            List<Opportunity> OpprtList = [Select Id,CountofContracts__c From Opportunity Where Id IN :OpprtIds and RecordTypeId =:Utility_Informatics.opportunity_Informatics];
            for(Opportunity oprt : OpprtList)
            {
                if(OpprtcontractCount.containsKey(oprt.Id))
                {
                    oprt.CountofContracts__c= OpprtcontractCount.get(oprt.Id);
                }
                else
                {
                    oprt.CountofContracts__c=0;
                }
            }
            if(null != OpprtList && OpprtList.size() > 0 )
            {
                List<Database.SaveResult> results = Database.update(OpprtList, false);
                   for(Integer i=0; i < results.size(); i++) {
                if(!results.get(i).isSuccess()) {
                    Custom_Exception__c exc = new Custom_Exception__c();
                    exc.Exception_Messages__c = results.get(i).getErrors().get(0).getMessage();
                    exc.Job_Id__c = results.get(i).id;
                    excList.add(exc);
                }
            }
            if(excList.size() > 0)
            {
                insert excList;
            }
            }
        }
    }
    
    public static List<Contract> validateToUpdateContractCount(Map<id,Contract> oldContract,Map<Id,Contract> newContract)
    {
        List<Contract> contractToUpdate = new List<Contract>();
        for(Id contractId : oldContract.keySet())
        {
            /*if(oldContract.get(contractId).SBQQ__ActiveContract__c != newContract.get(contractId).SBQQ__ActiveContract__c)*/
            {
                contractToUpdate.add(newContract.get(contractId));
            }
        }
        return contractToUpdate;
        
    }
}
public class OpportunityLineItemRollupHandler {
    
    public static void updateRollupCount(List<OpportunityLineItem> opprtLineItemList,Map<Id,OpportunityLineItem> oldOpprtLine,Map<Id,OpportunityLineItem> newOpprtLine,Boolean isUpdate)
    {
        List<Custom_Exception__c> excList = new List<Custom_Exception__c>();
        Map<Id,Decimal> serviceProductCountMap = new Map<Id,Decimal>();
        Map<id,Decimal> renewalCountMap = new Map<Id,Decimal>();
        Map<Id,Decimal> renewalProdSumMap = new Map<Id,Decimal>();
        Set<Id> opportunityIdList = new Set<Id>();
        if(isUpdate == true)
        {
            opprtLineItemList=validateOpportunityLineItem(oldOpprtLine,newOpprtLine);
        }
        for(OpportunityLineItem oprtline : opprtLineItemList)
        {
            if(oprtline.OpportunityId != null )
            {
                opportunityIdList.add(oprtline.OpportunityId);
            }
        }
        if(null !=opportunityIdList && opportunityIdList.size() > 0)
        {
            List<AggregateResult> serviceCountAgrResult = 
                [Select OpportunityId,Count(Id) serviceCount From OpportunityLineItem Where OpportunityId IN :opportunityIdList /*AND fxLicenseType__c='Services' */ Group By OpportunityId];
            
            List<AggregateResult> renewalCountAgrResult = 
                [Select OpportunityId,Count(Id) renewalCount From OpportunityLineItem Where OpportunityId IN :opportunityIdList /*AND isRenewable__c=TRUE */ Group By OpportunityId];
            
            List<AggregateResult> renewalProdSumAgrResult=
                [Select OpportunityId,Sum(TotalPrice) renewalSum From OpportunityLineItem Where OpportunityId IN :opportunityIdList /*AND isRenewable__c=TRUE AND fxLicenseType__c!='Services' */ Group By OpportunityId];
            
            for(AggregateResult agr : serviceCountAgrResult )
            {
                serviceProductCountMap.put((Id)agr.get('OpportunityId'),(Decimal)agr.get('serviceCount'));   
            }
            for(AggregateResult agr : renewalCountAgrResult )
            {
                renewalCountMap.put((Id)agr.get('OpportunityId'),(Decimal)agr.get('renewalCount')); 
            }
            for(AggregateResult agr : renewalProdSumAgrResult )
            {
                renewalProdSumMap.put((Id)agr.get('OpportunityId'),(Decimal)agr.get('renewalSum'));  
            }
            List<Opportunity> opportList = [Select CountofServiceProducts__c,CountofRenewalProducts__c,SumofRenewalProducts__c From Opportunity Where Id IN : opportunityIdList and RecordTypeId =:Utility_Informatics.opportunity_Informatics];
            
            for(Opportunity opprt : opportList)
            {
                if(serviceProductCountMap.containsKey(opprt.Id))
                {
                    opprt.CountofServiceProducts__c=serviceProductCountMap.get(opprt.Id);
                }
                if(renewalCountMap.containsKey(opprt.Id))
                {
                    opprt.CountofRenewalProducts__c=renewalCountMap.get(opprt.Id);
                }
                if(renewalProdSumMap.containsKey(opprt.Id))
                {
                    opprt.SumofRenewalProducts__c=renewalProdSumMap.get(opprt.Id);
                }
            }
            
            if(null !=opportList && opportList.size() > 0 )
            {
                List<Database.SaveResult> results = Database.update(opportList, false);
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
    
    public static void updateRollupCountAfterDelete(List<OpportunityLineItem> opprtLineItemList){
        Map<id,Decimal> renewalCountMap = new Map<Id,Decimal>();
        Set<Id> opportunityIds = new Set<Id>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        if(opprtLineItemList != null && opprtLineItemList.size() > 0){
            for(OpportunityLineItem oprtline : opprtLineItemList) {
                //if(oprtline.isRenewable__c)
                {
                    if(renewalCountMap.containsKey(oprtline.OpportunityId)) {
                        Decimal oppLinteItemCount = renewalCountMap.get(oprtline.OpportunityId);
                        renewalCountMap.put(oprtline.OpportunityId, oppLinteItemCount + 1);
                    } else {
                        renewalCountMap.put(oprtline.OpportunityId, 1);
                    }
                }
            }
            
            List<Opportunity> opportList = [Select Id, CountofServiceProducts__c,CountofRenewalProducts__c,SumofRenewalProducts__c From Opportunity Where Id IN : renewalCountMap.keySet() and RecordTypeId =:Utility_Informatics.opportunity_Informatics];
            for(Opportunity opprt : opportList){
                if(renewalCountMap.containsKey(opprt.Id)) {
                    Opportunity updateOpp = new Opportunity();
                    updateOpp.Id = opprt.Id;
                    if(opprt.CountofRenewalProducts__c == null){
                        updateOpp.CountofRenewalProducts__c = 0;
                    } else {
                        updateOpp.CountofRenewalProducts__c = opprt.CountofRenewalProducts__c - renewalCountMap.get(opprt.Id);
                    }
                    system.debug('opprt.CountofRenewalProducts__c= '+opprt.CountofRenewalProducts__c);
                    opportunitiesToUpdate.add(updateOpp);
                }
            }

            if(!opportunitiesToUpdate.isEmpty()){
                try{
                    Update opportunitiesToUpdate;
                } catch(DMLException e){
                    String errorMessage = e.getMessage();
                    SFDC_LOG__c newLog = new SFDC_LOG__c();
                    newLog.Log_Type__c = 'CPQ Logs';
                    newLog.Message_Long__c = e.getMessage();
                    newLog.Running_User__c = UserInfo.getUserName();
                    newLog.Source_Name__c = 'Opportunity Line item rollup delete operation';
                    newLog.Source_Type__c = 'APEX';
                    insert newLog;
                }
                
            }
        }
    }

    public static List<OpportunityLineItem> validateOpportunityLineItem(Map<Id,OpportunityLineItem> oldOpprtLine,Map<Id,OpportunityLineItem> newOpprtLine)
    {
        List<OpportunityLineItem> opprtlineToUpdate = new List<OpportunityLineItem>();
        
        for(Id opprtLineId : oldOpprtLine.keySet())
        {
           /* if((oldOpprtLine.get(opprtLineId).isRenewable__c != newOpprtLine.get(opprtLineId).isRenewable__c) || (oldOpprtLine.get(opprtLineId).fxLicenseType__c != newOpprtLine.get(opprtLineId).fxLicenseType__c)) */
            {
                opprtlineToUpdate.add(newOpprtLine.get(opprtLineId));
            }
            
        }
        return opprtlineToUpdate;
    }
}
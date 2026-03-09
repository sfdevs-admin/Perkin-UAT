public class OpportunityOrderRollUpHandler {
    
    public static void updateOrderCount(List<Order> orderList,Map<Id,Order> oldOrder,Map<Id,Order> newOrder,Boolean isUpdate)
    {
        List<Custom_Exception__c> excList = new List<Custom_Exception__c>();
        Map<Id,Double> OpprtOrderCount = new Map<Id,Double>();
        Set<Id> OpportunityId = new Set<Id>();
        if(isUpdate == true)
        {
            orderList=validateToUpdateOrderCount(oldOrder,newOrder);
        }
        for(Order ord : orderList)
        {
            if(ord.OpportunityId != null)
            {
                OpportunityId.add(ord.OpportunityId);
            }
        }
        if(null != OpportunityId && OpportunityId.size() > 0)
        {
            List<AggregateResult> agrResult = 
                [Select OpportunityId,Count(Id) orderCount From Order Where OpportunityId IN :OpportunityId /* AND SBQQ__Contracted__c=true */ Group By OpportunityId];
            for(AggregateResult ar : agrResult)
            {
                OpprtOrderCount.put((Id)ar.get('OpportunityId'),(Decimal)ar.get('orderCount'));
            }
            List<Opportunity> OpprtList = [Select Id,CountofOrders__c From Opportunity Where Id IN :OpportunityId and RecordTypeId =:Utility_Informatics.opportunity_Informatics];
            for(Opportunity oprt : OpprtList)
            {
                if(OpprtOrderCount.containsKey(oprt.Id))
                {
                    oprt.CountofOrders__c= OpprtOrderCount.get(oprt.Id);
                }
                else
                {
                    oprt.CountofOrders__c=0;
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
    
    public static List<Order> validateToUpdateOrderCount(Map<Id,Order> oldOrder,Map<Id,Order> newOrder)
    {
        List<Order> orderToUpdate = new List<Order>();
        
        for(Id ordId : oldOrder.keySet())
        {
           /* if(oldOrder.get(ordId).SBQQ__Contracted__c !=newOrder.get(ordId).SBQQ__Contracted__c) */
            {
                orderToUpdate.add(newOrder.get(ordId));
            }
        }  
        return orderToUpdate;
    }    
    
}
public class OpportunityChildCountHandler {
    //private static boolean isOnce= true;
   
    
    public static void updateChildCount(List<Opportunity> opprtLst,Map<Id,Opportunity> oldOpprt,Map<Id,Opportunity> newOpprt,Boolean isUpdate)
    {
       /* if(isOnce == true)
        {
         isOnce=false;
*/
        System.debug('Opportunity child count called '+opprtLst );
        System.debug('Opportunity Child Count Is Update '+ isUpdate);
        List<Custom_Exception__c> excList = new List<Custom_Exception__c>();
        Map<Id,Decimal> parentChildCount = new Map<Id,Decimal>();
        List<Opportunity> OpprtToUpdate = new List<Opportunity>();
        Set<id> parentOpportId = new Set<Id>();
        if(isUpdate == true )
        {
            System.debug('Calling opportunity child count update validate');
            opprtLst=validateToUpdateOpportunityChildCount(oldOpprt,newOpprt);
        }
        for(Opportunity oprt : opprtLst)
        {
             System.debug('OpprtId '+oprt.Id+'ParentId '+oprt.Originating_Opportunity_INF__c);
            
            if(oprt.Originating_Opportunity_INF__c!=null ) {parentOpportId.add(oprt.Originating_Opportunity_INF__c);}
            
            
        }
        if(null != parentOpportId && parentOpportId.size() > 0 )
        {
        List<AggregateResult> agrResult = 
            [Select Originating_Opportunity_INF__c,Count(Id) childcount From Opportunity Where Originating_Opportunity_INF__c IN :parentOpportId Group by Originating_Opportunity_INF__c];
        
        for(AggregateResult ar : agrResult)
        {
            parentChildCount.put((Id)ar.get('Originating_Opportunity_INF__c'),(Decimal)ar.get('childcount'));
        }
        List<Opportunity> parentOpprtList = [Select Id,CountofChildOpps__c From Opportunity Where Id IN :parentOpportId and RecordTypeId =:Utility_Informatics.opportunity_Informatics];
        
        for(Opportunity oprt : parentOpprtList)
        {
            if(parentChildCount.containsKey(oprt.Id))
            {
                oprt.CountofChildOpps__c= parentChildCount.get(oprt.Id);
            }
            else
            {
                oprt.CountofChildOpps__c=0;
            }
        } 	
        if(null != parentOpprtList && parentOpprtList.size() > 0 )
        {
            List<Database.SaveResult> results = Database.update(parentOpprtList, false);
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
                try {
                    database.insert (excList, false);
                }
                catch(exception ex){
                    system.debug('exception message :' +ex.getMessage());
                    system.debug('exception line mumber :' +ex.getLineNumber());
                }
            }
        }
        }
  //      }
        
    }
    public static List<Opportunity> validateToUpdateOpportunityChildCount(Map<Id,Opportunity> oldOpprt,Map<Id,Opportunity> newOpprt)
    {
        List<Opportunity> opprtToAddChildCount= new List<Opportunity>();
        Set<Id> opprtIdLst = oldOpprt.keySet();
        for(Id oppId : opprtIdLst )
        {
            if(oldOpprt.get(oppId).Originating_Opportunity_INF__c == null && newOpprt.get(oppId).Originating_Opportunity_INF__c !=null) {opprtToAddChildCount.add(newOpprt.get(oppId));}
            
            else if(oldOpprt.get(oppId).Originating_Opportunity_INF__c != null && newOpprt.get(oppId).Originating_Opportunity_INF__c !=oldOpprt.get(oppId).Originating_Opportunity_INF__c && newOpprt.get(oppId).Originating_Opportunity_INF__c !=null)
            {
                opprtToAddChildCount.add(newOpprt.get(oppId));
                opprtToAddChildCount.add(oldOpprt.get(oppId));
            }
            else if(oldOpprt.get(oppId).Originating_Opportunity_INF__c != null && newOpprt.get(oppId).Originating_Opportunity_INF__c ==null) {opprtToAddChildCount.add(oldOpprt.get(oppId)); }
            
                
            
        }
        
        return opprtToAddChildCount;
    }
}
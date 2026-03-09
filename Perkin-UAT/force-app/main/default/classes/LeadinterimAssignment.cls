public class LeadinterimAssignment implements Database.Batchable<sobject>{
    
    Map<Id,List<Lead_Interim_Assignment__c>> LeadAssignment = new Map<Id,List<Lead_Interim_Assignment__c>>();
    
    List<Lead_Interim_Assignment__c> leadassignRecs = new List<Lead_Interim_Assignment__c>();
    List<Date> startdates = new List<Date>();
    List<Date> enddates = new List<Date>();
    List<Lead> leadsList = new List<Lead>();
    Set<Lead> leadToUpdate = new Set<Lead>();
    List<Lead> leadsListFinal = new List<Lead>();
    
    
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        String leadassignRecs = 'select Id,End_Date__c,Start_Date__c,Originial_Owner__c,Replacement_Owner__c from Lead_Interim_Assignment__c order by createddate desc';
        return Database.getQueryLocator(leadassignRecs);
    }
    
    public void execute(Database.BatchableContext BC,List<Lead_Interim_Assignment__c> scope)
    {
        system.debug('inside execute');
        for(Lead_Interim_Assignment__c l:scope)
        {
            if(!LeadAssignment.containsKey(l.Originial_Owner__c))
            {
                LeadAssignment.put(l.Originial_Owner__c,new List<Lead_Interim_Assignment__c> {l}); 
                 
            }
            else
            {
                LeadAssignment.get(l.Originial_Owner__c).add(l);
            }
            
            startdates.add(l.Start_Date__c);
            enddates.add(l.End_Date__c);
        }
        startdates.sort();
        enddates.sort();
        
        
        system.debug('LeadAssignment '+LeadAssignment);
        system.debug('min start date is '+startdates[0]+' and max end date is '+enddates[enddates.size()-1]);
        
        if(test.isRunningTest())
         leadsList = [select id,OwnerId,createddate from lead where DAY_ONLY(createddate) >=:startdates[0] and DAY_ONLY(createddate) <=:enddates[enddates.size()-1] ];
        else
        leadsList = [select id,OwnerId,createddate from lead where DAY_ONLY(createddate) >=:startdates[0] and DAY_ONLY(createddate) <=:enddates[enddates.size()-1] and OwnerId in :LeadAssignment.keySet()];
        if(leadsList.size()>0)
            system.debug('leads list '+leadsList);
        
        for(Lead ll : leadsList)
        {
            Date createddateDate = date.newinstance(ll.createddate.year(), ll.createddate.month(), ll.createddate.day());

            if(LeadAssignment.containsKey(ll.ownerId))
            {
                system.debug('inside loop 1 '+LeadAssignment.get(ll.ownerId));
                for(Lead_Interim_Assignment__c lia :LeadAssignment.get(ll.ownerId) )
                {
                    if(createddateDate>=lia.Start_Date__c && createddateDate<=lia.End_Date__c)
                    {
                        system.debug('Inside leadass '+lia);
                        ll.ownerId = lia.Replacement_Owner__c;
                        leadToUpdate.add(ll);   
                    }
                   
                }
                
                
            }
            
        }
        system.debug('leadToUpdate '+leadToUpdate);
        if(leadToUpdate.size()>0)
        {
            leadsListFinal.addAll(leadToUpdate);
            update leadsListFinal;
            system.debug('updated the leads');
        }
        
        
        
    }
    
    public  void finish(Database.BatchableContext BC)
    {
        
    }
    
}
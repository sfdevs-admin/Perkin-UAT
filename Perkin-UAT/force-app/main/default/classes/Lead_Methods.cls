/*
Change Log:
-----------------------------------------------------------------------------------------------------------------------
VERSION     AUTHOR          DATE            DETAIL                                            
-----------------------------------------------------------------------------------------------------------------------
01.0        Tony Tran       20-NOV-15       Initial Version, created to house methods for Lead triggers.
At current time, there is more than one Lead trigger.
Converted actionable code in LeadAge.apxt into Lead_Methods class methods
*/

public class Lead_Methods
{
    //These variables store Trigger.oldMap and Trigger.newMap, respectively
    Map<Id, Lead> oldLeadMap;
    Map<Id, Lead> newLeadMap;
    List <Lead> oldLeadsList;
    List <Lead> newLeadsList;
    public Map<ID,Lead> OldMap=new Map<ID,Lead>();
    public Map<ID,Lead> NewMap=new Map<ID,Lead>();
    public List<Lead> NewTrigger=new List<Lead>();
    public List<Lead> OldTrigger=new List<Lead>();
    public Boolean IsInsert;
    public Boolean IsAfter;
    public Boolean IsUpdate;
    public Boolean IsBefore;
    
    //Constructor
    public Lead_Methods (Map <Id, Lead> mapOfOldLeads, List<Lead> OldLeads, Map <Id, Lead> mapOfNewLeads, List<Lead> newLeads)
    {
        oldLeadMap = mapOfOldLeads;
        newLeadMap = mapOfNewLeads;
        oldLeadsList = oldLeads;
        newLeadsList = newLeads;
    }
    
    public void LeadMethods(Map<ID,Lead> oldmap,Map<ID,Lead> newmap,List<Lead> oldtrig,List<Lead> newtrig,Boolean isIns,Boolean isBef,Boolean isAft,Boolean isUpd) 
    {
        if(isUpd) {
            OldMap=oldmap.clone();
            NewMap=newmap.clone();
            NewTrigger.addAll(newtrig);
            OldTrigger.addAll(oldtrig);
        }
        if(isIns&&isAft) {
            NewMap=newmap.clone();
            NewTrigger.addAll(newtrig);
        }
        if(isIns&&isBef) {
            NewTrigger.addAll(newtrig);
        }        
        IsInsert = isIns;
        IsBefore=isBef;
        IsAfter=isAft;
        IsUpdate=isUpd;
    }
    
    public void MarkPrimaryContactRoleLead2Opportunity() 
    {
        System.debug('Is Convert Lead');
        Map<Id,Id> mapOfOppIdToContactId = new Map<Id,Id>();
        List<OpportunityContactRole> listOfConvertedOppContactRoletoUpdate = new List<OpportunityContactRole>();
        
        for(Lead l:NewTrigger)
        {
            if(l.RecordTypeId == Utility_Informatics.lead_Informatics && l.IsConverted 
               && l.ConvertedDate == System.today() && l.ConvertedOpportunityId!=NULL && l.ConvertedContactId!=NULL)
            {
                mapOfOppIdToContactId.put(l.ConvertedOpportunityId,l.ConvertedContactId);
            }
        }
        
        //Querying the Contact Role records under Opportunity after Lead conversion and if the Contact Id 
        //in the Contact Role record matches with the Contact Id
        //in the map for the same Opportunity Id, then the Contact Role will be marked as Primary.
        if(mapOfOppIdToContactId.size() > 0)
        {
            for(OpportunityContactRole oCRcon:[Select OpportunityId, IsPrimary, Id, ContactId From OpportunityContactRole where OpportunityId IN:mapOfOppIdToContactId.keySet()])                                  
            {
                if(oCRcon.ContactId == mapOfOppIdToContactId.get(oCRcon.OpportunityId))
                {
                    oCRcon.IsPrimary = true;
                    oCRcon.Role      = 'Decision Maker';
                    listOfConvertedOppContactRoletoUpdate.add(oCRcon);
                }
            }
            //DML Operation to update the existing Contact Role record under opportunity with Primary Contacts
            try
            {
                update listOfConvertedOppContactRoletoUpdate;
            } catch(DMLException e) {
                System.debug('>>> Error Updating OpportunityContactRole:'+e.getStackTraceString());
            }
        }
    }
    
    public void INFConcatFields() 
    {
        //looping and contacting the field
        for(Lead iterating_lead : NewTrigger){
            if(iterating_lead.RecordTypeID == Utility_Informatics.lead_Informatics){
                iterating_lead.INF_Lead_Assignment_Field__c = '';
                if(iterating_lead.Topic_INF__c != null)
                    iterating_lead.INF_Lead_Assignment_Field__c = iterating_lead.Topic_INF__c + ' - ';
                if(iterating_lead.BusinessLine_INF__c <> null)
                    iterating_lead.INF_Lead_Assignment_Field__c +=  iterating_lead.BusinessLine_INF__c + ' - ';
                if(iterating_lead.Product_Interest_INF__c <> null)
                    iterating_lead.INF_Lead_Assignment_Field__c += iterating_lead.Product_Interest_INF__c + ' - ';
                if(iterating_lead.Product_Family_INF__c <> null)
                    iterating_lead.INF_Lead_Assignment_Field__c += iterating_lead.Product_Family_INF__c;
            }
        }
    }
    
    public void runLeadAssignRule(){
        List<Id> lIds=new List<id>();
        For (lead l:NewTrigger){
            if (l.IsConverted==False && l.GBL_GBL_Eloqua_Owner__c == null && l.BE__c=='Dx'){
                lIds.add(l.Id);            
            }
        }
        //Checks wheather the Class previously Called or not
        if (AssignLeads.assignAlreadyCalled()==FALSE && !system.isBatch()){
            AssignLeads.assign(lIds);
        }
    }

    
    public void LeadEloquaAssign() {
        for(lead l:NewTrigger) {
            if(l.GBL_GBL_Eloqua_Owner__c!=null) {
                l.OwnerId=l.GBL_GBL_Eloqua_Owner__c;
            }
        }
    }
    
    public void LeadTopic(){
        for(Lead itrLd : NewTrigger){
            if(itrLd.RecordTypeID != Utility_Informatics.lead_Informatics){
                itrLd.Topic_INF__c='';
                itrLd.Topic_INF__c += itrLd.Company + '~' + itrLd.Product_Line__c + '~' + itrLd.PostalCode + '~';
            }
        }
    }
}
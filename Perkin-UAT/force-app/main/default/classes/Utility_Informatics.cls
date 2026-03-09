/***********************************************************
*Created By: Lister technologies
*Purpose: For Informatics,Utility class to supply Id and other values as static,making it 
*as reusable code and avoiding repeated queries.
************************************************************/
public with sharing class Utility_Informatics {
    //Boolean to Stop Re-execution of Renewals trigger
    public static Boolean isRenewed = false;
    //Static Variable to provide Recordtype Id for Informatics Opportunities within an execution, to avoid re-querying.
    public static Id opportunity_Informatics = [Select r.Id From RecordType r
                                                 where r.SobjectType='Opportunity' and r.DeveloperName='Informatics'].Id;


    //Static variable to provide the recordtype ID for Informatcis Leads within an execution, to avoid re-querying.
    public static Id lead_Informatics        = [Select r.Id From RecordType r
                                                 where r.SobjectType='Lead' and r.DeveloperName='Informatics'].Id;
    public static Id case_Informatics        = [Select r.Id From RecordType r
                                                 where r.SobjectType='Case' and r.DeveloperName='Informatics'].Id;
                                                 
                                                 
    @future
     public static void assignLeads_Informatics(List<Id> leads){
         list<lead> lead_ToBeUpdated = new list<Lead>();
          Database.DMLOptions dmo = new Database.DMLOptions();
          dmo.assignmentRuleHeader.useDefaultRule= true;
         for(lead iterating_lead: [SELECT Id,LastModifiedByID,Lead_Assignment__c,Lead_Auto_Assign__c,OwnerID FROM Lead WHERE Id IN: leads AND isConverted = FALSE]){ 
            iterating_lead.setOptions(dmo);
            lead_ToBeUpdated.add(iterating_lead);
         }
            AssignLeads.assignAlreadyCalled = TRUE;
            update lead_ToBeUpdated;
     }
}
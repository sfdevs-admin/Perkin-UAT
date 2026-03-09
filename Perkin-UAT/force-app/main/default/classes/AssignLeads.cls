/**********************************************************************************************************************
Name: AssignLeads 
Copyright © 2012 PerkinElmer | Salesforce Instance 
=======================================================================================================================
Purpose: This Class called by LeadAssign Trigger to Update the Leads.
         This auto assigns a lead to default assignment-rule under certain condition.
=======================================================================================================================
REQUIREMENT INFORMATION & DEVELOPMENT INFORMATION:                                                         
-----------------------------------------------------------------------------------------------------------------------
VERSION AUTHOR                DATE       DETAIL                                            
-----------------------------------------------------------------------------------------------------------------------
1.0     Prasannajeet Parida   31/08/2012 Initial Development - SF2SF   
2.0     Gopi Kishore          02/05/2013 Modification at line 31,37         
**********************************************************************************************************************/

public class AssignLeads{

  public static Boolean assignAlreadyCalled=FALSE;
  
  //Make a bookmark that This class is been called.
  public static boolean assignAlreadyCalled(){
        return assignAlreadyCalled;
  }
    
  @future
  public static void assign(List<Id> lIds)
  {
      assignAlreadyCalled = TRUE;
      
   
      //Get the ID values from the Custom-Settings.
      Map<String,Lead_Assign__c> pla = Lead_Assign__c.getAll(); 
      ID  NASalesLeadID;
      ID  SAPConnectorID;
      
      if(pla.containskey('NALeadID'))
        NASalesLeadID = pla.get('NALeadID').FieldID__c;

      if(pla.containskey('SAPConnector'))
        SAPConnectorID = pla.get('SAPConnector').FieldID__c;
    
      //modified by ttran to allow assignment rules to run for Pardot Non Qualified Leads
      //Original SOQL: List<Lead> leads=[SELECT Id,LastModifiedByID,Lead_Assignment__c,Lead_Auto_Assign__c,OwnerID FROM Lead WHERE Id IN: lIds];
      List<Lead> leads=[SELECT Id,BE__c,LastModifiedByID,Lead_Assignment__c,Lead_Auto_Assign__c,OwnerID, Non_Qualified__c,eq_Is_Eloqua_Lead__c,GBL_GBL_Eloqua_Owner__c FROM Lead WHERE Id IN: lIds];
      for(lead l:leads)
      {
          String strOwnerID = Id.valueof(l.OwnerID);
           
          //when the owner is "NA Inside Sales Lead Qualification Queue" and LastModified is "SAP Connector" and assigment rule is not assigned.
         // if(l.OwnerID == NASalesLeadID && l.LastModifiedByID == SAPConnectorID && l.Lead_Assignment__c == false && l.Lead_Auto_Assign__c == false)
         // && l.eq_Is_Eloqua_Lead__c==false 
          if(l.OwnerID == NASalesLeadID && l.LastModifiedByID == SAPConnectorID && l.Lead_Assignment__c == false && l.Lead_Auto_Assign__c == false && l.GBL_GBL_Eloqua_Owner__c==null)
          {
              System.debug('---True');
              Database.DMLOptions dmo = new Database.DMLOptions();
              dmo.assignmentRuleHeader.useDefaultRule= true;              
              l.setOptions(dmo);              
              // Make the AssignmentRule check-box checked.
              l.Lead_Assignment__c = true;
          }
          
          //modified by ttran to allow assignment rules to run for any Lead that is not owned by a queue, has the "Non Qualified" field set to TRUE
          // and the "Lead Auto Assign" field set to FALE
          //Lead_Assignment__c's field label is "Assign Rule"
          //Added the criteria && l.Lead_Auto_Assign__c == false as part of the Eloqua integration project
         // if(!strOwnerID.startsWithIgnoreCase('00G') && l.Non_Qualified__c == TRUE && l.Lead_Auto_Assign__c == false)
         // l.eq_Is_Eloqua_Lead__c==false && 
          System.debug('BE::' + l.BE__c + 'OWNER:' + strOwnerID + '::NONQ::' + l.Non_Qualified__c + '::AUTO::' + l.Lead_Auto_Assign__c + '::ELQ::' + l.GBL_GBL_Eloqua_Owner__c);
          if(!strOwnerID.startsWithIgnoreCase('00G') && l.Non_Qualified__c == TRUE && l.Lead_Auto_Assign__c == false && l.GBL_GBL_Eloqua_Owner__c==null)
          {
              System.debug('>>>Encountered a Non-Qualified Lead owned by ' + l.OwnerId);
              Database.DMLOptions dmo = new Database.DMLOptions();
              dmo.assignmentRuleHeader.useDefaultRule= true;              
              l.setOptions(dmo);              
              // Make the AssignmentRule check-box checked.
              l.Lead_Assignment__c = true;
          }
          else
              System.debug('---False ' + l.ownerID);
      }
      
      If(!test.isRunningTest())
          update(leads);
  } 
  
}
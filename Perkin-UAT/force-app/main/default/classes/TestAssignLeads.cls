/**********************************************************************************************************************
Name: AssignLeads 
Copyright © 2012 PerkinElmer | Salesforce Instance 
=======================================================================================================================
Purpose: This Test Class is used to Code Coverage of AssignLeads Class & LeadAssign Trigger 
=======================================================================================================================
REQUIREMENT INFORMATION & DEVELOPMENT INFORMATION:                                                         
-----------------------------------------------------------------------------------------------------------------------
VERSION AUTHOR                DATE       DETAIL                                            
-----------------------------------------------------------------------------------------------------------------------
1.0     Prasannajeet Parida   31/08/2012 Initial Development - SF2SF                       
**********************************************************************************************************************/
@isTest /*(seeallData = true)*/
private class TestAssignLeads  
{
  static testMethod void TestAssignLeads ()
  {   
      SAI_Lead_Routing_Values__c cc =new SAI_Lead_Routing_Values__c();
      cc.SAI_Values__c = 'Applied Genomics, Maternal Fetal Health, Newborn Screening';
      insert cc;
      
      User testUser =createStandardUser(11);
      
      list<id> lds = new list<id>(); 
   // Query the database for the users.
    //  User testUser1 = [SELECT Id, Name FROM User WHERE IsActive=true  LIMIT 1];
   
      Database.DMLOptions dmo = new Database.DMLOptions();
      dmo.assignmentRuleHeader.useDefaultRule= true;   
     
      List<lead> leadinsert = new List<lead>();
      
      Lead le = new Lead();
      le.OwnerID = '00G300000011qzN';
      le.LastModifiedByID ='00530000000k8mj';
      le.Lead_Assignment__c =false;
      le.eq_Is_Eloqua_Lead__c=false;
      le.GBL_GBL_Eloqua_Owner__c=null;
      le.email = 'test@tttt.com';
      le.LastName = 'Test Namet';
      le.Company = 'Test Companyt';
      le.Country = '91';
      leadinsert.add(le);
      
      Lead varnew = new Lead();
      varnew.email = 'test@ttt.com';
      varnew.LastName = 'Test Name';
      varnew.Company = 'Test Company';
      varnew.Country = '91';
      //varnew.LastModifiedByid = testUser1.id;
   //Check the assignRulle check-box is checked or not
      if(varnew.Lead_Assignment__c == false)
          varnew.Lead_Assignment__c = true;      
      varnew.setOptions(dmo); 
      leadinsert.add(varnew);
   //that of trigger rather than test.
      test.startTest(); 
      //insert to Custom-settings Object
      List<Lead_Assign__c> LeaCusList = new List<Lead_Assign__c>();
      Lead_Assign__c LeaCusSet = new Lead_Assign__c();
      LeaCusSet.name = 'Test Name';
      LeaCusSet.FieldID__c='Test Case';
     
      LeaCusList.add(LeaCusSet);
     Lead_Assign__c LeaCusSet1 = new Lead_Assign__c();
      LeaCusSet1.name = 'NALeadID';
      LeaCusSet1.FieldID__c='00G300000011qzN';
      LeaCusList.add(LeaCusSet1);
      
      Lead_Assign__c LeaCusSet11 = new Lead_Assign__c();
      LeaCusSet11.name = 'SAPConnector';
      LeaCusSet11.FieldID__c=testUser.Id;
      LeaCusList.add(LeaCusSet11);
      
      insert LeaCusList;
    
   //Upsert to Lead records that cause the trigger to execute. 
   //
      system.runAs(testUser) {
           try{  
      insert leadinsert; 
      }
    
    catch(Exception e){}
      }
       
   List<Lead> leadList = [SELECT Id,lastModifiedbyid,OwnerId from Lead];
       system.debug('**** leadList - '+leadList);
   //Stop the test, this changes limit context back to test from trigger.
     test.stopTest();
    
    lds.add(varnew.id);
    lds.add(le.id);
    AssignLeads a=new AssignLeads();
    AssignLeads.assign(lds);
    
    AssignLeads.assignAlreadyCalled();
    
  }
    
    static user createStandardUser(Integer randNo) {
                    User standardUser = new User();
        System.runAs(new User(Id=userinfo.getUserId()))
        {

            standardUser.FirstName = 'Test';
            standardUser.LastName = 'test User ' + randNo;
            standardUser.Email = 'test_user11' + randNo + '@pkedev.test.com';
            standardUser.Alias = 'test' + randNo;
            standardUser.Username = standardUser.Email;
            standardUser.CommunityNickname = 'standard'+randNo;
            standardUser.TimeZoneSidKey = 'America/Chicago';
            standardUser.LocaleSidKey = 'en_US';
            standardUser.EmailEncodingKey = 'ISO-8859-1';
            standardUser.LanguageLocaleKey = 'en_US'; 
            standardUser.IsActive = true;
            standardUser.ProfileId = [ SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
            
            INSERT standardUser;
           
            //System.assert(standardUser.Id != null , 'Test standard user creation failed.');
        }
         return standardUser;
    }
    
}
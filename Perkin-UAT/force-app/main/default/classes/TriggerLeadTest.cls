/******************************************************************************
 * Name:        TriggerLeadTest
 * 
 * Purpose:     Tests against the TriggerLead Class, LeadBefore & LeadAfter Triggers
 *              and provides code coverage.
 *              
 * @Author:     Abdul Sattar (Magnet 360)
 * @Date:       01.19.2015
 * 
 * @Updates:
 *
 * 09.02.2015   Abdul Sattar (Magnet 360)
 *              Added test code for TriggerLead.overrideDuplicateErrorFromSF(LIST newLeads)
 */
@isTest
private class TriggerLeadTest {
/*
    public static UserRole pardotRole;              // Test Pardot Admin role.
    public static User pardotUser;                  // Test Pardot API user.
    public static User standardUser;                // Test Standard user.
    public static List<Lead> testLeads;             // Test Leads
    public static Id informaticsRecordTypeId;       // Informatics record type Id.
    
    public static String randNo = String.valueOf(Crypto.getRandomInteger());    // Random no. string

    // Test method
    static testMethod void testoverrideDuplicateError() {
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            // Create test data
            createTestLeads();

            Test.startTest();
                // Create a clone of firs lead and insert
                Lead cloneLead = testLeads[0].clone();
                try {
                    INSERT cloneLead;
                }
                catch (System.DmlException e) {
                        String errMsg = e.getMessage();
                        System.assert(errMsg.contains('This record is a duplicate and should not be updated.'),'Unable to allow duplication.');
                }
                
                try {
                    // Try to update clone
                    UPDATE cloneLead;       
                }
                catch (System.DmlException e) {
                    String errMsg = e.getMessage();
                    System.assert(errMsg.contains('This record is a duplicate and should not be updated.'),'Unable to determine duplication.');
                }
            Test.stopTest();
        }
    }
    
    // Test method
    static testMethod void testInterceptLeadUpdatesFromSF() {
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            // Create test data
            createTestLeads();

            // Set first lead as Synced
            testLeads[0].Synced__c = TRUE;
            UPDATE testLeads[0];

            Test.startTest();
                try {
                    // Try to update second
                    UPDATE testLeads[1];        
                }
                catch (System.DmlException e) {
                    String errMsg = e.getMessage();
                    System.assert(errMsg.contains('This record is a duplicate and should not be updated.'),'Unable to determine duplication.');
                }
            Test.stopTest();
        }
    }
    
    // Test method
    static testMethod void testInterceptLeadUpdates() {
        
        // Create test role & users
        createPardotRole(); 
        createPardotUser();
        createStandardUser();
        
        // Create custom settings
        Pardot_Settings__c psc = new Pardot_Settings__c(Name='Default', Default_Lead_Owner_ID__c = pardotUser.Id);
        INSERT psc;
        
        // Create test leads with standard user
        System.runAs(standardUser) {
            createTestLeads();

            // Change owner on first lead
            testLeads[0].OwnerId = pardotUser.Id;
            UPDATE testLeads[0];

            // Update second lead to make it last modified
            UPDATE testLeads[1];
        }
       
        System.runAs(pardotUser) {
        Test.startTest();
            // Emulate an update from Pardot - updating first lead
            testLeads[0].Requested_Interests__c = 'Interested';
            UPDATE testLeads[0];
        Test.stopTest();
        }

        // Aserts ???
    }
    
    // Test method
    static testMethod void testIsPardotCall() {
        Boolean isPardotCall;
        
        // Create test data
        createPardotRole(); 
        createPardotUser();
        
        Test.startTest();
        System.runAs(pardotUser) {
            isPardotCall = TriggerLead.isPardotCall();
        }
        Test.stopTest();
        System.assertEquals(true, isPardotCall, 'Unable to determine that it is an Pardot API user or not.');
    }
    
    // Test method
    //
    //static testMethod void testSetLeadAutoAssign() {

    //    createStandardUser();   // Create standard user.
        
    //    System.runAs(standardUser) {
    //        Test.startTest();
    //            createTestLeads();  // Create test leads
    //        Test.stopTest();
            
            // Query database to get updated values
    //        List<Lead> updatedLeads = [SELECT Id,RecordTypeId,Status, Lead_Auto_Assign__c FROM Lead];
             
            // All new leads.
     //       for (Lead l : updatedLeads) {
     //           if( informaticsRecordTypeId != null && l.RecordTypeId != null && 
     //              l.RecordTypeId == informaticsRecordTypeId && l.Status == 'Working')
     //               System.assertEquals(false, l.Lead_Auto_Assign__c, 'Lead Auto Assign is not correct for Working Informatics Lead.');
     //           else
     //               System.assertEquals(true, l.Lead_Auto_Assign__c, 'Lead Auto Assign is not correct for other lead.');
     //       }
     //   }
        
    //}
    
    // Test method
    static testMethod void testSetCreateDateOnStatusChagneTest() {

        DateTime dT = System.now();
        Date currentDate = Date.newinstance(dT.year(), dT.month(), dT.day());
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            createTestLeads();      // Create test leads
            
            Lead testWorkingLead;

            for (Lead l : testLeads) {
                if (l.Status == 'Working'){
                    l.Status = 'Open';
                    testWorkingLead = l;
                }
            }

            Test.startTest();
                    UPDATE testLeads;
            Test.stopTest();
            
            // Query database to get updated values
            //List<Lead> updatedLeads = [SELECT Id, LastName, Create_Date__c,Status FROM Lead WHERE Id = :testWorkingLead.Id];
            
            //for (Lead l : updatedLeads)
            //       System.assertEquals(currentDate,Date.newInstance(l.Create_Date__c.year(), l.Create_Date__c.month(), l.Create_Date__c.day()), 'Created date is not same to current date.' + l.LastName);
        }
    }
    
    // Test method
    static testMethod void testCreateLeadAgingTrack() {
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            createTestLeads();  // Create test leads
            
            // Change all Non-Open leads back to Open status.
            for (Lead l : testLeads) {
                if (l.Status != 'Open')
                    l.Status = 'Open';
            }
            
            Test.startTest();
            // Update leads to force Lead After Update trigger.
            try {
                update testLeads;       
            }
            catch (System.DmlException e) {
                System.assert(false, 'Unable to update leads for Lead Aging Track test.');
            } 
            
            Test.stopTest();
            
            // Query database to get inserted lead aging tracks.
            List<Lead_Agei__c> leadAgingTracks  = [SELECT Id FROM Lead_Agei__c WHERE Lead__c IN :testLeads];
            
            System.assert(leadAgingTracks.size() > 0, 'Unable to create lead aging tracks.');
        }
    }
    
    // Test method
    static testMethod void testCreateLeadInterestTrack() {
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            createTestLeads();  // Create test leads
            
            // Change interest tracks on leads.
            for (Lead l : testLeads) {
                l.Primary_Interest__c = 'Primary Interest';
                l.Secondary_Interest__c = 'Secondary Interest';
                l.Product_Interests__c = 'Product Intrests';
            }
            
            Test.startTest();
            // Update leads to force Lead After Update trigger.
            try {
                update testLeads;
            }
            catch (System.DmlException e) {
                System.assert(false, 'Unable to update leads for Lead Aging Track test.');
            } 
            
            Test.stopTest();
            
            // Query database to get inserted lead aging tracks.
            //List<Lead_Interest_Track__c> leadInterestTrack  = [SELECT Id FROM Lead_Interest_Track__c WHERE Lead__c IN :testLeads];
            
            //System.assert(leadInterestTrack.size() > 0, 'Unable to create lead interest tracks.');
        }
    }
    
    // Test method
    static testMethod void testCreateFormsQualificationHistory() {
        createStandardUser();   // Create standard user.
        
        System.runAs(standardUser) {
            createTestLeads();  // Create test leads
            
            // Change interest tracks on leads.
            for (Lead l : testLeads) {
                l.Primary_Qualification__c = 'Test Primary Qualification';
                l.Secondary_Qualification__c = 'Test Secondary Qualification';
                l.Requested_Interests__c = 'Test Requested Qualification';
            }
            
            Test.startTest();
            // Update leads to force Lead After Update trigger.
            try {
                update testLeads;
            }
            catch (System.DmlException e) {
                System.assert(false, 'Unable to update leads for Forms Qualification History creation test.' + e.getMessage());
            } 
            
            Test.stopTest();
            
            // Query database to get inserted records
            //List<Form_Qualification_History__c> fqhs  = [SELECT Id FROM Form_Qualification_History__c WHERE Corresponding_Lead__c IN :testLeads];
            
            //System.assert(fqhs.size() > 0, 'Unable to create Forms Qualification History records.');
        }
    }
    
    // ------------------------------------------------------------------------------------------
    // Test helper methods.
    // ------------------------------------------------------------------------------------------
    //
    
    // Create test data
    static void createTestLeads() {
        
        System.runAs(new User(Id=Userinfo.getUserId())){
            // Create test Leads.
            testLeads = new List<Lead>();
            
            Lead l1 = new Lead ();
            l1.FirstName        = 'Test ';
            l1.LastName         = 'Lead 1 ' + randNo;
            l1.Status           = 'Open';
            l1.Company          = 'Test Lead Company';
            l1.Email            = 'testemail@emailtest.com';
            l1.Status           = 'Open';
            l1.Completion_Action_Product__c='Completion_Action_Product__c';
            l1.IGOR_PAC__c='IGOR_PAC__c abc';
            l1.LeadSource       = 'Other';
            l1.Create_Date__c   = Date.today().addDays(-10);
            l1.Requested_Interests__c = 'No Interest';
            l1.pi__url__c       = 'http://pi.pardot.test.com/prospect/read?id=0000001';
            testLeads.add(l1);
            
            Lead l2 = new Lead ();
            l2.FirstName        = 'Test ';
            l2.LastName         = 'Lead 2 ' + randNo;
            l2.Status           = 'Open';
            l2.Company          = 'Test Lead Company';
            l2.Email            = 'testemail@emailtest.com';//'testemail2' + randNo + '@emailtest.com';
            l2.Status           = 'Open';
            l2.Completion_Action_Product__c='Completion_Action_Product__c';
            l2.IGOR_PAC__c      ='IGOR_PAC__c abc';
            l2.LeadSource       = 'Other';
            l2.Create_Date__c   = Date.today().addDays(-20);
            l2.Requested_Interests__c = 'No Interest';
            l2.pi__url__c       = 'http://pi.pardot.test.com/prospect/read?id=0000002';
            testLeads.add(l2);
            
            // Craete a test lead for set Auto Assign test.
            // Get the record type id for Informatics.
            informaticsRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Informatics' LIMIT 1].Id;
            
            Lead l3 = new Lead();
            l3.FirstName        = 'Test ';
            l3.LastName         = 'Lead 3 ' + randNo;
            l3.Status           = 'Working';
            l3.Company          = 'Test Lead Company';
            l3.Email            = 'testemail@emailtest.com';
            l3.Completion_Action_Product__c='Completion_Action_Product__c';
            l3.IGOR_PAC__c      ='IGOR_PAC__c abc';
            l3.Status           = 'Working';
            l3.LeadSource       = 'Other';
            l3.Create_Date__c   = Date.today().addDays(-20);
            l3.Requested_Interests__c = 'No Interest';
            
            // l3.pi__url__c        = 'http://pi.pardot.test.com/prospect/read?id=0000003';
            testLeads.add(l3);
            
            // Insert leads.
            try {
                insert testLeads;           
            }
            catch (System.DmlException e) {
                System.Assert(false, 'Test leads creation failed.' + e.getMessage());
            }
        }
        
    }
    
    static void createPardotRole() {
        System.runAs(new User(Id=userinfo.getUserId()))
        {
            pardotRole = new UserRole();
            pardotRole.Name = Label.Pardot_User_Role;
            
            INSERT pardotRole;
            System.assert(pardotRole.Id != null , 'Test user role creation failed.');
        }
    }
    
    static void createPardotUser() {
        System.runAs(new User(Id=userinfo.getUserId()))
        {
            pardotUser = new User();
            pardotUser.FirstName = 'Test';
            pardotUser.LastName = 'User ' + randNo;
            pardotUser.Email = 'noemail' + randNo + '@pkedev.test.com';
            pardotUser.Alias = randNo.substring( 0, 5 );
            pardotUser.Username = pardotUser.Email;
            pardotUser.CommunityNickname = 'pardot'+randNo;
            pardotUser.TimeZoneSidKey = 'America/Chicago';
            pardotUser.LocaleSidKey = 'en_US';
            pardotUser.EmailEncodingKey = 'ISO-8859-1';
            pardotUser.LanguageLocaleKey = 'en_US';
            pardotUser.IsActive = true;
            pardotUser.UserRoleId = [select Id from UserRole where name= :Label.Pardot_User_Role limit 1].Id;
            pardotUser.ProfileId = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            
            insert pardotUser;
            System.assert(pardotUser.Id != null , 'Test user creation failed.');
        }
    }

    static void createStandardUser() {
        System.runAs(new User(Id=userinfo.getUserId()))
        {
            standardUser = new User();
            standardUser.FirstName = 'Test';
            standardUser.LastName = 'Standard User ' + randNo;
            standardUser.Email = 'standard_user11' + randNo + '@pkedev.test.com';
            standardUser.Alias = randNo.substring( 0, 5 );
            standardUser.Username = standardUser.Email;
            standardUser.CommunityNickname = 'standard'+randNo;
            standardUser.TimeZoneSidKey = 'America/Chicago';
            standardUser.LocaleSidKey = 'en_US';
            standardUser.EmailEncodingKey = 'ISO-8859-1';
            standardUser.LanguageLocaleKey = 'en_US';
            standardUser.IsActive = true;
            standardUser.ProfileId = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            
            INSERT standardUser;
            System.assert(standardUser.Id != null , 'Test standard user creation failed.');
        }
    }
    */
}
/******************************************************************************
 * Name:        TriggerContactTest
 * 
 * Purpose:     Tests against the TriggerContact Class & ContactBefore Trigger
 *              and provides code coverage.
 *              
 * @Author:     Abdul Sattar (Magnet360)
 * @Date:       01.09.2015
 * 
 * @Updates:
 */
@isTest
private class TriggerContactTest {
/*
    public static UserRole pardotRole;      // Test Pardot Admin role.
    public static User pardotUser;          // Test Pardot API user.
    public static User standardUser;        // Test Standard user.
    public static List<Contact> testCts;    // Test Contact
    public static List<Lead> testLeads;     // Test Leads

    public static String randNo = String.valueOf(Crypto.getRandomInteger());    // Random no. string

    // Test method against TriggerContact.interceptContactUpdates
    static testMethod void interceptContactUpdatesTest() {
        // Populate custom settings - Contact to Lead Mapping
        List<ContactToLeadMappings__c> ctolMappings = new List<ContactToLeadMappings__c>();

        ctolMappings.add( new ContactToLeadMappings__c(Name = 'FirstName', Lead_Field__c = 'FirstName') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'LastName', Lead_Field__c = 'LastName') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'CurrencyIsoCode', Lead_Field__c = 'CurrencyIsoCode') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Email', Lead_Field__c = 'Email') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Completion_Action_Product__c', Lead_Field__c = 'Completion_Action_Product__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'IGOR_PAC__c', Lead_Field__c = 'IGOR_PAC__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'New_Create_Date__c', Lead_Field__c = 'Create_Date__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Primary_Qualification__c', Lead_Field__c = 'Primary_Qualification__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Requested_Interests__c', Lead_Field__c = 'Requested_Interests__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Salutation', Lead_Field__c = 'Salutation') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Synced__c', Lead_Field__c = 'Synced__c') );
        ctolMappings.add( new ContactToLeadMappings__c(Name = 'Account_Description__c', Lead_Field__c = 'Company') );
        INSERT ctolMappings;
        
        // Create test role & users
        createPardotRole(); 
        createPardotUser();
        createStandardUser();
        
        
        // Create test leads with standard user
        System.runAs(standardUser) {
            createTestLeads();
            createTestContacts();

            // Change owner on first contact
            testCts[0].OwnerId = pardotUser.Id;
            UPDATE testCts[0];
            
            // Update second lead to make it last modified
            UPDATE testLeads[1];
        }
       
        System.runAs(pardotUser) {
        Test.startTest();
            // Emulate an update from Pardot - updating first contact
            testCts[0].Requested_Interests__c = 'Interested';
            UPDATE testCts[0];
        Test.stopTest();
        }

        // Asserts???
    }


    // Test method against TriggerContact.isPardotCall()
    static testMethod void testIsPardotCall() {
        Boolean isPardotCall;
        
        // Create test data
        createPardotRole(); 
        createPardotUser();
        
        Test.startTest();
        System.runAs(pardotUser) {
            isPardotCall = TriggerContact.isPardotCall();
        }
        Test.stopTest();
        System.assertEquals(true, isPardotCall, 'Unable to determine that it is an Pardot API user or not.');
    }

    // ------------------------------------------------------------------------------------------
    // Test helper methods.
    // ------------------------------------------------------------------------------------------
    //
    
    // Create test contacts
    static void createTestContacts() {
     
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Account act = new Account();
                act.Name = 'Test Account ' + randNo;
            
            insert act;
            System.assert(act.Id != null , 'Test account creation failed.');

            // Create test contacts.
            testCts = new List<Contact>();

            Contact ct1 = new Contact ();
                ct1.FirstName   = 'Test ';
                ct1.LastName    = 'Contact 1 ' + randNo;
                ct1.AccountId   = act.Id;
                ct1.pi__url__c  = 'http://pi.pardot.test.com/prospect/read?id=0000001';
                ct1.Email           = 'testemail@emailtest.com';
                ct1.Completion_Action_Product__c='Completion_Action_Product__c';
                ct1.IGOR_PAC__c='IGOR_PAC__c abc';

                testCts.add(ct1);

            Contact ct2 = new Contact ();
                ct2.FirstName   = 'Test ';
                ct2.LastName    = 'Contact 2 ' + randNo;
                ct2.AccountId   = act.Id;
                ct2.pi__url__c  = 'http://pi.pardot.test.com/prospect/read?id=0000002';
                ct2.Email           = 'testemail@emailtest.com';
                ct2.Completion_Action_Product__c='Completion_Action_Product__c';
                ct2.IGOR_PAC__c='IGOR_PAC__c abc';

                testCts.add(ct2);

            // Insert contacts.
            try {
                insert testCts;         
            }
            catch (System.DmlException e) {
                System.Assert(false, 'Test contacts creation failed.');
            }
        }
    }

    // Create test Leads.
    static void createTestLeads() {
        
        System.runAs(new User(Id=Userinfo.getUserId())){

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
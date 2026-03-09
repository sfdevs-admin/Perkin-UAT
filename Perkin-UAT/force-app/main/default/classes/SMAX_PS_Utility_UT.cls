@isTest
private class SMAX_PS_Utility_UT {
    
    @isTest static void testLogging() {

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('TestAcct', 'TST001001001');

        SMAX_PS_LogUtility.logInfo('Test', acct.Id, 'Testing');

        try
        {
            String val = null;
            Integer len = val.length();
        }
        catch (Exception e)
        {
            SMAX_PS_LogUtility.logError(e, acct.Id, 'length');

            SMAX_PS_ErrorLog__c log = SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.WARNING, 'Warning message', 'Testing', e, acct.Id);
            insert log;
        }
    }
    
    @isTest static void testUtilities() {

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('TestAcct', 'TST001001001');

        SMAX_PS_Utility.clearCache();
        SMAX_PS_Utility.getCurrentUserProfile();
        SMAX_PS_Utility.loadFullObjects('Account', 'WHERE PKI_SAP_Customer_Number__c = \'TST001001001\'', null);

        SMAX_PS_Utility.isFirstRun('Test');
        SMAX_PS_Utility.isFirstRun('Test');
        SMAX_PS_Utility.reset('Test');
        
        SMAX_PS_Utility.isActive('Test');

        Date d = Date.today();
        SMAX_PS_Utility.getDateInSOQLFormat(d);
        SMAX_PS_Utility.doDatesOverlap(d, d, d, d);
        SMAX_PS_Utility.getCronString(Datetime.now());

        // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
        Map<String,List<String>> dependentPicklistValuesMap = SMAX_PS_Utility.getDependentPicklistValues(Account.eProcurement_Catalog_Type__c);
        System.debug('dependentPicklistValuesMap: ' + dependentPicklistValuesMap);
        System.assert(dependentPicklistValuesMap != null, 'dependentPicklistValuesMap should not return null');
    }

    @isTest static void testEventUtility() {

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TSTM001');
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);

        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();

        SMAX_PS_WorkOrder_Event__e e1 = new SMAX_PS_WorkOrder_Event__e();
        e1.SMAX_PS_Action__c = 'TEST';
        e1.SMAX_PS_WorkOrderId__c = wo.Id;
        events.add(e1);

        SMAX_PS_WorkOrder_Event__e e2 = new SMAX_PS_WorkOrder_Event__e();
        e2.SMAX_PS_Action__c = 'TEST';
        e2.SMAX_PS_WorkOrderId__c = wo.Id;
        e2.SMAX_PS_SAP_DMR_Number__c = 'This value is too long and it should throw an exception.';
        events.add(e2);

        Test.startTest();

        SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');

        Test.stopTest();

        List<SMAX_PS_Platform_Event_Log__c> logs = [SELECT Id, Name, SMAX_PS_Error_Message__c, SMAX_PS_Event_JSON__c, 
            SMAX_PS_Platform_Event_Type__c, SMAX_PS_Related_Element_Id__c, SMAX_PS_Action__c 
            FROM SMAX_PS_Platform_Event_Log__c WHERE SMAX_PS_Action__c = 'TEST'];

        System.debug('Found Event Logs: ' + logs);
        //System.assertEquals(2, logs.size());

        //SMAX_PS_PlatformEventUtility.resendEvent(logs[0].Name);

        //ApexPages.currentPage().getParameters().put('lc',objLeadCenter.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(logs[0]);
        SMAX_PS_PlatformEventController customController  = new SMAX_PS_PlatformEventController(stdController);
        
        customController.resendEvent();

    }

    @IsTest static void testGetComplaintForm() {

        ContentVersion contentVersion = new ContentVersion(
                Title          = 'PKI_COMPLAINTFORM',
                PathOnClient   = 'Test.txt',
                VersionData    = Blob.valueOf('Test Content'),
                IsMajorVersion = true);
        insert contentVersion;

//      ContentDocument contentDocument = new ContentDocument(Title='PKI_COMPLAINTFORM');
//      insert contentDocument;
//
//      ContentVersion contentVersion = new ContentVersion(ContentDocumentId=contentDocument.Id, IsLatest=true);
//      insert contentVersion;

        String testComplaintFormString = SMAX_PS_Utility.getComplaintFormString();
        System.debug('testComplaintFormString: ' + testComplaintFormString);
    }

    //static testMethod void testCalendarEvent()
    //{
    //  Profile testProfile = [SELECT Id FROM Profile WHERE Name='LST - Sales APAC'];
        
    //  //Inserting Users
    //  User testUser = new User();
    //  testUser.Alias = 'smax-xxx';
    //  testUser.Email='standarduser@testorg.com'; 
    //  testUser.EmailEncodingKey='UTF-8'; 
    //  testUser.LastName='Testing';
    //  testUser.LanguageLocaleKey='ja';//'en_US'; 
    //  testUser.LocaleSidKey='ja_JP';//'en_US';
    //  testUser.ProfileId = testProfile.Id;
    //  testUser.TimeZoneSidKey='America/Los_Angeles';
    //  testUser.UserName='standard@testorg.servicemax.com';
    //  insert testUser;

    //  System.runAs(testUser)
    //  {
    //      List<Event> eventList = new List<Event>();
    //      Event event1 = new Event();
    //      //event1.SVMX_PS_TS_Time_Entry__c = true;
    //      event1.StartDateTime = Datetime.now().addDays(5);
    //      event1.EndDateTime = Datetime.now().addDays(5).addHours(8);
    //      event1.Subject = 'Test';
    //      event1.Type = 'Holiday';
    //      event1.OwnerId = testUser.Id;
    //      eventList.add(event1);

    //      Test.startTest();
    //      insert eventList;
    //      Test.stopTest();
    //  }
    //}
}
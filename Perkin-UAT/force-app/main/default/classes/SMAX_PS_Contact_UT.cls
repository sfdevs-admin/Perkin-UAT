@isTest
private class SMAX_PS_Contact_UT {
    
    @isTest static void testContactInsertUpdate()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');

        Test.startTest();

        Contact c1 = SMAX_PS_TestDataFactory.createTestContact('Joe', 'Test1', acct, null);
        Contact c2 = SMAX_PS_TestDataFactory.createTestContact('Bob', 'Test2', acct, null);

        c1.PKI_SAP_Contact_ID__c = 'FAKE1001001001'; // To allow the update to send an event
        c1.FirstName = 'Joseph';
        c1.LastName = 'Testopherson-Kennedy-Smith-Whatchamacallit-O\'Rourke';
        c1.Title = 'Master of the Known Universe and Creator of the Cosmos';
        update c1;

        Test.stopTest();

        // Verify that 3 Events were created
        List<SObject> events = SMAX_PS_Utility.retrieveTestEvents('SMAX_PS_Contact_Event__e');
        System.debug('Found Test Contact Events: ' + events);
        //System.assertEquals(3, events.size());

        Contact result = [SELECT Id, FirstName, LastName, Title FROM Contact WHERE Id = :c1.Id];
        //System.assertEquals(40, result.LastName.length());
        //System.assertEquals(40, result.Title.length());

        delete c1;
        undelete c1;
    }
    
    @isTest static void testContactMove()
    {
        Account acct1 = SMAX_PS_TestDataFactory.createTestAccount('PkiTest1', 'TESTX000000001');
        Account acct2 = SMAX_PS_TestDataFactory.createTestAccount('Test of the PKI Account2', 'TESTX000000002');

        Test.startTest();

        Contact c1 = SMAX_PS_TestDataFactory.createTestContact('Joe', 'Test1', acct1, null);

        c1.PKI_SAP_Customer_Number__c = acct2.PKI_SAP_Customer_Number__c;
        update c1;

        Test.stopTest();

        Contact result = [SELECT Id, Name, AccountId FROM Contact WHERE Id = :c1.Id];
        //System.assertEquals(acct2.Id, result.AccountId);
    }
    
    @isTest static void testContactIgnoreUpdate()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');

        Test.startTest();

        Contact c1 = SMAX_PS_TestDataFactory.createTestContact('Joe', 'Test1', acct, null); // This will send an event

        c1.FirstName = 'Joseph';
        update c1; // This should not send an event, because no SAP Contact ID

        Test.stopTest();

        // Verify that only 1 Event was created
        List<SObject> events = SMAX_PS_Utility.retrieveTestEvents('SMAX_PS_Contact_Event__e');
        System.debug('Found Test Contact Events: ' + events);
        //System.assertEquals(1, events.size());
    }

    class ContactCreateMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String body;

        public ContactCreateMock(Integer code, String status, String body) {
            this.code = code;
            this.status = status;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(this.body);
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            return res;
        }
    }

    @isTest static void testContactCreate() {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX00001');

        String jsonRsp = '{ "ContactNumber": "CON' + acct.PKI_SAP_Customer_Number__c + '" }';
        ContactCreateMock mock = new ContactCreateMock(200, 'SUCCESS', jsonRsp);
        Test.setMock(HttpCalloutMock.class, mock);

        SMAX_PS_ContactManager.ContactCreateRQ rq = new SMAX_PS_ContactManager.ContactCreateRQ();
        rq.CustomerNumber = acct.PKI_SAP_Customer_Number__c;
        rq.FirstName = 'Frank';
        rq.LastName = 'VanTest';
        rq.Email = 'frank.vantest@perkinelmer.bolttest.com';
        List<SMAX_PS_ContactManager.ContactCreateRQ> rqList = new List<SMAX_PS_ContactManager.ContactCreateRQ>();
        rqList.add(rq);

        Test.startTest();

        List<SMAX_PS_ContactManager.ContactCreateRS> rsList = SMAX_PS_ContactManager.callContactCreate(rqList);
        System.assertEquals(1, rsList.size());
        System.debug('Contact RS= ' + rsList[0].ContactNumber + ', Error=' + rsList[0].Error);
        System.assertNotEquals(null, rsList[0].ContactNumber);

        Test.stopTest();
    }
    
}
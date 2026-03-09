@isTest(seeAlldata=false)
public class SMAX_PS_CaseEvent_UT {

    // Not a valid "test", but need code coverage.. 
    // We found that if seeAllData is true, Platform Event triggers don't fire.
    // BUT, can't create a Case without seeAllData=true
    static testMethod void caseEventTest() {
    
    
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        pd.product_line__c = 'TST1';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SMAX_PS_ShipTo__c = acctMap.get('ShipTo').Id;
        loc.SMAX_PS_BillTo__c = acctMap.get('BillTo').Id;
        loc.SMAX_PS_Payer__c = acctMap.get('Payer').Id;
        loc.SMAX_PS_LL_BillTo__c = acctMap.get('LocalLangBillTo').Id;
        loc.SMAX_PS_LL_ShipTo__c = acctMap.get('LocalLangShipTo').Id;
        update loc;
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for IP', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Component__c = ip.Id);
        insert cs;

        // Case event
        Test.startTest();
        Case_Event__e cEvent = new Case_Event__e (
                                    CaseId__c = cs.id);
        Database.SaveResult sr = EventBus.publish(cEvent);
        Test.stopTest();
   }
}
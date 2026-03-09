@isTest
public class SMAX_PS_WOTranslateUpdate_UT{
    @TestSetup
    static void createTestData(){
    
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000004','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');
        loc.SVMXC__Country__c = 'US';
        update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');
        
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');

        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = fsRecType.Id;
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = acct.id;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SMAX_PS_Translation__c=NULL;
        wo.SVMXC__Order_Status__c = 'On Hold - Credit';
        //wo.SVMXC__Country__c = 'US';
    
        insert wo;
        
        SMAX_PS_Translation__c t1 = SMAX_PS_TestDataFactory.createTestTranslation('English (US)', 'US');
        SMAX_PS_Translation__c t2 = SMAX_PS_TestDataFactory.createTestTranslation('Spanish (ES)', 'ES');
        
     }

      static testmethod void test() {        
        Test.startTest();
        SMAX_PS_WOTranslateUpdate woTrans = new SMAX_PS_WOTranslateUpdate();
        Database.executeBatch(woTrans);
        
        Test.stopTest();
        
        //SVMXC__Service_Order__c wo1 = [SELECT id, name, SMAX_PS_Translation__c from SVMXC__Service_Order__c limit 1];
        
       // System.assertNotEquals(wo1.SMAX_PS_Translation__c, NULL);


        
    }


     
}
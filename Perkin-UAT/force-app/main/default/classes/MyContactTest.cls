@isTest
public class MyContactTest {
	static testMethod void TestCase1(){
       	Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/MyContact?id='+acc.id));
        MyContactCtrl myc = new MyContactCtrl();
        myc.ldbcts[0].chk = true;
        myc.Save();
        myc.Cancel();
        Test.stopTest();
    }
}
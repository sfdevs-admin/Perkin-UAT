@isTest
Public class INF_CountChildRecords_Test {

    static TestMethod void method1(){
    
    Account testAccount1 = new Account();
    testAccount1.Name='TestoftheAccount1';
    testAccount1.type='Home';
    testAccount1.of_Informatics_Cases__c =123;
    testAccount1.Shippingcountry='United Kingdom';
   // testAccount1.RecordTypeId=Utility_Informatics.Account_Informatics;
    insert testAccount1;
    
    Case TestCase = new Case();
    TestCase.RecordTypeId=Utility_Informatics.case_Informatics;
    TestCase.accountid = testAccount1.id ;
    insert TestCase;
    
    }
    
}
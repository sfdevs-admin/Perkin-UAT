@isTest
private class TenderPaymentExtControllerTests {
    @testSetup
    static void createTestData() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity();
            testOpp.Name = 'Test Opportunity';
            testOpp.StageName = 'Prospecting';
            testOpp.CloseDate = Date.today().addDays(30);
            testOpp.Amount = 10000;
            testOpp.AccountId = testAccount.Id;
        
        insert testOpp;

    }
    
    testMethod static void testSubmit() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity limit 1];

        BD_Tender_Payment__c payment = new BD_Tender_Payment__c();
        payment.BD_Parent_Opportunity__c = opp.Id;
        payment.BD_Account__c = opp.AccountId;
        insert payment;
        
        Test.startTest();
        TenderPaymentExtController con = new TenderPaymentExtController(new ApexPages.StandardController(payment));
        con.onSubmit();
        payment = [SELECT ApprovalStatus__c FROM BD_Tender_Payment__c WHERE Id = :payment.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', payment.ApprovalStatus__c);
    }
    
    testMethod static void testRecall() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity limit 1];

        BD_Tender_Payment__c payment = new BD_Tender_Payment__c();
        payment.BD_Parent_Opportunity__c = opp.Id;
        payment.BD_Account__c = opp.AccountId;
        insert payment;
        
        Test.startTest();
        TenderPaymentExtController con = new TenderPaymentExtController(new ApexPages.StandardController(payment));
        con.onRecall();
        payment = [SELECT ApprovalStatus__c FROM BD_Tender_Payment__c WHERE Id = :payment.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', payment.ApprovalStatus__c);
    }
}
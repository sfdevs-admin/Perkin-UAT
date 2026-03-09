@isTest 
public class submitOrderTest 
{
static testMethod void submitOrderTest() 
{
    Account testAccount = new Account();
    testAccount.Name='Test Account' ;
    testAccount.CurrencyIsoCode = 'USD';
    testAccount.BillingStreet ='1234';
    testAccount.BillingCity='Boston';
    testAccount.BillingState='MA';
    testAccount.BillingCountry='US';
    testAccount.BillingPostalCode='123455';
    testAccount.ShippingStreet ='1234';
    testAccount.ShippingCity='Boston';
    testAccount.ShippingState='MA';
    testAccount.ShippingCountry='US';
    testAccount.ShippingPostalCode='123455';
    insert testAccount;
    
    Opportunity opp=new opportunity();
    opp.Name='testopp';
    opp.CloseDate=system.today()+50;
    opp.StageName='Open';
    opp.AccountId= testAccount.Id;
    opp.First_Name__c = 'Test FirstName';
    Opp.Last_Name__c = 'Test LastName';
    Opp.Primary_Email_Address__c = 'test@primary.com';
    opp.stageName='Stage 6 - Implement (Closed)';
    opp.Owned_by_Company__c = 'LSDX';
    
    insert opp;
    
    Test.StartTest(); 
    
    PageReference pageRef = Page.submitOrderController;
    pageRef.getparameters().put('id', opp.id);  
    Test.setCurrentPage(pageRef);
    
    apexpages.StandardController sc = new Apexpages.StandardController(opp);
    submitOrderController ext = new submitOrderController(sc);         
    ext.UpdateOpp();  
    
    Test.StopTest();
}
}
@isTest 
public class CompleteOrderTest
{
static testMethod void CompleteOrderTest() 
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
opp.AccountId=testAccount.Id;
      opp.stageName='Stage 6 - Implement (Closed)';
      opp.Solution_Area_of_Interest__c='Energy';

insert opp;

Test.StartTest(); 
PageReference pageRef = Page.CompleteOrderController;
pageRef.getparameters().put('id', opp.id);  
Test.setCurrentPage(pageRef);

apexpages.StandardController sc = new Apexpages.StandardController(opp);
CompleteOrderController ext = new CompleteOrderController(sc);         
ext.UpdateOpp();  

Test.StopTest();
}
}
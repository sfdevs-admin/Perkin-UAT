@IsTest
public class ResetCloneOpportunityTest{
public testmethod static void ResetCloneOpportunityTest(){
Id accRT= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
  //  removing references of Dx EMEA Record Type
  //    Id EMEART = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Dx EMEA Record Type').getRecordTypeId();
 Id EMEART = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

Account ac=new Account();
ac.Name='TestAcct';
ac.RecordTypeId=accRT;
insert ac;
opportunity op=new opportunity();
op.AccountId=ac.Id;
op.stagename='Stage 1 - Create/Plan';
op.CloseDate=system.today()+3;
op.Name='testOpp';
op.Product_Type__c='Software';
op.RecordTypeId=EMEART;
insert op;
test.starttest();
Opportunity opp2=op.clone(false, false, false, false);
insert opp2;
system.debug('---opp2 '+opp2);
test.stoptest();
}
public testmethod static void ResetCloneOpportunityTes2t(){
Id accRT= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
  //  removing references of Dx Record Type
  //    Id EMEART = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Dx Record Type').getRecordTypeId();
Id EMEART = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();

Account ac=new Account();
ac.Name='TestAcct';
ac.RecordTypeId=accRT;
insert ac;
opportunity op=new opportunity();
op.AccountId=ac.Id;
op.stagename='Stage 1 - Create/Plan';
op.CloseDate=system.today()+3;
op.Name='testOpp';
op.Product_Type__c='Software';
op.RecordTypeId=EMEART;
insert op;
test.starttest();
opportunity opp2 =op.clone(false, false, false, false);
insert opp2;
test.stoptest();
}
}
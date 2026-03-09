@isTest
private class OpportunityTrigger_Test{
  @testSetup
  static void setupTestData(){
    Territory2Model territory2model_Obj = new Territory2Model(Name = 'Name992', DeveloperName = 'Devel997');
    Insert territory2model_Obj; 

  }
  static testMethod void test_OpportunityTrigger(){
   test.startTest();
    List<Territory2Model> territory2model_Obj  =  [SELECT Name from Territory2Model];
    //System.assertEquals(1,territory2model_Obj.size());
    Opportunity opportunity_Obj = new Opportunity(IsPrivate = false, Name = 'Name478', StageName = 'Prospecting', CloseDate = Date.today());
    Insert opportunity_Obj; 
   test.stopTest();
  }
}
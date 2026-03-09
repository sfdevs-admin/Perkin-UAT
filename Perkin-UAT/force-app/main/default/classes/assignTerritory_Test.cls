@isTest
private class assignTerritory_Test{
  @testSetup
  static void setupTestData(){
    test.startTest();
    Territory2Model territory2model_Obj = new Territory2Model(Name = 'Name679', DeveloperName = 'Devel131');
    Insert territory2model_Obj; 
    Opportunity opportunity_Obj = new Opportunity(IsPrivate = false, Name = 'Name818', StageName = 'Prospecting', CloseDate = Date.today());
    //Insert opportunity_Obj; 
    test.stopTest();
  }
  static testMethod void test_assignTerritoryopp_UseCase1(){
    List<Territory2Model> territory2model_Obj  =  [SELECT Name,DeveloperName from Territory2Model];
    System.assertEquals(true,territory2model_Obj.size()>0);
    List<Opportunity> opportunity_Obj  =  [SELECT IsPrivate,Name,StageName,CloseDate,IsExcludedFromTerritory2Filter from Opportunity];
    //System.assertEquals(true,opportunity_Obj.size()>0);
    assignTerritory obj01 = new assignTerritory();
    obj01.assignTerritoryopp(opportunity_Obj);
  }
}
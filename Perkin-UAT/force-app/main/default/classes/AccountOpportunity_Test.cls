@isTest
private class AccountOpportunity_Test {
    
    @testSetup
    static void setupData() {
        Id INFORMATICS_RECORDTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Informatics').getRecordTypeId();
        
        //create Account
        Account a = new Account();
        a.name = 'Test Account';
        a.ShippingCity = 'test city';
        a.ShippingCountry = 'US';
        a.ShippingPostalCode = '12345678';
        a.ShippingState = 'AX';
        a.ShippingStreet = 'Test Street';
        insert a;
        
        //Create Opportunity
        Opportunity opportunity_Obj = new Opportunity(IsPrivate = false, 
                                                      Name = 'Test Opportunity Record', 
                                                      StageName = '	Stage 1 - Create/Plan',
                                                      CloseDate = Date.today(),
                                                      RecordtypeId = INFORMATICS_RECORDTYPEID,
                                                      accountId = a.Id,
                                                      GP_OrderNum_INF__c = '123456'
                                                     );
        insert opportunity_Obj;               
    }
    
    private testmethod static void testGetAccOppDetails() {
        List<Opportunity> optyList = AccountOpportunity.getAccOppDetails('Test Account'); 
        System.assertEquals(1, optyList.size());        
    }
    
    private testmethod static void testUpdateOrderNumber() {
        Opportunity opp = [SELECT Id, GP_OrderNum_INF__c, Probability FROM Opportunity WHERE Name = 'Test Opportunity Record'];
        Boolean result = AccountOpportunity.UpdateOrderNumber(opp); 
        System.assert(result);
    }    
    
     private testmethod static void testGetAccOppDetailsByOrderNum() {
         Test.startTest();
         Opportunity opportunity_Obj1               = [SELECT Id, StageName FROM Opportunity 
                                                       WHERE Name = 'Test Opportunity Record' 
                                                       LIMIT 1];
         opportunity_Obj1.StageName                 = 'Stage 3 - Develop';         
         update opportunity_Obj1;
         
         opportunity_Obj1.StageName                 = 'Closed Won';
         opportunity_Obj1.Renewal_Required_INF__c   = 'No';
         update opportunity_Obj1;
        
         Opportunity result = AccountOpportunity.getAccOppDetailsByOrderNum('123456');
         Test.stopTest();
     }
}
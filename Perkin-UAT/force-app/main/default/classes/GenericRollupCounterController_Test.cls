@isTest
private class GenericRollupCounterController_Test {
    @testSetup
    static void setupData() {
        Id INFORMATICS_RECORDTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Informatics').getRecordTypeId();
        
        //create Account
        /*Account a = new Account();
        a.name = 'Test Account';
        a.ShippingCity = 'test city';
        a.ShippingCountry = 'US';
        a.ShippingPostalCode = '12345678';
        a.ShippingState = 'AX';
        a.ShippingStreet = 'Test Street';
        insert a;
*/
        
        //Create Opportunity
        Opportunity opportunity_Obj = new Opportunity(IsPrivate = false, 
                                                      Name = 'Test Opportunity Record', 
                                                      StageName = 'Stage 1 - Create/Plan',
                                                      CloseDate = Date.today(),
                                                      RecordtypeId = INFORMATICS_RECORDTYPEID,
                                                      GP_OrderNum_INF__c = '123456', 
                                                      OwnerId = UserInfo.getUserId()
                                                     );
        insert opportunity_Obj;               
    }
    
    private static testMethod void testCorrectObjectMapping() {
        
        Opportunity opportunity_Obj1 = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        GenericRollupCounterController.Inputs inputs = new GenericRollupCounterController.Inputs();
        inputs.recId = UserInfo.getUserId();
        inputs.metadataLabel = 'UserRollup';
        List<Rollup_Counter_Mapping__mdt> testRollupMappings = [SELECT Aggregate_Column__c,Aggregate_Operation__c,Display_Label__c,Display_Order__c,Filter_Criteria__c,Mapping_For__c,SLDS_icon__c,Source_Object_API__c,Target_Object_API__c,Target_Object_Field__c FROM Rollup_Counter_Mapping__mdt WHERE Mapping_For__c = 'UserRollup' AND Target_Object_API__c = 'Opportunity'];     
        
        Test.startTest();        
        String res = GenericRollupCounterController.getCounterRecords(JSON.serialize(inputs));
        system.debug(res);
        GenericRollupCounterController.result results = (GenericRollupCounterController.result)JSON.deserialize(res, GenericRollupCounterController.result.class);
        System.debug('results in test: ' + results);
//        System.assertEquals(false, results.isError,'should have been false as no error'); 
//        System.assert(String.isBlank(results.message),'should have been blank as no error');        
        Test.stopTest();
    }
}
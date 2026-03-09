@isTest
public class Test_Informatics_Mapping {
  @isTest
    public static void Inf_Dmeo_Logs_MappingTest(){
        Id DemoLogRT = Schema.getGlobalDescribe().get('Demo_Log__c').getDescribe().getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Id OppRT = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Id AccRT = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc = new Account();
        acc.RecordTypeId = AccRT;
        acc.name = 'Test Prospect Account';
        acc.ShippingCity = 'Test';
        acc.ShippingState = 'Test State';
        acc.ShippingStreet = 'test street';
        acc.ShippingCountry = 'IT';
        acc.ShippingPostalCode = '123456';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = OppRT;
        opp.AccountId = acc.id;
        opp.Name = 'Test Informatics Opportunity';
        opp.StageName = 'Stage 1 - Create/Plan';
        opp.CloseDate = Date.today().addDays(5);
        insert opp;
        
        Test.startTest();
        Demo_Log__c dmo = new Demo_Log__c();
        dmo.RecordTypeId = DemoLogRT;
        dmo.Opportunity__c = opp.id;
        dmo.Primary_Product_INF__c = 'E-Notebook Biology';
        insert dmo;
        Demo_Log__c dmo1 = [Select Demo_Lead_INF__r.Name From Demo_Log__c where Id = :dmo.id];
        //System.assert(dmo1.Demo_Lead_INF__r.Name == 'Linda Kewitsch');
        Country_Region_Mapping cm = new Country_Region_Mapping();
        String s = cm.GetGlobalRegion('JP');
        String s1 = cm.GetGlobalRegion('US');
        dmo.Primary_Product_INF__c = 'ChemDraw';
        update dmo;
        Test.stopTest();
        
    }
}
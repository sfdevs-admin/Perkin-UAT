@isTest
public class SF_Tenent_Information_TEST {
    private static Account ac;
    private static Opportunity opp;
    //private static SBQQ__Quote__c sbQuote;
    private static Tenent_Information__c tenentInfo;
    private static Tenent_System_Information__c tenentSysInfo;
    
    public static void init(){
        RecordType OppRecType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Informatics'];
        RecordType AccRecType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Prospect'];
        
        ac = new Account();
        ac.name='Test Account';
        ac.RecordTypeId = AccRecType.Id;
        insert ac;        
        opp = new Opportunity();
        opp.Name = 'test Opp';
        opp.StageName = 'Stage 1 - Create/Plan';
        opp.Type = 'Instrument';
        //opp.CurrencyIsoCode = 'USD - U.S. Dollar';
        opp.RecordtypeId = OppRecType.Id;
        opp.CloseDate = Date.newInstance(2021, 03, 03);
        insert opp;        
        /*sbQuote = new SBQQ__Quote__c();
        sbQuote.SBQQ__StartDate__c = date.today();
        sbQuote.SBQQ__Opportunity2__c = opp.Id; 
        insert sbQuote;*/
        tenentInfo = new Tenent_Information__c();
        
        tenentSysInfo = new Tenent_System_Information__c();
    }
    public static testMethod void SF_Tenent_Information(){
        init();
        Test.startTest();
        //ApexPages.StandardController stdCon = new ApexPages.StandardController(sbQuote);
        //SF_Tenent_Information tenInfo = new SF_Tenent_Information(stdCon);
        //List<Selectoption> paidOrder = tenInfo.getselectedPaidOrder();
        //List<Selectoption> activeExpire = tenInfo.getselectedActiveOrExpire();
        //List<Selectoption> getCountry = tenInfo.getselectedCountry();
        //tenInfo.saveRecord();
        Test.stopTest();
    }
}
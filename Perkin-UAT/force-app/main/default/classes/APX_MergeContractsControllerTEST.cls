@isTest(SeeAllData=TRUE)
public class APX_MergeContractsControllerTEST {
    public static Contract con1;
    public static Contract con2;
    public static Contract con3;
    public static Contract con4;
    public static Account acc;
    public static List<Contract> conList;
    public static List<Contract> conList2;
    public static void init(){
        Id conRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Accountwide Contract').getRecordTypeId();
        Id opprtRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
        acc = new Account();
        acc.Name = 'Test';
        insert acc;
        
        con1 = new Contract();
        con1.Name = 'TestContract1';
        con1.AccountId = acc.Id;
        con1.StartDate = System.today();
        con1.EndDate = System.today() + 60;
        con1.ContractTerm = 12;
        con1.Status = 'Draft';
        con1.RecordTypeId = conRecTypeId;
        insert con1;
        
        conList = new List<Contract>();
        con2 = new Contract();
        con2.Name = 'TestContract2';
        con2.AccountId = acc.Id;
        con2.StartDate = System.today();
        con2.EndDate = System.today() + 60;
        con2.ContractTerm = 12;
        con2.Status = 'Draft';
        con2.RecordTypeId = conRecTypeId;
        conList.add(con2);
        insert conList;
        con2.Status = 'Activated';
        update con2;
        
        con3 = new Contract();
        con3.Name = 'TestContract3';
        con3.AccountId = acc.Id;
        con3.StartDate = System.today();
        con3.EndDate = System.today() + 60;
        con3.ContractTerm = 12;
        con3.Status = 'Draft';
        con3.RecordTypeId = conRecTypeId;
        insert con3;
        
        conList2 = new List<Contract>();
        con4 = new Contract();
        con4.Name = 'TestContract4';
        con4.AccountId = acc.Id;
        con4.StartDate = System.today();
        con4.EndDate = System.today() + 60;
        con4.ContractTerm = 12;
        con4.Status = 'Draft';
        con4.RecordTypeId = conRecTypeId;
        conList2.add(con4);
        insert conList2;
        
        Pricebook2 standardPB = [select id,CurrencyIsoCode from Pricebook2 where isStandard=true LIMIT 1];
        
        Product2 prod = new Product2();
        prod.Name = 'Test';
        prod.ProductCode = '01920';
        prod.IsActive = true;
        //prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        //prod.SBQQ__SubscriptionType__c = 'Renewable';
        prod.Business_Unit__c = 'INFORMATICS';
        insert prod;
        
        PricebookEntry pbe = [SELECT Id,name,CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id =:standardPB.Id LIMIT 1];
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = opprtRecTypeId;
        opp.Name = 'Test opp';
        opp.AccountId = acc.Id;
        opp.Strategic_Market_INF__c = 'Life Sciences Research';
        opp.Type = 'New Products';
        opp.CloseDate = System.today()+120;
        opp.StageName = 'Stage 6 - Implement (Closed)';
        opp.Pricebook2Id = standardPB.Id; 
        opp.Application__c = 'Materials';
        opp.Application_Segment__c = 'Informatics';
        opp.Application_Market__c = 'Applied';
        insert opp;
        
        /*SBQQ__Subscription__c subs = new SBQQ__Subscription__c(
            SBQQ__Contract__c = con2.Id, 
            SBQQ__Product__c = prod.Id, 
            SBQQ__Quantity__c = 1, 
            SBQQ__Account__c = acc.Id,
            SBQQ__NetPrice__c = 20,
            SBQQ__SubscriptionEndDate__c = Date.today().addYears(1));
        insert subs; */
    }
    public static testmethod void testApp(){
        init();
        Test.startTest();
        con1.Status = 'Activated';
        update con1;
        APX_MergeContractsController.getContractList(acc.Id);
        APX_MergeContractsController.getChildContractList(con1, acc.Id);
        Test.stopTest();
    }
    public static testmethod void testApp2(){
        init();
        Test.startTest();
        con3.Status = 'Activated';
        update con3;
        con4.Status = 'Activated';
        update con4;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Premier Support User'].Id,
            LastName = 'last',
            Email = 'puser000@test.com',
            Username = 'puser000@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            PKICountry__c = 'Brazil'
        );
        insert u;
        System.runAs(u) {
            APX_MergeContractsController.mergeMasterContract(conList2, con3);
        }
        APX_MergeContractsController.mergeMasterContract(conList2, con3);
        //APX_MergeContractsController.getSubscriptionList(con3, new List<Contract>{con2});
        Test.stopTest();
    }
}
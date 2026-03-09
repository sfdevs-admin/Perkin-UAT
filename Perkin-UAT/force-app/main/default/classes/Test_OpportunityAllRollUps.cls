@isTest
public class Test_OpportunityAllRollUps {

    @testSetup static void setup() {
         Date closeDt = Date.Today();
        Id opprecordId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Id accrecordId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Account acc = new Account(Name ='Test OpprtLine',RecordTypeId=accrecordId);
        insert acc;

        opportunity oppr = new opportunity(Name='Test Opprt OpprtLine' ,  AccountId= acc.Id,StageName = 'Prospecting', 
                                   CloseDate = closeDt,RecordTypeId=opprecordId);
        insert oppr;

         Opportunity opprt = new Opportunity();
        opprt.Name='Test Opport';
        opprt.RecordTypeId=oppr.RecordTypeId;
        opprt.Strategic_Market_INF__c='Life Sciences Research';
        opprt.Type='New Products'; 
        opprt.CloseDate=closeDt;
        opprt.StageName='Stage 1 - Create/Plan';
        Insert opprt;
        Opportunity opprt2 = new Opportunity();
        opprt2.Name='Test Opport2';
        opprt2.RecordTypeId=oppr.RecordTypeId;
        opprt2.Strategic_Market_INF__c='Life Sciences Research';
        opprt2.Type='New Products'; 
        opprt2.CloseDate=closeDt;
        opprt2.StageName='Stage 1 - Create/Plan';
        opprt2.Originating_Opportunity_INF__c=oppr.Id;
        Insert opprt2;
        
    }
     @isTest
    public static void testOpportunityChildCountUpdate()
    {
        Test.startTest();
        Opportunity opport = [Select Id,Originating_Opportunity_INF__c From Opportunity Where Name='Test Opprt OpprtLine' ];
        Opportunity opportId = [Select Id,Originating_Opportunity_INF__c From Opportunity Where Name='Test Opport' ];
        opportId.Originating_Opportunity_INF__c=opport.Id;
        update opportId;
        Opportunity opprt=[Select Id From Opportunity Where Name='Test Opport2'];
        delete opprt;
         Opportunity opprt2 = new Opportunity();
        opprt2.Name='Test Opport3';
        opprt2.Strategic_Market_INF__c='Life Sciences Research';
        opprt2.Type='New Products'; 
        opprt2.CloseDate=Date.TODAY();
        opprt2.StageName='Stage 1 - Create/Plan';
        Insert opprt2;
        opportId.Originating_Opportunity_INF__c=opprt2.Id;
        update opportId;
        Test.stopTest();
    }
    
    @isTest
    public static void testOpportContractRollUp()
    {
         Date closeDt = Date.Today();
        Id opprecordId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Id contrRecordId=Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Service Contract').getRecordTypeId();
        Id accrecordId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Test.startTest();
        Account acc = new Account(Name ='TestAccount',RecordTypeId=accrecordId);
        insert acc;   
        Opportunity opprt = new Opportunity();
        opprt.Name='Test Opport';
        opprt.AccountId=acc.Id;
        opprt.RecordTypeId=opprecordId;
        opprt.Strategic_Market_INF__c='Life Sciences Research';
        opprt.Type='New Products'; 
        opprt.CloseDate=closeDt;
        opprt.StageName='Stage 1 - Create/Plan';
        Insert opprt;
        Contract contr = new Contract();
        contr.Name='Test Contract';
        contr.AccountId=acc.Id;
        contr.StartDate=Date.TODAY();
        contr.EndDate=Date.TODAY() + 60;
        contr.Status='Draft';
        contr.ContractTerm=2;
        //contr.SBQQ__Opportunity__c=opprt.Id;
        contr.RecordTypeId=contrRecordId;
        insert contr;
        Contract contr1 = new Contract();
        contr1.Name='Test Contract1';
        contr1.AccountId=acc.Id;
        contr1.StartDate=Date.TODAY() - 30;
        contr1.EndDate=Date.TODAY();
        contr1.Status='Draft';
        contr1.ContractTerm=1;
        //contr1.SBQQ__Opportunity__c=opprt.Id;
        contr1.RecordTypeId=contrRecordId;
        insert contr1;
        delete contr1;
        Test.stopTest();
    }
    
    @isTest
    public static void testOpprtOrderRollUp()
    {
        Date closeDt = Date.Today()+ 1;
        Test.startTest();
        Id accrecordId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Account acc = new Account(Name ='TestAccount',RecordTypeId=accrecordId);
        insert acc; 
        Id opprecordId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Opportunity opprt = new Opportunity();
        opprt.Name='Test Opport';
        opprt.AccountId=acc.Id;
        opprt.RecordTypeId=opprecordId;
        opprt.Strategic_Market_INF__c='Life Sciences Research';
        opprt.Type='New Products'; 
        opprt.CloseDate=closeDt;
        opprt.StageName='Stage 1 - Create/Plan';
        Insert opprt;
        Order ord = new Order();
        ord.AccountId=acc.Id;
        ord.OpportunityId=opprt.Id;
        ord.EffectiveDate=Date.TODAY();
        ord.Status='Draft';
        insert ord;
        ord.Status='Draft';
        //ord.SBQQ__Contracted__c=TRUE;
        update ord;
        delete ord;
        Test.stopTest();
    }
    
    @isTest
    public static void testOpportQuoteRollUp()
    {
        Id opprecordId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        Id accrecordId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Test.startTest();
        Account acc = new Account(Name ='TestAccount',RecordTypeId=accrecordId);
        insert acc;
        Opportunity opprt = new Opportunity();
        opprt.Name='Test Opport';
        opprt.AccountId=acc.Id;
        opprt.RecordTypeId=opprecordId;
        opprt.Strategic_Market_INF__c='Life Sciences Research';
        opprt.Type='New Products'; 
        opprt.CloseDate=Date.TODAY();
        opprt.StageName='Stage 1 - Create/Plan';
        Insert opprt;
        /*SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Quote_Name__c='Test Quote';
        quote.SBQQ__Opportunity2__c=opprt.Id;
        quote.SBQQ__Primary__c=TRUE;
        quote.SBQQ__StartDate__c=Date.TODAY();
        insert quote;
        delete quote; */
        Test.stopTest();
    }
    
    @isTest
    public static void testOpprtunityLineItemRollup()
    { 
        Test.startTest();
        Opportunity oppr=[Select Id From Opportunity Where Name='Test Opprt OpprtLine' Limit 1 ];
        
        Pricebook2 pb22 = new Pricebook2(Name='TestPriceBook');
        insert pb22;

        Product2 pro2 = new Product2();
        pro2.Product_Line__c='AVS';
        pro2.Name='testProdLine';
        pro2.isActive=true;
        pro2.License_Type_INF__c='Services';
        insert pro2;
        
        
        PricebookEntry pbe2 =new PricebookEntry(unitprice=0.01,Product2Id=pro2.Id,Pricebook2Id=Test.getStandardPricebookId(),
                                         isActive=true,UseStandardPrice = false);
        insert pbe2;
         
        /*SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Quote_Name__c='Test Quote';
        quote.SBQQ__Opportunity2__c=oppr.Id;
        quote.SBQQ__StartDate__c=Date.TODAY();
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine= new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c=quote.Id;
        quoteLine.SBQQ__Product__c=pro2.Id;
        quoteLine.SBQQ__PricebookEntryId__c=pbe2.Id;
        insert quoteLine;*/

       OpportunityLineItem opprtLineItem = new OpportunityLineItem (/*SBQQ__QuoteLine__c=quoteLine.Id,*/Quantity=2, OpportunityId=oppr.Id,UnitPrice=0.01,PriceBookEntryId=pbe2.Id);
         insert opprtLineItem;
        Test.stopTest();
    }
    
    @isTest
    public static void testOpportunityLineItem2()
    {
        
        Test.startTest();
        Opportunity oppr=[Select Id From Opportunity Where Name='Test Opprt OpprtLine' Limit 1 ];
        Pricebook2 pb22 = new Pricebook2(Name='TestPriceBook');
        insert pb22;

        Product2 pro2 = new Product2();
        pro2.Product_Line__c='AVS';
        pro2.Name='testProdLine';
        pro2.isActive=true;
        pro2.License_Type_INF__c='Subscription';
        insert pro2;
        
        PricebookEntry pbe2 =new PricebookEntry(unitprice=0.01,Product2Id=pro2.Id,Pricebook2Id=Test.getStandardPricebookId(),
                                         isActive=true,UseStandardPrice = false);
        insert pbe2;
        OpportunityLineItem opprtLineItem = new OpportunityLineItem (Quantity=2, OpportunityId=oppr.Id,UnitPrice=0.01,PriceBookEntryId=pbe2.Id);
         insert opprtLineItem;
        delete opprtLineItem;
        Test.stopTest();
    }
}
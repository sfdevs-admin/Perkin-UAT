@isTest(seeAllData=true)
public class INF_CreateRenewalOpportunityOnClosedWon{
    
    static List<Opportunity> OpptyList;
    static Id AccountRTId;
    static ID OpportunityRTId;
    
    static List<RecordType> rtList =[Select Id, DeveloperName, SobjectType  from RecordType 
                                     Where SobjectType IN ('Account','Opportunity')
                                     And DeveloperName IN('ProspectAccount','Informatics') ];
    
    
    static void getRecorDtypeIds(){
        if(rtList.size() > 0){
            for(RecordType r: rtList){  
                if(r.DeveloperName == 'ProspectAccount' && r.SobjectType == 'Account')
                    AccountRTId = r.id;
                if(r.DeveloperName == 'Informatics' && r.SobjectType == 'Opportunity')
                    OpportunityRTId = r.id;        
            }
        }
    }
    
    static testMethod void CreateRenewalOpportunityOnClosedWon()
    {
        getRecorDtypeIds();             
        /* Insert an Account */
        Account acc = new Account ();
        acc.RecordTypeId = AccountRTId;
        acc.name='Test Account#2-1-2018';
        acc.shippingStreet = 'Street1';
        acc.shippingCity = 'City1';
        acc.shippingState = 'State';
        acc.shippingCountry ='US';
        acc.shippingPostalCode = '12345';
        acc.Industry ='Biotech';
        acc.CurrencyIsoCode = 'USD';
        insert acc;
        
        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.LastName = 'test';
        insert c;
        OpptyList = new List<Opportunity>();
        
        for (Integer i = 0; i < 10; i++)
        {
            OpptyList.add(new Opportunity(Name='OppTest'+i,AccountId=acc.Id,Probability=100,
                                          Renewal_Required_INF__c='Yes',RecordTypeId=OpportunityRTId,Account_Type_INF__c='Academic',Primary_Contact__c = c.Id,
                                          Solution_Area_of_Interest__c='Energy',StageName='Stage 6 - Implement (Closed)',LeadSource='Advertisement',CloseDate=Date.today(),
                                          Application__c = 'Virology', Application_Market__c = 'Clinical Diagnostics', Application_Segment__c = 'Diagnostics'));
        }
        insert OpptyList;
        
        Opportunity opp1 = new Opportunity (Name='Opp1',StageName='Stage 6 - Implement (Closed)',CloseDate=Date.today(),Solution_Area_of_Interest__c='Energy',Application__c = 'Virology', Application_Market__c = 'Clinical Diagnostics', Application_Segment__c = 'Diagnostics');
        insert opp1;
        
        Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
        Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
        insert pbk1;
        
        List<Product2> prod2List = new List<Product2>();
        Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Term',
                                      Description='Test Product Entry 1');
        prd1.PricebookEntryID__c = pbk1.ID;
        prod2List.add(prd1);
        
        Product2 prd2 = new Product2 (Name='test product',ProductCode='CPH568',License_Type_INF__c='',
                                      Description='Test Product Entry 2');
        prd2.PricebookEntryID__c = pbk1.ID;
        prod2List.add(prd2);
        insert prod2List;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=standardPb.id,IsActive=true,
                                                  UseStandardPrice=false,UnitPrice=50);
        pbeList.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
                                                  UseStandardPrice=false,UnitPrice=50);
        pbeList.add(pbe2);
        insert pbeList;
        
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        List<Opportunity> OppsUpdateRen = new List<Opportunity>();
        List<Opportunity> OppsUpdateNonRen1 = new List<Opportunity>();
        List<Opportunity> OppsUpdateNonRen = new List<Opportunity>();
        
        
        for(Opportunity opp : OpptyList){
            oppLineItems.add(new OpportunityLineItem(OpportunityID=opp.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbeList[0].id));
            oppLineItems.add(new OpportunityLineItem(OpportunityID=opp.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbeList[1].id));
            opp.StageName='Closed Won';
            opp.GP_OrderNum_INF__c ='ORD1234';
            opp.Solution_Area_of_Interest__c='Energy';
            opp.Application__c = 'Virology';
            opp.Application_Market__c = 'Clinical Diagnostics';
            opp.Application_Segment__c = 'Diagnostics';
            OppsUpdateRen.add(opp);
            
        }
        
        insert oppLineItems;
        test.startTest();
        update OppsUpdateRen;
        test.stopTest();
        
    }
    
    
    static testMethod void CreateNonRenewalOpportunityOnClosedWon()
    {
        getRecorDtypeIds();      
        /* Insert an Account */
        Account acc = new Account ();
        acc.RecordTypeId = AccountRTId;
        acc.name='Test Account#2-2-2018';
        acc.shippingStreet = 'Street1';
        acc.shippingCity = 'City1';
        acc.shippingState = 'State';
        acc.shippingCountry ='US';
        acc.shippingPostalCode = '12345';
        acc.Industry ='Biotech';
        acc.CurrencyIsoCode = 'USD';
        insert acc;
        
        
        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.LastName = 'test';
        insert c;
        
        OpptyList = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++)
        {
            OpptyList.add(new Opportunity(Name='OppTest'+i,AccountId=acc.Id,Probability=100,
                                          Renewal_Required_INF__c='Yes',RecordTypeId=OpportunityRTId,Account_Type_INF__c='Academic',Primary_Contact__c=c.Id,
                                          Solution_Area_of_Interest__c='Energy',StageName='Stage 6 - Implement (Closed)',LeadSource='Advertisement',CloseDate=Date.today(),
                                         Application__c = 'Virology', Application_Market__c = 'Clinical Diagnostics', Application_Segment__c = 'Diagnostics'));
        }
        insert OpptyList;
        
        List<Opportunity> OppNonren = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++)
        {
            OppNonren.add(new Opportunity(Name='OppTests'+i,AccountId=acc.Id,Probability=100,
                                          Renewal_Required_INF__c='NO',RecordTypeId=OpportunityRTId,Account_Type_INF__c='Academic',Primary_Contact__c=c.Id,
                                          Solution_Area_of_Interest__c='Energy',StageName='Stage 6 - Implement (Closed)',LeadSource='Advertisement',CloseDate=Date.today(),
                                          Application__c = 'Virology', Application_Market__c = 'Clinical Diagnostics', Application_Segment__c = 'Diagnostics'));
        }
        insert OppNonren;
        
        
        Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
        
        Opportunity opp1 = new Opportunity (Name='Opp1',StageName='Stage 6 - Implement (Closed)',CloseDate=Date.today(),Solution_Area_of_Interest__c='Energy',Application__c = 'Virology', Application_Market__c = 'Clinical Diagnostics', Application_Segment__c = 'Diagnostics');
        insert opp1;
        
        Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 2',Description='Test Pricebook Entry2');
        insert pbk1;
        
        List<Product2> prod2List = new List<Product2>();
        Product2 prd3 = new Product2 (Name='Term test product',ProductCode='CPH569',License_Type_INF__c='Term',
                                      Description='Test Product Entry 3');
        prd3.PricebookEntryID__c = pbk1.ID;
        prod2List.add(prd3);
        
        Product2 prd4 = new Product2 (Name='test product maint',ProductCode='CPH570',License_Type_INF__c='',
                                      Description='Test Product Entry 4');
        prd4.PricebookEntryID__c = pbk1.ID;
        prod2List.add(prd4);
        insert prod2List;
        
        List<PricebookEntry> pbeList1 = new List<PricebookEntry>();
        PricebookEntry pbe3 = new PricebookEntry (Product2ID=prd4.id,Pricebook2ID=standardPb.id,IsActive=true,
                                                  UseStandardPrice=false,UnitPrice=50);
        
        insert pbe3;
        
        List<Opportunity> OppsUpdateNonRen1 = new List<Opportunity>();
        List<OpportunityLineItem> oppLineItems1 = new List<OpportunityLineItem>();  
        for(Opportunity opp : OpptyList){
            oppLineItems1.add(new OpportunityLineItem(OpportunityID=opp.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbe3.id));
            opp.StageName='Closed Won';
            opp.GP_OrderNum_INF__c ='ORD234';
            opp.Lead_Source__c='Event';
            opp.Run_Rate_Opp_INF__c=false;
            opp.Renewal_Required_INF__c='No';
            opp.RecordTypeId = Utility_Informatics.opportunity_Informatics;
            opp.Solution_Area_of_Interest__c='Energy';
            OppsUpdateNonRen1.add(opp);
            
        }     
        test.startTest();
        OppResetControl oppc = new OppResetControl();
        oppc.dummyMthd();
        system.debug('OppsUpdateNonRen1 >>>>>>>>'+OppsUpdateNonRen1);
        insert oppLineItems1;
        update OppsUpdateNonRen1;
        test.stopTest();
    }
}
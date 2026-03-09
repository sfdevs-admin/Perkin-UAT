@isTest
public class Test_Opportunity_Trigger_Handler {
   @testSetup static void setup() {
     Id opportunity_Informatics = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
     Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            CurrencyIsoCode='USD'
        );
        Update standardPricebook;
        
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        List<Product2> productLst = new List<Product2>();
        Product2 product = new Product2(
            Name = 'TestProduct',
            IsActive = true, 
            /*SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable', */
            License_Type_INF__c = 'Perpetual'
        );
        productLst.add(product);
        
        Product2 prod = new Product2(
            Name = 'Services',
            IsActive = true, 
            /*SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable',*/
           // License_Type_INF__c = 'Services'
            License_Type_INF__c = 'Perpetual'
        );
        productLst.add(prod);
        
        Product2 pro = new Product2(
            Name = 'TestProduct',
            IsActive = true, 
            /*SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable',*/
            License_Type_INF__c = 'Maintenance'
        );
        productLst.add(pro);
        
        Product2 prodt = new Product2(
            Name = 'TestProduct',
            IsActive = true, 
            /*SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable',*/
            License_Type_INF__c = 'Saas'
        );
        productLst.add(prodt);
        insert productLst;
         Pricebook2 pb = new Pricebook2(Name = 'Informatics price', Description = 'Price Book 2009 Products', IsActive = true,CurrencyIsoCode = 'USD' );
    insert pb;
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 120.00,
            IsActive = true
        );
        insert pbEntry;
         PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = prod.Id,
            UnitPrice = 120.00,
            IsActive = true
        );
        insert pbEntry1;
        
        Account a = new Account(Name='Testing3456',Industry ='Biotech',
                                BillingStreet='Street1',BillingCity='City1',BillingState='State',BillingCountry='US',BillingPostalCode='12345');
        insert a;
        
        contact con = new contact();
        con.Lead_Owner_LDR_Conversion__c=userinfo.getName();
        con.LastName= 'Last Name';
        con.AccountId=a.Id;
        insert con;
       
        Opportunity op = new Opportunity(Name='opp1',AccountId=a.Id,RecordTypeId=opportunity_Informatics,
                                              Renewal_Required_INF__c='Yes',Account_Type_INF__c='Academic',
                                              StageName='Stage 1 - Create/Plan',CloseDate=Date.today(),
                                              Strategic_Market_INF__c='Clinical',Type='New Account',
                                              ForecastCategoryName='Pipeline',CurrencyIsoCode = 'USD',
                                              Solution_Area_of_Interest__c='Energy',pricebook2Id=pb.Id);        
        insert op;
        
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
                PricebookEntryId = pbEntry1.Id,
                Quantity = 3,
                UnitPrice = 1000,
                End_Date_INF__c=date.today(), 
                Start_Date_INF__c=date.today(),
                OpportunityId = op.Id);
        insert opportunityLineItem;
                
        
        
        OpportunityContactRole OppConRole = new OpportunityContactRole();
        OppConRole.ContactId=con.Id;
        OppConRole.OpportunityId =Op.Id;
        OppConRole.IsPrimary=true;
        insert OppConRole;
        
    }
    static testMethod void UpdateMethod2(){
        product2 prod=[select id,License_Type_INF__c from Product2 Where Name='Services' limit 1];
        prod.License_Type_INF__c = 'SaaS';
        Update prod;
       opportunity op  =[select id,StageName,Application__c,Application_Market__c,
                       Application_Segment__c,Renewal_Required_INF__c,Run_Rate_Opp_INF__c FROM Opportunity limit 1];
        op.StageName = 'Closed Won';
        op.Application__c = 'Virology';
        op.Application_Market__c = 'Clinical Diagnostics';
        op.Application_Segment__c = 'Diagnostics';
        op.Renewal_Required_INF__c = 'No';
        op.Run_Rate_Opp_INF__c = false;
        update op;
    }
    static testMethod void UpdateMethod3(){
       opportunity op  =[select id,StageName,Application__c,Application_Market__c,
                       Application_Segment__c,Renewal_Required_INF__c,Run_Rate_Opp_INF__c FROM Opportunity limit 1];
        op.StageName = 'Stage 6 - Implement (Closed)';
        op.Application__c = 'Virology';
        op.Application_Market__c = 'Clinical Diagnostics';
        op.Application_Segment__c = 'Diagnostics';
        op.Renewal_Required_INF__c = 'No';
        op.Run_Rate_Opp_INF__c = false;
        update op;
    }
    static testMethod void UpdateMethod4(){
        product2 prod=[select id,License_Type_INF__c from Product2 Where Name='Services' limit 1];
        prod.License_Type_INF__c = 'SaaS';
        Update prod;
        test.startTest();
         opportunity op  =[select id,StageName,Application__c,Application_Market__c,
                       Application_Segment__c,Renewal_Required_INF__c,Run_Rate_Opp_INF__c FROM Opportunity limit 1];
        op.StageName = 'Closed Won';
        op.Application__c = 'Virology';
        op.Application_Market__c = 'Clinical Diagnostics';
        op.Application_Segment__c = 'Diagnostics';
        op.Renewal_Required_INF__c = 'Yes';
        op.Run_Rate_Opp_INF__c = false;
        update op;
            test.stopTest();
        
    }
    
}
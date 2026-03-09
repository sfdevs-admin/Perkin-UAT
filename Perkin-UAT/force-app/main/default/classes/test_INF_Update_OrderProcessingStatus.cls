@isTest(seeAllData=true)
public class test_INF_Update_OrderProcessingStatus {

    @istest
    static void testmethod1() {
        Account a = new Account(Name='Testing3456',shippingCountry='US',Industry ='Biotech',
                                    BillingStreet='Street1',BillingCity='City1',BillingState='State',BillingCountry='US',BillingPostalCode='12345');
        insert a;
        Contact ct1 = new Contact(FirstName='Test',LastName='Contact 2',Email='testemail@emailtest.com');
        insert ct1;
        
        id recTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
    
        Opportunity op = new Opportunity(Name='opp1',AccountId=a.Id,RecordTypeId=recTypeId,
                                         Renewal_Required_INF__c='Yes',Account_Type_INF__c='Academic',
                                         StageName='Stage 1 - Create/Plan',CloseDate=Date.today(),
                                         Strategic_Market_INF__c='Clinical',Type='New Account',
                                         ForecastCategoryName='Pipeline',CurrencyIsoCode = 'USD',
                                         Primary_Contact__c = ct1.Id,
                                         Solution_Area_of_Interest__c='Energy');        
        insert op;
        
        Id pricebookId = Test.getStandardPricebookId();
    
        product2 prod = new Product2();
        prod.License_Type_INF__c='Services';
        prod.Name='OneSource LABIT';
        insert prod;
        
        PricebookEntry pbEntry = new PricebookEntry(
         Pricebook2Id = pricebookId,
         Product2Id = prod.Id,
         UnitPrice = 100.00,
         IsActive = true
        );
        insert pbEntry;
        
      /*  opportunitylineitem p = new opportunitylineitem();
        p.product2=prod;
        p.OpportunityId=op.Id;
        p.Quantity=1;
        p.TotalPrice=12.00;
        insert p;*/
        
        OpportunityLineItem oli = new OpportunityLineItem(
         OpportunityId = op.Id,
         Quantity = 5,
         PricebookEntryId = pbEntry.Id,
         TotalPrice = 12.00
        );
        insert oli;
        
        op.StageName='Stage 6 - Implement (Closed)';
        update op;
        
    }
}
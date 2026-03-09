@isTest
public class OrderItemsUpdateStartDateTest {

 @testSetup
    static void setupData()
    {
        Id opprtRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
        Product2 product = new Product2(
            Name = 'TestProduct',
            IsActive = true 
            //SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            //SBQQ__SubscriptionTerm__c = 12, 
            //SBQQ__SubscriptionType__c = 'Renewable'
        );

        insert product;
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 120.00,
            IsActive = true
        );
        insert pbEntry;
        Account acc= new Account();
        acc.Name='Test Account';
        insert acc;
        Opportunity opprt = new Opportunity(Name='TestOpprt',AccountId=acc.id,Strategic_Market_INF__c='Life Sciences Research'
                                            ,Type='New Products',CloseDate=System.today() + 120,StageName='Stage 5 - Negotiation',Pricebook2Id = Test.getStandardPricebookId());
        insert opprt;
        /*SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c='TestQuote',SBQQ__StartDate__c=System.today() 
                                                  ,SBQQ__Opportunity2__c=opprt.Id,SBQQ__Account__c=acc.Id
                                                 );
        insert quote;
         SBQQ__QuoteLine__C quoteline = new SBQQ__QuoteLine__C(
            SBQQ__Product__c = product.Id,
            SBQQ__Quote__c = quote.Id,
            SBQQ__PricebookEntryId__c = pbEntry.Id,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__Quantity__c = 1,
            CPQ_Product_Service_Start_Date__c=System.today()+ 2
        );

        insert quoteline;
        quote.SBQQ__Primary__c  =true;
        quote.SBQQ__Ordered__c=true;
        update quote;*/
    }
    @isTest
    static void testOrderItems()
    {
        //SBQQ__Quote__c quote =[Select id From SBQQ__Quote__c Where Quote_Name__c='TestQuote' limit 1];
        //Order ord= [Select Id From Order where SBQQ__Quote__c=:quote.Id ];
        List<Id> orderIds = new List<Id>();
        //orderIds.add(ord.Id);
        OrderItemsUpdateStartDate.updateOrderItems(orderIds);
    }
}
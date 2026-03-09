@isTest
public class Batch_AutoActivateOrderBatch_Test {
    public static testmethod void batchAutoActivateOrderTest(){
        
        List<PermissionSet> permissions = [SELECT Id FROM PermissionSet WHERE Name='CUSTOM_C_PERM_9200_Allow_Creating_Account'];
        if(permissions != null && permissions.size() > 0){
            insert new PermissionSetAssignment(AssigneeId = userinfo.getUserId(), PermissionSetId = permissions[0].Id);
        }
        
        User currentUser = [SELECT Id FROM USER Where Id=: userinfo.getUserId()];
        system.runAs(currentUser){
            
            Id INFORMATICS_RECORDTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Informatics').getRecordTypeId();
            
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            standardPricebook = [SELECT Id, IsStandard,CurrencyIsoCode FROM Pricebook2 WHERE Id = :standardPricebook.Id];
            system.debug('standardPricebook= '+standardPricebook);
            List<Product2> productLst = new List<Product2>();
            Product2 product = new Product2(
                Name = 'TestProduct',
                IsActive = true, 
                //SBQQ__SubscriptionPricing__c = 'Fixed Price', 
                //SBQQ__SubscriptionTerm__c = 12, 
                //SBQQ__SubscriptionType__c = 'Renewable',
                License_Type_INF__c = 'Perpetual'
            );
            insert product;
            
            PricebookEntry pbEntry = new PricebookEntry();
            List<PricebookEntry> pbentries = [SELECT Id, CurrencyISOCode from PricebookEntry where pricebook2Id =:standardPricebook.Id AND currencyISOCode=: standardPricebook.CurrencyIsoCode AND Product2Id =: product.Id ];
            system.debug('pbentries= '+pbentries);
            if(pbentries != null && pbentries.size() > 0){
                pbEntry = pbentries[0];
            } else {
                pbEntry = new PricebookEntry(
                    Pricebook2Id = standardPricebook.Id,
                    Product2Id = product.Id,
                    UnitPrice = 120.00,
                    IsActive = true,
                    currencyISOCode = 'USD'
                );
                insert pbEntry;
            }
            
            /*Product2 product = new Product2();
List<Product2> products = [SELECT Id from Product2 WHERE SBQQ__SubscriptionType__c ='Renewable' AND Business_Unit__c ='INFORMATICS' LIMIT 1];
product = products[0];

List<PricebookEntry> pbEntries= [SELECT ID from PricebookEntry WHERE product2Id =: product.Id];
PricebookEntry pbEntry = new PricebookEntry();
pbEntry = pbEntries[0]; */
            
            //create Account
            Account acc = new Account();
            acc.name = 'Test Account';
            acc.ShippingCity = 'test city';
            acc.ShippingCountry = 'US';
            acc.ShippingPostalCode = '12345678';
            acc.ShippingState = 'AX';
            acc.ShippingStreet = 'Test Street';
            insert acc;
            
            Opportunity opprt = new Opportunity(Name='TestOpprt',AccountId=acc.id,Strategic_Market_INF__c='Life Sciences Research', recordtypeId = INFORMATICS_RECORDTYPEID, Application__c = 'Materials', Application_Segment__c = 'Informatics', Application_Market__c = 'Applied'
                                                ,Type='New Products',CloseDate=System.today() + 120,StageName='Stage 6 - Implement (Closed)',Pricebook2Id = Test.getStandardPricebookId(), currencyISOCode ='USD',CountofRenewalProducts__c = 1);
            insert opprt;
            
            
            /*SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Primary__c  =true, Quote_Name__c='TestQuote',SBQQ__StartDate__c=System.today() 
                                                      ,SBQQ__Opportunity2__c=opprt.Id,SBQQ__Account__c=acc.Id, SBQQ__PricebookId__c = Test.getStandardPricebookId(), currencyISOCode ='USD' );
            insert quote;*/
            Test.startTest();
            
            
            /*SBQQ__QuoteLine__C quoteline = new SBQQ__QuoteLine__C(
                SBQQ__Product__c = product.Id,
                SBQQ__Quote__c = quote.Id,
                SBQQ__PricebookEntryId__c = pbEntry.Id,
                SBQQ__DefaultSubscriptionTerm__c = 12,
                SBQQ__Quantity__c = 1,
                SBQQ__SubscriptionPricing__c='Fixed Price',
                CurrencyISOCode ='USD'
            );
            
            
            insert quoteline;
            
            quote.SBQQ__Ordered__c=true;
            update quote; */
        }
        Batch_AutoActivateOrderBatch testAutoActivateBatch = new Batch_AutoActivateOrderBatch();
        Database.executeBatch(testAutoActivateBatch);
        Test.stopTest();
        
    }
    
    public static testmethod void testAutoActivateOrderSchedular(){
        Test.startTest();
        Batch_AutoActivateOrderBatch_Scheduler schedularClass = new Batch_AutoActivateOrderBatch_Scheduler();
        String schedularTime = '0 0 0,2,4,6,8,10,12,14,16,18,20,22 * * ? * *'; 
        system.schedule('Auto Activate Order1', schedularTime, schedularClass); 
        Test.stopTest();
    }
}
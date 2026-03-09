@isTest(seeAllData=true)
private class OrderProcessingStatus_Test {
static testMethod void OrderProcessingStatus(){

   Account acc = new Account ();
 //  acc.RecordTypeId = '01230000000cPp0';
    acc.name='Test Account';
    acc.shippingCountry = 'US';
    acc.Industry ='Biotech';
    acc.CurrencyIsoCode = 'USD';
    insert acc;
    
    Contact co = new Contact ();
     co.AccountId=acc.id;
     co.FirstName='Test Name';
     co.LastName='Test';
     insert co;

    Opportunity opp= new Opportunity();
      opp.name='testOpp';
      opp.AccountId=acc.id;
      opp.Primary_Contact__c = co.Id;
      opp.Renewal_Required_INF__c='Yes';
      opp.Probability = 5;
      opp.closeDate=system.today()+20;
      opp.RecordTypeId= Utility_Informatics.opportunity_Informatics;
      opp.Account_Type_INF__c='Academic';
      opp.stageName='Stage 1 - Qualification';
      opp.Solution_Area_of_Interest__c='Energy';
    insert opp;
     /* opp.stageName='Stage 2 - Needs Analysis';
    Update opp; */




//get standard pricebook
Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];


Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
insert pbk1;

Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd1;

Product2 prd2 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd2;



//PricebookEntry pbe1 = [select id from PricebookEntry where Product2ID=:prd1.id and Pricebook2ID=:standardPb.id limit 1];
PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
        UseStandardPrice=false,UnitPrice=50);
insert pbe2;



List<opportunitylineitem> opppro = new opportunitylineitem[]{new opportunitylineitem(UnitPrice=10000.00, Quantity=10, opportunityid=opp.id, pricebookEntryId=pbe2.id)};

insert opppro;

opp.stageName='Stage 6 - Implement (Closed)';
opp.Probability =100;

update opp;

 for(Opportunity op :[Select Id,Order_Processing_Status_INF__c,
                          (Select PricebookEntry.Product2.Product_Type_INF__c,PricebookEntry.Product2.License_Type_INF__c From OpportunityLineItems
                           WHERE (PricebookEntry.Product2.License_Type_INF__c ='Services' OR PricebookEntry.Product2.Product_Type_INF__c ='Services'OR PricebookEntry.Product2.Name='OneSource LABIT' OR PricebookEntry.Product2.product_line__c ='OMV'))                                    
                        From Opportunity o where Id =: opp.id]){
    
    if(op.OpportunityLineItems.size()>0)
    {
       for(OpportunityLineItem oppl : op.OpportunityLineItems)
           {
             op.Order_Processing_Status_INF__c = 'Submitted';
             op.GP_OrderNum_INF__c = '#';
             
                      
           } 
       
      } 
   
}

    
}


    
}
@isTest(seeAllData=true)
private class TestCreateRenewalOppClosedWon {
 public static void test_UpdateTargets()
    {
        User user = [select Id FROM User where IsActive = true LIMIT 1];
        Territory2 territory;
        System.runAs(user)
        {
        
            territory = new Territory2(
                Name = 'Apex Test Territory');
       //     insert territory;
            System.assertNotEquals(territory2.Id, null);
        }  
     }
 static testMethod void CreateRenewalOnlosedWonOpportunity(){
 Set<Id> SetOfOppIds = new Set<Id>();
    
    /* Added by Gireesh AccountId='0013000001DIhdl' */
    List<Opportunity> newOpps = new List<Opportunity>();
     List<Opportunity> listOfOpp = new List<Opportunity>();
     
     Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
    
        for (Integer i = 0; i < 10; i++)
         {  
             
            // RecordType optyrecordtype = [select id from recordType where Name='informatics' limit 1];
           newOpps.add(new Opportunity(Name='opp'+i,AccountId=ac.Id,Probability=99,Renewal_Required_INF__c='Yes'/*,RecordTypeId='01230000001aIi6'*/,Account_Type_INF__c='Academic',Primary_Contact__c=co.Id,StageName='Stage 7 - Submit Order',CloseDate=Date.today(),Revenue_Rec_Date__c = Date.today(),Solution_Area_of_Interest__c='Energy'));
         }
        insert newOpps;
        
        
//get standard pricebook
Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];


Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
insert pbk1;

Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd1;

Product2 prd2 = new Product2 (Name='test product',ProductCode='CPH568',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 2');
insert prd2;

Product2 prd3 = new Product2 (Name='test product',ProductCode='CPH569',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 3');
insert prd3;



PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
        UseStandardPrice=false,UnitPrice=50);
insert pbe2;

// Create a task for each one
List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>();
List<Opportunity> OppsUpdate = new List<Opportunity>();
  

for(Opportunity opp : newOpps){
newLineItems.add(new OpportunityLineItem(OpportunityID=opp.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbe2.id));
//newLineItems.add(new OpportunityLineItem(OpportunityID=opp.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbe2.id));
SetOfOppIds.add(opp.id);
}
insert newLineItems;

 /*for(Opportunity op :[Select Id,
                          (Select Type_INF__c, PricebookEntry.Product2.License_Type_INF__c,Start_Date_INF__c, Product_Status__c,
                           Product_Line__c,Quantity, Product_Family__c,OpportunityId, Id, End_Date_INF__c,PricebookEntryId,
                           UnitPrice,PricebookEntry.Product2.Product_Type_INF__c From OpportunityLineItems
                           WHERE (PricebookEntry.Product2.License_Type_INF__c ='Services' OR PricebookEntry.Product2.Product_Type_INF__c ='Services'))                                    
                        From Opportunity o where Id IN:SetOfOppIds]){
    
    if(op.OpportunityLineItems.size()>0)
    {
       for(OpportunityLineItem opp : op.OpportunityLineItems)
           {
             op.Order_Processing_Status_INF__c = 'Revenue Review Required';
             listOfOpp.add(op);           
           } 
             if(listOfOpp.size()>0)
                  update listOfOpp;    
      } 
}*/

    
}

 static testMethod void CreateRenewalOnlosedWon(){
 
  Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
           
           id rtID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

           Opportunity opp=new Opportunity();
           opp.Name='opl';
           opp.AccountId=ac.Id;
           opp.RecordtypeId=rtID;
           opp.Probability=99;
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=true;
           opp.Account_Type_INF__c='Academic';
           opp.Primary_Contact__c=co.Id;
           opp.StageName='Stage 2 - Qualified';
           opp.CloseDate=Date.today();
           opp.Revenue_Rec_Date__c = Date.today();
           opp.Solution_Area_of_Interest__c='Energy';
           insert opp;
           
          
           opp.StageName='Closed Won';
           opp.Run_Rate_Opp_INF__c=false;
           opp.Renewal_Required_INF__c='Yes';
      opp.GP_OrderNum_INF__c='12312';   
           update opp; 
 }
 
 
 static testMethod void Createopptesr(){
 
  Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
           
           id rtID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

           Opportunity opp=new Opportunity();
           opp.Name='opl';
           opp.AccountId=ac.Id;
           opp.RecordtypeId=rtID;
           opp.Probability=99;
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=true;
           opp.Account_Type_INF__c='Academic';
           opp.Primary_Contact__c=co.Id;
           opp.StageName='Stage 2 - Qualified';
           opp.CloseDate=Date.today();
           opp.Revenue_Rec_Date__c = Date.today();
           opp.Solution_Area_of_Interest__c='Energy';
       opp.GP_OrderNum_INF__c='12312';
           insert opp;
           
          
           opp.StageName='Stage 6 - Implement (Closed)';
      opp.GP_OrderNum_INF__c='12312';
           update opp; 
 }
 
 
  
 static testMethod void setOfOpp_NonRenew(){
 
  Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
           
           id rtID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

           Opportunity opp=new Opportunity();
           opp.Name='opl';
           opp.AccountId=ac.Id;
           opp.RecordtypeId=rtID;
           opp.Probability=99;
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=true;
           opp.Account_Type_INF__c='Academic';
           opp.Primary_Contact__c=co.Id;
           opp.StageName='Stage 2 - Qualified';
           opp.CloseDate=Date.today();
           opp.Revenue_Rec_Date__c = Date.today();
           opp.Solution_Area_of_Interest__c='Energy';
       opp.GP_OrderNum_INF__c='12312';
           insert opp;
           
          
           opp.StageName='Closed Won';
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=false;
       opp.GP_OrderNum_INF__c='12312';
           update opp; 
Test.startTest();           
           //get standard pricebook
Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];


Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
insert pbk1;

Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd1;

Product2 prd2 = new Product2 (Name='test product',ProductCode='CPH568',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 2');
insert prd2;

Product2 prd3 = new Product2 (Name='test product',ProductCode='CPH569',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 3');
insert prd3;



PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
        UseStandardPrice=false,UnitPrice=50);
insert pbe2;
           
          OpportunityLineItem opl= new OpportunityLineItem();
          opl.OpportunityID=opp.id;
          opl.Start_Date_INF__c=Date.today();
          opl.End_Date_INF__c=Date.today();
          opl.TotalPrice=10;
          opl.Quantity=1;
          opl.PriceBookEntryID=pbe2.id;
          insert opl;
     Test.stopTest();
           
 }
 
 
  
 static testMethod void setOfOpp_allCpb(){
 
  Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
           
           id rtID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

           Opportunity opp=new Opportunity();
           opp.Name='opl';
           opp.AccountId=ac.Id;
           opp.RecordtypeId=rtID;
           opp.Probability=99;
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=true;
           opp.Account_Type_INF__c='Academic';
           opp.Primary_Contact__c=co.Id;
           opp.StageName='Stage 2 - Qualified';
           opp.CloseDate=Date.today();
           opp.Revenue_Rec_Date__c = Date.today();
           opp.Solution_Area_of_Interest__c='Energy';
       opp.GP_OrderNum_INF__c='12312';
           insert opp;
           
          
           opp.StageName='Closed Won';
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=false;
       opp.GP_OrderNum_INF__c='12312';
           update opp; 
     Test.startTest();
           
           //get standard pricebook
Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];


Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
insert pbk1;

Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Perpetual',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd1;

Product2 prd2 = new Product2 (Name='test product',ProductCode='CPH568',License_Type_INF__c='Perpetual',Product_Type_INF__c='Services',Description='Test Product Entry 2');
insert prd2;

Product2 prd3 = new Product2 (Name='test product',ProductCode='CPH569',License_Type_INF__c='Perpetual',Product_Type_INF__c='Services',Description='Test Product Entry 3');
insert prd3;



PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
        UseStandardPrice=false,UnitPrice=50);
insert pbe2;
           
          OpportunityLineItem opl= new OpportunityLineItem();
          opl.OpportunityID=opp.id;
          opl.Start_Date_INF__c=Date.today();
          opl.End_Date_INF__c=Date.today();
          opl.TotalPrice=10;
          opl.Quantity=1;
          opl.PriceBookEntryID=pbe2.id;
          insert opl;
          
          //Now update the OCR for the primary contact
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = co.Id;
        ocr.OpportunityId = opp.Id;
        ocr.IsPrimary = TRUE;
        ocr.Role = 'Decision Maker';
        insert ocr;
     
     Test.stopTest();
          
           
 }
 
 static testMethod void setOfOpp_allprime(){
 
  Account ac = new Account ();
          
            ac.name='Test Account';
            ac.shippingCountry = 'US';
            ac.Industry ='Biotech';
            ac.CurrencyIsoCode = 'USD';
            ac.BillingStreet = 'Street1';
            ac.BillingCity = 'City1';
            ac.BillingState = 'State';
            ac.BillingCountry ='US';
            ac.BillingPostalCode = '12345';
            insert ac;
            
           /* Insert an Contact */
           Contact co = new Contact ();
           co.AccountId=ac.id;
           co.FirstName='Test Name';
           co.LastName='Test';
           insert co;
           
           id rtID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

           
           Opportunity opp=new Opportunity();
           opp.Name='opl';
           opp.AccountId=ac.Id;
           opp.RecordtypeId=rtID;
           opp.Probability=99;
           opp.Renewal_Required_INF__c='No';
           opp.Run_Rate_Opp_INF__c=true;
           opp.Account_Type_INF__c='Academic';
           opp.Primary_Contact__c=co.Id;
           opp.StageName='Stage 2 - Qualified';
           opp.CloseDate=Date.today();
           opp.Revenue_Rec_Date__c = Date.today();
           opp.Solution_Area_of_Interest__c='Energy';
           insert opp;
           
          
           opp.StageName='Closed Won';
           opp.Run_Rate_Opp_INF__c=false;
           opp.Renewal_Required_INF__c='Yes';
      opp.GP_OrderNum_INF__c='12312';   
           update opp; 
     Test.startTest();
           
           //get standard pricebook
//Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];



// Instantiate the Pricebook2 record first, setting the Id
Pricebook2 standardPricebook = new Pricebook2(
    Id = Test.getStandardPricebookId(),
    IsActive = true
);

// Run an update DML on the Pricebook2 record
// This is the weird workaround that enables IsStandard to become true
// on the PricebookEntry record
standardPricebook.name='Informatics';


// Re-Query for the Pricebook2 record, for debugging
Pricebook2  standardPb  = [SELECT IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];




Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
insert pbk1;

Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Subscription',Product_Type_INF__c='Services',Description='Test Product Entry 1');
insert prd1;

Product2 prd2 = new Product2 (Name='test product',ProductCode='CPH568',License_Type_INF__c='Subscription',Product_Type_INF__c='Services',Description='Test Product Entry 2');
insert prd2;

Product2 prd3 = new Product2 (Name='test product',ProductCode='CPH569',License_Type_INF__c='Subscription',Product_Type_INF__c='Services',Description='Test Product Entry 3');
insert prd3;



PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
        UseStandardPrice=false,UnitPrice=50);
insert pbe2;


           
          OpportunityLineItem opl= new OpportunityLineItem();
          opl.OpportunityID=opp.id;
          opl.Start_Date_INF__c=Date.today();
          opl.End_Date_INF__c=Date.today();
          opl.TotalPrice=10;
          opl.Quantity=1;
          opl.PriceBookEntryID=pbe2.id;
          insert opl;
          
          //Now update the OCR for the primary contact
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = co.Id;
        ocr.OpportunityId = opp.Id;
        ocr.IsPrimary = TRUE;
        ocr.Role = 'Decision Maker';
        insert ocr;
          Test.stopTest();
           
 }
 
 
}
@isTest(seeAllData=true)
public class TestDelOppLineTrigger {
	static testMethod void Test_Method1(){
        Opportunity newOpps = new Opportunity();
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
        System.debug('#######ACC:' + ac.Id);
		newOpps = new Opportunity(Name='opp1',AccountId=ac.Id,/*RecordTypeId='01230000001aIi6',*/Renewal_Required_INF__c='Yes',Account_Type_INF__c='Academic',StageName='Stage 1 - Create/Plan',CloseDate=Date.today(),Strategic_Market_INF__c='Clinical',Type='New Account',ForecastCategoryName='Pipeline',CurrencyIsoCode = 'USD',Solution_Area_of_Interest__c='Energy');        
        insert newOpps;
        
        Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];

        Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
        insert pbk1;
        
        Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',License_Type_INF__c='Services',Product_Type_INF__c='Services',Description='Test Product Entry 1');
		insert prd1;
        
        PricebookEntry pbe2 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=standardPb.id,IsActive=true,UseStandardPrice=false,UnitPrice=50);
		insert pbe2;
        System.debug('#######OPP:' + newOpps.Id);
        List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>();
        newLineItems.add(new OpportunityLineItem(OpportunityID=newOpps.id,Start_Date_INF__c=Date.today(),End_Date_INF__c=Date.today(),TotalPrice=10,Quantity=1,PriceBookEntryID=pbe2.id));
        insert newLineItems;
		System.debug('#######LineItem:' + newLineItems[0].Id);
          
        OpportunityLineItem opline = new OpportunityLineItem();
        opline.Id = newLineItems[0].Id;
        delete opline;
    }
}
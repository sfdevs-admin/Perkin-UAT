@isTest(seeAllData=true)
private class INF_Validates_Analytics_Test {
    
    static Id AccountRTId;
    static ID OpportunityRTId;
    static List<RecordType> rtList = null;
    
    static testMethod void INF_Validates_Analytics(){
        
        Set<Id> SetOfOppIds = new Set<Id>();
        List<Opportunity> listOfOpp = new List<Opportunity>();
        List<Opportunity> newOpps = new List<Opportunity>();
        List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>();
        
        
        
        rtList =[Select Id, DeveloperName, SobjectType  from RecordType 
                 Where SobjectType IN ('Account','Opportunity')
                 And DeveloperName IN('ProspectAccount','Informatics') ];
        
        if(rtList.size() > 0)
        {
            for(RecordType r: rtList)
            {  
                if(r.DeveloperName == 'ProspectAccount' && r.SobjectType == 'Account')
                    AccountRTId = r.id;
                if(r.DeveloperName == 'Informatics' && r.SobjectType == 'Opportunity')
                    OpportunityRTId = r.id;        
            }
        }
        
        Account acc = new Account ();
        acc.RecordTypeId = AccountRTId;
        
        acc.name='Test Account#2-2-2018';
        acc.shippingCountry = 'US';
        acc.Industry ='Biotech';
        acc.CurrencyIsoCode = 'USD';
        insert acc;
        
        for (Integer i = 0; i < 1; i++)
        {  
            newOpps.add(new Opportunity(Name='opp'+i,AccountId=acc.id,Probability=10,Renewal_Required_INF__c='Yes',RecordTypeId=OpportunityRTId,Account_Type_INF__c='Academic',StageName='Stage 1 - Create/Plan',CloseDate=Date.today(),Solution_Area_of_Interest__c='Energy'));
        }
        
        insert newOpps;
        newOpps[0].StageName='Stage 2 - Qualify';
        
        update newOpps;
        
        //get standard pricebook
        Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
        Pricebook2 pbk1 = new Pricebook2 (Name='Test Pricebook Entry 1',Description='Test Pricebook Entry 1');
        insert pbk1;
        Product2 prd1 = new Product2 (Name='Term test',ProductCode='CPH567',INF_Split__c='Yes');
        insert prd1;
        Product2 prd2 = new Product2 (Name ='Test',ProductCode='CPH568',INF_Split__c='Yes');
        insert prd2;
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd2.id,Pricebook2ID=standardPb.id,IsActive=true,
                                                  UseStandardPrice=false,UnitPrice=50);
        insert pbe1;
        
        for(Opportunity opp2 : newOpps){
            newLineItems.add(new OpportunityLineItem(OpportunityID=opp2.id,UnitPrice=10000.00,Quantity=10,PriceBookEntryID=pbe1.id));
            SetOfOppIds.add(opp2.id);
        }
        insert newLineItems;
        
        for(Opportunity op : [Select Id,INF_Analytics_AVS__c,
                              (Select Product2.Family,OpportunityId,Product2.INF_Split__c From OpportunityLineItems
                               WHERE  isDeleted = false AND Product2.INF_Split__c='Yes' )                                    
                              From Opportunity o where Id IN:SetOfOppIds]){
                                  if(op.OpportunityLineItems.size()>0)
                                  {
                                      for(OpportunityLineItem opp1 : op.OpportunityLineItems)
                                      {
                                          
                                          op.stageName='Stage 5 - Negotiation';
                                          op.Probability =99;
                                          op.INF_Analytics_AVS__c = 50;
                                          listOfOpp.add(op);
                                      }
                                      
                                      if(listOfOpp.size()>0){
                                          
                                          try {
                                              update listOfOpp;   
                                          } catch (DmlException e) {
                                              System.debug('test');
                                          }
                                      }
                                  }}
    } }
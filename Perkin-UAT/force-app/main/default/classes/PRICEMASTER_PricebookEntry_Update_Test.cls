/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ITSFDC-4691
*    - ITSFDC-####
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    this is test class for PRICEMASTER_PricebookEntry_Update_Batch
*
* 3. Objects referenced
*    -PRICE_Master__c
*    -PriceBookEntry
*	 - Product2	
*	 -Pricebook2
*
* 4. Class Name: PRICEMASTER_PricebookEntry_Update_test
*
*
* 5. Author Name(s): 
*    - Vishwas Gupta (2021.07.26)
*    - First Last & Updated Date(YYYY.MM.DD)
*    - First Last & Updated Date(YYYY.MM.DD)
*
*************************************************************/ 
@isTest
public class PRICEMASTER_PricebookEntry_Update_Test {
    @testSetup static void setup() {
        list<price_master__c> prmlist = new list<price_master__c>();
       price_master__c prm = new price_master__c();
        prm.External_Id__c='testpartnum-StandardPriceBook-USD';
        prm.PriceBook_Name__c='standard price book';
        prm.Product_Number__c='testpartnum';
        prm.Amount__c=10;
         prm.name='BOOMI-START-TIME';
        prmlist.add(prm);
         price_master__c prminsrt = new price_master__c();
        prminsrt.PriceBook_Name__c='Standard Price Book';
        prminsrt.Product_Number__c='testpartnuminsert';
        prminsrt.CurrencyIsoCode='USD';
        prminsrt.External_Id__c='testpartnuminsert-StandardPriceBook-USD';
        prminsrt.Amount__c=20;
         prminsrt.name='testpartnuminsert';
        prmlist.add(prminsrt);
        price_master__c prminsrterr = new price_master__c();
        prminsrterr.PriceBook_Name__c='Standard Price Book';
        prminsrterr.Product_Number__c='testpartnum';
        prminsrterr.CurrencyIsoCode='USD';
        prminsrterr.External_Id__c='testpartnuminserterr-StandardPriceBook-USD';
        prminsrterr.Amount__c=20;
        prminsrterr.name='testpartnuminserterr';
        prmlist.add(prminsrterr);
        price_master__c prmend = new price_master__c();
        prmend.PriceBook_Name__c='Standard Price Book';
        prmend.Product_Number__c='testpartnuminsert';
        prmend.CurrencyIsoCode='USD';
        prmend.External_Id__c='testpartnum1-StandardPriceBook-USD';
        prmend.Amount__c=20;
         prmend.name='BOOMI-END-TIME';
        prmlist.add(prmend);
        insert prmlist;
       
        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                name='Standard Price Book',
                IsActive = true
            );
        upsert standardPricebook;
        Product2 pro = new Product2(Name = 'testpartnum', Family = 'Mobile',partNum__c='testpartnum',Business_Unit__c=null);
          Insert pro;
        Product2 pro1 = new Product2(Name = 'testpartnum1', Family = 'Mobile',partNum__c='testpartnum1',Business_Unit__c=null);
          Insert pro1;
        Product2 proinsert = new Product2(Name = 'testpartnuminsert', Family = 'Mobile',partNum__c='testpartnuminsert',Business_Unit__c=null);
          Insert proinsert;
       pricebookEntry pbe= new pricebookEntry(
        product2Id=pro.Id,
        Pricebook2Id=standardPricebook.Id,
        Pricebook_entry_ID__c='testpartnum-StandardPriceBook-USD',
        UnitPrice =02   
        );
        insert pbe; 
        pricebookEntry pbe1= new pricebookEntry(
        product2Id=pro1.Id,
        Pricebook2Id=standardPricebook.Id,
        Pricebook_entry_ID__c='testpartnum1-StandardPriceBook-USD',
        UnitPrice =02   
        );
        insert pbe1; 
      //  
              //Create Product
         
         
        
    }static testMethod void testMethod1(){
        List<Product2> prdlst=[select id,name,partNum__c from product2];
        system.debug('prdlst=='+prdlst);
        list<pricebook2> prclst=[select id,name from pricebook2];
        system.debug('prclst=='+prclst);
        list<price_master__c> prlst=[select name,lastmodifieddate from price_master__c Where name='BOOMI-END-TIME' limit 1];
         Update prlst; 
         Database.executeBatch(new PRICEMASTER_PricebookEntry_Update_Batch(), 2000);
     }
	// static testMethod void testMethod2(){
         
      //   Database.executeBatch(new PRICEMASTER_PricebookEntry_Update_Batch(), 2000);
//    }
}
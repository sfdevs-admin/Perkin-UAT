@isTest(seealldata=true)
Public Class Test_BatchToUpdatePriceBookEntryCode{
    Public Static TestMethod void MyUnitTest1() {
        
        Id standardPBId = Test.getStandardPriceBookId();
        
        Pricebook2 pb = new pricebook2(name='test');
        insert pb;
        
        //insert a new product
        Product2 p = new product2(name='x', PartNum__c = '1234');
        insert p;       

        //Pricebook2 pb = new pricebook2(name='test');
        //insert pb;

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = p.Id, UnitPrice = 1.0, IsActive = true, CurrencyIsoCode='USD');
        insert standardPrice;
        
        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id=p.id,unitprice=1.0, isActive=true, CurrencyIsoCode='USD');
        insert pbe;
        
        // Get the datetime value 1 min from now.
        DateTime timeToSchedule = System.now().addMinutes(1);
        
        // Form the CRON Expression
        String expression = '0 ' + timeToSchedule.minute() + ' ' + timeToSchedule.hour() + ' ' +  timeToSchedule.day() + ' ' + timeToSchedule.month() + ' ? ' + timeToSchedule.year();
        // Schedule the batch class
        Test.startTest();
        System.schedule('Test-UpdatePriceBookEntryCode - ' + String.valueOf(Datetime.now()), expression, new ScheduleBatchToUpdatePriceBookEntryCode());
        Test.stopTest();
        
    }
    Public Static TestMethod void MyUnitTest2() {
        
        //insert a new product
        Product2 p = new product2(name='x', PartNum__c = '1234');
        insert p;       

        Id standardPBId = Test.getStandardPriceBookId();

        Pricebook2 pb = new pricebook2(name='test');
        insert pb;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = p.Id, UnitPrice = 1.0, IsActive = true, CurrencyIsoCode='USD');
        insert standardPrice;
        
        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id=p.id,unitprice=1.0, isActive=true, CurrencyIsoCode='USD');
        insert pbe;
        
        Test.startTest();
        BatchToUpdatePriceBookEntryCode obj = new BatchToUpdatePriceBookEntryCode();
        Database.executeBatch(obj, 2000);
        Test.stopTest();
        
    }
}
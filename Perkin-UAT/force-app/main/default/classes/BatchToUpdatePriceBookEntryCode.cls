global class BatchToUpdatePriceBookEntryCode implements Database.Batchable<SObject>,Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String Query;
        if(!Test.isRunningTest())
            Query='SELECT Id, Pricebook2Id, Pricebook2.Name, Product2Id, Product2.PartNum__c, CurrencyIsoCode, Pricebook_entry_ID__c FROM PricebookEntry where Pricebook_entry_ID__c = null and Pricebook2.Name != null and CurrencyIsoCode != null and Product2.PartNum__c != null';
        else
            Query='SELECT Id, Pricebook2Id, Pricebook2.Name, Product2Id, Product2.PartNum__c, CurrencyIsoCode, Pricebook_entry_ID__c FROM PricebookEntry where Pricebook_entry_ID__c = null and Pricebook2.Name != null and CurrencyIsoCode != null and Product2.PartNum__c != null limit 100';
        return  Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext BC, List<PricebookEntry> sObjectsFromStart) 
    {
        List<PricebookEntry> lstToUpdatePricebookEntry=new List<PricebookEntry>();
        for(PricebookEntry iter: sObjectsFromStart){
            iter.Pricebook_entry_ID__c = iter.Product2.PartNum__c + '-' + iter.Pricebook2.Name +'-'+ iter.CurrencyIsoCode;
            lstToUpdatePricebookEntry.add(iter);
        }
        update lstToUpdatePricebookEntry;
    }
    
    global void finish(Database.BatchableContext BC) {
    
    }
}
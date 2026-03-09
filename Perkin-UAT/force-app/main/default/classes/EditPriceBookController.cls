/*
  Class : EditPriceBookController
  Created By  : Lister
  Created Date : 12th Feb 2021
  Test Class : Test_EditPriceBookController
  Description: Controller for edit Pricebook entries from the Product page
*/
public with sharing class EditPriceBookController {
    @auraEnabled
    public static List<PriceBookWrapper> getRelatedStdPricebooks(Id productId){
        List<PriceBookWrapper> listofPricebookWrapper = new List<PriceBookWrapper>();
        for(PricebookEntry iterPriceBookEntry : [SELECT Id, Pricebook2.Name, Pricebook2.IsStandard, IsActive, CurrencyIsoCode, PKI_PBE_ID_check__c, Pricebook_Entry_Formula__c, Pricebook2Id, Product2.Name,
                                                ProductCode, UnitPrice, UseStandardPrice FROM PricebookEntry WHERE Product2Id =: productId AND Pricebook2.IsStandard = true ORDER BY CurrencyIsoCode]){
            PriceBookWrapper wrapperObj = new PriceBookWrapper();
            wrapperObj.Id = iterPriceBookEntry.Id;
            wrapperObj.Product = iterPriceBookEntry.Product2.Name;            
            wrapperObj.Pricebook = iterPriceBookEntry.Pricebook2.Name;
            wrapperObj.PricebookId = '/' + iterPriceBookEntry.Pricebook2Id;
            wrapperObj.UseStandardPrice = iterPriceBookEntry.UseStandardPrice;
            wrapperObj.UnitPrice = iterPriceBookEntry.UnitPrice;
            wrapperObj.CurrencyIsoCode = iterPriceBookEntry.CurrencyIsoCode;
            wrapperObj.IsActive = iterPriceBookEntry.IsActive;
            listofPricebookWrapper.add(wrapperObj);
        }
        return listofPricebookWrapper;
    }

    @auraEnabled
    public static List<PriceBookWrapper> getRelatedPricebooks(Id productId){
        List<PriceBookWrapper> listofPricebookWrapper = new List<PriceBookWrapper>();
        Map<String, Decimal> mapofCurrrencytoListPrice = new Map<String, Decimal>();
        for(PricebookEntry iterPriceBookEntry : [SELECT Id, CurrencyIsoCode, UnitPrice FROM PricebookEntry WHERE Product2Id =: productId AND Pricebook2.IsStandard = true]){
                mapofCurrrencytoListPrice.put(iterPriceBookEntry.CurrencyIsoCode, iterPriceBookEntry.UnitPrice);
        }
        for(PricebookEntry iterPriceBookEntry : [SELECT Id, Pricebook2.Name, Pricebook2.IsStandard, IsActive, CurrencyIsoCode, PKI_PBE_ID_check__c, Pricebook_Entry_Formula__c, Pricebook2Id, Product2.Name,
                                                ProductCode, UnitPrice, UseStandardPrice FROM PricebookEntry WHERE Product2Id =: productId AND Pricebook2.IsStandard = false ORDER BY CurrencyIsoCode, Pricebook2.Name]){
            PriceBookWrapper wrapperObj = new PriceBookWrapper();
            wrapperObj.Id = iterPriceBookEntry.Id;
            wrapperObj.Product = iterPriceBookEntry.Product2.Name;
            wrapperObj.Pricebook = iterPriceBookEntry.Pricebook2.Name;
            wrapperObj.PricebookId = '/' + iterPriceBookEntry.Pricebook2Id;
            wrapperObj.UseStandardPrice = iterPriceBookEntry.UseStandardPrice;
            wrapperObj.UnitPrice = iterPriceBookEntry.UnitPrice;
            wrapperObj.CurrencyIsoCode = iterPriceBookEntry.CurrencyIsoCode;
            wrapperObj.IsActive = iterPriceBookEntry.IsActive;
            wrapperObj.StandardPrice = iterPriceBookEntry.CurrencyIsoCode +' '+ mapofCurrrencytoListPrice.get(iterPriceBookEntry.CurrencyIsoCode);
            listofPricebookWrapper.add(wrapperObj);
        }
        return listofPricebookWrapper;
    }

    @auraEnabled
    public static String updatePricebook(List<PricebookEntry> listofPricebookEntry){
        try {                
            Boolean isStdPrice = false;
            Set<Id> setofPBE = new Set<Id>();
            Set<Id> setofProducts = new Set<Id>();
            List<PricebookEntry> listofPBEtoUpdate = new List<PricebookEntry>();
            Map<String, Decimal> mapofCurrrencytoListPrice = new Map<String, Decimal>();
            Map<Id,PricebookEntry> mapofPBE = new Map<Id,PricebookEntry>();

            for(PricebookEntry iPBE : listofPricebookEntry){
                if(iPBE.UseStandardPrice){
                    isStdPrice = true;
                }
            }
            for(PricebookEntry iterPBE : [SELECT Id, CurrencyIsoCode, Product2Id, UseStandardPrice, UnitPrice FROM PricebookEntry WHERE Id IN: listofPricebookEntry]){
                setofProducts.add(iterPBE.Product2Id);
                mapofPBE.put(iterPBE.Id, iterPBE);
            }

            if(!isStdPrice){
                for(PricebookEntry iPBE : listofPricebookEntry){
                    if(iPBE.UnitPrice != null && mapofPBE.get(iPBE.Id).UseStandardPrice == true){
                        return 'You may not be able to change the list price of Standard Pricebook in one of the records.';
                    } else {
                        listofPBEtoUpdate.add(iPBE);
                    }
                }
            } else {
                for(PricebookEntry iterPriceBookEntry : [SELECT Id, CurrencyIsoCode, UnitPrice FROM PricebookEntry WHERE Product2Id IN: setofProducts AND Pricebook2.IsStandard = true]){
                        mapofCurrrencytoListPrice.put(iterPriceBookEntry.CurrencyIsoCode, iterPriceBookEntry.UnitPrice);
                }
                
                for(PricebookEntry iPBE : listofPricebookEntry){
                    if(iPBE.UseStandardPrice){
                        iPBE.UnitPrice = mapofCurrrencytoListPrice.get(mapofPBE.get(iPBE.Id).CurrencyIsoCode);
                        listofPBEtoUpdate.add(iPBE);
                    }  
                }                                
            }
            system.debug('listofPBEtoUpdate--->'+listofPBEtoUpdate);
            if(listofPBEtoUpdate.size() > 0)
                update listofPBEtoUpdate; 
            return 'Success';                
        } catch(Exception e) {    
            system.debug('e--->'+e+'--->'+e.getLineNumber());      
            return e.getMessage();                
        } 
        
    }

    public class PriceBookWrapper{
        @AuraEnabled 
        public String Id;
        @AuraEnabled 
        public String Product;
        @AuraEnabled 
        public String PricebookId;
        @AuraEnabled 
        public String Pricebook;
        @AuraEnabled 
        public Boolean UseStandardPrice;
        @AuraEnabled 
        public String StandardPrice;
        @AuraEnabled 
        public Decimal UnitPrice;
        @AuraEnabled 
        public Boolean IsActive;
        @AuraEnabled
        public String CurrencyIsoCode;
    }
}
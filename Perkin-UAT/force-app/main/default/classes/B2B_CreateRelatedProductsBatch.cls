/**
 * test class- B2B_CreateRelatedProductsBatchTest
*/
public with sharing class B2B_CreateRelatedProductsBatch implements Database.Batchable<sObject> {

    public final String QueryStr;

    // SELECT Id, B2B_Alternate_Products__c, B2B_SKU__c FROM Product2 where B2B_Has_Related_Product__c = true
    public B2B_CreateRelatedProductsBatch( String query ) {
        QueryStr = query;
        System.debug('B2B_CreateRelatedProductsBatch Query-- '+QueryStr);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('B2B_CreateRelatedProductsBatch start Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope){
        try {
            List<Id> productIds = new List<Id>();
            List<B2B_Related_Product__c> relatedProductsToInsert = new List<B2B_Related_Product__c>();
            Map<String,Id> productSkuVsIdMap = new Map<String,Id>();
            //HT: Query Updated
            List<Product2> allProducts = [ SELECT Id, B2B_SKU__c FROM Product2 WHERE B2B_SKU__c != null AND Is_B2B_Product__c = true ];
            if( ! allProducts.isEmpty() ){
                for( Product2 prod : allProducts ){
                    productSkuVsIdMap.put(prod.B2B_SKU__c, prod.Id);
                }   
                for( Product2 prod : scope ){
                    Id parentProductId = prod.Id;
                    String alternateProductsStr = prod.B2B_Alternate_Products__c;
                    List<String> alternateProducts = alternateProductsStr.split(',');
                    if( ! alternateProducts.isEmpty() ){
                        for( String skuStr : alternateProducts ){
                            //Added the trim() method

                            skuStr = skuStr.trim();
                            if( productSkuVsIdMap.containsKey( skuStr ) ){

                                String childProductId = productSkuVsIdMap.get( skuStr );
                                if( String.isNotBlank( childProductId ) ){
                                    B2B_Related_Product__c relatedProductRecord = new B2B_Related_Product__c();
                                    relatedProductRecord.Parent_Product__c = parentProductId;
                                    relatedProductRecord.Child_Product__c = childProductId;
                                    relatedProductsToInsert.add( relatedProductRecord );
                                }
                            }
                        }
                    }
                }
                if( !relatedProductsToInsert.isEmpty() ){
                    Database.insert( relatedProductsToInsert, false );
                }
            }
        } catch (Exception e) {
            System.debug('Exception-- '+e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc){

    }
}
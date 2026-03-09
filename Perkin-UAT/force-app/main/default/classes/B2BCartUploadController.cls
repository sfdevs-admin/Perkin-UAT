/**
 * @description       : 
 * @author            : Abhishek
 * @group             : 
 * @last modified on  : 06-10-2025
 * @last modified by  : S.T
 * test class : B2BCartUploadControllerTest
**/
public with sharing class B2BCartUploadController {
    
    private static final String CLASSNAME = 'B2BCartUploadController';
    private static final String MODULE_NAME = 'Cart Upload';

    @AuraEnabled
    public static Map<String,Object> getProductIdFromSKU(List<String> skuList,String effectiveAccountId,String webStoreId) {
        String methodName = 'getProductIdFromSKU';
        String supportData = '';
        try{
            Map<String,Object> resMap = new Map<String,Object>();
            Map<String,Object> validSKUMap = new Map<String,Object>();
            Map<String,Object> entitledSKUMap = new Map<String,Object>();
            List<String> entitledProducts = new List<String>();
            List<String> prodIds = new List<String>();
            List<ConnectApi.ProductOverview> productOverviews = new List<ConnectApi.ProductOverview>();
            List<ConnectApi.PricingResultLineItem> pricingLineItemResults = new List<ConnectApi.PricingResultLineItem>();
            Map<String,String> errorPricingLineItemResults = new Map<String,String>();
            Map<String,ConnectApi.PurchaseQuantityRule> qtyRuleMap = new Map<String,ConnectApi.PurchaseQuantityRule>();
            // for(Product2 prod :[SELECT Id,StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN:skuList ]){
            for(Product2 prod :[SELECT Id,StockKeepingUnit, B2B_Part_Number__c FROM Product2 WHERE B2B_Part_Number__c IN:skuList ]){
                ConnectApi.ProductDetail prodDetail = B2BCheckProductEntitlement.getProduct(webStoreId, effectiveAccountId, prod.Id);
                if(prodDetail != null){
                    if(prodDetail.purchaseQuantityRule != null){
                        qtyRuleMap.put(prod.Id,prodDetail.purchaseQuantityRule);
                    }
                }
                // validSKUMap.put(prod.StockKeepingUnit,prod.Id);
                validSKUMap.put(prod.B2B_Part_Number__c,prod.Id);
                prodIds.add(prod.Id);
                if(prodIds.size() == 100 || Test.isRunningTest()){
                    ConnectApi.PricingResult priceResult;
                    priceResult = Test.isRunningTest() ? B2B_TestDataFactory.getPriceResultMock() : B2BCheckProductEntitlement.getProductPrices(webStoreId, effectiveAccountId, prodIds);
                    if(priceResult != null ){
                        pricingLineItemResults.addAll(priceResult.pricingLineItemResults);
                    }else{
                        
                    }
                    prodIds = new List<String>(); 
                }
            }
            if(!prodIds.isEmpty() || Test.isRunningTest()){
                ConnectApi.PricingResult priceResult;
                priceResult = Test.isRunningTest() ? B2B_TestDataFactory.getPriceResultMock() : B2BCheckProductEntitlement.getProductPrices(webStoreId, effectiveAccountId, prodIds);
                if(priceResult != null){
                    pricingLineItemResults.addAll(priceResult.pricingLineItemResults);
                }else{
                }
            }
            for(ConnectApi.PricingResultLineItem pricingLineItemResult:pricingLineItemResults){
                system.debug('pricingLineItemResult : '+pricingLineItemResult);
                if(pricingLineItemResult.success){
                    entitledProducts.add(pricingLineItemResult.productId);
                }else{
                    errorPricingLineItemResults.put(pricingLineItemResult.productId,pricingLineItemResult.error.errorCode);
                }
            }
            resMap.put('qtyRuleMap',qtyRuleMap);
            resMap.put('errorPricingLineItemResults',errorPricingLineItemResults);
            resMap.put('entitledProducts',entitledProducts);
            resMap.put('validSKUMap',validSKUMap);
            return resMap;
        }catch(Exception ex){
            //Logger.Log(ex, MODULE_NAME, CLASSNAME, methodName, supportData);
            System.debug('Exception in ' + MODULE_NAME + ' | Class + Method: ' + CLASSNAME + '.' + methodName + ': ' + ex.getMessage());
        }
        return null;
    }
}
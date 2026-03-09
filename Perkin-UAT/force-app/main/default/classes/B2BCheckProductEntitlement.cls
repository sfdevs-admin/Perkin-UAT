/**
 * @description       : 
 * @author            : Abhishek
 * @group             : 
 * @last modified on  : 01-06-2024
 * @last modified by  : Abhishek
 * test class : B2BCartUploadControllerTest
**/
public with sharing class B2BCheckProductEntitlement {

    public static ConnectApi.PricingResult getProductPrices(String webstoreId, String effectiveAccountId,List<String> prodIds){
        ConnectApi.PricingInput pricingInput = new ConnectApi.PricingInput();
        List<ConnectApi.PricingLineItemInput> pricingLineItemInput = new List<ConnectApi.PricingLineItemInput>();
        for(String pid : prodIds){
            ConnectApi.PricingLineItemInput pli = new ConnectApi.PricingLineItemInput();
            pli.productId = pid;
            pricingLineItemInput.add(pli);
        }
        pricingInput.pricingLineItems = pricingLineItemInput;
        ConnectApi.PricingResult priceResult = Test.isRunningTest() ? B2B_TestDataFactory.getPriceResultMock() :  ConnectApi.CommerceStorePricing.getProductPrices( webstoreId,  effectiveAccountId,pricingInput);
        //ConnectApi.PricingResult priceResult = ConnectApi.CommerceStorePricing.getProductPrices( webstoreId,  effectiveAccountId,pricingInput);
        return priceResult;
    }

    public static ConnectApi.ProductDetail getProduct(String webstoreId, String effectiveAccountId,String prodId){
        try{
            ConnectApi.ProductDetail prodDetail = ConnectApi.CommerceCatalog.getProduct( webstoreId, prodId, effectiveAccountId, null , true, null, true, true, true, true, true, false);
            return prodDetail;
        }catch(Exception ex){
            system.debug(ex.getMessage());
        }
        return null;
        
    }
    
}
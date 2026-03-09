/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
//Test class 		  : B2B_RelatedProductControllerTest
public without sharing class B2B_RelatedProductService {
    public B2B_RelatedProductService() {

    }

    public static Map<String,Object> getRelatedProducts(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        List<RelatedProductWrapper> relatedProductWrapperList = new List<RelatedProductWrapper>();
        System.debug('getRelatedProducts mapParams-- '+JSON.serialize(mapParams));
        if( mapParams.containsKey('isHomePage') && (Boolean) mapParams.get('isHomePage') ){
            System.debug('getRelatedProducts isHomePage-- '+JSON.serialize(mapParams));
            Map<Id,Product2> relatedProductList = new Map<Id,Product2>([ SELECT Id FROM Product2 
            WHERE B2B_Featured_Product__c = true ]);
            if( ! relatedProductList.isEmpty() ){
                // for( Product2 featuredProd : relatedProductList ){
                //     RelatedProductWrapper wrapperObj = new RelatedProductWrapper();
                //     // wrapperObj.parentProductId = featuredProd.Id;
                //     wrapperObj.childProductId = featuredProd.Id;
                //     relatedProductWrapperList.add(wrapperObj);
                // }
                mapParams.put('relatedProductList', relatedProductList.keySet());
                isSuccess = true;
            }else{
                message = System.Label.B2B_No_featured_product_found;
            }
        }
        else if( mapParams.containsKey('productId')){
            String prodId = (String) mapParams.get('productId');
            List<B2B_Related_Product__c> relatedProductList = [ SELECT Id, Parent_Product__c, Child_Product__c FROM B2B_Related_Product__c 
                                                               WHERE Parent_Product__c =: prodId ];
            Set<Id> childProdIdSet = new Set<Id>();
            if( ! relatedProductList.isEmpty() ){
                for( B2B_Related_Product__c featuredProd : relatedProductList ){
                    childProdIdSet.add(featuredProd.Child_Product__c);
                    // RelatedProductWrapper wrapperObj = new RelatedProductWrapper();
                    // wrapperObj.parentProductId = featuredProd.Parent_Product__c;
                    // wrapperObj.childProductId = featuredProd.Child_Product__c;
                    // relatedProductWrapperList.add(wrapperObj);
                }
                mapParams.put('relatedProductList', childProdIdSet);
                // mapParams.put('relatedProductList', relatedProductList);
                isSuccess = true;
            }else{
                message = System.Label.B2B_No_related_product_found;
            }
        }
         else{
            message = System.Label.B2B_ProductId_Missing;
        }
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        return mapParams;
    }

    public class RelatedProductWrapper{
        @AuraEnabled public String parentProductId;
        @AuraEnabled public String childProductId;
    }
}
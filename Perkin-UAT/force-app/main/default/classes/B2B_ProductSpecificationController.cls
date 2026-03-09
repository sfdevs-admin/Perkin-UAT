public without sharing class B2B_ProductSpecificationController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getProductWithFieldSet(
    Map<String, Object> mapParams
  ) {
    try {
      B2B_ProductSpecificationHelper.getProductData(mapParams);
    } catch (Exception e) {
      mapParams = mapParams == null ? new Map<String, Object>() : mapParams;
      mapParams.put('isSuccess', false);
      mapParams.put('message', e.getMessage());
    }
    return mapParams;
  }

  @AuraEnabled
  public static Map<String, Object> getProductResourcesByProductId(
    String productId
  ) {
    Map<String, Object> response = new Map<String, Object>();
    try {
      Map<String, List<B2B_Product_Resources__c>> resourceTypeMap = B2B_ProductSpecificationHelper.getProductResourcesByProductId(
        productId
      );
      response.put('isSuccess', true);
      response.put('data', resourceTypeMap);
    } catch (Exception e) {
      response.put('isSuccess', false);
      response.put('message', e.getMessage());
    }
    return response;
  }
}
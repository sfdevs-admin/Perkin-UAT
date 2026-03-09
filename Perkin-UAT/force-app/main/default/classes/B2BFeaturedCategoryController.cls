public without sharing class B2BFeaturedCategoryController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getFeaturedCategories(Map<String,Object> mapParams){   
        try {
            mapParams = B2BFeaturedCategoryHelper.getFeaturedCategories(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }
}
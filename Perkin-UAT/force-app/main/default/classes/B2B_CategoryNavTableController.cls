// test class- B2B_CategoryNavTableControllerTest
public without sharing class B2B_CategoryNavTableController {
    public B2B_CategoryNavTableController() {

    }

    @AuraEnabled
    public static Map<String,Object> fetchChildCategories(Map<String,Object> mapParams){
        try {
            B2B_CategoryNavTableService.fetchChildCategories(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message',e.getMessage());
        }
        return mapParams;
    }
}
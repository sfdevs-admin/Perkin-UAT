/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 11-10-2025
 * @last modified by  : Swati Chilap
**/
public without sharing class B2B_CountrySwitcherController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getGuestLocaleMetadataRecords(Map<String,Object> mapParams){   
        try {
            mapParams = B2B_CountrySwitcherHelper.guestLocaleMetadataRecords(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getCountrySelectorMetadataRecords(){   
        Map<String,Object> mapParams = new Map<String,Object>();
        try {
            mapParams = B2B_CountrySwitcherHelper.countrySelectorMetadataRecords();
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }


    @AuraEnabled()
    public static Map<String,Object> updateLoggedInUserDetails(Map<String,Object> mapParams){
        Savepoint sp = Database.setSavepoint();   
        try {
            mapParams = B2B_CountrySwitcherHelper.loggedInUserDetails(mapParams);
        } catch (Exception e) {
            Database.rollback(sp);
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getLoggedInUserBG(Map<String,Object> mapParams){   
        try {
            mapParams = B2B_CountrySwitcherHelper.getLoggedInUserBGHelper(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getPromotionBGInfo(Map<String,Object> mapParams){   
        try {
            mapParams = B2B_CountrySwitcherHelper.getPromotionBGInfoHelper(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }
}
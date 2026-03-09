/**
* @File Name : B2B_SubscriptionUtil.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 23, 2025
* @Modification Log :
* Test class : B2B_SubscriptionControllerTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 23, 2025 |   | Initial Version
**/

public class B2B_SubscriptionUtil {
	public static Map<String,Object> createSubscription(Map<String,Object> mapParams){
		Sobject insertRecord = mapParams.containsKey('insertRecord') ?
		(Sobject)mapParams.get('insertRecord') : null;
		if(mapParams.containsKey('doInsert') && (Boolean)mapParams.get('doInsert')){
			insert insertRecord;
		}
		mapParams.put('insertRecord',insertRecord);
		return mapParams;
	}

	public static sObject getInstance(String sobjectType, Map<Object, Object> fieldMap) {
    sObject record = (sObject) Type.forName('Schema.' + sobjectType).newInstance();

    for (Object key : fieldMap.keySet()) {
        record.put(String.valueOf(key), fieldMap.get(key));
    }

    return record;
}
	
	
}
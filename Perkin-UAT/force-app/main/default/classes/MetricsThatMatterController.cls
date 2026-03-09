global class MetricsThatMatterController {

    @RemoteAction
    global static List<User> getUsersInRegion(String region) {
        return [SELECT Id, Name, Region__c, (SELECT Id, ManagerId, Name 
                        FROM ManagedUsers 
                        WHERE IsActive = true 
                            AND (NOT Profile.Name LIKE '%Chatter%') 
                            AND Function__c = 'Sales'
                            AND (NOT Department LIKE '%FAS%')
                            AND Business__c IN ('EH','LST','Informatics','OneSource','Food Business')
                            AND PKI_GBL_Sub_function__c IN ('Inside Sales','Sales','Sales Indirect','Sales Mgmt','Sales Support')
                        ORDER BY Name) 
                FROM User 
                WHERE IsActive = true
                    AND (NOT Profile.Name LIKE '%Chatter%') 
                AND Region__c = :region
                ORDER BY Name];
}

    @RemoteAction
    global static List<Map<String, Object>> getFieldMetadata(String objectName, String fieldSetName) {
        SObjectType sobjType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> mfields = sobjType.getDescribe().fields.getMap();
        List<Map<String, Object>> mwList = new List<Map<String, Object>>();
        List<Schema.FieldSetMember> fieldsList;
        if(fieldSetName != '') {
            fieldsList = sobjType.getDescribe().fieldSets.getMap().get(fieldSetName).getFields();
        }
        for(String key : mfields.keySet()) {
            Schema.DescribeFieldResult field = mfields.get(key).getDescribe();
            if(fieldsList != null && !isFieldPresentInFieldSet(fieldsList, field.getName())) {
                continue ;
            }
            Map<String, Object> mw = new Map<String, Object>();
            mw.put('fullName', field.getName());
            mw.put('label', field.getLabel());
            mw.put('type', getTypeFromEnum(field.getType().name()));
            if(mw.get('type') == 'Picklist' || mw.get('type') == 'MultiselectPicklist') {
                mw.put('valueSet', createValueSet(field.getPicklistValues()));
            }
            mwList.add(mw);
        }
        return mwList;
    }

    global static Boolean isFieldPresentInFieldSet(List<Schema.FieldSetMember> fieldSet, String fieldApiName) {
        for(Schema.FieldSetMember field : fieldSet){
            if(field.getFieldPath() == fieldApiName) {
                return true;
            }
        }
        return false;
    }

    global static Map<String, Object> createValueSet(List<Schema.PicklistEntry> pList) {
        Map<String, Object> vsd = new Map<String, Object>();
        List<Map<String, Object>> valueList = new List<Map<String, Object>>();
        for(Schema.PicklistEntry pe : pList) {
            Map<String, Object> val = new Map<String, Object>();
            val.put('fullName', pe.getValue());
            val.put('label', pe.getLabel());
            valueList.add(val);
        }
        vsd.put('value', valueList);

        Map<String, Object> vs = new Map<String, Object>();

        vs.put('valueSetDefinition', vsd);
        return vs;
    }

    global static String getTypeFromEnum(String enumType) {
        switch on enumType.toLowerCase() {
            when 'boolean' {
                return 'Checkbox';
            }	
            when 'combobox', 'picklist' {
                return 'Picklist';
            }	
            when 'multipicklist' {
                return 'MultiselectPicklist';
            }
            when 'currency' {
                return 'Currency';
            }
            when 'percent' {
                return 'Percent';
            }
            when 'reference', 'id' {	
                return 'Lookup';
            }
            when 'date' {
                return 'Date';
            }
            when 'datetime' {
                return 'DateTime';
            }
            when 'double', 'integer', 'long' {
                return 'Number';
            }
            when 'email' {
                return 'Email';
            }
            when 'phone' {
                return 'Text';
            }
            when 'string' {
                return 'Text';
            }
            when 'textarea' {
                return 'TextArea';
            }
            when 'url' {		
                return 'Url';
            }
            when 'address' {		
                return 'Address';
            }
            when else {
                return enumType;
            }
        }
    }

    /*@RemoteAction
    global static List<User> filterManagerByRegion(String region){
        Set<Id> managerIds = new Set<Id>();
        for(User u : [SELECT Id, ManagerId 
                        FROM User 
                        WHERE Region__c = :region 
                            AND IsActive = true 
                            AND (NOT Profile.Name LIKE '%Chatter%') 
                            AND Function__c = 'Sales'
                            AND (NOT Department LIKE '%FAS%')
                            AND ManagerId != null
                            AND Business__c IN ('EH','LST','Informatics','OneSource','Food Business')
                            AND PKI_GBL_Sub_function__c IN ('Inside Sales','Sales','Sales Indirect','Sales Mgmt','Sales Support')]) {
            managerIds.add(u.ManagerId);
        }
        return [SELECT Id, Name, (SELECT Id, ManagerId 
                        FROM ManagedUsers 
                        WHERE Region__c = :region 
                            AND IsActive = true 
                            AND (NOT Profile.Name LIKE '%Chatter%') 
                            AND Function__c = 'Sales'
                            AND (NOT Department LIKE '%FAS%')
                            AND ManagerId != null
                            AND Business__c IN ('EH','LST','Informatics','OneSource','Food Business')
                            AND PKI_GBL_Sub_function__c IN ('Inside Sales','Sales','Sales Indirect','Sales Mgmt','Sales Support')
                        ORDER BY Name) 
                FROM User 
                WHERE Region__c = :region 
                AND IsActive = true ORDER BY Name];
    }

    @RemoteAction
    global static List<User> getUsersByManager(Id managerId){
        List<User> filteredUsers = [SELECT Id, Name FROM User WHERE ManagerId = :managerId ORDER BY Name];
        return filteredUsers;
    }*/
}
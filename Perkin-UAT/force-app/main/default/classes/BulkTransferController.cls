public with sharing class BulkTransferController {

    /* =========================================================
       1️⃣ GET ACTIVE OBJECTS FROM CUSTOM METADATA
    ========================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getObjects() {

        List<Map<String,String>> result = new List<Map<String,String>>();

        for (Bulk_Transfer_Config__mdt config :
            [SELECT Object_API_Name__c, MasterLabel
             FROM Bulk_Transfer_Config__mdt
             WHERE Is_Active__c = TRUE]) {

            result.add(new Map<String,String>{
                'label' => config.MasterLabel,
                'value' => config.Object_API_Name__c
            });
        }

        return result;
    }

    /* =========================================================
       2️⃣ GET FILTER FIELDS
    ========================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getFilterFields(String objectName) {

        Bulk_Transfer_Config__mdt config =
            [SELECT Filter_Fields__c
            FROM Bulk_Transfer_Config__mdt
            WHERE Object_API_Name__c = :objectName
            LIMIT 1];

        List<Map<String,Object>> filters = new List<Map<String,Object>>();

        if (String.isBlank(config.Filter_Fields__c)) {
            return filters;
        }

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap =
            sObjType.getDescribe().fields.getMap();

        for (String fieldApi : config.Filter_Fields__c.split(',')) {

            fieldApi = fieldApi.trim();

            if (fieldMap.containsKey(fieldApi)) {

                Schema.DescribeFieldResult describe =
                    fieldMap.get(fieldApi).getDescribe();

                Map<String,Object> fieldData = new Map<String,Object>{
                    'label' => describe.getLabel(),
                    'value' => fieldApi,
                    'type'  => String.valueOf(describe.getType())
                };

                // ✅ PICKLIST SUPPORT ADDED
                if (describe.getType() == Schema.DisplayType.PICKLIST) {

                    List<Map<String,String>> pickVals =
                        new List<Map<String,String>>();

                    for (Schema.PicklistEntry entry :
                        describe.getPicklistValues()) {

                        if (entry.isActive()) {
                            pickVals.add(new Map<String,String>{
                                'label' => entry.getLabel(),
                                'value' => entry.getValue()
                            });
                        }
                    }

                    fieldData.put('picklistValues', pickVals);
                }

                // Lookup handling (UNCHANGED)
                if (describe.getType() == Schema.DisplayType.REFERENCE) {
                    fieldData.put(
                        'referenceTo',
                        describe.getReferenceTo()[0]
                            .getDescribe()
                            .getName()
                    );
                }

                filters.add(fieldData);
            }
        }

        return filters;
    }


    /* =========================================================
       3️⃣ SEARCH RECORDS (UPDATED FOR ALL DATE/DATETIME FIELDS)
    ========================================================== */
   @AuraEnabled
    public static List<SObject> searchRecords(
        String objectName,
        Map<String,String> filters,
        String currentOwnerId
    ){
        try {

            Bulk_Transfer_Config__mdt config =
                [SELECT Column_Fields__c
                 FROM Bulk_Transfer_Config__mdt
                 WHERE Object_API_Name__c = :objectName
                 LIMIT 1];

            String soql =
                'SELECT Id,' + config.Column_Fields__c + ', Owner.Name ' +
                'FROM ' + objectName +
                ' WHERE Id != null';

            if (String.isNotBlank(currentOwnerId)) {
                soql += ' AND OwnerId = \'' + currentOwnerId + '\'';
            }

            Schema.SObjectType sObjType =
                Schema.getGlobalDescribe().get(objectName);

            Map<String, Schema.SObjectField> fieldMap =
                sObjType.getDescribe().fields.getMap();

            if (filters != null) {

                for (String key : filters.keySet()) {

                    String value = filters.get(key);
                    if (String.isBlank(value)) continue;

                    Boolean isFrom = key.endsWith('_from');
                    Boolean isTo   = key.endsWith('_to');

                    String fieldName =
                        key.replace('_from','').replace('_to','');

                    if (!fieldMap.containsKey(fieldName)) continue;

                    Schema.DescribeFieldResult describe =
                        fieldMap.get(fieldName).getDescribe();

                    // DATE
                    if (describe.getType() == Schema.DisplayType.DATE) {

                        if (isFrom)
                            soql += ' AND ' + fieldName + ' >= ' + value;

                        if (isTo)
                            soql += ' AND ' + fieldName + ' <= ' + value;
                    }

                    // DATETIME
                    else if (describe.getType() == Schema.DisplayType.DATETIME) {

                        if (isFrom)
                            soql += ' AND ' + fieldName +
                                    ' >= ' + value + 'T00:00:00Z';

                        if (isTo)
                            soql += ' AND ' + fieldName +
                                    ' <= ' + value + 'T23:59:59Z';
                    }

                    // LOOKUP
                    else if (describe.getType() == Schema.DisplayType.REFERENCE) {

                        if (value.contains(',')) {

                            List<String> ids = value.split(',');

                            soql += ' AND ' + fieldName + ' IN (';

                            for (Integer i = 0; i < ids.size(); i++) {
                                soql += '\'' + String.escapeSingleQuotes(ids[i]) + '\'';
                                if (i < ids.size() - 1) {
                                    soql += ',';
                                }
                            }

                            soql += ')';

                        } else {

                            soql += ' AND ' + fieldName +
                                    ' = \'' +
                                    String.escapeSingleQuotes(value) +
                                    '\'';
                        }
                    }


                    // TEXT
                    else if (value.contains(',')) {

                        List<String> values = value.split(',');

                        soql += ' AND ' + fieldName + ' IN (';

                        for (Integer i = 0; i < values.size(); i++) {
                            soql += '\'' + String.escapeSingleQuotes(values[i]) + '\'';
                            if (i < values.size() - 1) {
                                soql += ',';
                            }
                        }

                        soql += ')';
                    }
                    else {
                        soql += ' AND ' + fieldName +
                                ' LIKE \'%' +
                                String.escapeSingleQuotes(value) +
                                '%\'';
                    }

                }
            }

            soql += ' ORDER BY CreatedDate DESC LIMIT 200';

            return Database.query(soql);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* =========================================================
       4️⃣ GENERIC LOOKUP SEARCH (ANY OBJECT)
    ========================================================== */
    @AuraEnabled(cacheable=true)
    public static List<OwnerWrapper> searchLookupRecords(
        String objectName,
        String searchKey
    ){
        List<OwnerWrapper> results = new List<OwnerWrapper>();

        if (String.isBlank(searchKey) || searchKey.length() < 3) {
            return results;
        }

        String soql =
            'SELECT Id, Name FROM ' + objectName +
            ' WHERE Name LIKE \'%' +
            String.escapeSingleQuotes(searchKey) +
            '%\' LIMIT 10';

        for (SObject sob : Database.query(soql)) {
            results.add(new OwnerWrapper(
                (String)sob.get('Id'),
                (String)sob.get('Name')
            ));
        }

        return results;
    }


    /* =========================================================
       4️⃣ UPDATE OWNER
    ========================================================== */
    @AuraEnabled
    public static void updateOwner(
        String objectName,
        List<Id> recordIds,
        Id newOwnerId
    ){

        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        List<SObject> updateList = new List<SObject>();

        for (Id rid : recordIds) {

            SObject sobj =
                Schema.getGlobalDescribe()
                .get(objectName)
                .newSObject(rid);

            sobj.put('OwnerId', newOwnerId);
            updateList.add(sobj);
        }

        update updateList;
    }

    /* =========================================================
       5️⃣ GET COLUMNS
    ========================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getColumns(String objectName){

        try {

            Bulk_Transfer_Config__mdt config =
                [SELECT Column_Fields__c
                 FROM Bulk_Transfer_Config__mdt
                 WHERE Object_API_Name__c = :objectName
                 LIMIT 1];

            List<Map<String,Object>> columns =
                new List<Map<String,Object>>();

            if (String.isBlank(config.Column_Fields__c)) {
                return columns;
            }

            List<String> fieldApiNames =
                config.Column_Fields__c.split(',');

            Schema.SObjectType sObjType =
                Schema.getGlobalDescribe().get(objectName);

            Map<String, Schema.SObjectField> fieldMap =
                sObjType.getDescribe().fields.getMap();

            for (String fieldApi : fieldApiNames) {

                fieldApi = fieldApi.trim();

                if (fieldMap.containsKey(fieldApi)) {

                    Schema.DescribeFieldResult describe =
                        fieldMap.get(fieldApi).getDescribe();

                    Map<String,Object> col =
                        new Map<String,Object>();

                    col.put('label', describe.getLabel());
                    col.put('fieldName', fieldApi);
                    col.put('type', mapFieldType(describe.getType()));

                    columns.add(col);
                }
            }

            return columns;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* =========================================================
       HELPER
    ========================================================== */
    private static String mapFieldType(Schema.DisplayType typeVal) {

        switch on typeVal {
            when DATE { return 'date'; }
            when DATETIME { return 'date'; }
            when CURRENCY { return 'currency'; }
            when DOUBLE { return 'number'; }
            when INTEGER { return 'number'; }
            when BOOLEAN { return 'boolean'; }
            when EMAIL { return 'email'; }
            when PHONE { return 'phone'; }
            when URL { return 'url'; }
            when else { return 'text'; }
        }
    }

    /* =========================================================
       6️⃣ OWNER SEARCH (USER / QUEUE)
    ========================================================== */
    @AuraEnabled(cacheable=true)
    public static List<OwnerWrapper> searchOwners(
        String searchKey,
        String ownerType
    ){

        List<OwnerWrapper> results =
            new List<OwnerWrapper>();

        if (String.isBlank(searchKey) || searchKey.length() < 3) {
            return results;
        }

        if (ownerType == 'User') {

            for (User u : [
                SELECT Id, Name
                FROM User
                WHERE Name LIKE :('%' + searchKey + '%')
                AND IsActive = TRUE
                LIMIT 10
            ]) {
                results.add(new OwnerWrapper(u.Id, u.Name));
            }

        } else if (ownerType == 'Group') {

            for (Group g : [
                SELECT Id, Name
                FROM Group
                WHERE Name LIKE :('%' + searchKey + '%')
                AND Name!=null
                LIMIT 10
            ]) {
                results.add(new OwnerWrapper(g.Id, g.Name));
            }
        }

        return results;
    }
    public class OwnerWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public OwnerWrapper(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}
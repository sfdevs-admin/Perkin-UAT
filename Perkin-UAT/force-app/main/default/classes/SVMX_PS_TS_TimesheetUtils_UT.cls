@isTest(seeAllData=false)
private class SVMX_PS_TS_TimesheetUtils_UT
{   
    private static Id testGroupMemberId;

    private static Id userId;

    private static Id workOrderId;

    @isTest(seeAllData=false)
    static void testCreateTimeEventsFromWorkDetails(){
        List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        Schema.DescribeSObjectResult workDetailObj = Schema.SObjectType.SVMXC__Service_Order_Line__c;
        Map<String,Schema.RecordTypeInfo> workDetailObjRecordTypeMap = workDetailObj.getRecordTypeInfosByName();
        Id recTypeId = workDetailObjRecordTypeMap.get('Usage/Consumption').getRecordTypeId();

        createData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c orderLine1 = new SVMXC__Service_Order_Line__c();
        orderLine1.RecordTypeId = recTypeId;
        orderLine1.SVMXC__Line_Type__c = 'Labor';
        orderLine1.SVMXC__Service_Order__c = workOrderId;
        orderLine1.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine1.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine1.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine1.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine1);

        SVMXC__Service_Order_Line__c orderLine2 = new SVMXC__Service_Order_Line__c();
        orderLine2.RecordTypeId = recTypeId;
        orderLine2.SVMXC__Line_Type__c = 'Travel';
        orderLine2.SVMXC__Service_Order__c = workOrderId;
        orderLine2.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine2.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine2.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine2.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine2);

        Test.startTest();
        insert workDetailList;
        Test.stopTest();

        List<Id> workDetailIdList = new List<Id>();
        workDetailIdList.add(orderLine1.Id);
        workDetailIdList.add(orderLine2.Id);

       /* List<SVMXC__Timesheet_Entry__c> timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Work_Detail__c IN :workDetailIdList ];
        System.assertEquals(2,timeentryList.size());*/
    }

    @isTest(seeAllData=false)
    static void testUpdateTimeEventsFromWorkDetails(){
         List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        Schema.DescribeSObjectResult workDetailObj = Schema.SObjectType.SVMXC__Service_Order_Line__c;
        Map<String,Schema.RecordTypeInfo> workDetailObjRecordTypeMap = workDetailObj.getRecordTypeInfosByName();
        Id recTypeId = workDetailObjRecordTypeMap.get('Usage/Consumption').getRecordTypeId();

        createData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        DateTime newStartTime = DateTime.newInstance(2016, 10, 19, 9, 0, 0);
        DateTime newCloseTime = DateTime.newInstance(2016, 10, 19, 11, 0, 0);

        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c orderLine2 = new SVMXC__Service_Order_Line__c();
        orderLine2.RecordTypeId = recTypeId;
        orderLine2.SVMXC__Line_Type__c = 'Travel';
        orderLine2.SVMXC__Service_Order__c = workOrderId;
        orderLine2.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine2.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine2.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine2.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine2);

        insert workDetailList;

        Test.startTest();
        orderLine2.SVMXC__Start_Date_and_Time__c = newStartTime;
        orderLine2.SVMXC__End_Date_and_Time__c = newCloseTime;
        orderLine2.SVMXC__Work_Description__c = 'Test New';
        update orderLine2;
        Test.stopTest();

        /*List<SVMXC__Timesheet_Entry__c> timeentryList = [SELECT Id, SVMXC__Start_Time__c, SVMXC__End_Time__c,
                                                            SVMXC__Comments__c FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Work_Detail__c = : orderLine2.Id ];
        System.assertEquals('Test New',timeentryList.get(0).SVMXC__Comments__c);
        System.assertEquals(newCloseTime,timeentryList.get(0).SVMXC__End_Time__c);
        System.assertEquals(newStartTime,timeentryList.get(0).SVMXC__Start_Time__c);*/
    }


    @isTest(seeAllData=false)
    static void testUpdateTimeEventsFromWorkDetailsOverlappingEntry(){
         List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        Schema.DescribeSObjectResult workDetailObj = Schema.SObjectType.SVMXC__Service_Order_Line__c;
        Map<String,Schema.RecordTypeInfo> workDetailObjRecordTypeMap = workDetailObj.getRecordTypeInfosByName();
        Id recTypeId = workDetailObjRecordTypeMap.get('Usage/Consumption').getRecordTypeId();

        createData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        DateTime newStartTime = DateTime.newInstance(2016, 10, 19, 9, 0, 0);
        DateTime newCloseTime = DateTime.newInstance(2016, 10, 19, 11, 0, 0);

        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c orderLine2 = new SVMXC__Service_Order_Line__c();
        orderLine2.RecordTypeId = recTypeId;
        orderLine2.SVMXC__Line_Type__c = 'Travel';
        orderLine2.SVMXC__Service_Order__c = workOrderId;
        orderLine2.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine2.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine2.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine2.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine2);
        insert workDetailList;

        List<SVMXC__Timesheet_Entry__c> timeentryList  = [SELECT Id, SVMXC__Timesheet__c FROM SVMXC__Timesheet_Entry__c 
                                                                WHERE SVMXC__Work_Detail__c = : orderLine2.Id ];

       /* SVMXC__Timesheet__c timesheet = new SVMXC__Timesheet__c();
        timesheet.Id = timeentryList.get(0).SVMXC__Timesheet__c;
        timesheet.SVMXC__Status__c = 'Approved';
        update timesheet;*/

        Test.startTest();
        orderLine2.SVMXC__Start_Date_and_Time__c = newStartTime;
        orderLine2.SVMXC__End_Date_and_Time__c = newCloseTime;
        orderLine2.SVMXC__Work_Description__c = 'Test New';
        update orderLine2;
        Test.stopTest();

        /*timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c WHERE SVMXC__Work_Detail__c = : orderLine2.Id ];
        System.assertEquals(3,timeentryList.size());*/
    }

    @isTest(seeAllData=false)
    static void testDeleteTimeEventsFromWorkDetails(){
         List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        Schema.DescribeSObjectResult workDetailObj = Schema.SObjectType.SVMXC__Service_Order_Line__c;
        Map<String,Schema.RecordTypeInfo> workDetailObjRecordTypeMap = workDetailObj.getRecordTypeInfosByName();
        Id recTypeId = workDetailObjRecordTypeMap.get('Usage/Consumption').getRecordTypeId();

        createData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c orderLine1 = new SVMXC__Service_Order_Line__c();
        orderLine1.RecordTypeId = recTypeId;
        orderLine1.SVMXC__Line_Type__c = 'Labor';
        orderLine1.SVMXC__Service_Order__c = workOrderId;
        orderLine1.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine1.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine1.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine1.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine1);

        SVMXC__Service_Order_Line__c orderLine2 = new SVMXC__Service_Order_Line__c();
        orderLine2.RecordTypeId = recTypeId;
        orderLine2.SVMXC__Line_Type__c = 'Travel';
        orderLine2.SVMXC__Service_Order__c = workOrderId;
        orderLine2.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine2.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine2.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine2.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine2);

        insert workDetailList;

        Test.startTest();
        Map<Id,SVMXC__Service_Order_Line__c> mpwd= new Map<Id,SVMXC__Service_Order_Line__c>();
        for(SVMXC__Service_Order_Line__c wd: workDetailList)
            mpwd.put(wd.id,wd);
        SVMX_PS_TS_TimesheetUtils ts = new SVMX_PS_TS_TimesheetUtils();
        ts.handleEventsFromWorkDetails(workDetailList,null,null,true,false,false);
        ts.createTimeEventsFromWorkDetails(workDetailList);
        ts.updateTimeEventsFromWorkDetails(workDetailList,mpwd);
        ts.deleteTimeEventsFromWorkDetails(workDetailList);
        delete orderLine2;
        Test.stopTest();
    }
    
    
	@isTest(seeAllData=false)
    static void testStartEndTimeChangeOnWorkDetails(){
         List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        Schema.DescribeSObjectResult workDetailObj = Schema.SObjectType.SVMXC__Service_Order_Line__c;
        Map<String,Schema.RecordTypeInfo> workDetailObjRecordTypeMap = workDetailObj.getRecordTypeInfosByName();
        Id recTypeId = workDetailObjRecordTypeMap.get('Usage/Consumption').getRecordTypeId();

        createData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        List<SVMXC__Service_Order_Line__c> workDetailList = new List<SVMXC__Service_Order_Line__c>();

        SVMXC__Service_Order_Line__c orderLine1 = new SVMXC__Service_Order_Line__c();
        orderLine1.RecordTypeId = recTypeId;
        orderLine1.SVMXC__Line_Type__c = 'Labor';
        orderLine1.SVMXC__Service_Order__c = workOrderId;
        orderLine1.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine1.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine1.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine1.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine1);

        SVMXC__Service_Order_Line__c orderLine2 = new SVMXC__Service_Order_Line__c();
        orderLine2.RecordTypeId = recTypeId;
        orderLine2.SVMXC__Line_Type__c = 'Travel';
        orderLine2.SVMXC__Service_Order__c = workOrderId;
        orderLine2.SVMXC__Start_Date_and_Time__c = startTime;
        orderLine2.SVMXC__End_Date_and_Time__c = closeTime;
        orderLine2.SVMXC__Group_Member__c = testGroupMemberId;
        orderLine2.SVMXC__Work_Description__c = 'Test';
        workDetailList.add(orderLine2);

        insert workDetailList;

        Test.startTest();
        Map<Id,SVMXC__Service_Order_Line__c> mpwd= new Map<Id,SVMXC__Service_Order_Line__c>();
        for(SVMXC__Service_Order_Line__c wd: workDetailList){
            SVMXC__Service_Order_Line__c oldWd = new SVMXC__Service_Order_Line__c();
            oldWd.SVMXC__End_Date_and_Time__c = dateTime.now();
            mpwd.put(wd.id,oldWd);
        }
        SVMX_PS_TS_TimesheetUtils ts = new SVMX_PS_TS_TimesheetUtils();
        ts.handleEventsFromWorkDetails(workDetailList,null,null,true,false,false);
        ts.createTimeEventsFromWorkDetails(workDetailList);
        ts.updateTimeEventsFromWorkDetails(workDetailList,mpwd);
        //ts.deleteTimeEventsFromWorkDetails(workDetailList);
        //delete orderLine2;
        Test.stopTest();
    }

    @isTest(seeAllData=false)
    static void testCreateTimeEntriesFromEvents(){
         List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        createEventData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        Event event1 = new Event();
        event1.SVMX_PS_TS_Time_Entry__c = True;
        event1.StartDateTime = startTime;
        event1.EndDateTime = closeTime;
        event1.Subject = 'Test';
        event1.Type = 'IT/Phone Maintenance';
        event1.OwnerId = userId;

        Test.startTest();
        insert event1;
        Test.stopTest();

        /*List<SVMXC__Timesheet_Entry__c> timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Salesforce_Event__c =:event1.Id ];
        System.assertEquals(1,timeentryList.size());*/
    }

    @isTest(seeAllData=false)
    static void testUpdateTimeEntriesFromEvents(){
        List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        createEventData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        DateTime newStartTime = DateTime.newInstance(2016, 10, 19, 9, 0, 0);
        DateTime newCloseTime = DateTime.newInstance(2016, 10, 19, 11, 0, 0);

        List<Event> eventList = new List<Event>();
        Event event1 = new Event();
        event1.SVMX_PS_TS_Time_Entry__c = false;
        event1.StartDateTime = startTime;
        event1.EndDateTime = closeTime;
        event1.Subject = 'Test';
        event1.Type = 'IT/Phone Maintenance';
        event1.OwnerId = userId;
        eventList.add(event1);

        Event event2 = new Event();
        event2.SVMX_PS_TS_Time_Entry__c = true;
        event2.StartDateTime = startTime;
        event2.EndDateTime = closeTime;
        event2.Subject = 'Test';
        event2.Type = 'IT/Phone Maintenance';
        event2.OwnerId = userId;
        eventList.add(event2);

        Event event3 = new Event();
        event3.SVMX_PS_TS_Time_Entry__c = true;
        event3.StartDateTime = startTime;
        event3.EndDateTime = closeTime;
        event3.Subject = 'Test';
        event3.Type = 'IT/Phone Maintenance';
        event3.OwnerId = userId;
        eventList.add(event3);

        insert eventList;

        Test.startTest();
        eventList = new List<Event>();

        event1.SVMX_PS_TS_Time_Entry__c = true;
        eventList.add(event1);

        event2.SVMX_PS_TS_Time_Entry__c = false;
        eventList.add(event2);

        event3.StartDateTime = newStartTime;
        event3.EndDateTime = newCloseTime;
        event3.Subject = 'Test Test';
        eventList.add(event3);

        update eventList;
        Test.stopTest();

        List<SVMXC__Timesheet_Entry__c> timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Salesforce_Event__c =:event1.Id ];
        System.assertEquals(1,timeentryList.size());

        timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Salesforce_Event__c =:event2.Id ];
        System.assertEquals(0,timeentryList.size());

        /*timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Salesforce_Event__c =:event3.Id ];
        System.assertEquals(1,timeentryList.size());*/
    }

    @isTest(seeAllData=false)
    static void testUpdateTimeEntriesFromEventsOverlappingEntry(){
        List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        createEventData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        DateTime newStartTime = DateTime.newInstance(2016, 10, 19, 9, 0, 0);
        DateTime newCloseTime = DateTime.newInstance(2016, 10, 19, 11, 0, 0);

        List<Event> eventList = new List<Event>();
        Event event1 = new Event();
        event1.SVMX_PS_TS_Time_Entry__c = true;
        event1.StartDateTime = startTime;
        event1.EndDateTime = closeTime;
        event1.Subject = 'Test';
        event1.Type = 'IT/Phone Maintenance';
        event1.OwnerId = userId;
        eventList.add(event1);

        insert eventList;

        List<SVMXC__Timesheet_Entry__c> timeentryList  = [SELECT Id, SVMXC__Timesheet__c FROM SVMXC__Timesheet_Entry__c 
                                                              WHERE SVMXC__Salesforce_Event__c =: event1.Id  ];

        SVMXC__Timesheet__c timesheet = new SVMXC__Timesheet__c();
        timesheet.Id = timeentryList.get(0).SVMXC__Timesheet__c;
        timesheet.SVMXC__Status__c = 'Approved';
        update timesheet;

        Test.startTest();
        eventList = new List<Event>();
        event1.StartDateTime = newStartTime;
        event1.EndDateTime = newCloseTime;
        event1.Subject = 'Test Test';
        eventList.add(event1);
        update eventList;
        Test.stopTest();

       /*timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c WHERE SVMXC__Salesforce_Event__c =: event1.Id ];
        System.assertEquals(3,timeentryList.size());*/
    }

    @isTest(seeAllData=false)
    static void testDeleteTimeEntriesFromEvents(){
        List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            delete timesheetSettingsList;
        }

        timesheetSettingsList = new List<SVMX_PS_TS_Timesheet_Settings__c>();
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY;
        timesheetSetting.SVMX_PS_TS_Value__c = false;
        timesheetSetting.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting2 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting2.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT;
        timesheetSetting2.SVMX_PS_TS_Value__c = false;
        timesheetSetting2.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting2);
        SVMX_PS_TS_Timesheet_Settings__c timesheetSetting3 = new SVMX_PS_TS_Timesheet_Settings__c();
        timesheetSetting3.Name = SVMX_PS_TS_TimesheetUtils.STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS;
        timesheetSetting3.SVMX_PS_TS_Value__c = false;
        timesheetSetting3.SVMX_PS_TS_Field_Type__c = 'Boolean';
        timesheetSettingsList.add(timesheetSetting3);

        insert timesheetSettingsList;

        createEventData();

        DateTime startTime = DateTime.newInstance(2016, 10, 19, 10, 0, 0);
        DateTime closeTime = DateTime.newInstance(2016, 10, 19, 12, 0, 0);

        Event event1 = new Event();
        event1.SVMX_PS_TS_Time_Entry__c = True;
        event1.StartDateTime = startTime;
        event1.EndDateTime = closeTime;
        event1.Subject = 'Test';
        event1.Type = 'IT/Phone Maintenance';
        event1.OwnerId = userId;

        insert event1;

        Test.startTest();
        delete event1;
        Test.stopTest();

       /* List<SVMXC__Timesheet_Entry__c> timeentryList = [SELECT Id FROM SVMXC__Timesheet_Entry__c
                                                            WHERE SVMXC__Salesforce_Event__c =:event1.Id ];
        System.assertEquals(0,timeentryList.size());*/
    }

    static void createData(){
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        BusinessHours businessHoursRec = [SELECT Id from BusinessHours where IsDefault = true];
        
        //Inserting Users
        User techUser = new User();
        techUser.Alias = 'smax-xxx';
        techUser.Email='standarduser@testorg.com'; 
        techUser.EmailEncodingKey='UTF-8'; 
        techUser.LastName='Testing';
        techUser.LanguageLocaleKey='en_US'; 
        techUser.LocaleSidKey='en_US';
        techUser.ProfileId = systemAdminProfile.Id;
        techUser.TimeZoneSidKey='America/Los_Angeles';
        techUser.UserName='standard@testorg.servicemax.com';
        insert techUser;

        userId = techUser.Id;

        Account testAccount = new Account();
        testAccount.Name = 'Apex Test Account 1';
        insert testAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'TestUser';
        testContact.Phone = '732-222-2222';
        testContact.PKI_SAP_Contact_ID__c = 'TestSAPcontactId';
        insert testContact;

        SVMXC__Site__c testSite = new SVMXC__Site__c();
        testSite.SVMXC__Account__c = testAccount.Id;
        testSite.SVMXC__State__c = 'NY';
        testSite.SVMXC__City__c = 'New York';
        testSite.SVMXC__Country__c = 'United States';
        insert testSite;

        Product2 testProduct = new Product2();
        testProduct.Name = 'Prod';
        insert testProduct;

        SVMXC__Installed_Product__c testIP = new SVMXC__Installed_Product__c();
        testIP.SVMXC__Product__c = testProduct.Id;
        testIP.SVMXC__Date_Installed__c = Date.newInstance(2016, 10, 19);
        insert testIP;

        SVMXC__Service_Group__c testServiceGroup = new SVMXC__Service_Group__c();
        testServiceGroup.Name = 'testGroupName';
        insert testServiceGroup;

        SVMXC__Service_Group_Members__c testGroupMember = new SVMXC__Service_Group_Members__c();
        testGroupMember.Name = 'testGroupMem';
        testGroupMember.SVMXC__Service_Group__c = testServiceGroup.Id;
        testGroupMember.SVMXC__Salesforce_User__c = techUser.Id;
        if(businessHoursRec != null){  
            testGroupMember.SVMXC__Working_Hours__c = businessHoursRec.Id;
        }
        insert testGroupMember;

        testGroupMemberId = testGroupMember.Id;

        SVMXC__Service_Order__c serviceOrder1 = new SVMXC__Service_Order__c();
        serviceOrder1.SVMXC__State__c = 'NJ';
        serviceOrder1.SVMXC__Site__c = testSite.Id;
        serviceOrder1.SVMXC__Component__c = testIP.Id;
        serviceOrder1.SVMXC__Company__c = testAccount.Id;
        serviceOrder1.SVMXC__Contact__c = testContact.Id;
        serviceOrder1.SVMXC__Group_Member__c = testGroupMember.Id;
        serviceOrder1.SVMXC__Order_Status__c = 'Open';
        insert serviceOrder1;

        workOrderId = serviceOrder1.Id;
    }

     static void createEventData(){
        BusinessHours businessHoursRec = [SELECT Id from BusinessHours where IsDefault = true];
        
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        //Inserting Users
        User techUser = new User();
        techUser.Alias = 'smax-xxx';
        techUser.Email='standarduser@testorg.com'; 
        techUser.EmailEncodingKey='UTF-8'; 
        techUser.LastName='Testing';
        techUser.LanguageLocaleKey='en_US'; 
        techUser.LocaleSidKey='en_US';
        techUser.ProfileId = systemAdminProfile.Id;
        techUser.TimeZoneSidKey='America/Los_Angeles';
        techUser.UserName='standard@testorg.servicemax.com';
        insert techUser;

        SVMXC__Service_Group__c testServiceGroup = new SVMXC__Service_Group__c();
        testServiceGroup.Name = 'testGroupName';
        insert testServiceGroup;

        SVMXC__Service_Group_Members__c testGroupMember = new SVMXC__Service_Group_Members__c();
        testGroupMember.Name = 'testGroupMem';
        testGroupMember.SVMXC__Service_Group__c = testServiceGroup.Id;
        testGroupMember.SVMXC__Salesforce_User__c = techUser.Id;
        if(businessHoursRec != null){  
            testGroupMember.SVMXC__Working_Hours__c = businessHoursRec.Id;
        }
        insert testGroupMember;

        testGroupMemberId = testGroupMember.Id;
        userId = techUser.Id;
    }
}
@isTest
private class SMAX_PS_EventTriggerHandler_UT {

private static Id testGroupMemberId;

    private static Id userId;

    private static Id workOrderId;

    @isTest
    static void test1(){
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

        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();
        //h.beforeInsert();
    

    }

    @isTest
    static void test2(){
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

        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();
        //h.afterInsert();


    }
    
    @isTest
    static void test3(){
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
        update event1;
        
        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();
        //h.beforeUpdate();


    }
    
    @isTest
    static void test4(){
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
        update event1;
        
        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();
        //h.afterUpdate();


    }
    
    @isTest
    static void test5(){
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
        delete event1;
        
        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();
        //h.beforeDelete();


    }
    
    @isTest
    static void test6(){
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
        delete event1;

        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();

        //h.afterDelete();    


    }
    
    @isTest
    static void test7(){
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
        delete event1;
        undelete event1;

        //SMAX_PS_EventTriggerHandler h = new SMAX_PS_EventTriggerHandler();

        //h.afterUndelete();  

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
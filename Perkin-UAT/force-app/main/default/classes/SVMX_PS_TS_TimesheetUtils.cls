/**
* DESCRIPTION : 
* This class handles timesheet fuctionality.
* This creates time entries from work details and events.
*
* MODIFICATION LOG
*---------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                       DATE                  REASON
*---------------------------------------------------------------------------------------------------------------------------------------------------
* chinmay.kant@ge.com             Jul-31-2017           Initial implementation  
* frank.vanloon@bolt-data.com     Feb-05-2018           Locale safe changes
*/
public with sharing class SVMX_PS_TS_TimesheetUtils {
    //These constants are used to retrieve the custom settings. 
    //The names of custom setting stating is timesheet functionality is stopped
    @TestVisible private static final String STOP_TIMESHEET_FUNCTIONALITY= 'Stop Timesheet Functionality';
    //The names of custom setting stating is timesheet functionality is stopped for Work Details
    @TestVisible private static final String STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT = 'Stop for Salesforce Event';
    //The names of custom setting stating is timesheet functionality is stopped for Salesforce Event
    @TestVisible private static final String STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS = 'Stop for Work Details';
    //Variable to store the Usage/Consumption Record Type Name
    @TestVisible private static final String RECORD_TYPE_USAGE_CONSUMPTION = 'Usage/Consumption';
    //Variable to store the Line Type of Labor
    @TestVisible private static final String LINE_TYPE_LABOR = 'Labor';
    //Variable to store the Line Type of Travel
    @TestVisible private static final String LINE_TYPE_TRAVEL = 'Travel';
    //Variable to store the Line Status of Open
    @TestVisible private static final String LINE_STATUS_OPEN = 'Open';
    //Variable to store the Line Status of Submitted
    @TestVisible private static final String LINE_STATUS_SUBMITTED = 'Submitted';

    //Variable to store flag stating is timesheet functionality is stopped
    @TestVisible private boolean isStopFunctionality = null;
    //Variable to store flag stating is timesheet functionality is stopped for Work Details
    @TestVisible private boolean isStopFunctionalityForWorkDetails = null;
    //Variable to store flag stating is timesheet functionality is stopped for Salesforce Event
    @TestVisible private boolean isStopFunctionalityForEvent = null;
    //Variable to store the Id of Usage/Consumption Record Type
    @TestVisible private Id detailRecordTypeId = null;
    //Variable to store the Id of Default Business Hours
    @TestVisible private Id defaultBusinessHoursId = null;
    //Variable to store the duration of Default Business Hours on Monday
    @TestVisible private Long defaultMondayDuration = 0;
    //Variable to store the duration of Default Business Hours on Tuesday
    @TestVisible private Long defaultTuesdayDuration = 0;
    //Variable to store the duration of Default Business Hours on Wednesday
    @TestVisible private Long defaultWednesdayDuration = 0;
    //Variable to store the duration of Default Business Hours on Thursday
    @TestVisible private Long defaultThursdayDuration = 0;
    //Variable to store the duration of Default Business Hours on Friday
    @TestVisible private Long defaultFridayDuration = 0;
    //Variable to store the duration of Default Business Hours on Saturday
    @TestVisible private Long defaultSaturdayDuration = 0;
    //Variable to store the duration of Default Business Hours on Sunday
    @TestVisible private Long defaultSundayDuration = 0;

    /*****************************************************************************************************************************************
    *  Constructor Name  : SVMX_PS_TS_TimesheetUtils
    *  Parameter         : --
    *  Returns           : --
    *  Description       : Retrieve the Default Business Hours
    *******************************************************************************************************************************************/  
    public SVMX_PS_TS_TimesheetUtils(){
        //detailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId();
        detailRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;

        retrieveTimesheetSetting();

        BusinessHours timesheetBusinessHours = [ SELECT Id,MondayEndTime,MondayStartTime,TuesdayEndTime,TuesdayStartTime,
                                                    WednesdayEndTime,WednesdayStartTime,ThursdayEndTime,ThursdayStartTime,
                                                    FridayEndTime,FridayStartTime,SaturdayEndTime,SaturdayStartTime,
                                                    SundayEndTime,SundayStartTime,Name,IsDefault 
                                                    FROM BusinessHours
                                                    WHERE IsDefault = True];

        if(timesheetBusinessHours != null){
            defaultBusinessHoursId = timesheetBusinessHours.Id;
            Map<String,Long> durationMap = getDurationForEachDay(timesheetBusinessHours);

            if(durationMap != null){
                defaultMondayDuration = durationMap.get('Mon');
                defaultTuesdayDuration = durationMap.get('Tue');
                defaultWednesdayDuration = durationMap.get('Wed');
                defaultThursdayDuration = durationMap.get('Thu');
                defaultFridayDuration = durationMap.get('Fri');
                defaultSaturdayDuration = durationMap.get('Sat');
                defaultSundayDuration = durationMap.get('Sun');
            }
        }else{
            System.debug('Unable to find default business hours');
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : handleBeforeTimeSheetTrigger
    *  Parameter   : List<SVMXC__Timesheet__c> timeSheetList - Time Sheet list which is either updated or created
    *  Returns     : --
    *  Description : This method is called in Before Insert and Before Update Event of the Time Sheet
    *                This method keeps the fills the Technician/Equipment field on Timesheets
    *******************************************************************************************************************************************/  
    public void handleBeforeTimeSheetTrigger(List<SVMXC__Timesheet__c> timesheetList){
        //Set of users for which Techs need to be queried.
        Set<Id> userIdSet = new Set<Id>();
        //Map of Salesforce User Id as Key and Technician Id as Value
        Map<Id,Id> salesforceIdTechIdMap = new Map<Id,Id>();

        for(SVMXC__Timesheet__c timesheet : timesheetList){
           userIdSet.add(timesheet.SVMXC__User__c);
        }

        for(SVMXC__Service_Group_Members__c technician : [Select Id, SVMXC__Salesforce_User__c FROM SVMXC__Service_Group_Members__c
                                                            where SVMXC__Salesforce_User__c IN :userIdSet]){
            salesforceIdTechIdMap.put(technician.SVMXC__Salesforce_User__c, technician.Id);
        }

        for(SVMXC__Timesheet__c timesheet : timesheetList){
            if(timesheet.SVMXC__User__c != null){
                timesheet.SVMX_PS_TS_Group_Member__c = salesforceIdTechIdMap.get(timesheet.SVMXC__User__c);
            }else{
                System.debug('No Timesheet User Found');
            }
        }
    }

    /*****************************************************************************************************************************************
                        METHODS TO HANDLE TIME ENTRY CREATION/UPDATION/DELETION FROM WORK DETAIL
    *******************************************************************************************************************************************/ 

    /*****************************************************************************************************************************************
    *  Method Name : handleEventsFromWorkDetails
    *  Parameter   : List<SVMXC__Service_Order_Line__c> detailList - Work Details which are created (used when inserted/updated)
    *                Map<Id, SVMXC__Service_Order_Line__c> oldMap -  Map of old Work Details (used when updated)
    *                List<SVMXC__Service_Order_Line__c> olddetailList - old Work Details List (used when deleted)
    *                Boolean isInsert - Event to specify event is Insert
    *                Boolean isUpdate - Event to specify event is Update
    *                Boolean isDelete - Event to specify event is Delete
    *  Returns     : --
    *  Description : This method is called is called in After Insert of 
    *******************************************************************************************************************************************/  
    public void handleEventsFromWorkDetails(List<SVMXC__Service_Order_Line__c> detailList, 
                                            Map<Id, SVMXC__Service_Order_Line__c> oldMap,
                                            List<SVMXC__Service_Order_Line__c> olddetailList, 
                                            Boolean isInsert,
                                            Boolean isUpdate,
                                            Boolean isDelete) {

        if(!isStopFunctionality && !isStopFunctionalityForWorkDetails){
            System.debug('Time Entry Handling : Timesheet Functionality is active for Work Details.  Hence Proceed further');
            if(isInsert){
                createTimeEventsFromWorkDetails(detailList);
            }else if(isUpdate){
                updateTimeEventsFromWorkDetails(detailList, oldMap);
            }else if(isDelete){
                deleteTimeEventsFromWorkDetails(olddetailList);
            }
        }else{
            System.debug('Time Entry Handling : Timesheet Functionality is stopped for Work Details. Hence do not Proceed further.');
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : createTimeEventsFromWorkDetails
    *  Parameter   : List<SVMXC__Service_Order_Line__c> detailList - work details which are created
    *  Returns     : --
    *  Description : This method is called is called in After Insert of Work Details Record
    *                This method handles the creation of time entry
    *                This follows following logic:-
    *                   When a timesheet is in Open/Submitted Status, Create a new Time Entry
    *                   When a timesheet is in Closed/Approved Status, Create an +Ve Time Entry with an Overlapping Timesheet if needed
    *******************************************************************************************************************************************/  
    @TestVisible private void createTimeEventsFromWorkDetails(List<SVMXC__Service_Order_Line__c> detailList) {

        System.debug('Time Entry Handling : Handle Creation Event for Work Details');

        //List of work details which are valid for creation of time entry
        List<TimesheetWrapper> validWorkDetailWrapperList = new List<TimesheetWrapper>();

        //Find out the correct work details 
        //Only Labor and Travel are valid else not.
        for (SVMXC__Service_Order_Line__c detail : detailList) {            
            if (isLaborOrTravelWD(detail)){
                if(detail.SVMXC__Start_Date_and_Time__c != null 
                    && detail.SVMXC__End_Date_and_Time__c != null
                    && detail.SVMXC__Group_Member__c != null){
                        System.debug('Time Entry Handling : ' + detail.Id + 'is valid for Time Entry Creation');
                        TimesheetWrapper wrapper = new TimesheetWrapper(false, detail);
                        validWorkDetailWrapperList.add(wrapper);
                }else{
                    System.debug('Time Entry Handling : ' + detail.Id + ' is not valid as either Start/End Time Or Technician is not populated');
                }
            }else{
                System.debug('Time Entry Handling : ' + detail.Id + ' is not valid as either Labor/Travel Line');
            }
        }

        //if found any valid labor/travel work details, then create time entries
        if(validWorkDetailWrapperList.size() > 0){
            System.debug('Time Entry Handling : Start creating Time Entry');
            handleTimeEventsCreationFromWorkDetails(validWorkDetailWrapperList);
            System.debug('Time Entry Handling : Done with Creating Time Entry');
        }else{
            System.debug('Time Entry Handling : No Work Details are valid for time entry creation');
        }
        
        System.debug('Time Entry Handling : Handled Creation Event for Work Details');
    }

    /*****************************************************************************************************************************************
    *  Method Name : deleteTimeEventsFromWorkDetails
    *  Parameter   : List<SVMXC__Service_Order_Line__c> detailList - list of work details which are deleted
    *  Returns     : --
    *  Description : This method is called is called in Before Delete of Work Details Record
    *                This handles Work Detail Delete Scenario
    *                This follows following logic:-
    *                   When a timesheet is in Open Status, Delete The Time Entry associated with Work Detail
    *                   When a timesheet is in Submitted/Closed/Approved Status, Create an -Ve Time Entry with an Overlapping Timesheet if needed
    *******************************************************************************************************************************************/  
    @TestVisible private void deleteTimeEventsFromWorkDetails(List<SVMXC__Service_Order_Line__c> detailList){
        System.debug('Time Entry Handling : Handle Deletion Event for Work Details');

        //Set of valid Work Detail Id Set to be used to query Time Entries
        Set<Id> workDetailIdSet = new Set<Id>();
        //Set of valid Work Details which are either Labor/Travel and have proper Start/End Time.
        Set<SVMXC__Service_Order_Line__c> validWorkDetailLinesSet = new Set<SVMXC__Service_Order_Line__c>();
        //Map of work detail Id as key and its associated Time Entry as value. 
        //This used to store the relationship between work detail & time entry
        Map<Id,SVMXC__Timesheet_Entry__c> workDetailIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
        //Time Entries which will be deleted
        List<SVMXC__Timesheet_Entry__c> deleteEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //List of work details which have timesheets in closed and need to create an overlapping one.
        List<TimesheetWrapper> workDetailsForNegativeTimeCreationList = new List<TimesheetWrapper>();

        //Find the valid work details
        for (SVMXC__Service_Order_Line__c detail : detailList){
            if (isLaborOrTravelWD(detail) 
               && detail.SVMXC__Start_Date_and_Time__c != null 
               && detail.SVMXC__End_Date_and_Time__c != null){
                System.debug('Time Entry Handling : ' + detail.Id + 'is valid for time entry deletion event');
                workDetailIdSet.add(detail.Id);
                validWorkDetailLinesSet.add(detail);
            }else{
                 System.debug('Time Entry Handling : Work Detail ' + detail.Id + ' is not valid for time entry deletion event');
            }
        }
        
        //If found any, then delete appropriate time entry. If timesheet is approved, then create appropriate -ve entry
        if (workDetailIdSet.size() > 0){   
            //find the relative time entries. This method ensures that appropriate time entry is choosen among all.
            workDetailIdTimeEntryMap = findRelativeTimeEntryForWorkDetails(workDetailIdSet);
            
            for(SVMXC__Service_Order_Line__c detail : validWorkDetailLinesSet){
                //Get the Time Entry
                SVMXC__Timesheet_Entry__c timeEntry = workDetailIdTimeEntryMap.get(detail.Id);

                if(timeEntry != null){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;
                    //If open/submitted, delete the Time Entry
                    if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry Handling : Timesheet is open/submitted. Hence just delete the entry');
                        deleteEntryList.add(timeEntry);
                    //If not open,/submitted create -ve Time Entry
                    }else{
                        System.debug('Time Entry Handling : Timesheet is closed/approved. Hence create negative entry');
                        TimesheetWrapper wrapper = new TimesheetWrapper(true,detail);
                        workDetailsForNegativeTimeCreationList.add(wrapper);
                    }
                }else{
                   System.debug('Time Entry Handling : No Time Entry found for Work Detail -' + detail.Id  + '. Hence cannot delete time entry'); 
                }
            }

            //Handle creation of negative time entry creation.
            if(workDetailsForNegativeTimeCreationList.size() > 0){
                System.debug('Time Entry Handling : Create Negative Time Entries for closed timesheet');
                handleTimeEventsCreationFromWorkDetails(workDetailsForNegativeTimeCreationList);
                System.debug('Time Entry Handling : Completed Creation Negative Time Entries for closed timesheet');
            }

            //Handle deletion of time entries.
            if (!deleteEntryList.isEmpty()){
                System.debug('Time Entry Handling : Delete Time Entries for open timesheet');
                delete deleteEntryList;
                System.debug('Time Entry Handling : Delete Time Entries for open timesheet');
            }              
        }else{
             System.debug('Time Entry Handling : No Valid Work Details for Deletion');
        }

        System.debug('Time Entry Handling : Handle Deletion Event for Work Details');
    }

    /*****************************************************************************************************************************************
    *  Method Name : updateTimeEventsFromWorkDetails
    *  Parameter   : List<SVMXC__Service_Order_Line__c> detailList - list of work details with new updated data
    *                Map<Id, SVMXC__Service_Order_Line__c> oldMap - map of work detail id as key and work detail as record which refers to old
    *                                                               state
    *  Returns     : --
    *  Description : Handles Work Detail Update Scenario.
    *                Based on current Status of Timesheets, following logic will be applied
    *                The code will fire only if the folllowing fields are changed:-
    *                   a. SVMXC__Start_Date_and_Time__c
    *                   b. SVMXC__End_Date_and_Time__c
    *                   c. SVMXC__Work_Description__c
    *                If the Work Detail is changed, query the associated Time Entry.
    *                If No Time Entry found, create a new one
    *                If found and Timesheet is in Open/Submitted State, then follow the logic:-
    *                   If only Time is changed, update the old Time Entry
    *                   If Date is changed (within/outside of timesheet), delete the old Time Entry & create a new one
    *                If found and Timesheet is in Closed/Approved State, then follow the logic:-
    *                   If only Time is changed/Date is changed (within/outside of timesheet), create the -ve entry for old Time & + ve 
    *                   Time Entry for new Time. Also , if needed, create overlapping timesheet
    *******************************************************************************************************************************************/  
    @TestVisible private void updateTimeEventsFromWorkDetails(List<SVMXC__Service_Order_Line__c> detailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap){
        //Set of valid Work Detail Id Set
        Set<Id> workDetailIdSet = new Set<Id>();
        //Set of valid Work Details
        Set<SVMXC__Service_Order_Line__c> validWorkDetailLinesSet = new Set<SVMXC__Service_Order_Line__c>();
        //List of updated Time Entries which will be finally stored to db.
        List<SVMXC__Timesheet_Entry__c> updatedTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //List of all timesheet wrappers for which we need to create proper new time entries
        List<TimesheetWrapper> timesheetWrapperList = new List<TimesheetWrapper>();
        //List of time entries need to be deleted
        List<SVMXC__Timesheet_Entry__c> deletedTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //Map of work detail Id as key and its associated Time Entry as value
        Map<Id,SVMXC__Timesheet_Entry__c> workDetailIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
       
        //Find out the correct work details 
        //Only Labor and Travel are valid else not.
        //Also there should be change in the start/end date or description.
        for (SVMXC__Service_Order_Line__c detail : detailList) {
           
            System.debug('Time Entry Handling : Handle Work Detail - ' + detail.Id);
            
            SVMXC__Service_Order_Line__c oldDetail = oldMap.get(detail.Id);

            if (isLaborOrTravelWD(detail) 
                && detail.SVMXC__Start_Date_and_Time__c != null 
                && detail.SVMXC__End_Date_and_Time__c != null
                && (oldDetail.SVMXC__Start_Date_and_Time__c != detail.SVMXC__Start_Date_and_Time__c
                || oldDetail.SVMXC__End_Date_and_Time__c != detail.SVMXC__End_Date_and_Time__c
                || oldDetail.SVMXC__Work_Description__c != detail.SVMXC__Work_Description__c)){
                System.debug('Time Entry Handling : Work Detail has either Start/End Time or Description is changed');
                workDetailIdSet.add(detail.Id);
                validWorkDetailLinesSet.add(detail);
            }else{
                System.debug('Time Entry Handling : Work Detail is not valid for Time Entry Updation');
            }
        }
        
        if (workDetailIdSet.size() > 0) { 
            //find the relative time entries. This method ensures that appropriate time entry is choosen among all.
            workDetailIdTimeEntryMap = findRelativeTimeEntryForWorkDetails(workDetailIdSet);

            for(SVMXC__Service_Order_Line__c detail : validWorkDetailLinesSet){

                System.debug('Time Entry Handling : Handle update for ' + detail.Id);

                SVMXC__Timesheet_Entry__c timeEntry = workDetailIdTimeEntryMap.get(detail.Id);

                //get the start date of the time entry
                //Generally Start Date and End Date of the Work Detail will be same.
                //Hence just check Start Date.
                Date workDetailStartDate = detail.SVMXC__Start_Date_and_Time__c.date();

                if(timeEntry != null){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;
                    //if the timesheet is in open/submitted state
                    if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry Handling : Timesheet is open/submitted. Hence handle update');

                        //check if only time is changed, just update the time. No changes to daily Summary and timesheet
                        if(workDetailStartDate == timeEntry.SVMXC__Start_Time__c.date()){
                            System.debug('Time Entry Handling : Only Time is changed. Hence no changes to Daily Summary or Timesheet');

                            timeEntry.SVMXC__Start_Time__c = detail.SVMXC__Start_Date_and_Time__c;
                            timeEntry.SVMXC__End_Time__c = detail.SVMXC__End_Date_and_Time__c;
                            timeEntry.SVMXC__Comments__c = detail.SVMXC__Work_Description__c;
                            timeEntry.SVMXC__Duration__c = ((Decimal) (timeEntry.SVMXC__End_Time__c.getTime() - timeEntry.SVMXC__Start_Time__c.getTime()) / 3600000.0).setScale(2);
                            timeEntry.SVMX_PS_TS_Time_Entry_Start_Date__c = detail.SVMXC__Start_Date_and_Time__c.date();
                            timeEntry.SVMX_PS_TS_Time_Entry_End_Date__c = detail.SVMXC__End_Date_and_Time__c.date();
                
                            if(detail.SVMXC__Line_Type__c == LINE_TYPE_LABOR){
                                timeEntry.SVMXC__Activity__c = LINE_TYPE_LABOR;
                            }else if(detail.SVMXC__Line_Type__c == LINE_TYPE_TRAVEL ){
                                timeEntry.SVMXC__Activity__c = LINE_TYPE_TRAVEL;
                            }else{
                                timeEntry.SVMXC__Activity__c = detail.SVMXC__Activity_Type__c;
                            }
                            updatedTimeEntryList.add(timeEntry);
                        }else{
                            //Check if the time is moved within the timesheet. If yes, then update daily Summary only.
                            if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c <= workDetailStartDate &&
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c >= workDetailStartDate){
                                System.debug('Time Entry Handling : Date is moved within Timesheet. Hence changes Daily Summary');
                            //Check if the time is moved outside the timesheet. If yes, then update daily Summary and timesheet
                            }else if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c >= workDetailStartDate ||
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c <= workDetailStartDate){
                                System.debug('Time Entry Handling : Date is moved outside Timesheet. Hence changes Daily Summary & Timesheet');
                            }

                            //Create a postive Time Entry for new data.
                            TimesheetWrapper wrapper = new TimesheetWrapper(false, detail);
                            timesheetWrapperList.add(wrapper);
                            //delete the old Time Entry
                            deletedTimeEntryList.add(timeEntry);
                        }
                    }else{
                        System.debug('Time Entry Handling : Timesheet is closed/approved. Hence handle overlapping');
                       
                        //check if only time is changed, just update the time. No changes to daily Summary and timesheet
                        if(workDetailStartDate == timeEntry.SVMXC__Start_Time__c.date()){
                            System.debug('Time Entry Handling : Only Time is changed. Hence no changes to Daily Summary or Timesheet.' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                        }else{
                            //Check if the time is moved within the timesheet. If yes, then update daily Summary only.
                            if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c <= workDetailStartDate &&
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c >= workDetailStartDate){
                                System.debug('Time Entry Handling : Date is moved within Timesheet. Hence changes Daily Summary' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                            //Check if the time is moved outside the timesheet. If yes, then update daily Summary and timesheet
                            }else if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c >= workDetailStartDate ||
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c <= workDetailStartDate){
                                System.debug('Time Entry Handling : Date is moved outside Timesheet. Hence changes Daily Summary & Timesheet' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                            }
                        }

                        //Create a postive Time Entry for new data.
                        TimesheetWrapper wrapper = new TimesheetWrapper(false, detail);
                        timesheetWrapperList.add(wrapper);

                        //find the old Work Detail
                        SVMXC__Service_Order_Line__c oldDetail = oldMap.get(detail.Id);
                        //Create a negative Time Entry for old data
                        TimesheetWrapper negativeEntryWrapper = new TimesheetWrapper(true, oldDetail);
                        timesheetWrapperList.add(negativeEntryWrapper);
                    }
                }else{
                    System.debug('Time Entry Handling : No Time Entry found for Work Detail -' + detail.Id  + '. Hence create a new time entry'); 
                    //Create a postive Time Entry for new data.
                    TimesheetWrapper wrapper = new TimesheetWrapper(false, detail);
                    timesheetWrapperList.add(wrapper);
                }
            }

            if (!updatedTimeEntryList.isEmpty()){
                System.debug('Time Entry Handling : Update Time Entries directly which are in Open/Submitted Timesheet');
                update updatedTimeEntryList;
                System.debug('Time Entry Handling : Update Done for Time Entries directly which are in Open/Submitted Timesheet');
            }

            if(!deletedTimeEntryList.isEmpty()){
                System.debug('Time Entry Handling : Delete Time Entries which are in Open/Submitted Timesheet');
                delete deletedTimeEntryList;
                System.debug('Time Entry Handling : Delete done for Time Entries which are in Open/Submitted Timesheet');
            } 

            if(!timesheetWrapperList.isEmpty()){
                System.debug('Time Entry Handling : Handle Creation of Overlapping Time Entries');
                handleTimeEventsCreationFromWorkDetails(timesheetWrapperList);
                System.debug('Time Entry Handling : Creation of Overlapping Time Entries done');
            }             
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : handleTimeEventsCreationFromWorkDetails
    *  Parameter   : List<TimesheetWrapper> validWorkDetailWrapperList - list of valid work details
    *  Returns     : --
    *  Description : This method handles the creation of time entry
    *                Based on current status of timesheet, it will create a new entry.
    *                If needed, it will create a new overlapping timesheet.
    *                Also, based on the flag in wrapper, it will create +ve or -ve Time Entry.
    *******************************************************************************************************************************************/  
     @TestVisible private void handleTimeEventsCreationFromWorkDetails(List<TimesheetWrapper> validWorkDetailWrapperList) {
        //List of Time Entries newly created
        List<SVMXC__Timesheet_Entry__c> createdTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //Set of Technician Ids to be used to query the Business Hours and Timesheets
        Set<Id> technicianIdSet = new Set<Id>();
        //Set of Dates to query the Timesheets
        Set<Date> timesheetDateSet = new Set<Date>();
         //Set of Salesforce User Ids to query the Timesheets
        Set<Id> timesheetSalesforceUserSet = new Set<Id>();
        //Map to indicate the Technician ID as Key and Techncian Record which includes its Business Hours as Value
        Map<Id, SVMXC__Service_Group_Members__c> technicianIdTechnicianMap = new  Map<Id, SVMXC__Service_Group_Members__c> ();
        //Map to store Technician Id as Key and all associated Daily Summaries
        Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>> techTimesheetDayMap = new Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>>();
        //Map to store Technician Id as Key and all associated Daily Summaries
        Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>> closedTechTimesheetDayMap = new Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>>();
        //Map of Work Detail Id as key and Salesforce User Id as Value
        Map<Id,Id> detailIdSalesforceUserIdMap = new Map<Id,Id>();
        //Map of Work Detail Id as key and Technician Id as Value
        Map<Id,Id> detailIdTechnicianIdMap = new Map<Id,Id>();
        //Map with Key created from combination of Salesforce User Id to which the Daily Summary belongs and Date of Daily Summary 
        //and Value is the Daily Summary Record itself
        Map<String, SVMXC__Timesheet_Day_Entry__c> dailyEntryMap = new Map<String, SVMXC__Timesheet_Day_Entry__c>();
        //Map of Salesforce User Id as key and Business Hours as value
        Map<Id,BusinessHours> sfIdBusinessHrsMap = new  Map<Id,BusinessHours>();
        //Map to store unique id created from using Salesforce User Id to which Timesheet belongs, Start Date of Timesheet and End Date
        //of Timesheet as Key and Newly Created Timesheet as Value
        Map<String,SVMXC__Timesheet__c> timesheetMap = new Map<String,SVMXC__Timesheet__c>();
        
        
        if(validWorkDetailWrapperList.size() > 0){
            //Get all Technicians 
            for (TimesheetWrapper wrapper : validWorkDetailWrapperList) {
                SVMXC__Service_Order_Line__c detail = wrapper.getWorkDetail();       
                technicianIdSet.add(detail.SVMXC__Group_Member__c);
            }

            //If found then query all the Techncians Record.
            technicianIdTechnicianMap = new Map<Id, SVMXC__Service_Group_Members__c>(
                                                [SELECT Id, SVMXC__Salesforce_User__c, SVMXC__Working_Hours__c, SVMXC__Working_Hours__r.MondayEndTime, 
                                                        SVMXC__Working_Hours__r.MondayStartTime, SVMXC__Working_Hours__r.TuesdayEndTime,
                                                        SVMXC__Working_Hours__r.TuesdayStartTime, SVMXC__Working_Hours__r.WednesdayEndTime,
                                                        SVMXC__Working_Hours__r.WednesdayStartTime, SVMXC__Working_Hours__r.ThursdayEndTime,
                                                        SVMXC__Working_Hours__r.ThursdayStartTime, SVMXC__Working_Hours__r.FridayEndTime,
                                                        SVMXC__Working_Hours__r.FridayStartTime, SVMXC__Working_Hours__r.SaturdayEndTime,
                                                        SVMXC__Working_Hours__r.SaturdayStartTime, SVMXC__Working_Hours__r.SundayEndTime,
                                                        SVMXC__Working_Hours__r.SundayStartTime
                                                    FROM SVMXC__Service_Group_Members__c
                                                    WHERE Id IN :technicianIdSet]);

            //Create the map of Business Hours Record which will be used to while creating daily summaries
            for(Id technicianId : technicianIdTechnicianMap.keySet()){
               SVMXC__Service_Group_Members__c technicianRecord = technicianIdTechnicianMap.get(technicianId);

               if(technicianRecord.SVMXC__Working_Hours__c != null && technicianRecord.SVMXC__Salesforce_User__c != null){
                    BusinessHours businessHours = new BusinessHours();
                    businessHours.MondayStartTime = technicianRecord.SVMXC__Working_Hours__r.MondayStartTime;
                    businessHours.MondayEndTime = technicianRecord.SVMXC__Working_Hours__r.MondayEndTime;
                    businessHours.TuesdayEndTime = technicianRecord.SVMXC__Working_Hours__r.TuesdayStartTime;
                    businessHours.TuesdayStartTime = technicianRecord.SVMXC__Working_Hours__r.TuesdayEndTime;
                    businessHours.WednesdayEndTime = technicianRecord.SVMXC__Working_Hours__r.WednesdayEndTime;
                    businessHours.WednesdayStartTime = technicianRecord.SVMXC__Working_Hours__r.WednesdayStartTime;
                    businessHours.ThursdayEndTime = technicianRecord.SVMXC__Working_Hours__r.ThursdayEndTime;
                    businessHours.ThursdayStartTime = technicianRecord.SVMXC__Working_Hours__r.ThursdayStartTime;
                    businessHours.FridayEndTime = technicianRecord.SVMXC__Working_Hours__r.FridayEndTime;
                    businessHours.FridayStartTime = technicianRecord.SVMXC__Working_Hours__r.FridayStartTime;
                    businessHours.SaturdayEndTime = technicianRecord.SVMXC__Working_Hours__r.SaturdayEndTime;
                    businessHours.SaturdayStartTime = technicianRecord.SVMXC__Working_Hours__r.SaturdayStartTime;
                    businessHours.SundayEndTime = technicianRecord.SVMXC__Working_Hours__r.SundayEndTime; 
                    businessHours.SundayStartTime = technicianRecord.SVMXC__Working_Hours__r.SundayStartTime;

                    sfIdBusinessHrsMap.put(technicianRecord.SVMXC__Salesforce_User__c, businessHours);
               }
            }

            //Now create Time Entries for each valid work details
            for (TimesheetWrapper wrapper : validWorkDetailWrapperList) {
                //Get the work detail from wrapper
                SVMXC__Service_Order_Line__c detail = wrapper.getWorkDetail();

                //Check if Salesforce User and Technician are linked or not. If not, we cannot proceed further.
                if(technicianIdTechnicianMap.get(detail.SVMXC__Group_Member__c) != null){
                    //Get the Salesforce User Id of Technician.
                    Id salesforceUserId = technicianIdTechnicianMap.get(detail.SVMXC__Group_Member__c).SVMXC__Salesforce_User__c;

                    //Create a new Time Entry
                    SVMXC__Timesheet_Entry__c timeEntry = new SVMXC__Timesheet_Entry__c();
                    timeEntry.SVMXC__Work_Detail__c = detail.Id;
                    timeEntry.SVMXC__Start_Time__c = detail.SVMXC__Start_Date_and_Time__c;
                    timeEntry.SVMXC__End_Time__c = detail.SVMXC__End_Date_and_Time__c;
                    timeEntry.SVMXC__Comments__c = detail.SVMXC__Work_Description__c;
                    timeEntry.SVMXC__Duration__c = ((Decimal) (timeEntry.SVMXC__End_Time__c.getTime() - timeEntry.SVMXC__Start_Time__c.getTime()) / 3600000.0).setScale(2);
                    timeEntry.SVMX_PS_TS_Time_Entry_Start_Date__c = detail.SVMXC__Start_Date_and_Time__c.date();
                    timeEntry.SVMX_PS_TS_Time_Entry_End_Date__c = detail.SVMXC__End_Date_and_Time__c.date();

                    //The flag "SVMX_Is_Negative_Time_Entry__c" will make the duration as negative.
                    if(wrapper.getIsNegativeTimeEntry()){
                        timeEntry.SVMXC__Duration__c = timeEntry.SVMXC__Duration__c * -1.0;
                    }
                
                    //Set appropriate Activty Value
                    if(detail.SVMXC__Line_Type__c == LINE_TYPE_LABOR){
                        timeEntry.SVMXC__Activity__c = LINE_TYPE_LABOR;
                    }else if(detail.SVMXC__Line_Type__c == LINE_TYPE_TRAVEL ){
                        timeEntry.SVMXC__Activity__c = LINE_TYPE_TRAVEL;
                    }else{
                        timeEntry.SVMXC__Activity__c = detail.SVMXC__Activity_Type__c;
                    }
                
                    //Store the time entry for insertion.
                    createdTimeEntryList.add(timeEntry);
                    //Add the start time to query timesheet daily summary associated with that period
                    timesheetDateSet.add(timeEntry.SVMXC__Start_Time__c.date());
                    //Add Salesforce User to query timesheet daily summary associated
                    timesheetSalesforceUserSet.add(salesforceUserId);
                    //Store the associated Salesforce User Id with the Work Detail. This will be used for finding proper time sheet.
                    detailIdSalesforceUserIdMap.put(detail.Id,salesforceUserId);
                    //Store the associated Technician Id with Work Detail
                    detailIdTechnicianIdMap.put(detail.Id,detail.SVMXC__Group_Member__c);
                }else{
                    System.debug('Time Entry Handling : ' + detail.Id + ' does have a proper technician - ' + detail.SVMXC__Group_Member__c);
                }
            }

            //Now query all daily summaries for all the time entries which we want to create.
            for (SVMXC__Timesheet_Day_Entry__c dailySummary : [SELECT Id, SVMXC__Timesheet__c, SVMXC__Timsheet_Day__c, SVMXC__Timesheet__r.SVMXC__User__c,
                                                                            SVMXC__Timesheet__r.SVMXC__Status__c 
                                                                FROM SVMXC__Timesheet_Day_Entry__c 
                                                                WHERE SVMXC__Timsheet_Day__c IN :timesheetDateSet AND 
                                                                      SVMXC__Timesheet__r.SVMXC__User__c IN :timesheetSalesforceUserSet]){
                
                Map<Date, SVMXC__Timesheet_Day_Entry__c> dayMap = null;

                //Get the status
                String status = dailySummary.SVMXC__Timesheet__r.SVMXC__Status__c;
                //if the timesheet is in Open/Submitted state
                if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                    //This daily summary belongs to open/submitted timesheets.
                    if(techTimesheetDayMap.containsKey(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c)){
                        dayMap = techTimesheetDayMap.get(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c);
                    }else{
                        dayMap = new Map<Date, SVMXC__Timesheet_Day_Entry__c>();
                        techTimesheetDayMap.put(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c,dayMap);
                    }
                    dayMap.put(dailySummary.SVMXC__Timsheet_Day__c, dailySummary);
                }else{
                    //This daily summary belongs to either closed/approved timesheets.
                    //This will help in creating overlapping timesheet
                    if(closedTechTimesheetDayMap.containsKey(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c)){
                        dayMap = closedTechTimesheetDayMap.get(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c);
                    }else{
                        dayMap = new Map<Date, SVMXC__Timesheet_Day_Entry__c>();
                        closedTechTimesheetDayMap.put(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c,dayMap);
                    }
                    dayMap.put(dailySummary.SVMXC__Timsheet_Day__c, dailySummary);
                }
            }

            //Now, here we are trying to associate the time entries with apporpriate daily summary and timesheet.
            for (SVMXC__Timesheet_Entry__c timeEntry : createdTimeEntryList) {
                
                //check if the timesheet exists in open state.
                if (detailIdSalesforceUserIdMap.containsKey(timeEntry.SVMXC__Work_Detail__c) 
                    && techTimesheetDayMap.containsKey(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c)) 
                    && (techTimesheetDayMap.get(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))).containsKey(timeEntry.SVMXC__Start_Time__c.date())) {
                        //here check if timesheet is found in open status
                        //Associate it with time entry.
                        SVMXC__Timesheet_Day_Entry__c dailySummary = (techTimesheetDayMap.get(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))).get(timeEntry.SVMXC__Start_Time__c.date());
                        timeEntry.SVMXC__Timesheet__c = dailySummary.SVMXC__Timesheet__c;
                        timeEntry.SVMXC__Timesheet_Day__c = dailySummary.Id;
                }else{
                    //
                    String key = null;
                    
                    //This is to make sure if we are creating timesheets on sunday
                    //which will be the nextStartOfweek, the time entries should go on
                    //last week timesheets and not this one
                    //String dayOfWeek = timeEntry.SVMXC__Start_Time__c.format('EEE');
                    //if(dayOfWeek.equals('Sun')){
                    //    DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
                    //    key =   String.valueOf(detailIdSalesforceUserIdMap.get(String.valueOf(timeEntry.SVMXC__Work_Detail__c)))
                    //                + previousDay.date().toStartOfWeek().addDays(1)
                    //                + previousDay.date().toStartOfWeek().addDays(7);
                    //}else{
                    //    key = String.valueOf(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))
                    //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(1)
                    //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(7);
                    //}
                    Integer dayOfWeek = getDayOfWeek(timeEntry.SVMXC__Start_Time__c.date());
                    if(dayOfWeek == 0){
                        DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
                        key =   String.valueOf(detailIdSalesforceUserIdMap.get(String.valueOf(timeEntry.SVMXC__Work_Detail__c)))
                                    + toStartOfWeek(previousDay.date()).addDays(1)
                                    + toStartOfWeek(previousDay.date()).addDays(7);
                    }else{
                        key = String.valueOf(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))
                                    + toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(1)
                                    + toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(7);
                    }
                    
                    //This check is to not create duplicate timesheets for same period.
                    if (!timesheetMap.containsKey(key)) {

                        boolean isOverlapFound = false; 

                        if (detailIdSalesforceUserIdMap.containsKey(timeEntry.SVMXC__Work_Detail__c) 
                            && closedTechTimesheetDayMap.containsKey(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c)) 
                            && (closedTechTimesheetDayMap.get(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))).containsKey(timeEntry.SVMXC__Start_Time__c.date())) {
                            isOverlapFound = true;
                        }

                        SVMXC__Service_Group_Members__c technician = technicianIdTechnicianMap.get(detailIdTechnicianIdMap.get(timeEntry.SVMXC__Work_Detail__c));
                        SVMXC__Timesheet__c newTimesheet = createNewTimeSheet(timeEntry, technician.SVMXC__Salesforce_User__c, technician.SVMXC__Working_Hours__c, isOverlapFound);
                        timesheetMap.put(key, newTimesheet);
                    }
                }
            }
                
            //If needed to create the timesheet, then create timesheet and daily summary.
            if (!timesheetMap.isEmpty()) {
                //insert Timesheets
                insert timesheetMap.values();
                //create daily summaries
                dailyEntryMap = createTimeSheetDailySummary(timesheetMap.values(),sfIdBusinessHrsMap);
                //insert daily summary
                insert dailyEntryMap.values();
                for (String dailyKey : dailyEntryMap.keySet())
                {
                    System.debug('>> DailyEntryMap[' + dailyKey + '] = ' + dailyEntryMap.get(dailyKey));
                }
            }
            
            //Associate Time Entries with the Timesheets
            for (SVMXC__Timesheet_Entry__c timeEntry : createdTimeEntryList) {
                if (timeEntry.SVMXC__Timesheet_Day__c == null || timeEntry.SVMXC__Timesheet__c == null) {

                    String dayKey = String.valueOf(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c)) + timeEntry.SVMXC__Start_Time__c.date();
                    System.debug('>> Trying to get DailyEntry Key = ' + dayKey);
                    SVMXC__Timesheet_Day_Entry__c dayEntry = dailyEntryMap.get(dayKey);
                    if(dayEntry != null){
                        timeEntry.SVMXC__Timesheet_Day__c = dayEntry.Id;
                        timeEntry.SVMX_PS_TS_Timesheet_Daily_Summary_Date__c = dayEntry.SVMXC__Timsheet_Day__c;

                        //This is to make sure if we are creating timesheets on sunday
                        //which will be the nextStartOfweek, the time entries should go on
                        //last week timesheets and not this one
                        //String key = String.valueOf(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))
                        //                +timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(1)
                        //                +timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(7);
                        //String dayOfWeek = timeEntry.SVMXC__Start_Time__c.format('EEE');
                        //if(dayOfWeek.equals('Sun')){
                        //    DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);

                        //    key =   String.valueOf(detailIdSalesforceUserIdMap.get(String.valueOf(timeEntry.SVMXC__Work_Detail__c)))
                        //                + previousDay.date().toStartOfWeek().addDays(1)
                        //                + previousDay.date().toStartOfWeek().addDays(7);
                        //}
                        String key = String.valueOf(detailIdSalesforceUserIdMap.get(timeEntry.SVMXC__Work_Detail__c))
                                        +toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(1)
                                        +toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(7);
                        Integer dayOfWeek = getDayOfWeek(timeEntry.SVMXC__Start_Time__c.date());
                        if(dayOfWeek == 0){
                            DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);

                            key =   String.valueOf(detailIdSalesforceUserIdMap.get(String.valueOf(timeEntry.SVMXC__Work_Detail__c)))
                                        + toStartOfWeek(previousDay.date()).addDays(1)
                                        + toStartOfWeek(previousDay.date()).addDays(7);
                        }
                                                        
                        timeEntry.SVMXC__Timesheet__c = timesheetMap.get(key).Id; 
                    }    
                }
            }
            
            if (! createdTimeEntryList.isEmpty()) {
                insert createdTimeEntryList;
            }
        }else{
            System.debug('Time Entry Handling : No Valid Work Detail found for creation of time entry');
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : findRelativeTimeEntryForWorkDetails
    *  Parameter   : Set<Id> workDetailIdSet - Set of Work Detail Ids against which we want to find time entry
    *  Returns     : Map<Id,SVMXC__Timesheet_Entry__c> - Map of Work Detail Id as key and associated Time Entry as Value
    *  Description : This method is finds the appropriate Time Entry for the Work Detail
    *                Following Logic is applied to make sure that Time Entry is appropriate:-
    *                   a.  Use Time Entry with Open/Submitted Timesheets First
    *                   b.  If not found, Use Time entry which is Created Latest (means last approved one)
    *******************************************************************************************************************************************/
     @TestVisible private Map<Id,SVMXC__Timesheet_Entry__c> findRelativeTimeEntryForWorkDetails(Set<Id> workDetailIdSet){
        //Map of work detail Id as key and its associated Time Entry as value
        Map<Id,SVMXC__Timesheet_Entry__c> workDetailIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
        //Map of work detail Id as key and its associated Time Entry all time entries with postive duration
        Map<Id,List<SVMXC__Timesheet_Entry__c>> workDetailIdTimeEntryListMap = new Map<Id,List<SVMXC__Timesheet_Entry__c>>();

        //populate map
        for (SVMXC__Timesheet_Entry__c timeEntry : [SELECT Id, SVMXC__Work_Detail__c, SVMXC__Activity__c, 
                                                                SVMXC__Start_Time__c, SVMXC__End_Time__c, SVMXC__Comments__c,
                                                                SVMXC__Duration__c, SVMXC__Timesheet__r.SVMXC__Status__c, 
                                                                SVMXC__Timesheet__r.SVMXC__End_Date__c, 
                                                                SVMXC__Timesheet__r.SVMXC__Start_Date__c,
                                                                SVMXC__Timesheet__r.SVMXC__User__c, CreatedDate 
                                                            FROM SVMXC__Timesheet_Entry__c 
                                                            WHERE SVMXC__Work_Detail__c IN :workDetailIdSet 
                                                                AND SVMXC__Duration__c > 0]){
            List<SVMXC__Timesheet_Entry__c> timeEntryList = workDetailIdTimeEntryListMap.get(timeEntry.SVMXC__Work_Detail__c);
            if(timeEntryList == null){
                timeEntryList = new List<SVMXC__Timesheet_Entry__c>();
                workDetailIdTimeEntryListMap.put(timeEntry.SVMXC__Work_Detail__c, timeEntryList);
            }
            timeEntryList.add(timeEntry);
        }

        //Using this we want to find the proper time entry
        //Criteria is :-
        // Use if there is an Time Entry with Open/Submitted Timesheets First
        // else  use the time entry which is lastly modified (means last approved one)
        for(Id workDetailId : workDetailIdTimeEntryListMap.keySet()){
            List<SVMXC__Timesheet_Entry__c> timeEntryList = workDetailIdTimeEntryListMap.get(workDetailId);

            if(timeEntryList.size() <= 0){
                System.debug('No Time Entry found for this Work Detail ' + workDetailId);
            }else if(timeEntryList.size() == 1){
                System.debug('Single Time Entry found for this Work Detail ' + workDetailId);
                workDetailIdTimeEntryMap.put(workDetailId,timeEntryList.get(0));
            }else{
                //variable to check if any open time entry found
                boolean isTimeEntryFound = false;
                //check if there is an time entry with open status timesheet.
                for(SVMXC__Timesheet_Entry__c timeEntry : timeEntryList){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;
                    //if the timesheet is in open/submitted state
                    if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry found with Open/Submitted Timesheet for this Work Detail ' + workDetailId + 'found -' + timeEntry.Id);
                        isTimeEntryFound = true;
                        workDetailIdTimeEntryMap.put(workDetailId,timeEntry);
                        break;
                    }
                }
                //if not, get the last modified one which will be the last approved.
                if(!isTimeEntryFound){
                    
                    SVMXC__Timesheet_Entry__c timeEntryFound = timeEntryList.get(0);

                    for(Integer count = 1; count < timeEntryList.size(); count++){
                        SVMXC__Timesheet_Entry__c timeEntry = timeEntryList.get(count);
                        for(SVMXC__Timesheet_Entry__c timeEntryCompare : timeEntryList){
                            if(timeEntry.Id == timeEntryCompare.Id){
                                System.debug('This is the same one. Hence ignore');
                            }else if(timeEntryCompare.CreatedDate > timeEntryFound.CreatedDate){
                                timeEntryFound = timeEntryList.get(0);
                            }
                        }
                    }

                    System.debug('Time Entry found with Closed Timesheet for this Work Detail ' + workDetailId + 'found -' + timeEntryFound.Id);
                    workDetailIdTimeEntryMap.put(workDetailId,timeEntryFound);
                }
            }
        }

        return workDetailIdTimeEntryMap;
    }

    /*****************************************************************************************************************************************
    *  Method Name : isLaborOrTravelWD
    *  Parameter   : SVMXC__Service_Order_Line__c detail - work detail line to be used to determine if labor/travel
    *  Returns     : Boolean - true if the line is Labor/Travel else false
    *  Description : Check if the line is Travel/Labor type or not.
    *******************************************************************************************************************************************/  
    @TestVisible private Boolean isLaborOrTravelWD(SVMXC__Service_Order_Line__c detail){   
        Boolean isLaborLine = false;

        if (detail != null && detail.RecordTypeId == detailRecordTypeId 
          && (detail.SVMXC__Line_Type__c == LINE_TYPE_LABOR ||
              detail.SVMXC__Line_Type__c == LINE_TYPE_TRAVEL )){
            isLaborLine = true;
        }

        return isLaborLine;
    }

    /*****************************************************************************************************************************************
                        METHODS TO HANDLE TIME ENTRY CREATION/UPDATION/DELETION FROM SALESFORCE EVENT
    *******************************************************************************************************************************************/  

    /*****************************************************************************************************************************************
    *  Method Name : handleEventsFromSalesforceEvents
    *  Parameter   : List<Event> detailList - Events which are created (used when inserted/updated)
    *                Map<Id, Event> oldMap -  Map of old Events (used when updated)
    *                List<Event> olddetailList - old Events List (used when deleted)
    *                Boolean isInsert - Event to specify event is Insert
    *                Boolean isUpdate - Event to specify event is Update
    *                Boolean isDelete - Event to specify event is Delete
    *  Returns     : --
    *  Description : This method is called is called in After Insert of 
    *******************************************************************************************************************************************/  
    public void handleEventsFromSalesforceEvents(List<Event> eventList, 
                                            Map<Id, Event> oldMap,
                                            List<Event> oldEventList, 
                                            Boolean isInsert,
                                            Boolean isUpdate,
                                            Boolean isDelete) {
        if(!isStopFunctionality && !isStopFunctionalityForEvent){
            System.debug('Time Entry Handling : Timesheet Functionality is active for Events.  Hence Proceed further');
            if(isInsert){
                createTimeEntriesFromEvents(eventList);
            }else if(isUpdate){
                updateTimeEntriesFromEvents(eventList, oldMap);
            }else if(isDelete){
                deleteTimeEntriesFromEvents(oldEventList);
            }
        }else{
            System.debug('Time Entry Handling : Timesheet Functionality is stopped for Events. Hence do not Proceed further.');
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : createTimeEntriesFromEvents
    *  Parameter   : List<Event> eventRecList - List of Salesforce Events which are created
    *  Returns     : --
    *  Description : This method is called is called in After Insert of Salesforce Event Record
    *                This method handles the creation of time entry
    *                This follows following logic:-
    *                   When a timesheet is in Open/Submitted Status, Create a new Time Entry
    *                   When a timesheet is in Closed/Approved Status, Create an +Ve Time Entry with an Overlapping Timesheet if needed
    *******************************************************************************************************************************************/  
    @TestVisible private void createTimeEntriesFromEvents(List<Event> eventRecList) {

        System.debug('Time Entry Handling : Handle Creation Event for Salesforce Events');

        //List of Salesforce Events which are valid for creation of time entry
        List<TimesheetWrapper> validSalesforceEventWrapperList = new List<TimesheetWrapper>();

        //Find out the correct Salesforce Event
        //Events marked with Time Entry are valid
        for (Event eventRec : eventRecList) {            
           if(eventRec.StartDateTime != null 
               && eventRec.EndDateTime != null
               && eventRec.OwnerId != null 
               && eventRec.SVMX_PS_TS_Time_Entry__c){
                System.debug('Time Entry Handling : ' + eventRec.Id + 'is valid for Time Entry Creation');
                TimesheetWrapper wrapper = new TimesheetWrapper(false, eventRec);
                validSalesforceEventWrapperList.add(wrapper);
            }else{
                System.debug('Time Entry Handling : ' + eventRec.Id + ' is not valid as either Start/End Time Or Time Entry field is not marked');
            }
        }

        //if found any valid labor/travel work details, then create time entries
        if(validSalesforceEventWrapperList.size() > 0){
            System.debug('Time Entry Handling : Start creating Time Entry');
            handleTimeEventsCreationFromSalesforceEvents(validSalesforceEventWrapperList);
            System.debug('Time Entry Handling : Done with Creating Time Entry');
        }else{
            System.debug('Time Entry Handling : No Salesforce Events are valid for time entry creation');
        }
        
        System.debug('Time Entry Handling : Handled Creation Event for Salesforce Events');
    }

    /*****************************************************************************************************************************************
    *  Method Name : deleteTimeEntriesFromEvents
    *  Parameter   : List<Event> eventRecList - list of Salesforce Event which are deleted
    *  Returns     : --
    *  Description : This method is called is called in Before Delete of Salesforce Event Record
    *                This handles Salesforce Event Delete Scenario
    *                This follows following logic:-
    *                   When a timesheet is in Open Status, Delete The Time Entry associated with Work Detail
    *                   When a timesheet is in Submitted/Closed/Approved Status, Create an -Ve Time Entry with an Overlapping Timesheet if needed
    *******************************************************************************************************************************************/  
    @TestVisible private void deleteTimeEntriesFromEvents(List<Event> eventRecList){
        System.debug('Time Entry Handling : Handle Deletion Event for Salesforce Event');

        //Set of valid Salesforce Event Set to be used to query Time Entries
        Set<Id> salesforceEventIdSet = new Set<Id>();
        //Set of valid Salesforce Event that are time entries and have proper Start/End Time.
        Set<Event> validSalesforceEventSet = new Set<Event>();
        //Map of work detail Id as key and its associated Time Entry as value. 
        //This used to store the relationship between work detail & time entry
        Map<Id,SVMXC__Timesheet_Entry__c> salesforceEventIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
        //Time Entries which will be deleted
        List<SVMXC__Timesheet_Entry__c> deleteEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //List of work details which have timesheets in closed and need to create an overlapping one.
        List<TimesheetWrapper> salesforceEventForNegativeTimeCreationList = new List<TimesheetWrapper>();

        //Find out the correct Salesforce Event
        //Events marked with Time Entry are valid
        for (Event eventRec : eventRecList) {            
           if(eventRec.StartDateTime != null 
               && eventRec.EndDateTime != null
               && eventRec.OwnerId != null 
               && eventRec.SVMX_PS_TS_Time_Entry__c){
                System.debug('Time Entry Handling : ' + eventRec.Id + 'is valid for Time Entry Deletion Event');
                salesforceEventIdSet.add(eventRec.Id);
                validSalesforceEventSet.add(eventRec);
            }else{
                System.debug('Time Entry Handling : ' + eventRec.Id + ' is not valid as either Start/End Time Or Time Entry field is not marked');
            }
        }
        
        //If found any, then delete appropriate time entry. If timesheet is approved, then create appropriate -ve entry
        if (salesforceEventIdSet.size() > 0){   
            //find the relative time entries. This method ensures that appropriate time entry is choosen among all.
            salesforceEventIdTimeEntryMap = findRelativeTimeEntryForSalesforceEvents(salesforceEventIdSet);
            
            for(Event salesforceEvent : validSalesforceEventSet){
                //Get the Time Entry
                SVMXC__Timesheet_Entry__c timeEntry = salesforceEventIdTimeEntryMap.get(salesforceEvent.Id);

                if(timeEntry != null){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;
                    //If open/submitted, delete the Time Entry
                    if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry Handling : Timesheet is open/submitted. Hence just delete the entry');
                        deleteEntryList.add(timeEntry);
                    //If not open,/submitted create -ve Time Entry
                    }else{
                        System.debug('Time Entry Handling : Timesheet is closed/approved. Hence create negative entry');
                        TimesheetWrapper wrapper = new TimesheetWrapper(true,salesforceEvent);
                        salesforceEventForNegativeTimeCreationList.add(wrapper);
                    }
                }else{
                   System.debug('Time Entry Handling : No Time Entry found for Salesforce Event -' + salesforceEvent.Id  + '. Hence cannot delete time entry'); 
                }
            }

            //Handle creation of negative time entry creation.
            if(salesforceEventForNegativeTimeCreationList.size() > 0){
                System.debug('Time Entry Handling : Create Negative Time Entries for closed timesheet');
                handleTimeEventsCreationFromSalesforceEvents(salesforceEventForNegativeTimeCreationList);
                System.debug('Time Entry Handling : Completed Creation Negative Time Entries for closed timesheet');
            }

            //Handle deletion of time entries.
            if (!deleteEntryList.isEmpty()){
                System.debug('Time Entry Handling : Delete Time Entries for open timesheet');
                delete deleteEntryList;
                System.debug('Time Entry Handling : Delete Time Entries for open timesheet');
            }              
        }else{
             System.debug('Time Entry Handling : No Valid Salesforce Events for Deletion');
        }

        System.debug('Time Entry Handling : Handle Deletion Event for Salesforce Event');
    }

    /*****************************************************************************************************************************************
    *  Method Name : updateTimeEntriesFromEvents
    *  Parameter   : List<Event> eventList - List of Events with new updated data
    *                Map<Id, Event> oldEventMap - map of Events Id as key and Salesforce Event as record which refers to old state
    *  Returns     : --
    *  Description : Handles Salesforce Event Update Scenario
    *                Based on current Status of Timesheets, following logic will be applied
    *                The code will fire only if the folllowing fields are changed:-
    *                   a. StartDateTime
    *                   b. EndDateTime
    *                   c. SVMX_PS_TS_Time_Entry__c
    *                If the Event is changed, query the associated Time Entry.
    *                If No Time Entry found, create a new one
    *                If found and Timesheet is in Open/Submitted State, then follow the logic:-
    *                   If only Time is changed, update the old Time Entry
    *                   If Date is changed (within/outside of timesheet), delete the old Time Entry & create a new one
    *                If found and Timesheet is in Closed/Approved State, then follow the logic:-
    *                   If only Time is changed/Date is changed (within/outside of timesheet), create the -ve entry for old Time & + ve 
    *                   Time Entry for new Time. Also , if needed, create overlapping timesheet
    *******************************************************************************************************************************************/  
    @TestVisible private void updateTimeEntriesFromEvents(List<Event> eventList, Map<Id, Event> oldEventMap){
        //Set of valid Salesforce Event Id Set
        Set<Id> salesforceEventIdSet = new Set<Id>();
        //Set of valid Salesforce Event Id Set which are un-marked as Time Entry.
        Set<Id> unMarkedSalesforceEventIdSet = new Set<Id>();
        //Set of valid Work Details
        Set<Event> validSalesforceEventSet = new Set<Event>();
        //List of updated Time Entries which will be finally stored to db.
        List<SVMXC__Timesheet_Entry__c> updatedTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //List of all timesheet wrappers for which we need to create proper new time entries
        List<TimesheetWrapper> timesheetWrapperList = new List<TimesheetWrapper>();
        //List of time entries need to be deleted
        List<SVMXC__Timesheet_Entry__c> deletedTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //Map of work detail Id as key and its associated Time Entry as value
        Map<Id,SVMXC__Timesheet_Entry__c> salesforceEventIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
       
        //Find out the valid Salesforce Events
        for (Event eventRec : eventList) {
            System.debug('Time Entry Handling : Handle Event - ' + eventRec.Id);
            //Get Old Event
            Event oldEventRec = oldEventMap.get(eventRec.Id);

            //Check if the event is changed or not
           if(eventRec.StartDateTime != null && 
               eventRec.EndDateTime != null &&
               eventRec.SVMX_PS_TS_Time_Entry__c != oldEventRec.SVMX_PS_TS_Time_Entry__c){
                if(eventRec.SVMX_PS_TS_Time_Entry__c){
                    System.debug('Time Entry Handling : Event is newly Marked as Time Entry');
                    salesforceEventIdSet.add(eventRec.Id);
                    validSalesforceEventSet.add(eventRec);
                }else{
                    System.debug('Time Entry Handling : Event is  UnMarked as Time Entry');
                    unMarkedSalesforceEventIdSet.add(eventRec.Id);
                    salesforceEventIdSet.add(eventRec.Id);
                    validSalesforceEventSet.add(eventRec);
                }
            }
            else if(eventRec.StartDateTime != null 
                    && eventRec.EndDateTime != null 
                    && eventRec.SVMX_PS_TS_Time_Entry__c
                    && (oldEventRec.StartDateTime != eventRec.StartDateTime
                        || oldEventRec.EndDateTime != eventRec.EndDateTime
                        || oldEventRec.Subject != eventRec.Subject)){
                System.debug('Time Entry Handling : Event has either Start/End Time or Subject is changed');
                salesforceEventIdSet.add(eventRec.Id);
                validSalesforceEventSet.add(eventRec);
            }else{
                System.debug('Time Entry Handling : Event is not valid for Time Entry');
            }
        }
        
        if (validSalesforceEventSet.size() > 0) { 
            //find the relative time entries. This method ensures that appropriate time entry is choosen among all.
            salesforceEventIdTimeEntryMap = findRelativeTimeEntryForSalesforceEvents(salesforceEventIdSet);

            for(Event salesforceEvent : validSalesforceEventSet){

                System.debug('Time Entry Handling : Handle update for ' + salesforceEvent.Id);

                SVMXC__Timesheet_Entry__c timeEntry = salesforceEventIdTimeEntryMap.get(salesforceEvent.Id);

                if(timeEntry != null){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;

                    //get the start date of the time entry
                    //Generally Start Date and End Date of the Salesforce Event will be same.
                    //Hence just check Start Date.
                    Date salesforceEventStartDate = salesforceEvent.StartDateTime.date();

                    //This means the Event is unmarked as Salesforce Evewnt
                    if(unMarkedSalesforceEventIdSet.contains(salesforceEvent.Id)){
                        System.debug('Time Entry Handling : Timesheet is Un-Marked as Time Entry.');
                        //if the timesheet is in open/submitted state
                        if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                            System.debug('Time Entry Handling : Timesheet is Open/Submitted. Hence Delete Entry');
                            //As timesheet is open/submited, just delete the entry
                            deletedTimeEntryList.add(timeEntry);
                        }else{
                            System.debug('Time Entry Handling : Timesheet is Closed/Approved. Hence Create Overlapping Time Entry');
                            //Timesheet is closed/approved. Hence create -ve Time Entry
                            //find the old Event
                            Event oldEvent = oldEventMap.get(salesforceEvent.Id);
                            //Create a negative Time Entry for old data
                            TimesheetWrapper negativeEntryWrapper = new TimesheetWrapper(true, oldEvent);
                            timesheetWrapperList.add(negativeEntryWrapper);
                        }
                    }
                    //if the timesheet is in open/submitted state
                    else if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry Handling : Timesheet is open/submitted. Hence handle update');
                        
                        //check if only time is changed, just update the time. No changes to daily Summary and timesheet
                        if(salesforceEventStartDate == timeEntry.SVMXC__Start_Time__c.date()){
                            System.debug('Time Entry Handling : Only Time is changed. Hence no changes to Daily Summary or Timesheet');

                            timeEntry.SVMXC__Salesforce_Event__c = salesforceEvent.id;
                            timeEntry.SVMXC__Activity__c = salesforceEvent.Type;
                            timeEntry.SVMXC__Start_Time__c = salesforceEvent.StartDateTime;
                            timeEntry.SVMXC__End_Time__c = salesforceEvent.EndDateTime;
                            timeEntry.SVMXC__Comments__c = salesforceEvent.Subject;
                            timeEntry.SVMXC__Duration__c = ((Decimal) (timeEntry.SVMXC__End_Time__c.getTime() - timeEntry.SVMXC__Start_Time__c.getTime()) / 3600000.0).setScale(2);
                            timeEntry.SVMX_PS_TS_Time_Entry_Start_Date__c = salesforceEvent.StartDateTime.date();
                            timeEntry.SVMX_PS_TS_Time_Entry_End_Date__c = salesforceEvent.EndDateTime.date();

                            updatedTimeEntryList.add(timeEntry);
                        }else{
                            //Check if the time is moved within the timesheet. If yes, then update daily Summary only.
                            if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c <= salesforceEventStartDate &&
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c >= salesforceEventStartDate){
                                System.debug('Time Entry Handling : Date is moved within Timesheet. Hence changes Daily Summary');
                            //Check if the time is moved outside the timesheet. If yes, then update daily Summary and timesheet
                            }else if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c >= salesforceEventStartDate ||
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c <= salesforceEventStartDate){
                                System.debug('Time Entry Handling : Date is moved outside Timesheet. Hence changes Daily Summary & Timesheet');
                            }

                            //Create a postive Time Entry for new data.
                            TimesheetWrapper wrapper = new TimesheetWrapper(false, salesforceEvent);
                            timesheetWrapperList.add(wrapper);
                            //delete the old Time Entry
                            deletedTimeEntryList.add(timeEntry);
                        }
                    //if the timesheet is in approved/closed state
                    }else{
                        System.debug('Time Entry Handling : Timesheet is closed/approved. Hence handle overlapping');

                        //check if only time is changed, just update the time. No changes to daily Summary and timesheet
                        if(salesforceEventStartDate == timeEntry.SVMXC__Start_Time__c.date()){
                            System.debug('Time Entry Handling : Only Time is changed. Hence no changes to Daily Summary or Timesheet.' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                        }else{
                            //Check if the time is moved within the timesheet. If yes, then update daily Summary only.
                            if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c <= salesforceEventStartDate &&
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c >= salesforceEventStartDate){
                                System.debug('Time Entry Handling : Date is moved within Timesheet. Hence changes Daily Summary' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                            //Check if the time is moved outside the timesheet. If yes, then update daily Summary and timesheet
                            }else if(timeEntry.SVMXC__Timesheet__r.SVMXC__Start_Date__c >= salesforceEventStartDate ||
                                timeEntry.SVMXC__Timesheet__r.SVMXC__End_Date__c <= salesforceEventStartDate){
                                System.debug('Time Entry Handling : Date is moved outside Timesheet. Hence changes Daily Summary & Timesheet' +
                                    'But as timesheet is closed/approved, create negative & postive entry');
                            }
                        }

                        //Create a postive Time Entry for new data.
                        TimesheetWrapper wrapper = new TimesheetWrapper(false, salesforceEvent);
                        timesheetWrapperList.add(wrapper);

                        //find the old Event
                        Event oldEvent = oldEventMap.get(salesforceEvent.Id);
                        //Create a negative Time Entry for old data
                        TimesheetWrapper negativeEntryWrapper = new TimesheetWrapper(true, oldEvent);
                        timesheetWrapperList.add(negativeEntryWrapper);
                    }
                }else{
                    if(unMarkedSalesforceEventIdSet.contains(salesforceEvent.Id)){
                        System.debug('Time Entry Handling : Timesheet is Un-Marked as Time Entry. Hence do not create a new time entry');
                    }else{
                        System.debug('Time Entry Handling : No Time Entry found for Time Entry -' + salesforceEvent.Id  + '. Hence create a new time entry'); 
                        //Create a postive Time Entry for new data.
                        TimesheetWrapper wrapper = new TimesheetWrapper(false, salesforceEvent);
                        timesheetWrapperList.add(wrapper);
                    }
                }
            }

            if (!updatedTimeEntryList.isEmpty()){
                System.debug('Time Entry Handling : Update Time Entries directly which are in Open/Submitted Timesheet');
                update updatedTimeEntryList;
                System.debug('Time Entry Handling : Update Done for Time Entries directly which are in Open/Submitted Timesheet');
            }

            if(!deletedTimeEntryList.isEmpty()){
                System.debug('Time Entry Handling : Delete Time Entries which are in Open/Submitted Timesheet');
                delete deletedTimeEntryList;
                System.debug('Time Entry Handling : Delete done for Time Entries which are in Open/Submitted Timesheet');
            } 

            if(!timesheetWrapperList.isEmpty()){
                System.debug('Time Entry Handling : Handle Creation of Overlapping Time Entries');
                handleTimeEventsCreationFromSalesforceEvents(timesheetWrapperList);
                System.debug('Time Entry Handling : Creation of Overlapping Time Entries done');
            }             
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : handleTimeEventsCreationFromSalesforceEvents
    *  Parameter   : List<TimesheetWrapper> validSalesforceEventWrapperList - list of valid Salesforce Events
    *  Returns     : --
    *  Description : This method handles the creation of time entry
    *                Based on current status of timesheet, it will create a new entry.
    *                If needed, it will create a new overlapping timesheet.
    *                Also, based on the flag in wrapper, it will create +ve or -ve Time Entry.
    *******************************************************************************************************************************************/  
    @TestVisible private void handleTimeEventsCreationFromSalesforceEvents(List<TimesheetWrapper> validSalesforceEventWrapperList) {
        //List of Time Entries newly created
        List<SVMXC__Timesheet_Entry__c> createdTimeEntryList = new List<SVMXC__Timesheet_Entry__c>();
        //Set of Salesforce Users Id Set to be used to query the Business Hours and Timesheets
        Set<Id> salesforceUserIdSet = new Set<Id>();
        //Set of Dates to query the Timesheets
        Set<Date> timesheetDateSet = new Set<Date>();
        //Set of Salesforce User Ids to query the Timesheets
        Set<Id> timesheetSalesforceUserSet = new Set<Id>();
        //Map of Salesforce Event Id as key and associated Salesforce User Id as Value
        Map<Id,Id> eventIdSalesforceUserIdMap = new Map<Id,Id>();
        //Map to indicate the Salesforce User Id as Key and Techncian Record which includes its Business Hours as Value
        Map<Id, SVMXC__Service_Group_Members__c> technicianIdTechnicianMap = new  Map<Id, SVMXC__Service_Group_Members__c> ();
        //Map to store Technician Id as Key and all associated Daily Summaries
        Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>> techTimesheetDayMap = new Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>>();
        //Map to store Technician Id as Key and all associated Daily Summaries
        Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>> closedTechTimesheetDayMap = new Map<Id,Map<Date, SVMXC__Timesheet_Day_Entry__c>>();
        //Map with Key created from combination of Salesforce User Id to which the Daily Summary belongs and Date of Daily Summary 
        //and Value is the Daily Summary Record itself
        Map<String, SVMXC__Timesheet_Day_Entry__c> dailyEntryMap = new Map<String, SVMXC__Timesheet_Day_Entry__c>();
        //Map of Salesforce User Id as key and Business Hours as value
        Map<Id,BusinessHours> sfIdBusinessHrsMap = new  Map<Id,BusinessHours>();
        //Map to store unique id created from using Salesforce User Id to which Timesheet belongs, Start Date of Timesheet and End Date
        //of Timesheet as Key and Newly Created Timesheet as Value
        Map<String,SVMXC__Timesheet__c> timesheetMap = new Map<String,SVMXC__Timesheet__c>();
        
        
        if(validSalesforceEventWrapperList.size() > 0){
            //Get all Technicians 
            for (TimesheetWrapper wrapper : validSalesforceEventWrapperList) {
                Event salesforceEvent = wrapper.getSalesforceEvent();      
                salesforceUserIdSet.add(salesforceEvent.OwnerId);
            }

            //If found then query all the Techncians Record.
            for(SVMXC__Service_Group_Members__c technicianRecord :
                                                [SELECT Id, SVMXC__Salesforce_User__c, SVMXC__Working_Hours__c, SVMXC__Working_Hours__r.MondayEndTime, 
                                                        SVMXC__Working_Hours__r.MondayStartTime, SVMXC__Working_Hours__r.TuesdayEndTime,
                                                        SVMXC__Working_Hours__r.TuesdayStartTime, SVMXC__Working_Hours__r.WednesdayEndTime,
                                                        SVMXC__Working_Hours__r.WednesdayStartTime, SVMXC__Working_Hours__r.ThursdayEndTime,
                                                        SVMXC__Working_Hours__r.ThursdayStartTime, SVMXC__Working_Hours__r.FridayEndTime,
                                                        SVMXC__Working_Hours__r.FridayStartTime, SVMXC__Working_Hours__r.SaturdayEndTime,
                                                        SVMXC__Working_Hours__r.SaturdayStartTime, SVMXC__Working_Hours__r.SundayEndTime,
                                                        SVMXC__Working_Hours__r.SundayStartTime
                                                    FROM SVMXC__Service_Group_Members__c
                                                    WHERE SVMXC__Salesforce_User__c IN :salesforceUserIdSet]){

               //Create the map of Business Hours Record which will be used to while creating daily summaries
               if(technicianRecord.SVMXC__Working_Hours__c != null && technicianRecord.SVMXC__Salesforce_User__c != null){
                    BusinessHours businessHours = new BusinessHours();
                    businessHours.MondayStartTime = technicianRecord.SVMXC__Working_Hours__r.MondayStartTime;
                    businessHours.MondayEndTime = technicianRecord.SVMXC__Working_Hours__r.MondayEndTime;
                    businessHours.TuesdayEndTime = technicianRecord.SVMXC__Working_Hours__r.TuesdayStartTime;
                    businessHours.TuesdayStartTime = technicianRecord.SVMXC__Working_Hours__r.TuesdayEndTime;
                    businessHours.WednesdayEndTime = technicianRecord.SVMXC__Working_Hours__r.WednesdayEndTime;
                    businessHours.WednesdayStartTime = technicianRecord.SVMXC__Working_Hours__r.WednesdayStartTime;
                    businessHours.ThursdayEndTime = technicianRecord.SVMXC__Working_Hours__r.ThursdayEndTime;
                    businessHours.ThursdayStartTime = technicianRecord.SVMXC__Working_Hours__r.ThursdayStartTime;
                    businessHours.FridayEndTime = technicianRecord.SVMXC__Working_Hours__r.FridayEndTime;
                    businessHours.FridayStartTime = technicianRecord.SVMXC__Working_Hours__r.FridayStartTime;
                    businessHours.SaturdayEndTime = technicianRecord.SVMXC__Working_Hours__r.SaturdayEndTime;
                    businessHours.SaturdayStartTime = technicianRecord.SVMXC__Working_Hours__r.SaturdayStartTime;
                    businessHours.SundayEndTime = technicianRecord.SVMXC__Working_Hours__r.SundayEndTime; 
                    businessHours.SundayStartTime = technicianRecord.SVMXC__Working_Hours__r.SundayStartTime;

                    sfIdBusinessHrsMap.put(technicianRecord.SVMXC__Salesforce_User__c, businessHours);
               }

                if(technicianRecord.SVMXC__Salesforce_User__c != null){
                    technicianIdTechnicianMap.put(technicianRecord.SVMXC__Salesforce_User__c,technicianRecord);
                }
            }

            //Now create Time Entries for each valid work details
            for (TimesheetWrapper wrapper : validSalesforceEventWrapperList) {
                //Get the salesforce event from wrapper
                 Event salesforceEvent = wrapper.getSalesforceEvent(); 

                //Check if Salesforce User and Technician are linked or not. If not, we cannot proceed further.
                if(technicianIdTechnicianMap.get(salesforceEvent.OwnerId) != null){
                    //Create a new Time Entry
                    SVMXC__Timesheet_Entry__c timeEntry = new SVMXC__Timesheet_Entry__c();
                    timeEntry.SVMXC__Salesforce_Event__c = salesforceEvent.id;
                    timeEntry.SVMXC__Activity__c = salesforceEvent.Type;
                    timeEntry.SVMXC__Start_Time__c = salesforceEvent.StartDateTime;
                    timeEntry.SVMXC__End_Time__c = salesforceEvent.EndDateTime;
                    timeEntry.SVMXC__Comments__c = salesforceEvent.Subject;
                    timeEntry.SVMXC__Duration__c = ((Decimal) (timeEntry.SVMXC__End_Time__c.getTime() - timeEntry.SVMXC__Start_Time__c.getTime()) / 3600000.0).setScale(2);
                    timeEntry.SVMX_PS_TS_Time_Entry_Start_Date__c = salesforceEvent.StartDateTime.date();
                    timeEntry.SVMX_PS_TS_Time_Entry_End_Date__c = salesforceEvent.EndDateTime.date();

                    //The flag "SVMX_Is_Negative_Time_Entry__c" will make the duration as negative.
                    if(wrapper.getIsNegativeTimeEntry()){
                        timeEntry.SVMXC__Duration__c = timeEntry.SVMXC__Duration__c * -1.0;
                    }

                    //Store the time entry for insertion.
                    createdTimeEntryList.add(timeEntry);
                    //Store the associated Salesforce User Id with Salesforce Event. This will be used for finding proper time sheet.
                    eventIdSalesforceUserIdMap.put(salesforceEvent.Id,salesforceEvent.OwnerId);
                    //Add the start time to query timesheet daily summary associated with that period
                    timesheetDateSet.add(timeEntry.SVMXC__Start_Time__c.date());
                    //Add Salesforce User to query timesheet daily summary associated
                    timesheetSalesforceUserSet.add(salesforceEvent.OwnerId);
                }else{
                    System.debug('Time Entry Handling : ' + salesforceEvent.Id + ' does have a proper owner - ' + salesforceEvent.OwnerId);
                }
            }

            //Now query all daily summaries for all the time entries which we want to create.
            for (SVMXC__Timesheet_Day_Entry__c dailySummary : [SELECT Id, SVMXC__Timesheet__c, SVMXC__Timsheet_Day__c, SVMXC__Timesheet__r.SVMXC__User__c,
                                                                            SVMXC__Timesheet__r.SVMXC__Status__c 
                                                                FROM SVMXC__Timesheet_Day_Entry__c 
                                                                WHERE SVMXC__Timsheet_Day__c IN :timesheetDateSet AND 
                                                                      SVMXC__Timesheet__r.SVMXC__User__c IN :timesheetSalesforceUserSet]){
                
                Map<Date, SVMXC__Timesheet_Day_Entry__c> dayMap = null;

                //Get the status
                String status = dailySummary.SVMXC__Timesheet__r.SVMXC__Status__c;
                //if the timesheet is in Open/Submitted state
                if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                    //This daily summary belongs to open/submitted timesheets.
                    if(techTimesheetDayMap.containsKey(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c)){
                        dayMap = techTimesheetDayMap.get(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c);
                    }else{
                        dayMap = new Map<Date, SVMXC__Timesheet_Day_Entry__c>();
                        techTimesheetDayMap.put(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c,dayMap);
                    }
                    dayMap.put(dailySummary.SVMXC__Timsheet_Day__c, dailySummary);
                }else{
                    //This daily summary belongs to either closed/approved timesheets.
                    //This will help in creating overlapping timesheet
                    if(closedTechTimesheetDayMap.containsKey(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c)){
                        dayMap = closedTechTimesheetDayMap.get(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c);
                    }else{
                        dayMap = new Map<Date, SVMXC__Timesheet_Day_Entry__c>();
                        closedTechTimesheetDayMap.put(dailySummary.SVMXC__Timesheet__r.SVMXC__User__c,dayMap);
                    }
                    dayMap.put(dailySummary.SVMXC__Timsheet_Day__c, dailySummary);
                }
            }

            //Now, here we are trying to associate the time entries with apporpriate daily summary and timesheet.
            for (SVMXC__Timesheet_Entry__c timeEntry : createdTimeEntryList) {
                
                //check if the timesheet exists in open state.
                if (eventIdSalesforceUserIdMap.containsKey(timeEntry.SVMXC__Salesforce_Event__c) 
                    && techTimesheetDayMap.containsKey(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c)) 
                    && (techTimesheetDayMap.get(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))).containsKey(timeEntry.SVMXC__Start_Time__c.date())) {
                        //here check if timesheet is found in open status
                        //Associate it with time entry.
                        SVMXC__Timesheet_Day_Entry__c dailySummary = (techTimesheetDayMap.get(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))).get(timeEntry.SVMXC__Start_Time__c.date());
                        timeEntry.SVMXC__Timesheet__c = dailySummary.SVMXC__Timesheet__c;
                        timeEntry.SVMXC__Timesheet_Day__c = dailySummary.Id;
                }else{
                    //
                    String key = null;
                    
                    //This is to make sure if we are creating timesheets on sunday
                    //which will be the nextStartOfweek, the time entries should go on
                    //last week timesheets and not this one
                    //String dayOfWeek = timeEntry.SVMXC__Start_Time__c.format('EEE');
                    //if(dayOfWeek.equals('Sun')){
                    //    DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
                    //    key =   String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))  
                    //                + previousDay.date().toStartOfWeek().addDays(1)
                    //                + previousDay.date().toStartOfWeek().addDays(7);
                    //}else{
                    //    key = String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                    //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(1)
                    //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(7);
                    //}
                    Integer dayOfWeek = getDayOfWeek(timeEntry.SVMXC__Start_Time__c.date());
                    if(dayOfWeek == 0){
                        DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
                        key =   String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                                    + toStartOfWeek(previousDay.date()).addDays(1)
                                    + toStartOfWeek(previousDay.date()).addDays(7);
                    }else{
                        key = String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                                    + toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(1)
                                    + toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(7);
                    }
                    
                    //This check is to not create duplicate timesheets for same period.
                    if (!timesheetMap.containsKey(key)) {

                        boolean isOverlapFound = false; 

                        if (eventIdSalesforceUserIdMap.containsKey(timeEntry.SVMXC__Salesforce_Event__c) 
                            && closedTechTimesheetDayMap.containsKey(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c)) 
                            && (closedTechTimesheetDayMap.get(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))).containsKey(timeEntry.SVMXC__Start_Time__c.date())) {
                            isOverlapFound = true;
                        }

                        SVMXC__Service_Group_Members__c technician = technicianIdTechnicianMap.get(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c));
                        SVMXC__Timesheet__c newTimesheet = createNewTimeSheet(timeEntry, technician.SVMXC__Salesforce_User__c, technician.SVMXC__Working_Hours__c, isOverlapFound);
                        timesheetMap.put(key, newTimesheet);
                    }
                }
            }
                
            //If needed to create the timesheet, then create timesheet and daily summary.
            if (!timesheetMap.isEmpty()) {
                //insert Timesheets
                insert timesheetMap.values();
                //create daily summaries
                dailyEntryMap = createTimeSheetDailySummary(timesheetMap.values(),sfIdBusinessHrsMap);
                //insert daily summary
                insert dailyEntryMap.values();
            }
            
            //Associate Time Entries with the Timesheets
            for (SVMXC__Timesheet_Entry__c timeEntry : createdTimeEntryList) {
                if (timeEntry.SVMXC__Timesheet_Day__c == null || timeEntry.SVMXC__Timesheet__c == null) {
                    SVMXC__Timesheet_Day_Entry__c dayEntry = dailyEntryMap.get(String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                                                                                 + timeEntry.SVMXC__Start_Time__c.date());
                    if(dayEntry != null){
                        timeEntry.SVMXC__Timesheet_Day__c = dayEntry.Id;
                        timeEntry.SVMX_PS_TS_Timesheet_Daily_Summary_Date__c = dayEntry.SVMXC__Timsheet_Day__c;

                        //This is to make sure if we are creating timesheets on sunday
                        //which will be the nextStartOfweek, the time entries should go on
                        //last week timesheets and not this one
                        //String key = String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c)) 
                        //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(1)
                        //                + timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(7);
                        //String dayOfWeek = timeEntry.SVMXC__Start_Time__c.format('EEE');
                        //if(dayOfWeek.equals('Sun')){
                        //    DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);

                        //    key =   String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c)) 
                        //                + previousDay.date().toStartOfWeek().addDays(1)
                        //                + previousDay.date().toStartOfWeek().addDays(7);
                        //}
                        String key = String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                                        +toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(1)
                                        +toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(7);
                        Integer dayOfWeek = getDayOfWeek(timeEntry.SVMXC__Start_Time__c.date());
                        if(dayOfWeek == 0){
                            DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);

                            key =   String.valueOf(eventIdSalesforceUserIdMap.get(timeEntry.SVMXC__Salesforce_Event__c))
                                        + toStartOfWeek(previousDay.date()).addDays(1)
                                        + toStartOfWeek(previousDay.date()).addDays(7);
                        }
                                                        
                        timeEntry.SVMXC__Timesheet__c = timesheetMap.get(key).Id; 
                    }    
                }
            }
            
            if (! createdTimeEntryList.isEmpty()) {
                insert createdTimeEntryList;
            }
        }else{
            System.debug('Time Entry Handling : No Valid Salesforce Event found for creation of time entry');
        }
    }

    /*****************************************************************************************************************************************
    *  Method Name : findRelativeTimeEntryForSalesforceEvents
    *  Parameter   : Set<Id> salesforceEventIdSet - Set of Salesforce Event Ids against which we want to find time entry
    *  Returns     : Map<Id,SVMXC__Timesheet_Entry__c> - Map of Salesforce Event Id as key and associated Time Entry as Value
    *  Description : This method is finds the appropriate Time Entry for the Salesforce Event
    *                Following Logic is applied to make sure that Time Entry is appropriate:-
    *                   a.  Use Time Entry with Open/Submitted Timesheets First
    *                   b.  If not found, Use Time entry which is Created Latest (means last approved one)
    *******************************************************************************************************************************************/
    @TestVisible private Map<Id,SVMXC__Timesheet_Entry__c> findRelativeTimeEntryForSalesforceEvents(Set<Id> salesforceEventIdSet){
        //Map of Salesforce Event Id as key and its associated Time Entry as value
        Map<Id,SVMXC__Timesheet_Entry__c> salesforceEventIdTimeEntryMap = new Map<Id,SVMXC__Timesheet_Entry__c>();
        //Map of Salesforce Event Id as key and its associated Time Entry all time entries with postive duration
        Map<Id,List<SVMXC__Timesheet_Entry__c>> salesforceEventIdTimeEntryListMap = new Map<Id,List<SVMXC__Timesheet_Entry__c>>();

        //populate map
        for (SVMXC__Timesheet_Entry__c timeEntry : [SELECT Id, SVMXC__Salesforce_Event__c, SVMXC__Activity__c, 
                                                                SVMXC__Start_Time__c, SVMXC__End_Time__c, SVMXC__Comments__c,
                                                                SVMXC__Duration__c, SVMXC__Timesheet__r.SVMXC__Status__c, 
                                                                SVMXC__Timesheet__r.SVMXC__End_Date__c, 
                                                                SVMXC__Timesheet__r.SVMXC__Start_Date__c,
                                                                SVMXC__Timesheet__r.SVMXC__User__c, CreatedDate 
                                                            FROM SVMXC__Timesheet_Entry__c 
                                                            WHERE SVMXC__Salesforce_Event__c IN :salesforceEventIdSet 
                                                                AND SVMXC__Duration__c > 0]){
            List<SVMXC__Timesheet_Entry__c> timeEntryList = salesforceEventIdTimeEntryListMap.get(timeEntry.SVMXC__Salesforce_Event__c);
            if(timeEntryList == null){
                timeEntryList = new List<SVMXC__Timesheet_Entry__c>();
                salesforceEventIdTimeEntryListMap.put(timeEntry.SVMXC__Salesforce_Event__c, timeEntryList);
            }
            timeEntryList.add(timeEntry);
        }

        //Using this we want to find the proper time entry
        //Criteria is :-
        // Use if there is an Time Entry with Open/Submitted Timesheets First
        // else  use the time entry which is lastly modified (means last approved one)
        for(Id salesforceEventId : salesforceEventIdTimeEntryListMap.keySet()){
            List<SVMXC__Timesheet_Entry__c> timeEntryList = salesforceEventIdTimeEntryListMap.get(salesforceEventId);

            if(timeEntryList.size() <= 0){
                System.debug('No Time Entry found for this Work Detail ' + salesforceEventId);
            }else if(timeEntryList.size() == 1){
                System.debug('Single Time Entry found for this Work Detail ' + salesforceEventId);
                salesforceEventIdTimeEntryMap.put(salesforceEventId,timeEntryList.get(0));
            }else{
                //variable to check if any open time entry found
                boolean isTimeEntryFound = false;
                //check if there is an time entry with open status timesheet.
                for(SVMXC__Timesheet_Entry__c timeEntry : timeEntryList){
                    //Get the status
                    String status = timeEntry.SVMXC__Timesheet__r.SVMXC__Status__c;
                    //if the timesheet is in open/submitted state
                    if(status == LINE_STATUS_OPEN || status == LINE_STATUS_SUBMITTED){
                        System.debug('Time Entry found with Open/Submitted Timesheet for this Work Detail ' + salesforceEventId + 'found -' + timeEntry.Id);
                        isTimeEntryFound = true;
                        salesforceEventIdTimeEntryMap.put(salesforceEventId,timeEntry);
                        break;
                    }
                }
                //if not, get the last modified one which will be the last approved.
                if(!isTimeEntryFound){
                    
                    SVMXC__Timesheet_Entry__c timeEntryFound = timeEntryList.get(0);

                    for(Integer count = 1; count < timeEntryList.size(); count++){
                        SVMXC__Timesheet_Entry__c timeEntry = timeEntryList.get(count);
                        for(SVMXC__Timesheet_Entry__c timeEntryCompare : timeEntryList){
                            if(timeEntry.Id == timeEntryCompare.Id){
                                System.debug('This is the same one. Hence ignore');
                            }else if(timeEntryCompare.CreatedDate > timeEntryFound.CreatedDate){
                                timeEntryFound = timeEntryList.get(0);
                            }
                        }
                    }

                    System.debug('Time Entry found with Closed Timesheet for this Work Detail ' + salesforceEventId + 'found -' + timeEntryFound.Id);
                    salesforceEventIdTimeEntryMap.put(salesforceEventId,timeEntryFound);
                }
            }
        }

        return salesforceEventIdTimeEntryMap;
    }

    /*****************************************************************************************************************************************
                                    UTILITY METHODS FOR BOTH WORK DETAIL AND SALESFORCE EVENT
    *******************************************************************************************************************************************/  

    /*****************************************************************************************************************************************
    *  Method Name : createNewTimeSheet
    *  Parameter   : SVMXC__Timesheet_Entry__c timeEntry - Time Entry for which we need to create a new Timesheet
    *                Id timesheetOwnerId - Salesforce User Id who will be the owner and user of timesheet (Basically Technician)
    *                Id businessHoursId - Business Hours Id asssciated with Technician (used to populate timesheet working hours for SPM)
    *                Boolean isOverlappingTimesheet - Flag to indicate that this timesheet is an overlapping timesheet.
    *  Returns     : SVMXC__Timesheet__c - newly created timesheet records. 
    *  Description : This method is creates a new time sheet based on parameters given.
    *                If the businessHoursId is null, it uses the default company wide business hours.
    *                This method does not performa any DML operation.
    *******************************************************************************************************************************************/  
    @TestVisible private SVMXC__Timesheet__c createNewTimeSheet(SVMXC__Timesheet_Entry__c timeEntry, Id timesheetOwnerId, Id businessHoursId, Boolean isOverlappingTimesheet){

        SVMXC__Timesheet__c newTimesheet = new SVMXC__Timesheet__c();
        newTimesheet.SVMXC__User__c = timesheetOwnerId;
        newTimesheet.SVMXC__Period__c = 'Weekly';
        newTimesheet.SVMXC__Status__c = 'Open';
        newTimesheet.OwnerId = timesheetOwnerId;

        if(businessHoursId != null){
            newTimesheet.SVMXC__SM_Business_Hours__c = businessHoursId;
        }else{
            newTimesheet.SVMXC__SM_Business_Hours__c = businessHoursId;
        }

        if(isOverlappingTimesheet){
            newTimesheet.SVMX_PS_TS_Is_Overlapping_Timesheet__c = true;
        }

        //String dayOfWeek = timeEntry.SVMXC__Start_Time__c.format('EEE');
        //newTimesheet.SVMXC__Start_Date__c = timeEntry.SVMXC__Start_Time__c.date().toStartOfWeek().addDays(1);
        //if(dayOfWeek.equals('Sun')){
        //    DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
        //    newTimesheet.SVMXC__Start_Date__c = previousDay.date().toStartOfWeek().addDays(1);
        //}
        newTimesheet.SVMXC__Start_Date__c = toStartOfWeek(timeEntry.SVMXC__Start_Time__c.date()).addDays(1);
        Integer dayOfWeek = getDayOfWeek(timeEntry.SVMXC__Start_Time__c.date());
        if(dayOfWeek == 0){
            DateTime previousDay = timeEntry.SVMXC__Start_Time__c.date().addDays(-1);
            newTimesheet.SVMXC__Start_Date__c = toStartOfWeek(previousDay.date()).addDays(1);
        }
        newTimesheet.SVMXC__End_Date__c = newTimesheet.SVMXC__Start_Date__c.addDays(6);
    
        return newTimesheet;
    }

    /*****************************************************************************************************************************************
    *  Method Name : createTimeSheetDailySummary
    *  Parameter   : List<SVMXC__Timesheet__c> timesheetList - List of newly created Timesheets
    *                Map<Id, BusinessHours> sfIdBusinessHrsMap - Map with Salesforce User Id as key and Related Business Hours are value
    *  Returns     : Map<String, SVMXC__Timesheet_Day_Entry__c> - Key is the combination of Salesforce User Id to which the Daily Summary 
    *                                                               belongs and Date of Dialy Summary and Value is the Daily Summary Record 
    *                                                               itself
    *  Description : This method is creates a daily summaries for all days for newly created timesheets.
    *                If the businessHours associated with Tech are null, it uses the default company wide business hours.
    *                This method does not performa any DML operation.
    *******************************************************************************************************************************************/  
    @TestVisible private Map<String, SVMXC__Timesheet_Day_Entry__c> createTimeSheetDailySummary(List<SVMXC__Timesheet__c> timesheetList, 
                                                                                        Map<Id, BusinessHours> sfIdBusinessHrsMap){
        
        Map<String, SVMXC__Timesheet_Day_Entry__c> dailyEntryMap = new Map<String, SVMXC__Timesheet_Day_Entry__c>();

        for (SVMXC__Timesheet__c timesheet : timesheetList) {

            BusinessHours businessHoursRec = sfIdBusinessHrsMap.get(timesheet.SVMXC__User__c);
            Map<String, Double> businessHoursDurationMap = getDurationForEachDay(businessHoursRec);

            Date dateValue = timesheet.SVMXC__Start_Date__c;

            while (dateValue <= timesheet.SVMXC__End_Date__c) {
                
                Time timeInstance = Time.newInstance(0,0,0,0);
                DateTime dateTimeInstance = Datetime.newInstance(dateValue, timeInstance);
                String dayOfWeek = dateTimeInstance.format('EEE');
                Double duration = 0;
                
                if(dayOfWeek.equals('Mon')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Mon');
                    }else{
                        duration = defaultMondayDuration;
                    }
                }else if(dayOfWeek.equals('Tue')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Tue');
                    }else{
                        duration = defaultTuesdayDuration;
                    }
                }else if(dayOfWeek.equals('Wed')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Wed');
                    }else{
                        duration = defaultWednesdayDuration;
                    }
                }else if(dayOfWeek.equals('Thu')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Thu');
                    }else{
                        duration = defaultThursdayDuration;
                    }
                }else if(dayOfWeek.equals('Fri')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Fri');
                    }else{
                        duration = defaultFridayDuration;
                    }
                }else if(dayOfWeek.equals('Sat')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Sat');
                    }else{
                        duration = defaultSaturdayDuration;
                    }
                }else if(dayOfWeek.equals('Sun')){
                    if(businessHoursRec != null){
                        duration = businessHoursDurationMap.get('Sun');
                    }else{
                        duration = defaultSundayDuration;
                    }
                }

                SVMXC__Timesheet_Day_Entry__c dailySummary = new SVMXC__Timesheet_Day_Entry__c();
                dailySummary.SVMXC__Timesheet__c = timesheet.Id;
                dailySummary.SVMXC__Timsheet_Day__c = dateValue;
                dailySummary.SVMXC__SM_Working_Minutes__c = duration;

                dailyEntryMap.put(String.valueOf(timesheet.SVMXC__User__c) + dateValue, dailySummary);

                dateValue = dateValue.addDays(1);
            }
        }

        return dailyEntryMap;
    }

    /*****************************************************************************************************************************************
    *  Method Name : getDurationForEachDay
    *  Parameter   : BusinessHours timesheetBusinessHours - business hours for which durations for each day need to be calculated.
    *  Returns     : Map<String,Long> - Map where Day Identifier String is key and duration of the day in hours.
    *  Description : Calculates the duration of hours for each day for given Business Hours.
    *******************************************************************************************************************************************/  
    @TestVisible private Map<String,Long> getDurationForEachDay(BusinessHours timesheetBusinessHours){

        Long mondayDuration = 0;
        Long tuesdayDuration = 0;
        Long wednesdayDuration = 0;
        Long thursdayDuration = 0;
        Long fridayDuration = 0;
        Long saturdayDuration = 0;
        Long sundayDuration = 0;

        if(timesheetBusinessHours != null){
            if(timesheetBusinessHours.MondayEndTime != null && timesheetBusinessHours.MondayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.MondayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.MondayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    mondayDuration = 1440;
                }else{
                    Long mondayEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.MondayEndTime).getTime();
                    Long mondayStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.MondayStartTime).getTime();
                    mondayDuration = (mondayEndTime - mondayStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.TuesdayEndTime != null && timesheetBusinessHours.TuesdayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.TuesdayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.TuesdayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    tuesdayDuration = 1440;
                }else{
                    Long tuesdayEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.TuesdayEndTime).getTime();
                    Long tuesdayStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.TuesdayStartTime).getTime();
                    tuesdayDuration = (tuesdayEndTime - tuesdayStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.WednesdayEndTime != null && timesheetBusinessHours.WednesdayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.WednesdayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.WednesdayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    wednesdayDuration = 1440;
                }else{
                    Long wedEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.WednesdayEndTime).getTime();
                    Long wedStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.WednesdayStartTime).getTime();
                    wednesdayDuration = (wedEndTime - wedStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.ThursdayEndTime != null && timesheetBusinessHours.ThursdayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.ThursdayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.ThursdayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    thursdayDuration = 1440;
                }else{
                    Long thuEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.ThursdayEndTime).getTime();
                    Long thuStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.ThursdayStartTime).getTime();
                    thursdayDuration = (thuEndTime - thuStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.FridayEndTime != null && timesheetBusinessHours.FridayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.FridayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.FridayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    fridayDuration = 1440;
                }else{
                    Long friEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.FridayEndTime).getTime();
                    Long friStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.FridayStartTime).getTime();
                    fridayDuration = (friEndTime - friStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.SaturdayEndTime != null && timesheetBusinessHours.SaturdayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.SaturdayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.SaturdayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    saturdayDuration = 1440;
                }else{
                    Long satEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.SaturdayEndTime).getTime();
                    Long satStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.SaturdayStartTime).getTime();
                    saturdayDuration = (satEndTime - satStartTime) / (1000 * 60);
                }
            }

            if(timesheetBusinessHours.SundayEndTime != null && timesheetBusinessHours.SundayStartTime != null){
                String startTime = String.valueOf(timesheetBusinessHours.SundayEndTime);
                String endTime = String.valueOf(timesheetBusinessHours.SundayStartTime);

                if(startTime.equals('00:00:00.000Z') && endTime.equals('00:00:00.000Z')){
                    sundayDuration = 1440;
                }else{
                    Long sunEndTime = DateTime.newInstance(System.today(),timesheetBusinessHours.SundayEndTime).getTime();
                    Long sunStartTime = DateTime.newInstance(System.today(),timesheetBusinessHours.SundayStartTime).getTime();
                    sundayDuration = (sunEndTime - sunStartTime) / (1000 * 60);
                }
            }
        }else{
            System.debug('No Business Hours Provided');
        }

        Map<String,Long> durationMap = new Map<String,Long>();
        durationMap.put('Mon',mondayDuration);
        durationMap.put('Tue',tuesdayDuration);
        durationMap.put('Wed',wednesdayDuration);
        durationMap.put('Thu',thursdayDuration);
        durationMap.put('Fri',fridayDuration);
        durationMap.put('Sat',saturdayDuration);
        durationMap.put('Sun',sundayDuration);

        return durationMap;
    }


    /*****************************************************************************************************************************************
    *  Method Name : retrieveTimesheetSetting
    *  Parameter   : --
    *  Returns     : --
    *  Description : Get All Timesheet Settings which control the timesheet functionality and store it in variables
    *******************************************************************************************************************************************/  
    @TestVisible private void retrieveTimesheetSetting(){
        List<SVMX_PS_TS_Timesheet_Settings__c> timesheetSettingsList = SVMX_PS_TS_Timesheet_Settings__c.getAll().values();
        if(timesheetSettingsList != null){
            for(SVMX_PS_TS_Timesheet_Settings__c timesheetSetting : timesheetSettingsList){
                if(timesheetSetting.Name.equals(STOP_TIMESHEET_FUNCTIONALITY)){
                    isStopFunctionality = timesheetSetting.SVMX_PS_TS_Value__c;
                }else if(timesheetSetting.Name.equals(STOP_TIMESHEET_FUNCTIONALITY_FOR_EVENT)){
                    isStopFunctionalityForWorkDetails = timesheetSetting.SVMX_PS_TS_Value__c;
                }else if(timesheetSetting.Name.equals(STOP_TIMESHEET_FUNCTIONALITY_FOR_WORK_DETAILS)){
                    isStopFunctionalityForEvent = timesheetSetting.SVMX_PS_TS_Value__c;
                }
            }
        }

        //if custom settings are not present, open the timesheet functionality
        if(isStopFunctionality == null){
            isStopFunctionality = false;
        }

        if(isStopFunctionalityForWorkDetails == null){
            isStopFunctionalityForWorkDetails = false;
        }

        if(isStopFunctionalityForEvent == null){
            isStopFunctionalityForEvent = false;
        }
    }

    /*****************************************************************************************************************************************
    *  InnerClass Name : TimesheetWrapper
    *  Description : Class to hold timesheet variables. 
    *******************************************************************************************************************************************/  
    public class TimesheetWrapper {
        //boolean variable to revert time entry
        Boolean isNegativeTimeEntry;
        //Work Detail 
        SVMXC__Service_Order_Line__c workDetail;
        //Salesforce Event
        Event salesforceEvent;

        //Constructor for initialization of variable used for Work Details
        TimesheetWrapper(Boolean isNegativeTimeEntry, SVMXC__Service_Order_Line__c workDetail){
            this.isNegativeTimeEntry = isNegativeTimeEntry;
            this.workDetail = workDetail;
        }

        //Constructor for initialization of variable used for Events
        TimesheetWrapper(Boolean isNegativeTimeEntry, Event salesforceEvent){
            this.isNegativeTimeEntry = isNegativeTimeEntry;
            this.salesforceEvent = salesforceEvent;
        }

        //method to get time entry needs to be marked as negative
        public boolean getIsNegativeTimeEntry(){
            return this.isNegativeTimeEntry;
        }

        //method to get work detail
        public SVMXC__Service_Order_Line__c getWorkDetail(){
            return  this.workDetail;
        } 

        //method to get events
        public Event getSalesforceEvent(){
            return  this.salesforceEvent;
        } 
    }

    // The following methods are Locale safe, and should be used instead of Date.toStartOfWeek()

    private final static Date COMPARE_DATE = Date.newInstance(2001, 01, 07);
    public static Integer getDayOfWeek(Date d) 
    {
        return Math.mod(COMPARE_DATE.daysBetween(d) , 7);
    }

    public static Date toStartOfWeek(Date d)
    {
        Integer dayNum = getDayOfWeek(d);
        return d.addDays(-dayNum);
    }

}
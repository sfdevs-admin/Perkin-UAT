/**
 * Created by Bolt Data - John Lill on 5/11/2021.
 *
 * <*** Updates ***>
 * 06/03/2022   tony    ITSVMX-899 Get Candidate Error
 * 06/30/2022   tony    ITSVMX-899 Get Candidate Error - additional fix to add the SMAX_PS_ProductSeries__c field to the query
 * 09/26/2022   tony    ITSVMX-1005 Get Candidates Assignment Error - Throw new exceptions with more detailed information
 * 2022-10-04		Sarala Lakkireddy         ITSVMX-664 Replace model series field on IP with new custom field with SMAX_PS_ModelSeries_2__c field	
 *                                            Get the model series form product if not available get it from IP.  
 */
 

public with sharing class SMAX_PS_AutoAssignmentObjectives
{

    // 09/26/2022 tony Added exception class to throw new exception with more detailed user information
    public class SMAX_PS_AutoAssignmentObjectivesException extends Exception {}

    public class AssignTechWrapper
    {
        @AuraEnabled public Id techId {get;set;}
        @AuraEnabled public String techName {get;set;}
        @AuraEnabled public Decimal availability {get;set;}
        @AuraEnabled public List<Datetime> timeSlots {get;set;}
        @AuraEnabled public Datetime firstTimeSlot {get;set;}
        @AuraEnabled public Decimal expertise {get;set;}
        @AuraEnabled public Id expId {get;set;}
        @AuraEnabled public Decimal proximity {get;set;}
        @AuraEnabled public Decimal continuity {get;set;}
        @AuraEnabled public Decimal bundling {get;set;}
        @AuraEnabled public Decimal mileage {get;set;}
        @AuraEnabled public Decimal availabilityScore {get;set;}
        @AuraEnabled public Decimal expertiseScore {get;set;}
        @AuraEnabled public Decimal proximityScore {get;set;}
        @AuraEnabled public Decimal continuityScore {get;set;}
        @AuraEnabled public Decimal bundlingScore {get;set;}
        @AuraEnabled public String availabilityDisplay {get;set;}
        @AuraEnabled public String expertiseDisplay {get;set;}
        @AuraEnabled public String proximityDisplay {get;set;}
        @AuraEnabled public String continuityDisplay {get;set;}
        @AuraEnabled public String bundlingDisplay {get;set;}
        @AuraEnabled public Decimal totalScore {get;set;}
    }

    public class LabelValue
    {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}

        public LabelValue(String label, String value)
        {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static List<LabelValue> getAssignmentPolicies()
    {
        List<SMAX_PS_Assignment_Policy__mdt> policies = [SELECT Id, Label, DeveloperName
        FROM SMAX_PS_Assignment_Policy__mdt];
        List<LabelValue> assignmentPolicies = new List<LabelValue>();
        for (SMAX_PS_Assignment_Policy__mdt policy :policies) {
            LabelValue labelValue = new LabelValue(policy.Label, policy.DeveloperName);
            assignmentPolicies.add(labelValue);
        }
        return assignmentPolicies;
    }

    @AuraEnabled
    public static String assignTech(Id woId, Id techId, Datetime schedDateTime, Id expId)
    {
        System.debug('assignTech entry: ' + woId + ' ' + techId + ' ' + schedDateTime + ' ' + expId);
        SVMXC__Service_Order__c wo = [SELECT Id, Name, SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SMAX_PS_AutoAssignmentNotes__c,
                SVMX_PS_Problem_Summary__c
        FROM SVMXC__Service_Order__c WHERE Id = :woId];
        SVMXC__Service_Group_Members__c tech = [SELECT Id, SVMXC__Salesforce_User__c, SVMXC__Service_Group__c
        FROM SVMXC__Service_Group_Members__c WHERE Id = :techId];
//        SVMXC__Service_Group_Skills__c expertise = [SELECT Id FROM SVMXC__Service_Group_Skills__c WHERE Id = :expId];

        Event evt = SMAX_PS_AutoAssignment.assignTechnician(wo, tech, schedDateTime, expId);
        if(evt != null)
        {
            insert evt;
            return 'Success';
        }
        else
        {
            return 'Failed';
        }

    }


    //called from LWC
    @AuraEnabled
    public static List<AssignTechWrapper> getCandidates(Id woId, Date firstDate, Date lastDate, String policyDevName)
    {
        // 06/30/2022 ITSVMX-899 Get Candidate Error - need to add the SMAX_PS_ProductSeries__c field to the query
        List<SVMXC__Service_Order__c> woList = [SELECT Id, SVMXC__Order_Type__c, SVMXC__Component__c, SVMXC__Site__c, SMAX_PS_Geography__c,
                SVMXC__Scheduled_Date__c, SVMXC__SM_Estimated_Duration__c, SVMXC__Latitude__c, SVMXC__Longitude__c,
                SMAX_PS_Is_Enterprise__c, SVMXC__Site__r.SVMXC__Zip__c, SVMXC__Component__r.SVMXC__Product__r.product_line__c,
                SMAX_PS_AutoAssignmentNotes__c, SMAX_PS_ProductSeries__c
        FROM SVMXC__Service_Order__c WHERE Id = :woId];

        SMAX_PS_Assignment_Policy__mdt policy = [SELECT Id, SMAX_PS_Availability__c, SMAX_PS_Bundling__c, SMAX_PS_Continuity__c,
                SMAX_PS_Expertise__c, SMAX_PS_Proximity__c
        FROM SMAX_PS_Assignment_Policy__mdt WHERE DeveloperName = :policyDevName];

        return doAssignment(woList, firstDate, lastDate, policy, false).values();
    }

    //called from auto-assignment
    public static Map<Id, AssignTechWrapper> doAutoAssignment(SVMXC__Service_Order__c wo, SMAX_PS_Assignment_Policy__mdt policy, Boolean autoAssign)
    {
        List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
        woList.add(wo);

        return doAssignment(woList, null, null, policy, autoAssign);
    }

    @AuraEnabled //not sure this is still needed
    public static Map<Id, AssignTechWrapper> doAssignment(List<SVMXC__Service_Order__c> woList, Date firstDate, Date lastDate, SMAX_PS_Assignment_Policy__mdt policy, Boolean autoAssign)
    {
        List<Id> ipIds = new List<Id>();
        List<Id> locIds = new List<Id>();
        List<Id> geoIds = new List<Id>();
        List<Id> techIds = new List<Id>();
        Set<String> series = new Set<String>();
        Map<Id, AssignTechWrapper> wrapperMap = new Map<Id, AssignTechWrapper>();

        for(SVMXC__Service_Order__c wo:woList)
        {
            ipIds.add(wo.SVMXC__Component__c);
            locIds.add(wo.SVMXC__Site__c);
        }
       // ITSVMX-664 Added new field SMAX_PS_ModelSeries_2__c
        Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>(
        [SELECT Id, SVMXC__Preferred_Technician__c, SVMXC__Preferred_Technician__r.Name,
                SVMXC__Preferred_Technician__r.SVMXC__Service_Group__c, SVMXC__Preferred_Technician__r.SVMXC__Zip__c,
                SVMXC__Preferred_Technician__r.SVMXC__Salesforce_User__c, SVMXC__Preferred_Technician__r.SVMXC__Active__c,
                SVMXC__Preferred_Technician__r.SVMXC__Enable_Scheduling__c, SVMXC__Site__c, SVMXC__Site__r.SVMXC__Zip__c,
                SVMXC__Site__r.SMAX_PS_Geography__c, SVMXC__Product__c, SVMXC__Product__r.Product_Line__c, SMAX_PS_ModelSeries__c,
                SMAX_PS_ModelSeries_2__c,
        (SELECT Id, SVMXC__Group_Member__c, SVMXC__Scheduled_Date__c
        FROM SVMXC__Service_Order_Component__r
        WHERE (SVMXC__Scheduled_Date__c = LAST_N_DAYS:365 OR SVMXC__Scheduled_Date__c > TODAY)
        ORDER BY SVMXC__Scheduled_Date__c DESC)
        FROM SVMXC__Installed_Product__c
        WHERE Id IN :ipIds]);

        Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>(
        [SELECT Id, SVMXC__Zip__c, SMAX_PS_Geography__c
        FROM SVMXC__Site__c
        WHERE Id IN :locIds]);

        //bundling
        Set<String> zipSet = new Set<String>();
        Set<String> prdLineSet = new Set<String>();

        Map<Id, Id> woGeoMap = new Map<Id, Id>();
        Map<Id, String> woSeriesMap = new Map<Id, String>();

        for(SVMXC__Service_Order__c wo:woList)
        {
            if(ipMap.containsKey(wo.SVMXC__Component__c))
            {
                geoIds.add(ipMap.get(wo.SVMXC__Component__c).SVMXC__Site__r.SMAX_PS_Geography__c);
                woGeoMap.put(wo.Id, ipMap.get(wo.SVMXC__Component__c).SVMXC__Site__r.SMAX_PS_Geography__c);
        //ITSVMX-664 Replace SMAX_PS_ModelSeries__c with SMAX_PS_ModelSeries_2__c
                if(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_ModelSeries_2__c != null)
                {
                    series.add(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_ModelSeries_2__c);
                    woSeriesMap.put(wo.id, ipMap.get(wo.SVMXC__Component__c).SMAX_PS_ModelSeries_2__c);
                    //for bundling
                    zipSet.add(ipMap.get(wo.SVMXC__Component__c).SVMXC__Site__r.SVMXC__Zip__c);
                    prdLineSet.add(ipMap.get(wo.SVMXC__Component__c).SVMXC__Product__r.product_line__c);
                }

            }
            else
            {
                if(locMap.containsKey(wo.SVMXC__Site__c))
                {
                    geoIds.add(locMap.get(wo.SVMXC__Site__c).SMAX_PS_Geography__c);
                    woGeoMap.put(wo.Id, locMap.get(wo.SVMXC__Site__c).SMAX_PS_Geography__c);
                }

                if (wo.SMAX_PS_ProductSeries__c != null)
                {
                    series.add(wo.SMAX_PS_ProductSeries__c);
                    woSeriesMap.put(wo.Id, wo.SMAX_PS_ProductSeries__c);
                }
            }

        }

        Map<String, List<SVMXC__Service_Order__c>> bundleMap = new Map<String, List<SVMXC__Service_Order__c>>();
        List<SVMXC__Service_Order__c> bundleWOList = [SELECT Id, SVMXC__Group_Member__c, SVMXC__Site__r.SVMXC__Zip__c,
                SVMXC__Component__r.SVMXC__Product__r.product_line__c
        FROM SVMXC__Service_Order__c
        WHERE SVMXC__Component__r.SVMXC__Product__r.product_line__c IN :prdLineSet
        AND SVMXC__Site__r.SVMXC__Zip__c IN :zipSet
        AND SVMXC__Scheduled_Date__c = NEXT_N_DAYS:30];

        for(SVMXC__Service_Order__c bundleWO:bundleWOList)
        {
            String bundleKey = bundleWO.SVMXC__Site__r.SVMXC__Zip__c + bundleWO.SVMXC__Component__r.SVMXC__Product__r.product_line__c;
            if(!bundleMap.containsKey(bundleKey))
            {
                bundleMap.put(bundleKey, new List<SVMXC__Service_Order__c>());
            }
            bundleMap.get(bundleKey).add(bundleWO);
        }


        Map<Id, List<SMAX_PS_Geography_Technician__c>> geoTechMap = new Map<Id, List<SMAX_PS_Geography_Technician__c>>();
        for (SMAX_PS_Geography_Technician__c geoTech : [SELECT Id, SMAX_PS_Geography__c, SMAX_PS_Technician__c, SMAX_PS_Rank__c
        FROM SMAX_PS_Geography_Technician__c WHERE SMAX_PS_Geography__c IN :geoIds ORDER BY SMAX_PS_Rank__c])
        {
            if (!geoTechMap.containsKey(geoTech.SMAX_PS_Geography__c))
                geoTechMap.put(geoTech.SMAX_PS_Geography__c, new List<SMAX_PS_Geography_Technician__c>());
            geoTechMap.get(geoTech.SMAX_PS_Geography__c).add(geoTech);

            techIds.add(geoTech.SMAX_PS_Technician__c);
        }

        System.debug('techIds: ' + techIds);

        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
        [SELECT Id, Name, SVMXC__Salesforce_User__c, SVMXC__Zip__c, SVMXC__Service_Group__c,
                SVMXC__Service_Group__r.SMAX_PS_Is_Enterprise__c, SVMXC__Latitude_Home__c, SVMXC__Longitude_Home__c,
                SVMXC__Working_Hours__c, SVMXC__Working_Hours__r.TimeZoneSidKey,
                SVMXC__Working_Hours__r.MondayStartTime, SVMXC__Working_Hours__r.MondayEndTime,
                SVMXC__Working_Hours__r.TuesdayStartTime, SVMXC__Working_Hours__r.TuesdayEndTime,
                SVMXC__Working_Hours__r.WednesdayStartTime, SVMXC__Working_Hours__r.WednesdayEndTime,
                SVMXC__Working_Hours__r.ThursdayStartTime, SVMXC__Working_Hours__r.ThursdayEndTime,
                SVMXC__Working_Hours__r.FridayStartTime, SVMXC__Working_Hours__r.FridayEndTime,
                SVMXC__Working_Hours__r.SaturdayStartTime, SVMXC__Working_Hours__r.SaturdayEndTime,
                SVMXC__Working_Hours__r.SundayStartTime, SVMXC__Working_Hours__r.SundayEndTime,
        (SELECT Id, SVMXC__Skill__c, SVMXC__Skill__r.Name, SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c,
                SVMXC__Skill_Level__c, SMAX_PS_Activity_Type__c
        FROM SVMXC__Service_Group_Skills__r
        WHERE SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c IN :series
        ORDER BY SVMXC__Skill_Level__c DESC)
        FROM SVMXC__Service_Group_Members__c
        WHERE Id IN :techIds
        AND SVMXC__Active__c = TRUE
        AND SVMXC__Enable_Scheduling__c = TRUE]);

        BusinessHours stdBH = [SELECT Id, TimeZoneSidKey, IsActive FROM BusinessHours WHERE IsDefault = true];


        for(SVMXC__Service_Order__c wo:woList)
        {
            Map<Id, SVMXC__Service_Group_Members__c> techToCheckMap = new Map<Id, SVMXC__Service_Group_Members__c>();
            Id geoId = woGeoMap.get(wo.id);
//            List<SMAX_PS_Geography_Technician__c> geoTechList = geoTechMap.get(geoId);
            List<SMAX_PS_Geography_Technician__c> geoTechList = new List<SMAX_PS_Geography_Technician__c>();
            if (geoId != null)
            {
                // 09/27/2022 tony Added debug lines for troubleshooting
                System.debug('geoId: ' + geoId);
                System.debug('geoTechMap: ' + geoTechMap);
                if (!geoTechMap.isEmpty()) {
                    geoTechList.addAll(geoTechMap?.get(geoId));
                } else {
                    System.debug('There were no SMAX_PS_Geography_Technician__c records found');
                    throw new SMAX_PS_AutoAssignmentObjectivesException(
                            'No SMAX_PS_Geography_Technician__c records found for Geography: ' + geoId + ' ');
                }
                System.debug('geoTechList: ' + geoTechList.size() + ' ' + geoTechList);
            }

            SVMXC__Installed_Product__c ip = ipMap.get(wo.SVMXC__Component__c);
            String modelSeries = woSeriesMap.get(wo.Id);
            if (modelSeries == null)
            {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Cannot perform auto-assignment without IP Skill.';
                continue;
            }

            System.debug('geoTechList: ' + geoTechList);

            Map<Id,Id> techToExpertiseMap = new Map<Id,Id>();

            for(SMAX_PS_Geography_Technician__c geoTech:geoTechList)
            {
                if(techMap.get(geotech.SMAX_PS_Technician__c) == null)
                    continue;

                SVMXC__Service_Group_Members__c techToCheck = techMap.get(geoTech.SMAX_PS_Technician__c);
                for(SVMXC__Service_Group_Skills__c skill:techToCheck.SVMXC__Service_Group_Skills__r)
                {
                    if(skill.SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c == modelSeries &&
                            techToCheck.SVMXC__Service_Group__r.SMAX_PS_Is_Enterprise__c == wo.SMAX_PS_Is_Enterprise__c &&
                            !techToCheckMap.containsKey(techToCheck.id))

                    {
                        techToCheckMap.put(techToCheck.id, techToCheck);
                        techToExpertiseMap.put(techToCheck.id, skill.id);
                        continue;
                    }
                }
            }

            for(SVMXC__Service_Group_Members__c tech:techToCheckMap.values())
            {
                AssignTechWrapper wrapper = new AssignTechWrapper();
                wrapper.techId = tech.id;
                wrapper.techName = tech.Name;
                wrapper.expId = techToExpertiseMap.get(tech.id);
                wrapper.availability = 0;
                wrapper.availabilityScore = 0;
                wrapper.availabilityDisplay = '0/0';
                wrapper.bundling = 0;
                wrapper.bundlingScore = 0;
                wrapper.bundlingDisplay = '0/0';
                wrapper.continuity = 0;
                wrapper.continuityScore = 0;
                wrapper.continuityDisplay = '0/0';
                wrapper.expertise = 0;
                wrapper.expertiseScore = 0;
                wrapper.expertiseDisplay = '0/0';
                wrapper.proximity = 0;
                wrapper.proximityScore = 0;
                wrapper.proximityDisplay = '0/0';
                wrapper.totalScore = 0;
                wrapperMap.put(tech.id, wrapper);
            }

//
            if(policy.SMAX_PS_Availability__c != null && policy.SMAX_PS_Availability__c > 0)
            {
                doAvailability(techToCheckMap, wrapperMap, wo, autoAssign, firstDate, lastDate);
            }
            if(policy.SMAX_PS_Bundling__c != null && policy.SMAX_PS_Bundling__c > 0)
            {
                doBundling(techToCheckMap, wrapperMap, wo, autoAssign, bundleMap);
            }
            if(policy.SMAX_PS_Continuity__c != null && policy.SMAX_PS_Continuity__c > 0)
            {
                doContinuity(techToCheckMap, wrapperMap, wo, autoAssign, ip);
            }
            if(policy.SMAX_PS_Expertise__c != null && policy.SMAX_PS_Expertise__c > 0)
            {
                doExpertise(techToCheckMap, wrapperMap, wo, autoAssign, ip);
            }
            if(policy.SMAX_PS_Proximity__c != null && policy.SMAX_PS_Proximity__c > 0)
            {
                doProximity(techToCheckMap, wrapperMap, wo, autoAssign);
            }

            for(AssignTechWrapper wrapper:wrapperMap.values())
            {
                Decimal availabilityWeight = policy.SMAX_PS_Availability__c == null ? 0 : policy.SMAX_PS_Availability__c;
                wrapper.availabilityScore = wrapper.availability * availabilityWeight;
                wrapper.availabilityDisplay = wrapper.availabilityScore + '/' + availabilityWeight;
                Decimal bundlingWeight = policy.SMAX_PS_Bundling__c == null ? 0 : policy.SMAX_PS_Bundling__c;
                wrapper.bundlingScore = wrapper.bundling * bundlingWeight;
                wrapper.bundlingDisplay = wrapper.bundlingScore + '/' + bundlingWeight;
                Decimal continuityWeight = policy.SMAX_PS_Continuity__c == null ? 0 : policy.SMAX_PS_Continuity__c;
                wrapper.continuityScore = wrapper.continuity * continuityWeight;
                wrapper.continuityDisplay = wrapper.continuityScore + '/' + continuityWeight;
                Decimal expertiseWeight = policy.SMAX_PS_Expertise__c == null ? 0 : policy.SMAX_PS_Expertise__c;
                wrapper.expertiseScore = wrapper.expertise * expertiseWeight;
                wrapper.expertiseDisplay = wrapper.expertiseScore + '/' + expertiseWeight;
                Decimal proximityWeight = policy.SMAX_PS_Proximity__c == null ? 0 : policy.SMAX_PS_Proximity__c;
                wrapper.proximityScore = wrapper.proximity * proximityWeight;
                wrapper.proximityDisplay = wrapper.proximityScore + '/' + proximityWeight;

                wrapper.totalScore = wrapper.availabilityScore + wrapper.bundlingScore + wrapper.continuityScore +
                        wrapper.expertiseScore + wrapper.proximityScore;

//                wrapper.totalScore =
//                        (wrapper.availability * (policy.SMAX_PS_Availability__c == null ? 0 : policy.SMAX_PS_Availability__c)) +
//                                (wrapper.bundling * (policy.SMAX_PS_Bundling__c == null ? 0 : policy.SMAX_PS_Bundling__c)) +
//                                (wrapper.continuity * (policy.SMAX_PS_Continuity__c == null ? 0 : policy.SMAX_PS_Continuity__c)) +
//                                (wrapper.expertise * (policy.SMAX_PS_Expertise__c == null ? 0 : policy.SMAX_PS_Expertise__c)) +
//                                (wrapper.proximity * (policy.SMAX_PS_Proximity__c == null ? 0 : policy.SMAX_PS_Proximity__c));

                System.debug('Final status of wrapper: ' + wrapper);
            }

        }

        return wrapperMap;


    }

    public static Map<Id, AssignTechWrapper> doAvailability(Map<Id,SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign, Date firstDate, Date lastDate)
    {
        //build event map
        List<Id> techUserIds = new List<Id>();
        List<Date> dateList = new List<Date>();
        Map<Id, Map<Date, List<Event>>> userToDateToEvtList = new Map<Id,Map<Date,List<Event>>>();

        //build eligible dates
        if(firstDate == null)
        {
            dateList.add(wo.SVMXC__Scheduled_Date__c);
        }
        else if((firstDate != null && lastDate == null) || (firstDate == lastDate))
        {
            dateList.add(firstDate);
        }
        else if(firstDate != null && lastDate != null)
        {
            for(Integer i = 0 ; i <= firstDate.daysBetween(lastDate) ; i++)
            {
                dateList.add(firstDate.addDays(i));
            }
        }



//        Date schedDate = custDate != null ? custDate : wo.SVMXC__Scheduled_Date__c;
//        Integer dayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(schedDate),7); //Sunday = 0
//        dateList.add(schedDate);
//
//        //add day after for auto assign only
//        if(autoAssign == true)
//        {
//            if(dayOfWeek == 0 || dayOfWeek == 1|| dayOfWeek == 2|| dayOfWeek == 3|| dayOfWeek == 4)
//            {
//                dateList.add(schedDate.addDays(1));
//            }
//            else if(dayOfWeek == 5)
//            {
//                dateList.add(schedDate.addDays(3));
//            }
//            else if(dayOfWeek == 6)
//            {
//                dateList.add(schedDate.addDays(2));
//            }
//        }

        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            techUserIds.add(tech.SVMXC__Salesforce_User__c);
            Map<Date,List<Event>> newDateToEvtMap = new Map<Date,List<Event>>();
            for(Date schDate:dateList)
            {
                newDateToEvtMap.put(schDate, new List<Event>());
            }
            userToDateToEvtList.put(tech.SVMXC__Salesforce_User__c, newDateToEvtMap);
        }

        List<Event> evtToCheck = [SELECT Id, Subject, ActivityDate, OwnerId, StartDateTime, EndDateTime
        FROM Event WHERE OwnerId IN :techUserIds AND ActivityDate IN :dateList];

        for(Event evt:evtToCheck)
        {
            userToDateToEvtList.get(evt.OwnerId).get(evt.ActivityDate).add(evt);
        }

        List<Datetime> techBestSlots = new List<Datetime>();
        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {

            AssignTechWrapper assignTech = wrapperMap.get(tech.id);

            //pad duration for travel by adding 1 hour, then round up
            Decimal woDur = Math.ceil((wo.SVMXC__SM_Estimated_Duration__c/60) + 1);
            List<Datetime> goodTimeSlots = new List<Datetime>();

            System.debug('tech.SVMXC__Working_Hours__c: ' + tech.SVMXC__Working_Hours__c);
            System.debug('tech.SVMXC__Working_Hours__r.TimeZoneSidKey: ' + tech.SVMXC__Working_Hours__r.TimeZoneSidKey);
            System.debug('No SVMXC__Working_Hours__c OR TimeZoneSidKey was found for tech: ' + tech.Id + ' ' + tech.Name);
            // 09/26/2022 tony Throw new exception with more detailed information
            if (tech.SVMXC__Working_Hours__c == null) {
                throw new SMAX_PS_AutoAssignmentObjectivesException(
                        'No SVMXC__Working_Hours__c OR SVMXC__Working_Hours__r.TimeZoneSidKey was found for tech: ' + tech.Id + ' ' + tech.Name + ' ');
            }

            TimeZone tz = TimeZone.getTimeZone(tech.SVMXC__Working_Hours__r.TimeZoneSidKey);
            TimeZone local = UserInfo.getTimeZone();
            Integer offset = (local.getOffset(Datetime.now()) - tz.getOffset(Datetime.now()))/3600000;


            if(userToDateToEvtList.get(tech.SVMXC__Salesforce_User__c) != null)
//                    && userToDateToEvtList.get(tech.SVMXC__Salesforce_User__c).containsKey(schedDate))
            {
                for(Date dateToCheck:userToDateToEvtList.get(tech.SVMXC__Salesforce_User__c).keyset())
                {
                    //set tech working hours
                    Time startTime;
                    Time endTime;
                    Integer dayToCheck = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(dateToCheck),7); //Sunday = 0

                    if(dayToCheck == 0)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.SundayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.SundayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 1)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.MondayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.MondayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 2)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.TuesdayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.TuesdayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 3)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.WednesdayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.WednesdayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 4)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.ThursdayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.ThursdayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 5)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.FridayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.FridayEndTime?.addHours(offset);
                    }
                    else if(dayToCheck == 6)
                    {
                        startTime = tech.SVMXC__Working_Hours__r.SaturdayStartTime?.addHours(offset);
                        endTime = tech.SVMXC__Working_Hours__r.SaturdayEndTime?.addHours(offset);
                    }

                    System.debug('Offset is ' + offset);
                    System.debug('Work hours start ' + startTime);


                    Map<Integer, Boolean> hourMap = new Map<Integer, Boolean>();
                    if(startTime != null)
                    {
                        for(Integer i = startTime.hour() ; i < endTime.hour() ; i++)
                        {
                            hourMap.put(i, true);
                        }
                    }


                    //iterate through all that days events; determine which hours are open
                    List<Event> evtsToCheck = userToDateToEvtList.get(tech.SVMXC__Salesforce_User__c).get(dateToCheck);
                    for(Event evt:evtsToCheck)
                    {
                        System.debug('EVENT start: ' + evt.StartDateTime + ' and end: ' + evt.EndDateTime);
                        for(Integer i = evt.StartDateTime.hour() ; i < evt.EndDateTime.hour() ; i++)
                        {
                            Boolean available = hourMap.get(i);
                            available = false;
                            hourMap.put(i, false);
                            System.debug('HourMap in evt loop: ' + hourMap);
                        }

                    }
                    System.debug('HourMap after all evt loop: ' + hourMap);
                    System.debug('WO Duration: ' + woDur);

                    //find available timeslots
                    if(startTime != null)
                    {
                        for(Integer i = startTime.hour() ; i < endTime.hour() ; i++)
                        {
                            Boolean durCheck = false;
                            if(hourMap.get(i) == true)
                            {
                                durCheck = true;
                                for(Integer j = 0 ; j < woDur -1 ; j++ )
                                {
                                    if(hourMap.get(i + j) == null || hourMap.get(i + j) == false)
                                    {
                                        durCheck = false;
                                        break;
                                    }
                                }
                                if(durCheck == true)
                                {
                                    //good timeslot found - build datetime and add to List
                                    Datetime goodTime = Datetime.newInstance(dateToCheck, Time.newInstance(i, 0, 0, 0));
                                    goodTimeSlots.add(goodTime);
                                }

                            }
                        }
                    }

                }
            }

            if(!goodTimeSlots.isEmpty())
            {
                goodTimeSlots.sort();
                assignTech.firstTimeSlot = goodTimeSlots[0];
                assignTech.timeSlots = goodTimeSlots;
                techBestSlots.add(goodTimeSlots[0]);
            }

        }

        Decimal minAvail;
        Decimal maxAvail;
        Decimal divisor;
        if(!techBestSlots.isEmpty())
        {
            techBestSlots.sort();
            minAvail = techBestSlots[0].getTime() * -1;
            maxAvail = techBestSlots[techBestSlots.size()-1].getTime() * -1;
            divisor = (maxAvail - minAvail == 0 ? 1 : maxAvail - minAvail);
        }



        //create Availability score
        for(AssignTechWrapper wrapper:wrapperMap.values())
        {
            if(!techBestSlots.isEmpty())
            {
                // 09/27/2022 tony Added debug code for troubleshooting and a check for the firstTimeSlot
                System.debug('divisor: ' + divisor);
                System.debug('minAvail: ' + minAvail);
                System.debug('wrapper: ' + wrapper);
                System.debug('wrapper.techId: ' + wrapper.techId + '  wrapper.techName: ' + wrapper.techName);
                System.debug('wrapper.firstTimeSlot: ' + wrapper.firstTimeSlot);
                if (wrapper.firstTimeSlot != null) {
                    wrapper.availability = (divisor - ((wrapper.firstTimeSlot.getTime() * -1)- minAvail))/divisor;
                } else {
                    throw new SMAX_PS_AutoAssignmentObjectivesException(
                            'No Time Slots found for Technician: ' + wrapper.techId + ' ' + wrapper.techName + ' ');
                    //wrapper.availability = 0;
                }
            }
            else
            {
                wrapper.availability = 0;
            }

        }

        System.debug('WrapperMap after Availability: ' + wrapperMap);

        return wrapperMap;


    }

    public static Map<Id, AssignTechWrapper> doExpertise(Map<Id, SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign, SVMXC__Installed_Product__c ip)
    {
        String activityType = SMAX_PS_ExperienceManager.lookupSkillActivityType(wo.SVMXC__Order_Type__c);

        Map<Id, Map<String, Decimal>> techToSkillToSkillLevel = new Map<Id, Map<String,Decimal>>();
        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            if(!techToSkillToSkillLevel.containsKey(tech.id))
            {
                techToSkillToSkillLevel.put(tech.id, new Map<String, Decimal>());
            }
            Map<String, Decimal> skillToSkillLevel = techToSkillToSkillLevel.get(tech.id);
            for(SVMXC__Service_Group_Skills__c skill:tech.SVMXC__Service_Group_Skills__r)
            {
                String actTypes = (skill.SMAX_PS_Activity_Type__c == null) ? '' : skill.SMAX_PS_Activity_Type__c;
                Set<String> activityTypes = new Set<String>(actTypes.split(';'));
                if (activityTypes.contains('ALL') || activityTypes.contains(activityType)) {
                    // Only give them the score if the Activity Types match.. if not, they'll get a blank = 0
                    skillToSkillLevel.put(skill.SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c, skill.SVMXC__Skill_Level__c);
                }
            }
        }

        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            AssignTechWrapper assignTech = wrapperMap.get(tech.id);
            //ITSVMX-664 Replace SMAX_PS_ModelSeries__c with SMAX_PS_ModelSeries_2__c
            Decimal skillLevel = techToSkillToSkillLevel.get(tech.id).get(ip.SMAX_PS_ModelSeries_2__c);
            if(skillLevel == null || skillLevel == 0)
            {
                assignTech.expertise = 0;
            }
            else
            {
                assignTech.expertise = (skillLevel/5);
            }
        }

        System.debug('WrapperMap after Expertise: ' + wrapperMap);
        return wrapperMap;
    }

    public static Map<Id, AssignTechWrapper> doProximity(Map<Id, SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign)
    {
        List<Decimal> mileageValues = new List<Decimal>();
        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            AssignTechWrapper assignTech = wrapperMap.get(tech.id);
            Location techHome = Location.newInstance(tech.SVMXC__Latitude_Home__c, tech.SVMXC__Longitude_Home__c);
            Location woLoc = Location.newInstance(wo.SVMXC__Latitude__c, wo.SVMXC__Longitude__c);
            System.debug('Lat/Longs: ' + techHome + ' - ' + woLoc);
            // 6/3/2022 tony ITSVMX-899 Get Candidate Error - Added check for lat/long as you have to check each individually
            // if (techHome == null || woLoc == null) {
            if (techHome.latitude == null || techHome.longitude == null || woLoc.latitude == null || woLoc.longitude == null) {
                assignTech.mileage = null;
            } else {
                // 6/3/2022 tony Added debug lines for troubleshooting
                System.debug('techHome: ' + techHome.latitude + ' ' + techHome.longitude);
                System.debug('woLoc: ' + woLoc.latitude + ' ' + woLoc.longitude);
                Double distance = Location.getDistance(techHome, woLoc, 'mi').round();
                System.debug('distance: ' + distance);
                assignTech.mileage = Decimal.valueOf(distance);
                mileageValues.add(Decimal.valueOf(distance));
            }
        }

        if(mileageValues.isEmpty()){
            return wrapperMap;
        }

        mileageValues.sort();
        Decimal minMileage = mileageValues[0] * -1;
        Decimal maxMileage = mileageValues[(mileageValues.size()-1)] * -1;
        Decimal divisor = (maxMileage - minMileage == 0 ? 1 : maxMileage - minMileage);
        System.debug('min: ' + minMileage + ' - max: ' + maxMileage + ' - div: ' + divisor);

        for(AssignTechWrapper wrapper:wrapperMap.values())
        {
            wrapper.proximity = (wrapper.mileage == null) ? 0 :
                    ((divisor - ((wrapper.mileage * -1) - minMileage))/divisor).round();
        }

        System.debug('WrapperMap after Proximity: ' + wrapperMap);
        return wrapperMap;
    }

    public static Map<Id, AssignTechWrapper> doContinuity(Map<Id, SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign, SVMXC__Installed_Product__c ip)
    {
        if(ip == null)
            return wrapperMap;

        List<SVMXC__Service_Order__c> oldWOList = new List<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c otherWO:ip.SVMXC__Service_Order_Component__r)
        {
            if(otherWO.SVMXC__Scheduled_Date__c < wo.SVMXC__Scheduled_Date__c)
            {
                oldWOList.add(otherWO);
            }
        }

        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            AssignTechWrapper assignTech = wrapperMap.get(tech.id);

            if(oldWOList.size() >= 1 && oldWOList[0].SVMXC__Group_Member__c == tech.id )
            {
                assignTech.continuity = 1;
                continue;
            }
            else if(oldWOList.size() >= 2 && oldWOList[1].SVMXC__Group_Member__c == tech.id )
            {
                assignTech.continuity = 0.6;
                continue;
            }
            else if(oldWOList.size() >= 3 && oldWOList[2].SVMXC__Group_Member__c == tech.id )
            {
                assignTech.continuity = 0.3;
                continue;
            }
            else
            {
                assignTech.continuity = 0;
            }

        }

        System.debug('WrapperMap after Continuity: ' + wrapperMap);
        return wrapperMap;
    }

    public static Map<Id, AssignTechWrapper> doBundling(Map<Id, SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign, Map<String, List<SVMXC__Service_Order__c>> bundleMap)
    {
        if(wo.SVMXC__Site__r.SVMXC__Zip__c == null || wo.SVMXC__Component__r.SVMXC__Product__r.product_line__c == null)
        {
            return wrapperMap;
        }

        String key = wo.SVMXC__Site__r.SVMXC__Zip__c + wo.SVMXC__Component__r.SVMXC__Product__r.product_line__c;
        List<SVMXC__Service_Order__c> bundleList = bundleMap.get(key);

        if(bundleList == null || bundleList.isEmpty())
            return wrapperMap;

        Decimal bundTotal = bundleList.size();

        for(SVMXC__Service_Group_Members__c tech:techMap.values())
        {
            AssignTechWrapper assignTech = wrapperMap.get(tech.id);
            Decimal bundMatch = 0;

            for(SVMXC__Service_Order__c bundleWO:bundleList)
            {
                if(bundleWO.SVMXC__Group_Member__c == tech.id)
                {
                    bundMatch += 1;

                }
            }
            System.debug('bundle match? ' + assignTech.techName + ' - ' + bundMatch + '/' + bundTotal);
            assignTech.bundling = bundMatch/bundTotal;
            System.debug('bundling: ' + assignTech.bundling);

        }

        System.debug('WrapperMap after Bundling: ' + wrapperMap);
        return wrapperMap;
    }


//    public static Map<Id, AssignTechWrapper> doBundling(Map<Id, SVMXC__Service_Group_Members__c> techMap, Map<Id, AssignTechWrapper> wrapperMap, SVMXC__Service_Order__c wo, Boolean autoAssign, SVMXC__Installed_Product__c ip)
//    {
//        List<SVMXC__Service_Order__c> futWOList = new List<SVMXC__Service_Order__c>();
//
//        if(ip == null)
//            return wrapperMap;
//
//
//        for(SVMXC__Service_Order__c otherWO:ip.SVMXC__Service_Order_Component__r)
//        {
//            if(otherWO.SVMXC__Scheduled_Date__c > wo.SVMXC__Scheduled_Date__c)
//            {
//                futWOList.add(otherWO);
//            }
//
//
//            for(SVMXC__Service_Group_Members__c tech:techMap.values())
//            {
//                AssignTechWrapper assignTech = wrapperMap.get(tech.id);
//                Integer bundMatch = 0;
//                Integer bundTotal = 0;
//
//                for(SVMXC__Service_Order__c futWO:futWOList)
//                {
//                    bundTotal += 1;
//                    if(otherWO.SVMXC__Group_Member__c == tech.id)
//                    {
//                        bundMatch += 1;
//                    }
//                }
//
//                if(bundTotal != 0)
//                {
//                    assignTech.bundling = bundMatch/bundTotal;
//                }
//                else
//                {
//                    assignTech.bundling = 0;
//                }
//
//
//            }
//        }
//
//        System.debug('WrapperMap after Bundling: ' + wrapperMap);
//        return wrapperMap;
//    }

}
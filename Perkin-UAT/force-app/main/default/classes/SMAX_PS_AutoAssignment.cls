/** 
* Apex Class for WO [SVMXC__Service_Order__C] Auto Assignment Logic
* 2017-10-02 Bill Convis - Initial Creation
* 1: For each WO passed into the Trigger - check if Auto Assign = TRUE , Check Schedule Dates
* 2: If IP has default Tech - assign to Tech
* 3. Else - follow Geography, Skill, Expertise match looking for matching Tech.
*
* Updates:
*   03/17/2022  Tony - ITSVMX-776 Long Job Scheduling - Scheduling status not updated in Long Jobs
*   03/27/2022  Sarala Lakkireddy - ITSVMX-743 Tech Support & Hybrid Profile(w/ Tech Equip Record) Accepting RWO From Queue
*   03/29/2022  Tony - ITSVMX-801 Error when attempt to accept WO from queue
*   05/03/2022  Tony - ITSVMX-688 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
*   05/27/2022  Tony - ITSVMX-801 Go ahead and assign Service Request (Estimate) WOs even if they are LJS
*   6/02/2022   Tony - ITSVMX-862 To fix error being thrown by ServiceMax validation rule we need to add the Driving Time to the EndDateTime
*  2022-10-04       Sarala Lakkireddy         ITSVMX-664 Replace model series field on IP with new custom field with SMAX_PS_ModelSeries_2__c field
 *                                            Get the model series form product if not available get it from IP.
 */

public with sharing class SMAX_PS_AutoAssignment {

    private SMAX_PS_AutoAssignment() {
    }

    public class AssignTechWrapper
    {
        Id techId;
        Integer availability;
        Integer expertise;
        Decimal proximity;
        Decimal continuity;
        Decimal bundling;
        Decimal mileage;
        Decimal totalScore;
    }


    public static void performAutoAssignmentCheck(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('WO Auto Assignment', 'Perform a Auto-Assignment on the WO based on the IP or Location, and the Technician Skills and Geography.'))
            return;

        Date today = System.today();
        Date nearFuture = System.today().addDays(90);

        List<SVMXC__Service_Order__c> wosToCheck = new List<SVMXC__Service_Order__c>();
        Map<Id, Date> woScheduledDate = new Map<Id, Date>();
        Set<Id> ipIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();
        Map<Id, String> woSeriesMap = new Map<Id, String>();
        Set<String> series = new Set<String>();
        Set<String> sapTechIds = new Set<String>();

        // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();

        // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
        List<Group> longJobQueueRecord = [SELECT Id, Name, Type, DeveloperName FROM Group WHERE DeveloperName = 'AES_SMAX_PS_CRC_Queue' LIMIT 1];
        Id longJobQueueId = null;
        if (!longJobQueueRecord.isEmpty())
        {
            longJobQueueId = longJobQueueRecord[0].Id;
        }
        System.debug('longJobQueueRecord: ' + longJobQueueRecord.size() + ' ' + longJobQueueRecord);

        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            // Decoupling Date incase we want to change which field we use
            Date newDate = wo.SVMXC__Scheduled_Date__c;
            Date oldDate = (old == null) ? null : old.SVMXC__Scheduled_Date__c;
            // Status is Open & PerformAutoAssign is checked & Date in near future & Technician is blank & either IP or Series not blank
            if (wo.SMAX_PS_Perform_Auto_Assignment__c == true //&& newDate != null && newDate >= today && newDate <= nearFuture
                    // ITSVMX-801 4/26/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
//                  && wo.SVMXC__Order_Status__c == 'Open'
                    && (wo.SVMXC__Order_Status__c == 'Open' || (wo.SVMXC__Order_Status__c == 'Assigned' && old != null && old.RecordTypeId == estimateRTId))
//                  && wo.SVMXC__Group_Member__c == null
                    && (wo.SVMXC__Group_Member__c == null || (wo.SVMXC__Group_Member__c != null && old != null && old.RecordTypeId == estimateRTId))
                    //&& (wo.SVMXC__Component__c != null || wo.SMAX_PS_ProductSeries__c != null)
                    && (old == null
                    || wo.SMAX_PS_Perform_Auto_Assignment__c != old.SMAX_PS_Perform_Auto_Assignment__c
                    || wo.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c
                    || wo.SVMXC__Order_Status__c != old.SVMXC__Order_Status__c
                    || newDate != oldDate) )
            {
                if (wo.SMAX_PS_AutoAssignmentNotes__c == null)
                    wo.SMAX_PS_AutoAssignmentNotes__c = '';
                else
                        wo.SMAX_PS_AutoAssignmentNotes__c += '\n';
                wo.SMAX_PS_AutoAssignmentNotes__c += '* WO Auto-Assign Running...';
                wo.SMAX_PS_Perform_Auto_Assignment__c = FALSE;

                // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
                // ITSVMX-801 5/27/2022 Go ahead and Assign the Service Request WOs
//              if (wo.SVMX_PS_Is_Long_Job__c) {
                if (wo.SVMX_PS_Is_Long_Job__c && wo.RecordTypeId != estimateRTId) {

                    // Set the Owner to Long Job Queue
                    System.debug('longJobQueueId: ' + longJobQueueId);
                    if (longJobQueueId != null)
                    {
                        wo.OwnerId = longJobQueueId;
                    }

                    wo.SMAX_PS_AutoAssignmentNotes__c += ' Skip Auto Assignment as this is a Long Job and Assign to CRC Queue.';
                    System.debug('Skip Auto Assignment as this is a Long Job and Assign to CRC Queue.');
                    continue;
                }

                // 2023-02-06 Moved these lines down to after the "Long Job" logic so that we fully skip these WO
                wosToCheck.add(wo);
                woScheduledDate.put(wo.Id, newDate);

                // SVMXCFG-379 - Auto-Assign to SAP Work Center / Plant
                String sapTechId = getSAP_TechId(wo);
                if (sapTechId != null)
                {
                    sapTechIds.add(sapTechId);
                }

                if (wo.SVMXC__Component__c != null)
                {
                    ipIds.add(wo.SVMXC__Component__c);
                }
                else
                {
                    if (wo.SVMXC__Site__c != null)
                    {
                        locIds.add(wo.SVMXC__Site__c);
                    }
                    else
                    {
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' No IP or Location on Work Order.';
                    }

                    if (wo.SMAX_PS_ProductSeries__c != null)
                    {
                        series.add(wo.SMAX_PS_ProductSeries__c);
                        woSeriesMap.put(wo.Id, wo.SMAX_PS_ProductSeries__c);
                    }
                    else
                    {
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' No IP or Model Series on Work Order.';
                    }
                }
            }
        }

        List<Event> events = new List<Event>();

        // SVMXCFG-379 - Auto-Assign to SAP Work Center / Plant
        Map<String, SVMXC__Service_Group_Members__c> sapTechMap = new Map<String, SVMXC__Service_Group_Members__c>();
        if (!sapTechIds.isEmpty())
        {
            // SVMXCFG-856 Auto-Assign to SAP Work Center (only)
            //for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Salesforce_User__c,
            //  SVMXC__Zip__c, SVMXC__Service_Group__c, SVMXC__Active__c, SVMXC__Enable_Scheduling__c
            //  FROM SVMXC__Service_Group_Members__c WHERE SVMX_PS_External_ID__c IN :sapTechIds])
            //{
            //  sapTechMap.put(tech.SVMX_PS_External_ID__c, tech);
            //}
            for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SMAX_PS_Work_Center__c, SVMXC__Salesforce_User__c,
                    SVMXC__Zip__c, SVMXC__Service_Group__c, SVMXC__Active__c, SVMXC__Enable_Scheduling__c
            FROM SVMXC__Service_Group_Members__c WHERE SMAX_PS_Work_Center__c IN :sapTechIds])
            {
                sapTechMap.put(tech.SMAX_PS_Work_Center__c, tech);
            }

            for (SVMXC__Service_Order__c wo : wosToCheck)
            {
                String sapTechId = getSAP_TechId(wo);
                if (sapTechId != null)
                {
                    SVMXC__Service_Group_Members__c tech = sapTechMap.get(sapTechId);
                    if (tech != null)
                    {
                        // SVMXCFG-693 Only assign if "Active" & "Enable Scheduling"
                        if (tech.SVMXC__Active__c == FALSE || tech.SVMXC__Enable_Scheduling__c == FALSE)
                        {
                            wo.SMAX_PS_AutoAssignmentNotes__c += ' Skipped SAP Work Center Technician because not Active or Enabled for Scheduling.';
                        }
                        else
                        {
                            Date scheduledDate = woScheduledDate.get(wo.Id);

                            Event evt = assignTechnician(wo, tech, scheduledDate, null);
                            if (evt != null)
                                events.add(evt);
                            wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned to SAP Work Center Technician.';
                        }
                    }
                }
            }

            wosToCheck = filterAssigned(wosToCheck);
        }

        Map<Id, SVMXC__Installed_Product__c> ipMap = null;
        Map<Id, SVMXC__Site__c> locMap = null;
        if (!wosToCheck.isEmpty())
        {
            //Get all the Installed Products and the Default Tech Setting - put in Map
            if (!ipIds.isEmpty())
            {
//              ipMap = new Map<Id, SVMXC__Installed_Product__c>([Select Id,
//                      SVMXC__Preferred_Technician__c, SVMXC__Preferred_Technician__r.Name, SVMXC__Preferred_Technician__r.SVMXC__Service_Group__c,
//                      SVMXC__Preferred_Technician__r.SVMXC__Zip__c, SVMXC__Preferred_Technician__r.SVMXC__Salesforce_User__c,
//                      SVMXC__Preferred_Technician__r.SVMXC__Active__c, SVMXC__Preferred_Technician__r.SVMXC__Enable_Scheduling__c,
//                      SVMXC__Site__c, SVMXC__Site__r.SVMXC__Zip__c, SVMXC__Site__r.SMAX_PS_Geography__c,
//                      SVMXC__Product__c, SMAX_PS_ModelSeries__c
//              FROM SVMXC__Installed_Product__c where Id IN :ipIds]);

                //TODO JL future auto-assignment changes - adding IP WOs for Continuity/Bundle
                //ITSVMX-664 Added new field SMAX_PS_ModelSeries_2__c in select statement

                ipMap = new Map<Id, SVMXC__Installed_Product__c>([SELECT Id,
                        SVMXC__Preferred_Technician__c, SVMXC__Preferred_Technician__r.Name, SVMXC__Preferred_Technician__r.SVMXC__Service_Group__c,
                        SVMXC__Preferred_Technician__r.SVMXC__Zip__c, SVMXC__Preferred_Technician__r.SVMXC__Salesforce_User__c,
                        SVMXC__Preferred_Technician__r.SVMXC__Active__c, SVMXC__Preferred_Technician__r.SVMXC__Enable_Scheduling__c,
                        SVMXC__Site__c, SVMXC__Site__r.SVMXC__Zip__c, SVMXC__Site__r.SMAX_PS_Geography__c,
                        SVMXC__Product__c, SMAX_PS_ModelSeries__c, SMAX_PS_ModelSeries_2__c,
                (SELECT Id, SVMXC__Group_Member__c, SVMXC__Scheduled_Date__c FROM SVMXC__Service_Order_Component__r
                WHERE (SVMXC__Scheduled_Date__c = LAST_N_DAYS:365 OR SVMXC__Scheduled_Date__c > TODAY) ORDER BY SVMXC__Scheduled_Date__c DESC)
                FROM SVMXC__Installed_Product__c where Id IN :ipIds]);
            }

            if (!locIds.isEmpty())
            {
                locMap = new Map<Id, SVMXC__Site__c>([Select Id, SVMXC__Zip__c, SMAX_PS_Geography__c
                FROM SVMXC__Site__c where Id IN :locIds]);
            }
        }

        Set<Id> geoIds = new Set<Id>();
        Map<Id, Id> woGeoMap = new Map<Id, Id>();
        // Second pass.. try to assign to Preferred if possible.. else collect geo and skills
        for (SVMXC__Service_Order__c wo : wosToCheck)
        {
            Date scheduledDate = woScheduledDate.get(wo.Id);
            SVMXC__Installed_Product__c ip = (wo.SVMXC__Component__c != null && ipMap != null) ?
                    ipMap.get(wo.SVMXC__Component__c) : null;
            if (ip != null)
            {
                SVMXC__Service_Group_Members__c tech = (ip.SVMXC__Preferred_Technician__c != null) ? ip.SVMXC__Preferred_Technician__r : null;
                System.debug('ip.SVMXC__Preferred_Technician__c: ' + ip.SVMXC__Preferred_Technician__c);
                Boolean enabled = (tech != null && tech.SVMXC__Active__c == TRUE && tech.SVMXC__Enable_Scheduling__c == TRUE);
                System.debug('enabled: ' + enabled);
                // SVMXCFG-693 Only assign if "Active" & "Enable Scheduling"
                if (tech != null && !enabled)
                {
                    wo.SMAX_PS_AutoAssignmentNotes__c += ' Skipped IP Preferred Technician because not Active or Enabled for Scheduling.';
                }

                if (tech != null && enabled)
                {
                    Event evt = assignTechnician(wo, tech, scheduledDate, null);
                    if (evt != null)
                        events.add(evt);
                    wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned to IP Preferred Technician.';
                }
                else
                {
                    if (ip.SVMXC__Site__c != null && ip.SVMXC__Site__r.SMAX_PS_Geography__c != null)
                    {
                        geoIds.add(ip.SVMXC__Site__r.SMAX_PS_Geography__c);
                        woGeoMap.put(wo.Id, ip.SVMXC__Site__r.SMAX_PS_Geography__c);
                    }
                    else
                    {
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' No IP Location / Geography Found.';
                    }
// ITSVMX-664 Replace with SMAX_PS_ModelSeries__c with SMAX_PS_ModelSeries_2__c
                    if (ip.SMAX_PS_ModelSeries_2__c != null)
                    {
                        series.add(ip.SMAX_PS_ModelSeries_2__c);
                        woSeriesMap.put(wo.Id, ip.SMAX_PS_ModelSeries_2__c);
                    }
                    else
                    {
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' No Model Series (Skill) Found on the IP.';
                    }
                }
            }
            else
            {
                SVMXC__Site__c loc = (locMap != null && wo.SVMXC__Site__c != null) ?
                        locMap.get(wo.SVMXC__Site__c) : null;
                if (loc != null && loc.SMAX_PS_Geography__c != null)
                {
                    geoIds.add(loc.SMAX_PS_Geography__c);
                    woGeoMap.put(wo.Id, loc.SMAX_PS_Geography__c);
                }
                else
                {
                    wo.SMAX_PS_AutoAssignmentNotes__c += ' No Location / Geography Found.';
                }
            }
        }

        wosToCheck = filterAssigned(wosToCheck);

        // ITSVMX-282 Do not allow Geography / Skills matching for Enterprise
        wosToCheck = filterEnterprise(wosToCheck);

        Set<Id> techIds = new Set<Id>();
        Set<Id> techUserIds = new Set<Id>();
        Map<Id, List<SMAX_PS_Geography_Technician__c>> geoTechMap = new Map<Id, List<SMAX_PS_Geography_Technician__c>>();
        Map<Id, SVMXC__Service_Group_Members__c> techMap = null;
        if (!wosToCheck.isEmpty())
        {
            // Get all the Geo-Technicians by Geography
            for (SMAX_PS_Geography_Technician__c geoTech : [SELECT Id, SMAX_PS_Geography__c, SMAX_PS_Technician__c, SMAX_PS_Rank__c
            FROM SMAX_PS_Geography_Technician__c WHERE SMAX_PS_Geography__c IN :geoIds ORDER BY SMAX_PS_Rank__c])
            {
                if (!geoTechMap.containsKey(geoTech.SMAX_PS_Geography__c))
                    geoTechMap.put(geoTech.SMAX_PS_Geography__c, new List<SMAX_PS_Geography_Technician__c>());
                geoTechMap.get(geoTech.SMAX_PS_Geography__c).add(geoTech);

                techIds.add(geoTech.SMAX_PS_Technician__c);
            }

            // Get all the Technicians and (relevant) Expertise
            // SVMXCFG-693 Filter the NON "Active" & "Enable Scheduling"
            techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
            [SELECT Id, Name, SVMXC__Salesforce_User__c, SVMXC__Zip__c, SVMXC__Service_Group__c,
                    SVMXC__Service_Group__r.SMAX_PS_Is_Enterprise__c, SVMXC__Latitude_Home__c, SVMXC__Longitude_Home__c,
                    SVMXC__Working_Hours__c, SVMXC__Working_Hours__r.MondayStartTime, SVMXC__Working_Hours__r.MondayEndTime,
                    SVMXC__Working_Hours__r.TuesdayStartTime, SVMXC__Working_Hours__r.TuesdayEndTime,
                    SVMXC__Working_Hours__r.WednesdayStartTime, SVMXC__Working_Hours__r.WednesdayEndTime,
                    SVMXC__Working_Hours__r.ThursdayStartTime, SVMXC__Working_Hours__r.ThursdayEndTime,
                    SVMXC__Working_Hours__r.FridayStartTime, SVMXC__Working_Hours__r.FridayEndTime,
                    SVMXC__Working_Hours__r.SaturdayStartTime, SVMXC__Working_Hours__r.SaturdayEndTime,
                    SVMXC__Working_Hours__r.SundayStartTime, SVMXC__Working_Hours__r.SundayEndTime,
                    SMAX_PS_Owned_By_Company__c,
            (SELECT Id, SVMXC__Skill__c, SVMXC__Skill__r.Name, SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c, SVMXC__Skill_Level__c
            FROM SVMXC__Service_Group_Skills__r WHERE SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c IN :series
            ORDER BY SVMXC__Skill_Level__c DESC)
            FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds AND SVMXC__Active__c = TRUE AND SVMXC__Enable_Scheduling__c = TRUE]);

            System.debug('update? ' + Trigger.isUpdate);
            System.debug('Techs to consider: ' + techMap);
            for(SVMXC__Service_Group_Members__c schedTech:techMap.values())
            {
                techUserIds.add(schedTech.SVMXC__Salesforce_User__c);
            }


        }

        Map<Id, Map<Date, List<Event>>> userToDateToEvtList = new Map<Id,Map<Date,List<Event>>>();
        //add all techs to Map first, bc they may not have events to query
        for(Id techUser:techUserIds)
        {
            Map<Date,List<Event>> newDateToEvtList = new Map<Date,List<Event>>();
            userToDateToEvtList.put(techUser, newDateToEvtList);
        }
        List<Event> evtToCheck = [SELECT Id, Subject, ActivityDate, OwnerId
        FROM Event WHERE OwnerId IN :techUserIds AND ActivityDate IN :woScheduledDate.values()];

        for(Event evt:evtToCheck)
        {
//          if(!userToDateToEvtList.containsKey(evt.OwnerId))
//          {
//              Map<Date,List<Event>> newDateToEvtList = new Map<Date,List<Event>>();
//              userToDateToEvtList.put(evt.OwnerId, newDateToEvtList);
//          }

            Map<Date, List<Event>> dateToEvtList = userToDateToEvtList.get(evt.OwnerId);

            if(!dateToEvtList.containsKey(evt.ActivityDate))
            {
                List<Event> newEvtList = new List<Event>();
                dateToEvtList.put(evt.ActivityDate, newEvtList);
            }

            List<Event> evtList = dateToEvtList.get(evt.ActivityDate);
            evtList.add(evt);

        }

        SMAX_PS_Assignment_Policy__mdt policy = [SELECT Id, MasterLabel, SMAX_PS_Availability__c, SMAX_PS_Bundling__c, SMAX_PS_Continuity__c,
                SMAX_PS_Expertise__c, SMAX_PS_Proximity__c
        FROM SMAX_PS_Assignment_Policy__mdt WHERE SMAX_PS_Auto_Assignment_Default__c = true];

        SMAX_PS_Assignment_Settings__c setting = SMAX_PS_Assignment_Settings__c.getOrgDefaults();



        // Third pass.. try to assign based on geo and skill
        for (SVMXC__Service_Order__c wo : wosToCheck)
        {

            Date scheduledDate = woScheduledDate.get(wo.Id);
            //if (scheduledDate < Date.today().addDays(14))
            //{
            //    wo.SMAX_PS_AutoAssignmentNotes__c += ' WO within next 2 weeks. Stopped processing.';
            //    continue;
            //}

            Id geoId = woGeoMap.get(wo.Id);
            if (geoId == null)
            {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Cannot perform auto-assignment without Geography.';
                continue;
            }

            List<SMAX_PS_Geography_Technician__c> geoTechs = geoTechMap.get(geoId);
            if (geoTechs == null || geoTechs.isEmpty())
            {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Cannot perform auto-assignment without Geography-Technicians for Geography: ' + geoId;
                continue;
            }

            // SVMXCFG-693 Do not assign by Geo Only.. no "Model Series", no assignment..
            String modelSeries = woSeriesMap.get(wo.Id);
            if (modelSeries == null)
            {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Cannot perform auto-assignment without IP Skill.';
                continue;
            }

            if(setting != null && setting.SMAX_PS_Use_Assignment_Policy__c)
            {
                List<SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper> techWrappers = SMAX_PS_AutoAssignmentObjectives.doAutoAssignment(wo, policy, true).values();
                //sort wrappers to find most qualified tech
                SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper highScoreTech;
                for(SMAX_PS_AutoAssignmentObjectives.AssignTechWrapper wrapperToCheck:techwrappers)
                {
                    if(highScoreTech == null || wrapperToCheck.totalScore > highScoreTech.totalscore)
                    {
                        highScoreTech = wrapperToCheck;
                    }
                }


                SVMXC__Service_Group_Members__c techToAssign = techMap.get(highScoreTech.techId);

                for (SVMXC__Service_Group_Skills__c expertise : techToAssign.SVMXC__Service_Group_Skills__r)
                {
                    String skillName = expertise.SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c;
                    if (skillName != null && skillName.equalsIgnoreCase(modelSeries))
                    {
                        Event evt = assignTechnician(wo, techToAssign, scheduledDate, expertise);
                        if (evt != null)
                            events.add(evt);
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' Auto-assigned using the ' + policy.MasterLabel + ' Assignment Policy';
                        break;
                    }
                }
            }
            else
            {
                //existing logic in this else statement
                for (SMAX_PS_Geography_Technician__c geoTech : geoTechs)
                {
                    SVMXC__Service_Group_Members__c tech = techMap.get(geoTech.SMAX_PS_Technician__c);
                    if (tech == null)
                        continue;

                    if (tech.SVMXC__Service_Group__r.SMAX_PS_Is_Enterprise__c != wo.SMAX_PS_Is_Enterprise__c)
                    {
                        // SVMXCFG-693 Only assign if WO & ServiceTeam "Is Enterprise" match
                        continue;
                    }

                    // 2023-02-08 Adding Polaris OwnedByCompany into Auto-Assign check
                    if (tech.SMAX_PS_Owned_By_Company__c != wo.SMAX_PS_Owned_By_Company__c) {
                        wo.SMAX_PS_AutoAssignmentNotes__c += ' Skipping Tech due to OwnedByCompany: ' + tech.Name;
                        continue;
                    }

                    //if (modelSeries == null)
                    //{
                    //  // Bypass Skill check.. assign to first Technician
                    //  Event evt = assignTechnician(wo, tech, scheduledDate, null);
                    //  if (evt != null)
                    //      events.add(evt);
                    //  wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned to closest Technician, no Skill check.';
                    //  break;
                    //}

                    for (SVMXC__Service_Group_Skills__c expertise : tech.SVMXC__Service_Group_Skills__r)
                    {
                        String skillName = expertise.SVMXC__Skill__r.SVMX_PS_Skill_External_ID__c;
                        if (skillName != null && skillName.equalsIgnoreCase(modelSeries))
                        {
                            Event evt = assignTechnician(wo, tech, scheduledDate, expertise);
                            if (evt != null)
                                events.add(evt);
                            wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned to closest Technician, with matching Skill: ' + modelSeries;
                            break;
                        }
                    }

                    if (wo.SVMXC__Group_Member__c != null)
                        break;  // Exit for "geoTechs"

                }
            }





            if (wo.SVMXC__Group_Member__c == null)
            {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Could not find a matching Technician for Geography: ' + geoId + ' and Skill: ' + modelSeries;
                continue;
            }
        }

        if (!events.isEmpty())
            insert events;

        // NOTE: Could add a trim function to wo.SMAX_PS_AutoAssignmentNotes__c if necessary
    }

    private static List<SVMXC__Service_Order__c> filterAssigned(List<SVMXC__Service_Order__c> woList)
    {
        List<SVMXC__Service_Order__c> result = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.SVMXC__Group_Member__c == null)
                result.add(wo);
        }
        return result;
    }

    @testVisible
    private static List<SVMXC__Service_Order__c> filterLongJobs(List<SVMXC__Service_Order__c> woList)
    {
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        List<SVMXC__Service_Order__c> result = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.SVMX_PS_Is_Long_Job__c && wo.RecordTypeId != estimateRTId)
                result.add(wo);
        }
        return result;
    }

    // ITSVMX-282 Do not allow Geography / Skills matching for Enterprise
    private static List<SVMXC__Service_Order__c> filterEnterprise(List<SVMXC__Service_Order__c> woList)
    {
        List<SVMXC__Service_Order__c> result = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList) {
            if (wo.SMAX_PS_Is_Enterprise__c == true) {
                wo.SMAX_PS_AutoAssignmentNotes__c += ' Skipping match by Geography and Skill for Enterprise.';
            } else {
                result.add(wo);
            }
        }
        return result;
    }

    private static Set<String> IGNORE_WORK_CENTERS = new Set<String> { 'SCHEDULE', 'OS_SCHED' };

    private static String getSAP_TechId(SVMXC__Service_Order__c wo)
    {
        // SVMXCFG-856 Auto-Assign to SAP Work Center (only)
        if (String.isNotBlank(wo.SMAX_PS_SAP_Work_Center__c))// && String.isNotBlank(wo.SMAX_PS_SAP_Maintenance_Plant__c))
        {
            if (IGNORE_WORK_CENTERS.contains(wo.SMAX_PS_SAP_Work_Center__c.toUpperCase()))
                return null;

            //return wo.SMAX_PS_SAP_Maintenance_Plant__c + wo.SMAX_PS_SAP_Work_Center__c;
            return wo.SMAX_PS_SAP_Work_Center__c;
        }
        return null;
    }

    // ITSFDC-1099 5/14/2020 Estimates: calendar event not created when the FSE creates the estimate
    // updated to allow for events to be created after the record is Inserted
    public static Event assignTechnician(SVMXC__Service_Order__c wo, SVMXC__Service_Group_Members__c tech, Date d, SVMXC__Service_Group_Skills__c expertise)
    {
        // Added to prevent recursive update of WO from new Event
        WO_IDS_SYNCHRONIZED.add(wo.Id);

        Event evt = null;
        wo.SVMXC__Group_Member__c = tech.Id;
        wo.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        if (tech.SVMXC__Salesforce_User__c != null)
            wo.OwnerId = tech.SVMXC__Salesforce_User__c;
        wo.SVMXC__Order_Status__c = 'Assigned';
        System.debug('Setting SVMXC__Order_Status__c to Assigned');
        wo.SMAX_PS_Tech_Expertise__c = (expertise == null) ? null : expertise.Id;
        if (d == null)
            d = Date.today();
        Datetime startTime = Datetime.newInstance(d.year(), d.month(), d.day(), 9, 0, 0);
        // TODO: Shift timezone...
         // commenting below SVMXC__Scheduled_Date_Time__c assignment line for INC0107508, Pankaj B
        //wo.SVMXC__Scheduled_Date_Time__c = startTime;

        // Event on the Calendar?
//      Event evt = null;
        if (tech.SVMXC__Salesforce_User__c != null)
        {
            if (wo.Id == null)
            {
                wo.BD_Create_Event_After_Insert__c = true;
                System.debug('BD_Create_Event_After_Insert__c = true');
            }
            else
            {
                // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
                Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
                // ITSVMX-35 6/24/2020 Tony Check to make sure Event has not already been created for this Tech
                List<Event> currentEvents = new List<Event>([SELECT Id, Subject, OwnerId FROM Event WHERE WhatId = :wo.Id AND OwnerId = :tech.SVMXC__Salesforce_User__c]);
                System.debug('currentEvents: ' + currentEvents);
                // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
//              if (currentEvents == null || currentEvents.size() == 0)
                if ((currentEvents == null || currentEvents.size() == 0) && wo.RecordTypeId != estimateRTId)
                {
                    System.debug('Creating Event');
                    evt = createEvent(wo, tech);

                    // 8/11/20 ITSVMX-70 tony - Update the "Scheduled Duration" on the WO based on Event Start / End Times
                    if(evt != null){
                        setDurations(wo, evt.StartDateTime.getTime(), evt.EndDateTime.getTime());
                    }
                } else
                {
                    System.debug('Event already exists where the OwnerId == tech.SVMXC__Salesforce_User__c OR This is a Service Request work order');
                }
            }
        }
        System.debug('evt: ' + evt);
        return evt;
    }

    // 6/14/2021 for GetCandidates LWC assignment, need to send in a datetime instead of a date
    public static Event assignTechnician(SVMXC__Service_Order__c wo, SVMXC__Service_Group_Members__c tech, Datetime dt, Id expId)
    {
        // Added to prevent recursive update of WO from new Event
        WO_IDS_SYNCHRONIZED.add(wo.Id);
        wo.SVMXC__Group_Member__c = tech.Id;
        wo.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        if (tech.SVMXC__Salesforce_User__c != null)
            wo.OwnerId = tech.SVMXC__Salesforce_User__c;
        wo.SVMXC__Order_Status__c = 'Assigned';
        wo.SMAX_PS_Tech_Expertise__c = (expId == null) ? null : expId;
//      if (d == null)
//          d = Date.today();
//      Datetime startTime = Datetime.newInstance(d.year(), d.month(), d.day(), 9, 0, 0);
		// commenting below SVMXC__Scheduled_Date_Time__c assignment line for INC0107508
        //wo.SVMXC__Scheduled_Date_Time__c = dt;
        wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned using Get Candidates on Work Order';
        // Event on the Calendar?
        Event evt = null;
        if (tech.SVMXC__Salesforce_User__c != null)
        {
            if (wo.Id == null)
            {
                wo.BD_Create_Event_After_Insert__c = true;
            }
            else
            {

                // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
                Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
                // ITSVMX-35 6/24/2020 Tony Check to make sure Event has not already been created for this Tech
                List<Event> currentEvents = new List<Event>([SELECT Id, Subject, OwnerId FROM Event WHERE WhatId = :wo.Id AND OwnerId = :tech.SVMXC__Salesforce_User__c]);
                System.debug('currentEvents: ' + currentEvents);
                // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
//              if (currentEvents == null || currentEvents.size() == 0)
                if ((currentEvents == null || currentEvents.size() == 0) && wo.RecordTypeId != estimateRTId)
                {
                    System.debug('Creating Event');
                    evt = createEvent(wo, tech);

                    // 8/11/20 ITSVMX-70 tony - Update the "Scheduled Duration" on the WO based on Event Start / End Times
                    if(evt != null){
                        setDurations(wo, evt.StartDateTime.getTime(), evt.EndDateTime.getTime());
                    }
                } else
                {
                    System.debug('Event already exists where the OwnerId == tech.SVMXC__Salesforce_User__c OR This is a Service Request work order');
                }
            }
        }
        System.debug('WO Update next: ' + wo.SVMXC__Group_Member__c);
        update wo;
        return evt;
    }

    // ITSFDC-1099 5/14/2020 Estimates: calendar event not created when the FSE creates the estimate
    // updated to allow for events to be created after the record is Inserted
    public static void createEventsAfterInsert(List<SVMXC__Service_Order__c> woList)
    {
        Set<Id> techIds = new Set<Id>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.BD_Create_Event_After_Insert__c == true && wo.SVMXC__Group_Member__c != null)
            {
                techIds.add(wo.SVMXC__Group_Member__c);
            }
        }
        if (techIds.isEmpty()) {
            return;
        }
        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
                [SELECT Id, Name, SVMXC__Salesforce_User__c FROM SVMXC__Service_Group_Members__c]);
        List<Event> eventList = new List<Event>();

        // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.BD_Create_Event_After_Insert__c == true && wo.SVMXC__Group_Member__c != null)
            {
                SVMXC__Service_Group_Members__c tech = techMap.get(wo.SVMXC__Group_Member__c);

                // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
//              if (tech != null && tech.SVMXC__Salesforce_User__c != null)
                if (tech != null && tech.SVMXC__Salesforce_User__c != null && wo.RecordTypeId != estimateRTId)
                {
                    Event evt = createEvent(wo, tech);
                    eventList.add(evt);
                }
            }
        }
        if (!eventList.isEmpty()) {
            insert eventList;
        }
    }

    // ITSFDC-1099 5/14/2020 Estimates: calendar event not created when the FSE creates the estimate
    // moved code outside of the assignTechnician method
    private static Event createEvent(SVMXC__Service_Order__c wo, SVMXC__Service_Group_Members__c tech)
    {
        //return if wo.SVMXC__Scheduled_Date_Time__c is null, 19 Feb, 2026. Pankaj B
        if(wo.SVMXC__Scheduled_Date_Time__c == null){
            return null;
        }
        // 3/29/22 Tony ITSVMX-801 Error when attempt to accept WO from queue
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        Event evt = new Event();
        evt.WhatId=wo.Id;
        evt.StartDateTime = wo.SVMXC__Scheduled_Date_Time__c;
        evt.SVMXC__Driving_Time__c = 60; // Default all to 1 Hour of Drive Time
        // ITSVMX-606: Changing Scheduled Duration field
        if (wo.SMAX_PS_Scheduled_Duration_Hours__c == null || wo.SMAX_PS_Scheduled_Duration_Hours__c == 0)
        {
            evt.EndDateTime = evt.StartDateTime.addHours(3);
        }
        // ITSVMX-801 4/26/2022 Removed as the requirment changed to no longer create events for Service Request work orders
//      // 3/29/22 Tony ITSVMX-801 Error when attempt to accept WO from queue  Estimate = Service Request
//      else if (wo.RecordTypeId == estimateRTId && wo.SVMXC__SM_Scheduling_Options__c == 'JDM and LJS Enabled')
//      {
//          System.debug('Since this is an Estimate WO that is LJS, setting EndDateTime to StartDateTime + 30 mins.');
//          evt.EndDateTime = evt.StartDateTime.addMinutes(30);
//          evt.SVMXC__Driving_Time__c = 0; // There is no Drive Time for Estimate WOs
//          // Unsetting this value as ServiceMax code will keep the event from being created if we don't have all the matching fields on the work order
//          evt.WhatId = null;
//      }
        else
        {
            Integer minutes = (wo.SMAX_PS_Scheduled_Duration_Hours__c * 60).round().intValue();
            evt.EndDateTime = evt.StartDateTime.addMinutes(minutes);
        }

        evt.Subject=wo.Name + ';' + wo.SVMXC__Billing_Type__c + ';' + wo.SVMXC__Order_Type__c + ';' + wo.SVMX_PS_Problem_Summary__c;
        if(evt.Subject.length() > 255) evt.Subject = evt.Subject.substring(0, 252) + '...';
        evt.OwnerId=tech.SVMXC__Salesforce_User__c;
//      evt.WhatId=wo.Id;
        // 6/2/2022 Tony ITSVMX-862 To fix error being thrown by ServiceMax validation rule we need to add the Driving Time to the EndDateTime
        evt.EndDateTime = evt.EndDateTime.addMinutes(evt.SVMXC__Driving_Time__c.intValue());
        return evt;
    }


    /**
     *  Finishes Assignment when custom is logic is used to partially assign.
     *  Should be called from BEFORE UPDATE
     */
    public static void finishAssignment(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        RecordType pendingRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Enterprise_Pending_IP');
        if (pendingRT == null)
            return;

        Set<Id> techIds = new Set<Id>();
        List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (wo.RecordTypeId == pendingRT.Id && wo.SVMXC__Group_Member__c != null
                    && (old == null || wo.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c))
            {
                // SVMXCFG-682 Found one to update.. assign Owner
                wosToUpdate.add(wo);
                techIds.add(wo.SVMXC__Group_Member__c);
            }
        }

        if (techIds.isEmpty())
            return;

        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
        [SELECT Id, Name, SVMXC__Salesforce_User__c
        FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);
        for (SVMXC__Service_Order__c wo : wosToUpdate)
        {
            SVMXC__Service_Group_Members__c tech = techMap.get(wo.SVMXC__Group_Member__c);
            if (tech != null && tech.SVMXC__Salesforce_User__c != null)
            {
                System.debug(' tech.SVMXC__Salesforce_User__c : '+tech.SVMXC__Salesforce_User__c);
                wo.OwnerId = tech.SVMXC__Salesforce_User__c;
            }
        }
    }

    /**
        Synchronization of Work Order Scheduled Datetime / Duration to Event Start / End Datetimes
     */

    private static Set<Id> WO_IDS_SYNCHRONIZED = new Set<Id>();

    // SHOULD ONLY BE USED IN UNIT TESTS TO CLEAR STATIC VALUES
    public static void clearSynchronizedList()
    {
        WO_IDS_SYNCHRONIZED.clear();
    }

    /**
     * Build-Card: BC-05272
     * When the WO "Scheduled Datetime" is changed, update the corresponding Calendar Event Start Time
     */
    public static void confirmScheduling(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        Set<Id> techIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        Map<Id, SVMXC__Service_Order__c> woToReschedule = new Map<Id, SVMXC__Service_Order__c>();
        Map<Id, SVMXC__Service_Order__c> woToSync = new Map<Id, SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            // ITSVMX-776 Long Job Scheduling - Scheduling status not updated in Long Jobs
            // Commented out to allow work order Scheduling Status to be updated on Long Job events
            // ITSVMX-226 Skip Long Job Scheduling
//          if (wo.SVMXC__SM_Scheduling_Options__c == 'JDM and LJS Enabled') {
//              continue;
//          }

            // ITSVMX-606: Changing Scheduled Duration field
            if (old != null && wo.SVMXC__Scheduled_Date_Time__c != null
                    && old.SVMXC__Scheduled_Date_Time__c != null
                    && (wo.SVMXC__Scheduled_Date_Time__c != old.SVMXC__Scheduled_Date_Time__c
                    || wo.SMAX_PS_Scheduled_Duration_Hours__c != old.SMAX_PS_Scheduled_Duration_Hours__c
                    || wo.SVMXC__Work_Order_Scheduling_Status__c != old.SVMXC__Work_Order_Scheduling_Status__c)
                    && wo.SVMXC__Group_Member__c != null)
            {
                if (WO_IDS_SYNCHRONIZED.contains(wo.Id))
                    continue;

                WO_IDS_SYNCHRONIZED.add(wo.Id);
                woIds.add(wo.Id);
                if (wo.SVMXC__Scheduled_Date_Time__c != old.SVMXC__Scheduled_Date_Time__c
                        || wo.SMAX_PS_Scheduled_Duration_Hours__c != old.SMAX_PS_Scheduled_Duration_Hours__c)
                {
                    // ITSVMX-776 Long Job Scheduling - Scheduling status not updated in Long Jobs
                    // We don't want to reschedule all the Long Job events to the same Date/Time or Duration
                    if (wo.SVMXC__SM_Scheduling_Options__c != 'JDM and LJS Enabled')
                    {
                        woToReschedule.put(wo.Id, wo);
                    }
                }
                if (wo.SVMXC__Work_Order_Scheduling_Status__c != old.SVMXC__Work_Order_Scheduling_Status__c)
                {
                    woToSync.put(wo.Id, wo);
                }
                techIds.add(wo.SVMXC__Group_Member__c);
            }
        }

        if (woIds.isEmpty())
        {
            return;
        }

        // SVMXCFG-1075 WO with multiple Event assignments - Only change assigned Technician's events
        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>(
        [SELECT Id, Name, SVMXC__Salesforce_User__c, SVMXC__Salesforce_User__r.IsActive
        FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);
        Set<Id> userIds = new Set<Id>();
        for (SVMXC__Service_Group_Members__c tech : techMap.values())
        {
            if (tech.SVMXC__Salesforce_User__c != null && tech.SVMXC__Salesforce_User__r.IsActive)
            {
                userIds.add(tech.SVMXC__Salesforce_User__c);
            }
        }

        if (userIds.isEmpty())
        {
            return; // No User Ids for Events anyway.. exit
        }

        System.debug('AUTO-SCHED: Trying to reschedule WO Events: ' + woToReschedule.keySet());
        Map<Id, Event> eventsToUpdate = new Map<Id, Event>();
        // ITSVMX-269: Load all Event fields needed for Description & Subject here
        for (Event evt : [SELECT Id, StartDateTime, WhatId, OwnerId,
                Description, Subject, SMAX_PS_Scheduling_status__c,
                SMAX_PS_Work_Order_Number__c, SMAX_PS_Work_Order_Record_Type__c, SMAX_PS_Billing_Type__c,
                SMAX_PS_Order_Type__c, SMAX_PS_Escalation_Justification__c, SMAX_PS_Instrument__c,
                SMAX_PS_Company__c, SMAX_PS_Contact_Name__c, SMAX_PS_Contact_Phone__c,
                SMAX_PS_SAP_ActivityType__c, SMAX_PS_Product__c, SMAX_PS_Location__c, SVMXC_City__c, SVMXC_Zip_Code__c
        FROM Event WHERE WhatId IN :woIds AND OwnerId IN :userIds])
        {
            Id woId = evt.WhatId;
            if (woToReschedule.containsKey(woId))
            {
                SVMXC__Service_Order__c wo = woToReschedule.get(woId);
                SVMXC__Service_Order__c old = oldMap.get(woId);
                SVMXC__Service_Group_Members__c tech = techMap.get(wo.SVMXC__Group_Member__c);
                Id userId = tech.SVMXC__Salesforce_User__c;

                if (userId != null && userId == evt.OwnerId
                        && old.SVMXC__Scheduled_Date_Time__c == evt.StartDateTime)
                {
                    evt.StartDateTime = wo.SVMXC__Scheduled_Date_Time__c;
                    if (wo.SMAX_PS_Scheduled_Duration_Hours__c != null)
                    {
                        Integer minutes = (wo.SMAX_PS_Scheduled_Duration_Hours__c * 60).round().intValue();
                        evt.EndDateTime = wo.SVMXC__Scheduled_Date_Time__c.addMinutes(minutes);
                    }
                    eventsToUpdate.put(evt.Id, evt);
                }
            }
            if (woToSync.containsKey(woId))
            {
                SVMXC__Service_Order__c wo = woToSync.get(woId);
                evt.SMAX_PS_Scheduling_status__c = wo.SVMXC__Work_Order_Scheduling_Status__c;
                evt.SMAX_PS_Escalation_Justification__c = wo.SMAX_PS_Justify_Reason__c;
                // ITSVMX-269 Sync the Subject & Description when Scheduling Status changes
                syncEventDescSubject(evt);
                eventsToUpdate.put(evt.Id, evt);
            }
        }

        if (!eventsToUpdate.isEmpty())
        {
            update eventsToUpdate.values();
        }
    }

    /**
     * SVMXCFG-151 : When Events are rescheduled, update the associated Work Order (if applicable)
     */
    public static void schedulingConfirm(List<Event> eventList, Map<Id, Event> oldMap)
    {
        List<Event> woEvents = new List<Event>();
        Set<Id> woIds = new Set<Id>();
        String woPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
        for (Event e : eventList)
        {
            Event oldE = (oldMap == null) ? null : oldMap.get(e.Id);
            if (e.WhatId != null && ((String)e.WhatId).startsWith(woPrefix) &&
                    (oldE == null || e.StartDateTime != oldE.StartDateTime || e.EndDateTime != oldE.EndDateTime))
            {
                Id woId = e.WhatId;
                if (WO_IDS_SYNCHRONIZED.contains(woId))
                    continue;

                WO_IDS_SYNCHRONIZED.add(woId);
                woEvents.add(e);
                woIds.add(woId);
            }
        }

        if (woIds.isEmpty())
            return;

        // ITSVMX-606: Changing Scheduled Duration field
        System.debug('AUTO-SCHED: Trying to reschedule WOs from Events: ' + woIds);
        List<SVMXC__Service_Order__c> wosToUpdate = new List<SVMXC__Service_Order__c>();
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name,
                SVMXC__Scheduled_Date_Time__c, SMAX_PS_Scheduled_Duration_Hours__c, SVMXC__Service_Duration__c,
                SVMXC__SM_Estimated_Duration__c, SVMXC__SM_Scheduling_Options__c
        FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
        for (Event e : woEvents)
        {
            Id woId = e.WhatId;
            SVMXC__Service_Order__c wo = woMap.get(woId);

            // 8/24/21 Tony ITSVMX-226 - Excluding this code as it is causing WOs to be updated with the wrong values when LJS is active
            if (wo.SVMXC__SM_Scheduling_Options__c != 'JDM and LJS Enabled')
            {
                wo.SVMXC__Scheduled_Date_Time__c = e.StartDateTime;

                // 8/11/20 ITSVMX-70 tony - Update the "Scheduled Duration" on the WO based on Event Start / End Times
                //wo.SVMXC__SM_Scheduled_Duration__c = scheduledDuration(e.StartDateTime.getTime(), e.EndDateTime.getTime());
                setDurations(wo, e.StartDateTime.getTime(), e.EndDateTime.getTime());

                wosToUpdate.add(wo);
                System.debug('AUTO-SCHED: Rescheduled WO from Event: ' + wo);
            }
        }

        if (!wosToUpdate.isEmpty())
            update wosToUpdate;
    }

    // SVMXCFG-723 - 09/05/18 - Add WO data to Calendar Events
    public static void syncEventFields(List<Event> eventList)
    {
        List<Event> woEvents = new List<Event>();
        Set<Id> woIds = new Set<Id>();
        String woPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
        for (Event e : eventList)
        {
            //Event oldE = (oldMap == null) ? null : oldMap.get(e.Id);
            if (e.WhatId != null && ((String)e.WhatId).startsWith(woPrefix))
            {
                Id woId = e.WhatId;
                woEvents.add(e);
                woIds.add(woId);
            }
        }

        if (woIds.isEmpty())
            return;

        // IT-SVMX-264 & IT-SVMX-269: Added "Scheduling Status" through "Account Zip Code", and updates to Description and Subject
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
        [SELECT Id, Name, SVMXC__Company__c, SVMXC__Company__r.Name, SMAX_PS_ContactName__c, SVMX_PS_Contact_Phone__c,
                SVMXC__Order_Type__c, SVMXC__Component__c, SVMXC__Component__r.Name,
                RecordType.Name, SVMXC__Billing_Type__c, SVMX_PS_Problem_Summary__c,
                SVMXC__Work_Order_Scheduling_Status__c, BD_Record_Type_formula__c,
                SMAX_PS_SAP_ActivityType__c, SMAX_PS_Justify_Reason__c,
                SVMXC__Product__c, SVMXC__Product__r.Name, SVMXC__Site__c, SVMXC__Site__r.Name,
                SVMXC__City__c, SMAX_PS_Account_Zip_Code__c
        FROM SVMXC__Service_Order__c
        WHERE Id IN :woIds]);

        for (Event e : woEvents)
        {
            Id woId = e.WhatId;
            SVMXC__Service_Order__c wo = woMap.get(woId);
            e.SMAX_PS_Company__c = (wo.SVMXC__Company__c == null) ? '' : wo.SVMXC__Company__r.Name;
            e.SMAX_PS_Contact_Name__c = wo.SMAX_PS_ContactName__c;
            e.SMAX_PS_Contact_Phone__c = wo.SVMX_PS_Contact_Phone__c;
            e.SMAX_PS_Order_Type__c = wo.SVMXC__Order_Type__c;
            e.SMAX_PS_Instrument__c = (wo.SVMXC__Component__c == null) ? '' : wo.SVMXC__Component__r.Name;
            e.SMAX_PS_Work_Order_Number__c = wo.Name;
            e.SMAX_PS_Scheduling_status__c = wo.SVMXC__Work_Order_Scheduling_Status__c;
            e.SMAX_PS_Billing_Type__c = wo.SVMXC__Billing_Type__c;
            //e.SMAX_PS_Work_Order_Record_Type__c = wo.RecordType.Name;
            e.SMAX_PS_Work_Order_Record_Type__c = wo.BD_Record_Type_formula__c;
            e.SMAX_PS_Escalation_Justification__c = wo.SMAX_PS_Justify_Reason__c;
            e.SVMXC_City__c = wo.SVMXC__City__c;
            e.SVMXC_Zip_Code__c = wo.SMAX_PS_Account_Zip_Code__c;
            e.SMAX_PS_Product__c = (wo.SVMXC__Product__c == null) ? '' : wo.SVMXC__Product__r.Name;
            e.SMAX_PS_Location__c = (wo.SVMXC__Site__c == null) ? '' : wo.SVMXC__Site__r.Name;
            e.SMAX_PS_SAP_ActivityType__c = wo.SMAX_PS_SAP_ActivityType__c;
            syncEventDescSubject(e);
        }
    }

    // IT-SVMX-264 & IT-SVMX-269: Refactored into a separate method so we can reuse from "confirmScheduling" also
    private static void syncEventDescSubject(Event e)
    {
        e.Description = 'Sched Status:' + blankNull(e.SMAX_PS_Scheduling_status__c, '')
                + '\n' + 'Work Order Number: ' + blankNull(e.SMAX_PS_Work_Order_Number__c, '')
                + '\n' + 'Record Type:'  + blankNull(e.SMAX_PS_Work_Order_Record_Type__c, '')
                + '\n' + 'Billing Type:' +  blankNull(e.SMAX_PS_Billing_Type__c, '')
                + '\n' + 'Order Type: ' + blankNull(e.SMAX_PS_Order_Type__c, '')
                + '\n' + 'Escalation Justification: ' + blankNull(e.SMAX_PS_Escalation_Justification__c, '')
                + '\n' + 'Instrument: ' + blankNull(e.SMAX_PS_Instrument__c, '')
                + '\n' + 'Account: ' + blankNull(e.SMAX_PS_Company__c, '')
                + '\n' + 'City: ' + blankNull(e.SVMXC_City__c, '')
                + '\n' + 'Zip: '  + blankNull(e.SVMXC_Zip_Code__c, '')
                + '\n' + 'Contact Name: ' + blankNull(e.SMAX_PS_Contact_Name__c, '')
                + '\n' + 'Contact Phone: ' + blankNull(e.SMAX_PS_Contact_Phone__c, '');

        // SVMXCFG-806 : Update Event Subject Concatenation
        e.Subject = blankNull(e.SMAX_PS_Scheduling_status__c, '**')
                + blankNull(e.SMAX_PS_Work_Order_Number__c, '**')
                + blankNull(e.SMAX_PS_Work_Order_Record_Type__c, '**')
                + blankNull(e.SMAX_PS_Billing_Type__c, '**')
                + blankNull(e.SMAX_PS_SAP_ActivityType__c, '**')
                + blankNull(e.SMAX_PS_Escalation_Justification__c, '**')
                + blankNullTrim(e.SMAX_PS_Product__c, '**', 12)
                + blankNullTrim(e.SMAX_PS_Location__c, '**', 12)
                + blankNullTrim(e.SVMXC_City__c, '**', 12)
                + blankNull(e.SVMXC_Zip_Code__c, '**');
        if(e.Subject.length() > 255) {
            e.Subject = e.Subject.substring(0, 252) + '...';
        }
    }

    private static String blankNull(String val, String sep) {
        return (val == null) ? '' : val + sep;
    }

    private static String blankNullTrim(String val, String sep, Integer max) {
        return (val == null) ? '' : val.left(max) + sep;
    }

    // SVMXCFG-1000 Auto-Assign for Estimates
    public static void autoAssignServiceEstimates(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('WO Service Estimate Auto Assign', 'Perform a Auto-Assignment on the WO when Service Estimate Record Type and Created By FSE Profile.'))
            return;

        RecordType estimateRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');
        Set<Id> userIds = new Set<Id>();
        List<SVMXC__Service_Order__c> woToAssign = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.RecordTypeId == estimateRT.Id && wo.SVMXC__Group_Member__c == null)
            {
                // Try to assign to the current User's Technician...
                woToAssign.add(wo);
                userIds.add(wo.OwnerId);
            }
        }

        if (woToAssign.isEmpty())
            return;

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Profile.Name FROM User WHERE Id IN :userIds]);

        Map<Id, SVMXC__Service_Group_Members__c> userTechMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Salesforce_User__c, SVMXC__Service_Group__c
        FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c IN :userIds])
        {
            userTechMap.put(tech.SVMXC__Salesforce_User__c, tech);
        }

        // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();

        // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
        // Get the Long Job Queue Id that will be used in calls to assignTechnician()
        List<Group> longJobQueueRecord = [SELECT Id, Name, Type, DeveloperName FROM Group WHERE DeveloperName = 'AES_SMAX_PS_CRC_Queue' LIMIT 1];
        Id longJobQueueId = null;
        if (!longJobQueueRecord.isEmpty())
        {
            longJobQueueId = longJobQueueRecord[0].Id;
        }

        List<Event> events = new List<Event>();
        for (SVMXC__Service_Order__c wo : woToAssign)
        {
            User u = userMap.get(wo.OwnerId);
            SVMXC__Service_Group_Members__c tech = userTechMap.get(wo.OwnerId);
            // SVMXCFG-1107 Null protect the User variable (could be a Group or Queue)
            // 6/16/2020 Tony - ITSVMX-51 Estimate scheduling - follow up: Added Service Manager
            //if (u != null && u.Profile.Name.contains('Field Engineer') && tech != null)

            // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
            // ITSVMX-801 5/27/2022 Go ahead and Assign the Service Request WOs
//              if (wo.SVMX_PS_Is_Long_Job__c) {
            if (wo.SVMX_PS_Is_Long_Job__c && wo.RecordTypeId != estimateRTId) {

                // Set the Owner to Long Job Queue
                System.debug('longJobQueueId: ' + longJobQueueId);
                if (longJobQueueId != null)
                {
                    wo.OwnerId = longJobQueueId;
                }

                wo.SMAX_PS_AutoAssignmentNotes__c += ' Skip Auto Assignment Service Estimate as this is a Long Job and Assign to CRC Queue.';
                System.debug('Skip Auto Assignment Service Estimate as this is a Long Job and Assign to CRC Queue.');
                continue;
            }

            //ITSVMX-743 Tech Support & Hybrid Profile(w/ Tech Equip Record) Accepting RWO From Queue
            //Sarala Lakkireddy - Removed the condition that checks the Field Engineer or Support Manager so that
            //technician is auto assigned for all profiles
            //if (u != null && tech != null && (u.Profile.Name.contains('Field Engineer') || u.Profile.Name.contains('Service Manager')))
            if (u != null && tech != null)
            {
                Event evt = assignTechnician(wo, tech, Date.today(), null);

                // ITSFDC-1099 Don't add NULL events to inert list
                if (evt != null)
                {
                    events.add(evt);
                }

            }
        }

        System.debug('About to Insert events: [' + events + ']');
        if (!events.isEmpty())
            insert events;
    }

    // ITSFDC-1099 Remove the SVMXCFG-1103 code as it is not approved
    /*
    // SVMXCFG-1103 Problem with Estimate Conversions
    public static void convertedFromEstimate(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        DateTime dt = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(9, 0, 0, 0));
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (old != null && wo.SVMXC__Group_Member__c != null
                && wo.SMAX_PS_Converted_from_Estimate__c == true
                && old.SMAX_PS_Converted_from_Estimate__c == false)
            {
                // A WO is currently converting from a Estimate...
                wo.SVMXC__Scheduled_Date_Time__c = dt;
                System.debug('!! UPDATED Scheduled Date for converted Estimate: ' + dt);
                // NOTE: This will cause confirmScheduling(...) to run and adjust the Event as well
            }
        }
    }
    */

    // ITSFDC-509 Auto-Assign for Depot Work Orders (when they "Accept" from the Queue)
    public static void autoAssignOwnerChanges(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('WO Auto Assign Owner Changes', 'Perform a Auto-Assignment to a Technician related to the new WO Owner.'))
            return;

        // ITSVMX-35 Adding Custom Setting for Record Types
        SMAX_PS_Assignment_Settings__c csAssignmentSettings = SMAX_PS_Assignment_Settings__c.getOrgDefaults();

        String recordTypes;

        if(Test.isRunningTest()){
            //If Unit test is running set values
            recordTypes = 'Remote, Depot_Repair, Service_Request';
            System.debug('Testing recordTypes: ' + recordTypes);

        } else {
            if (csAssignmentSettings == null || csAssignmentSettings.Auto_Assign_Owner_On_Changes_for_RT__c == null) {
                System.debug('Custom Setting SMAX_PS_Assignment_Settings__c.Auto_Assign_Owner_On_Changes_for_RT__c value has not been set.');
                return;
            }

            recordTypes = csAssignmentSettings.Auto_Assign_Owner_On_Changes_for_RT__c;
            System.debug('Custom Setting recordTypes: ' + recordTypes);
        }

        List<String> lstRecordTypeStrings = recordTypes.split(',');
        System.debug('lstRecordTypeStrings: ' + lstRecordTypeStrings);

        List<Id> lstRecordTypeIds = new List<Id>();
        RecordType tempRecordType;
        for (String recordTypeString : lstRecordTypeStrings) {

            tempRecordType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', recordTypeString.trim());
            lstRecordTypeIds.add(tempRecordType.Id);
        }
        System.debug('lstRecordTypeIds: ' + lstRecordTypeIds);

        // ITSFDC-1047 Need to add Technician to "Remote" Work Orders also
        //RecordType remoteRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');
        //RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');

        String queuePrefix = Schema.SObjectType.Group.getKeyPrefix();
        System.debug('QUEUE PREFIX = ' + queuePrefix);
        Set<Id> userIds = new Set<Id>();
        List<SVMXC__Service_Order__c> woToAssign = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            Boolean oldInQueue = (old == null) ? false : ('' + old.OwnerId).startsWith(queuePrefix);
            System.debug('OLD IN QUEUE? ' + oldInQueue + ', ACCEPT FROM QUEUE? ' + wo.BD_Accept_from_Queue__c);

            // Mass-Quick-Action Support - SVMX_PS_Accept_Work_Order__c (checkbox)
            // New Field: "Accept From Queue", if NOT in a Queue throw Exception!
            if (wo.BD_Accept_from_Queue__c == true && old.BD_Accept_from_Queue__c != wo.BD_Accept_from_Queue__c)
            {
                if (oldInQueue) {
                    wo.OwnerId = UserInfo.getUserId();
                    wo.BD_Accept_from_Queue__c = false;  // Revert the value... like a "button click"

                    // ITSFDC-1047 Also check for "Remote" WOs
                    //if ((wo.RecordTypeId == depotRT.Id || wo.RecordTypeId == remoteRT.Id) && (old != null && wo.OwnerId != old.OwnerId))
                    // ITSVMX-48 Roll-back the auto-assign for Remote Owner changes (for now)
                    // ITSVMX-35 Adding Custom Setting for Record Types
                    //if (wo.RecordTypeId == depotRT.Id && (old != null && wo.OwnerId != old.OwnerId))
                    // ITSVMX-660 Moved this code from outside the top "if" AND Removed the following criteria:
                    //  && (old != null && wo.OwnerId != old.OwnerId && oldInQueue)
                    if (lstRecordTypeIds.contains(wo.RecordTypeId))
                    {
                        // Try to assign to the current User's Technician...
                        System.debug('Adding WO record to Assign list');
                        woToAssign.add(wo);
                        userIds.add(wo.OwnerId);
                    }
                } else {
                    wo.addError('The "Accept from Queue" feature is only available for Work Orders currently in a Queue');
                    continue;
                }
                // This should be in time for the next bit of logic to also fire...
            }
        }

        System.debug('UserIds: ' + UserIds.size() + ' ' + UserIds);

        if (woToAssign.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Profile.Name FROM User WHERE Id IN :userIds]);

        Map<Id, SVMXC__Service_Group_Members__c> userTechMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Salesforce_User__c, SVMXC__Service_Group__c
        FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c IN :userIds])
        {
            userTechMap.put(tech.SVMXC__Salesforce_User__c, tech);
        }

        // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();

        // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
        // Get the Long Job Queue Id that will be used in calls to assignTechnician()
        List<Group> longJobQueueRecord = [SELECT Id, Name, Type, DeveloperName FROM Group WHERE DeveloperName = 'AES_SMAX_PS_CRC_Queue' LIMIT 1];
        Id longJobQueueId = null;
        if (!longJobQueueRecord.isEmpty())
        {
            longJobQueueId = longJobQueueRecord[0].Id;
        }

        List<Event> events = new List<Event>();
        for (SVMXC__Service_Order__c wo : woToAssign)
        {
            User u = userMap.get(wo.OwnerId);
            SVMXC__Service_Group_Members__c tech = userTechMap.get(wo.OwnerId);

            // ITSVMX-688 5/3/2022 Issue #4 Exclude WOs from auto assignment if they have long job scheduling. CRC should monitor them on unassigned queue.
            // ITSVMX-801 5/27/2022 Go ahead and Assign the Service Request WOs
//              if (wo.SVMX_PS_Is_Long_Job__c) {
            if (wo.SVMX_PS_Is_Long_Job__c && wo.RecordTypeId != estimateRTId) {

                // Set the Owner to Long Job Queue
                System.debug('longJobQueueId: ' + longJobQueueId);
                if (longJobQueueId != null)
                {
                    wo.OwnerId = longJobQueueId;
                }

                wo.SMAX_PS_AutoAssignmentNotes__c += ' Skip Auto Assignment Depot Owner Changes as this is a Long Job and Assign to CRC Queue.';
                System.debug('Skip Auto Assignment Service Estimate as this is a Long Job and Assign to CRC Queue.');
                continue;
            }

            System.debug('wo.SVMXC__Order_Status__c: ' + wo.SVMXC__Order_Status__c);
            System.debug('wo.OwnerId: ' + wo.OwnerId);
            System.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
            System.debug('u: ' + u);
            System.debug('tech: ' + tech);

            // SVMXCFG-1107 Null protect the User variable (could be a Group or Queue)
            if (u != null && tech != null)
            {
                // IF WO is still in "Initializing", don't allow this...
                if (wo.SVMXC__Order_Status__c == 'Initializing')
                {
                    wo.addError('Cannot Accept the Work Order until it has finished initializing. Please check for Integration Errors.');
                }
                // ITSVMX-34 05/28/2020 - Don't allow a User to take ownership of the WO if the order status is "On Hold - Credit"
                //else
                else if (wo.SVMXC__Order_Status__c == 'On Hold - Credit' && wo.OwnerId == UserInfo.getUserId())
                {
                    wo.addError('Cannot Accept a Work Order in "On Hold - Credit" status.');
                }
                else
                {
                    Date startDate = wo.SMAX_PS_Customer_Required_Start_Date__c;

                    Event evt = assignTechnician(wo, tech, (startDate == null ? Date.today() : startDate), null);

                    // ITSVMX-35 6/24/2020 Tony Check to make sure Event has not already been created for this Tech
                    if (evt != null)
                    {
                        events.add(evt);
                    }
                }
            }
        }

        if (!events.isEmpty())
        {
            insert events;
        }
    }

    // 8/11/20 ITSVMX-70 tony - Update the "Scheduled Duration" on the WO based on Event Start / End Times
    // ITSVMX-575 Added logic to set the Service Duration and Estimated Duration also
    public static void setDurations(SVMXC__Service_Order__c wo, Long startTime, Long endTime) {
        Long milliseconds = endTime - startTime;
        Long seconds = milliseconds / 1000;
        wo.SVMXC__Service_Duration__c = seconds; // In seconds
        Long minutes = seconds / 60;
        // ITSVMX-606 Only change the "Estimated Duration" if not already set, it should be preserved
        if (wo.SVMXC__SM_Estimated_Duration__c == null || wo.SVMXC__SM_Estimated_Duration__c == 0) {
            wo.SVMXC__SM_Estimated_Duration__c = minutes; // in minutes
        }
        Decimal hours = (minutes / 60.00).setScale(2);
        // ITSVMX-606: Changing Scheduled Duration field
        wo.SMAX_PS_Scheduled_Duration_Hours__c = hours; // in hours
    }

}
/**
 * Created by frankvanloon on 2019-05-08.
 * ITSFDC-1161 (old SVMXCFG-1108) Created initially for the KPI Metrics
 */
public with sharing class SMAX_PS_BusinessHours
{
	/*
		Technician field:  SVMXC__Service_Group_Members__c.SVMXC__Working_Hours__c

		BusinessHours (class) methods:
		https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_businesshours.htm
		add(businessHoursId, startDate, intervalMilliseconds) : Datetime
		addGmt(businessHoursId, startDate, intervalMilliseconds) : Datetime
		diff(businessHoursId, startDate, endDate) : Long (milliseconds)
		isWithin(businessHoursId, targetDate) : Boolean
		nextStartDate(businessHoursId, targetDate) : Datetime

		NOTE: Use the Decimal.setScale(scale, roundingMode) method to round to 1 decimal, using System.RoundingMode.HALF_UP
	 */

	public static Map<Id, BusinessHours> lookupTechnicianBusinessHours(Set<Id> techIds)
	{
		BusinessHours DEFAULT_BS = null;
		Map<Id, BusinessHours> results = new Map<Id, BusinessHours>();
		for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Working_Hours__c,
				SVMXC__Working_Hours__r.Id, SVMXC__Working_Hours__r.TimeZoneSidKey, SVMXC__Working_Hours__r.IsActive
			FROM SVMXC__Service_Group_Members__c WHERE Id = :techIds])
		{
			BusinessHours bizHours = tech.SVMXC__Working_Hours__r;
			if (bizHours != null && bizHours.IsActive == true)
			{
				results.put(tech.Id, tech.SVMXC__Working_Hours__r);
			}
			else
			{
				if (DEFAULT_BS == null)
				{
					DEFAULT_BS = [SELECT Id, TimeZoneSidKey, IsActive FROM BusinessHours WHERE IsDefault = true];
				}
				// Add "Default" BusinessHours instead
				results.put(tech.Id, DEFAULT_BS);
			}
		}

		return results;
	}

	public static Map<Id, BusinessHours> lookupWorkOrderBusinessHours(Set<Id> woIds)
	{
		BusinessHours DEFAULT_BH = null;
		Map<Id, BusinessHours> results = new Map<Id, BusinessHours>();

		for (SVMXC__Service_Order__c wo : [SELECT Id, Name,
				SVMXC__Preferred_Business_Hours__c,
				SVMXC__Preferred_Business_Hours__r.Id,
				SVMXC__Preferred_Business_Hours__r.TimeZoneSidKey,
				SVMXC__Preferred_Business_Hours__r.IsActive,
				SVMXC__Group_Member__r.SVMXC__Working_Hours__c,
				SVMXC__Group_Member__r.SVMXC__Working_Hours__r.Id,
				SVMXC__Group_Member__r.SVMXC__Working_Hours__r.TimeZoneSidKey,
				SVMXC__Group_Member__r.SVMXC__Working_Hours__r.IsActive
		FROM SVMXC__Service_Order__c WHERE Id = :woIds])
		{
			BusinessHours woBizHours = wo.SVMXC__Preferred_Business_Hours__r;
			BusinessHours techBizHours = wo.SVMXC__Group_Member__r.SVMXC__Working_Hours__r;
			System.debug('WO = ' + wo.Id + ', PREF BH = ' + woBizHours + ', TECH BH = ' + techBizHours);
			if (woBizHours != null && woBizHours.IsActive == true)
			{
				results.put(wo.Id, woBizHours);
			}
			else if (techBizHours != null && techBizHours.IsActive == true)
			{
				results.put(wo.Id, techBizHours);
			}
			else
			{
				if (DEFAULT_BH == null)
				{
					DEFAULT_BH = [SELECT Id, TimeZoneSidKey, IsActive FROM BusinessHours WHERE IsDefault = true];
				}
				// Add "Default" BusinessHours instead
				results.put(wo.Id, DEFAULT_BH);
			}
		}

		return results;
	}

	private static Decimal MILLIS_PER_HOUR = (1000 * 60 * 60);
	private static Decimal MILLIS_PER_DAY = (1000 * 60 * 60 * 8);

	public static Decimal businessHoursBetween(BusinessHours bizHours, Datetime startDate, Datetime endDate)
	{
		if (startDate == null || endDate == null || bizHours == null)
		{
			return null;
		}

		Long millis = BusinessHours.diff(bizHours.Id, startDate, endDate);
		//System.debug('RAW Business Millis: ' + millis);
		Decimal hours = millis / MILLIS_PER_HOUR;
		// 2020-05-27: Added to prevent any negative values...
		if (hours < 0.0) {
			hours = 0.0;
		}
		//System.debug('RAW Business Hours: ' + hours);
		return hours.setScale(1); // , RoundingMode.HALF_UP
	}

	public static Decimal businessDaysBetween(BusinessHours bizHours, Datetime startDate, Datetime endDate)
	{
		if (startDate == null || endDate == null || bizHours == null)
		{
			return null;
		}

		Long millis = BusinessHours.diff(bizHours.Id, startDate, endDate);
		Decimal days = millis / MILLIS_PER_DAY;
		// 2020-05-27: Added to prevent any negative values...
		if (days < 0.0) {
			days = 0.0;
		}
		return days.setScale(1, RoundingMode.HALF_UP);
	}

	/*
		In case we need to count Days by looping over the Business Hours object (instead of "8" hours / day)
		BusinessHours (object) fields:
		TimeZoneSidKey
		MondayEndTime
		MondayStartTime
		TuesdayEndTime
		TuesdayStartTime
		WednesdayEndTime
		WednesdayStartTime
		ThursdayEndTime
		ThursdayStartTime
		FridayEndTime
		FridayStartTime
		SaturdayEndTime
		SaturdayStartTime
		SundayEndTime
		SundayStartTime
	 */

}
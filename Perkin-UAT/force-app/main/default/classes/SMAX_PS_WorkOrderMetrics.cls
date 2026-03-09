/**
 * Created by frankvanloon on 2019-05-09.
 * ITSFDC-1161 (old SVMXCFG-1108) Metrics and KPI
 *
 * Changes:
 * 03/03/2022	tony 	ITSVMX-778 - Work Order Metrics - cancelled labor line correction
 */
public with sharing class SMAX_PS_WorkOrderMetrics
{
	public static String SAP_SYS_STATUS_TECO = 'TECO';
	public static String ORDER_TYPE_REPAIR = 'Repair';
	public static String ORDER_STATUS_READY = 'Ready for Review';
	public static String ORDER_STATUS_INVOICED = 'Invoiced';

	public static RecordType FIELD_SERVICE_RT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
	public static RecordType REMOTE_RT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');

	public static String getExternalId(SVMXC__Service_Order__c wo, String type)
	{
		return wo.Name + '__' + type;
	}

	public static SMAX_PS_Work_Order_Metrics__c getMetrics(SVMXC__Service_Order__c wo, String type, Map<String, SMAX_PS_Work_Order_Metrics__c> metrics)
	{
		String externalId = getExternalId(wo, type);
		SMAX_PS_Work_Order_Metrics__c wom = metrics.get(externalId);
		if (wom == null)
		{
			wom = new SMAX_PS_Work_Order_Metrics__c(Name = externalId, SMAX_PS_External_Id__c = externalId,
					SMAX_PS_Work_Order__c = wo.Id, SMAX_PS_Metrics_Type__c = type);
			metrics.put(externalId, wom);
		}
		return wom;
	}

	/**
	 * Should be called from the AFTER INSERT & BEFORE UPDATE Triggers
	 */
	public static void countAssignments(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		// Number of Assignments [SMAX_PS_Number_of_Assignments__c] "Dispatch Efficiency"
		// Increment Number of Times Assigned by 1 for each assignment. (not TECO.. on assign)
		Set<String> externalIds = new Set<String>();
		List<SVMXC__Service_Order__c> assignedList = new List<SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if ((wo.RecordTypeId == FIELD_SERVICE_RT.Id || wo.RecordTypeId == REMOTE_RT.Id)
					&& (old == null || wo.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c)
					&& wo.SVMXC__Group_Member__c != null)
			{
				if (old != null) {
					System.debug('>> WO ASSIGNED: ' + wo.Name + ' from: ' + old.SVMXC__Group_Member__c + ' to: ' + wo.SVMXC__Group_Member__c);
				}
				String run1key = 'countAssignments_' + wo.Id;
				if (SMAX_PS_Utility.isFirstRun(run1key)) {
					String type = (wo.RecordTypeId == REMOTE_RT.Id) ? REMOTE_RT.DeveloperName : FIELD_SERVICE_RT.DeveloperName;
					externalIds.add(getExternalId(wo, type));
					assignedList.add(wo);
				}
			}
		}

		if (assignedList.isEmpty())
		{
			return;
		}

		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SMAX_PS_Work_Order_Metrics__c m : [SELECT Id, Name, SMAX_PS_External_Id__c,
				SMAX_PS_Number_of_Assignments__c, SMAX_PS_First_Assigned_Datetime__c
		FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_External_Id__c IN :externalIds])
		{
			metrics.put(m.SMAX_PS_External_Id__c, m);
		}

		for (SVMXC__Service_Order__c wo : assignedList)
		{
			String type = (wo.RecordTypeId == REMOTE_RT.Id) ? REMOTE_RT.DeveloperName : FIELD_SERVICE_RT.DeveloperName;
			SMAX_PS_Work_Order_Metrics__c wom = getMetrics(wo, type, metrics);

			if (wom.SMAX_PS_Number_of_Assignments__c == null)
			{
				wom.SMAX_PS_Number_of_Assignments__c = 0;
			}
			System.debug('>> INCREMENTING WO METRICS: NumAssignments: ' + wo.Name);
			wom.SMAX_PS_Number_of_Assignments__c = wom.SMAX_PS_Number_of_Assignments__c + 1;
			if (wom.SMAX_PS_First_Assigned_Datetime__c == null)
			{
				wom.SMAX_PS_First_Assigned_Datetime__c = Datetime.now();
			}
		}

		upsertMetrics(metrics.values(), 'countAssignments');
	}

	/**
	 * Should be called from the AFTER INSERT & AFTER UPDATE Triggers
	 */
	public static void calculateMetricsOnTECO(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		Set<String> externalIds = new Set<String>();
		List<SVMXC__Service_Order__c> tecoList = new List<SVMXC__Service_Order__c>();
		Set<Id> woIds = new Set<Id>();
		Set<Id> woIdsRecalcFTF = new Set<Id>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if ((old == null || wo.SMAX_PS_SAP_SystemStatus__c != old.SMAX_PS_SAP_SystemStatus__c)
					&& wo.SMAX_PS_SAP_SystemStatus__c == SAP_SYS_STATUS_TECO
					&& wo.RecordTypeId == FIELD_SERVICE_RT.Id)
			{
				tecoList.add(wo);
				woIds.add(wo.Id);
				externalIds.add(getExternalId(wo, FIELD_SERVICE_RT.DeveloperName));
			}
		}

		if (tecoList.isEmpty())
		{
			return;
		}

		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SMAX_PS_Work_Order_Metrics__c m : [SELECT Id, Name, SMAX_PS_External_Id__c, SMAX_PS_First_Labor_DateTime__c, SMAX_PS_Last_Labor_Datetime__c,
				SMAX_PS_First_Assigned_Datetime__c, SMAX_PS_Case_Opened_Datetime__c, SMAX_PS_Work_Order_Created_Datetime__c,
				SMAX_PS_Completed_Datetime__c, SMAX_PS_Calculated_Dispatch_Time__c, SMAX_PS_Calc_Onsite_Response_Time__c,
				SMAX_PS_Calculated_Downtime__c, SMAX_PS_Calc_Call_Upload_Time__c, SMAX_PS_Is_First_Time_Fix__c,
				SMAX_PS_Business_Hours__c
		FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_External_Id__c IN :externalIds])
		{
			metrics.put(m.SMAX_PS_External_Id__c, m);
		}

		Map<Id, AggregateResult> woDates = new Map<Id, AggregateResult>();
		for (AggregateResult aggResult : [SELECT SVMXC__Service_Order__c,
				MIN(SVMXC__Start_Date_and_Time__c) FirstLabor, MAX(SVMXC__End_Date_and_Time__c) LastLabor
		FROM SVMXC__Service_Order_Line__c
		WHERE SVMXC__Service_Order__c IN :woIds AND SVMXC__Line_Type__c = 'Labor'
		AND RecordType.DeveloperName = 'UsageConsumption'
		// ITSVMX-778 3/3/22 - Work Order Metrics - cancelled labor line correction
		AND SVMXC__Line_Status__c != 'Canceled'
		GROUP BY SVMXC__Service_Order__c])
		{
			woDates.put((Id)aggResult.get('SVMXC__Service_Order__c'), aggResult);
		}

		Map<Id, BusinessHours> bizHoursMap = SMAX_PS_BusinessHours.lookupWorkOrderBusinessHours(woIds);

		for (SVMXC__Service_Order__c wo : tecoList)
		{
			SMAX_PS_Work_Order_Metrics__c wom = getMetrics(wo, FIELD_SERVICE_RT.DeveloperName, metrics);

			// Copy fields from WO:
			wom.SMAX_PS_Case_Opened_Datetime__c = wo.SVMX_PS_Case_Opened_Date_Time__c;
			wom.SMAX_PS_Completed_Datetime__c = wo.SVMXC__Completed_Date_Time__c;
			// ITSFDC-1162 - Added on 2020-06-04
			wom.SMAX_PS_Work_Order_Created_Datetime__c = wo.CreatedDate;

			AggregateResult woDateResult = woDates.get(wo.Id);
			if (woDateResult != null)
			{
				wom.SMAX_PS_First_Labor_DateTime__c = (Datetime) woDateResult.get('FirstLabor');
				wom.SMAX_PS_Last_Labor_Datetime__c = (Datetime) woDateResult.get('LastLabor');
			}

			BusinessHours bizHours = bizHoursMap.get(wo.Id);
			if (bizHours != null) {
				wom.SMAX_PS_Business_Hours__c = bizHours.Id;
			}

			//Calculated Dispatch Time [SVMXC__Service_Order__c.SMAX_PS_Calculated_Dispatch_Time__c]
			//First Assigned DateTime, Created Date, and the business hours id
			wom.SMAX_PS_Calculated_Dispatch_Time__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Work_Order_Created_Datetime__c, wom.SMAX_PS_First_Assigned_Datetime__c);

			//Calculated On-site Response Time [SVMXC__Service_Order__c.SMAX_PS_Calc_Onsite_Response_Time__c]
			//First Labor Datetime, SVMX_PS_Case_Opened_Date_Time__c, and business hours obtained from the assigned technician
			//to be triggered when the Record Type IS NOT Remote and SAP System Status = TECO.
			wom.SMAX_PS_Calc_Onsite_Response_Time__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Case_Opened_Datetime__c, wom.SMAX_PS_First_Labor_DateTime__c);

			// Calculated Downtime [SVMXC__Service_Order__c.SMAX_PS_Calculated_Downtime__c]
			//SVMX_PS_Case_Opened_Date_Time__c, Last Labor DateTime, and the business hours id
			wom.SMAX_PS_Calculated_Downtime__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Case_Opened_Datetime__c, wom.SMAX_PS_Last_Labor_Datetime__c);

			// Calculated Call Upload Time [SVMXC__Service_Order__c.SMAX_PS_Calc_Call_Upload_Time__c]
			//Last Labor DateTime, SVMXC__Completed_Date_Time__c, and the business hours id
			wom.SMAX_PS_Calc_Call_Upload_Time__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Last_Labor_Datetime__c, wom.SMAX_PS_Completed_Datetime__c);

			// Is First Time Fix? [SMAX_PS_Is_First_Time_Fix__c]
			//“First Labor Datetime” and “Last Labor DateTime”.  If the same DAY then output 1 if different than output 0.
			Boolean ftfSameDay = isSameDay(bizHours, wom.SMAX_PS_First_Labor_DateTime__c, wom.SMAX_PS_Last_Labor_Datetime__c);
			wom.SMAX_PS_Is_First_Time_Fix__c = (ftfSameDay ? 1 : 0);
		}

		upsertMetrics(metrics.values(), 'calculateMetricsOnTECO');
	}

	public static void recalcFirstTimeFix(List<SMAX_PS_Work_Order_Metrics__c> scope) {
		Set<Id> bizHoursIds = new Set<Id>();
		for (SMAX_PS_Work_Order_Metrics__c wom : scope) {
			if (wom.SMAX_PS_Business_Hours__c != null) {
				bizHoursIds.add(wom.SMAX_PS_Business_Hours__c);
			}
		}

		if (bizHoursIds.isEmpty()) {
			return;
		}

		Map<Id, BusinessHours> bizHoursMap = new Map<Id, BusinessHours>([SELECT Id, Name, TimeZoneSidKey
			FROM BusinessHours WHERE Id IN :bizHoursIds]);

		for (SMAX_PS_Work_Order_Metrics__c wom : scope) {
			BusinessHours bizHours = bizHoursMap.get(wom.SMAX_PS_Business_Hours__c);
			System.debug('Trying to recalc FTF: ' + wom);
			if (bizHours != null) {
				// RECALCULATE: “First Time Fix”...  If the same DAY then output 1 if different than output 0.
				Boolean ftfSameDay = SMAX_PS_WorkOrderMetrics.isSameDay(bizHours, wom.SMAX_PS_First_Labor_DateTime__c, wom.SMAX_PS_Last_Labor_Datetime__c);
				System.debug('Recalc FTF Same Day: ' + ftfSameDay);
				wom.SMAX_PS_Is_First_Time_Fix__c = (ftfSameDay ? 1 : 0);
			}
		}
		// No update needed - should be called from BEFORE UPDATE
		// update scope;
	}

	/**
	 * Should be called from the AFTER UPDATE Trigger
	 */
	public static void calculateMetricsOnInvoicing(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		Datetime NOW = Datetime.now();
		Set<String> externalIds = new Set<String>();
		List<SVMXC__Service_Order__c> readyList = new List<SVMXC__Service_Order__c>();
		List<SVMXC__Service_Order__c> invoicedList = new List<SVMXC__Service_Order__c>();
		Set<Id> woIds = new Set<Id>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.RecordTypeId == FIELD_SERVICE_RT.Id &&
					(old == null || wo.SVMXC__Order_Status__c != old.SVMXC__Order_Status__c))
			{
				if (wo.SVMXC__Order_Status__c == ORDER_STATUS_READY)
				{
					externalIds.add(getExternalId(wo, FIELD_SERVICE_RT.DeveloperName));
					//wo.SVMX_PS_Ready_to_Review_Date_Time__c = NOW;
					readyList.add(wo);
				}
				else if (wo.SVMXC__Order_Status__c == ORDER_STATUS_INVOICED)
				{
					externalIds.add(getExternalId(wo, FIELD_SERVICE_RT.DeveloperName));
					//wo.SMAX_PS_Invoiced_DateTime__c = NOW;
					invoicedList.add(wo);
					woIds.add(wo.Id);
				}
			}
		}

		if (externalIds.isEmpty())
		{
			return;
		}

		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SMAX_PS_Work_Order_Metrics__c m : [SELECT Id, Name, SMAX_PS_External_Id__c,
				SMAX_PS_Ready_to_Review_Datetime__c, SMAX_PS_Invoiced_DateTime__c, SMAX_PS_Calc_Days_to_Invoice__c,
				SMAX_PS_Business_Hours__c
		FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_External_Id__c IN :externalIds])
		{
			metrics.put(m.SMAX_PS_External_Id__c, m);
		}

		for (SVMXC__Service_Order__c wo : readyList)
		{
			SMAX_PS_Work_Order_Metrics__c wom = getMetrics(wo, FIELD_SERVICE_RT.DeveloperName, metrics);
			wom.SMAX_PS_Ready_to_Review_Datetime__c = NOW;
		}

		if (!invoicedList.isEmpty())
		{
			Map<Id, BusinessHours> bizHoursMap = SMAX_PS_BusinessHours.lookupWorkOrderBusinessHours(woIds);

			for (SVMXC__Service_Order__c wo : invoicedList) {
				SMAX_PS_Work_Order_Metrics__c wom = getMetrics(wo, FIELD_SERVICE_RT.DeveloperName, metrics);

				BusinessHours bizHours = bizHoursMap.get(wo.Id);
				if (bizHours != null) {
					wom.SMAX_PS_Business_Hours__c = bizHours.Id;
				}

				wom.SMAX_PS_Invoiced_DateTime__c = NOW;
				// Calculated Days to Invoice [SVMXC__Service_Order__c.SMAX_PS_Calc_Days_to_Invoice__c]
				// SVMX_PS_Ready_to_Review_Date_Time__c, SMAX_PS_Invoiced_DateTime__c (IN DAYS)
				wom.SMAX_PS_Calc_Days_to_Invoice__c = SMAX_PS_BusinessHours.businessDaysBetween(bizHours,
						wom.SMAX_PS_Ready_to_Review_Datetime__c, wom.SMAX_PS_Invoiced_DateTime__c);
			}
		}

		upsertMetrics(metrics.values(), 'calculateMetricsOnInvoicing');
	}

	/**
	 * Should be called from the AFTER INSERT & BEFORE UPDATE Triggers
	 * Handles both Remote Conversion to FieldService and Remote Closed
	 */
	public static void calculateMetricsOnRemote(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		Set<Id> woIds = new Set<Id>();
		List<SVMXC__Service_Order__c> closedOrConverted = new List<SVMXC__Service_Order__c>();
		Set<String> externalIds = new Set<String>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			// Remote WO Converted to FieldService...
			if (old != null && wo.RecordTypeId == FIELD_SERVICE_RT.Id && old.RecordTypeId == REMOTE_RT.Id) {
				externalIds.add(getExternalId(wo, REMOTE_RT.DeveloperName));
				woIds.add(wo.Id);
				closedOrConverted.add(wo);
			}
			// Remote WO Closed...
			if ((old == null || old.SVMXC__Order_Status__c != wo.SVMXC__Order_Status__c)
					&& wo.RecordTypeId == REMOTE_RT.Id
					&& wo.SVMXC__Order_Status__c == 'Closed') {
				externalIds.add(getExternalId(wo, REMOTE_RT.DeveloperName));
				woIds.add(wo.Id);
				closedOrConverted.add(wo);
			}
		}

		if (closedOrConverted.isEmpty())
		{
			return;
		}

		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SMAX_PS_Work_Order_Metrics__c m : [SELECT Id, Name, SMAX_PS_External_Id__c, SMAX_PS_First_Labor_DateTime__c, SMAX_PS_Last_Labor_Datetime__c,
				SMAX_PS_Case_Opened_Datetime__c, SMAX_PS_Work_Order_Created_Datetime__c, SMAX_PS_Remote_Fix__c,
				SMAX_PS_Calc_Tech_Support_Response_Time__c, SMAX_PS_Calculated_Downtime__c,
				SMAX_PS_Business_Hours__c
		FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_External_Id__c IN :externalIds])
		{
			metrics.put(m.SMAX_PS_External_Id__c, m);
		}

		Map<Id, AggregateResult> woDates = new Map<Id, AggregateResult>();
		for (AggregateResult aggResult : [SELECT SVMXC__Service_Order__c,
				MIN(SVMXC__Start_Date_and_Time__c) FirstLabor, MAX(SVMXC__End_Date_and_Time__c) LastLabor
		FROM SVMXC__Service_Order_Line__c
		WHERE SVMXC__Service_Order__c IN :closedOrConverted AND SVMXC__Line_Type__c = 'Labor'
		AND RecordType.DeveloperName = 'SMAX_PS_Remote_Support'
		GROUP BY SVMXC__Service_Order__c])
		{
			woDates.put((Id)aggResult.get('SVMXC__Service_Order__c'), aggResult);
		}

		Map<Id, BusinessHours> bizHoursMap = SMAX_PS_BusinessHours.lookupWorkOrderBusinessHours(woIds);

		for (SVMXC__Service_Order__c wo : closedOrConverted)
		{
			SMAX_PS_Work_Order_Metrics__c wom = getMetrics(wo, REMOTE_RT.DeveloperName, metrics);

			// Copy fields from WO:
			wom.SMAX_PS_Case_Opened_Datetime__c = wo.SVMX_PS_Case_Opened_Date_Time__c;
			// ITSFDC-1162 - Added on 2020-06-04
			wom.SMAX_PS_Work_Order_Created_Datetime__c = wo.CreatedDate;

			AggregateResult woDateResult = woDates.get(wo.Id);
			if (woDateResult != null)
			{
				wom.SMAX_PS_First_Labor_DateTime__c = (Datetime) woDateResult.get('FirstLabor');
				wom.SMAX_PS_Last_Labor_Datetime__c = (Datetime) woDateResult.get('LastLabor');
			}

			BusinessHours bizHours = bizHoursMap.get(wo.Id);
			if (bizHours != null) {
				wom.SMAX_PS_Business_Hours__c = bizHours.Id;
			}

			//Calculated Tech Support Response Time [SVMXC__Service_Order__c.SMAX_PS_Calc_Tech_Support_Response_Time__c]
			//SVMX_PS_Case_Opened_Date_Time__c to first labor date time, and the business hours from the technician assigned
			//to the work order only when the Work Order record type is Remote and the SAP System Status = TECO
			wom.SMAX_PS_Calc_Tech_Support_Response_Time__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Case_Opened_Datetime__c, wom.SMAX_PS_First_Labor_DateTime__c);

			// Calculated Downtime [SVMXC__Service_Order__c.SMAX_PS_Calculated_Downtime__c]
			//SVMX_PS_Case_Opened_Date_Time__c, Last Labor DateTime, and the business hours id
			wom.SMAX_PS_Calculated_Downtime__c = SMAX_PS_BusinessHours.businessHoursBetween(bizHours,
					wom.SMAX_PS_Case_Opened_Datetime__c, wom.SMAX_PS_Last_Labor_Datetime__c);

			if (wo.RecordTypeId == FIELD_SERVICE_RT.Id)
			{
				//wom.SMAX_PS_Is_Converted_to_Repair__c = 1;
				wom.SMAX_PS_Calculated_Downtime__c = null; // When converted to Field Service the DownTime calculation is reset
				wom.SMAX_PS_Remote_Fix__c = 0;
			}
			else
			{
				wom.SMAX_PS_Remote_Fix__c = 1;
			}

		}

		upsertMetrics(metrics.values(), 'calculateMetricsOnRemote');
	}

	/**
	 * Should be called from the AFTER UPDATE Trigger
	 */
	public static void deleteMetricsOnCanceled(List<SVMXC__Service_Order__c> woList)
	{
		Set<Id> canceledIds = new Set<Id>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			if (wo.SVMXC__Order_Status__c == 'Canceled') {
				canceledIds.add(wo.Id);
			}
		}

		if (canceledIds.isEmpty()) {
			return;
		}

		List<SMAX_PS_Work_Order_Metrics__c> metrics = [SELECT Id, SMAX_PS_Work_Order__c
			FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_Work_Order__c IN :canceledIds];

		if (!metrics.isEmpty()) {
			delete metrics;
		}
	}

	/**
	 * Should be called from the AFTER INSERT Trigger
	 */
	public static void calculateMetricsOnCallback(List<SVMXC__Service_Order__c> woList)
	{
		Date earliestCreateDate = null;
		Set<String> externalIds = new Set<String>();
		Map<Id, List<SVMXC__Service_Order__c>> ipWO = new Map<Id, List<SVMXC__Service_Order__c>>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			// Only run this logic if a NEW FieldService / Repair WO is being created
			if (wo.SVMXC__Component__c != null && wo.RecordTypeId == FIELD_SERVICE_RT.Id
					&& wo.SVMXC__Order_Type__c == ORDER_TYPE_REPAIR)
			{
				if (!ipWO.containsKey(wo.SVMXC__Component__c))
				{
					ipWO.put(wo.SVMXC__Component__c, new List<SVMXC__Service_Order__c>());
				}
				ipWO.get(wo.SVMXC__Component__c).add(wo);

				String externalId =  getExternalId(wo, FIELD_SERVICE_RT.DeveloperName);
				externalIds.add(externalId);

				// Find the earliest create date (for Batch mode)
				if (wo.CreatedDate != null && (earliestCreateDate == null || wo.CreatedDate.date() < earliestCreateDate))
				{
					earliestCreateDate = wo.CreatedDate.date();
				}
			}
		}

		if (ipWO.isEmpty())
		{
			return;
		}

		// Need to load the existing metrics only for when running in batch mode
		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SMAX_PS_Work_Order_Metrics__c m : [SELECT Id, Name, SMAX_PS_External_Id__c,
				SMAX_PS_Number_of_Assignments__c, SMAX_PS_First_Assigned_Datetime__c
			FROM SMAX_PS_Work_Order_Metrics__c WHERE SMAX_PS_External_Id__c IN :externalIds])
		{
			metrics.put(m.SMAX_PS_External_Id__c, m);
		}

		// Cannot use TODAY + 30 for historical Work Orders.. will need to use "earliest" create date instead
		// ITSVMX-1373 Look back up to 90 days instead of 30 days..
		Date afterDate = (earliestCreateDate == null ? Date.today() : earliestCreateDate).addDays(-90); //.addDays(-30);
		Map<String, SMAX_PS_Work_Order_Metrics__c> womToUpdate = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		// Find old WO where (Remote + Closed) OR (FS + TECO) - This is done simply by using "Last Labor".. it is only calculated in these scenarios
		for (SMAX_PS_Work_Order_Metrics__c oldWom : [SELECT Id, Name, SMAX_PS_Work_Order__c, SMAX_PS_External_Id__c,
				SMAX_PS_Work_Order__r.SVMXC__Component__c, SMAX_PS_Last_Labor_Datetime__c, SMAX_PS_Repair_Callback_Required__c,
				SMAX_PS_Repair_Callback_Required_90__c
			FROM SMAX_PS_Work_Order_Metrics__c
			WHERE SMAX_PS_Work_Order__r.SVMXC__Component__c IN :ipWO.keySet() AND SMAX_PS_Last_Labor_Datetime__c >= :afterDate])
		{
			List<SVMXC__Service_Order__c> newWorkOrders = ipWO.get(oldWom.SMAX_PS_Work_Order__r.SVMXC__Component__c);
			if (newWorkOrders != null)
			{
				for (SVMXC__Service_Order__c newWO : newWorkOrders)
				{
					// ITSFDC-3222: Skip this "oldWom" if it is same key as newWO metric.. (circular reference)
					if (oldWom.SMAX_PS_Work_Order__c == newWO.Id) {
						continue;
					}

					Date woCreateDate = (newWO.CreatedDate == null ? Date.today() : newWO.CreatedDate.date());
					Date thirtyDaysAgo = woCreateDate.addDays(-30);
					// ITSFDC-3222: Don't count as a Callback unless the last labor is also before the create date
					Date lastLaborDate = oldWom.SMAX_PS_Last_Labor_Datetime__c.date();
					if (thirtyDaysAgo <= lastLaborDate && lastLaborDate <= woCreateDate)
					{
						// Repair Callback Required? [SMAX_PS_Repair_Callback_Required__c]
						// When WO created, find previous WO for same IP.. if any in < 30 days ago then "1"
						oldWom.SMAX_PS_Repair_Callback_Required__c = 1;
						womToUpdate.put(oldWom.SMAX_PS_External_Id__c, oldWom); // NOTE: Might do this more than once per WOM, but thats ok

						// Create a new Metrics Object for the New WO, and set the SMAX_PS_Is_Repair_Callback to 1
						SMAX_PS_Work_Order_Metrics__c newWom = getMetrics(newWO, FIELD_SERVICE_RT.DeveloperName, metrics);
						newWom.SMAX_PS_Is_Repair_Callback__c = 1;
						womToUpdate.put(newWom.SMAX_PS_External_Id__c, newWom);
					}
					// ITSVMX-1373 Create a "Repair Callback Required (90 Days)"
					Date ninetyDaysAgo = woCreateDate.addDays(-90);
					if (ninetyDaysAgo <= lastLaborDate && lastLaborDate <= woCreateDate)
					{
						// Repair Callback Required (90 Days)? [SMAX_PS_Repair_Callback_Required_90__c]
						// When WO created, find previous WO for same IP.. if any in < 30 days ago then "1"
						oldWom.SMAX_PS_Repair_Callback_Required_90__c = 1;
						womToUpdate.put(oldWom.SMAX_PS_External_Id__c, oldWom); // NOTE: Might do this more than once per WOM, but thats ok
					}
				}
			}
		}

		if (!womToUpdate.isEmpty())
		{
			upsertMetrics(womToUpdate.values(), 'calculateMetricsOnCallback');
		}
	}

	// ITSVMX-1373 Recalculate "Repair Callback Required (90 Days)" for historical WOM..
	public static void recalcRepairCallbackRequired(List<SMAX_PS_Work_Order_Metrics__c> scope) {
		// Recalculate the RCR and RCR90 metrics... SMAX_PS_Recalculate_RCR__c

		// we are really recalculating the "oldWom" from the above method..
		// this means that here we need to look for another wom which is 30/90 days AFTER the input wom
		// NOTE: compare the old labordate to the new createdate for the 30/90 thresholds

		// NOTE2: When data-loading the recalc fields.. sort by SMAX_PS_Last_Labor_Datetime__c
		// and filter by SMAX_PS_Last_Labor_Datetime__c != null

		Date earliestLaborDate = null;
		Date latestLaborDate = null;
		Set<Id> woIds = new Set<Id>();
		for (SMAX_PS_Work_Order_Metrics__c wom: scope) {
			Date laborDate = wom.SMAX_PS_Last_Labor_Datetime__c.date();
			if (earliestLaborDate == null || earliestLaborDate > laborDate) {
				earliestLaborDate = laborDate;
			}
			if (latestLaborDate == null || latestLaborDate < laborDate) {
				latestLaborDate = laborDate;
			}
			woIds.add(wom.SMAX_PS_Work_Order__c);
		}

		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
			[SELECT Id, Name, SVMXC__Component__c FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
		Set<Id> ipIds = new Set<Id>();
		for (SVMXC__Service_Order__c wo : woMap.values()) {
			if (wo.SVMXC__Component__c != null) {
				ipIds.add(wo.SVMXC__Component__c);
			}
		}

		if (ipIds.isEmpty()) {
			return;
		}

		Date startDate = earliestLaborDate.addDays(30);
		Date endDate = latestLaborDate.addDays(90);
		Map<Id, List<SMAX_PS_Work_Order_Metrics__c>> ipWomMap = new Map<Id, List<SMAX_PS_Work_Order_Metrics__c>>();
		for (SMAX_PS_Work_Order_Metrics__c newWom : [SELECT Id, Name, SMAX_PS_Work_Order__c,
				SMAX_PS_Work_Order__r.CreatedDate, SMAX_PS_Work_Order__r.SVMXC__Component__c
			FROM SMAX_PS_Work_Order_Metrics__c
			WHERE SMAX_PS_Work_Order__r.SVMXC__Component__c IN :ipIds
			AND SMAX_PS_Work_Order__r.CreatedDate >= :startDate AND SMAX_PS_Work_Order__r.CreatedDate <= :endDate])
		{
			Id ipId = newWom.SMAX_PS_Work_Order__r.SVMXC__Component__c;
			if (!ipWomMap.containsKey(ipId)) {
				ipWomMap.put(ipId, new List<SMAX_PS_Work_Order_Metrics__c>());
			}
			ipWomMap.get(ipId).add(newWom);
		}

		for (SMAX_PS_Work_Order_Metrics__c wom: scope) {
			Date laborDate = wom.SMAX_PS_Last_Labor_Datetime__c.date();
			SVMXC__Service_Order__c wo = woMap.get(wom.SMAX_PS_Work_Order__c);
			Id ipId = wo.SVMXC__Component__c;
			List<SMAX_PS_Work_Order_Metrics__c> newMetrics = ipWomMap.get(ipId);
			if (newMetrics == null || newMetrics.isEmpty()) {
				continue;
			}
			for (SMAX_PS_Work_Order_Metrics__c newWom : newMetrics) {
				if (newWom.Id == wom.Id) {
					continue; // Don't compare to self...
				}
				Date woCreateDate = newWom.SMAX_PS_Work_Order__r.CreatedDate.date();
				Integer days = Math.abs(laborDate.daysBetween(woCreateDate));
				if (days <= 30) {
					wom.SMAX_PS_Repair_Callback_Required__c = 1;
				}
				if (days <= 90) {
					wom.SMAX_PS_Repair_Callback_Required_90__c = 1;
				}
			}
		}
	}

	public static void upsertMetrics(List<SMAX_PS_Work_Order_Metrics__c> womList, String methodName)
	{
		List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		if (!womList.isEmpty())
		{
			SObjectField externalIdField = SMAX_PS_Work_Order_Metrics__c.Fields.SMAX_PS_External_Id__c;
			Database.UpsertResult[] results = Database.upsert(womList, externalIdField, false);
			for (Integer i = 0; i < results.size(); i++)
			{
				Database.UpsertResult result = results[i];
				SMAX_PS_Work_Order_Metrics__c wom = womList[i];
				if (!result.isSuccess())
				{
					String errorMsg = 'Error upserting Work Order Metrics: ' + wom.Name + ' - ' + result.getErrors();
					logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, methodName, null, wom.Id));
				}
			}
		}

		if (!logs.isEmpty())
		{
			insert logs;
		}
	}

	private static String YMD_FORMAT = 'yyyy-MM-dd';
	public static Boolean isSameDay(BusinessHours bizHours, Datetime dt1, Datetime dt2)
	{
		if (dt1 == null || dt2 == null) {
			return false;
		}

		// ITSVMX-1328 Adding BusinessHours to use TimeZone to compare dates
		if (bizHours == null) {
			// If no BusinessHours, use the old method..
			return (dt1.year() == dt2.year() && dt1.dayOfYear() == dt2.dayOfYear());
		}

		String tz = bizHours.TimeZoneSidKey;
		String first = dt1.format(YMD_FORMAT, tz);
		String last = dt2.format(YMD_FORMAT, tz);
		System.debug('TimeZone based date comparison: ' + first + ' vs: ' + last);
		return first.equals(last);
	}
}
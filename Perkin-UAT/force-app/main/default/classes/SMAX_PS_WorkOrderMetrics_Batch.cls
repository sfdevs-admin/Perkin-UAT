/**
 * Created by frankvanloon on 2019-06-10.
 * SVMXCFG-1122  Batch Job to Retro-populate Metrics & KPI
 */
global class SMAX_PS_WorkOrderMetrics_Batch implements Database.Batchable<SObject>
{
	global enum MetricsBatchMode { FIELD_SERVICE, REMOTE  }

	private MetricsBatchMode mode;
	private Id workOrderId;

	public SMAX_PS_WorkOrderMetrics_Batch(MetricsBatchMode mode)
	{
		this.mode = mode;
	}

	public SMAX_PS_WorkOrderMetrics_Batch(MetricsBatchMode mode, Id woId)
	{
		this.mode = mode;
		this.workOrderId = woId;
	}

	public static void startFieldServiceBatch()
	{
		Database.executeBatch(new SMAX_PS_WorkOrderMetrics_Batch(MetricsBatchMode.FIELD_SERVICE), 50);
	}

	public static void startRemoteBatch()
	{
		Database.executeBatch(new SMAX_PS_WorkOrderMetrics_Batch(MetricsBatchMode.REMOTE), 50);
	}

	public static void startManualBatch(MetricsBatchMode mode, Id woId)
	{
		Database.executeBatch(new SMAX_PS_WorkOrderMetrics_Batch(mode, woId), 1);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		if (this.workOrderId != null) {
			return Database.getQueryLocator([SELECT Id, Name, CreatedDate, RecordTypeId,
					SMAX_PS_SAP_SystemStatus__c, SVMXC__Order_Status__c, SVMXC__Component__c, SVMXC__Order_Type__c,
					SVMX_PS_Case_Opened_Date_Time__c, SVMXC__Completed_Date_Time__c
				FROM SVMXC__Service_Order__c
				WHERE Id = :workOrderId]);
		}

		switch on this.mode
		{
			when FIELD_SERVICE {
				return Database.getQueryLocator([SELECT Id, Name, CreatedDate, RecordTypeId, SVMXC__Order_Status__c,
						SMAX_PS_SAP_SystemStatus__c, SVMXC__Component__c, SVMXC__Order_Type__c,
						SVMX_PS_Case_Opened_Date_Time__c, SVMXC__Completed_Date_Time__c
					FROM SVMXC__Service_Order__c
					WHERE RecordType.DeveloperName = 'Field_Service' AND SVMXC__Order_Status__c != 'Canceled'
					ORDER BY CreatedDate]);
			}
			when REMOTE {
				return Database.getQueryLocator([SELECT Id, Name, CreatedDate, RecordTypeId,
						SMAX_PS_SAP_SystemStatus__c, SVMXC__Order_Status__c, SVMXC__Order_Type__c,
						SVMX_PS_Case_Opened_Date_Time__c, SVMXC__Completed_Date_Time__c
					FROM SVMXC__Service_Order__c
					WHERE RecordType.DeveloperName = 'Remote' AND SVMXC__Order_Status__c != 'Canceled'
					ORDER BY CreatedDate]);
			}
		}
		return null;
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> workOrders)
	{
		switch on this.mode
		{
			when FIELD_SERVICE {
				// countAssignments - Will need to recreate logic using SVMXC__Service_Order__History
				// calculateMetricsOnInvoicing - Will need to recreate logic using SVMXC__Service_Order__History
				this.calculateHistoricalMetrics(workOrders);

				// calculateMetricsOnTECO - Will work AS-IS
				SMAX_PS_WorkOrderMetrics.calculateMetricsOnTECO(workOrders, null);

				// calculateMetricsOnCallback - Will work AS-IS
				SMAX_PS_WorkOrderMetrics.calculateMetricsOnCallback(workOrders);
			}
			when REMOTE {
				// countAssignments - Will need to recreate logic using SVMXC__Service_Order__History.. will need to run on ALL?
				this.calculateHistoricalMetrics(workOrders);

				// calculateMetricsOnRemote: Closed "Remote" WO's will work fine
				SMAX_PS_WorkOrderMetrics.calculateMetricsOnRemote(workOrders, null);
			}
		}

		/*
			TODO: Converted "FS" from "Remote" will not create "Remote" Metrics...
			Could Use "Escalated to Field Service Datetime" to create "Remote" Metrics..
			But, that would confuse things too.. specifically the Assignments
		 */
	}

	global void finish(Database.BatchableContext BC)
	{
	}

	private void calculateHistoricalMetrics(List<SVMXC__Service_Order__c> woList)
	{
		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			woMap.put(wo.Id, wo);
		}

		Map<Id, BusinessHours> bizHoursMap = SMAX_PS_BusinessHours.lookupWorkOrderBusinessHours(woMap.keySet());

		// Lookup SVMXC__Service_Order__History and adapt logic
		List<SVMXC__Service_Order__History> history = [SELECT Id, ParentId, Field, OldValue, NewValue, CreatedDate
			FROM SVMXC__Service_Order__History WHERE ParentId IN :woMap.keySet() ORDER BY ParentId, CreatedDate];
		if (history.isEmpty() && Test.isRunningTest())
		{
			// History records are not created during a UT.. need to fake it.
			for (SVMXC__Service_Order__c wo : woList)
			{
				history.add(new SVMXC__Service_Order__History(ParentId = wo.Id, Field = 'SVMXC__Group_Member__c'));
				history.add(new SVMXC__Service_Order__History(ParentId = wo.Id, Field = 'SVMXC__Order_Status__c'));
			}
		}

		Map<String, SMAX_PS_Work_Order_Metrics__c> metrics = new Map<String, SMAX_PS_Work_Order_Metrics__c>();
		for (SVMXC__Service_Order__History woHistory : history)
		{
			SVMXC__Service_Order__c wo = woMap.get(woHistory.ParentId);

			String type = (wo.RecordTypeId == SMAX_PS_WorkOrderMetrics.REMOTE_RT.Id) ?
					SMAX_PS_WorkOrderMetrics.REMOTE_RT.DeveloperName : SMAX_PS_WorkOrderMetrics.FIELD_SERVICE_RT.DeveloperName;
			SMAX_PS_Work_Order_Metrics__c wom = SMAX_PS_WorkOrderMetrics.getMetrics(wo, type, metrics);

			if (woHistory.Field == 'SVMXC__Group_Member__c'
				&& ((woHistory.NewValue != null && woHistory.NewValue instanceof Id) || Test.isRunningTest()))
			{
				// Number of Assignments [SMAX_PS_Number_of_Assignments__c] "Dispatch Efficiency"
				// Increment Number of Times Assigned by 1 for each assignment.
				if (wom.SMAX_PS_Number_of_Assignments__c == null)
				{
					wom.SMAX_PS_Number_of_Assignments__c = 0;
				}
				wom.SMAX_PS_Number_of_Assignments__c = wom.SMAX_PS_Number_of_Assignments__c + 1;
				System.debug('~~ INCREMENTING WO METRICS: NumAssignments: ' + wo.Name + ' > ' + woHistory.NewValue + ' : ' + woHistory.CreatedDate);
				if (wom.SMAX_PS_First_Assigned_Datetime__c == null)
				{
					wom.SMAX_PS_First_Assigned_Datetime__c = (Test.isRunningTest() ? System.now() : woHistory.CreatedDate);
				}
			}
			else if (woHistory.Field == 'SVMXC__Order_Status__c'
				&& (woHistory.NewValue != null || Test.isRunningTest()))
			{
				if (woHistory.NewValue == SMAX_PS_WorkOrderMetrics.ORDER_STATUS_READY
					|| Test.isRunningTest())
				{
					wom.SMAX_PS_Ready_to_Review_Datetime__c = (Test.isRunningTest() ? System.now() : woHistory.CreatedDate);
				}
				if (woHistory.NewValue == SMAX_PS_WorkOrderMetrics.ORDER_STATUS_INVOICED
					|| Test.isRunningTest())
				{
					BusinessHours bizHours = bizHoursMap.get(wo.Id);
					wom.SMAX_PS_Invoiced_DateTime__c = (Test.isRunningTest() ? System.now() : woHistory.CreatedDate);
					// Calculated Days to Invoice [SVMXC__Service_Order__c.SMAX_PS_Calc_Days_to_Invoice__c]
					// SVMX_PS_Ready_to_Review_Date_Time__c, SMAX_PS_Invoiced_DateTime__c (IN DAYS)
					wom.SMAX_PS_Calc_Days_to_Invoice__c = SMAX_PS_BusinessHours.businessDaysBetween(bizHours,
							wom.SMAX_PS_Ready_to_Review_Datetime__c, wom.SMAX_PS_Invoiced_DateTime__c);
				}
			}
		}

		SMAX_PS_WorkOrderMetrics.upsertMetrics(metrics.values(), 'calculateHistoricalMetrics');
	}

}
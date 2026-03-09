/**
 * Created by frankvanloon on 2019-01-25.
 * SVMXINT-637 : WO 1CC - Date Cleanup / Stop-Gap
 */
global class SMAX_PS_WorkOrder_1CCFixBatch implements Database.Batchable<SObject>, Schedulable
{
	global Date START_DATE;
	global Date END_DATE;

	global SMAX_PS_WorkOrder_1CCFixBatch() { }
	global SMAX_PS_WorkOrder_1CCFixBatch(Date singleDate)
	{
		this.START_DATE = singleDate;
		this.END_DATE = singleDate.addDays(1);
	}
	global SMAX_PS_WorkOrder_1CCFixBatch(Date startDate, Date endDate)
	{
		this.START_DATE = startDate;
		this.END_DATE = endDate;
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		SMAX_PS_WorkOrder_1CCFixBatch btch = new SMAX_PS_WorkOrder_1CCFixBatch(this.START_DATE, this.END_DATE);
		Database.executeBatch(btch);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		if (this.START_DATE == null)
		{
			// Default to "Yesterday"
			this.START_DATE = Date.today().addDays(-1);
		}
		if (this.END_DATE == null)
		{
			this.END_DATE = this.START_DATE.addDays(1);
		}

		System.debug('~~ FINDING WO with Completed Dates between: ' + this.START_DATE + ' - ' + this.END_DATE);
		return Database.getQueryLocator([SELECT Id, Name, SVMXC__Order_Status__c
			FROM SVMXC__Service_Order__c
			WHERE SVMXC__Completed_Date_Time__c > :START_DATE AND SVMXC__Completed_Date_Time__c < :END_DATE
				AND SVMXC__Order_Status__c NOT IN ('Work Complete - Error', 'Work Complete - Pending')
		]);
	}

	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> workOrders)
	{
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		for (SVMXC__Service_Order__c wo : workOrders)
		{
			SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
			iEvent.SMAX_PS_Action__c = 'UPDATE';
			iEvent.SMAX_PS_WorkOrderId__c = wo.Id;
			events.add(iEvent);
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
	}

	global void finish(Database.BatchableContext BC)
	{
	}
}
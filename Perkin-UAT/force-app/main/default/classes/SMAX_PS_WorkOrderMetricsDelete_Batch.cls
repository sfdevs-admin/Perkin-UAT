/**
 * Created by frankvanloon on 11/20/20.
 * Deletes Work Order Metrics - Needed due to high data volumes, for recalculating records
 */
global class SMAX_PS_WorkOrderMetricsDelete_Batch implements Database.Batchable<SObject>  {

	global Id USER_ID;
	global Date START_DATE;
	global Date END_DATE;

	global SMAX_PS_WorkOrderMetricsDelete_Batch(Id userId, Date startDt, Date endDt) {
		this.USER_ID = userId;
		this.START_DATE = startDt;
		this.END_DATE = endDt;
	}

	global Database.QueryLocator start(Database.BatchableContext ctx) {
		return Database.getQueryLocator([SELECT Id FROM SMAX_PS_Work_Order_Metrics__c
			WHERE CreatedById = :USER_ID AND CreatedDate >= :START_DATE AND CreatedDate <= :END_DATE]);
	}

	global void execute(Database.BatchableContext ctx, List<SMAX_PS_Work_Order_Metrics__c> scope) {
		delete scope;
	}

	global void finish(Database.BatchableContext ctx) {
	}

}
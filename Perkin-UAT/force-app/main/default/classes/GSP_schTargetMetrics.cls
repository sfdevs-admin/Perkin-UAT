global class GSP_schTargetMetrics implements Schedulable
{
	global void execute(SchedulableContext ctx)
	{
		Batch_Target_Settings__c batchSettings = Batch_Target_Settings__c.getValues('Default');
		GSP_batchTargetAssignment batch = new GSP_batchTargetAssignment('OPPORTUNITY');
		Database.executeBatch(batch, Integer.valueOf(batchSettings.Opportunity_Target_Batch_Size__c));
	}
}
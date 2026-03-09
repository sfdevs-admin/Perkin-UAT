@isTest
private class GSP_schTargetMetrics_TEST
{
	@isTest
	private static void test_schTargetMetrics()
	{
		Batch_Target_Settings__c batchSettings = new Batch_Target_Settings__c(
			Name = 'Default',
			Lead_Metrics_Batch_Size__c = 100,
			Lead_Target_Batch_Size__c = 100,
			Line_Item_Target_Batch_Size__c = 100,
			Opportunity_Metrics_Batch_Size__c = 100,
			Opportunity_Target_Batch_Size__c = 100,
			Product_Line_Metrics_Batch_Size__c = 100,
			Rgn_Product_Line_Metrics_Batch_Size__c = 100,
			Zero_Month_Rep_Target_Batch_Size__c = 1000,
			Zero_Month_Territory_Target_Batch_Size__c = 100,
			Zero_Product_Lead_Batch_Size__c = 1000,
			Zero_Rep_Product_Line_Target_Batch_Size__c = 1000,
			Zero_Rgn_Product_Line_Target_Batch_Size__c = 1000);
		insert batchSettings;
		System.assertNotEquals(batchSettings.Id, null);
		
		String CRON_EXP = '0 0 0 3 9 ? 2026';
		Test.startTest();
		String jobId = System.schedule('testPEScheduledApex', CRON_EXP,  new GSP_schTargetMetrics());
      	
      	CronTrigger ct = [
      		SELECT
      			id,
      			CronExpression,
      			TimesTriggered,
      			NextFireTime
         	FROM
         		CronTrigger
         	WHERE id = : jobId];
         
         //System.assertEquals(CRON_EXP, ct.CronExpression);
         //System.assertEquals(0, ct.TimesTriggered);
         //System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
         Test.stopTest();
	}
}
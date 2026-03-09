@isTest
private class GSP_batchZeroTargets_TEST
{
	private static Map<Integer, String> monthToStringMap = new Map<Integer, String>{ 1 => '01-Jan', 2 => '02-Feb', 3 => '03-Mar', 4 => '04-Apr', 5 => '05-May',
		6 => '06-Jun', 7 => '07-Jul', 8 => '08-Aug', 9 => '09-Sep', 10 => '10-Oct', 11 => '11-Nov', 12 => '12-Dec' };
	private static String PRODUCT_LINE = 'SOS';
	
	@isTest
	private static void test_batchZeroTargets()
	{
		InsertBatchSettings();
		Month_Rep_Target__c monthRepTarget = new Month_Rep_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.getUserId());
		insert monthRepTarget;
		System.assertNotEquals(monthRepTarget.Id, null);
		
		Month_Territory_Target__c monthTerritoryTarget = new Month_Territory_Target__c(
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(),
			Month__c = monthToStringMap.get(Date.today().month()),
			Unique_Field__c = 'Apex Test Territory');
		insert monthTerritoryTarget;
		System.assertNotEquals(monthTerritoryTarget.Id, null);
		
		Rep_Product_Line_Target__c repProductLineTarget = new Rep_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.GetUserId(),
			Product_Line__c = PRODUCT_LINE);
		insert repProductLineTarget;
		System.assertNotEquals(repProductLineTarget.Id, null);
		
		Region_Product_Line_Target__c regionProductLineTarget = new Region_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE);
		insert regionProductLineTarget;
		System.assertNotEquals(regionProductLineTarget.Id, null);
		
		Region_Product_Line_Target_Leads__c regionProductLineTargetLead = new Region_Product_Line_Target_Leads__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(), 
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Leads_Created__c = 1000);
		insert regionProductLineTargetLead;
		System.assertNotEquals(regionProductLineTargetLead.Id, null);
		
		GSP_batchZeroTargets batch = new GSP_batchZeroTargets('MONTH_REP_TARGET');
		Database.executeBatch(batch, 1);
	}

	private static void InsertBatchSettings()
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
	}
}
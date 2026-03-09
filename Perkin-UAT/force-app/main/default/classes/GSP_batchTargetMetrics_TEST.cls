@isTest
private class GSP_batchTargetMetrics_TEST
{
	@isTest(seeAllData=true)
	private static void test_GSP_batchTargetMetrics()
	{		
        Month_Territory_Target__c tar = new Month_Territory_Target__c();
        insert tar;
        
        opportunity opp = new opportunity();
        opp.name = 'test';
        opp.closedate = date.today();
        opp.Month_territory_Target__c = tar.id;
        opp.StageName = 'Zero Stage';
        insert opp;
        
		GSP_batchTargetMetrics batch = new GSP_batchTargetMetrics('OPPORTUNITY');        
		Database.executeBatch(batch, 1);
	}
}
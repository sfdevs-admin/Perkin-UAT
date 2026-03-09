global class GSP_batchZeroTargets implements Database.Batchable<sObject>, Database.Stateful
{
	private String strQuery;
	private String strObjectType;
	
	global GSP_batchZeroTargets(String strObjectType)
	{
		System.debug('\n\nZERO: ' + strObjectType + '\n\n');
		this.strObjectType = strObjectType;
		
		if (this.strObjectType == 'MONTH_REP_TARGET')
		{
			strQuery = 'SELECT Id, Won_Revenue__c, Pipeline_Opportunities__c, Commit_Opportunities__c, Commit_Amount__c, Closed_Won_Opportunities__c,' +
				' Closed_Lost_Opportunities__c, Closed_Lost_Amount__c FROM Month_Rep_Target__c WHERE (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY OR' +
				' CreatedDate = NEXT_N_MONTHS:6) AND (Won_Revenue__c != 0 OR Pipeline_Opportunities__c != 0 OR Commit_Opportunities__c != 0 OR' +
				' Commit_Amount__c != 0 OR Closed_Won_Opportunities__c != 0 OR Closed_Lost_Opportunities__c != 0 OR Closed_Lost_Amount__c != 0)';
		}
		else if (this.strObjectType == 'MONTH_TERRITORY_TARGET')
		{
			strQuery = 'SELECT Id, Won_Revenue__c, Pipeline_Opportunities__c, Commit_Amount__c, Closed_Won_Opportunities__c, Closed_Lost_Opportunities__c,' +
				' Closed_Lost_Amount__c FROM Month_Territory_Target__c WHERE (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY OR CreatedDate = NEXT_N_MONTHS:6) AND' +
				' (Won_Revenue__c != 0 OR Pipeline_Opportunities__c != 0 OR Commit_Amount__c != 0 OR Closed_Won_Opportunities__c != 0 OR Closed_Lost_Opportunities__c != 0' +
				' OR Closed_Lost_Amount__c != 0)';
		}
		else if (this.strObjectType == 'REP_PRODUCT_LINE_TARGET')
		{
			strQuery = 'SELECT Id, Won_Revenue__c, Won_Quantity__c, Commit_Quantity__c, Commit_Amount__c, Closed_Lost_Amount__c' +
				' FROM Rep_Product_Line_Target__c WHERE (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY OR CreatedDate = NEXT_N_MONTHS:6)' +
				' AND (Won_Revenue__c != 0 OR Commit_Quantity__c != 0 OR Commit_Amount__c != 0 OR Closed_Lost_Amount__c != 0)';
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET')
		{
			strQuery = 'SELECT Id, Won_Revenue__c, Won_Quantity__c, Pipeline_Created__c, Pipeline_Created_Qty__c, Commit_Quantity__c, Commit_Amount__c,' +
				' Closed_Lost_Quantity__c, Closed_Lost_Amount__c FROM Region_Product_Line_Target__c WHERE (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY OR' +
				' CreatedDate = NEXT_N_MONTHS:6) AND (Won_Revenue__c != 0 OR Won_Quantity__c != 0 OR Pipeline_Created__c != 0 OR Pipeline_Created_Qty__c != 0 OR' +
				' Commit_Quantity__c != 0 OR Closed_Lost_Quantity__c != 0 OR Closed_Lost_Amount__c != 0)';
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET_LEAD')
		{
			strQuery = 'SELECT Id, Leads_Created__c FROM Region_Product_Line_Target_Leads__c WHERE (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY OR' +
			' CreatedDate = NEXT_N_MONTHS:6) AND Leads_Created__c != 0';
		}
		if (Test.IsRunningTest())
		{
			strQuery += ' LIMIT 1';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(strQuery);
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		if (this.strObjectType == 'MONTH_REP_TARGET')
		{
			GSP_targetAssignmentHelper.ZeroMonthRepTargets((List<Month_Rep_Target__c>)scope);
		}
		else if (this.strObjectType == 'MONTH_TERRITORY_TARGET')
		{
			GSP_targetAssignmentHelper.ZeroMonthTerritoryTarget((List<Month_Territory_Target__c>)scope);
		}
		else if (this.strObjectType == 'REP_PRODUCT_LINE_TARGET')
		{
			GSP_targetAssignmentHelper.ZeroRepProductLineTarget((List<Rep_Product_Line_Target__c>)scope);
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET')
		{
			GSP_targetAssignmentHelper.ZeroRegionProductLineTarget((List<Region_Product_Line_Target__c>)scope);
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET_LEAD')
		{
			GSP_targetAssignmentHelper.ZeroRegionProductLineTargetLead((List<Region_Product_Line_Target_Leads__c>)scope);
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
		Batch_Target_Settings__c batchSettings = Batch_Target_Settings__c.getValues('Default');
		if (this.strObjectType == 'MONTH_REP_TARGET')
		{
			GSP_batchZeroTargets batch = new GSP_batchZeroTargets('MONTH_TERRITORY_TARGET');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Zero_Month_Territory_Target_Batch_Size__c));
		}
		else if (this.strObjectType == 'MONTH_TERRITORY_TARGET')
		{
			GSP_batchZeroTargets batch = new GSP_batchZeroTargets('REP_PRODUCT_LINE_TARGET');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Zero_Rep_Product_Line_Target_Batch_Size__c));
		}
		else if (this.strObjectType == 'REP_PRODUCT_LINE_TARGET')
		{
			GSP_batchZeroTargets batch = new GSP_batchZeroTargets('REGION_PRODUCT_LINE_TARGET');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Zero_Rgn_Product_Line_Target_Batch_Size__c));
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET')
		{
			GSP_batchZeroTargets batch = new GSP_batchZeroTargets('REGION_PRODUCT_LINE_TARGET_LEAD');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Zero_Product_Lead_Batch_Size__c));
		}
		else if (this.strObjectType == 'REGION_PRODUCT_LINE_TARGET_LEAD')
		{
			GSP_batchTargetMetrics batch = new GSP_batchTargetmetrics('OPPORTUNITY');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Opportunity_Metrics_Batch_Size__c));
		}
	}
}
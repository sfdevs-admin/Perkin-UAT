global class GSP_batchTargetMetrics  implements Database.Batchable<sObject>, Database.Stateful
{
	private String strObjectType;
	private String strQuery;
	
	global GSP_batchTargetMetrics(String strObjectType)
	{
		System.debug('\n\nMETRICS: ' + strObjectType + '\n\n');
		this.strObjectType = strObjectType;
		if (strObjectType == 'OPPORTUNITY')
		{
			strQuery = 'SELECT Id, IsClosed, IsWon, ForecastCategoryName, Month_Rep_Target__c, Month_Territory_Target__c, Amount' +
				' FROM Opportunity WHERE (Month_Rep_Target__c != null OR Month_Territory_Target__c != null) AND (CloseDate =' +
				' LAST_N_DAYS:365 OR CloseDate = THIS_MONTH OR CloseDate = NEXT_N_MONTHS:6) ORDER BY OwnerId';
		}
		else if (this.strObjectType == 'OPPORTUNITY_LINE_ITEM')
		{
			strQuery = 'SELECT Id, TotalPrice, Opportunity.ForecastCategoryName, IGOR_PAC__c, Rep_Product_Line_Target__c,' +
				' Region_Product_Line_Target__c, Opportunity.IsWon, Opportunity.IsClosed FROM OpportunityLineItem WHERE' +
				' (Rep_Product_Line_Target__c != null OR Region_Product_Line_Target__c != null) AND' +
				' (Opportunity.CloseDate = LAST_YEAR OR Opportunity.CloseDate = THIS_MONTH OR Opportunity.CloseDate = NEXT_N_MONTHS:6) ORDER BY Opportunity.OwnerId';
		}
		else if (this.strObjectType == 'LEAD')
		{
			strQuery = 'SELECT Id, Region_Product_Line_Target_Lead__c FROM Lead WHERE Region_Product_Line_Target_Lead__c != null' +
				' AND (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = THIS_MONTH OR CreatedDate = NEXT_N_MONTHS:6)';
		}
		if (test.IsRunningTest())
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
		if (this.strObjectType == 'OPPORTUNITY')
		{
			GSP_targetAssignmentHelper.SumOpportunityTargets((List<Opportunity>)scope);
		}
		else if (this.strObjectType == 'OPPORTUNITY_LINE_ITEM')
		{
			GSP_targetAssignmentHelper.SumProductLineTargets((List<OpportunityLineItem>)scope);
		}
		else if (this.strObjectType == 'LEAD')
		{
			GSP_targetAssignmentHelper.SumLeadTargets((List<Lead>)scope);
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
		Batch_Target_Settings__c batchSettings = Batch_Target_Settings__c.getValues('Default');
        if(!Test.isRunningTest()) {
            if (this.strObjectType == 'OPPORTUNITY')
            {
                GSP_batchTargetMetrics batch = new GSP_batchTargetMetrics('OPPORTUNITY_LINE_ITEM');
                Database.executebatch(batch, Integer.valueOf(batchSettings.Product_Line_Metrics_Batch_Size__c));
            }
            else if (this.strObjectType == 'OPPORTUNITY_LINE_ITEM')
            {
                GSP_batchTargetMetrics batch = new GSP_batchTargetMetrics('LEAD');
                Database.executebatch(batch, Integer.valueOf(batchSettings.Lead_Metrics_Batch_Size__c));
            }
            else
            {
                System.debug('\n\nDONE\n\n');
            }
        }
	}
}
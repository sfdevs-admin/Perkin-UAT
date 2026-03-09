global class GSP_batchTargetAssignment implements Database.Batchable<sObject>, Database.Stateful
{
	private String strQuery;
	private String strObjectType;
	
	global GSP_batchTargetAssignment(String strObjectType)
	{
		System.debug('\n\nASSIGN TYPE: ' + strObjectType + '\n\n');
		this.strObjectType = strObjectType;
		if (strObjectType == 'OPPORTUNITY')
		{
			strQuery = 'SELECT Id, OwnerId, CloseDate, Month_Rep_Target__c, Territory2.Name FROM Opportunity WHERE Month_Rep_Target__c = null OR Month_Territory_Target__c = null';
		}
		else if (strObjectType == 'OPPORTUNITY_LINE_ITEM')
		{
			strQuery = 'SELECT Id, Product_Line__c, Rep_Product_Line_Target__c,  Region_Product_Line_Target__c, Opportunity.OwnerId,' +
				' Opportunity.CloseDate, Opportunity.Global_Region__c FROM OpportunityLineItem WHERE Rep_Product_Line_Target__c = null' +
				' OR Region_Product_Line_Target__c = null';
		}
		else
		{
			strQuery = 'SELECT Id, Product_Line__c, Global_Region__c, CreatedDate, Region_Product_Line_Target_Lead__c FROM Lead' +
				' WHERE Region_Product_Line_Target_Lead__c = null AND IsConverted = false';
		}
		
		if (Test.isRunningTest())
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
			GSP_targetAssignmentHelper.AssignOpportunityTargets((List<Opportunity>)scope);
		}
		else if (this.strObjectType == 'OPPORTUNITY_LINE_ITEM')
		{
			GSP_targetAssignmentHelper.AssignOpportunityLineItemTargets((List<OpportunityLineItem>) scope);
		}
		else if (this.strObjectType == 'LEAD')
		{
			GSP_targetAssignmentHelper.AssignLeadTargets((List<Lead>)scope);
		}	
	}
	
	global void finish(Database.BatchableContext BC)
	{
		Batch_Target_Settings__c batchSettings = Batch_Target_Settings__c.getValues('Default');
		
		// Process all lookups
		if (this.strObjectType == 'OPPORTUNITY')
		{
			GSP_batchTargetAssignment batch = new GSP_batchTargetAssignment('OPPORTUNITY_LINE_ITEM');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Line_Item_Target_Batch_Size__c));
		}
		else if (this.strObjectType == 'OPPORTUNITY_LINE_ITEM')
		{
			GSP_batchTargetAssignment batch = new GSP_batchTargetAssignment('LEAD');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Lead_Target_Batch_Size__c));
		}
		else if (this.strObjectType == 'LEAD')
		{
			// Start processing zeroing of fields
			GSP_batchZeroTargets batch = new GSP_batchZeroTargets('MONTH_REP_TARGET');
			Database.executeBatch(batch, Integer.valueOf(batchSettings.Zero_Month_Rep_Target_Batch_Size__c));
		}
	}
}
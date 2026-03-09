@isTest
private class GSP_TriggerContext_TEST
{
	@isTest
	private static void test_TriggerContext()
	{
		GSP_TriggerContext.DisableAllTriggers			= true;
		GSP_TRiggerContext.DisableOpportunityTriggers	= true;
		GSP_TRiggerContext.DisableLeadTriggers			= true;
		
		GSP_TriggerContext.DisableAllTriggers			= false;
		GSP_TRiggerContext.DisableOpportunityTriggers	= false;
		GSP_TRiggerContext.DisableLeadTriggers			= false;
	}
}
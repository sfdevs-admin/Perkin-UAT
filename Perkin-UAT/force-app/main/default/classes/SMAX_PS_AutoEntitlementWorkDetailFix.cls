global class SMAX_PS_AutoEntitlementWorkDetailFix implements Database.Batchable<sObject> {
	
	
	global SMAX_PS_AutoEntitlementWorkDetailFix() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id, Name,
			SMAX_PS_ContractEntitlement__c,
			(SELECT Id, Name, SVMXC__Product__c, SMAX_PS_ContractPercentDiscount__c, SVMXC__Line_Type__c
				FROM SVMXC__Service_Order_Line__r WHERE SVMXC__Product__c != null 
					AND SVMXC__Line_Type__c IN ('Parts', 'Labor', 'Travel', 'Expenses'))
			FROM SVMXC__Service_Order__c
			WHERE SVMXC__Entitlement_Type__c = 'SAP' AND SMAX_PS_ContractEntitlement__c != null]);
	}

   	global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope) {
		for (SVMXC__Service_Order__c wo : scope)
		{
			List<SVMXC__Service_Order_Line__c> lines = wo.SVMXC__Service_Order_Line__r;
			if (lines != null && !lines.isEmpty())
		   	{
		   		SMAX_PS_WorkOrderPricingService.applyContractDiscounts(wo, lines);
		   		update lines;
		   	}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
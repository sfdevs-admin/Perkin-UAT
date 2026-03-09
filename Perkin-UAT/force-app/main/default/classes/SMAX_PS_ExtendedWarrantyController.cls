/**
 * Created by frankvanloon on 11/19/20.
 */

public with sharing class SMAX_PS_ExtendedWarrantyController {

	public SVMXC__Service_Order__c wo;
	public Boolean isRunning { get; set; }

	public SMAX_PS_ExtendedWarrantyController(ApexPages.StandardController stdController)
	{
		wo = [SELECT Id, Name, SMAX_PS_IsEntitledWarranty__c, SVMXC__Component__c
		FROM SVMXC__Service_Order__c
		WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
	}

	// ITSVMX-185 Recalculate Extended Warranty Coverage
	public void recalculate()
	{
		this.isRunning = TRUE;
		Id woId = this.wo.Id;
		List<BD_Extended_Warranty_Coverage__c> existingCoverage = [SELECT Id, Name, BD_Parent_Work_Order__c
		FROM BD_Extended_Warranty_Coverage__c WHERE BD_Parent_Work_Order__c = :woId];
		if (!existingCoverage.isEmpty()) {
			delete existingCoverage;
		}

		SMAX_PS_ExtendedWarranty.createCoverage(new List<SVMXC__Service_Order__c> { this.wo });
	}
}
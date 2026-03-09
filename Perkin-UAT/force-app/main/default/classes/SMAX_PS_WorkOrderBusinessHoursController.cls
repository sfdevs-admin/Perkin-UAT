/**
 * Created by frankvanloon on 2019-06-04.
 * ITSFDC-1161 (old SVMXCFG-1108) Created to support the editing of the Preferred Business Hours field
 */
public with sharing class SMAX_PS_WorkOrderBusinessHoursController {

	public SVMXC__Service_Order__c wo { get; set; }

	public SMAX_PS_WorkOrderBusinessHoursController(ApexPages.StandardController controller)
	{
		Id woId = ((SVMXC__Service_Order__c)controller.getRecord()).Id;
		this.wo = [SELECT Id, Name, SVMXC__Preferred_Business_Hours__c FROM SVMXC__Service_Order__c WHERE Id = :woId];
	}

	public PageReference saveWO()
	{
		update wo;
		return new PageReference('/' + wo.Id);
	}
}
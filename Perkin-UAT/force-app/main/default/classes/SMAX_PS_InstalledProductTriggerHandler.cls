/*
 *  Trigger Handler for Installed Product [SVMXC__Installed_Product__c]
 *  2017-08-14      Veerendra Moodbidri       Initial creation, for Installed Product Integration.
 *  2022-10-24      Bolt Data - E. Ross      MOdifications for Polaris Project.
 */

public with sharing class SMAX_PS_InstalledProductTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

	public SMAX_PS_InstalledProductTriggerHandler() {
	}

	public void beforeInsert()
	{
		List<SVMXC__Installed_Product__c> newList = Trigger.new;

		SMAX_PS_InstalledProductManager.updateIPAddressFields(newList, null);
		SMAX_PS_InstalledProductManager.updateLookups(newList, null);
		BD_Address_i18n.formatAddressTrigger(newList, null);
		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
	}

	public void afterInsert() {}
	public void beforeUpdate() 
	{
		List<SVMXC__Installed_Product__c> newList = Trigger.new;
		Map<Id, SVMXC__Installed_Product__c> oldMap = (Map<Id, SVMXC__Installed_Product__c>) Trigger.oldMap;
		// SVMXCFG-482 - Update IP Address when Location changes
		SMAX_PS_InstalledProductManager.updateIPAddressFields(newList, oldMap);
		SMAX_PS_InstalledProductManager.updateLookups(newList, oldMap);
		// SVMXCFG-253 - Calibrated Tool Log - 20180124
		SMAX_PS_InstalledProductManager.calibratedToolChangeLog(newList, oldMap);
		BD_Address_i18n.formatAddressTrigger(newList, oldMap);
		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
	}
	public void afterUpdate() 
	{
		List<SVMXC__Installed_Product__c> newList = Trigger.new;
		Map<Id, SVMXC__Installed_Product__c> oldMap = (Map<Id, SVMXC__Installed_Product__c>) Trigger.oldMap;
		SMAX_PS_InstalledProductManager.deleteIPclassifications(newList, oldMap);
	}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}
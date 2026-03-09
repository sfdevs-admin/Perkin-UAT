/**
 *  Trigger Handler for Contact [Contact]
 *  2017-07-14		Frank VanLoon		Initial creation, for Outbound Contact Integration.
 */
public with sharing class SMAX_PS_ContactTriggerHandler implements SMAX_PS_Utility.ITriggerHandler
{
	public SMAX_PS_ContactTriggerHandler() {
	}

	public void beforeInsert() 
	{
		List<Contact> newList = Trigger.new;

		SMAX_PS_ContactManager.updateSAPFields(newList, null);
		SMAX_PS_ContactManager.updateContactAccount(newList, null);
		SMAX_PS_ContactManager.truncateFields(newList, null);
	}

	public void afterInsert()
	{
		List<Contact> newList = Trigger.new;

		SMAX_PS_ContactManager.createContactEvents(newList, null);
	}

	public void beforeUpdate() 
	{
		List<Contact> newList = Trigger.new;
		Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;

		SMAX_PS_ContactManager.updateSAPFields(newList, oldMap);
		SMAX_PS_ContactManager.updateContactAccount(newList, oldMap);
		SMAX_PS_ContactManager.truncateFields(newList, oldMap);
	}

	public void afterUpdate()
	{
		List<Contact> newList = Trigger.new;
		Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;

		SMAX_PS_ContactManager.createContactEvents(newList, oldMap);
	}

	public void beforeDelete() {}
	public void afterDelete() 
	{
		List<Contact> oldList = Trigger.old;

		SMAX_PS_ContactManager.createContactEvents(oldList, null);
	}

	public void afterUndelete() 
	{
		List<Contact> newList = Trigger.new;

		SMAX_PS_ContactManager.createContactEvents(newList, null);
	}

}
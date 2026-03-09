/**
 * Created by frankvanloon on 2018-11-27.
 */
public with sharing class SMAX_PS_AccountTriggerHandler implements SMAX_PS_Utility.ITriggerHandler
{
	public void beforeInsert() {
	}

	public void afterInsert() {
	}

	public void beforeUpdate() {
		List<Account> newList = Trigger.new;
		Map<Id, Account> oldMap = (Map<Id, Account>) Trigger.oldMap;

		SMAX_PS_LocationManager.updateStorageAddress(newList, oldMap);
	}

	public void afterUpdate() {
	}

	public void beforeDelete() {
	}

	public void afterDelete() {
	}

	public void afterUndelete() {
	}

}
/**
 * Created by frankvanloon on 11/16/20.
 */

public with sharing class SMAX_PS_StockedSerialTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
	
	public void beforeInsert() {
	}

	public void afterInsert() {
		List<SVMXC__Product_Serial__c> newList = Trigger.new;
		
        if(!newList.isEmpty()) {
			SMAX_PS_InventoryManager.stockedSerialReplacements(newList);
        }
	}

	public void beforeUpdate() {
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
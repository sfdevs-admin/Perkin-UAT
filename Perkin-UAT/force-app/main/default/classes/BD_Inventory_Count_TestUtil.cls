/**
 * Created by frankvanloon on 5/28/20.
 */

public with sharing class BD_Inventory_Count_TestUtil
{

	public static void createTestInventoryCount(String locName)
	{
		SVMXC__Site__c loc = [SELECT Id, Name, SMAX_PS_LocationCode__c, SMAX_PS_MaintenancePlant__c
			FROM SVMXC__Site__c WHERE Name = :locName AND SVMXC__Stocking_Location__c = TRUE];

		List<SMAX_PS_InventoryCount__c> existingCounts = [SELECT Id, Name, SMAX_PS_Status__c
			FROM SMAX_PS_InventoryCount__c WHERE SMAX_PS_RequestedFrom__c = :loc.Id];
		if (!existingCounts.isEmpty()) {
			System.debug('Existing Inventory Counts found, exiting... ' + existingCounts);
			return;
		}

		SMAX_PS_InventoryCount__c count = new SMAX_PS_InventoryCount__c(SMAX_PS_Status__c = 'Open',
			SMAX_PS_RequestedFrom__c = loc.Id, SMAX_PS_DocumentDate__c = Date.today(),
			SMAX_PS_PlannedDate__c = Date.today().addDays(14), OwnerId = UserInfo.getUserId());
		insert count;

		List<SMAX_PS_InventoryCountLine__c> lines = new List<SMAX_PS_InventoryCountLine__c>();
		List<SVMXC__Product_Stock__c> availStock = [SELECT Id, Name, SVMXC__Status__c, SVMXC__Product__c, SVMXC__Quantity2__c
			FROM SVMXC__Product_Stock__c WHERE SVMXC__Location__c = :loc.Id AND SVMXC__Status__c = 'Available'];
		for (SVMXC__Product_Stock__c stock : availStock)
		{
			SMAX_PS_InventoryCountLine__c line = new SMAX_PS_InventoryCountLine__c(SMAX_PS_InventoryCount__c = count.Id,
				SMAX_PS_ProductStock__c = stock.Id, SMAX_PS_Product__c = stock.SVMXC__Product__c, SMAX_PS_InvCnt_Status__c = 'Open',
				SMAX_PS_BookedQty__c = stock.SVMXC__Quantity2__c);
			lines.add(line);
		}
		insert lines;
		System.debug('Created Inventory Count with ' + lines.size() + ' lines.');
	}
}
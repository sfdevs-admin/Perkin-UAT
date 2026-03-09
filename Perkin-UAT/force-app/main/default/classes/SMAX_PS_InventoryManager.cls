/**
 * Updates
 * 04/05/2022	Tony	ITSVMX-562 Modify the replenishment parts ordering process in SVMX to automatically change the ordered part from new to refurbished if a refurbished option is available IF the customer/contract allows
 * 06/10/2022	Tony	Fix SVMXC__Product__c and Partnum__c being set to null when no refurbished part was found
*/

public with sharing class SMAX_PS_InventoryManager {

	private SMAX_PS_InventoryManager() {
	}

	public static void createStockTransferEvents(List<SVMXC__Stock_Transfer__c> transfers, Map<Id, SVMXC__Stock_Transfer__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Create Stock Transfer Events', 'Create Inventory Platform Events when Stock Transfers are Submitted.'))
			return;

		List<SMAX_PS_Inventory_Event__e> events = new List<SMAX_PS_Inventory_Event__e>();
		for (SVMXC__Stock_Transfer__c stockTransfer : transfers)
		{
			SVMXC__Stock_Transfer__c old = (oldMap == null) ? null : oldMap.get(stockTransfer.Id);
			if (stockTransfer.SMAX_PS_Status__c == 'Submitted'
					&& (old == null || stockTransfer.SMAX_PS_Status__c != old.SMAX_PS_Status__c))
			{
				SMAX_PS_Inventory_Event__e iEvent = new SMAX_PS_Inventory_Event__e();
				iEvent.SMAX_PS_Action__c = 'STOCK_TRANSFER';
				iEvent.SMAX_PS_StockTransferId__c = stockTransfer.Id;
				events.add(iEvent);
			}
		}

		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_StockTransferId__c', 'SMAX_PS_Action__c');
	}

	public static void afterUpdateComplete(List<SVMXC__Product_Stock__c> newPStockList, Map<Id, SVMXC__Product_Stock__c> oldPStockMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Product Stock Complete', 'Update Product, Stocked Serial and Delete Product Stock.'))
			return;

		Set<Id> pStockIds = new Set<Id>();
		Set<Id> pdIds = new Set<Id>();
		for (SVMXC__Product_Stock__c ps : newPStockList)
		{
			SVMXC__Product_Stock__c old = (oldPStockMap == null) ? null : oldPStockMap.get(ps.Id);
			if ( old != null && old.SMAX_PS_CompletedTxnNum__c != ps.SMAX_PS_CompletedTxnNum__c )
				pStockIds.add(ps.id);
			if(ps.SVMXC__Product__c != null)
				pdIds.add(ps.SVMXC__Product__c);

		}
		if (pStockIds.isEmpty())
			return;

		List<SVMXC__Product_Serial__c> ssList = [SELECT id, name, SMAX_PS_LastTxnNum__c, SVMXC__Product_Stock__c, SVMXC__Active__c
		FROM SVMXC__Product_Serial__c WHERE SVMXC__Product_Stock__c In :pStockIds];
		Map<id, list<SVMXC__Product_Serial__c>> ssMap = new Map<id, list<SVMXC__Product_Serial__c>>();

		//Get the Related Product
		Map<Id, Product2> pdMap = null;
		if (!pdIds.isEmpty())
		{
			pdMap = new Map<Id, Product2>([SELECT Id,   SMAX_PS_Include_in_Download__c
			FROM Product2 WHERE Id IN :pdIds]);
		}
		// Fill in Stocked Serial map
		for (SVMXC__Product_Serial__c ss : ssList)
		{
			if(!ssMap.containskey(ss.SVMXC__Product_Stock__c))
				ssMap.put(ss.SVMXC__Product_Stock__c, new List<SVMXC__Product_Serial__c>());

			ssMap.get(ss.SVMXC__Product_Stock__c).add(ss);
		}

		// Main process
		List<SVMXC__Product_Stock__c> stockToDelete = new List<SVMXC__Product_Stock__c>();
		List<SVMXC__Product_Serial__c> ssUpdateList = new List<SVMXC__Product_Serial__c>();
		List<Product2> pdToUpdate = new List<Product2>();
		for ( SVMXC__Product_Stock__c  ps : newPStockList )
		{
			List<SVMXC__Product_Serial__c> listSerial = (ssMap.ContainsKey(ps.Id)) ? ssMap.get(ps.Id) : null;

			if (listSerial == null)
			{
				// No Stocked Serials.. should we delete it?
				if (ps.SVMXC__Status__c != 'Available' && ps.SVMXC__Quantity2__c == 0)
				{
					SVMXC__Product_Stock__c psd = new SVMXC__Product_Stock__c();
					psd.Id = ps.Id;
					stockToDelete.add(psd);
				}
			}
			else
			{
				for (SVMXC__Product_Serial__c ss : listSerial)
				{
					if (ss.SMAX_PS_LastTxnNum__c != ps.SMAX_PS_CompletedTxnNum__c) {
						ss.SMAX_PS_Quantity__c = 0;
						ss.SVMXC__Active__c = false;
						ssUpdateList.add(ss);
					} else if (ss.SVMXC__Active__c == false) {
						ss.SVMXC__Active__c = true;
						ssUpdateList.add(ss);
					}
				}
			}
			//Add to Mobile Download Criteria if Available and greater than 0 in quantity
			if (ps.SVMXC__Status__c == 'Available' && ps.SVMXC__Quantity2__c > 0){
				Product2 pd = (pdMap == null) ? null : pdMap.get(ps.SVMXC__Product__c);
				if(pd != null){
					pd.SMAX_PS_Include_in_Download__c = TRUE;
					pdToUpdate.add(pd);
				}
			}
		}

		// Update Stocked Serial
		if (!ssUpdateList.isEmpty())
			update ssUpdateList;
		if(!pdToUpdate.isEmpty())
			update pdToUpdate;
		if (!stockToDelete.isEmpty())
		{
			//delete stockToDelete;
			Database.DeleteResult[] results = Database.delete(stockToDelete, false);
			for (Integer i = 0; i < results.size(); i++)
			{
				Database.DeleteResult result = results[i];
				if (!result.isSuccess())
				{
					System.debug('Error deleting Product Stock: ' + result.getId() + ' with Error: ' + result.getErrors());
				}
			}
		}
	}

//	public static void copyInventoryCountTechs(List<SMAX_PS_InventoryCount__c> invCountList)
//	{
//		if (!SMAX_PS_Utility.isActive('Copy Inventory Count Techs', 'Copy Inventory Count Technicians on Create.'))
//			return;
//
//		Set<Id> locIds = new Set<Id>();
//		for (SMAX_PS_InventoryCount__c invCount : invCountList)
//		{
//			if (invCount.SMAX_PS_RequestedFrom__c != null)
//				locIds.add(invCount.SMAX_PS_RequestedFrom__c);
//		}
//
//		if (locIds.isEmpty())
//			return;
//
//		Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SVMXC__Service_Engineer__c
//		FROM SVMXC__Site__c WHERE Id IN :locIds]);
//		Set<Id> userIds = new Set<Id>();
//		for (SMAX_PS_InventoryCount__c invCount : invCountList)
//		{
//			if (invCount.SMAX_PS_RequestedFrom__c != null)
//			{
//				SVMXC__Site__c loc = locMap.get(invCount.SMAX_PS_RequestedFrom__c);
//				if (loc.SVMXC__Service_Engineer__c != null)
//				{
//					invCount.SMAX_PS_Service_Engineer__c = loc.SVMXC__Service_Engineer__c;
//					// Also make the engineer the Owner
//					invCount.OwnerId = loc.SVMXC__Service_Engineer__c;
//					userIds.add(loc.SVMXC__Service_Engineer__c);
//				}
//			}
//		}
//
//		if (userIds.isEmpty())
//			return;
//
//		Map<Id, SVMXC__Service_Group_Members__c> userTechMap = new Map<Id, SVMXC__Service_Group_Members__c>();
//		for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Salesforce_User__c,
//				SVMXC__Salesforce_User__r.ManagerId
//			FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c IN :userIds])
//		{
//			userTechMap.put(tech.SVMXC__Salesforce_User__c, tech);
//		}
//
//		for (SMAX_PS_InventoryCount__c invCount : invCountList)
//		{
//			if (invCount.SMAX_PS_Service_Engineer__c != null)
//			{
//				SVMXC__Service_Group_Members__c tech = userTechMap.get(invCount.SMAX_PS_Service_Engineer__c);
//				if (tech != null)
//				{
//					invCount.SMAX_PS_RequestedTechnician__c = tech.Id;
//					if (tech.SVMXC__Salesforce_User__r != null) {
//						invCount.BD_Service_Manager__c = tech.SVMXC__Salesforce_User__r.ManagerId;
//					}
//				}
//			}
//		}
//	}
//
//	public static void createInventoryCountEvents(List<SMAX_PS_InventoryCount__c> invCountList, Map<Id, SMAX_PS_InventoryCount__c> oldMap)
//	{
//		if (!SMAX_PS_Utility.isActive('Create Inventory Count Events', 'Create Inventory Platform Events when Inventory Counts are Submitted.'))
//			return;
//
//		List<SMAX_PS_Inventory_Event__e> events = new List<SMAX_PS_Inventory_Event__e>();
//		for (SMAX_PS_InventoryCount__c invCount : invCountList)
//		{
//			SMAX_PS_InventoryCount__c old = (oldMap == null) ? null : oldMap.get(invCount.Id);
//			if (invCount.SMAX_PS_Status__c == 'Confirmed'
//					&& (old == null || invCount.SMAX_PS_Status__c != old.SMAX_PS_Status__c))
//			{
//				SMAX_PS_Inventory_Event__e iEvent = new SMAX_PS_Inventory_Event__e();
//				iEvent.SMAX_PS_Action__c = 'COUNT';
//				iEvent.SMAX_PS_CountDocumentId__c = invCount.Id;
//				events.add(iEvent);
//			}
//		}
//
//		SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_CountDocumentId__c', 'SMAX_PS_Action__c');
//		//if (!events.isEmpty())
//		//{
//		//    List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
//		//    Database.SaveResult[] results = EventBus.publish(events);
//		//    for (Integer i = 0; i < results.size(); i++)
//		//    {
//		//        Database.SaveResult result = results[i];
//		//        if (!result.isSuccess())
//		//        {
//		//            SMAX_PS_Inventory_Event__e iEvent = events[i];
//		//            String msg = 'Error publishing Inventory Count Confirmed Event: ' + iEvent.SMAX_PS_CountDocumentId__c + ' -- ' + result.getErrors();
//		//            System.debug(msg);
//		//            logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, msg, 'createInventoryCountEvents', null, iEvent.SMAX_PS_CountDocumentId__c));
//		//        }
//		//    }
//		//    if (!logs.isEmpty())
//		//        insert logs;
//		//}
//	}

//	/**
//	 *  Should be called from the BEFORE INSERT / UPDATE Triggers of SMAX_PS_InventoryCountLine__c
//	 */
//	public static void lookupLineStock(List<SMAX_PS_InventoryCountLine__c> lineList, Map<Id, SMAX_PS_InventoryCountLine__c> oldMap)
//	{
//		if (!SMAX_PS_Utility.isActive('InvCountLine Lookup Stock', 'Lookup the Inventory Count Lines Product Stock'))
//			return;
//
//		List<SMAX_PS_InventoryCountLine__c> linesToUpdate = new List<SMAX_PS_InventoryCountLine__c>();
//		Set<Id> countIds = new Set<Id>();
//		Set<Id> productIds = new Set<Id>();
//		for (SMAX_PS_InventoryCountLine__c line : lineList)
//		{
//			SMAX_PS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
//			Boolean productChanged = (old != null && line.SMAX_PS_Product__c != old.SMAX_PS_Product__c);
//			if (line.SMAX_PS_Product__c != null && (line.SMAX_PS_ProductStock__c == null || productChanged))
//			{
//				linesToUpdate.add(line);
//				countIds.add(line.SMAX_PS_InventoryCount__c);
//				productIds.add(line.SMAX_PS_Product__c);
//			}
//		}
//
//		if (linesToUpdate.isEmpty())
//			return;
//
//		// Lookup Inventory Counts.. and their Locations
//		Map<Id, SMAX_PS_InventoryCount__c> countMap = new Map<Id, SMAX_PS_InventoryCount__c>(
//		[SELECT Id, Name, SMAX_PS_RequestedFrom__c FROM SMAX_PS_InventoryCount__c WHERE Id IN :countIds]);
//		Set<Id> locIds = new Set<Id>();
//		for (SMAX_PS_InventoryCount__c count : countMap.values())
//		{
//			locIds.add(count.SMAX_PS_RequestedFrom__c);
//		}
//
//		// Lookup all ProductStock with xref of Location and Product
//		Map<String, SVMXC__Product_Stock__c> stockMap = new Map<String, SVMXC__Product_Stock__c>();
//		for (SVMXC__Product_Stock__c stock : [SELECT Id, Name, SVMXC__Location__c, SVMXC__Product__c, SVMXC__Product_Cost__c
//		FROM SVMXC__Product_Stock__c WHERE SVMXC__Status__c = 'Available'
//		AND SVMXC__Location__c IN :locIds AND SVMXC__Product__c IN :productIds])
//		{
//			String key = stock.SVMXC__Location__c + '-' + stock.SVMXC__Product__c;
//			stockMap.put(key, stock);
//		}
//
//		// Assign ProductStock to each count line
//		for (SMAX_PS_InventoryCountLine__c line : linesToUpdate)
//		{
//			SMAX_PS_InventoryCount__c count = countMap.get(line.SMAX_PS_InventoryCount__c);
//			String key = count.SMAX_PS_RequestedFrom__c + '-' + line.SMAX_PS_Product__c;
//			if (stockMap.containsKey(key))
//			{
//				SVMXC__Product_Stock__c stock = stockMap.get(key);
//				line.SMAX_PS_ProductStock__c = stock.Id;
//			}
//		}
//	}
//
//	/**
//	 *  Should be called from the AFTER UPDATE Trigger of SMAX_PS_InventoryCountLine__c
//	 */
//	public static void allLinesConfirmed(List<SMAX_PS_InventoryCountLine__c> lineList, Map<Id, SMAX_PS_InventoryCountLine__c> oldMap)
//	{
//		if (!SMAX_PS_Utility.isActive('InvCountLine All Confirmed', 'When all Inventory Count Lines are Confirmed update the Inventory Count Status'))
//			return;
//
//		Set<Id> countIds = new Set<Id>();
//		Set<Id> confirmedLines = new Set<Id>();
//		for (SMAX_PS_InventoryCountLine__c line : lineList)
//		{
//			SMAX_PS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
//			if (line.SMAX_PS_InvCnt_Status__c == 'Confirmed'
//					&& old != null && old.SMAX_PS_InvCnt_Status__c != line.SMAX_PS_InvCnt_Status__c)
//			{
//				confirmedLines.add(line.Id);
//				countIds.add(line.SMAX_PS_InventoryCount__c);
//			}
//		}
//
//		if (countIds.isEmpty()) {
//			return;
//		}
//
//		List<SMAX_PS_InventoryCount__c> countsToUpdate = new List<SMAX_PS_InventoryCount__c>();
//		List<SMAX_PS_InventoryCount__c> counts = [SELECT Id, Name, SMAX_PS_Status__c,
//		(SELECT Id, Name, SMAX_PS_InvCnt_Status__c FROM Inventory_Count_Lines__r
//		WHERE Id NOT IN :confirmedLines AND SMAX_PS_InvCnt_Status__c != 'Confirmed')
//		FROM SMAX_PS_InventoryCount__c WHERE Id IN :countIds];
//		for (SMAX_PS_InventoryCount__c count : counts)
//		{
//			if (count.SMAX_PS_Status__c == 'Submitted')
//			{
//				if (count.Inventory_Count_Lines__r == null || count.Inventory_Count_Lines__r.isEmpty())
//				{
//					count.SMAX_PS_Status__c = 'Confirmed';
//					countsToUpdate.add(count);
//				}
//				else
//				{
//					System.debug('Inv Count NOT ready to move to Confirmed: ' + count);
//				}
//			}
//		}
//
//		if (!countsToUpdate.isEmpty()) {
//			update counts;
//		}
//	}

	public static void stockedSerialReplacements(List<SVMXC__Product_Serial__c> serialList)
	{
		if (!SMAX_PS_Utility.isActive('AdvReplacement Consumption', 'Consume the Serialized Stock on an Advanced Replacement WO by adding a Parts Work Detail line')) {
			return;
		}

		Set<Id> serialIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		Set<String> serialNums = new Set<String>();
		for (SVMXC__Product_Serial__c serial : serialList)
		{
			// NOTE: Can't verify 'Available' yet... 1st query will handle that
			if (String.isNotBlank(serial.SMAX_PS_SerialNum__c) && serial.SVMXC__Product__c != null
					&& serial.SMAX_PS_Quantity__c >= 1)
			{
				serialIds.add(serial.Id);
				productIds.add(serial.SVMXC__Product__c);
				serialNums.add(serial.SMAX_PS_SerialNum__c);
			}
		}

		if (serialIds.isEmpty()) {
			return;
		}

		List<SVMXC__Product_Serial__c> stockSerials = [SELECT Id, Name, SMAX_PS_SerialNum__c,
				SVMXC__Product__c, SVMXC__Product__r.Partnum__c,
				SVMXC__Product_Stock__c,
				SVMXC__Product_Stock__r.SVMXC__Status__c,
				SVMXC__Product_Stock__r.SVMXC__Location__c
		FROM SVMXC__Product_Serial__c
		WHERE Id IN :serialIds
		AND SVMXC__Product_Stock__r.SVMXC__Status__c = 'Available'];

		if (stockSerials.isEmpty()) {
			return;
		}

		// Lookup Open (Delivery) Parts Orders + Lines w same Product & Serial (at the same Location)
		List<SVMXC__RMA_Shipment_Line__c> deliveryLines = [SELECT Id, Name, SMAX_PS_SerialNum__c, SVMXC__Product__c,
				SVMXC__RMA_Shipment_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Name,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Group_Member__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Master_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Master_Order__r.SVMXC__Destination_Location__c
		FROM SVMXC__RMA_Shipment_Line__c
		WHERE SVMXC__Product__c IN :productIds AND SMAX_PS_SerialNum__c IN :serialNums
		AND SVMXC__RMA_Shipment_Order__r.RecordType.DeveloperName = 'Delivery'
		AND SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMX_PS_Replacement_Required__c = TRUE];

		List<AdvancedReplacementConsumption> matches = new List<AdvancedReplacementConsumption>();
		for (SVMXC__Product_Serial__c serial : stockSerials) {
			for (SVMXC__RMA_Shipment_Line__c deliveryLine : deliveryLines) {
				SVMXC__Service_Order__c wo = (SVMXC__Service_Order__c) deliveryLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r;
				// ITSVMX-201 Match the Delivery "Destination Location" to the Stock location instead of the Tech
				//Id techLocation = (wo != null && wo.SVMXC__Group_Member__r != null) ? wo.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c : null;
				Id deliveryLocation = deliveryLine?.SVMXC__RMA_Shipment_Order__r?.SVMXC__Destination_Location__c;
				if (serial.SMAX_PS_SerialNum__c == deliveryLine.SMAX_PS_SerialNum__c
						&& serial.SVMXC__Product__c == deliveryLine.SVMXC__Product__c
						&& deliveryLocation == serial.SVMXC__Product_Stock__r.SVMXC__Location__c)
				{
					AdvancedReplacementConsumption match = new AdvancedReplacementConsumption(deliveryLine, serial, wo);
					matches.add(match);
				}
			}
		}

		// Call reusable method with Stock Serial + Delivery Line + WO
		if (!matches.isEmpty()) {
			consumeReplacementSerial(matches);
		}
	}

	public static void deliveryLineReplacements(List<SVMXC__RMA_Shipment_Line__c> lineList)
	{
		if (!SMAX_PS_Utility.isActive('AdvReplacement Consumption', 'Consume the Serialized Stock on an Advanced Replacement WO by adding a Parts Work Detail line')) {
			return;
		}

		Set<Id> productIds = new Set<Id>();
		Set<String> serialNums = new Set<String>();
		Set<Id> lineIds = new Set<Id>();
		for (SVMXC__RMA_Shipment_Line__c line : lineList)
		{
			// NOTE: Can't verify this is a "Delivery" line yet.. 1st lookup will handle that
			if (line.SVMXC__Product__c != null && String.isNotBlank(line.SMAX_PS_SerialNum__c))
			{
				lineIds.add(line.Id);
				productIds.add(line.SVMXC__Product__c);
				serialNums.add(line.SMAX_PS_SerialNum__c);
			}
		}

		if (lineIds.isEmpty()) {
			return;
		}

		// Lookup the Parts Order (& RT) + Location + WO (only if "Delivery" & "Replacement Required")
		List<SVMXC__RMA_Shipment_Line__c> deliveryLines = [SELECT Id, Name, SMAX_PS_SerialNum__c, SVMXC__Product__c,
				SVMXC__RMA_Shipment_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Name,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Group_Member__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Master_Order__c,
				SVMXC__RMA_Shipment_Order__r.SVMXC__Master_Order__r.SVMXC__Destination_Location__c
		FROM SVMXC__RMA_Shipment_Line__c
		WHERE Id IN :lineIds
		AND SVMXC__RMA_Shipment_Order__r.RecordType.DeveloperName = 'Delivery'
		AND SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMX_PS_Replacement_Required__c = TRUE];

		if (deliveryLines.isEmpty()) {
			return;
		}

		// Lookup Product Stock + Serials w same Product & Serial (at the same Location)
		List<SVMXC__Product_Serial__c> stockSerials = [SELECT Id, Name, SMAX_PS_SerialNum__c,
				SVMXC__Product__c, SVMXC__Product__r.Partnum__c,
				SVMXC__Product_Stock__c,
				SVMXC__Product_Stock__r.SVMXC__Status__c,
				SVMXC__Product_Stock__r.SVMXC__Location__c
		FROM SVMXC__Product_Serial__c
		WHERE SVMXC__Product__c IN :productIds AND SMAX_PS_SerialNum__c IN :serialNums
		AND SVMXC__Product_Stock__r.SVMXC__Status__c = 'Available'
		AND SMAX_PS_Quantity__c >= 1];
		List<AdvancedReplacementConsumption> matches = new List<AdvancedReplacementConsumption>();
		for (SVMXC__Product_Serial__c serial : stockSerials) {
			for (SVMXC__RMA_Shipment_Line__c deliveryLine : deliveryLines) {
				SVMXC__Service_Order__c wo = (SVMXC__Service_Order__c) deliveryLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r;
				// ITSVMX-201 Match the Delivery "Destination Location" to the Stock location instead of the Tech
				//Id techLocation = (wo != null && wo.SVMXC__Group_Member__r != null) ? wo.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c : null;
				Id deliveryLocation = deliveryLine?.SVMXC__RMA_Shipment_Order__r?.SVMXC__Destination_Location__c;
				if (serial.SMAX_PS_SerialNum__c == deliveryLine.SMAX_PS_SerialNum__c
						&& serial.SVMXC__Product__c == deliveryLine.SVMXC__Product__c
						&& deliveryLocation == serial.SVMXC__Product_Stock__r.SVMXC__Location__c)
				{
					AdvancedReplacementConsumption match = new AdvancedReplacementConsumption(deliveryLine, serial, wo);
					matches.add(match);
				}
			}
		}

		// Call reusable method with Stock Serial + Delivery Line + WO
		if (!matches.isEmpty()) {
			consumeReplacementSerial(matches);
		}
	}

	public class AdvancedReplacementConsumption
	{
		public SVMXC__RMA_Shipment_Line__c deliveryLine { get; set; }
		public SVMXC__Product_Serial__c serializedStock { get; set; }
		public SVMXC__Service_Order__c workOrder { get; set; }

		public AdvancedReplacementConsumption(SVMXC__RMA_Shipment_Line__c line, SVMXC__Product_Serial__c stock, SVMXC__Service_Order__c wo)
		{
			this.deliveryLine = line;
			this.serializedStock = stock;
			this.workOrder = wo;
		}
	}

	private static void consumeReplacementSerial(List<AdvancedReplacementConsumption> consumptions)
	{
		Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
		List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
		for (AdvancedReplacementConsumption arc : consumptions)
		{
			SVMXC__Service_Order_Line__c detail = new SVMXC__Service_Order_Line__c(
					SVMXC__Service_Order__c = arc.workOrder.Id,
					RecordTypeId = usageRecTypeId,
					SVMXC__Line_Type__c = 'Parts',
					SVMXC__Line_Status__c = 'Open',
					SVMXC__Consumed_From_Location__c = arc.serializedStock.SVMXC__Product_Stock__r.SVMXC__Location__c,
					SVMX_PS_VS_Consumed_Product_Stock__c = arc.serializedStock.SVMXC__Product_Stock__c,
					SVMX_PS_VS_Consumed_Stocked_Serial__c = arc.serializedStock.Id,
					SVMXC__Product__c = arc.serializedStock.SVMXC__Product__c,
					SMAX_PS_Part_Number__c = arc.serializedStock.SVMXC__Product__r.Partnum__c,
					BD_Advanced_Replacement_Delivery__c = arc.deliveryLine.Id,
					SVMXC__Actual_Quantity2__c = 1
			);

			lines.add(detail);
		}
		insert lines;

		// INTEGRATION: Submit the Line(s) and send WO Events... (copied from SMAX_PS_WorkOrderDebriefManager)
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		String txnId = String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
		for (SVMXC__Service_Order_Line__c wd : lines) {
			wd.SVMXC__Line_Status__c = 'Submitted';
			wd.SMAX_PS_SubmitTxnId__c = txnId;

			SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
			iEvent.SMAX_PS_Action__c = 'SUBMIT';
			iEvent.SMAX_PS_WorkOrderId__c = wd.SVMXC__Service_Order__c;
			iEvent.SMAX_PS_SubmitTxnId__c = txnId;
			events.add(iEvent);
		}
		SMAX_PS_WorkOrderManager.sendWorkOrderEvents(events);
		update lines;

		// TODO: Post to Chatter on the WO (ask Chad about the details here.. maybe we should use PB for this?).. saying something like "Auto Consumed Delivered Stock Serial for Advanced Replacement ... WO Number, Serial Number, WD Line Number"

	}

	public static void autoCreateRMA(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Work Order Auto Create RMA', 'When WO is changed to "Depot" OR is "Depot" and gets a SAP Id... auto-create RMA.'))
			return;

		// 11/13/20 tony - Auto Create Parts Request - initialize
		Map<Id, SVMXC__Service_Order__c> replacementWorkOrders = new Map<Id, SVMXC__Service_Order__c>();
		RecordType prRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
		RecordType prLineRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'Shipment');

		Map<Id, SVMXC__Service_Order__c> depotWorkOrders = new Map<Id, SVMXC__Service_Order__c>();
		RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');
		RecordType rmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'RMA');
		RecordType rmaLineRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'RMA');

		for (SVMXC__Service_Order__c wo : woList)
		{
			// ITSVMX-253 Only run when NOT on credit-hold
			// ITSVMX-500 Only run when a "Depot Plant" is already assigned to the WO
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.RecordTypeId == depotRT.Id && wo.SVMX_PS_External_ID__c != null && wo.SMAX_PS_CreditHold__c == false
					&& wo.SMAX_PS_Depot_Plant__c != null
					&& (old == null || old.RecordTypeId != wo.RecordTypeId
					|| wo.SVMX_PS_External_ID__c != old.SVMX_PS_External_ID__c
					|| wo.SMAX_PS_CreditHold__c != old.SMAX_PS_CreditHold__c
					|| wo.SMAX_PS_Depot_Plant__c != old.SMAX_PS_Depot_Plant__c))
			{
				depotWorkOrders.put(wo.Id, wo);

				// 11/13/20 tony - Auto Create Parts Request
				if (wo.SVMX_PS_Replacement_Required__c == true) {
					System.debug('Adding WO to replacement list: ' + wo);
					replacementWorkOrders.put(wo.Id, wo);
				}
			}
		}

		if (depotWorkOrders.isEmpty())
		{
			return;
		}

		// Check for pre-existing RMA (if found, stop)
		List<SVMXC__RMA_Shipment_Order__c> existingRMAs = [SELECT Id, Name, SVMXC__Service_Order__c
		FROM SVMXC__RMA_Shipment_Order__c
		WHERE SVMXC__Service_Order__c IN :depotWorkOrders.keySet() AND RecordTypeId = :rmaRT.Id];

		// ITSFDC-1047: Lookup new WO "From" Fields
		Map<Id, SVMXC__Service_Order__c> woDetailMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name,
				SVMXC__Site__c, SVMXC__Site__r.SVMXC__Street__c, SVMXC__Site__r.SVMXC__City__c,
				SVMXC__Site__r.SVMXC__State__c, SVMXC__Site__r.SVMXC__Country__c, SVMXC__Site__r.SVMXC__Zip__c,
				SVMXC__Site__r.SMAX_PS_MaintenancePlant__c,
				SVMXC__Group_Member__c, SVMXC__Group_Member__r.SVMXC__Street__c, SVMXC__Group_Member__r.SVMXC__City__c,
				SVMXC__Group_Member__r.SVMXC__State__c, SVMXC__Group_Member__r.SVMXC__Country__c, SVMXC__Group_Member__r.SVMXC__Zip__c,
				SVMXC__Group_Member__r.SVMXC__Role__c, SVMXC__Group_Member__r.Name, SVMXC__Group_Member__r.SMAX_PS_Work_Center__c,
				BD_FromStreet1__c, BD_FromStreet2__c, BD_FromStreet3__c, BD_FromStreet4__c, BD_FromStreet5__c,
				BD_Global_From_Country__c, BD_Global_From_State__c, BD_Source_City__c, BD_Source_Zip__c,
				BD_SourceName1__c, BD_SourceName2__c, BD_SourceName3__c,
				SVMXC__Contact__c, SMAX_PS_ContactName__c, SVMX_PS_Contact_Phone__c, SMAX_PS_SalesOrg__c,
				SVMXC__Product__r.Partnum__c
		FROM SVMXC__Service_Order__c WHERE Id IN :depotWorkOrders.keySet()]);

		// ITSVMX-200 Lookup the "Advanced Replacement Locations" in the form XXXXAREP
		Map<String, SVMXC__Site__c> advRepLocations = new Map<String, SVMXC__Site__c>();
		if (!replacementWorkOrders.isEmpty()) {
			Set<String> advRepKeys = new Set<String>();
			for (SVMXC__Service_Order__c woDetail : woDetailMap.values()) {
				String advRepKey = woDetail.SVMXC__Site__r.SMAX_PS_MaintenancePlant__c + 'AREP';
				advRepKeys.add(advRepKey);
			}

			for (SVMXC__Site__c loc : [SELECT Id, Name, SVMX_PS_External_ID__c FROM SVMXC__Site__c
			WHERE SVMX_PS_External_ID__c IN :advRepKeys]) {
				advRepLocations.put(loc.SVMX_PS_External_ID__c, loc);
			}
		}

		Set<Id> partIdsForRefurb = new Set<Id>();
		List<SVMXC__RMA_Shipment_Order__c> rmaList = new List<SVMXC__RMA_Shipment_Order__c>();
		for (SVMXC__Service_Order__c wo : depotWorkOrders.values())
		{
			SVMXC__RMA_Shipment_Order__c woRMA = null;
			for (SVMXC__RMA_Shipment_Order__c rma : existingRMAs)
			{
				if (rma.SVMXC__Service_Order__c == wo.Id)
				{
					woRMA = rma;
					break;
				}
			}

			if (woRMA == null)
			{
				SVMXC__Service_Order__c woDetail = woDetailMap.get(wo.Id);

				// Didn't find one, so auto-create one...
				woRMA = new SVMXC__RMA_Shipment_Order__c();
				woRMA.RecordTypeId = rmaRT.Id;
				woRMA.SVMXC__Service_Order__c = wo.Id;
				woRMA.SVMXC__Company__c = wo.SVMXC__Company__c;
				woRMA.SMAX_PS_ShipTo__c = wo.SMAX_PS_ShipTo__c;
				woRMA.SVMXC__Order_Status__c = 'Open';
				woRMA.SVMXC__Order_Type__c = 'Return';
				woRMA.SVMXC__RMA_Type__c = 'Instrument';

				// ITSVMX-555 Use TODAY for traditional Depot, let Adv Replacement use Scheduled Date
				Boolean isAdvReplacement = (wo.SVMX_PS_Replacement_Required__c == true);
				if (isAdvReplacement) {
					woRMA.SMAX_PS_Requested_Delivery_Date__c = wo.SVMXC__Scheduled_Date__c;
				} else {
					woRMA.SMAX_PS_Requested_Delivery_Date__c = Date.today();
				}

				// Map the Source (From) fields from the Location...
				woRMA.SVMXC__Source_Location__c = wo.SVMXC__Site__c;
				// ITSFDC-1047 Copy the Customer Address (From XXX) from WO to RMA
				woRMA.SMAX_PS_FromStreet1__c = woDetail.BD_FromStreet1__c;
				woRMA.SMAX_PS_FromStreet2__c = woDetail.BD_FromStreet2__c;
				woRMA.SMAX_PS_FromStreet3__c = woDetail.BD_FromStreet3__c;
				woRMA.SMAX_PS_FromStreet4__c = woDetail.BD_FromStreet4__c;
				woRMA.SMAX_PS_FromStreet5__c = woDetail.BD_FromStreet5__c;
				woRMA.SMAX_PS_Global_From_Country__c = woDetail.BD_Global_From_Country__c;
				woRMA.SMAX_PS_Global_From_State__c = woDetail.BD_Global_From_State__c;
				woRMA.SMAX_PS_SourceName1__c = woDetail.BD_SourceName1__c;
				woRMA.SMAX_PS_SourceName2__c = woDetail.BD_SourceName2__c;
				woRMA.SMAX_PS_SourceName3__c = woDetail.BD_SourceName3__c;
				woRMA.SVMXC__Source_City__c = woDetail.BD_Source_City__c;
				woRMA.SVMXC__Source_Zip__c = woDetail.BD_Source_Zip__c;

				// ITSFDC-863: Also copy the Contact fields...
				woRMA.SVMXC__Contact__c = woDetail.SVMXC__Contact__c;
				woRMA.SMAX_PS_Contact_Name__c = woDetail.SMAX_PS_ContactName__c;
				woRMA.SMAX_PS_Contact_Phone__c = woDetail.SVMX_PS_Contact_Phone__c;
				woRMA.SMAX_PS_SalesOrg__c = woDetail.SMAX_PS_SalesOrg__c;

				// Map the Destination (To) fields from the "Depot Queue" Technician
				SVMXC__Service_Group_Members__c tech = (woDetail != null) ? woDetail.SVMXC__Group_Member__r : null;
				if (tech != null && tech.SVMXC__Role__c == 'Depot Queue')
				{
					woRMA.SVMXC__Warehouse__c = tech.Name + ' [' + tech.SMAX_PS_Work_Center__c + ']';
					woRMA.SVMXC__Destination_Street__c = tech.SVMXC__Street__c;
					woRMA.SVMXC__Destination_City__c = tech.SVMXC__City__c;
					woRMA.SVMXC__Destination_State__c = tech.SVMXC__State__c;
					woRMA.SVMXC__Destination_Zip__c = tech.SVMXC__Zip__c;
					woRMA.SVMXC__Destination_Country__c = tech.SVMXC__Country__c;
				}

				rmaList.add(woRMA);

				// ITSVMX-200 11/13/20 tony - Auto Create Parts Request - create new Parts Request PO
				if (replacementWorkOrders.get(wo.Id) != null) {
					SVMXC__RMA_Shipment_Order__c pr = new SVMXC__RMA_Shipment_Order__c();

					// 11/13/20 tony - Auto Create Parts Request - create Parts Request PO
					pr.RecordTypeId = prRT.Id;
					pr.SVMXC__Service_Order__c = wo.Id;
					pr.SVMXC__Company__c = wo.SVMXC__Company__c;
					pr.SMAX_PS_ShipTo__c = wo.SMAX_PS_ShipTo__c;
					pr.SVMXC__Order_Status__c = 'Open';
					pr.SVMXC__Order_Type__c = 'Return';
					pr.SVMXC__RMA_Type__c = 'Instrument';
					pr.SMAX_PS_Requested_Delivery_Date__c = wo.SVMXC__Scheduled_Date__c;

					// ITSVMX-200 Map the "Destination Location" to the XXXXAREP Location
					String advRepKey = woDetail.SVMXC__Site__r.SMAX_PS_MaintenancePlant__c + 'AREP';
					if (advRepLocations.containsKey(advRepKey)) {
						SVMXC__Site__c advRepLoc = advRepLocations.get(advRepKey);
						pr.SVMXC__Destination_Location__c = advRepLoc.Id;
					}

					pr.SVMXC__Source_Location__c = wo.SVMXC__Site__c;
					pr.SMAX_PS_ToStreet1__c = woDetail.BD_FromStreet1__c;
					pr.SMAX_PS_ToStreet2__c = woDetail.BD_FromStreet2__c;
					pr.SMAX_PS_ToStreet3__c = woDetail.BD_FromStreet3__c;
					pr.SMAX_PS_ToStreet4__c = woDetail.BD_FromStreet4__c;
					pr.SMAX_PS_ToStreet5__c = woDetail.BD_FromStreet5__c;
					pr.SMAX_PS_Global_To_Country__c = woDetail.BD_Global_From_Country__c;
					pr.SMAX_PS_Global_To_State__c = woDetail.BD_Global_From_State__c;

					if (wo.SVMX_PS_Replacement_Type_Issued__c == 'Refurbished') {
						partIdsForRefurb.add(wo.SVMXC__Product__c);
					}

					pr.SMAX_PS_SourceName1__c = woDetail.BD_SourceName1__c;
					pr.SMAX_PS_SourceName2__c = woDetail.BD_SourceName2__c;
					pr.SMAX_PS_SourceName3__c = woDetail.BD_SourceName3__c;

					pr.SVMXC__Destination_Street__c = woDetail.BD_FromStreet1__c;
					pr.SVMXC__Destination_City__c = woDetail.BD_Source_City__c;
					pr.SVMXC__Destination_State__c = woDetail.BD_Global_From_State__c;
					pr.SVMXC__Destination_Zip__c = woDetail.BD_Source_Zip__c;
					pr.SVMXC__Destination_Country__c = woDetail.BD_Global_From_Country__c;

					pr.SVMXC__Contact__c = woDetail.SVMXC__Contact__c;
					pr.SMAX_PS_Contact_Name__c = woDetail.SMAX_PS_ContactName__c;
					pr.SMAX_PS_Contact_Phone__c = woDetail.SVMX_PS_Contact_Phone__c;
					pr.SMAX_PS_SalesOrg__c = woDetail.SMAX_PS_SalesOrg__c;

					// ITSVMX-200 11/13/20 tony - Auto Create Parts Request - Map the Destination (To) fields from the "Depot Queue" Technician
//					SVMXC__Service_Group_Members__c tech = (woDetail != null) ? woDetail.SVMXC__Group_Member__r : null;
					if (tech != null && tech.SVMXC__Role__c == 'Depot Queue')
					{
						// 11/13/20 tony - Auto Create Parts Request - Map From Fields
						pr.SVMXC__Warehouse__c = tech.Name + ' [' + tech.SMAX_PS_Work_Center__c + ']';
						pr.SMAX_PS_FromStreet1__c = tech.SVMXC__Street__c;
						pr.SVMXC__Source_City__c = tech.SVMXC__City__c;
						pr.SVMXC__Source_State__c = tech.SVMXC__State__c;
						pr.SVMXC__Source_Zip__c = tech.SVMXC__Zip__c;
						pr.SVMXC__Source_Country__c = tech.SVMXC__Country__c;
					}

					rmaList.add(pr);
				}
			}
		}

		if (rmaList.isEmpty())
		{
			return;
		}

		insert rmaList;

		// ITSVMX-200 Adv Replacement: Refurbished Parts. Lookup the corresponding "Refurbished" Parts using PARTNUM+"R"
		Map<Id, Product2> refurbPartMap = new Map<Id, Product2>();
		if (!partIdsForRefurb.isEmpty()) {
			Set<String> refurbPartNums = new Set<String>();
			List<Product2> origParts = [SELECT Id, Name, Partnum__c FROM Product2 WHERE Id IN :partIdsForRefurb];
			for (Product2 origPart : origParts) {
				refurbPartNums.add(origPart.Partnum__c + 'R');
			}
			List<Product2> refurbParts = [SELECT Id, Name, Partnum__c FROM Product2 WHERE Partnum__c IN :refurbPartNums];
			for (Product2 origPart : origParts) {
				String refurbPartNum = origPart.Partnum__c + 'R';
				for (Product2 refurbPart : refurbParts) {
					if (refurbPartNum == refurbPart.Partnum__c) {
						refurbPartMap.put(origPart.Id, refurbPart);
						break;
					}
				}
			}
		}

		// Map all the RMA's by the WO Id, so the Parts Requests can be linked to them
		Map<Id, SVMXC__RMA_Shipment_Order__c> woRmaMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
		for (SVMXC__RMA_Shipment_Order__c rma : rmaList)
		{
			if (rma.RecordTypeId == rmaRT.Id) {
				woRmaMap.put(rma.SVMXC__Service_Order__c, rma);
			}
		}

		List<SVMXC__RMA_Shipment_Line__c> rmaLines = new List<SVMXC__RMA_Shipment_Line__c>();
		for (SVMXC__RMA_Shipment_Order__c partsOrder : rmaList)
		{
			// Create lines & then update to "Submitted to ERP"
			SVMXC__Service_Order__c wo = depotWorkOrders.get(partsOrder.SVMXC__Service_Order__c);
			SVMXC__Service_Order__c woDetail = woDetailMap.get(wo.Id);

			SVMXC__RMA_Shipment_Line__c partsLine = new SVMXC__RMA_Shipment_Line__c();
			partsLine.SVMXC__RMA_Shipment_Order__c = partsOrder.Id;
			partsLine.SVMXC__Expected_Quantity2__c = 1;
			partsLine.SVMXC__Serial_Number__c = wo.SVMXC__Component__c;
			partsLine.SVMXC__Product__c = wo.SVMXC__Product__c;
			// Added to map the raw Part Number in BOOMI
			partsLine.Partnum__c = woDetail.SVMXC__Product__r.Partnum__c;

			// ITSVMX-555 We should not fill in the "Return Part Number" for traditional Depot
			Boolean isAdvReplacement = (wo.SVMX_PS_Replacement_Required__c == true);
			if (isAdvReplacement) {
				partsLine.BD_Return_Part_Number__c = wo.BD_Equipment_Part_Return_Number__c;
			}

			if (partsOrder.RecordTypeId == rmaRT.Id) {
				partsLine.RecordTypeId = rmaLineRT.Id;
				// Only submit the RMA, not the Parts Request..
				partsOrder.SVMXC__Order_Status__c = 'Submitted to ERP';
			} else {
				partsLine.RecordTypeId = prLineRT.Id;
				// ITSVMX-200 The Parts Request cannot send until the RMA completes..
				partsOrder.SVMXC__Order_Status__c = 'Pending RMA';
				// Link the Parts Request to the RMA..
				SVMXC__RMA_Shipment_Order__c rma = woRmaMap.get(partsOrder.SVMXC__Service_Order__c);
				if (rma != null) {
					partsOrder.SVMXC__Shipment_Reference__c = rma.Id;
				}
				if (wo.SVMX_PS_Replacement_Type_Issued__c == 'Refurbished') {
					// Lookup the Refurb part instead
					Product2 refurbPart = refurbPartMap.get(wo.SVMXC__Product__c);
					if (refurbPart != null) {
						partsLine.SVMXC__Product__c = refurbPart.Id;
					}
				}
			}
			rmaLines.add(partsLine);
		}

		insert rmaLines;
		update rmaList;
	}

	// 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
	// NOTE: Should be called on before insert and before update
	public static void useRefurbishedParts(List<SVMXC__RMA_Shipment_Line__c> partsOrderLines, Map<Id, SVMXC__RMA_Shipment_Line__c> oldMap) {
		if (!SMAX_PS_Utility.isActive('Use Refurbished Part on Order Line', 'If Refurbished Parts are allowed then use them on this Parts Order Line.'))
			return;

		System.debug('Entering SMAX_PS_InventoryManager.useRefurbishedParts');

		// Get Sets of Ids for Parts Orders, Work Orders, and Products
		Set<Id> partsOrderIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		for (SVMXC__RMA_Shipment_Line__c partsOrderLine :partsOrderLines) {

			if (partsOrderLine.SVMXC__RMA_Shipment_Order__c != null) partsOrderIds.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
			if (partsOrderLine.SVMXC__Product__c != null) productIds.add(partsOrderLine.SVMXC__Product__c);
		}

		System.debug('partsOrderIds: ' + partsOrderIds.size() + ' ' + partsOrderIds);
		System.debug('productIds: ' + productIds.size() + ' ' + productIds);

		// 7/14/2022 We are getting the "Too Many SOQL Queries" error in our unit tests. Exit early if there are no partsOrderIds or productIds
		if (partsOrderIds.isEmpty() && productIds.isEmpty()) return;

		// Get the List of Parts Orders with Use Refurbished Parts value
		List<SVMXC__RMA_Shipment_Order__c> partsOrders = [
				SELECT Id, BD_Use_Refurbished_Parts__c, SVMXC__Service_Order__c
				FROM SVMXC__RMA_Shipment_Order__c
				WHERE Id IN :partsOrderIds
		];

		// Create a Map of Parts Order Ids to Use Refurbished Parts values AND Get a Set of Ids for Work Orders
		Set<Id> workOrderIds = new Set<Id>();
		Map<Id, Boolean> partsOrderIdToUseRefurbPartValue = new Map<Id, Boolean>();
		Map<Id, Id> partsOrderIdToWorkOrderId = new Map<Id, Id>();
		for (SVMXC__RMA_Shipment_Order__c partsOrder :partsOrders) {

			partsOrderIdToUseRefurbPartValue.put(partsOrder.Id, partsOrder.BD_Use_Refurbished_Parts__c);

			System.debug('partsOrder.SVMXC__Service_Order__c: ' + partsOrder.SVMXC__Service_Order__c);
			if (partsOrder.SVMXC__Service_Order__c != null) workOrderIds.add(partsOrder.SVMXC__Service_Order__c);
			partsOrderIdToWorkOrderId.put(partsOrder.Id, partsOrder.SVMXC__Service_Order__c);
		}
		System.debug('workOrderIds: ' + workOrderIds.size() + ' ' + workOrderIds);
		System.debug('partsOrderIdToWorkOrderId: ' + partsOrderIdToWorkOrderId.size() + ' ' + partsOrderIdToWorkOrderId);

		// Get the List of Work Orders with Use Refurbished Parts values and Plant Codes
		List<SVMXC__Service_Order__c> workOrders = [
				SELECT Id, BD_Use_Refurbished_Parts__c, SVMXC__Component__r.SMAX_PS_MaintenancePlant__c
				FROM SVMXC__Service_Order__c
				WHERE Id IN:workOrderIds
		];

		// Create Maps of Work Order Ids to Use Refurbished Parts values and Work Order Ids to Plant Codes
		Map<Id, Boolean> workOrderIdToUseRefurbPartValue = new Map<Id, Boolean>();
		Map<Id, String> workOrderIdToPlantCode = new Map<Id, String>();
		for (SVMXC__Service_Order__c workOrder :workOrders) {

			workOrderIdToUseRefurbPartValue.put(workOrder.Id, workOrder.BD_Use_Refurbished_Parts__c);
			workOrderIdToPlantCode.put(workOrder.Id, workOrder.SVMXC__Component__r.SMAX_PS_MaintenancePlant__c);
		}
		System.debug('workOrderIdToUseRefurbPartValue: ' + workOrderIdToUseRefurbPartValue.size() + ' ' + workOrderIdToUseRefurbPartValue);
		System.debug('workOrderIdToPlantCode: ' + workOrderIdToPlantCode.size() + ' ' + workOrderIdToPlantCode);

		// Get the list of Parts Order Lines that have a Parts Order with BD_Use_Refurbished_Parts__c = TRUE and Work Order with BD_Use_Refurbished_Parts__c = TRUE
		List<SVMXC__RMA_Shipment_Line__c> partsOrderLinesToUpdate = new List<SVMXC__RMA_Shipment_Line__c>();
		for (SVMXC__RMA_Shipment_Line__c partsOrderLine :partsOrderLines) {

			System.debug('partsOrderLine.SVMXC__RMA_Shipment_Order__c: ' + partsOrderLine.SVMXC__RMA_Shipment_Order__c);
			Id workOrderId = partsOrderIdToWorkOrderId.get(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
			System.debug('Parts Order workOrderId: ' + workOrderId);
			if (partsOrderIdToUseRefurbPartValue.get(partsOrderLine.SVMXC__RMA_Shipment_Order__c) == true
					&& workOrderIdToUseRefurbPartValue.get(workOrderId) == true) {

				System.debug('Adding Parts Order Line to partsOrderLinesToUpdate: ' + partsOrderLine);
				partsOrderLinesToUpdate.add(partsOrderLine);
			}
		}

		if (partsOrderLinesToUpdate.isEmpty()) {
			System.debug('There are no Parts Order Lines that qualify to use Refurbished Parts');
			return;
		}

		// Get the list of Product Plants that have the same Product and Plant as our Parts Order Line/Work Order
		List<SMAX_PS_ProductPlant__c> productPlants = [
				SELECT Id, SMAX_PS_Product__c, SMAX_PS_Plant__c, BD_Refurbished_Part__c, BD_Refurbished_Part_Number__c
				FROM SMAX_PS_ProductPlant__c
				WHERE SMAX_PS_Product__c IN :productIds
				AND SMAX_PS_Plant__c IN :workOrderIdToPlantCode.values()
		];
		System.debug('productPlants: ' + productPlants.size() + ' ' + productPlants);

		// Create Maps using a combination key of product-plant to BD_Refurbished_Part__c and BD_Refurbished_Part_Number__c
		Map<String, Id> productPlantToRefurbPart = new Map<String, Id>();
		Map<String, String> productPlantToRefurbPartNumber = new Map<String, String>();
		for (SMAX_PS_ProductPlant__c productPlant :productPlants) {

			productPlantToRefurbPart.put(productPlant.SMAX_PS_Product__c + '-' + productPlant.SMAX_PS_Plant__c, productPlant.BD_Refurbished_Part__c);
			productPlantToRefurbPartNumber.put(productPlant.SMAX_PS_Product__c + '-' + productPlant.SMAX_PS_Plant__c, productPlant.BD_Refurbished_Part_Number__c);
		}
		System.debug('productPlantToRefurbPart: ' + productPlantToRefurbPart.size() + ' ' + productPlantToRefurbPart);
		System.debug('productPlantToRefurbPartNumber: ' + productPlantToRefurbPartNumber.size() + ' ' + productPlantToRefurbPartNumber);

		// Update the Parts Order Line SVMXC__Product__c and Partnum__c
		for (SVMXC__RMA_Shipment_Line__c partsOrderLine :partsOrderLinesToUpdate) {

			Id workOrderId = partsOrderIdToWorkOrderId.get(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
			String plantCode = workOrderIdToPlantCode.get(workOrderId);
			Id productId = partsOrderLine.SVMXC__Product__c;

			//06/10/2022 Tony Fix SVMXC__Product__c and Partnum__c being set to null when no refurbished part was found
			//partsOrderLine.SVMXC__Product__c = productPlantToRefurbPart.get(productId + '-' + plantCode);
			//partsOrderLine.Partnum__c = productPlantToRefurbPartNumber.get(productId + '-' + plantCode);
			Id refurbPart = productPlantToRefurbPart.get(productId + '-' + plantCode);
			String refurbPartNum = productPlantToRefurbPartNumber.get(productId + '-' + plantCode);
			if (refurbPart != null && refurbPartNum != null) {

				partsOrderLine.SVMXC__Product__c = refurbPart;
				partsOrderLine.Partnum__c = refurbPartNum;
			}
		}
		System.debug('partsOrderLinesToUpdated: ' + partsOrderLinesToUpdate.size() + ' ' + partsOrderLinesToUpdate);

		System.debug('Exiting SMAX_PS_InventoryManager.useRefurbishedParts');
	}

}
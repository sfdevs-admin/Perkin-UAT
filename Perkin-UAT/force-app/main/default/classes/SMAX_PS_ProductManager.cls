/**
 *  Apex Class for Product [Product2] Business Logic.
 *  2017-08-03      Veerendra Moodbidri       Initial creation, for Product Outbound Integration.
 *
 *  deleteProductChildRecords method
 *  --------------------------------
 *  Delete the records in the child objects when the parent Product record is deleted.
 *
 *  updateDeletedFlag method
 *  ------------------------
 *  2017-09-22      
 *  1. Delete Product Revision records if "Completed Transaction number" is changed in the Product and it does not match with
 *       the Last Transaction NUmber in the Product Revision.
 *  2. Delete Product Classification records if "Completed Transaction number" is changed in the Product and it does not match with
 *       the Last Transaction NUmber in the Product Classification.
 *  3. Update "SAP Deleted" to true in all the Product Sales related to the above Products if same conditions are met.
 *  4. Update "SAP Deleted" to true in all the Product Plants related to the above Products if same conditions are met.
 *
 *  Updates
 *  2022-04-20	Tony	ITSVMX-562 Modify the replenishment parts ordering process
 */

public with sharing class SMAX_PS_ProductManager {

	private SMAX_PS_ProductManager() {
	}

	public static void updateDeletedFlag(List<Product2> newProductList, Map<Id, Product2> oldProductMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Deleted Flag', 'Update delete flag in Product Sales and Product Plant, Delete Product Revision and Product Classification.'))
		{	return;	}

		List<SMAX_PS_ProductRevision__c> prDeleteList = new List<SMAX_PS_ProductRevision__c>();
		List<SMAX_PS_ProductClassification__c> pcDeleteList = new List<SMAX_PS_ProductClassification__c>();
		List<SMAX_PS_ProductSales__c> psUpdateList = new List<SMAX_PS_ProductSales__c>();
		List<SMAX_PS_ProductPlant__c> ppUpdateList = new List<SMAX_PS_ProductPlant__c>();
		Map<Id, List<SMAX_PS_ProductRevision__c>> prMap = new Map<Id, List<SMAX_PS_ProductRevision__c>>();
		Map<Id, List<SMAX_PS_ProductClassification__c>> pcMap = new Map<Id, List<SMAX_PS_ProductClassification__c>>();
		Map<Id, List<SMAX_PS_ProductSales__c>> psMap = new Map<Id, List<SMAX_PS_ProductSales__c>>();
		Map<Id, List<SMAX_PS_ProductPlant__c>> ppMap = new Map<Id, List<SMAX_PS_ProductPlant__c>>();
		Set<Id> productIds = new Set<Id>();

		// ITSFDC-350 Adding Contract Discount Exception (CDE)
		List<BD_Contract_Discount_Exception__c> cdeDeleteList = new List<BD_Contract_Discount_Exception__c>();
		Map<Id, List<BD_Contract_Discount_Exception__c>> cdeMap = new Map<Id, List<BD_Contract_Discount_Exception__c>>();

		// ITSFDC-507 Adding Extended Warranty Parts (EWP)
		List<BD_Extended_Warranty_Part__c> ewpUpdateList = new List<BD_Extended_Warranty_Part__c>();
		Map<Id, List<BD_Extended_Warranty_Part__c>> ewpMap = new Map<Id, List<BD_Extended_Warranty_Part__c>>();

		if (!newProductList.isEmpty()) {
			for (Product2 prod : newProductList)
			{
				if ( oldProductMap.get(prod.Id) != null
						&& oldProductMap.get(prod.Id).SMAX_PS_CompletedTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c ) {
					productIds.add(prod.Id);
				}
			}
		}
		// Exit if no records are qualified
		if (productIds.isEmpty()) {
			return;
		}

		List<SMAX_PS_ProductRevision__c> prList = new List<SMAX_PS_ProductRevision__c>([SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ProductRevision__c WHERE SMAX_PS_Product__c IN :productIds]);
												  
		List<SMAX_PS_ProductClassification__c> pcList = new List<SMAX_PS_ProductClassification__c>([SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ProductClassification__c WHERE SMAX_PS_Product__c IN :productIds]);

		List<SMAX_PS_ProductSales__c> psList = new List<SMAX_PS_ProductSales__c>([SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_LastTxnNum__c, SMAX_PS_SAP_Deleted__c FROM SMAX_PS_ProductSales__c WHERE SMAX_PS_Product__c IN :productIds]);

		List<SMAX_PS_ProductPlant__c> ppList = new List<SMAX_PS_ProductPlant__c>([SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_LastTxnNum__c, SMAX_PS_SAP_Deleted__c FROM SMAX_PS_ProductPlant__c WHERE SMAX_PS_Product__c IN :productIds]);

		// ITSFDC-350 Adding Contract Discount Exception (CDE)
		List<BD_Contract_Discount_Exception__c> cdeList = new List<BD_Contract_Discount_Exception__c>([SELECT Id, Name, BD_Parts_Product__c, BD_Last_Txn_Number__c FROM BD_Contract_Discount_Exception__c WHERE BD_Parts_Product__c IN :productIds]);

		// ITSFDC-507 Adding Extended Warranty Parts (EWP)
		List<BD_Extended_Warranty_Part__c> ewpList = new List<BD_Extended_Warranty_Part__c>([SELECT Id, Name, BD_Equipment_Product__c, BD_Last_Txn_Number__c FROM BD_Extended_Warranty_Part__c WHERE BD_Equipment_Product__c IN :productIds]);

		// Fill in Product Revision Map
		if (!prList.isEmpty()) {
			for (SMAX_PS_ProductRevision__c pr : prList) {
				List<SMAX_PS_ProductRevision__c> listPR = new List<SMAX_PS_ProductRevision__c>();
				if(prMap.containsKey(pr.SMAX_PS_Product__c)) {
					listPR = prMap.get(pr.SMAX_PS_Product__c);
				}
				listPR.add(pr);
				prMap.put(pr.SMAX_PS_Product__c, listPR);
			}
		}

		// Fill in Product Classification Map
		if (!pcList.isEmpty()) {
			for (SMAX_PS_ProductClassification__c pc : pcList) {
				List<SMAX_PS_ProductClassification__c> listPC = new List<SMAX_PS_ProductClassification__c>();                
				if(pcMap.containsKey(pc.SMAX_PS_Product__c)) {
					listPC = pcMap.get(pc.SMAX_PS_Product__c);
				}
				listPC.add(pc);
				pcMap.put(pc.SMAX_PS_Product__c, listPC);
			}
		}

		// Fill in Product Sales Map
		if (!psList.isEmpty()) {
			for (SMAX_PS_ProductSales__c ps : psList) {
				List<SMAX_PS_ProductSales__c> listPS = new List<SMAX_PS_ProductSales__c>();
				if(psMap.containsKey(ps.SMAX_PS_Product__c)) {
					listPS = psMap.get(ps.SMAX_PS_Product__c);
				}
				listPS.add(ps);
				psMap.put(ps.SMAX_PS_Product__c, listPS);
			}
		}

		// Fill in Product Plant Map
		if (!ppList.isEmpty()) {
			for (SMAX_PS_ProductPlant__c pp : ppList) {
				List<SMAX_PS_ProductPlant__c> listPP = new List<SMAX_PS_ProductPlant__c>();                
				if(ppMap.containsKey(pp.SMAX_PS_Product__c)) {
					listPP = ppMap.get(pp.SMAX_PS_Product__c);
				}
				listPP.add(pp);
				ppMap.put(pp.SMAX_PS_Product__c, listPP);
			}
		}

		// ITSFDC-350 Fill in Contract Discount Exception Map
		if (!cdeList.isEmpty()) {
			for (BD_Contract_Discount_Exception__c cde : cdeList) {
				List<BD_Contract_Discount_Exception__c> listCDE = new List<BD_Contract_Discount_Exception__c>();
				if(cdeMap.containsKey(cde.BD_Parts_Product__c)) {
					listCDE = cdeMap.get(cde.BD_Parts_Product__c);
				}
				listCDE.add(cde);
				cdeMap.put(cde.BD_Parts_Product__c, listCDE);
			}
		}

		// ITSFDC-507 Fill in Extended Warranty Parts Map
		if (!ewpList.isEmpty()) {
			for (BD_Extended_Warranty_Part__c ewp : ewpList) {
				List<BD_Extended_Warranty_Part__c> listEWP = new List<BD_Extended_Warranty_Part__c>();
				if(ewpMap.containsKey(ewp.BD_Equipment_Product__c)) {
					listEWP = ewpMap.get(ewp.BD_Equipment_Product__c);
				}
				listEWP.add(ewp);
				ewpMap.put(ewp.BD_Equipment_Product__c, listEWP);
			}
		}

		// Main process
		if (!newProductList.isEmpty()) {
			for ( Product2 prod : newProductList ) {
				// create list of records to be deleted in Product Revision
				List<SMAX_PS_ProductRevision__c> listPR = new List<SMAX_PS_ProductRevision__c>();
				if ( prMap.containsKey(prod.Id) ) {
					listPR = prMap.get(prod.Id);
					if (!listPR.isEmpty()) {
						for (SMAX_PS_ProductRevision__c pr : listPR) {
							if (pr.SMAX_PS_LastTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c) {
								prDeleteList.add(pr);
							}
						}
					}
				}
				// create list of records to be deleted in Product Classification
				List<SMAX_PS_ProductClassification__c> listPC = new List<SMAX_PS_ProductClassification__c>();
				if ( pcMap.containsKey(prod.Id) ) {
					listPC = pcMap.get(prod.Id);
					if (!listPC.isEmpty()) {
						for (SMAX_PS_ProductClassification__c pc : listPC) {
							if (pc.SMAX_PS_LastTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c) {
								pcDeleteList.add(pc);
							}
						}
					}
				}
				// create list of records to be updated in Product Sales
				List<SMAX_PS_ProductSales__c> listPS = new List<SMAX_PS_ProductSales__c>();
				if ( psMap.containsKey(prod.Id) ) {
					listPS = psMap.get(prod.Id);
					if (!listPS.isEmpty()) {
						for (SMAX_PS_ProductSales__c ps : listPS) {
							if (ps.SMAX_PS_LastTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c) {
								ps.SMAX_PS_SAP_Deleted__c = true;
								psUpdateList.add(ps);
							}
						}
					}
				}
				// create list of records to be updated in Product Plant
				List<SMAX_PS_ProductPlant__c> listPP = new List<SMAX_PS_ProductPlant__c>();
				if ( ppMap.containsKey(prod.Id) ) {
					listPP = ppMap.get(prod.Id);
					if (!listPP.isEmpty()) {
						for (SMAX_PS_ProductPlant__c pp : listPP) {
							if (pp.SMAX_PS_LastTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c) {
								pp.SMAX_PS_SAP_Deleted__c = true;
								ppUpdateList.add(pp);
							}
						}
					}
				}
				// ITSFDC-350 create list of records to be deleted in Contract Discount Exception
				List<BD_Contract_Discount_Exception__c> listCDE = new List<BD_Contract_Discount_Exception__c>();
				if ( cdeMap.containsKey(prod.Id) ) {
					listCDE = cdeMap.get(prod.Id);
					if (!listCDE.isEmpty()) {
						for (BD_Contract_Discount_Exception__c cde : listCDE) {
							if (cde.BD_Last_Txn_Number__c != prod.SMAX_PS_CompletedTxnNum__c) {
								cdeDeleteList.add(cde);
							}
						}
					}
				}
				// ITSFDC-507 create list of records to be updated in Extended Warranty Parts
				List<BD_Extended_Warranty_Part__c> listEWP = new List<BD_Extended_Warranty_Part__c>();
				if ( ewpMap.containsKey(prod.Id) ) {
					listEWP = ewpMap.get(prod.Id);
					if (!listEWP.isEmpty()) {
						for (BD_Extended_Warranty_Part__c ewp : listEWP) {
							if (ewp.BD_Last_Txn_Number__c != prod.SMAX_PS_CompletedTxnNum__c) {
								ewp.BD_Is_Deleted__c = true;
								ewpUpdateList.add(ewp);
							}
						}
					}
				}
			}
			// Delete Product Revision, Product Classification and Update Product Sales, Product Plant
			if (!prDeleteList.isEmpty()) {
				delete prDeleteList;
			}
			if (!pcDeleteList.isEmpty()) {
				delete pcDeleteList;
			}
			if (!psUpdateList.isEmpty()) {
				update psUpdateList;
			}
			if (!ppUpdateList.isEmpty()) {
				update ppUpdateList;
			}
			if (!cdeDeleteList.isEmpty()) {
				delete cdeDeleteList;
			}
			if (!ewpUpdateList.isEmpty()) {
				update ewpUpdateList;
			}
		}
	}

	public static void deleteProductChildRecords(List<Product2> prodOldList)
	{    
		
		if (!SMAX_PS_Utility.isActive('Delete Product Child Records', 'Deletes related Product Sales, Product Plant, Product Revision and Product Classification when a Product is deleted.'))
		{	return;	}

		Set<Id> prodIdSet = new Set<Id>();

		if (!prodOldList.isEmpty()) {
			for (Product2 prd : prodOldList) {
				prodIdSet.add(prd.Id);
			}
		}
		System.debug('prodIdSet->'+prodIdSet);
		// Exit if no records are qualified
		if (prodIdSet.isEmpty()) {
			return;
		}

		// Delete the related Revision records
		List<SMAX_PS_ProductRevision__c> prodRevList = [SELECT Id FROM SMAX_PS_ProductRevision__c WHERE SMAX_PS_Product__c IN :prodIdSet];
		if (!prodRevList.isEmpty()) {
			delete prodRevList;
		}

		// Delete the related Classification records
		List<SMAX_PS_ProductClassification__c> prodClsList = [SELECT Id FROM SMAX_PS_ProductClassification__c WHERE SMAX_PS_Product__c IN :prodIdSet];
		if (!prodClsList.isEmpty()) {
			delete prodClsList;
		}

		// Delete the related Sales records
		List<SMAX_PS_ProductSales__c> prodSalesList = [SELECT Id FROM SMAX_PS_ProductSales__c WHERE SMAX_PS_Product__c IN :prodIdSet];
		if (!prodSalesList.isEmpty()) {
			delete prodSalesList;
		}

		// Delete the related Plant records
		List<SMAX_PS_ProductPlant__c> prodPlantList = [SELECT Id FROM SMAX_PS_ProductPlant__c WHERE SMAX_PS_Product__c IN :prodIdSet];
		if (!prodPlantList.isEmpty()) {
			delete prodPlantList;
		}

		// ITSFDC-350 Delete the related Contract Discount Exception (CDE)
		List<BD_Contract_Discount_Exception__c> cdeList = [SELECT Id FROM BD_Contract_Discount_Exception__c WHERE BD_Parts_Product__c IN :prodIdSet];
		if (!cdeList.isEmpty()) {
			delete cdeList;
		}

		// ITSFDC-507 Delete the related Extended Warranty Parts (EWP)
		List<BD_Extended_Warranty_Part__c> ewpList = [SELECT Id FROM BD_Extended_Warranty_Part__c WHERE BD_Equipment_Product__c IN :prodIdSet];
		if (!ewpList.isEmpty()) {
			delete ewpList;
		}

	}

	public static void processProductClassifications(List<SMAX_PS_ProductClassification__c> pcList, Map<Id, SMAX_PS_ProductClassification__c> oldMap)
	{
		Map<Id, Product2> prodMap = new Map<Id, Product2>();
		for(SMAX_PS_ProductClassification__c pc : pcList)
		{
			if (pc.SMAX_PS_Characteristic__c == 'PE Medical Device' || pc.SMAX_PS_Characteristic__c == 'PE_MEDICAL_DEVICE')
			{
				Product2 p = new Product2();
				p.Id = pc.SMAX_PS_Product__c;
				p.SMAX_PS_Medical_Classification__c = pc.SMAX_PS_Value__c;
				prodMap.put(p.Id, p);
			}
		}

		if (!prodMap.isEmpty())
		{
			Database.update(prodMap.values(), false);
		}
	}

	public static void processProductSales(List<SMAX_PS_ProductSales__c> psList, Map<Id, SMAX_PS_ProductSales__c> oldMap)
	{
		Set<Id> productIds = new Set<Id>();
		for(SMAX_PS_ProductSales__c pSales : psList)
		{
			productIds.add(pSales.SMAX_PS_Product__c);
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name, 
			Description, Partnum__c, SVMXC__Product_Type__c, SMAX_PS_ActivityType__c
			FROM Product2 WHERE Id IN :productIds]);
		for(SMAX_PS_ProductSales__c pSales : psList)
		{
			Product2 prod = productMap.get(pSales.SMAX_PS_Product__c);
			
			pSales.SMAX_PS_PartDescription__c = prod.Description;
			if (pSales.SMAX_PS_PartDescription__c != null && pSales.SMAX_PS_PartDescription__c.length() > 255)
			{
				pSales.SMAX_PS_PartDescription__c = pSales.SMAX_PS_PartDescription__c.substring(0, 252) + '...';
			}

			pSales.SMAX_PS_PartNumber__c = prod.Partnum__c;
			pSales.SMAX_PS_ProductType__c = prod.SVMXC__Product_Type__c;
			pSales.SMAX_PS_SAP_ActivityType__c = prod.SMAX_PS_ActivityType__c;
		}
	}

	// ITSFDC-509 Lookup the "Return Part" from the "Return Part Number"
	public static void processProductPlant(List<SMAX_PS_ProductPlant__c> ppList, Map<Id, SMAX_PS_ProductPlant__c> oldMap)
	{
		// 2022-04-20 Tony ITSVMX-562 Modify the replenishment parts ordering process
		Set<String> refurbPartNumbers = new Set<String>();
		Set<String> productCodes = new Set<String>();
		for(SMAX_PS_ProductPlant__c pPlant : ppList)
		{
			if (pPlant.BD_Return_Part__c == null && pPlant.BD_Return_Part_Number__c != null)
			{
				productCodes.add(pPlant.BD_Return_Part_Number__c);
			}

			// 2022-04-20 Tony ITSVMX-562 Get the list of Refurbished Part Numbers that don't have a Refurbished Part
			if (pPlant.BD_Refurbished_Part__c == null && pPlant.BD_Refurbished_Part_Number__c != null)
			{
				refurbPartNumbers.add(pPlant.BD_Refurbished_Part_Number__c);
			}
		}

		if (productCodes.isEmpty() && refurbPartNumbers.isEmpty())
		{
			return;
		}

		Map<String, Product2> productMap = new Map<String, Product2>();
		for (Product2 prod : [SELECT Id, Name, Partnum__c
			FROM Product2 WHERE Partnum__c IN :productCodes])
		{
			productMap.put(prod.Partnum__c, prod);
		}

		// 2022-04-20 Tony ITSVMX-562 Get a Map of the Refurbished Part Numbers to Products
		Map<String, Product2> refurbPartMap = new Map<String, Product2>();
		for (Product2 prod : [SELECT Id, Name, Partnum__c
		FROM Product2 WHERE Partnum__c IN :refurbPartNumbers])
		{
			refurbPartMap.put(prod.Partnum__c, prod);
		}

		for(SMAX_PS_ProductPlant__c pPlant : ppList)
		{
			if (pPlant.BD_Return_Part__c == null && pPlant.BD_Return_Part_Number__c != null)
			{
				Product2 prod = productMap.get(pPlant.BD_Return_Part_Number__c);
				if (prod != null)
				{
					pPlant.BD_Return_Part__c = prod.Id;
				}
			}

			// 2022-04-20 Tony ITSVMX-562 If there is a Refurbished Part Numbers but no Refurbished Part then add it
			if (pPlant.BD_Refurbished_Part__c == null && pPlant.BD_Refurbished_Part_Number__c != null)
			{
				Product2 refurbPart = refurbPartMap.get(pPlant.BD_Refurbished_Part_Number__c);
				if (refurbPart != null)
				{
					pPlant.BD_Refurbished_Part__c = refurbPart.Id;
				}
			}
		}
	}

}
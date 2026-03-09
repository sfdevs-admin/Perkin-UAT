/**
 * Created by frankvanloon on 2019-11-11.
 */
public without sharing class SMAX_PS_ExtendedWarranty {

	public class ExtendedWarrantyCoverage {
		@AuraEnabled public String extendedWarrantyPart {get;set;}
		@AuraEnabled public String warrantyContract {get;set;}
		@AuraEnabled public String warrantyContractItem {get;set;}
		@AuraEnabled public String coveredPart {get;set;}
		@AuraEnabled public Date coveredUntil {get;set;}

		@AuraEnabled public String extendedWarrantyPartId {get;set;}
		@AuraEnabled public String warrantyContractId {get;set;}
		@AuraEnabled public String warrantyContractItemId {get;set;}
		@AuraEnabled public String coveredPartId {get;set;}
	}

	// ITSVMX-386 Used by the smaxExtendedWarranty LWC
	@AuraEnabled(Cacheable=true)
	public static List<ExtendedWarrantyCoverage> getCoveragesForIp(Id ipId)
	{
		List<Id> ipIds = new List<Id>();
		ipIds.add(ipId);

		List<BD_Extended_Warranty_Coverage__c> coverages = getCoverages(ipIds, null);
		System.debug('coverages: ' + coverages);

		Set<Id> warrantyPartIds = new Set<Id>();
		Set<Id> warrantyContractIds = new Set<Id>();
		Set<Id> warrantyContractItemIds = new Set<Id>();
		Set<Id> coveredPartIds = new Set<Id>();
		for (BD_Extended_Warranty_Coverage__c coverage :coverages) {
			warrantyPartIds.add(coverage.BD_Extended_Warranty_Part__c);
			warrantyContractIds.add(coverage.BD_Warranty_Contract__c);
			warrantyContractItemIds.add(coverage.BD_Warranty_Contract_Item__c);
			coveredPartIds.add(coverage.BD_Covered_Part__c);
		}

		Map<Id, BD_Extended_Warranty_Part__c> warrantyPartMap = new Map<Id, BD_Extended_Warranty_Part__c>([
				SELECT Id, Name
				FROM BD_Extended_Warranty_Part__c
				WHERE Id IN :warrantyPartIds
		]);

		Map<Id, SVMXC__Service_Contract__c> warrantyContractMap = new Map<Id, SVMXC__Service_Contract__c>([
				SELECT Id, Name
				FROM SVMXC__Service_Contract__c
				WHERE Id IN :warrantyContractIds
		]);

		Map<Id, SVMXC__Service_Contract__c> warrantyContractItemMap = new Map<Id, SVMXC__Service_Contract__c>([
				SELECT Id, Name
				FROM SVMXC__Service_Contract__c
				WHERE Id IN :warrantyContractItemIds
		]);

		Map<Id, Product2> coveredPartMap = new Map<Id, Product2>([
				SELECT Id, Name
				FROM Product2
				WHERE Id IN :coveredPartIds
		]);

		List<ExtendedWarrantyCoverage> extendedWarrantyCoverages = new List<ExtendedWarrantyCoverage>();
		for (BD_Extended_Warranty_Coverage__c coverage :coverages) {
			ExtendedWarrantyCoverage ewc = new ExtendedWarrantyCoverage();
			ewc.extendedWarrantyPart = warrantyPartMap.get(coverage.BD_Extended_Warranty_Part__c).Name;
			ewc.warrantyContract = warrantyContractMap.get(coverage.BD_Warranty_Contract__c).Name;
			ewc.warrantyContractItem = warrantyContractItemMap.get(coverage.BD_Warranty_Contract_Item__c).Name;
			ewc.coveredPart = coveredPartMap.get(coverage.BD_Covered_Part__c).Name;
			ewc.coveredUntil = coverage.BD_Covered_Until__c;

			ewc.extendedWarrantyPartId = warrantyPartMap.get(coverage.BD_Extended_Warranty_Part__c).Id;
			ewc.warrantyContractId = warrantyContractMap.get(coverage.BD_Warranty_Contract__c).Id;
			ewc.warrantyContractItemId = warrantyContractItemMap.get(coverage.BD_Warranty_Contract_Item__c).Id;
			ewc.coveredPartId = coveredPartMap.get(coverage.BD_Covered_Part__c).Id;
			extendedWarrantyCoverages.add(ewc);
		}
		System.debug('extendedWarrantyCoverages: ' + extendedWarrantyCoverages);

		return extendedWarrantyCoverages;
	}

	public static List<BD_Extended_Warranty_Coverage__c> getCoverages(List<Id> ipIds, List<SVMXC__Service_Order__c> woToProcess)
	{
		System.debug('ipIds: ' + ipIds);
		System.debug('woToProcess: ' + woToProcess);

		List<BD_Extended_Warranty_Coverage__c> newCoverages = new List<BD_Extended_Warranty_Coverage__c>();
		Set<Id> productIds = new Set<Id>();
		Map<Id, SVMXC__Service_Contract_Products__c> ipCpMap = new Map<Id, SVMXC__Service_Contract_Products__c>();
		List<SVMXC__Service_Contract_Products__c> cpList = [SELECT Id, Name,
				SVMXC__Installed_Product__c,
				SVMXC__Installed_Product__r.SVMXC__Product__c,
				SVMXC__Installed_Product__r.SVMXC__Site__r.SMAX_PS_SalesOrg__c,
				SVMXC__Service_Contract__r.Id,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Enterprise__c,
				SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c,
				SVMXC__Service_Contract__r.SMAX_PS_SLA_Terms_Notes__c,
				SVMXC__Service_Contract__r.SMAX_PS_SalesOrg__c,
				SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c,
				SVMXC__Start_Date__c, SVMXC__End_Date__c
		FROM SVMXC__Service_Contract_Products__c
		WHERE SVMXC__Installed_Product__c IN :ipIds
		AND SVMXC__End_Date__c < TODAY
		AND SMAX_PS_IsDeleted__c = FALSE
		AND SVMXC__Service_Contract__r.SMAX_PS_Is_Warranty__c = TRUE
		ORDER BY SVMXC__End_Date__c];
		for (SVMXC__Service_Contract_Products__c cp : cpList)
		{
			// ITSVMX-1251 Adding check of the Sales Org to make sure we only select Contracts in the same Sales Org as the IP/Location
			if (cp.SVMXC__Installed_Product__c != null && cp.SVMXC__Installed_Product__r.SVMXC__Product__c != null
				&& cp.SVMXC__Installed_Product__r.SVMXC__Site__r.SMAX_PS_SalesOrg__c == cp.SVMXC__Service_Contract__r.SMAX_PS_SalesOrg__c)
			{
				// NOTE: If more than one CP per IP found this will overwrite with the latest thanks to the ORDER BY above
				ipCpMap.put(cp.SVMXC__Installed_Product__c, cp);
				productIds.add(cp.SVMXC__Installed_Product__r.SVMXC__Product__c);
			}
		}

		// No Expired Contracts found.. go ahead and exit now
		if (productIds.isEmpty())
		{
			return newCoverages;
		}

		List<BD_Extended_Warranty_Part__c> allEWP = [SELECT Id, Name, BD_Equipment_Product__c,
				BD_Extended_Months__c, BD_Covered_Part__c, BD_Sales_Org__c
		FROM BD_Extended_Warranty_Part__c WHERE BD_Equipment_Product__c IN :productIds AND BD_Is_Deleted__c = FALSE];

		// If no Extended Warranty Parts were found.. go ahead and exit now
		if (allEWP.isEmpty())
		{
			return newCoverages;
		}

		Map<Id, List<BD_Extended_Warranty_Part__c>> eqEwpMap = new Map<Id, List<BD_Extended_Warranty_Part__c>>();
		for (BD_Extended_Warranty_Part__c ewp : allEWP)
		{
			if (!eqEwpMap.containsKey(ewp.BD_Equipment_Product__c))
			{
				eqEwpMap.put(ewp.BD_Equipment_Product__c, new List<BD_Extended_Warranty_Part__c>());
			}
			eqEwpMap.get(ewp.BD_Equipment_Product__c).add(ewp);
		}

		if (woToProcess == null)
		{
			for (Id ipId : ipIds)
			{
				SVMXC__Service_Contract_Products__c cp = ipCpMap.get(ipId);
				if (cp != null)
				{
					SVMXC__Service_Contract__c item = cp.SVMXC__Service_Contract__r;
					Id eqProdId = cp.SVMXC__Installed_Product__r.SVMXC__Product__c;
					String salesOrg = (cp.SVMXC__Installed_Product__r.SVMXC__Site__r == null) ? null:
							cp.SVMXC__Installed_Product__r.SVMXC__Site__r.SMAX_PS_SalesOrg__c;

					List<BD_Extended_Warranty_Part__c> ewpList = eqEwpMap.get(eqProdId);
					if (ewpList == null || ewpList.isEmpty())
					{
						continue;
					}

					for (BD_Extended_Warranty_Part__c ewp : ewpList)
					{
						// If SalesOrgs match... create a Extended Warranty Coverage (EWC)
						if (salesOrg == null || ewp.BD_Sales_Org__c == null || ewp.BD_Sales_Org__c.equalsIgnoreCase(salesOrg))
						{
							BD_Extended_Warranty_Coverage__c ewc = new BD_Extended_Warranty_Coverage__c();
							ewc.BD_Extended_Warranty_Part__c = ewp.Id;
							ewc.BD_Parent_Work_Order__c = null;
							ewc.BD_Warranty_Contract__c = item.SVMX_PS_Parent_Contract__c;
							ewc.BD_Warranty_Contract_Item__c = item.Id;
							ewc.BD_Covered_Part__c = ewp.BD_Covered_Part__c;
							ewc.BD_Covered_Until__c = cp.SVMXC__End_Date__c.addMonths(ewp.BD_Extended_Months__c.intValue());

							newCoverages.add(ewc);
						}
					}
				}
			}
		} else
		{
			for (SVMXC__Service_Order__c wo : woToProcess)
			{
				SVMXC__Service_Contract_Products__c cp = ipCpMap.get(wo.SVMXC__Component__c);
				if (cp != null)
				{
					SVMXC__Service_Contract__c item = cp.SVMXC__Service_Contract__r;
					Id eqProdId = cp.SVMXC__Installed_Product__r.SVMXC__Product__c;
					String salesOrg = (cp.SVMXC__Installed_Product__r.SVMXC__Site__r == null) ? null:
							cp.SVMXC__Installed_Product__r.SVMXC__Site__r.SMAX_PS_SalesOrg__c;

					List<BD_Extended_Warranty_Part__c> ewpList = eqEwpMap.get(eqProdId);
					if (ewpList == null || ewpList.isEmpty())
					{
						continue;
					}

					for (BD_Extended_Warranty_Part__c ewp : ewpList)
					{
						// If SalesOrgs match... create a Extended Warranty Coverage (EWC)
						if (salesOrg == null || ewp.BD_Sales_Org__c == null || ewp.BD_Sales_Org__c.equalsIgnoreCase(salesOrg))
						{
							BD_Extended_Warranty_Coverage__c ewc = new BD_Extended_Warranty_Coverage__c();
							ewc.BD_Extended_Warranty_Part__c = ewp.Id;
							ewc.BD_Parent_Work_Order__c = wo.Id;
							ewc.BD_Warranty_Contract__c = item.SVMX_PS_Parent_Contract__c;
							ewc.BD_Warranty_Contract_Item__c = item.Id;
							ewc.BD_Covered_Part__c = ewp.BD_Covered_Part__c;
							ewc.BD_Covered_Until__c = cp.SVMXC__End_Date__c.addMonths(ewp.BD_Extended_Months__c.intValue());

							newCoverages.add(ewc);
						}
					}
				}
			}
		}

		return newCoverages;
	}

	public static void createCoverage(List<SVMXC__Service_Order__c> woList)
	{
		if (!SMAX_PS_Utility.isActive('WO Extended Warranty Coverage', 'Create Extended Warranty Coverage records for the Work Order, if corresponding Expired Warranty and Extended Warranty Parts records are found.'))
		{	return;	}

		// TODO: Do we need to support changes to the Lookup(Installed Product)? (would need to add to update trigger)

		Set<Id> ipIds = new Set<Id>();
		List<SVMXC__Service_Order__c> woToProcess = new List<SVMXC__Service_Order__c>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			// NOTE: Assume that if the WO is "Entitled by Warranty" then an "Extended Warranty" would NOT apply
			if (wo.SMAX_PS_IsEntitledWarranty__c == false && wo.SVMXC__Component__c != null)
			{
				ipIds.add(wo.SVMXC__Component__c);
				woToProcess.add(wo);
			}
		}

		if (woToProcess.isEmpty())
		{
			return;
		}

		List<BD_Extended_Warranty_Coverage__c> newCoverages = getCoverages(new List<Id>(ipIds), woList);

		if (!newCoverages.isEmpty())
		{
			insert newCoverages;
		}
	}

	public static void createExtendedWarrantyWorkOrders(List<BD_Extended_Warranty_Coverage__c> ewcList, Map<Id, BD_Extended_Warranty_Coverage__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('WO Extended Warranty WOs', 'Create Extended Warranty Work Orders for the Coverage, if corresponding Create Work Order is checked.'))
		{	return;	}

		Set<Id> woIds = new Set<Id>();
		List<BD_Extended_Warranty_Coverage__c> ewcToUpdate = new List<BD_Extended_Warranty_Coverage__c>();
		for (BD_Extended_Warranty_Coverage__c ewc : ewcList)
		{
			BD_Extended_Warranty_Coverage__c old = (oldMap == null) ? null : oldMap.get(ewc.Id);
			if (old != null && ewc.BD_Create_Warranty_Work_Order__c == TRUE && ewc.BD_Warranty_Work_Order__c == null
					&& old.BD_Create_Warranty_Work_Order__c != ewc.BD_Create_Warranty_Work_Order__c)
			{
				// When the "Create Work Order" checkbox is checked, create a Work Order...
				ewcToUpdate.add(ewc);
				woIds.add(ewc.BD_Parent_Work_Order__c);
			}
		}

		if (ewcToUpdate.isEmpty())
		{
			return;
		}

		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name, RecordTypeId,
				SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMX_PS_Origin__c, SVMXC__Priority__c,
				SVMXC__Company__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c, SVMXC__Component__c,
				SVMXC__Site__c, SVMXC__Contact__c, SVMXC__Group_Member__c, SMAX_PS_Customer_Required_Start_Date__c,
				SVMXC__Problem_Description__c, SVMX_PS_Problem_Summary__c,
				SMAX_PS_SettlementOrderType__c, SMAX_PS_SettlementReciever__c,
				SVMXC__City__c, SVMXC__State__c, SVMXC__Street__c, SVMXC__Zip__c, SVMXC__Country__c
			FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);

		RecordType fsRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
		Map<BD_Extended_Warranty_Coverage__c, SVMXC__Service_Order__c> ewcWoMap = new Map<BD_Extended_Warranty_Coverage__c, SVMXC__Service_Order__c>();
		for (BD_Extended_Warranty_Coverage__c ewc : ewcToUpdate)
		{
			SVMXC__Service_Order__c wo = woMap.get(ewc.BD_Parent_Work_Order__c);
			if (wo != null)
			{
				SVMXC__Service_Order__c newWO = new SVMXC__Service_Order__c();
				newWO.SVMX_PS_Parent_Work_Order__c = wo.Id;
				newWO.RecordTypeId = fsRT.Id;
				newWO.SVMXC__Order_Status__c = 'Initializing';
				newWO.SVMXC__Billing_Type__c = 'Contract';
				newWO.SVMXC__Service_Contract__c = ewc.BD_Warranty_Contract__c;
				newWO.SMAX_PS_ContractItem__c = ewc.BD_Warranty_Contract_Item__c;
				newWO.SVMXC__Order_Type__c = wo.SVMXC__Order_Type__c;
				newWO.SVMX_PS_Origin__c = wo.SVMX_PS_Origin__c;
				newWO.SVMXC__Priority__c = wo.SVMXC__Priority__c;
				newWO.SVMXC__Company__c = wo.SVMXC__Company__c;
				newWO.SMAX_PS_BillTo__c = wo.SMAX_PS_BillTo__c;
				newWO.SMAX_PS_Payer__c = wo.SMAX_PS_Payer__c;
				newWO.SMAX_PS_ShipTo__c = wo.SMAX_PS_ShipTo__c;
				newWO.SVMXC__Component__c = wo.SVMXC__Component__c;
				newWO.SVMXC__Site__c = wo.SVMXC__Site__c;
				newWO.SVMXC__Contact__c = wo.SVMXC__Contact__c;
				newWO.SVMXC__Group_Member__c = wo.SVMXC__Group_Member__c;
				newWO.SMAX_PS_Customer_Required_Start_Date__c = wo.SMAX_PS_Customer_Required_Start_Date__c;
				newWO.SVMXC__Problem_Description__c = ewc.BD_Extended_Warranty_Description__c
					+ '\n' + wo.SVMXC__Problem_Description__c;
				newWO.SVMX_PS_Problem_Summary__c = wo.SVMX_PS_Problem_Summary__c;
				newWO.SMAX_PS_SettlementOrderType__c = wo.SMAX_PS_SettlementOrderType__c;
				newWO.SMAX_PS_SettlementReciever__c = wo.SMAX_PS_SettlementReciever__c;
				newWO.SVMXC__City__c = wo.SVMXC__City__c;
				newWO.SVMXC__State__c = wo.SVMXC__State__c;
				newWO.SVMXC__Street__c = wo.SVMXC__Street__c;
				newWO.SVMXC__Zip__c = wo.SVMXC__Zip__c;
				newWO.SVMXC__Country__c = wo.SVMXC__Country__c;

				ewcWoMap.put(ewc, newWO);
			}

		}

		if (ewcWoMap.isEmpty())
		{
			return;
		}

		insert ewcWoMap.values();

		for (BD_Extended_Warranty_Coverage__c ewc : ewcWoMap.keySet())
		{
			SVMXC__Service_Order__c wo = ewcWoMap.get(ewc);
			if (wo != null)
			{
				ewc.BD_Warranty_Work_Order__c = wo.Id;
			}
		}
	}
}
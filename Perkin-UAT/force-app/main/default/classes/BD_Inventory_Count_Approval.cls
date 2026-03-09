/**
 * This class encapsulates all of the Wired Services needed for the Inventory Count LWC
 * Created by frankvanloon & Seth on 5/5/20.
 * Updated by frankvanloon on 11/16/2021: Preventing updates to Inventory Count if already Approved
 */
public class BD_Inventory_Count_Approval {

	public class BD_Inventory_Count_Exception extends Exception { }

	// Results for the Single or Multi Select Picklists
	public class LabelValue
	{
		@AuraEnabled public String label { get; set; }
		@AuraEnabled public String value { get; set; }

		public LabelValue(String l, String v)
		{
			this.label = l;
			this.value = v;
		}
	}

	// Used to initialize the filters on the LWC
	public class InventoryCountFilterData
	{
		@AuraEnabled public List<LabelValue> allPlants { get; set; }
		@AuraEnabled public List<LabelValue> allStatuses { get; set; }
		@AuraEnabled public List<LabelValue> allTechnicians { get; set;}
		@AuraEnabled public String location { get; set; }
		@AuraEnabled public SMAX_PS_InventoryCount__c countTemplate { get; set; }

		public InventoryCountFilterData()
		{
		}
	}

	// Filter parameters passed from the LWC
	public class InventoryCountFilter
	{
		@AuraEnabled public List<String> selectedPlants { get; set; }
		@AuraEnabled public List<String> selectedStatuses { get; set; }
		@AuraEnabled public String selectedLocation { get; set; }
		@AuraEnabled public String selectedTechnician { get; set;}
		@AuraEnabled public List<BD_CustomLookupService.LookupSearchResult> selectedTechnicians { get; set; }

		public InventoryCountFilter()
		{
		}
	}

	// Parameters passed in to update a set of Inventory Count Line records
	public class InventoryUpdateList
	{
		@AuraEnabled public List<String> selectedLines { get; set; }
		@AuraEnabled public String selectedReviewStatus { get; set; }
		@AuraEnabled public String selectedRejectReason { get; set;}

		public InventoryUpdateList()
		{
		}
	}

	// 8/17/20 tony - Parameters passed in to update Inventory Count Lines for a single selected Inventory Count header
	public class InventoryHeaderUpdateData
	{
		@AuraEnabled public String selectedHeaderLine { get; set; }
		@AuraEnabled public String selectedReviewStatus { get; set; }
		@AuraEnabled public String selectedRejectReason { get; set;}

		public InventoryHeaderUpdateData()
		{
		}
	}

	@AuraEnabled(Cacheable=true)
	public static InventoryCountFilterData lookupFilters()
	{
		InventoryCountFilterData result = new InventoryCountFilterData();
		result.allPlants = loadPlants();
		result.allStatuses = new List<LabelValue>();
		Schema.DescribeFieldResult fieldResult = SMAX_PS_InventoryCount__c.SMAX_PS_Status__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			result.allStatuses.add(new LabelValue(pickListVal.getLabel(),pickListVal.getLabel()));
		}

		result.countTemplate = new SMAX_PS_InventoryCount__c();
		return result;
	}

	public static List<LabelValue> loadPlants()
	{
		List<LabelValue> plants=new List<LabelValue>();
		for(AggregateResult s:[SELECT SMAX_PS_Plant__c FROM SVMXC__Service_Group_Members__c
				WHERE SMAX_PS_Plant__c!=NULL GROUP BY SMAX_PS_Plant__c])
		{
			String p=(String) s.get('SMAX_PS_Plant__c');
			plants.add(new LabelValue(p,p));
		}
		return plants;
	}

	@AuraEnabled(Cacheable=false)
	public static List<SMAX_PS_InventoryCount__c> filterInventory(InventoryCountFilter filter) {
		System.debug('filter:'+filter);
		List<SMAX_PS_InventoryCount__c> inventoryList=new List<SMAX_PS_InventoryCount__c>();

		String filterError=null;
		if((filter.selectedPlants!=null || filter.selectedTechnicians!=null))
		{
			String whereClause = '';
			List<String> statuses=filter.selectedStatuses;
			if(filter.selectedStatuses==null || filter.selectedStatuses.isEmpty()) {
				statuses.add('Submitted');
			}
			whereClause+=('SMAX_PS_Status__c IN :statuses');

			//List<String> whereClauses = new List<String>();
			//whereClauses.add('SMAX_PS_Status__c IN :filter.selectedStatuses ');

			Set<Id> technicianIds=new Set<Id>();
			Set<Id> locationIds=new Set<Id>();

			Set<String> plants= new Set<String>();
			if (filter.selectedPlants != null) {
				plants.addAll(filter.selectedPlants);
			}

			whereClause += ' AND (';
			System.debug('Selected Technicians/Locations: ' + filter.selectedTechnicians);
			if (filter.selectedTechnicians != null)
			{
				for (BD_CustomLookupService.LookupSearchResult searchResult : filter.selectedTechnicians)
				{
					if (searchResult.sObjectType == 'SVMXC__Service_Group_Members__c') {
						System.debug('TECHNICIAN for filter: ' + searchResult.id);
						technicianIds.add(searchResult.id);
					}
					if (searchResult.sObjectType == 'SVMXC__Site__c') {
						System.debug('LOCATION for filter: ' + searchResult.id);
						locationIds.add(searchResult.id);
					}
					if (searchResult.sObjectType == 'PLANT') {
						System.debug('PLANT for filter: ' + searchResult.id);
						plants.add(searchResult.id);
					}
				}
				if (!technicianIds.isEmpty()) {
					//whereClauses.add('SMAX_PS_RequestedTechnician__c IN :technicianIds');
					whereClause+=(' SMAX_PS_RequestedTechnician__c IN  :technicianIds OR');
				}
				if (!locationIds.isEmpty()) {
					//whereClauses.add('SMAX_PS_RequestedTechnician__r.SVMXC__Inventory_Location__c IN :locationIds ');
					// ITSVMX-392 Find Inv Counts without Technician
					//whereClause+=(' SMAX_PS_RequestedTechnician__r.SVMXC__Inventory_Location__c IN :locationIds OR');
					whereClause+=(' SMAX_PS_RequestedFrom__c IN :locationIds OR');
				}
			}

			if (plants != null && !plants.isEmpty()) {
				// ITSVMX-392 Find Inv Counts without Technician
				//whereClause+=(' SMAX_PS_RequestedTechnician__r.SMAX_PS_Plant__c IN :plants OR');
				whereClause+=(' SMAX_PS_Maintenance_Plant__c IN :plants OR');
			}
			whereClause = whereClause.removeEnd('OR') + ')';
			System.debug('whereclause: ' + whereClause);

			String fullQuery = 'SELECT Id, Name, SMAX_PS_Status__c, LastModifiedDate, ' +
					'SMAX_PS_RequestedTechnician__r.Name, ' +
					'SMAX_PS_Maintenance_Plant__c, SMAX_PS_RequestedFrom__c, ' +
					'SMAX_PS_RequestedFrom__r.SMAX_PS_LocationCode__c, SMAX_PS_RequestedFrom__r.Name, ' +
					// 8/6/20 tony - added new rollup fields for header lines
					'SMAX_PS_Booked_Qty_Total__c, SMAX_PS_Counted_Qty_Total__c, SMAX_PS_Entry_Qty_Total__c, SMAX_PS_Lines_Count__c, ' +
					'SMAX_PS_Is_Found_Item_True_Count__c, CurrencyIsoCode, SMAX_PS_Is_Found_Item_True_Qty__c, SMAX_PS_Difference_Value_Total__c ' +
//					'(Select Id, LastModifiedDate, Name, SMAX_PS_InvCnt_Status__c, ' +
//						'SMAX_PS_BookedQty__c, SMAX_PS_CountedQty__c, BD_Difference_In_Qty__c, SMAX_PS_InventoryCount__c, ' +
//						'SMAX_PS_Reason_for_Difference__c, SMAX_PS_SAP_Calcualted_Stock_Cost__c, '+
//						'SMAX_PS_Difference_in_Cost__c, SMAX_PS_Counted_Product_Cost__c, SMAX_PS_ProductCost__c, ' +
//						'SMAX_PS_Value_of_PhysicalInventoryCount__c, SMAX_PS_ValueofBookedQty__c, SMAX_PS_DifferenceValue__c, '+
//						'BD_Selected__c, SMAX_PS_Product__c, SMAX_PS_Product__r.Partnum__c, SMAX_PS_Product__r.Name, ' +
//						'SMAX_PS_Why_Recount_Needed__c, SMAX_PS_Found_Item__c, SMAX_PS_EntryQty__c FROM Inventory_Count_Lines__r) ' +
					'FROM SMAX_PS_InventoryCount__c WHERE '
					+ whereClause + ' ORDER BY ' +  'Name' + ' LIMIT 1000';

			inventoryList = Database.query(fullQuery);
			if (inventoryList.size() > 500) {
				filterError='Stock list update size limited to 500 records. Current Size: '+inventoryList.size()+'. Please apply additional filters.';
				inventoryList=new List<SMAX_PS_InventoryCount__c>();
				// ITSVMX-1327 Throw error to show to user in LWC
				throw new BD_Inventory_Count_Exception(filterError);
			}
		}

		// 8/6/20 tony - Added for the Summary of the Difference Values
		// Query the Lines and then iterate over them to update the inventoryList with the Difference values
		Set<Id> inventoryCountIds = new Set<Id>();
		Set<String> currencyCodes = new Set<String>();
		for (SMAX_PS_InventoryCount__c inventoryCount :inventoryList) {
			inventoryCountIds.add(inventoryCount.Id);
			currencyCodes.add(inventoryCount.CurrencyIsoCode);
		}

		Map<String, CurrencyType> currencyMap = new Map<String, CurrencyType>();
		for(CurrencyType cType : [SELECT IsoCode, ConversionRate
			FROM CurrencyType WHERE IsoCode IN :currencyCodes]) {
			currencyMap.put(cType.IsoCode, cType);
		}

		List<AggregateResult> aggregateResults = [
				SELECT SMAX_PS_InventoryCount__c, SUM(SMAX_PS_DifferenceValue__c) DifferenceSum
				FROM SMAX_PS_InventoryCountLine__c
				WHERE SMAX_PS_InventoryCount__c IN :inventoryCountIds
				GROUP BY SMAX_PS_InventoryCount__c
		];
		System.debug('inventoryCountLines with Difference Value: ' + aggregateResults);

		Map<Id, Decimal> inventoryCountIdToDifferenceValue = new Map<Id, Decimal>();
		for (AggregateResult aggregateResult :aggregateResults) {
			Id inventoryCountId = (Id) aggregateResult.get('SMAX_PS_InventoryCount__c');
			Decimal differenceSum = (Decimal) aggregateResult.get('DifferenceSum');
			inventoryCountIdToDifferenceValue.put(inventoryCountId, differenceSum);
		}
		System.debug('inventoryCountIdToDifferenceValue: ' + inventoryCountIdToDifferenceValue);

		List<SMAX_PS_InventoryCount__c> invToUpdate = new List<SMAX_PS_InventoryCount__c>();
		for (SMAX_PS_InventoryCount__c inventoryCount :inventoryList) {
			Decimal diffSum = inventoryCountIdToDifferenceValue.get(inventoryCount.Id);
			CurrencyType currencyType = currencyMap.get(inventoryCount.CurrencyIsoCode);
			if (diffSum != null && currencyType != null) {
				Decimal updatedValue = diffSum * currencyType.ConversionRate;
				// 20211116: FRANK - Do not update if the count is already 'Approved'
				if (updatedValue != inventoryCount.SMAX_PS_Difference_Value_Total__c
						&& inventoryCount.SMAX_PS_Status__c != 'Approved') {
					inventoryCount.SMAX_PS_Difference_Value_Total__c = updatedValue;
					invToUpdate.add(inventoryCount);
				}
			}
		}
		if (!invToUpdate.isEmpty()) {
			update invToUpdate;
		}

		System.debug('Inventory Counts found:' + inventoryList.size());
		return inventoryList;
	}

	@AuraEnabled(Cacheable=false)
	public static List<SMAX_PS_InventoryCountLine__c> getLines(Id inventoryCountId)
	{
		System.debug('Getting Lines for Inventory Count: ' + inventoryCountId);
		List<SMAX_PS_InventoryCountLine__c> result = [SELECT Id, LastModifiedDate, Name, SMAX_PS_InvCnt_Status__c,
				SMAX_PS_BookedQty__c, SMAX_PS_CountedQty__c, BD_Difference_In_Qty__c, SMAX_PS_InventoryCount__c,
				SMAX_PS_Reason_for_Difference__c, SMAX_PS_SAP_Calcualted_Stock_Cost__c,
				SMAX_PS_Difference_in_Cost__c, SMAX_PS_Counted_Product_Cost__c, SMAX_PS_ProductCost__c,
				SMAX_PS_Value_of_PhysicalInventoryCount__c, SMAX_PS_ValueofBookedQty__c, SMAX_PS_DifferenceValue__c,
				BD_Selected__c, SMAX_PS_Product__c, SMAX_PS_Product__r.Partnum__c, SMAX_PS_Product__r.Name,
				SMAX_PS_Why_Recount_Needed__c, SMAX_PS_Found_Item__c, SMAX_PS_EntryQty__c, CurrencyIsoCode
			FROM SMAX_PS_InventoryCountLine__c WHERE SMAX_PS_InventoryCount__c = :inventoryCountId];
		return result;
	}

	@AuraEnabled(Cacheable=false)
	public static String updateInventory(InventoryUpdateList iList)
	{
		System.debug('updateInventory method');
		Set<Id> lineIds=new Set<Id>();
		for(String st : iList.selectedLines){
			lineIds.add(Id.valueOf(st));
		}

		List<SMAX_PS_InventoryCountLine__c> lines = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
				BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c,SMAX_PS_InventoryCount__c,
			    SMAX_PS_InventoryCount__r.Owner.Name FROM SMAX_PS_InventoryCountLine__c WHERE Id IN :lineIds];
		List<SMAX_PS_InventoryCountLine__c> updates = new List<SMAX_PS_InventoryCountLine__c>();
        // added by Pankaj, 21 jan 26
        Set<SMAX_PS_InventoryCount__c> invCountObjSet = new Set<SMAX_PS_InventoryCount__c>();
		for (SMAX_PS_InventoryCountLine__c i : lines)
		{
			if (i.SMAX_PS_InvCnt_Status__c == 'Submitted')
			{
				i.SMAX_PS_InvCnt_Status__c = iList.selectedReviewStatus;
				if (iList.selectedReviewStatus == 'Confirmed') {
					i.BD_Confirmed_Date__c = Datetime.now();
					i.BD_Confirmed_By__c = UserInfo.getName();
				}
				else if (iList.selectedReviewStatus == 'Recount') {
					i.BD_Recount_Requested_Date__c = Datetime.now();
					i.BD_Recount_Requested_By__c = UserInfo.getName();
					i.SMAX_PS_Why_Recount_Needed__c = iList.selectedRejectReason;
                    // added by Pankaj, 21 jan 26
                    invCountObjSet.add(new SMAX_PS_InventoryCount__c(Id=i.SMAX_PS_InventoryCount__c,SMAX_PS_Status__c='Recount Required'));
				}
				System.debug('inv count owner:' + i.SMAX_PS_InventoryCount__r.Owner.Name);
                updates.add(i);
			}
			else if (i.SMAX_PS_InvCnt_Status__c == 'Confirmed')
			{
				i.SMAX_PS_InvCnt_Status__c = iList.selectedReviewStatus;
				if (iList.selectedReviewStatus == 'Approved') {
					i.BD_Approved_Date__c = Datetime.now();
					i.BD_Approved_By__c = UserInfo.getName();
				}
                System.debug('inv count owner:' + i.SMAX_PS_InventoryCount__r.ownerId);
				updates.add(i);
			}
		}

		String result=null;
		if (updates.isEmpty()) {
			result = 'No lines to update found';
		} else {
			try {
				update updates;
				result= updates.size()+ ' records updated.';
			} catch (Exception e) {
				result= 'Error while trying to update lines: ' + e;
			}
		}
        // added by Pankaj, 21 jan 26
		if(!invCountObjSet.isEmpty()){
            update new List<SMAX_PS_InventoryCount__c>(invCountObjSet);
        }
		System.debug('result '+result);
		return result;
	}

	// 8/17/20 tony - Added to allow Inventory Counts Lines to be updated when a Header is checked
	@AuraEnabled(Cacheable=false)
	public static String updateInventoryFromHeader(InventoryHeaderUpdateData headerData)
	{
		System.debug('updateInventoryFromHeader method');
		Id headerId = Id.valueOf(headerData.selectedHeaderLine);

		List<SMAX_PS_InventoryCountLine__c> lines = [SELECT Id, SMAX_PS_InvCnt_Status__c, SMAX_PS_Why_Recount_Needed__c,
				BD_Confirmed_Date__c, BD_Confirmed_By__c, BD_Recount_Requested_Date__c, BD_Recount_Requested_By__c,SMAX_PS_InventoryCount__c
		        FROM SMAX_PS_InventoryCountLine__c WHERE SMAX_PS_InventoryCount__c = :headerId];
		List<SMAX_PS_InventoryCountLine__c> updates = new List<SMAX_PS_InventoryCountLine__c>();
        // added by Pankaj, 21 jan 26
        Set<SMAX_PS_InventoryCount__c> invCountObjSet = new Set<SMAX_PS_InventoryCount__c>();
		for (SMAX_PS_InventoryCountLine__c i : lines)
		{
			if (i.SMAX_PS_InvCnt_Status__c == 'Submitted')
			{
				i.SMAX_PS_InvCnt_Status__c = headerData.selectedReviewStatus;
				if (headerData.selectedReviewStatus == 'Confirmed') {
					i.BD_Confirmed_Date__c = Datetime.now();
					i.BD_Confirmed_By__c = UserInfo.getName();
				}
				else if (headerData.selectedReviewStatus == 'Recount') {
					i.BD_Recount_Requested_Date__c = Datetime.now();
					i.BD_Recount_Requested_By__c = UserInfo.getName();
					i.SMAX_PS_Why_Recount_Needed__c = headerData.selectedRejectReason;
                    // added by Pankaj, 21 jan 26
                    invCountObjSet.add(new SMAX_PS_InventoryCount__c(Id=i.SMAX_PS_InventoryCount__c,SMAX_PS_Status__c='Recount Required'));
				}
				updates.add(i);
			}
			else if (i.SMAX_PS_InvCnt_Status__c == 'Confirmed')
			{
				i.SMAX_PS_InvCnt_Status__c = headerData.selectedReviewStatus;
				if (headerData.selectedReviewStatus == 'Approved') {
					i.BD_Approved_Date__c = Datetime.now();
					i.BD_Approved_By__c = UserInfo.getName();
				}
				updates.add(i);
			}
		}

		String result=null;
		if (updates.isEmpty()) {
			result = 'No lines to update found for headers';
		} else {
			try {
				update updates;
				result= updates.size()+ ' records updated.';
			} catch (Exception e) {
				result= 'Error while trying to update lines: ' + e;
			}
		}
		// added by Pankaj, 21 jan 26
		if(!invCountObjSet.isEmpty()){
            update new List<SMAX_PS_InventoryCount__c>(invCountObjSet);
        }
		System.debug('result '+result);
		return result;
	}

}
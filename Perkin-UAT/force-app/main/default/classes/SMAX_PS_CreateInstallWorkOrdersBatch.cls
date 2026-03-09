/* 
 *  Schedulable Batch class for Creating Install Work Orders
 *  2017-11-14      Veerendra Moodbidri     Initial creation.
 *  2018-05-01		Frank VanLoon			Changes for SVMXINT-518: External ID Fields, Status, Error Message
 *  2018-06-18		Frank VanLoon			Updated for Phase 1.0: SVMXCFG-605
*/
global class SMAX_PS_CreateInstallWorkOrdersBatch implements Database.Batchable<sobject> , Schedulable {

	private static Map<String, String> ORDER_TYPE_MAP = new Map<String, String> { 'PIV' => 'Pre Install Visit', 'PHONE' => 'Phone', 'INSTALLATION' => 'Installation' };

	global Set<String> SALES_ORGS;

	public SMAX_PS_CreateInstallWorkOrdersBatch(Set<String> salesOrgs)
	{
		this.SALES_ORGS = salesOrgs;
	}

	/** 
		Schedulable methods 
	**/

	global void execute(SchedulableContext sc) {
		SMAX_PS_CreateInstallWorkOrdersBatch cInstallWObatch = new SMAX_PS_CreateInstallWorkOrdersBatch(this.SALES_ORGS);
		database.executeBatch(cInstallWObatch, 1);
	}
	   
	/** 
		Batchable methods 
	**/

	global Database.QueryLocator start(Database.BatchableContext BC) {

		// ITSVMX-1467 Configurable SAP Outages
		if (SMAX_PS_CreateScheduledWorkOrdersBatch.isSAPOutage()) {
			return Database.getQueryLocator([SELECT Id FROM SMAX_PS_Install_Request__c LIMIT 0]);
		}

		return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_Status__c,
			SMAX_PS_InstallType__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c, 
			SMAX_PS_InstalledProduct__c, SMAX_PS_SalesOrderNumber__c, SMAX_PS_SalesOrderLineNumber__c, 
			SMAX_PS_Contact__c, SMAX_PS_ContactName__c, SMAX_PS_ContactPhone__c, SMAX_PS_ContactEmail__c,
			SMAX_PS_TechnicianAccount__c, SMAX_PS_ProductSeries__c, SMAX_PS_SalesOrderLinesDescription__c,
			SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_ShipTo__c,
			SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_BillTo__c, 
			SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_Payer__c,
			SMAX_PS_Account_ExtId__c, SMAX_PS_Contact_ExtId__c, SMAX_PS_InstalledProduct_ExtId__c, 
			SMAX_PS_Location_ExtId__c, SMAX_PS_Product_ExtId__c 
		FROM SMAX_PS_Install_Request__c WHERE SMAX_PS_WorkOrder__c = null
			AND SMAX_PS_Status__c != 'Canceled']);
	}

	global void execute(Database.BatchableContext BC, List<SMAX_PS_Install_Request__c> irList) 
	{
		// First pass.. collect external ids to related objects
		Set<String> acctExtIds = new Set<String>();
		Set<String> contactExtIds = new Set<String>();
		Set<String> ipExtIds = new Set<String>();
		Set<String> locExtIds = new Set<String>();
		Set<Id> locIds = new Set<Id>();
		Set<String> productExtIds = new Set<String>();
		Set<Id> ipIds = new Set<Id>();
		for (SMAX_PS_Install_Request__c ir : irList) {
			if (ir.SMAX_PS_Account__c == null && String.isNotBlank(ir.SMAX_PS_Account_ExtId__c)) {
				acctExtIds.add(ir.SMAX_PS_Account_ExtId__c);
			}
			if (ir.SMAX_PS_Contact__c == null && String.isNotBlank(ir.SMAX_PS_Contact_ExtId__c)) {
				contactExtIds.add(ir.SMAX_PS_Contact_ExtId__c);
			}
			if (ir.SMAX_PS_InstalledProduct__c == null && String.isNotBlank(ir.SMAX_PS_InstalledProduct_ExtId__c)) {
				ipExtIds.add(ir.SMAX_PS_InstalledProduct_ExtId__c);
			}
			if (ir.SMAX_PS_Location__c == null && String.isNotBlank(ir.SMAX_PS_Location_ExtId__c)) {
				locExtIds.add(ir.SMAX_PS_Location_ExtId__c);
			}
			if (ir.SMAX_PS_Location__c != null) {
				locIds.add(ir.SMAX_PS_Location__c);
			}
			if (ir.SMAX_PS_Product__c == null && String.isNotBlank(ir.SMAX_PS_Product_ExtId__c)) {
				productExtIds.add(ir.SMAX_PS_Product_ExtId__c);
			}
			if (ir.SMAX_PS_InstalledProduct__c != null) {
				ipIds.add(ir.SMAX_PS_InstalledProduct__c);
			}
		}

		// Lookup related records using their external ids
		Map<String, Account> acctMap = new Map<String, Account>();
		if (!acctExtIds.isEmpty())
		{
			//System.debug('~~~ LOOKUP Accounts: ' + acctExtIds);
			List<Account> acctList = [SELECT Id, Name, PKI_SAP_Customer_Number__c FROM Account WHERE PKI_SAP_Customer_Number__c IN :acctExtIds];
			for (Account acct : acctList)
			{
				acctMap.put(acct.PKI_SAP_Customer_Number__c, acct);
				//System.debug('~~~ FOUND Account: ' + acct);
			}
		}

		Map<String, Contact> contactMap = new Map<String, Contact>();
		if (!contactExtIds.isEmpty())
		{
			// ITSVMX-1542 Do not assign to Contact with "PKI SAP Marked for Deletion" flag
			for (Contact c : [SELECT Id, Name, PKI_SAP_Contact_ID__c FROM Contact
				WHERE PKI_SAP_Contact_ID__c IN :contactExtIds AND PKI_SAP_Marked_for_Deletion__c = FALSE])
			{
				contactMap.put(c.PKI_SAP_Contact_ID__c, c);
			}
		}

		Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
		Map<Id, SVMXC__Installed_Product__c> ipIdMap = new Map<Id, SVMXC__Installed_Product__c>();
		if (!ipExtIds.isEmpty())
		{
			for (SVMXC__Installed_Product__c ip : [SELECT Id, Name, SVMX_PS_External_ID__c, SMAX_PS_Technical_ID_Number__c, SMAX_PS_Building__c, SMAX_PS_Room__c 
					FROM SVMXC__Installed_Product__c WHERE SVMX_PS_External_ID__c IN :ipExtIds])
			{
				ipMap.put(ip.SVMX_PS_External_ID__c, ip);
				ipIdMap.put(ip.Id, ip);
			}
		}
		if (!ipIds.isEmpty())
		{
			for (SVMXC__Installed_Product__c ip : [SELECT Id, Name, SVMX_PS_External_ID__c, SMAX_PS_Technical_ID_Number__c, SMAX_PS_Building__c, SMAX_PS_Room__c 
					FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds])
			{
				ipIdMap.put(ip.Id, ip);
			}
		}

		// SVMXCFG-605: Batch Jobs - i18n Parameters
		Map<Id, String> locSalesOrgMap = new Map<Id, String>();

		Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
		if (!locExtIds.isEmpty())
		{
			for (SVMXC__Site__c loc : [SELECT Id, Name, SVMX_PS_External_ID__c, SMAX_PS_SalesOrg__c FROM SVMXC__Site__c WHERE SVMX_PS_External_ID__c IN :locExtIds])
			{
				locMap.put(loc.SVMX_PS_External_ID__c, loc);
				locSalesOrgMap.put(loc.Id, loc.SMAX_PS_SalesOrg__c);
			}
		}

		if (!locIds.isEmpty())
		{
			for (SVMXC__Site__c loc : [SELECT Id, Name, SMAX_PS_SalesOrg__c FROM SVMXC__Site__c WHERE Id IN :locIds])
			{
				locSalesOrgMap.put(loc.Id, loc.SMAX_PS_SalesOrg__c);
			}
		}

		Map<String, Product2> productMap = new Map<String, Product2>();
		if (!productExtIds.isEmpty())
		{
			for (Product2 prdct : [SELECT Id, Name, Partnum__c FROM Product2 WHERE Partnum__c IN :productExtIds])
			{
				productMap.put(prdct.Partnum__c, prdct);
			}
		}

		RecordType fieldServiceRT = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__Service_Order__c').get('Field_Service');
		List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
		List<SMAX_PS_Install_Request__c> irWoList = new List<SMAX_PS_Install_Request__c>();
		for (SMAX_PS_Install_Request__c ir : irList) {
			// Assign Lookups... 
			List<String> missingLookups = new List<String>();
			if (ir.SMAX_PS_Account__c == null && String.isNotBlank(ir.SMAX_PS_Account_ExtId__c)) {
				Account acct = acctMap.get(ir.SMAX_PS_Account_ExtId__c);
				//System.debug('~~~ UPDATING Account: ' + acct);
				if (acct != null)
					ir.SMAX_PS_Account__c = acct.Id;
				else
					missingLookups.add('Account not found: ' + ir.SMAX_PS_Account_ExtId__c);
			}
			if (ir.SMAX_PS_Contact__c == null && String.isNotBlank(ir.SMAX_PS_Contact_ExtId__c)) {
				Contact cntct = contactMap.get(ir.SMAX_PS_Contact_ExtId__c);
				if (cntct != null)
					ir.SMAX_PS_Contact__c = cntct.Id;
				else
					missingLookups.add('Contact not found: ' + ir.SMAX_PS_Contact_ExtId__c);
			}
			if (ir.SMAX_PS_InstalledProduct__c == null && String.isNotBlank(ir.SMAX_PS_InstalledProduct_ExtId__c)) {
				SVMXC__Installed_Product__c ip = ipMap.get(ir.SMAX_PS_InstalledProduct_ExtId__c);
				if (ip != null)
					ir.SMAX_PS_InstalledProduct__c = ip.Id;
				else
					missingLookups.add('Installed Product not found: ' + ir.SMAX_PS_InstalledProduct_ExtId__c);
			}
			if (ir.SMAX_PS_Location__c == null && String.isNotBlank(ir.SMAX_PS_Location_ExtId__c)) {
				SVMXC__Site__c loc = locMap.get(ir.SMAX_PS_Location_ExtId__c);
				if (loc != null)
					ir.SMAX_PS_Location__c = loc.Id;
				else
					missingLookups.add('Location not found: ' + ir.SMAX_PS_Location_ExtId__c);
			}
			if (ir.SMAX_PS_Product__c == null && String.isNotBlank(ir.SMAX_PS_Product_ExtId__c)) {
				Product2 prdct = productMap.get(ir.SMAX_PS_Product_ExtId__c);
				if (prdct != null)
					ir.SMAX_PS_Product__c = prdct.Id;
				else
					missingLookups.add('Product not found: ' + ir.SMAX_PS_Product_ExtId__c);
			}

			// If any Lookups are missing, put On-Hold and skip
			if (!missingLookups.isEmpty()) {
				ir.SMAX_PS_Status__c = 'On-Hold';
				ir.SMAX_PS_Error_Message__c = 'On-Hold due to missing lookup data: ' + missingLookups;
				continue;
			}

			// SVMXCFG-605: Batch Jobs - i18n Parameters
			if (this.SALES_ORGS != null && !this.SALES_ORGS.isEmpty())
			{
				String salesOrg = locSalesOrgMap.get(ir.SMAX_PS_Location__c);
				if (String.isBlank(salesOrg))
				{
					ir.SMAX_PS_Status__c = 'On-Hold';
					ir.SMAX_PS_Error_Message__c = 'On-Hold because unable to determine SalesOrg of Location: ' + ir.SMAX_PS_Location__c;
					continue;
				}
				else if (!this.SALES_ORGS.contains(salesOrg))
				{
					// ITSVMX-1278 Do not set to On-Hold, but don't process the WO either since it's not correct Sales Org
//					ir.SMAX_PS_Status__c = 'On-Hold';
					ir.SMAX_PS_Error_Message__c = 'Skipping due to SalesOrg: ' + salesOrg + ' ... not included in configured SalesOrg list: ' + this.SALES_ORGS;
					continue;
				}
			}

			SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
			wo.RecordTypeId = fieldServiceRT.Id;
			wo.SVMXC__Order_Status__c = 'Initializing';
			wo.SVMXC__Billing_Type__c = 'Installation';
			wo.SVMXC__Order_Type__c = ORDER_TYPE_MAP.get(ir.SMAX_PS_InstallType__c);
			wo.SVMXC__Company__c = ir.SMAX_PS_Account__c;
			wo.SVMXC__Site__c = ir.SMAX_PS_Location__c;
			wo.SVMXC__Product__c = ir.SMAX_PS_Product__c;
			wo.SVMXC__Component__c = ir.SMAX_PS_InstalledProduct__c;
			wo.SMAX_PS_SalesOrderNumber__c = ir.SMAX_PS_SalesOrderNumber__c;
			wo.SMAX_PS_SalesOrderLineNumber__c = ir.SMAX_PS_SalesOrderLineNumber__c;
			wo.SVMXC__Contact__c = ir.SMAX_PS_Contact__c;
			wo.SMAX_PS_ContactName__c = ir.SMAX_PS_ContactName__c;
			wo.SVMX_PS_Contact_Phone__c = ir.SMAX_PS_ContactPhone__c;
			wo.SVMX_PS_Contact_Email__c = ir.SMAX_PS_ContactEmail__c;
			//wo.SVMXC__Group_Member__c = ir.SMAX_PS_TechnicianAccount__c;
			wo.SMAX_PS_ProductSeries__c = ir.SMAX_PS_ProductSeries__c;
			wo.SVMXC__Special_Instructions__c = ir.SMAX_PS_SalesOrderLinesDescription__c;
			wo.SVMXC__Perform_Auto_Entitlement__c = FALSE;
			wo.SMAX_PS_Perform_Auto_Assignment__c = FALSE; //(ir.SMAX_PS_InstallType__c != 'PIV')
			wo.SMAX_PS_ShipTo__c = ir.SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_ShipTo__c;
			wo.SMAX_PS_BillTo__c = ir.SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_BillTo__c;
			wo.SMAX_PS_Payer__c = ir.SMAX_PS_InstalledProduct__r.SVMXC__Site__r.SMAX_PS_Payer__c;
			//wo.SVMXC__Skill__c = ??
			wo.SVMXC__Scheduled_Date__c = Date.today();

			// SVMXCFG-523: Problem Summary: MM/YYYY-Maintenance Activity Type-Technical ID-Building-Room
			Datetime entDate = Datetime.newInstance(wo.SVMXC__Scheduled_Date__c, Time.newInstance(0, 0, 0, 0));
			String ps = entDate.format('MM/yyyy') + '-' + ir.SMAX_PS_InstallType__c;

			SVMXC__Installed_Product__c ip = (ir.SMAX_PS_InstalledProduct__c == null) ? null : ipIdMap.get(ir.SMAX_PS_InstalledProduct__c);
			if (ip != null) {
				if (String.isNotBlank(ip.SMAX_PS_Technical_ID_Number__c))
					ps += '-' + ip.SMAX_PS_Technical_ID_Number__c;
				if (String.isNotBlank(ip.SMAX_PS_Building__c))
					ps += '-' + ip.SMAX_PS_Building__c;
				if (String.isNotBlank(ip.SMAX_PS_Room__c))
					ps += '-' + ip.SMAX_PS_Room__c;
			}

			wo.SVMXC__Problem_Description__c = ps;
			wo.SVMX_PS_Problem_Summary__c = (ps.length() > 40) ? ps.substring(0, 37) + '...' : ps;

			woList.add(wo);
			irWoList.add(ir);
		}

		List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		if (!woList.isEmpty())
		{
			Database.SaveResult[] results = Database.insert(woList, false);
			for (Integer i = 0; i < results.size(); i++)
			{
				Database.SaveResult result = results[i];
				SMAX_PS_Install_Request__c ir = irWoList[i];
				SVMXC__Service_Order__c wo = woList[i];
				if (!result.isSuccess())
				{
					String errorMsg = 'Error inserting Work Order for Install Request: ' + ir.Name + ' - ' + result.getErrors();
					System.debug(errorMsg);
					logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_CreateInstallWorkOrdersBatch', null, ir.Id));
					ir.SMAX_PS_Status__c = 'Error';
					ir.SMAX_PS_Error_Message__c = errorMsg;
				}
				else
				{
					System.debug('Success creating Install Request Work Order: ' + wo.Id);
					ir.SMAX_PS_Status__c = 'Success';
					ir.SMAX_PS_WorkOrder__c = wo.Id;
					ir.SMAX_PS_Error_Message__c = null;
				}
			}
		}

		update irList;

		if (!logs.isEmpty())
			insert logs;
	}
	
	global void finish(Database.BatchableContext BC) {
	}      

	/*Public static void SchedulerMethod() {
	 // Run a Schedulable class once i.e. after 2 minutes
	String hour = String.valueOf(Datetime.now().hour());
	String min = String.valueOf(Datetime.now().minute() + 2); 
	String ss = String.valueOf(Datetime.now().second());
	//parse to cron expression
	String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
	SMAX_PS_CreateInstallWorkOrdersBatch cWObatch = new SMAX_PS_CreateInstallWorkOrdersBatch(); 
	System.schedule('Create Install Work Orders - Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, cWObatch);
	}*/
}
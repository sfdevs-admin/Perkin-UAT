/**
 * Created by frankvanloon on 2019-02-18.
 */
@isTest
private class SMAX_PS_WorkOrder_LocalLangFixBatch_UT
{
	static testMethod void copyFromLocation()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
		Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
		pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
		update pd;

		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		loc.SMAX_PS_SalesOrg__c = 'TT10';
		update loc;

		SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

		Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
		Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

		// Insert Work Order
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		wo.SVMX_PS_External_ID__c = 'SO001991992';
		wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
		update wo;

		// SVMXCFG-903 Copy Local Language Accounts to WO
		loc.SMAX_PS_LL_BillToExtID__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
		loc.SMAX_PS_LL_ShipToExtID__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
		update loc;

		Test.startTest();

		SMAX_PS_WorkOrder_LocalLangFixBatch b = new SMAX_PS_WorkOrder_LocalLangFixBatch(new List<String> { 'TT10' }, 1);
		Database.executeBatch(b);

		Test.stopTest();

		SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c,
			SMAX_PS_Local_Language_Ship_To_Account__c, SMAX_PS_Local_Language_Bill_To_Account__c
			FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertNotEquals(null, result.SMAX_PS_Local_Language_Ship_To_Account__c);
		System.assertNotEquals(null, result.SMAX_PS_Local_Language_Ship_To_Account__c);
	}

	static testMethod void copyFromIP()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
		Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
		pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
		update pd;

		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		loc.SMAX_PS_SalesOrg__c = 'TT10';
		update loc;

		SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

		Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
		Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

		// Insert Work Order
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		wo.SVMX_PS_External_ID__c = 'SO001991992';
		wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
		update wo;

		// SVMXCFG-903 Copy Local Language Accounts to WO
		ip.SMAX_PS_LL_BillTo_ExtId__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
		ip.SMAX_PS_LL_ShipTo_ExtId__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
		update ip;

		Test.startTest();

		SMAX_PS_WorkOrder_LocalLangFixBatch b = new SMAX_PS_WorkOrder_LocalLangFixBatch(new List<String> { 'TT10' }, 1);
		Database.executeBatch(b);

		Test.stopTest();

		SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c,
				SMAX_PS_Local_Language_Ship_To_Account__c, SMAX_PS_Local_Language_Bill_To_Account__c
		FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertNotEquals(null, result.SMAX_PS_Local_Language_Ship_To_Account__c);
		System.assertNotEquals(null, result.SMAX_PS_Local_Language_Ship_To_Account__c);
	}
}
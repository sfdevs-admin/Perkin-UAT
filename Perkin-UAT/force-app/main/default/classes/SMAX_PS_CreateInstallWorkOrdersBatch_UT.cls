@isTest
public class SMAX_PS_CreateInstallWorkOrdersBatch_UT {
	
	public static testmethod void testSuccessBatch(){
		
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTXYZ0000001','GB');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','TST');
		pd.Partnum__c = pd.ProductCode;
		update pd;
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', 'TESTXYZ121212','LOC123');
		loc.SMAX_PS_SalesOrg__c = 'TST2';
		update loc;
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		ip.SVMX_PS_External_ID__c = 'TESTXYZ00001I';
		update ip;

		SMAX_PS_Install_Request__c ir = new SMAX_PS_Install_Request__c();
		ir.SMAX_PS_Account_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		ir.SMAX_PS_Contact_ExtId__c = cont.PKI_SAP_Contact_ID__c;
		ir.SMAX_PS_InstalledProduct_ExtId__c = ip.SVMX_PS_External_ID__c;
		ir.SMAX_PS_Location_ExtId__c = loc.SVMX_PS_External_ID__c;
		ir.SMAX_PS_Product_ExtId__c = pd.Partnum__c;
		ir.SMAX_PS_InstallType__c = 'INSTALLATION';
		ir.SMAX_PS_SalesOrderNumber__c = 'SOXYZ10010';
		ir.SMAX_PS_SalesOrderLineNumber__c = '0012';
		ir.SMAX_PS_External_Id__c = ir.SMAX_PS_SalesOrderNumber__c + '-' + ir.SMAX_PS_SalesOrderLineNumber__c + '-' + ir.SMAX_PS_InstalledProduct_ExtId__c;

		insert ir;

		Test.startTest(); 
		
		SMAX_PS_CreateInstallWorkOrdersBatch obj = new SMAX_PS_CreateInstallWorkOrdersBatch(new Set<String> { 'TST2' });
		Database.executeBatch(obj);
		
		Test.stopTest();

		SMAX_PS_Install_Request__c result = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c, 
			SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir.Id];
		System.debug('RESULT InstallRequest (Success): ' + result);
		System.assertEquals(acct.Id, result.SMAX_PS_Account__c);
		System.assertEquals(loc.Id, result.SMAX_PS_Location__c);
		System.assertEquals(pd.Id, result.SMAX_PS_Product__c);
		System.assertEquals(ip.Id, result.SMAX_PS_InstalledProduct__c);
		System.assertEquals(cont.Id, result.SMAX_PS_Contact__c);
		System.assertEquals('Success', result.SMAX_PS_Status__c);
	}


	public static testmethod void testOnHoldBatch(){
		
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTXYZ0000001','GB');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','TST');
		pd.Partnum__c = pd.ProductCode;
		update pd;
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', 'TESTXYZ121212','LOC123');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		ip.SVMX_PS_External_ID__c = 'TESTXYZ00001I';
		update ip;

		SMAX_PS_Install_Request__c ir = new SMAX_PS_Install_Request__c();
		ir.SMAX_PS_Account_ExtId__c = acct.PKI_SAP_Customer_Number__c + '??';
		ir.SMAX_PS_Contact_ExtId__c = cont.PKI_SAP_Contact_ID__c + '??';
		ir.SMAX_PS_InstalledProduct_ExtId__c = ip.SVMX_PS_External_ID__c + '??';
		ir.SMAX_PS_Location_ExtId__c = loc.SVMX_PS_External_ID__c + '??';
		ir.SMAX_PS_Product_ExtId__c = pd.Partnum__c + '??';
		ir.SMAX_PS_InstallType__c = 'INSTALLATION';
		ir.SMAX_PS_SalesOrderNumber__c = 'SOXYZ10010';
		ir.SMAX_PS_SalesOrderLineNumber__c = '0012';
		ir.SMAX_PS_External_Id__c = ir.SMAX_PS_SalesOrderNumber__c + '-' + ir.SMAX_PS_SalesOrderLineNumber__c + '-' + ir.SMAX_PS_InstalledProduct_ExtId__c;

		insert ir;

		Test.startTest(); 
		
		SMAX_PS_CreateInstallWorkOrdersBatch obj = new SMAX_PS_CreateInstallWorkOrdersBatch(null);
		Database.executeBatch(obj);
		
		Test.stopTest();

		SMAX_PS_Install_Request__c result = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c, 
			SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir.Id];
		System.debug('RESULT InstallRequest (On-Hold): ' + result);
		System.assertEquals(null, result.SMAX_PS_Account__c);
		System.assertEquals(null, result.SMAX_PS_Location__c);
		System.assertEquals(null, result.SMAX_PS_Product__c);
		System.assertEquals(null, result.SMAX_PS_InstalledProduct__c);
		System.assertEquals(null, result.SMAX_PS_Contact__c);
		System.assertEquals('On-Hold', result.SMAX_PS_Status__c);
	}

	public static testmethod void testSalesOrgBatch(){
		
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTXYZ0000001','GB');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','TST');
		pd.Partnum__c = pd.ProductCode;
		update pd;

		SVMXC__Site__c loc1 = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite1', 'TESTXYZ121111','LOC1_1');
		SVMXC__Site__c loc2 = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite2', 'TESTXYZ122222','LOC1_2');
		loc1.SMAX_PS_SalesOrg__c = 'TST1';
		loc2.SMAX_PS_SalesOrg__c = 'TST2';
		update new List<SVMXC__Site__c> { loc1, loc2 };

		SVMXC__Installed_Product__c ip1 = SMAX_PS_TestDataFactory.createIP('123456-1',acct,loc1,'5545333',pd);
		ip1.SVMX_PS_External_ID__c = 'TESTXYZ00001I';
		SVMXC__Installed_Product__c ip2 = SMAX_PS_TestDataFactory.createIP('123456-2',acct,loc2,'5545333',pd);
		ip2.SVMX_PS_External_ID__c = 'TESTXYZ00002I';
		update new List<SVMXC__Installed_Product__c> { ip1, ip2 };

		SMAX_PS_Install_Request__c ir1 = new SMAX_PS_Install_Request__c();
		ir1.SMAX_PS_Account_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		ir1.SMAX_PS_Contact_ExtId__c = cont.PKI_SAP_Contact_ID__c;
		ir1.SMAX_PS_InstalledProduct_ExtId__c = ip1.SVMX_PS_External_ID__c;
		ir1.SMAX_PS_Location_ExtId__c = loc1.SVMX_PS_External_ID__c;
		ir1.SMAX_PS_Product_ExtId__c = pd.Partnum__c;
		ir1.SMAX_PS_InstallType__c = 'INSTALLATION';
		ir1.SMAX_PS_SalesOrderNumber__c = 'SOXYZ10010';
		ir1.SMAX_PS_SalesOrderLineNumber__c = '0012';
		ir1.SMAX_PS_External_Id__c = ir1.SMAX_PS_SalesOrderNumber__c + '-' + ir1.SMAX_PS_SalesOrderLineNumber__c + '-' + ir1.SMAX_PS_InstalledProduct_ExtId__c;

		SMAX_PS_Install_Request__c ir2 = new SMAX_PS_Install_Request__c();
		ir2.SMAX_PS_Account_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		ir2.SMAX_PS_Contact_ExtId__c = cont.PKI_SAP_Contact_ID__c;
		ir2.SMAX_PS_InstalledProduct_ExtId__c = ip2.SVMX_PS_External_ID__c;
		ir2.SMAX_PS_Location_ExtId__c = loc2.SVMX_PS_External_ID__c;
		ir2.SMAX_PS_Product_ExtId__c = pd.Partnum__c;
		ir2.SMAX_PS_InstallType__c = 'INSTALLATION';
		ir2.SMAX_PS_SalesOrderNumber__c = 'SOXYZ10010';
		ir2.SMAX_PS_SalesOrderLineNumber__c = '0012';
		ir2.SMAX_PS_External_Id__c = ir2.SMAX_PS_SalesOrderNumber__c + '-' + ir2.SMAX_PS_SalesOrderLineNumber__c + '-' + ir2.SMAX_PS_InstalledProduct_ExtId__c;

		insert new List<SMAX_PS_Install_Request__c> { ir1, ir2 };

		Test.startTest(); 
		
		SMAX_PS_CreateInstallWorkOrdersBatch obj = new SMAX_PS_CreateInstallWorkOrdersBatch(new Set<String> { 'TST2' });
		Database.executeBatch(obj);
		
		Test.stopTest();

		SMAX_PS_Install_Request__c result1 = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c, 
			SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c, SMAX_PS_Error_Message__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir1.Id];
		System.debug('RESULT InstallRequest (SalesOrg On-Hold): ' + result1);
		System.assertNotEquals(null, result1.SMAX_PS_Location__c);
		// ITSVMX-1278 Do not set to On-Hold
		//System.assertEquals('On-Hold', result1.SMAX_PS_Status__c);
		System.assert(result1.SMAX_PS_Error_Message__c.contains('SalesOrg'));

		SMAX_PS_Install_Request__c result2 = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c, 
			SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c, SMAX_PS_Error_Message__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir2.Id];
		System.debug('RESULT InstallRequest (SalesOrg Success): ' + result2);
		System.assertNotEquals(null, result2.SMAX_PS_Location__c);
		System.assertEquals('Success', result2.SMAX_PS_Status__c);
	}
}
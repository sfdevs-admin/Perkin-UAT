/*
	Test Class for  SMAX_PS_InstalledProductManager
	Client      :   PerkinElmer
	Created by  :   Veerendra on 2017-08-14
*/
@isTest(seeAllData=false)
public class SMAX_PS_InstalledProduct_UT
{         
	static testMethod void createTestData()
	{       
		// Insert location
		SVMXC__Site__c loc = new SVMXC__Site__c(
							Name='Test Location',
							SVMXC__Street__c='123 street',
							SVMXC__City__c='This City',
							SVMXC__State__c='FL',
							SVMXC__Zip__c='12345',
							SVMXC__Country__c='United States');
		insert loc;

		SVMXC__Site__c loc2 = new SVMXC__Site__c(
							Name='Test Alt Location',
							SVMXC__Street__c='987 street',
							SVMXC__City__c='That City',
							SVMXC__State__c='CT',
							SVMXC__Zip__c='98765',
							SVMXC__Country__c='United States');
		insert loc2;

		// Insert Product
		Product2 prod = new Product2(
							Name='Test Product');
		insert prod;

		// Insert Installed Product
		SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(
							Name='Test Product',
							SVMXC__Product__c=prod.id,
							SVMXC__Site__c=loc.id);
		insert ip;

		SVMXC__Installed_Product__c result = [SELECT Id, Name, SVMXC__City__c FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
		System.assertEquals(loc.SVMXC__City__c, result.SVMXC__City__c);

		// insert IP classification
		SMAX_PS_InstalledProductClassification__c ipClass = new SMAX_PS_InstalledProductClassification__c(
							SMAX_PS_InstalledProduct__c=ip.Id
							);
		insert ipClass;

		ip.SMAX_PS_CompletedTxnNum__c='ABC';
		ip.SVMXC__Site__c = loc2.Id;
		update ip;

		SVMXC__Installed_Product__c updated = [SELECT Id, Name, SVMXC__City__c FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
		System.assertEquals(loc2.SVMXC__City__c, updated.SVMXC__City__c);

		delete ip;
	}

	static testMethod void testLookups()
	{
		// SVMXCFG-647 - Cannot create new User due to managed package error
		//User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
		User techUser = new User(Id = UserInfo.getUserId());
		//User techUser2 = SMAX_PS_TestDataFactory.createTestUser('testtec2');
		User techUser2 = new User(Id = UserInfo.getUserId());

		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
		SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam02', techUser2, 'Test Tech2', 'TS10', 'T002');

		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'LOC101');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TestSeries001');

		SVMXC__Installed_Product__c result = [SELECT Id, Name, SVMXC__Preferred_Technician__c, SMAX_PS_Secondary_Technician__c,
			SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
			SMAX_PS_LL_ShipTo_Account__c, SMAX_PS_LL_BillTo_Account__c
			FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];

		System.assertEquals(null, result.SVMXC__Preferred_Technician__c);
		System.assertEquals(null, result.SMAX_PS_Secondary_Technician__c);
		System.assertEquals(null, result.SMAX_PS_SoldTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_ShipTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_BillTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_Payer_Account__c);
		System.assertEquals(null, result.SMAX_PS_LL_ShipTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_LL_BillTo_Account__c);

		SVMXC__Installed_Product__c update1 = new SVMXC__Installed_Product__c();
		update1.Id = ip.Id;
		update1.SMAX_PS_PreferredTechnicianNumber__c = tech.SVMX_PS_External_ID__c;
		update1.SMAX_PS_SecondaryTechnicianNumber__c = 'JUNK_VALUE';
		update1.SMAX_PS_SoldTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update1.SMAX_PS_ShipTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update1.SMAX_PS_BillTo_ExtId__c = 'JUNK_VALUE';
		update1.SMAX_PS_Payer_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update1.SMAX_PS_LL_ShipTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update1.SMAX_PS_LL_BillTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update update1;

		result = [SELECT Id, Name, SVMXC__Preferred_Technician__c, SMAX_PS_Secondary_Technician__c,
			SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
			SMAX_PS_LL_ShipTo_Account__c, SMAX_PS_LL_BillTo_Account__c
			FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];

		System.assertEquals(tech.Id, result.SVMXC__Preferred_Technician__c);
		System.assertEquals(null, result.SMAX_PS_Secondary_Technician__c);
		System.assertEquals(acct.Id, result.SMAX_PS_SoldTo_Account__c);
		System.assertEquals(acct.Id, result.SMAX_PS_ShipTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_BillTo_Account__c);
		System.assertEquals(acct.Id, result.SMAX_PS_Payer_Account__c);
		System.assertEquals(acct.Id, result.SMAX_PS_LL_ShipTo_Account__c);
		System.assertEquals(acct.Id, result.SMAX_PS_LL_BillTo_Account__c);

		SVMXC__Installed_Product__c update2 = new SVMXC__Installed_Product__c();
		update2.Id = ip.Id;
		update2.SMAX_PS_PreferredTechnicianNumber__c = tech2.SVMX_PS_External_ID__c;
		update2.SMAX_PS_SecondaryTechnicianNumber__c = tech.SVMX_PS_External_ID__c;
		update2.SMAX_PS_BillTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		update2.SMAX_PS_Payer_ExtId__c = null;
		update update2;

		result = [SELECT Id, Name, SVMXC__Preferred_Technician__c, SMAX_PS_Secondary_Technician__c,
			SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
			SMAX_PS_LL_ShipTo_Account__c, SMAX_PS_LL_BillTo_Account__c
			FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];

		System.assertEquals(tech2.Id, result.SVMXC__Preferred_Technician__c);
		System.assertEquals(tech.Id, result.SMAX_PS_Secondary_Technician__c);
		System.assertEquals(acct.Id, result.SMAX_PS_BillTo_Account__c);
		System.assertEquals(null, result.SMAX_PS_Payer_Account__c);

	}

	static testMethod void testCalibratedTools()
	{
		RecordType calToolRecType = SMAX_PS_Utility.getRecordType('SVMXC__Installed_Product__c', 'SMAX_PS_Calibrated_Tools');
		SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(RecordTypeId = calToolRecType.Id);
        ip.SVMXC__Serial_Lot_Number__c = 'CALTOOL001';
        insert ip;

        ip.SMAX_PS_MTE_Change_Reason__c = 'Data Correction';
        ip.SMAX_PS_MTE_Change_Description__c = 'Testing...';
        ip.SVMXC__Serial_Lot_Number__c = 'CALTOOL001-01';
        update ip;

	}

	// SVMXCFG-711 Ensure IP address is synced with Location address
	static testMethod void testIpAddressBatch()
	{
		Account acct1 = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');

		SVMXC__Site__c loc1 = new SVMXC__Site__c();
		loc1.SVMXC__Street__c = '123 Main Street';
		loc1.SVMXC__City__c = 'Anytown';
		loc1.SVMXC__State__c = 'FL';
		loc1.SVMXC__Zip__c = '33601';
		loc1.SVMXC__Country__c = 'USA';
		insert loc1; 

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('001', acct1, loc1,'TestSeries001');
		ip.SVMXC__Street__c = '';
		ip.SVMXC__City__c = '';
		ip.SVMXC__State__c = '';
		ip.SVMXC__Zip__c = '';
		ip.SVMXC__Country__c = '';
		update ip;

		Test.startTest();

		SMAX_PS_InstalledProductAddresses_Batch bat1 = new SMAX_PS_InstalledProductAddresses_Batch();
		Database.executeBatch(bat1);

		SMAX_PS_InstalledProductAddresses_Batch bat2 = new SMAX_PS_InstalledProductAddresses_Batch();
		System.schedule('testSchedJob', '0 0 23 * * ?', bat2);

		Test.stopTest();
	}
}
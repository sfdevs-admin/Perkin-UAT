/**
	Test Class for  SMAX_PS_PartsOrderManager
	Client      :   PerkinElmer
	Created by  :   Veerendra on 2017-10-11

	Updates:
	2022-05-06	Tony	ITSVMX-562 Modify the replenishment parts ordering process
*/

@isTest(seeAllData=true)
public class SMAX_PS_PartsOrder_UT
{         
	static testMethod void createPartsOrderTestData()
	{     
		// Insert Account  
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000001');
		acct.SMAX_PS_Transportation_Zone__c = '1';
		acct.PKI_SAP_Language__c = 'ES';
		update acct;

		// Insert Contact  
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

		// Insert location
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');

		User u = new User();
		u.Id = UserInfo.getUserId();
		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TEST', u, 'Test Tech', 'TS01', 'TST001');
		tech.SVMXC__Inventory_Location__c = loc.Id;
		update tech;

		// Insert Parts Order
		RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
		SVMXC__RMA_Shipment_Order__c po = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, acct, cont, loc, tech, null, null, null);

		Test.startTest();

		po.SVMXC__Destination_City__c = 'The Most Terrific City in the World with the Most Amazing Food';
		po.SVMXC__Destination_Zip__c = '012345678900123456789001234567890';
		po.SVMXC__Order_Status__c='Submitted to ERP';
		update po;

		// Insert Parts Order
		RecordType poRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'RMA');
		SVMXC__RMA_Shipment_Order__c rma = SMAX_PS_TestDataFactory.createTestPartsOrder(poRmaRT, acct, cont, loc, null, null, null, null);

		rma.SVMXC__Order_Status__c='Submitted to ERP';
		update rma;

		Test.stopTest();

		// SVMXINT-612 map the Transportation Zone and Language from Account if no WO
		SVMXC__RMA_Shipment_Order__c result = [SELECT Id, Name, SMAX_PS_Transportation_Zone__c, SMAX_PS_Language__c,
				SVMXC__Destination_City__c, SVMXC__Destination_Zip__c
			FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :po.Id];
		System.assertEquals(acct.SMAX_PS_Transportation_Zone__c, result.SMAX_PS_Transportation_Zone__c);
		System.assertEquals(acct.PKI_SAP_Language__c, result.SMAX_PS_Language__c);
		System.assertEquals(40, result.SVMXC__Destination_City__c.length());
		System.assertEquals(10, result.SVMXC__Destination_Zip__c.length());

		//List<String> poIds = new List<String> { po.Id + '', rma.Id + '' };
		//List<SMAX_PS_Platform_Event_Log__c> logs = [SELECT Id, Name FROM SMAX_PS_Platform_Event_Log__c 
		//    WHERE SMAX_PS_Platform_Event_Type__c = 'SMAX_PS_PartsOrder_Event__e' AND SMAX_PS_Related_Element_Id__c IN :poIds];
		//System.assertEquals(2, logs.size());
	}

	static testMethod void createLinkedOrders()
	{
		User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');

		tech.SVMXC__Inventory_Location__c = loc.Id;
		update tech;

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101');
		ip.SVMXC__Preferred_Technician__c = tech.Id;
		update ip;

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		// Insert Parts Order
		RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
		RecordType poShipRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Shipment');
		RecordType poDelRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Delivery');
		RecordType poRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'RMA');

		Test.startTest();

		// Create PO w/o Account, but with Tech.StorageLocation... and test SalesOrg too
		SVMXC__RMA_Shipment_Order__c poReq = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, null, cont, loc, tech, wo, null, null);

		// Mimic the tech relasing it to SAP..
		poReq.SVMXC__Order_Status__c = 'Submitted to ERP';
		update poReq;

		// Mimic BOOMI assgning the SAP Id...
		poReq.SMAX_PS_ExternalId__c = 'PO-REQ-0001';
		update poReq;

		SVMXC__RMA_Shipment_Order__c reqResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :poReq.Id];
		System.assertEquals('Received by ERP', reqResult.SVMXC__Order_Status__c);

		// SVMXINT-573 Parts Orders - Double Submit... make sure this isn't allowed.
		reqResult.SVMXC__Order_Status__c = 'Submitted to ERP';
		update reqResult;
		reqResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :poReq.Id];
		System.assertEquals('Received by ERP', reqResult.SVMXC__Order_Status__c);

		// Create linked Shipment, Deliveries (SMAX_PS_RelatedExternalId__c / SMAX_PS_ExternalId__c)
//		SVMXC__RMA_Shipment_Order__c poShip = SMAX_PS_TestDataFactory.createTestPartsOrder(poShipRT, null, cont, loc, null, null, 'PO-SHP-0001', 'PO-REQ-0001');
		SVMXC__RMA_Shipment_Order__c poShip = new SVMXC__RMA_Shipment_Order__c(RecordTypeId=poShipRT.Id);
		poShip.SVMXC__Order_Status__c = 'Open';
		poShip.SVMXC__Expected_Receive_Date__c = Date.today();
		poShip.SMAX_PS_SoldTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		poShip.SMAX_PS_ShipTo_ExtId__c = acct.PKI_SAP_Customer_Number__c;
		poShip.SVMXC__Contact__c = cont.Id;
		poShip.SVMXC__Destination_Location__c = loc.Id;
		poShip.SMAX_PS_RelatedExternalId__c = 'PO-REQ-0001';
		poShip.SMAX_PS_ExternalId__c = 'PO-SHP-0001';
		insert poShip;

		reqResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :poReq.Id];
		System.assertEquals('Processed', reqResult.SVMXC__Order_Status__c);

		SVMXC__RMA_Shipment_Order__c poDel = SMAX_PS_TestDataFactory.createTestPartsOrder(poDelRT, null, cont, loc, null, null, 'PO-DEL-0001', 'PO-SHP-0001');

		reqResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :poReq.Id];
		System.assertEquals('Picked', reqResult.SVMXC__Order_Status__c);

		Test.stopTest();

		//SVMXC__RMA_Shipment_Order__c poRma = SMAX_PS_TestDataFactory.createTestPartsOrder(poRmaRT, null, cont, loc, tech, null, 'PO-RMA-0001', 'PO-REQ-0001');
	}

	static testMethod void testInstrumentReturn()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		update loc;
		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Eq Product', 'TSTEQ01', 'TSTT');

		SMAX_PS_ProductPlant__c pp1 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'TT12', SMAX_PS_Product__c = prod.Id,
				BD_Return_Part_Number__c = 'L' + prod.Partnum__c);
		insert new List<SMAX_PS_ProductPlant__c> { pp1 };

		Group g1 = new Group(Name='TST FOODS TS12 Depot', DeveloperName='TST_FOODS_TS12_Depot', Type='Queue');
		insert g1;
		System.runAs(new User(Id=UserInfo.getUserId()))
		{
			QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'SVMXC__Service_Order__c');
			insert q1;
		}

		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestDepot01',
			null, 'Test Depot1', 'TS12', 'T001', 'DEPOT01');
		tech.BD_Depot_Queue_Name__c = g1.DeveloperName;
		tech.SVMXC__Role__c = 'Depot Queue';
		tech.SVMXC__Street__c = '123 Main St';
		tech.SVMXC__City__c = 'Springfield';
		tech.SVMXC__State__c = 'IL';
		tech.SVMXC__Zip__c = '11111';
		tech.SVMXC__Country__c = 'US';
		update tech;

		SMAX_PS_Depot_Plant__c depotPlant = new SMAX_PS_Depot_Plant__c();
		depotPlant.SMAX_PS_Depot_Technician__c = tech.Id;
		depotPlant.SMAX_PS_Plant_Code__c = 'TS12';
		depotPlant.SMAX_PS_Sales_Org__c = 'TS10';
		depotPlant.SMAX_PS_Country__c = 'US';
		insert depotPlant;

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

/*		// "Instrument Return to Depot" SFM...
		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType rmaRT = recTypeMap.get('RMA');
		SVMXC__RMA_Shipment_Order__c rma = SMAX_PS_TestDataFactory.createTestPartsOrder(rmaRT, acct, cont, null, tech, wo, null, null);
		rma.SVMXC__Order_Type__c = 'Return';
		rma.SVMXC__RMA_Type__c = 'Instrument';
		update rma;

		SVMXC__RMA_Shipment_Line__c rmaLine = new SVMXC__RMA_Shipment_Line__c();
		rmaLine.SVMXC__Product__c = prod.Id;
		rmaLine.SVMXC__Actual_Quantity2__c = 1;
		rmaLine.SVMXC__RMA_Shipment_Order__c = rma.Id;
		rmaLine.BD_Return_Part_Number__c = pp1.BD_Return_Part_Number__c;
		insert rmaLine;

		wo = new SVMXC__Service_Order__c( Id = wo.Id );
		wo.SVMXC__Order_Status__c = 'Initializing';
		wo.BD_Escalate_to_Depot__c = true;
		wo.BD_Escalate_to_Depot_Date_Time__c = Datetime.now();
		update wo;

		Test.startTest();

		// Simulate the SAP WO Id being updated from SAP.. should cause the RMA to be submitted
		wo.SVMX_PS_External_ID__c = 'SO-TEST-01';
		update wo;

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
				SVMX_PS_External_ID__c, BD_Equipment_Part_Return_Number__c
		FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals('Depot_Repair', woResult.RecordType.DeveloperName);
		System.assertEquals(g1.Id, woResult.OwnerId);
		System.assertEquals(pp1.BD_Return_Part_Number__c, woResult.BD_Equipment_Part_Return_Number__c);

		SVMXC__RMA_Shipment_Order__c rmaResult = [SELECT Id, Name, SVMXC__Order_Type__c, SVMXC__RMA_Type__c,
				SVMXC__Order_Status__c, SVMXC__Service_Order__c, SMAX_PS_DestinationName1__c
			FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c = :wo.Id AND RecordTypeId = :rmaRT.Id];
				//SMAX_PS_TestDataFactory.createTestPartsOrder(rmaRT, acct, cont, null, tech, wo, null, null);
		System.assertNotEquals(null, rmaResult);
		System.assertEquals('Submitted to ERP', rmaResult.SVMXC__Order_Status__c);

		SVMXC__RMA_Shipment_Line__c rmaLineResult = [SELECT Id, Name, SVMXC__Product__c, SVMXC__Expected_Quantity2__c, BD_Return_Part_Number__c
			FROM SVMXC__RMA_Shipment_Line__c WHERE SVMXC__RMA_Shipment_Order__c = :rmaResult.Id];
		System.assertEquals(prod.Id, rmaLineResult.SVMXC__Product__c);
		System.assertEquals(pp1.BD_Return_Part_Number__c, rmaLineResult.BD_Return_Part_Number__c);
*/
		// "Instrument Return to Depot" SFM...
		wo.SVMXC__Group_Member__c = tech.Id;
		wo.SVMXC__Order_Status__c = 'Initializing';
		wo.BD_SourceName1__c = 'Test Co.';
		update wo;

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
				SVMX_PS_External_ID__c, BD_Equipment_Part_Return_Number__c
		FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals('Depot_Repair', woResult.RecordType.DeveloperName);
		System.assertEquals(g1.Id, woResult.OwnerId);
		System.assertEquals(pp1.BD_Return_Part_Number__c, woResult.BD_Equipment_Part_Return_Number__c);

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType rmaRT = recTypeMap.get('RMA');

//		Test.startTest();

		// Simulate the SAP WO Id being assigned.. should cause the RMA to be created
		woResult.SMAX_PS_Depot_Plant__c = depotPlant.Id;
		woResult.SVMX_PS_External_ID__c = 'SO-TEST-01';
		update woResult;

		Test.startTest();

		SVMXC__RMA_Shipment_Order__c rma = [SELECT Id, Name, SVMXC__Order_Type__c, SVMXC__RMA_Type__c,
				SVMXC__Order_Status__c, SVMXC__Service_Order__c, SMAX_PS_SourceName1__c
			FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c = :wo.Id AND RecordTypeId = :rmaRT.Id];
		//SMAX_PS_TestDataFactory.createTestPartsOrder(rmaRT, acct, cont, null, tech, wo, null, null);
		System.assertNotEquals(null, rma);
		System.assertEquals(wo.BD_SourceName1__c, rma.SMAX_PS_SourceName1__c);
		System.assertEquals('Submitted to ERP', rma.SVMXC__Order_Status__c);

		SVMXC__RMA_Shipment_Line__c rmaLine = [SELECT Id, Name, SVMXC__Product__c, SVMXC__Expected_Quantity2__c, BD_Return_Part_Number__c
		FROM SVMXC__RMA_Shipment_Line__c WHERE SVMXC__RMA_Shipment_Order__c = :rma.Id];
		System.assertEquals(prod.Id, rmaLine.SVMXC__Product__c);
		// ITSVMX-555 We should not fill in the "Return Part Number" for traditional Depot
		//System.assertEquals(pp1.BD_Return_Part_Number__c, rmaLine.BD_Return_Part_Number__c);

		// Mimic BOOMI assigning the SAP Id...
		rma.SMAX_PS_ExternalId__c = 'RMA-REQ-0001';
		update rma;
		SVMXC__RMA_Shipment_Order__c rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Return Requested', rmaResult.SVMXC__Order_Status__c);

		rma.BD_SAP_Delivery_Number__c = 'RMA-DEL-0001';
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Received', rmaResult.SVMXC__Order_Status__c);

		rma.BD_SAP_Return_Number__c = 'RMA-RET-0001';
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Shipment Requested', rmaResult.SVMXC__Order_Status__c);

		rma.BD_SAP_Return_Delivery_Number__c = 'RMA-RDL-0001';
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Issued from Warehouse', rmaResult.SVMXC__Order_Status__c);

		Test.stopTest();
	}

	static testMethod void testPartsReturn()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		update loc;

		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Eq Product', 'TSTEQ01', 'TSTT');
		Product2 part = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', 'TST0001', 'TEST', 'Parts');
		Product2 retPart = SMAX_PS_TestDataFactory.createTestProduct('TestProduct2', 'TST0001C', 'TEST', 'Parts');

		SMAX_PS_ProductPlant__c pp1 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'TT12', SMAX_PS_Product__c = part.Id,
				BD_Return_Part_Number__c = retPart.Partnum__c);
		insert new List<SMAX_PS_ProductPlant__c> { pp1 };

		Group g1 = new Group(Name='TST FOODS TS12 Depot', DeveloperName='TST_FOODS_TS12_Depot', Type='Queue');
		insert g1;

		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestDepot01',
				null, 'Test Depot1', 'TS12', 'T001', 'DEPOT01');
		tech.BD_Depot_Queue_Name__c = g1.DeveloperName;
		// 7/2/20 - tony - added a Role value as the test was failing
		tech.SVMXC__Role__c = 'Depot Queue';
		update tech;

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
				SVMXC__Product__c = part.Id, SVMXC__Actual_Quantity2__c = 1);
		insert new List<SVMXC__Service_Order_Line__c> { line1 };

		SVMXC__Service_Order_Line__c line1Result = [SELECT Id, Name, BD_Return_Part_Number__c
			FROM SVMXC__Service_Order_Line__c WHERE Id = :line1.Id];

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType rmaRT = recTypeMap.get('RMA');

		Test.startTest();

		SVMXC__RMA_Shipment_Order__c rma = SMAX_PS_TestDataFactory.createTestPartsOrder(rmaRT, acct, cont, null, tech, wo, null, null);

		SVMXC__RMA_Shipment_Line__c rmaLine = new SVMXC__RMA_Shipment_Line__c();
		rmaLine.SVMXC__Product__c = retPart.Id; // NOTE: The SFM should do this.. use the "Return Part" instead of the "Debriefed Part"
		rmaLine.SVMXC__Actual_Quantity2__c = 1;
		rmaLine.SVMXC__RMA_Shipment_Order__c = rma.Id;
		rmaLine.BD_Return_Part_Number__c = line1Result.BD_Return_Part_Number__c;
		insert rmaLine;

		// Mimic the tech releasing it to SAP..
		rma.SVMXC__Order_Type__c = 'Return';
		rma.SVMXC__RMA_Type__c = 'Parts';
		rma.SVMXC__Order_Status__c = 'Submitted to ERP';
		update rma;

		// Mimic BOOMI assigning the SAP Id...
		rma.SMAX_PS_ExternalId__c = 'RMA-REQ-0001';
		update rma;
		SVMXC__RMA_Shipment_Order__c rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Return Requested', rmaResult.SVMXC__Order_Status__c);

		rma.BD_SAP_Delivery_Number__c = 'RMA-DEL-0001';
//		rma.BD_Depot_Work_Center__c = tech.SMAX_PS_Work_Center__c; // This should NOT cause WO to auto-assign to tech above..
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Received', rmaResult.SVMXC__Order_Status__c);

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, SVMXC__Group_Member__c
		FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertNotEquals(tech.Id, woResult.SVMXC__Group_Member__c);

		rma.BD_SAP_Return_Number__c = 'RMA-RET-0001';
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Shipment Requested', rmaResult.SVMXC__Order_Status__c);

		rma.BD_SAP_Return_Delivery_Number__c = 'RMA-RDL-0001';
		update rma;
		rmaResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :rma.Id];
		System.assertEquals('Issued from Warehouse', rmaResult.SVMXC__Order_Status__c);

		Test.stopTest();
	}

	static testMethod void testLoaner()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		update loc;
		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Eq Product', 'TSTEQ01', 'TSTT');

		SMAX_PS_ProductPlant__c pp1 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'TT12', SMAX_PS_Product__c = prod.Id,
				BD_Return_Part_Number__c = 'L' + prod.Partnum__c);
		insert new List<SMAX_PS_ProductPlant__c> { pp1 };

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);
		SVMXC__Installed_Product__c loanerIP = SMAX_PS_TestDataFactory.createIP('LOANX0000234001', acct, loc, 'TST00101', prod);
		loanerIP.SVMX_PS_External_ID__c = 'EQ-' + loanerIP.SVMXC__Serial_Lot_Number__c;
		loanerIP.SMAX_PS_UserStatus__c = 'LOAN';
		update loanerIP;

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, BD_Equipment_Part_Return_Number__c
			FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals(pp1.BD_Return_Part_Number__c, woResult.BD_Equipment_Part_Return_Number__c);

		Map<String, RecordType> recTypeMap = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__RMA_Shipment_Order__c');
		RecordType loanerRT = recTypeMap.get('Loaner');

		Test.startTest();

		SVMXC__RMA_Shipment_Order__c loaner = SMAX_PS_TestDataFactory.createTestPartsOrder(loanerRT, acct, cont, null, null, wo, null, null);

		SVMXC__RMA_Shipment_Line__c loanerLine = new SVMXC__RMA_Shipment_Line__c();
		loanerLine.SVMXC__Product__c = prod.Id;
		loanerLine.SVMXC__Actual_Quantity2__c = 1;
		loanerLine.SVMXC__RMA_Shipment_Order__c = loaner.Id;
		loanerLine.BD_Return_Part_Number__c = woResult.BD_Equipment_Part_Return_Number__c;
		insert loanerLine;

		// Mimic the tech releasing it to SAP..
		loaner.SVMXC__Order_Type__c = 'Loaner';
		loaner.SVMXC__Order_Status__c = 'Submitted to ERP';
		update loaner;

		// Mimic BOOMI assigning the SAP Id...
		loaner.SMAX_PS_ExternalId__c = 'LOAN-REQ-0001';
		update loaner;
		SVMXC__RMA_Shipment_Order__c loanerResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :loaner.Id];
		System.assertEquals('Loan Requested', loanerResult.SVMXC__Order_Status__c);

		loaner.BD_SAP_Delivery_Number__c = 'LOAN-DEL-0001';
		loaner.BD_Loaner_Equipment_External_Id__c = loanerIP.SVMX_PS_External_ID__c; // This should cause the IP Lookup to populate
		update loaner;
		loanerResult = [SELECT Id, Name, SVMXC__Order_Status__c, BD_Loaner_Equipment__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :loaner.Id];
		System.assertEquals('On Loan', loanerResult.SVMXC__Order_Status__c);
		System.assertEquals(loanerIP.Id, loanerResult.BD_Loaner_Equipment__c);

		// Mimic the SFM: Return Loaner
		loaner.SVMXC__Order_Status__c = 'Return Requested';
		update loaner;

		loaner.BD_SAP_Return_Number__c = 'LOAN-RET-0001';
		update loaner;
		loanerResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :loaner.Id];
		System.assertEquals('Loaner Return', loanerResult.SVMXC__Order_Status__c);

		loaner.BD_SAP_Return_Delivery_Number__c = 'LOAN-RDL-0001';
		update loaner;
		loanerResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :loaner.Id];
		System.assertEquals('Returned', loanerResult.SVMXC__Order_Status__c);

		Test.stopTest();
	}

	// 2022-05-06 Tony ITSVMX-562 Modify the replenishment parts ordering process
	@IsTest
	static void testRefurbishedPartsAllowed() {

		// Insert Account
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000001');
		acct.SMAX_PS_Transportation_Zone__c = '1';
		acct.PKI_SAP_Language__c = 'ES';
		update acct;

		// Insert Contact
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

		// Insert location
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');

		User usr = new User();
		usr.Id = UserInfo.getUserId();
		SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TEST', usr, 'Test Tech', 'TS01', 'TST001');
		tech.SVMXC__Inventory_Location__c = loc.Id;
		update tech;

		// Insert Product
		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Eq Product', 'TSTEQ01', 'TSTT');

		// Insert Installed Product
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);

		// Insert Work Order
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		wo.BD_Use_Refurbished_Parts__c = true;
		wo.BD_Refurbished_Parts_Allowed__c = true;
		update wo;

		// Insert Parts Order
		RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
		SVMXC__RMA_Shipment_Order__c po = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, acct, cont, loc, tech, wo, null, null);

		Test.startTest();

		// Get the Parts Order
		System.debug('po.Id: ' + po.Id);
		List<SVMXC__RMA_Shipment_Order__c> testPOs = [
				SELECT Id, Name, BD_Refurbished_Parts_Allowed__c, BD_Use_Refurbished_Parts__c, SMAX_PS_Is_APAC_Parts_Order__c
				FROM SVMXC__RMA_Shipment_Order__c
				WHERE Id = :po.Id
				LIMIT 1
		];
		System.debug('testPOs: ' + testPOs.size() + ' ' + testPOs);

		// Validate
		System.assertEquals(true, testPOs[0].BD_Refurbished_Parts_Allowed__c, 'Parts Order BD_Refurbished_Parts_Allowed__c should be TRUE');
		System.assertEquals(true, testPOs[0].BD_Use_Refurbished_Parts__c, 'Parts Order BD_Use_Refurbished_Parts__c should be TRUE');

		Test.stopTest();
	}

}
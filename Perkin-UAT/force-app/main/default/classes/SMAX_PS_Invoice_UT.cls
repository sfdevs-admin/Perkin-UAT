/*
	Test Class for  SMAX_PS_InvoiceManager
	Client      :   PerkinElmer
	Created by  :   Veerendra on 2017-11-16
*/
@isTest(seeAllData=false)
public class SMAX_PS_Invoice_UT
{
	static testMethod void dmrInvoiceCreateCancel()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		// Get Record type Id's for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;
		Id invInvoiceRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'Invoice').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c dmr = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId, SVMXC__Status__c='Open');
		// SVMXCFG-1144 make sure this gets auto populated now...
		//dmr.SMAX_PS_SAP_DMR_InvoiceNumber__c = 'ABC12345678';
		dmr.SMAX_PS_SAP_DMR_Number__c = 'DEF0001001001';
		insert dmr;

		SVMXC__Proforma_Invoice_Detail__c dmrDetail = new SVMXC__Proforma_Invoice_Detail__c();
		dmrDetail.SVMXC__Proforma_Invoice__c = dmr.Id;
		dmrDetail.SVMXC__Work_Order__c = wo.Id;
		insert dmrDetail;

		SVMXC__Proforma_Invoice_Line__c dmrLine = new SVMXC__Proforma_Invoice_Line__c();
		dmrLine.SVMXC__Proforma_Invoice_Detail__c = dmrDetail.Id;
		dmrLine.SVMXC__Proforma_Invoice__c = dmr.Id;
		insert dmrLine;

		dmr.SVMXC__Status__c='Released';
		update dmr;

		SVMXC__Proforma_Invoice__c dmrResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, SMAX_PS_SAP_DMR_InvoiceNumber__c
			FROM SVMXC__Proforma_Invoice__c WHERE Id = :dmr.Id];
		System.assertEquals(wo.Id, dmrResult.SMAX_PS_Work_Order__c);
		System.assertEquals(null, dmrResult.SMAX_PS_SAP_DMR_InvoiceNumber__c);

		dmr.SVMXC__Status__c='Rejected';
		dmr.SMAX_PS_Rejection_Reason__c = 'Duplicate';
		update dmr;

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, SMAX_PS_Rejection_Reason__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals(dmr.SMAX_PS_Rejection_Reason__c, woResult.SMAX_PS_Rejection_Reason__c);

		Test.startTest();

		// Insert Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(
				RecordTypeId=invInvoiceRecordTypeId,
				SVMXC__Status__c='Open');
		inv.SMAX_PS_SAP_InvoiceNumber__c = 'ABC12345678';
		inv.SMAX_PS_SAP_Invoice_DMR_Number__c = 'DEF0001001001';
		insert inv;

		dmrResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, SMAX_PS_SAP_DMR_InvoiceNumber__c
			FROM SVMXC__Proforma_Invoice__c WHERE Id = :dmr.Id];
		// SVMXCFG-1144 make sure this gets auto populated now...
		System.assertEquals(inv.SMAX_PS_SAP_InvoiceNumber__c, dmrResult.SMAX_PS_SAP_DMR_InvoiceNumber__c);

		SVMXC__Proforma_Invoice_Detail__c invDetail = new SVMXC__Proforma_Invoice_Detail__c();
		invDetail.SVMXC__Proforma_Invoice__c = inv.Id;
		invDetail.SVMXC__Work_Order__c = wo.Id;
		invDetail.SMAX_PS_TotalNetAmount__c = 180.00;
		invDetail.SMAX_PS_TotalTaxAmount__c = 20.00;
		invDetail.SVMXC__Total_Amount__c = 200.00;
		insert invDetail;

		SVMXC__Proforma_Invoice_Line__c invLine = new SVMXC__Proforma_Invoice_Line__c();
		invLine.SVMXC__Proforma_Invoice_Detail__c = invDetail.Id;
		invLine.SVMXC__Proforma_Invoice__c = inv.Id;
		invLine.SMAX_PS_NetAmount__c = 180.00;
		invLine.SMAX_PS_TaxAmount__c = 20.00;
		invLine.SVMXC__Total_Line_Price__c = 200.00;
		insert invLine;

		inv.SVMXC__Status__c='Canceled';
		inv.SMAX_PS_SAP_CancelInvoiceNumber__c = 'CANC12345678';
		update inv;

		SVMXC__Proforma_Invoice__c invResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, RecordType.Name,
			(SELECT Id, Name, SVMXC__Total_Amount__c, SMAX_PS_TotalNetAmount__c, SMAX_PS_TotalTaxAmount__c
			FROM SVMXC__Proforma_Invoice_Detail__r),
			(SELECT Id, Name, SVMXC__Billable_Line_Price__c, SMAX_PS_NetAmount__c, SVMXC__Price__c,
				SMAX_PS_TaxAmount__c, SVMXC__Total_Line_Price__c FROM SVMXC__Proforma_Invoice_Lines__r)
			FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals(wo.Id, invResult.SMAX_PS_Work_Order__c);
		System.assertEquals('Invoice', invResult.RecordType.Name);
		for (SVMXC__Proforma_Invoice_Detail__c resultDet : invResult.SVMXC__Proforma_Invoice_Detail__r)
		{
			System.assert(resultDet.SVMXC__Total_Amount__c > 0, 'Invoice Total Amount should be positive');
		}
		for (SVMXC__Proforma_Invoice_Line__c resultLine : invResult.SVMXC__Proforma_Invoice_Lines__r)
		{
			System.assert(resultLine.SVMXC__Total_Line_Price__c > 0, 'Invoice Line Total Line Price should be positive');
		}

		// Insert Cancelation Invoice
		SVMXC__Proforma_Invoice__c cancel = new SVMXC__Proforma_Invoice__c(
				RecordTypeId=invInvoiceRecordTypeId,
				SVMXC__Status__c='Open');
		cancel.SMAX_PS_SAP_InvoiceNumber__c = 'CANC12345678';
		cancel.SMAX_PS_SAP_Invoice_DMR_Number__c = 'DEF0001001001';
		insert cancel;

		SVMXC__Proforma_Invoice_Detail__c cancelDetail = new SVMXC__Proforma_Invoice_Detail__c();
		cancelDetail.SVMXC__Proforma_Invoice__c = cancel.Id;
		cancelDetail.SVMXC__Work_Order__c = wo.Id;
		cancelDetail.SMAX_PS_TotalNetAmount__c = 180.00;
		cancelDetail.SMAX_PS_TotalTaxAmount__c = 20.00;
		cancelDetail.SVMXC__Total_Amount__c = 200.00;
		insert cancelDetail;

		SVMXC__Proforma_Invoice_Line__c cancelLine = new SVMXC__Proforma_Invoice_Line__c();
		cancelLine.SVMXC__Proforma_Invoice_Detail__c = cancelDetail.Id;
		cancelLine.SVMXC__Proforma_Invoice__c = cancel.Id;
		cancelLine.SMAX_PS_NetAmount__c = 180.00;
		cancelLine.SMAX_PS_TaxAmount__c = 20.00;
		cancelLine.SVMXC__Total_Line_Price__c = 200.00;
		insert cancelLine;

		SVMXC__Proforma_Invoice__c cancelResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, RecordType.Name,
			(SELECT Id, Name, SVMXC__Total_Amount__c, SMAX_PS_TotalNetAmount__c, SMAX_PS_TotalTaxAmount__c
			FROM SVMXC__Proforma_Invoice_Detail__r),
			(SELECT Id, Name, SVMXC__Billable_Line_Price__c, SMAX_PS_NetAmount__c, SVMXC__Price__c,
				SMAX_PS_TaxAmount__c, SVMXC__Total_Line_Price__c FROM SVMXC__Proforma_Invoice_Lines__r)
			FROM SVMXC__Proforma_Invoice__c WHERE Id = :cancel.Id];
		System.assertEquals(wo.Id, cancelResult.SMAX_PS_Work_Order__c);
		System.assertEquals('Cancelation', cancelResult.RecordType.Name);
		for (SVMXC__Proforma_Invoice_Detail__c resultDet : cancelResult.SVMXC__Proforma_Invoice_Detail__r)
		{
			System.assert(resultDet.SVMXC__Total_Amount__c < 0, 'Cancelation Total Amount should be negative');
		}
		for (SVMXC__Proforma_Invoice_Line__c resultLine : cancelResult.SVMXC__Proforma_Invoice_Lines__r)
		{
			System.assert(resultLine.SVMXC__Total_Line_Price__c < 0, 'Cancelation Line Total Line Price should be negative');
		}

		Test.stopTest();
	}

	static testMethod void dmrAdjustments()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		update wo;

		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD001', 'TEST');

		Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
		SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(RecordTypeId=usageRecTypeId);
		wd.SVMXC__Service_Order__c = wo.Id;
		wd.SVMXC__Line_Status__c = 'Priced';
		wd.SVMXC__Line_Type__c = 'Parts';
		wd.SVMXC__Actual_Price2__c = 100.00;
		wd.SVMXC__Actual_Quantity2__c = 2;
		wd.SVMXC__Product__c = prod.Id;
		wd.SMAX_PS_ServiceAmountAdjustment__c = 25.00;
		wd.SMAX_PS_ServiceAmountAdjustmentType__c = 'Uplift';
		// SVMXCFG-897 Material Part Description
		wd.SMAX_PS_Material_Part_Description__c = 'Frank was here';
		insert wd;

		// Get DMR Record type Id for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId);
		inv.SVMXC__Status__c='New';
		insert inv;

		SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.SVMXC__Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;

		SVMXC__Proforma_Invoice_Line__c line = new SVMXC__Proforma_Invoice_Line__c();
		line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.SVMXC__Proforma_Invoice__c = inv.Id;
		line.SVMXC__Product__c = prod.Id;
		line.SVMXC__Quantity__c = 2;
		insert line;

		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run...
		SVMXC__Proforma_Invoice_Line__c result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c, SMAX_PS_Material_Part_Description__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(null, result.SMAX_PS_ContractPercentDiscount__c);
		System.assertEquals(wd.SMAX_PS_ServiceAmountAdjustment__c, result.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(wd.SMAX_PS_ServiceAmountAdjustmentType__c, result.SMAX_PS_ServiceAmountAdjustmentType__c);
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);
		System.assertEquals(wd.SMAX_PS_Material_Part_Description__c, result.SMAX_PS_Material_Part_Description__c);

		// Review and approve adjustments..
		inv.SMAX_PS_Adjustments_Reviewed__c = TRUE;
		update inv;

		result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);

		// Unlock DMR (simulate update back from SAP)
		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000002';
		update inv;

		result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);

		// Make Price Adjustments now..

		SVMXC__Proforma_Invoice_Line__c lineUpdate = new SVMXC__Proforma_Invoice_Line__c();
		lineUpdate.Id = line.Id;
		lineUpdate.SMAX_PS_ContractPercentDiscount__c = 10.00;
		update lineUpdate;

		result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(10.00, result.SMAX_PS_ContractPercentDiscount__c);
		System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);

		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000002';
		update inv;

	}

	static testMethod void dmrEInvoiceAdjustments()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		wo.SMAX_PS_EInvoice_Platform_Id__c = 'PLATFORM00100101';
		wo.SMAX_PS_EInvoice_Customer_Id__c = 'CUSTOMER00100101';
		wo.SMAX_PS_EInvoice_Code_1__c = 'CODE1111111H';
		wo.SMAX_PS_EInvoice_Code_2__c = 'CODE2222222H';
		wo.SMAX_PS_EInvoice_Code_3__c = 'CODE3333333H';
		update wo;

		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD001', 'TEST');

		Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
		SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(RecordTypeId=usageRecTypeId);
		wd.SVMXC__Service_Order__c = wo.Id;
		wd.SVMXC__Line_Status__c = 'Priced';
		wd.SVMXC__Line_Type__c = 'Parts';
		wd.SVMXC__Actual_Price2__c = 100.00;
		wd.SVMXC__Actual_Quantity2__c = 2;
		wd.SVMXC__Product__c = prod.Id;
		wd.SMAX_PS_EInvoice_Code_1__c = 'CODE1111111';
		wd.SMAX_PS_EInvoice_Code_2__c = 'CODE2222222';
		wd.SMAX_PS_EInvoice_Code_3__c = 'CODE3333333';
		insert wd;

		// Get DMR Record type Id for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId);
		inv.SVMXC__Status__c='New';
		insert inv;

		SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.SVMXC__Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;

		SVMXC__Proforma_Invoice_Line__c line = new SVMXC__Proforma_Invoice_Line__c();
		line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.SVMXC__Proforma_Invoice__c = inv.Id;
		line.SVMXC__Product__c = prod.Id;
		line.SVMXC__Quantity__c = 2;
		insert line;

		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run...

		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		SVMXC__Proforma_Invoice__c invResult = [SELECT Id, Name,
				SMAX_PS_EInvoice_Platform_Id__c, SMAX_PS_EInvoice_Customer_Id__c
		FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals(wo.SMAX_PS_EInvoice_Platform_Id__c, invResult.SMAX_PS_EInvoice_Platform_Id__c);
		System.assertEquals(wo.SMAX_PS_EInvoice_Customer_Id__c, invResult.SMAX_PS_EInvoice_Customer_Id__c);

		SVMXC__Proforma_Invoice_Line__c result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c,
				SMAX_PS_EInvoice_Code_1__c, SMAX_PS_EInvoice_Code_2__c, SMAX_PS_Material_Part_Description__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);
		System.assertEquals(wd.SMAX_PS_EInvoice_Code_1__c, result.SMAX_PS_EInvoice_Code_1__c);
		System.assertEquals(wd.SMAX_PS_EInvoice_Code_2__c, result.SMAX_PS_EInvoice_Code_2__c);
		System.assertEquals(wd.SMAX_PS_Material_Part_Description__c, result.SMAX_PS_Material_Part_Description__c);

		// Review and approve adjustments..
		inv.SMAX_PS_Adjustments_Reviewed__c = TRUE;
		update inv;

		result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);

		// Unlock DMR (simulate update back from SAP)
		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000002';
		update inv;

		result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);

	}

	static testMethod void testCopyAdjustmentsContract()
	{
		String modelSeries = 'TST001';
		String locCode = 'TSTC01';

		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');

		Date startDate = System.today();
		Date endDate = startDate.addMonths(12);
		SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
		SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
		SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);

		Test.startTest();

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

		Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Confirmed',
				SVMXC__Product__c = prod.Id, SVMXC__Actual_Quantity2__c = 1.5, SMAX_PS_ContractPercentDiscount__c = 100);
		List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { wd };
		insert lines;

		// Get DMR Record type Id for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId);
		inv.SVMXC__Status__c='New';
		insert inv;

		SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.SVMXC__Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;

		SVMXC__Proforma_Invoice_Line__c line = new SVMXC__Proforma_Invoice_Line__c();
		line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.SVMXC__Proforma_Invoice__c = inv.Id;
		line.SVMXC__Product__c = prod.Id;
		line.SVMXC__Quantity__c = 2;
		insert line;

		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run... 
		SVMXC__Proforma_Invoice__c result = [SELECT Id, Name, SMAX_PS_Contract_Item__c, SMAX_PS_Contract_Entitlement__c
		FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals(item.Id, result.SMAX_PS_Contract_Item__c);
		System.assertEquals(ent.Id, result.SMAX_PS_Contract_Entitlement__c);
	}

	static testMethod void testCopyAdjustmentsMergedLines()
	{
		String modelSeries = 'TST001';
		String locCode = 'TSTC01';

		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

		Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
		Product2 prod2 = SMAX_PS_TestDataFactory.createTestProduct('TestSvcPart', 'TSP10010', 'TEST', 'Service Parts');

		Date startDate = System.today();
		Date endDate = startDate.addMonths(12);
		SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
		SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
		SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);

		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

		Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		SVMXC__Service_Order_Line__c wd1 = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Confirmed',
				SVMXC__Product__c = prod.Id, SVMXC__Actual_Quantity2__c = 1.5, SMAX_PS_ContractPercentDiscount__c = 100,
				SMAX_PS_ServiceAmountAdjustment__c = 50, SMAX_PS_ServiceAmountAdjustmentType__c = 'Discount',
				SMAX_PS_ServicePercentAdjustment__c = 5, SMAX_PS_ServicePercentAdjustmentType__c = 'Discount',
				SMAX_PS_Material_Part_Description__c = prod.Name);
		SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Confirmed',
				SVMXC__Product__c = prod.Id, SVMXC__Actual_Quantity2__c = 2.5, SMAX_PS_ContractPercentDiscount__c = 100,
				SMAX_PS_ServiceAmountAdjustment__c = 70, SMAX_PS_ServiceAmountAdjustmentType__c = 'Uplift',
				SMAX_PS_ServicePercentAdjustment__c = 10, SMAX_PS_ServicePercentAdjustmentType__c = 'Discount',
				SMAX_PS_Material_Part_Description__c = prod.Name);
		SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Confirmed',
				SVMXC__Product__c = prod2.Id, SVMXC__Actual_Quantity2__c = 1, SMAX_PS_ContractPercentDiscount__c = 50,
				SMAX_PS_Material_Part_Description__c = 'Custom');
		List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { wd1, wd2, wd3 };
		insert lines;

		Test.startTest();

		// Get DMR Record type Id for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId);
		inv.SVMXC__Status__c='New';
		insert inv;

		SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.SVMXC__Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;

		SVMXC__Proforma_Invoice_Line__c line1 = new SVMXC__Proforma_Invoice_Line__c();
		line1.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line1.SVMXC__Proforma_Invoice__c = inv.Id;
		line1.SVMXC__Product__c = prod.Id;
		line1.SVMXC__Quantity__c = 4;

		SVMXC__Proforma_Invoice_Line__c line2 = new SVMXC__Proforma_Invoice_Line__c();
		line2.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line2.SVMXC__Proforma_Invoice__c = inv.Id;
		line2.SVMXC__Product__c = prod2.Id;
		line2.SVMXC__Quantity__c = 1;

		insert new List<SVMXC__Proforma_Invoice_Line__c> { line1, line2 };

		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run... 
		SVMXC__Proforma_Invoice__c result = [SELECT Id, Name, SMAX_PS_Contract_Item__c, SMAX_PS_Contract_Entitlement__c
		FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals(item.Id, result.SMAX_PS_Contract_Item__c);
		System.assertEquals(ent.Id, result.SMAX_PS_Contract_Entitlement__c);

		SVMXC__Proforma_Invoice_Line__c resultLine1 = [SELECT Id, Name, SVMXC__Line_Notes__c, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServicePercentAdjustmentType__c,
				SMAX_PS_Material_Part_Description__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line1.Id];
		System.assert(resultLine1.SVMXC__Line_Notes__c.contains('Adjustments partially copied from Work Details:'));
		System.assert(resultLine1.SVMXC__Line_Notes__c.contains('Service Percent Adjustment'));
		System.assertEquals(null, resultLine1.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals('Uplift', resultLine1.SMAX_PS_ServiceAmountAdjustmentType__c);
		System.assertEquals(20, resultLine1.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(100, resultLine1.SMAX_PS_ContractPercentDiscount__c);

		SVMXC__Proforma_Invoice_Line__c resultLine2 = [SELECT Id, Name, SVMXC__Line_Notes__c, SMAX_PS_ContractPercentDiscount__c,
				SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
				SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServicePercentAdjustmentType__c,
				SMAX_PS_Material_Part_Description__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line2.Id];
		System.assert(resultLine2.SVMXC__Line_Notes__c.contains('Adjustments copied from Work Detail:'));
		System.assertEquals(null, resultLine2.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals(null, resultLine2.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(50, resultLine2.SMAX_PS_ContractPercentDiscount__c);

		// SVMXCFG-1002 DMR - Only Copy Material Description when changed
		System.assertEquals(null, resultLine1.SMAX_PS_Material_Part_Description__c); // Did not copy.. was not modified
		System.assertEquals(wd3.SMAX_PS_Material_Part_Description__c, resultLine2.SMAX_PS_Material_Part_Description__c); // Did copy.. was modified

		Test.stopTest();
	}

	// For SVMXCFG-607 - added 6/18/18
	static testMethod void testCopyBillingAddressFromAcct()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c();
		insert inv;
		SVMXC__Proforma_Invoice_Detail__c invDet = new SVMXC__Proforma_Invoice_Detail__c();

		acct.BillingStreet = '123 Main St';
		acct.BillingCity = 'Fake City';
		acct.BillingState = 'NC';
		acct.BillingPostalCode = '11111';
		update acct;

		inv.SVMXC__Account__c = acct.id;
		update inv;

		invDet.SVMXC__Proforma_Invoice__c = inv.id;

		//trigger to run
		test.startTest();

		insert invDet;

		test.stopTest();

		SVMXC__Proforma_Invoice__c invResult = [SELECT id, SVMXC__Billing_Street__c,SVMXC__Billing_City__c,SVMXC__Billing_State__c,SVMXC__Billing_Postal_Code__c
		FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];

		System.assertEquals(invResult.SVMXC__Billing_Street__c,acct.BillingStreet);
		System.assertEquals(invResult.SVMXC__Billing_City__c,acct.BillingCity);
		System.assertEquals(invResult.SVMXC__Billing_State__c,acct.BillingState);
		System.assertEquals(invResult.SVMXC__Billing_Postal_Code__c,acct.BillingPostalCode);

		invDet.SVMXC__Quantity__c = 1;
		update invDet;

		delete invDet;
	}

	// SVMXINT-566 DMR - Invoice Not Required
	static testMethod void testInvoiceNotRequired()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		// Get DMR Record type Id for Invoice
		Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		SVMXC__Proforma_Invoice__c inv = new SVMXC__Proforma_Invoice__c(RecordTypeId=invDMRRecordTypeId, SVMXC__Status__c='Open');
		inv.SMAX_PS_SAP_DMR_InvoiceNumber__c = 'ABC12345678';
		inv.SMAX_PS_SAP_DMR_Number__c = 'DEF0001001001';
		insert inv;

		SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.SVMXC__Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;

		SVMXC__Proforma_Invoice_Line__c line = new SVMXC__Proforma_Invoice_Line__c();
		line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.SVMXC__Proforma_Invoice__c = inv.Id;
		insert line;

		Test.startTest();

		// This should cause an auto adjustment of the line to 100% Discount, and Lock the header..
		inv.SMAX_PS_Invoice_Not_Required__c = TRUE;
		update inv;

		SVMXC__Proforma_Invoice_Line__c lineResult = [SELECT Id, Name, SMAX_PS_ServicePercentAdjustment__c,
				SMAX_PS_ServicePercentAdjustmentType__c, SMAX_PS_AutoAdjust_InvoiceNotReq__c
		FROM SVMXC__Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(100, lineResult.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals('Discount', lineResult.SMAX_PS_ServicePercentAdjustmentType__c);
		System.assertEquals(TRUE, lineResult.SMAX_PS_AutoAdjust_InvoiceNotReq__c);

		SVMXC__Proforma_Invoice__c invResult = [SELECT Id, Name, SVMXC__Status__c FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals('Locked', invResult.SVMXC__Status__c);

		// Simulate the SAP response now..
		inv.SMAX_PS_CompletedTxnNumber__c = 'TST000000001';
		update inv;

		Test.stopTest();

		SVMXC__Proforma_Invoice__c invResult2 = [SELECT Id, Name, SVMXC__Status__c FROM SVMXC__Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals('Invoice Not Required', invResult2.SVMXC__Status__c);

		SVMXC__Service_Order__c woResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals('Invoice Not Required', woResult.SVMXC__Order_Status__c);

	}
}
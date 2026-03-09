/**
 * Created by frankvanloon on 2019-01-25.
 * SVMXINT-637 : WO 1CC - Date Cleanup / Stop-Gap
 */
@isTest
private class SMAX_PS_WorkOrder_1CCFixBatch_UT {

	static testMethod void createWorkOrderTestData()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
		pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
		update pd;

		SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
		loc.SMAX_PS_MaintenancePlant__c = 'TT12';
		update loc;

		SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

		Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
		Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');
		SMAX_PS_Fault_Code__c fc = SMAX_PS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', FALSE);

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

		// Insert Work Order
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

		SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

		// Simulate SAP success
		wo.SVMX_PS_External_ID__c = 'SO001991992';
		wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
		wo.SMAX_PS_CreditHold__c = false;
		update wo;

		Test.startTest();

		Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Priced',
				SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
		SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Priced',
				SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
		SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
				SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Open',
				SMAX_PS_Fault_Code__c = fc.Id);
		List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, fcl };
		insert lines;

		wo.SVMXC__Order_Status__c='Work Complete';  // One-Click Complete
		wo.SVMXC__Completed_Date_Time__c = System.now();
		update wo;

		// Should fail.. No Fault Lines..
		//result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		//System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

		result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
		System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
		System.assertEquals('Work Complete - Pending', result.SVMXC__Order_Status__c);

		List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
		for (SVMXC__Service_Order_Line__c lineResult : lineResults)
		{
			System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
		}

		// Simulate a success response from SAP
		SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
		rsp.ServiceOrderNumber = wo.SVMX_PS_External_ID__c;
		rsp.NotificationNumber = 'NO' + wo.SVMX_PS_External_ID__c;
		rsp.CreditHold = false;
		rsp.SystemStatus = 'TECO';
		rsp.UserStatus = 'CMPT;DIR;SRA';
		rsp.TransactionNumber = 'IDOC0007';
		rsp.Lines = new List<SMAX_PS_WorkOrderDebriefService.DebriefLine>();
		for (SVMXC__Service_Order_Line__c lineResult : lineResults)
		{
			SMAX_PS_WorkOrderDebriefService.DebriefLine dline = new SMAX_PS_WorkOrderDebriefService.DebriefLine();
			dline.LineId = lineResult.Name;
			dline.ConfirmationNumber = 'SAPCONF-' + lineResult.Name;
			rsp.Lines.add(dline);
		}
		String svcResult = SMAX_PS_WorkOrderDebriefService.submitDebriefResponse(rsp);
		System.assertEquals('Successfully processed Debrief Response', svcResult);

        SVMXC__Service_Order__c target = new SVMXC__Service_Order__c(id = wo.id);
        target.SVMXC__Order_Status__c = 'Work Complete';
        update target;
        
		result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        
		
		System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
		System.assertEquals('Work Complete', result.SVMXC__Order_Status__c);

		SMAX_PS_WorkOrder_1CCFixBatch b1 = new SMAX_PS_WorkOrder_1CCFixBatch(Date.today());
		b1.execute(null);

		Test.stopTest();
	}



}
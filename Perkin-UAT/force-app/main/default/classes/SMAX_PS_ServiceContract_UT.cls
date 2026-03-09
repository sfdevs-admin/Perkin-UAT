/*
    Test Class for  SMAX_PS_ServiceContractManager
    Client      :   PerkinElmer
    Created by  :   Veerendra on 2017-09-11
*/
@isTest(seeAllData=false)
public class SMAX_PS_ServiceContract_UT
{
	static testMethod void updateServiceContractDeleted()
	{
		Map<String, SObject> data = createTestData();
		SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
		SVMXC__Service_Contract__c item = (SVMXC__Service_Contract__c) data.get('Item');

		// update Parent contract Completed Transaction Number
		scParent.SMAX_PS_CompletedTxnNum__c='tran2';
		update scParent;
		item.SMAX_PS_PreviousContractNumber__c='EXT_ID1';
		item.SMAX_PS_RenewalContractNumber__c='EXT_ID2';
		update item;

		// NOTE: In the above test, since "SMAX_PS_LastTxnNum__c" didn't match, the trigger marked all for deletion

		// Now we'll restore them...
		scParent.SMAX_PS_CompletedTxnNum__c='tran1';
		update scParent;

		// Now test by Cancel Notes..
		item.SVMXC__Cancelation_Notes__c = '17';
		update item;

		scParent.SMAX_PS_CompletedTxnNum__c='tran2';
		update scParent;

		scParent.SMAX_PS_CompletedTxnNum__c='tran1';
		update scParent;
	}

	static testMethod void updateServiceContractSuccess()
	{
		Map<String, SObject> data = createTestData();
		SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
		SVMXC__Service_Contract__c item = (SVMXC__Service_Contract__c) data.get('Item');

		Test.startTest();

		// update Parent contract Completed Transaction Number
		scParent.SMAX_PS_CompletedTxnNum__c='tran1';
		update scParent;

		item.SMAX_PS_PreviousContractNumber__c='EXT_ID1';
		item.SMAX_PS_RenewalContractNumber__c='EXT_ID2';
		update item;

		Test.stopTest();

		// ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
		// Test that the Line Item was updated
		List<SVMXC__Service_Contract__c> scChild = [
				SELECT Id, SMAX_PS_ContractType__c
				FROM SVMXC__Service_Contract__c
				WHERE Id = :item.Id
		];
		System.debug('Parent Service Contract - Contract Type: ' + scParent.SMAX_PS_ContractType__c);
		System.debug('Contract Item - Contract Type: ' + scChild[0].SMAX_PS_ContractType__c);
		System.assertEquals(scParent.SMAX_PS_ContractType__c, scChild[0].SMAX_PS_ContractType__c);

		Account acct = (Account) data.get('Account');
		Contact cont = (Contact) data.get('Contact');
		SVMXC__Site__c loc = (SVMXC__Site__c) data.get('Location');
		SMAX_PS_EntitlementDate__c ed = (SMAX_PS_EntitlementDate__c) data.get('EntDate');

		// NOTE: In the above test, since ALL of the child records populated "SMAX_PS_LastTxnNum__c", the trigger DID NOT mark for deletion
		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',null);
		SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
		wo.SVMX_PS_External_ID__c = 'TEST1001001001';
		update wo;

		ed.SMAX_PS_ServiceOrderNumber__c = wo.SVMX_PS_External_ID__c;
		update ed;

		SMAX_PS_EntitlementDate__c result = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :ed.Id];
		System.assertEquals(wo.Id, result.SMAX_PS_WorkOrder__c);

		// SVMXINT-571 validate that the Service Contract Event was sent
		List<SObject> testEvents = SMAX_PS_Utility.retrieveTestEvents('SMAX_PS_ServiceContract_Event__e');
		System.assertEquals(1, testEvents.size());
	}

	private static Map<String, SObject> createTestData()
	{
		Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'USA');
		Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

		// Insert location
		SVMXC__Site__c loc = new SVMXC__Site__c(
				Name='Test Location',
				SVMXC__Street__c='123 street',
				SVMXC__City__c='123 city',
				SVMXC__State__c='123 state',
				SVMXC__Zip__c='12345',
				SVMXC__Country__c='United States');
		insert loc;

		SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',null);

		// insert Service Contract
		// ITSVMX-228 Added Contract Type
		SVMXC__Service_Contract__c scParent = new SVMXC__Service_Contract__c(
				Name='Test Parent Contract',
				SVMXC__Company__c=acct.Id,
				SVMXC__Contact__c=cont.Id,
				SMAX_PS_LastTxnNum__c ='tran1',
				SMAX_PS_CompletedTxnNum__c='tran',
				SVMX_PS_External_ID__c='EXT_ID1',
				SMAX_PS_ContractType__c = 'ContractType');
		insert scParent;

		// ITSVMX-228 added Contract Item record type
		Id contractItemRTId = Schema.SObjectType.SVMXC__Service_Contract__c.getRecordTypeInfosByDeveloperName().get('ContractItem').getRecordTypeId();
		SVMXC__Service_Contract__c item = new SVMXC__Service_Contract__c(
				Name='Test Contract',
				SVMXC__Company__c=acct.Id,
				SVMXC__Contact__c=cont.Id,
				SMAX_PS_LastTxnNum__c ='tran1',
				SVMX_PS_Parent_Contract__c=scParent.Id,
				RecordTypeId = contractItemRTId);
		insert item;

		// insert covered Product
		SVMXC__Service_Contract_Products__c cp = new SVMXC__Service_Contract_Products__c(
				SMAX_PS_LastTxnNum__c ='tran1',
				SVMXC__Service_Contract__c=item.Id,
				SVMXC__Installed_Product__c = ip.Id,
				SMAX_PS_Parent_Contract__c = scParent.Id);
		insert cp;
		// insert included Services
		SVMXC__Service_Contract_Services__c is = new SVMXC__Service_Contract_Services__c(
				SMAX_PS_LastTxnNum__c ='tran1',
				SVMXC__Service_Contract__c=item.Id);
		insert is;

		// insert Entitlement Dates
		SMAX_PS_EntitlementDate__c ed = new SMAX_PS_EntitlementDate__c(
				SMAX_PS_LastTxnNum__c ='tran1',
				SMAX_PS_Entitlement__c=is.Id,
				SMAX_PS_CoveredProduct__c=cp.Id,
				SMAX_PS_ContractItem__c = item.Id,
				SMAX_PS_PlannedDate__c = Date.today());
		insert ed;

		Map<String, SObject> result = new Map<String, SObject>();
		result.put('Account', acct);
		result.put('Contact', cont);
		result.put('Location', loc);
		result.put('Contract', scParent);
		result.put('Item', item);
		result.put('EntDate', ed);

		return result;
	}

	static testMethod void svcContract_TxnBatch_Sucess()
	{
		Map<String, SObject> data = createTestData();
		SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
		SVMXC__Service_Contract__c item = (SVMXC__Service_Contract__c) data.get('Item');

		Test.startTest();
		SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch();
		b.execute(null);
		//Database.executeBatch(b);
		Test.stopTest();
	}

	static testMethod void svcContract_TxnBatch_Deleted()
	{
		Map<String, SObject> data = createTestData();
		SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
		// This will cause the children to not match, and get marked as deleted
		scParent.SMAX_PS_LastTxnNum__c = 'tran2';
		update scParent;

		Test.startTest();
		SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch();
		b.execute(null);
		//Database.executeBatch(b);
		Test.stopTest();
	}

	@IsTest static void svcContract_TxnNumController()
	{
		Map<String, SObject> data = createTestData();
		SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
		SVMXC__Service_Contract__c item = (SVMXC__Service_Contract__c) data.get('Item');
		//item.SMAX_PS_IsDeleted__c = true;
		//item.SVMXC__Cancelation_Notes__c = '';
		//update item;

		PageReference pageRef = Page.SMAX_PS_ServiceContract_TxnNum;
		pageRef.getParameters().put('id', item.Id);
		Test.setCurrentPage(pageRef);

		//ApexPages.currentPage().getParameters().put('id', item.Id);

		Apexpages.StandardController sc = new Apexpages.StandardController(item);

		SMAX_PS_ServiceContract_TxNumController controller = new SMAX_PS_ServiceContract_TxNumController(sc);

		Test.startTest();
		controller.scheduleServiceContractTxnNumBatch();
		Test.stopTest();
	}
}
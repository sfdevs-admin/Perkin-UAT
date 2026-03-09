@isTest
private class SMAX_PS_ServiceContractController_UT {
	
	@isTest static void testServiceContractController() 
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

		Map<String, RecordType> recTypes = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__Service_Contract__c');
		// insert Service Contract
		SVMXC__Service_Contract__c scParent = new SVMXC__Service_Contract__c(
							Name='Test Parent Contract',
							RecordTypeId = recTypes.get('ServiceContract').Id,
							SVMXC__Company__c=acct.id,
							SVMXC__Contact__c=cont.id,
							SMAX_PS_LastTxnNum__c ='tran1',
							SMAX_PS_CompletedTxnNum__c='tran',
							SVMX_PS_External_ID__c='EXT_ID1');
		insert scParent;

		SVMXC__Service_Contract__c item = new SVMXC__Service_Contract__c(
							Name='Test Contract',
							RecordTypeId = recTypes.get('ContractItem').Id,
							SVMXC__Company__c=acct.id,
							SVMXC__Contact__c=cont.id,
							SMAX_PS_LastTxnNum__c ='tran1',
							SVMX_PS_Parent_Contract__c=scParent.id);
		insert item;

		// Test Parent Contract
		PageReference pageRef1 = Page.SMAX_PS_ServiceContract_ScheduleWO;
		pageRef1.getParameters().put('id', String.valueOf(scParent.Id));
		Test.setCurrentPage(pageRef1);

		ApexPages.StandardController stdc1 = new ApexPages.StandardController(scParent);
		SMAX_PS_ServiceContractController scc1 = new SMAX_PS_ServiceContractController(stdc1);

		scc1.scheduleWorkOrder();

		// Test Contract Item
		PageReference pageRef2 = Page.SMAX_PS_ServiceContract_ScheduleWO;
		pageRef2.getParameters().put('id', String.valueOf(item.Id));
		Test.setCurrentPage(pageRef2);

		ApexPages.StandardController stdc2 = new ApexPages.StandardController(item);
		SMAX_PS_ServiceContractController scc2 = new SMAX_PS_ServiceContractController(stdc2);

		scc2.scheduleWorkOrder();

	}
	
}
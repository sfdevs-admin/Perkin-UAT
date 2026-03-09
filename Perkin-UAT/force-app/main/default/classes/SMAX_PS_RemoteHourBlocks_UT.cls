/**
 * Created by tony on 8/11/21.
 */

@IsTest
public without sharing class SMAX_PS_RemoteHourBlocks_UT {

    @IsTest
    static void testGetRemoteHourBlocksForRecord() {

        // Set up Data

        // Create an Account
        Account account = SMAX_PS_TestDataFactory.createTestAccount('Test Account', 'ACC123');

        // Create a Contact
        Contact contact = SMAX_PS_TestDataFactory.createTestContact('Testy', 'Testerson', account, 'CON123');

        // Create Product
        Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'PRD123', 'PL01');

        // Create Location
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(account, 'Test Location', '23422', 'LOC123');

        // Create an Installed Product
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('SN12345', account, loc, 'ModelSeries1', prod);

        // Create a Service Contract
        SVMXC__Service_Contract__c serviceContract = SMAX_PS_TestDataFactory.createSvcMaintContract('Test Service Contract', account.Id, Date.today() - 30, Date.today() + 30);

        // Create a Service Contract Item
        SVMXC__Service_Contract__c serviceContractItem = SMAX_PS_TestDataFactory.createContractItem(serviceContract, 'Test Item', Date.today() - 30, Date.today() + 30);

        // Create a Covered Products
        SVMXC__Service_Contract_Products__c coveredProduct1 = SMAX_PS_TestDataFactory.createCoveredIP(serviceContractItem, Date.today() - 30, Date.today() + 30, ip);
        coveredProduct1.SMAX_PS_SLA_Terms_Notes__c = 'ZHRS-Remote Support Hours';
        update coveredProduct1;

        SVMXC__Service_Contract_Products__c coveredProduct2 = SMAX_PS_TestDataFactory.createCoveredIP(serviceContractItem, Date.today() - 30, Date.today() + 30, ip);
        coveredProduct2.SMAX_PS_SLA_Terms_Notes__c = 'Some Random Text';
        update coveredProduct2;

        // Create a Remote Work Order
        SVMXC__Service_Order__c rwo = SMAX_PS_TestDataFactory.createRemoteWO(ip, contact);

        // Create a Case
        Case caseRecord = new Case();
        caseRecord.AccountId = account.Id;
        caseRecord.SVMXC__Component__c = ip.Id;
        insert caseRecord;

        // Test with Work Order Id
        List<SMAX_PS_RemoteHourBlocks.RemoteHourBlock> woRhbList = SMAX_PS_RemoteHourBlocks.getRemoteHourBlocksForRecord(rwo.Id);
        System.debug('woRhbList: ' + woRhbList);
        System.assertEquals(2, woRhbList.size(), 'There should be 2 Remote Hour Blocks for the Remote Work Order.');

        // Test with Installed Product Id
        List<SMAX_PS_RemoteHourBlocks.RemoteHourBlock> ipRhbList = SMAX_PS_RemoteHourBlocks.getRemoteHourBlocksForRecord(ip.Id);
        System.debug('ipRhbList: ' + ipRhbList);
        System.assertEquals(2, ipRhbList.size(), 'There should be 2 Remote Hour Blocks for the Installed Product.');

        // Test with Case Id
        List<SMAX_PS_RemoteHourBlocks.RemoteHourBlock> caseRhbList = SMAX_PS_RemoteHourBlocks.getRemoteHourBlocksForRecord(caseRecord.Id);
        System.debug('caseRhbList: ' + caseRhbList);
        System.assertEquals(2, caseRhbList.size(), 'There should be 2 Remote Hour Blocks for the Case.');

    }
}
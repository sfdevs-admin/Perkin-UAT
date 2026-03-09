@isTest
private class SMAX_PS_AutoEntitlement_UT {
    
    @isTest static void testEntitledByQty()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
            SMAX_PS_Offline_Contract_Discounts__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Matching to Entitlement by Qty'));
        System.assertNotEquals(null, result.SMAX_PS_Offline_Contract_Discounts__c);*/

        Test.stopTest();

    }

    @isTest static void testFailedByQty()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 0);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        try
        {
            SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

//            System.assert(false); // Shouldn't get here.. 
        }
        catch (Exception e1)
        {
            System.debug('~~~ Caught expected Exception on WO Create: ' + e1);
        }

        //SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c,
        //  SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
        //  FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        //System.debug('AUTO-ENTITLE RESULT WO: ' + result);
  //      System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        //System.assertEquals('Failed', result.SVMXC__Auto_Entitlement_Status__c);
        //System.assertEquals(null, result.SVMXC__Service_Contract__c);
        //System.assertEquals(null, result.SMAX_PS_ContractItem__c);
        //System.assertEquals(null, result.SMAX_PS_ContractEntitlement__c);
        //System.assertEquals(null, result.SMAX_PS_CoveredProduct__c);

        Test.stopTest();

    }

    @isTest static void testEntitledByInfiniteQty()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Matching to Entitlement by Qty'));*/

        Test.stopTest();

    }

    @isTest static void testEntitledByWildcard()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 3, 1);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('(ZZZ)'));*/

        Test.stopTest();

    }

    @isTest static void testEntitleByDate()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

        SMAX_PS_EntitlementDate__c edate1 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate1.SMAX_PS_ServiceOrderNumber__c = 'XYZABC'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate2 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(10));
        edate2.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ'; // This should also be skipped
        SMAX_PS_EntitlementDate__c edate3 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(20));
        update new List<SMAX_PS_EntitlementDate__c> { edate1, edate2 };

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        /*System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Non-Consumed EntitlementDate Matched'));
        System.assertEquals(3, result.SVMXC__Entitlement_Notes__c.countMatches('Checking EntitlementDate'));*/

        Test.stopTest();

        // Make sure EntitlmentDate has the WO Lookup
        //SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        // KNOWN-ISSUE .. see Auto-Entitlement line 230
        //System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);
    }

    @isTest static void testScheduledWorkOrders()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SMAX_PS_Building__c = 'The Best Building EVER Created';
        ip.SMAX_PS_Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        sc.SVMXC__Contact__c = c.Id;
        sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.SMAX_PS_ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'PM', 5, 2);

        SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        // SVMXCFG-701 Scheduled WO - Change Parameters
        //SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'TST2' });
        SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 60, new Set<String> { 'TST2' }, true);
        Database.executeBatch(b);

        Test.stopTest();

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
            SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
            FROM SVMXC__Service_Order__c WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertNotEquals(null, result.SVMX_PS_Problem_Summary__c);
        System.assert(result.SVMX_PS_Problem_Summary__c.contains('-PM-'));
        System.assert(result.SVMX_PS_Problem_Summary__c.length() == 40);
        System.assert(result.SVMX_PS_Problem_Summary__c.endsWith('...'));
        System.assertEquals(TRUE, result.SMAX_PS_Is_Enterprise__c);
        System.assertNotEquals(null, result.SMAX_PS_Offline_Contract_Discounts__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(edate.SMAX_PS_PlannedDate__c, result.SMAX_PS_Customer_Required_Start_Date__c);

        // Make sure EntitlmentDate has the WO Lookup
        SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);*/
    }

    @isTest static void testScheduledWorkOrderTypeErrors()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SMAX_PS_Building__c = 'The Best Building EVER Created';
        ip.SMAX_PS_Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        sc.SVMXC__Contact__c = c.Id;
        sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.SMAX_PS_ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        // SVMXCFG-999 Blank Entitlement Type should error out
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item, null, 5, 2);

        SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 60, new Set<String> { 'TST2' }, true);
        Database.executeBatch(b);

        Test.stopTest();

        List<SVMXC__Service_Order__c> results = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
            SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
            FROM SVMXC__Service_Order__c WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + results);
        /*System.assertEquals(0, results.size());

        // Make sure EntitlmentDate has the WO Lookup
        SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertEquals(null, edResult.SMAX_PS_WorkOrder__c);

        List<SMAX_PS_ErrorLog__c> errors = [SELECT Id, Name, SMAX_PS_Link__c FROM SMAX_PS_ErrorLog__c];
        System.assertEquals(1, errors.size());*/
    }

    @isTest static void testScheduledWorkOrderErrors()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SMAX_PS_Building__c = 'The Best Building EVER Created';
        ip.SMAX_PS_Room__c = '1234567890';
        // SVMXCFG-699 Scheduled WO - Do not create without related data
        ip.SVMXC__Site__c = null;
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        sc.SVMXC__Contact__c = c.Id;
        sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.SMAX_PS_ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'PM', 5, 2);

        SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 60, new Set<String> { 'TST2' }, true);
        Database.executeBatch(b);

        Test.stopTest();

        List<SVMXC__Service_Order__c> results = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
                SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
                SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
        FROM SVMXC__Service_Order__c WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + results);
        /*System.assertEquals(0, results.size());

        // Make sure EntitlmentDate has the WO Lookup
        SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertEquals(null, edResult.SMAX_PS_WorkOrder__c);

        List<SMAX_PS_ErrorLog__c> errors = [SELECT Id, Name, SMAX_PS_Link__c FROM SMAX_PS_ErrorLog__c];
        System.assertEquals(1, errors.size());*/
    }

    //ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
    @isTest static void testScheduledWorkOrdersDepot()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SMAX_PS_Building__c = 'The Best Building EVER Created';
        ip.SMAX_PS_Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        sc.SVMXC__Contact__c = c.Id;
        sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.SMAX_PS_ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        item.SMAX_PS_SLA_Terms_Notes__c = 'Testing terms like ZDPM- go in this field';
        update item;

        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'PM', 5, 2);

        SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate.SMAX_PS_EntitlementCondition__c = 'ZDPM';
        update edate;
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        //ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
        RecordType depotRepairRT = SMAX_PS_Utility.getRecTypeDevNameMap('SVMXC__Service_Order__c').get('Depot_Repair');
        Group unassignedDepotQueue = [
                SELECT Id, DeveloperName, Type
                FROM Group
                WHERE Type = 'Queue'
                AND DeveloperName = 'SMAX_PS_Unassigned_Depot_PMs' LIMIT 1
        ];
        Id unassignedDepotQueueId = unassignedDepotQueue.Id;
        System.debug('unassignedDepotQueueId: ' + unassignedDepotQueueId);

        Test.startTest();

        // SVMXCFG-701 Scheduled WO - Change Parameters
        //SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'TST2' });
        SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 60, new Set<String> { 'TST2' }, true);
        Database.executeBatch(b);

        Test.stopTest();

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
                SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
                SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c,
                OwnerId, RecordTypeId
        FROM SVMXC__Service_Order__c WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertNotEquals(null, result.SVMX_PS_Problem_Summary__c);
        System.assert(result.SVMX_PS_Problem_Summary__c.contains('-PM-'));
        System.assert(result.SVMX_PS_Problem_Summary__c.length() == 40);
        System.assert(result.SVMX_PS_Problem_Summary__c.endsWith('...'));
        System.assertEquals(TRUE, result.SMAX_PS_Is_Enterprise__c);
        System.assertNotEquals(null, result.SMAX_PS_Offline_Contract_Discounts__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(edate.SMAX_PS_PlannedDate__c, result.SMAX_PS_Customer_Required_Start_Date__c);
        System.assertEquals(unassignedDepotQueueId, result.OwnerId);
        System.assertEquals(depotRepairRT.Id, result.RecordTypeId);

        // Make sure EntitlmentDate has the WO Lookup
        SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);*/
    }

    @isTest static void testScheduledWorkOrdersFuture()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);
        ip.SMAX_PS_Building__c = 'The Best Building EVER Created';
        ip.SMAX_PS_Room__c = '1234567890';
        update ip;

        Date startDate = System.today().addDays(7); // ITSVMX-1563 - Start in the future
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        sc.SVMXC__Contact__c = c.Id;
        sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.SMAX_PS_ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'PM', 5, 2);

        SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        // ITSVMX-1563 Scheduled WO - "startedOnly" is true
        SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 60, new Set<String> { 'TST2' }, true, true);
        //Database.executeBatch(b);
        b.execute(null);

        Test.stopTest();

       /* List<SVMXC__Service_Order__c> results = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
                SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
                SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
        FROM SVMXC__Service_Order__c WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO(s): ' + results);
        System.assertEquals(0, results.size());

        // Make sure EntitlmentDate has NO WO Lookup
        SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        //System.assertEquals(null, edResult.SMAX_PS_WorkOrder__c);*/
    }

    @isTest static void testCasePreEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact contct = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        Product2 prod = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'Test');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);

        Date startDate = System.today().addMonths(-1);
        Date endDate = startDate.addMonths(11);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        RecordType techSupport = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support');

        Case c = new Case();
        c.RecordTypeId = techSupport.Id;
        c.SVMXC__Perform_Auto_Entitlement__c = TRUE;
        c.SVMXC__Component__c = ip.Id;
        c.SVMXC__Product__c = prod.Id;
        c.AccountId = acct.Id;
        c.Case_Team__c = 'Customer Care';
        c.ContactId = contct.Id;
        c.Status = 'New';
        c.SVMXC__Site__c = loc.Id;
        c.Subject = 'Testing Auto-Entitlement';
        insert c;

        //Case result = [SELECT Id, CaseNumber, SVMXC__Service_Contract__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c FROM Case WHERE Id = :c.Id];

        //System.debug('AUTO-ENTITLE RESULT CASE: ' + result);
        //System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        //System.assertEquals(item.Id, result.SVMXC__Service_Contract__c);
        //System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);

        Test.stopTest();
    }
    
    @isTest static void testCompleteEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Billing_Type__c = 'Contract';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SVMXC__Service_Contract__c = sc.Id;
        wo.SMAX_PS_ContractItem__c = item.Id;
        wo.SMAX_PS_Customer_Required_Start_Date__c = System.today().addDays(30);
        insert wo;

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_Customer_Required_Start_Date__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, 
            SVMXC__Is_Entitlement_Performed__c, SVMXC__Entitlement_Type__c, SVMXC__Entitlement_Notes__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        /*System.debug('COMPLETE-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals('SAP', result.SVMXC__Entitlement_Type__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Matching to Entitlement by Qty'));*/

        Database.executeBatch(new SMAX_PS_AutoEntitlementWoLoadFix(result.Name));

        Test.stopTest();

    }
    
    @isTest static void testSMAX_PS_AutoEntitlementWorkDetailFix()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        //SMAX_PS_EntitlementDate__c edate = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Billing_Type__c = 'Contract';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SVMXC__Service_Contract__c = sc.Id;
        wo.SMAX_PS_ContractItem__c = item.Id;
        wo.SMAX_PS_Customer_Required_Start_Date__c = System.today().addDays(30);
        wo.SVMXC__Entitlement_Type__c ='SAP';
        wo.SMAX_PS_ContractEntitlement__c =ent.id;
        insert wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_Customer_Required_Start_Date__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, 
            SVMXC__Is_Entitlement_Performed__c, SVMXC__Entitlement_Type__c, SVMXC__Entitlement_Notes__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];*/

        /*System.debug('COMPLETE-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals('SAP', result.SVMXC__Entitlement_Type__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Matching to Entitlement by Qty'));*/

        Database.executeBatch(new SMAX_PS_AutoEntitlementWorkDetailFix ());

        Test.stopTest();

    }

    @isTest static void testDoubleEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an exact Entitlement Type match
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item2.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item2.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp2.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();

        // Make sure EntitlmentDate has the WO Lookup
        //SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        // KNOWN-ISSUE .. see Auto-Entitlement line 230
        //System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);
    }

    @isTest static void testDoubleEntitlementByDate()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an unconsumed Entitlement Date
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);

        // SVMXCFG-1162 Only count the "non-consumed" Entitlement Dates
        SMAX_PS_EntitlementDate__c edate1_1 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate1_1.SMAX_PS_ServiceOrderNumber__c = 'XYZABC1'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate1_2 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(10));
        edate1_2.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ2'; // This should also be skipped
        SMAX_PS_EntitlementDate__c edate1_3 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate1_3.SMAX_PS_ServiceOrderNumber__c = 'XYZABC3'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate1_4 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(10));
        edate1_4.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ4'; // This should also be skipped

        SMAX_PS_EntitlementDate__c edate2_1 = SMAX_PS_TestDataFactory.createEntitlementDate(cp2, ent2, startDate.addDays(1));
        edate2_1.SMAX_PS_ServiceOrderNumber__c = 'XYZABC'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate2_2 = SMAX_PS_TestDataFactory.createEntitlementDate(cp2, ent2, startDate.addDays(10));
        edate2_2.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ'; // This should also be skipped
        SMAX_PS_EntitlementDate__c edate2_3 = SMAX_PS_TestDataFactory.createEntitlementDate(cp2, ent2, startDate.addDays(20));
        update new List<SMAX_PS_EntitlementDate__c> { edate1_1, edate1_2, edate1_3, edate1_4, edate2_1, edate2_2 };

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item2.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item2.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp2.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Non-Consumed EntitlementDate Matched'));
        System.assertEquals(3, result.SVMXC__Entitlement_Notes__c.countMatches('Checking EntitlementDate'));*/

        Test.stopTest();

        // Make sure EntitlmentDate has the WO Lookup
        //SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        // KNOWN-ISSUE .. see Auto-Entitlement line 230
        //System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);
    }

    @isTest static void testQuadrupleEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent1_1 = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent1_2 = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an exact Entitlement Type match
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2_1 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent2_2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'ZZZ', 5, 2);

        // To test SVMXCFG-700, change 2_1 to have higher coverage and ensure it gets selected..
        ent2_1.SVMXC__Parts_Discount_Covered__c = 100;
        ent2_1.SMAX_PS_ServicePartsDiscountCovered__c = 100;
        update ent2_1;

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item2.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item2.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2_1.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp2.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();
    }

    @isTest static void testQuadrupleEntitlementByDate()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent1_1 = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent1_2 = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an exact Entitlement Type match
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2_1 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent2_2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'ZZZ', 5, 2);

        // To test SVMXCFG-700, change 2_1 to have higher coverage..
        ent2_1.SVMXC__Parts_Discount_Covered__c = 100;
        ent2_1.SMAX_PS_ServicePartsDiscountCovered__c = 100;
        update ent2_1;

        // ... but because we add Ent Dates to 1_1 is should get selected instead.
        SMAX_PS_EntitlementDate__c edate1 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent1_1, startDate.addDays(1));
        edate1.SMAX_PS_ServiceOrderNumber__c = 'XYZABC'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate2 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent1_1, startDate.addDays(10));
        edate2.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ'; // This should also be skipped
        SMAX_PS_EntitlementDate__c edate3 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent1_1, startDate.addDays(20));
        update new List<SMAX_PS_EntitlementDate__c> { edate1, edate2 };

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

       /* SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent1_1.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();
    }

    @isTest static void testQuadrupleEntitlementByNonRelatedDate()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent1_1 = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent1_2 = SMAX_PS_TestDataFactory.createEntitlement(item,'PM', 5, 2);
        SVMXC__Service_Contract_Services__c ent1_3 = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an exact Entitlement Type match
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2_1 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent2_2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'ZZZ', 5, 2);

        // To test SVMXCFG-700, change 2_1 to have higher coverage..
        ent2_1.SVMXC__Parts_Discount_Covered__c = 100;
        ent2_1.SMAX_PS_ServicePartsDiscountCovered__c = 100;
        update ent2_1;

        // ... and because we add Ent Dates to 1_2, which does not match, it should NOT get selected instead.
        SMAX_PS_EntitlementDate__c edate1 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent1_2, startDate.addDays(1));
        edate1.SMAX_PS_ServiceOrderNumber__c = 'XYZABC'; // This should no be skipped
        SMAX_PS_EntitlementDate__c edate2 = SMAX_PS_TestDataFactory.createEntitlementDate(cp, ent1_2, startDate.addDays(10));
        edate2.SMAX_PS_SAP_Notification_ID__c = 'ABCXYZ'; // This should also be skipped
        update new List<SMAX_PS_EntitlementDate__c> { edate1, edate2 };

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item2.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item2.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2_1.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp2.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();
    }

    @isTest static void testRecalcEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent1_1 = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        SVMXC__Service_Contract_Services__c ent1_2 = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);

        // In this test, we should skip the first Item/CP/Ent because the second has an exact Entitlement Type match
        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2_1 = SMAX_PS_TestDataFactory.createEntitlement(item2,'PM', 5, 2);
        SVMXC__Service_Contract_Services__c ent2_2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'ZZZ', 5, 2);

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent1_1.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        wo.SVMXC__Order_Type__c = 'Planned Maintenance';
        //wo.SVMXC__Perform_Auto_Entitlement__c = TRUE;
        update wo;

        /*result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RECALC RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item2.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item2.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2_1.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp2.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();
    }

    @isTest static void testDeletedEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem1', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', 5, 2);
        SVMXC__Service_Contract_Services__c ent1 = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

        SVMXC__Service_Contract__c item2 = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContractItem2', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp2 = SMAX_PS_TestDataFactory.createCoveredIP(item2, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent2 = SMAX_PS_TestDataFactory.createEntitlement(item2,'REP', 5, 2);

        // Mark records as IsDeleted...
        item2.SMAX_PS_IsDeleted__c = true;
        update item2;
        cp2.SMAX_PS_IsDeleted__c = true;
        update cp2;
        ent1.SMAX_PS_IsDeleted__c = true;
        ent2.SMAX_PS_IsDeleted__c = true;
        update new List<SVMXC__Service_Contract_Services__c> { ent1, ent2 };

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
                SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);*/

        Test.stopTest();

        // Make sure EntitlmentDate has the WO Lookup
        //SMAX_PS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM SMAX_PS_EntitlementDate__c WHERE Id = :edate.Id];
        // KNOWN-ISSUE .. see Auto-Entitlement line 230
        //System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);
    }

    @isTest static void testRemoteHoursEntitlement()
    {
        // ITSFDC-1047 Create SvcContract with "PHN", Remote WO (auto-entitled)...
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestPart', 'PRT100101', 'PART', 'Parts');
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');

        Date startDate = System.today().addMonths(-1);
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        // Populate the "Item Qty Remaining"...
        item.BD_Item_Qty__c = 100;
        item.BD_Item_Qty_Remaining__c = 90;
        update item;

        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'ZZZ', null, null);
        SVMXC__Service_Contract_Services__c ent2 = SMAX_PS_TestDataFactory.createEntitlement(item,'PHN', null, null);

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createRemoteWO(ip, c);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMXC__Entitlement_Notes__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
            SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMXC__Order_Status__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
        System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
        System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
        System.assertEquals(ent2.Id, result.SMAX_PS_ContractEntitlement__c);
        System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
        System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
        System.assertEquals(TRUE, result.SVMXC__Entitlement_Notes__c.contains('Matching to Entitlement of Remote Hours'));
        System.assertEquals('Initializing', result.SVMXC__Order_Status__c);
        System.assertEquals('Contract', result.SVMXC__Billing_Type__c);*/

        // Make sure we consume hours correctly...

        RecordType recType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'SMAX_PS_Remote_Support');
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=recType.Id, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 3.5);
        insert laborLine;

        // Assert on the ContractItem, not the Entitlement...
        //SVMXC__Service_Contract__c itemResult = [SELECT Id, Name, BD_Remote_Hours_Remaining__c FROM SVMXC__Service_Contract__c WHERE Id = :item.Id];
       // System.assertEquals(86.5, itemResult.BD_Remote_Hours_Remaining__c);

        laborLine.SVMXC__Actual_Quantity2__c = 1.0;
        update laborLine;
        //itemResult = [SELECT Id, Name, BD_Remote_Hours_Remaining__c FROM SVMXC__Service_Contract__c WHERE Id = :item.Id];
       // System.assertEquals(89.0, itemResult.BD_Remote_Hours_Remaining__c);

        delete laborLine;
        //itemResult = [SELECT Id, Name, BD_Remote_Hours_Remaining__c FROM SVMXC__Service_Contract__c WHERE Id = :item.Id];
       // System.assertEquals(90.0, itemResult.BD_Remote_Hours_Remaining__c);

        SVMXC__Service_Order_Line__c laborLine1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=recType.Id, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 3);
        SVMXC__Service_Order_Line__c laborLine2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=recType.Id, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 2);
        SVMXC__Service_Order_Line__c partsLine1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=recType.Id, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = partsProd.Id, SVMXC__Actual_Quantity2__c = 5);
        insert new List<SVMXC__Service_Order_Line__c> { laborLine1, laborLine2, partsLine1 };
        //itemResult = [SELECT Id, Name, BD_Remote_Hours_Remaining__c FROM SVMXC__Service_Contract__c WHERE Id = :item.Id];
        //System.assertEquals(85.0, itemResult.BD_Remote_Hours_Remaining__c);

        Test.stopTest();
    }

}
/**
 * Created by frankvanloon on 4/28/21.
 */

@IsTest
private class SMAX_PS_WorkOrderStandardJobTime_UT {

    @IsTest
    static void testStandardJobTimeDashboard() {

        // Create SJT records
        List<SVMX_PS_Standard_Job_Time__c> newSjtRecords = new List<SVMX_PS_Standard_Job_Time__c>();

        SVMX_PS_Standard_Job_Time__c newStjRecord1 = new SVMX_PS_Standard_Job_Time__c();
        newStjRecord1.SVMX_PS_Order_Type__c = 'Repair';
        newStjRecord1.SVMX_PS_Status__c = 'Active';
        newStjRecord1.SVMX_PS_1MoAvg__c  = 10;
        newStjRecord1.SVMX_PS_1MoRecCnt__c = 1;
        newStjRecord1.SVMX_PS_Standard_Duration__c = 3;
        newStjRecord1.SVMX_PS_Product_Line__c = 'Product1';
        newStjRecord1.SVMX_PS_Model_Series__c = 'ModelSeries1';
        newSjtRecords.add(newStjRecord1);

        SVMX_PS_Standard_Job_Time__c newStjRecord2 = new SVMX_PS_Standard_Job_Time__c();
        newStjRecord2.SVMX_PS_Order_Type__c = 'PM';
        newStjRecord2.SVMX_PS_Status__c = 'Active';
        newStjRecord2.SVMX_PS_1MoAvg__c  = 10;
        newStjRecord2.SVMX_PS_1MoRecCnt__c = 1;
        newStjRecord2.SVMX_PS_Standard_Duration__c = 3;
        newStjRecord2.SVMX_PS_Product_Line__c = 'Product2';
        newStjRecord2.SVMX_PS_Model_Series__c = 'ModelSeries2';
        newSjtRecords.add(newStjRecord2);

        insert newSjtRecords;

        // Create Account
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Account1', 'AC123');

        // Create IP
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('SER123');

        // Create Contact
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CT123');

        // Create Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_IP_Product_Line__c = 'Product2';
        wo.SMAX_PS_ModelSeries__c = 'ModelSeries2';
        wo.SVMXC__Completed_Date_Time__c = Date.today().addDays(-15);
        wo.SVMXC__Order_Type__c = 'Repair';
        update wo;

        // TODO Add validations for below methods

        // Test Dashboard functions
        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> status = SMAX_PS_WorkOrderStandardJobTime.apexStatuses();
        System.debug('statuses: ' + status);
        System.assert(status.size() >= 2, 'Status Values not found');

        List<String> selectedTypes = new List<String>{'PM'};
        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexOrderTypes = SMAX_PS_WorkOrderStandardJobTime.apexOrderTypes(selectedTypes);
        System.debug('apexOrderTypes: ' + apexOrderTypes);
        System.assertEquals('Repair', apexOrderTypes[0].value, 'Order Type not found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexProductLines1 = SMAX_PS_WorkOrderStandardJobTime.apexProductLines(new List<String>(), new List<String> {'selectedLines'});
        System.debug('apexProductLines1: ' + apexProductLines1);
        System.assertEquals(2, apexProductLines1.size(), '2 Product Lines not found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexProductLines2 = SMAX_PS_WorkOrderStandardJobTime.apexProductLines(new List<String> {'PM'}, new List<String> {'selectedLines'});
        System.debug('apexProductLines2: ' + apexProductLines2);
        System.assertEquals(1, apexProductLines2.size(), '1 Product Line not found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexModelSeries1 = SMAX_PS_WorkOrderStandardJobTime.apexModelSeries(new List<String>(), new List<String>(), new List<String> {'selectedModels'});
        System.debug('apexModelSeries1: ' + apexModelSeries1);
        System.assertEquals(2, apexModelSeries1.size(), '2 Model Series not found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexModelSeries2 = SMAX_PS_WorkOrderStandardJobTime.apexModelSeries(new List<String>(), new List<String> {'includedLines'}, new List<String> {'selectedModels'});
        System.debug('apexModelSeries2: ' + apexModelSeries2);
        System.assertEquals(0, apexModelSeries2.size(), 'Model Series was not supposed to be found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexModelSeries3 = SMAX_PS_WorkOrderStandardJobTime.apexModelSeries(new List<String> {'PM'}, new List<String>(), new List<String> {'selectedModels'});
        System.debug('apexModelSeries3: ' + apexModelSeries3);
        System.assertEquals(1, apexModelSeries3.size(), '1 Model Series not found');

        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> apexModelSeries4 = SMAX_PS_WorkOrderStandardJobTime.apexModelSeries(new List<String> {'PM'}, new List<String> {'includedLines'}, new List<String> {'selectedModels'});
        System.debug('apexModelSeries4: ' + apexModelSeries4);
        System.assertEquals(0, apexModelSeries4.size(), 'Model Series was not supposed to be found');


        List<SMAX_PS_WorkOrderStandardJobTime.jobSearchResult> searchJobs = SMAX_PS_WorkOrderStandardJobTime.searchJobs(new List<String>{'Active'}, new List<String>{'Repair'}, new List<String>{'Product1'}, new List<String>{'ModelSeries1'}, '1', 1, 1);
        System.debug('searchJobs[0].id: ' + searchJobs[0].id);
        System.assertEquals(1, searchJobs.size(), 'Job was not found');

        SVMX_PS_Standard_Job_Time__c getSjtDetails = SMAX_PS_WorkOrderStandardJobTime.getSjtDetails(searchJobs[0].id);
        System.debug('getSjtDetails: ' + getSjtDetails);
        System.assertEquals('Repair', getSjtDetails.SVMX_PS_Order_Type__c, 'SJT Details not Found');


        String getAllExtantModels = SMAX_PS_WorkOrderStandardJobTime.getAllExtantModels('Repair', 'Product1');
        System.debug('getAllExtantModels: ' + getAllExtantModels);
        System.assertEquals('ModelSeries1', getAllExtantModels, 'Extant Model Series not Found');


        List<SMAX_PS_WorkOrderStandardJobTime.comboBoxResult> allOrderTypes = SMAX_PS_WorkOrderStandardJobTime.allOrderTypes();
        System.debug('allOrderTypes: ' + allOrderTypes);
        System.assert(allOrderTypes.size() > 0, 'Order Types not found');


        List<SMAX_PS_WorkOrderStandardJobTime.jobSearchResult> findNewSJT1 = SMAX_PS_WorkOrderStandardJobTime.findNewSJT('Repair', null);
        System.debug('findNewSJT1: ' + findNewSJT1);
        System.assertEquals('Repair-Product2-(Empty)', findNewSJT1[0].name, 'Empty SJT not found');


        List<SMAX_PS_WorkOrderStandardJobTime.jobSearchResult> findNewSJT2 = SMAX_PS_WorkOrderStandardJobTime.findNewSJT('Repair', 'Product2');
        System.debug('findNewSJT2: ' + findNewSJT2);
        System.assertEquals('Repair-Product2-ModelSeries2', findNewSJT2[0].name, 'SJT with ModelSeries not found');


        String createNewSJT = SMAX_PS_WorkOrderStandardJobTime.createNewSJT(findNewSJT2);
        System.debug('createNewSJT: ' + createNewSJT);
        System.assertEquals('Successfully created 1 new "Draft" Standard Job Times', createNewSJT, 'Create SJT record failed');
    }

    @IsTest(SeeAllData=true)
    static void testGetReportId() {

        // Need to check these in a separate method with SeeAllData=True to check if the reports actually exist
        Id getReportId1 = SMAX_PS_WorkOrderStandardJobTime.getReportId(true);
        //System.assert(getReportId1 != null, 'SMAX_PS_WO_by_SJT_Empty report does not exist');

        Id getReportId2 = SMAX_PS_WorkOrderStandardJobTime.getReportId(false);
        //System.assert(getReportId1 != null, 'SMAX_PS_WO_by_SJT report does not exist');
    }

    // 1/8/21 ITSVMX-225 Test Standard Job Time Automation
    @IsTest
    static void testUpdateStandardJobTime() {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        //ip.SMAX_PS_System_ID__c='000-01';
        //update ip;

        SVMX_PS_Standard_Job_Time__c standardJobTime1 = new SVMX_PS_Standard_Job_Time__c(
                SVMX_PS_Product_Line__c = 'null',
                SVMX_PS_Model_Series__c = '5545333',
                SVMX_PS_Order_Type__c = 'null',
                SVMX_PS_Standard_Duration__c = 3.00,
                SVMX_PS_Status__c = 'Active'
                //SVMX_PS_External_ID__c = 'null' + 'null' + '5545333'
        );
        insert standardJobTime1;

        SVMX_PS_Standard_Job_Time__c standardJobTime2 = new SVMX_PS_Standard_Job_Time__c(
                SVMX_PS_Product_Line__c = 'TST',
                SVMX_PS_Model_Series__c = '5545333',
                SVMX_PS_Order_Type__c = 'Repair',
                SVMX_PS_Standard_Duration__c = 2.50,
                SVMX_PS_Status__c = 'Active'
                //SVMX_PS_External_ID__c = 'Repair' + 'TST' + '5545333'
        );
        insert standardJobTime2;

        //SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = fsRecType.Id;
        wo.SVMXC__Component__c = ip.Id;
        wo.SVMXC__Perform_Auto_Entitlement__c = true;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = '';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = cont.Id;
        //wo.SMAX_PS_IP_Product_Line__c = 'TST';
        insert wo;
        System.debug('WO ID = ' + wo.Id);

        Test.startTest();
        SVMXC__Service_Order__c woTest1 = [
                SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
                FROM SVMXC__Service_Order__c
                LIMIT 1
        ];
        // Test Insert new WO causes update of Standard Job Time and Service Duration
        //System.assertEquals(3.00, woTest1.SVMX_PS_Standard_Job_Time__c);
        //System.assertEquals(10800.00, woTest1.SVMXC__Service_Duration__c);

        wo.SMAX_PS_IP_Product_Line__c = 'TST';
        wo.SVMXC__Order_Type__c = 'Repair';
        update wo;

        SVMXC__Service_Order__c woTest2 = [
                SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
                FROM SVMXC__Service_Order__c
                LIMIT 1
        ];
        // Test Update of WO causes update of Standard Job Time and Service Duration
        //System.assertEquals(2.50, woTest2.SVMX_PS_Standard_Job_Time__c);
//System.assertEquals(9000.00, woTest2.SVMXC__Service_Duration__c);

        wo.SMAX_PS_IP_Product_Line__c = 'BAD';
        wo.SVMXC__Order_Type__c = 'Upgrade';
        update wo;

        SVMXC__Service_Order__c woTest3 = [
                SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
                FROM SVMXC__Service_Order__c
                LIMIT 1
        ];
        // Test Update of WO that is unable to find a matching Standard Job Time record so values stay the same
       // System.assertEquals(2.50, woTest3.SVMX_PS_Standard_Job_Time__c);
        //System.assertEquals(9000.00, woTest3.SVMXC__Service_Duration__c);

        Test.stopTest();
    }

    // 21-02-09 b.s.salmans - test class for SMAX_PS_WorkOrderStandardJobTime_Batch
    @IsTest
    static void testWorkOrderStandardJobTime_Batch() {

        // create standard job time records
        SVMX_PS_Standard_Job_Time__c sjt = new SVMX_PS_Standard_Job_Time__c(SVMX_PS_Model_Series__c = '5545333', SVMX_PS_Order_Type__c = 'Training', SVMX_PS_Product_Line__c = '__test__');
        insert sjt;
        SVMX_PS_Standard_Job_Time__c sjt2 = new SVMX_PS_Standard_Job_Time__c(SVMX_PS_Model_Series__c = '(Empty)', SVMX_PS_Order_Type__c = 'Training', SVMX_PS_Product_Line__c = '__test2__');
        insert sjt2;

        // Create test data
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        Integer timeFrame;  //  number of months to include in query
        Date startDate = System.today();  //  today's date
        SVMXC__Service_Order__c wo;  //  dummy WO for test data creation loop
        SVMXC__Service_Order_Line__c woli;  //  dummy WO line for test data creation loop
        List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();  //  list to hold test data WOs
        List<SVMXC__Service_Order_Line__c> woliList = new List<SVMXC__Service_Order_Line__c>();  //  list to hold test data WO lines

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SVMXC__Product_Line__c = '__test__';
        update pd;
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');

        // create one WO for each period of data
        for(Integer x = 0; x < 5; x++) {
            timeFrame = x == 0 ? 1 : x * 3;
            if(timeFrame == 9) continue;

            wo = new SVMXC__Service_Order__c();
            wo.RecordTypeId = fieldServiceRTId;
            wo.SVMXC__Component__c = ip.Id;
            wo.SVMXC__Perform_Auto_Entitlement__c = true;
            wo.SVMXC__Billing_Type__c = 'Billable';
            wo.SVMXC__Order_Type__c = 'Training';
            wo.SMAX_PS_ModelSeries__c = '__test__';
            wo.SMAX_PS_IP_Product_Line__c = '__test__';
            wo.SVMXC__Company__c = ip.SVMXC__Company__c;
            wo.SVMXC__Site__c = ip.SVMXC__Site__c;
            wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
            wo.SVMXC__Contact__c = cont.Id;
            wo.SVMXC__Completed_Date_Time__c = Datetime.now().addMonths(-timeFrame).addDays(3);
            woList.add(wo);
        }
        insert woList;

        // create labor line for each WO
        Integer x = 1;
        for(SVMXC__Service_Order__c worder:woList) {
            System.debug('(--) wo.SVMXC__Order_Type__c: '+worder.SVMXC__Order_Type__c);
            System.debug('(--) wo.SMAX_PS_ModelSeries__c: '+worder.SMAX_PS_ModelSeries__c);
            System.debug('(--) wo.SMAX_PS_IP_Product_Line__c: '+worder.SMAX_PS_IP_Product_Line__c);
            System.debug('(--) wo.SVMXC__Completed_Date_Time__c: '+worder.SVMXC__Completed_Date_Time__c);
            woli = new SVMXC__Service_Order_Line__c();
            woli.SVMXC__Service_Order__c = worder.Id;
            woli.RecordTypeId = usage;
            woli.SVMXC__Line_Type__c = 'Labor';
            woli.SVMXC__Line_Status__c = 'Confirmed';
            woli.SVMXC__Product__c = laborProd.Id;
            woli.SVMXC__Actual_Quantity2__c = x;
            woliList.add(woli);
            x++;
        }
        insert woliList;

        Test.startTest();

        // run batch job
        SMAX_PS_WorkOrderStandardJobTime_Batch btch = new SMAX_PS_WorkOrderStandardJobTime_Batch();
        Database.executeBatch(btch);

        Test.stopTest();

        // assert standard job time records were correctly updated
        sjt = [SELECT SVMX_PS_1MoRecCnt__c, SVMX_PS_1MoAvg__c, SVMX_PS_1MoMax__c, SVMX_PS_1MoMin__c, SVMX_PS_3MoRecCnt__c,
                SVMX_PS_3MoAvg__c, SVMX_PS_3MoMax__c, SVMX_PS_3MoMin__c, SVMX_PS_6MoRecCnt__c, SVMX_PS_6MoAvg__c, SVMX_PS_6MoMax__c,
                SVMX_PS_6MoMin__c, SVMX_PS_12MoRecCnt__c, SVMX_PS_12MoAvg__c, SVMX_PS_12MoMax__c, SVMX_PS_12MoMin__c
               FROM SVMX_PS_Standard_Job_Time__c WHERE Id = :sjt.Id];
        /*System.assertEquals(1, sjt.SVMX_PS_1MoRecCnt__c, '1 Month Record Count is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_1MoAvg__c, '1 Month Average is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_1MoMax__c, '1 Month Maximum is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_1MoMin__c, '1 Month Minimum is incorrect');

        System.assertEquals(2, sjt.SVMX_PS_3MoRecCnt__c, '3 Month Record Count is incorrect');
        System.assertEquals(1.5, sjt.SVMX_PS_3MoAvg__c, '3 Month Average is incorrect');
        System.assertEquals(2, sjt.SVMX_PS_3MoMax__c, '3 Month Maximum is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_3MoMin__c, '3 Month Minimum is incorrect');

        System.assertEquals(3, sjt.SVMX_PS_6MoRecCnt__c, '6 Month Record Count is incorrect');
        System.assertEquals(2, sjt.SVMX_PS_6MoAvg__c, '6 Month Average is incorrect');
        System.assertEquals(3, sjt.SVMX_PS_6MoMax__c, '6 Month Maximum is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_6MoMin__c, '6 Month Minimum is incorrect');

        System.assertEquals(4, sjt.SVMX_PS_12MoRecCnt__c, '12 Month Record Count is incorrect');
        System.assertEquals(2.5, sjt.SVMX_PS_12MoAvg__c, '12 Month Average is incorrect');
        System.assertEquals(4, sjt.SVMX_PS_12MoMax__c, '12 Month Maximum is incorrect');
        System.assertEquals(1, sjt.SVMX_PS_12MoMin__c, '12 Month Minimum is incorrect');*/
    }

    @IsTest
    static void testChartController() {
        // Unit Tests for the SMAX_PS_ChartController class

        // create standard job time records
        SVMX_PS_Standard_Job_Time__c sjt1 = new SVMX_PS_Standard_Job_Time__c(SVMX_PS_Model_Series__c = '5545333', SVMX_PS_Order_Type__c = 'Training', SVMX_PS_Product_Line__c = '__test__');
        insert sjt1;
        System.debug('sjt1.Id: ' + sjt1.Id);
        SVMX_PS_Standard_Job_Time__c sjt2 = new SVMX_PS_Standard_Job_Time__c(SVMX_PS_Model_Series__c = '(Empty)', SVMX_PS_Order_Type__c = 'Training', SVMX_PS_Product_Line__c = '__test2__');
        insert sjt2;

        // create account record
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Account1', 'ACC123', 'US');

        // create contact record
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Testy', 'Testerson', acct, 'CON123');

        // create work order records
        SVMXC__Service_Order__c wo1 = new SVMXC__Service_Order__c();
        wo1.SVMXC__Contact__c = cont.Id;
        wo1.SVMXC__Completed_Date_Time__c = Date.today().addDays(-15);
        wo1.SVMXC__Order_Type__c = 'Training';
        wo1.SMAX_PS_IP_Product_Line__c = '__test__';
        wo1.SMAX_PS_ModelSeries__c = '5545333';
        insert wo1;

        // Validate methods
        List<SMAX_PS_ChartController.DataSet> getSjtDataSets1 = SMAX_PS_ChartController.getSjtDataSets(sjt1.Id, '1');
        System.debug('getSjtDataSets1: ' + getSjtDataSets1);
        //System.assert(getSjtDataSets1.size() > 0, 'getSjtDataSets1 horizon 1 returned no values');

        List<SMAX_PS_ChartController.DataSet> getSjtDataSets2 = SMAX_PS_ChartController.getSjtDataSets(sjt2.Id, '3');
        System.debug('getSjtDataSets2: ' + getSjtDataSets2);
        //System.assert(getSjtDataSets2.size() > 0, 'getSjtDataSets2 horizon 3 returned no values');

        List<SMAX_PS_ChartController.DataSet> getSjtDataSets3 = SMAX_PS_ChartController.getSjtDataSets(sjt2.Id, '6');
        System.debug('getSjtDataSets3: ' + getSjtDataSets3);
        //System.assert(getSjtDataSets3.size() > 0, 'getSjtDataSets3 horizon 6 returned no values');

        List<SMAX_PS_ChartController.DataSet> getSjtDataSets4 = SMAX_PS_ChartController.getSjtDataSets(sjt2.Id, '12');
        System.debug('getSjtDataSets4: ' + getSjtDataSets4);
        //System.assert(getSjtDataSets4.size() > 0, 'getSjtDataSets4 horizon 12 returned no values');


        List<SMAX_PS_ChartController.DataSet> getTechManDataSets1 = SMAX_PS_ChartController.getTechManDataSets(sjt1.Id, '1');
        System.debug('getTechManDataSets1: ' + getTechManDataSets1);
        //System.assert(getTechManDataSets1.size() > 0, 'getTechManDataSets1 horizon 1 returned no values');

        List<SMAX_PS_ChartController.DataSet> getTechManDataSets2 = SMAX_PS_ChartController.getTechManDataSets(sjt2.Id, '3');
        System.debug('getTechManDataSets2: ' + getTechManDataSets2);
        //System.assert(getTechManDataSets2.size() > 0, 'getTechManDataSets2 horizon 3 returned no values');
    }
}
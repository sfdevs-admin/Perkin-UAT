/**
 * Test Class for  SMAX_PS_WorkDetailManager
 * Client      :   PerkinElmer
 * Created by  :   Veerendra on 2017-10-12
 *
 * <--- Updates --->
 * 06/20/2022   Tony    ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
 *
*/

@isTest(seeAllData=false)
public class SMAX_PS_WorkDetail_UT
{
    static testMethod void createWorkOrderEventTestData()
    {
        // Insert Account
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000001');
        // Insert Contact
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        // Insert Location
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // Insert Work Detail
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Status__c='Open');
        insert wd;

        // Update Work Detail
        wd.SVMXC__Line_Status__c='Submitted';
        update wd;

        // [ITSFDC-89] Default the DiscoutType fields to 'Uplift' if not specified
        wd.SMAX_PS_ServiceAmountAdjustment__c = 100;
        wd.SMAX_PS_ServicePercentAdjustment__c = 10;
        update wd;

        SVMXC__Service_Order_Line__c result = [SELECT Id, Name,
                SMAX_PS_ServiceAmountAdjustmentType__c, SMAX_PS_ServicePercentAdjustmentType__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :wd.Id];
        //System.assertEquals('Uplift', result.SMAX_PS_ServiceAmountAdjustmentType__c);
        //System.assertEquals('Uplift', result.SMAX_PS_ServicePercentAdjustmentType__c);

    }

    static testMethod void updateIntegrationStatusTestData()
    {
        // Insert Account
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000002');
        // Insert Contact
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        // Insert Location
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // Insert Work Detail
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Status__c='Open');
        insert wd;

        // Update Work Detail
        wd.SMAX_PS_SAP_Confirmation__c='Test';
        update wd;
    }


    static testMethod void testUOM()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000003');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');
        loc.SMAX_PS_SalesOrg__c = 'TT11';
        update loc;
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        Product2 prod1 = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', 'TST0001', 'TEST', 'Parts', 'PK', 'KP');
        Product2 prod2 = SMAX_PS_TestDataFactory.createTestProduct('TestProduct2', 'TST0002', 'TEST', 'Parts', 'PK', 'KP');
        Product2 prod3 = SMAX_PS_TestDataFactory.createTestProduct('TestProduct3', 'TST0003', 'TEST', 'Parts', 'PK', 'KP');

        // One with no Product Sales, one with no UOM on PS, one good
        SMAX_PS_ProductSales__c ps1 = new SMAX_PS_ProductSales__c(SMAX_PS_SalesOrg__c = 'TT11', SMAX_PS_Product__c = prod1.Id,
                SMAX_PS_SalesUnit__c = 'PC', SMAX_PS_Sales_Unit_Code__c = 'CP');
        SMAX_PS_ProductSales__c ps2 = new SMAX_PS_ProductSales__c(SMAX_PS_SalesOrg__c = 'TT11', SMAX_PS_Product__c = prod2.Id,
                SMAX_PS_SalesUnit__c = null, SMAX_PS_Sales_Unit_Code__c = null);
        insert new List<SMAX_PS_ProductSales__c> { ps1, ps2 };

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = prod1.Id, SVMXC__Actual_Quantity2__c = 1, SMAX_PS_Use_Product_Sales_UOM__c = TRUE);
        SVMXC__Service_Order_Line__c line2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = prod2.Id, SVMXC__Actual_Quantity2__c = 1, SMAX_PS_Use_Product_Sales_UOM__c = TRUE);
        SVMXC__Service_Order_Line__c line3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = prod3.Id, SVMXC__Actual_Quantity2__c = 1, SMAX_PS_Use_Product_Sales_UOM__c = TRUE);
        insert new List<SVMXC__Service_Order_Line__c> { line1, line2, line3 };

        Map<Id, SVMXC__Service_Order_Line__c> lineMap = new Map<Id, SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c line : [SELECT Id, Name, SVMXC__Product__c,
                SMAX_PS_UnitOfMeasure__c, SMAX_PS_UOM_Code__c, SMAX_PS_Use_Product_Sales_UOM__c
        FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id])
            lineMap.put(line.SVMXC__Product__c, line);

        // Verify: SMAX_PS_UnitOfMeasure__c, SMAX_PS_UOM_Code__c
        line1 = lineMap.get(prod1.Id);
        //System.assertEquals(TRUE, line1.SMAX_PS_Use_Product_Sales_UOM__c);
       // System.assertEquals(ps1.SMAX_PS_Sales_Unit_Code__c, line1.SMAX_PS_UOM_Code__c);

        line2 = lineMap.get(prod2.Id);
        //System.assertEquals(FALSE, line2.SMAX_PS_Use_Product_Sales_UOM__c);
        //System.assertEquals(prod2.PKI_Qty_UOM_Code__c, line2.SMAX_PS_UOM_Code__c);

        line3 = lineMap.get(prod3.Id);
        //System.assertEquals(FALSE, line3.SMAX_PS_Use_Product_Sales_UOM__c);
        //System.assertEquals(prod3.PKI_Qty_UOM_Code__c, line3.SMAX_PS_UOM_Code__c);

    }

    static testMethod void testFaultCodes()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000004','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        ip.SMAX_PS_CatalogProfile__c = 'TCP';
        update ip;
        SMAX_PS_HSI_Settings__c hsi = SMAX_PS_TestDataFactory.createHSICustomSetting('GB','MFT');  // Should force HSI rules

        // Fault Code data
        SMAX_PS_Catalog_Profile__c catProf = new SMAX_PS_Catalog_Profile__c(Name = 'TCP',
                SMAX_PS_Catalog_Profile__c = 'TCP', SMAX_PS_Code_Family__c = 'TFAM');
        insert catProf;

        SMAX_PS_Fault_Code__c fc = SMAX_PS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', TRUE);
        SMAX_PS_Fault_Code__c jc = SMAX_PS_TestDataFactory.createTestFaultCode('SVC', 'SVC-JC1', 'JC01', 'Job Completed', TRUE);
        SMAX_PS_Fault_Code__c ac = SMAX_PS_TestDataFactory.createTestFaultCode('SVC', 'SVC-AC1', 'AC01', 'Advised', TRUE);
        SMAX_PS_Fault_Code__c ic = SMAX_PS_TestDataFactory.createTestFaultCode('SVC', 'SVC-IN1', 'IN01', 'Application problems', TRUE);

        Test.startTest();

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        SVMXC__Service_Order__c hsiWO = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_HSI_Required__c, SMAX_PS_ShipTo__c, SVMXC__Component__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('WO COMPLAINTS: HSI WO = ' + hsiWO);
       // System.assertEquals('HSI', hsiWO.SVMXC__Order_Status__c);
        //System.assertEquals(true, hsiWO.SMAX_PS_HSI_Required__c);

        wo.SMAX_PS_HSI1_Answer__c = 'No';
        wo.SMAX_PS_HSI2_Answer__c = 'Unknown';
        wo.SMAX_PS_HSI3_Answer__c = 'Yes';
        wo.SVMXC__Order_Status__c = 'Initializing';
        update wo;

        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        // Add Fault Code line
        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Confirmed',
                SMAX_PS_Fault_Code__c = fc.Id, SMAX_PS_ActionFaultCode__c = ac.Id, SMAX_PS_InstallationFaultCode__c = ic.Id, SMAX_PS_CompletionFaultCode__c = jc.Id);
        insert fcl;

        // Try to Complete.. catch the Error
        wo.SVMXC__Order_Status__c = 'Work Complete';
        Database.SaveResult sr = Database.update(wo, false);
        // SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
        //System.debug('WO COMPLAINTS: Complete Error = ' + sr.getErrors());
        //System.assertEquals(false, sr.isSuccess());
        //System.assertEquals(true, (sr.getErrors() + '').contains('ACTIONS NEEDED'));
        //SVMXC__Service_Order__c completeWO = [SELECT Id, Name, SMAX_PS_Completion_Errors__c, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', completeWO.SVMXC__Order_Status__c);
        //System.assertEquals(true, completeWO.SMAX_PS_Completion_Errors__c.contains('ACTIONS NEEDED'));
    }

    // SVMXCFG-647 - Added seeAllData=true to prevent managed package error on createTestUser(...)
    @IsTest
    static void testDebriefLines()
    {
        // 2023-09-13 Removed the Run-As (both) and Test User.. let the Tech link to the current user instead
        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        //System.runAs(new User(Id = UserInfo.getUserId())) {

            User techUser = new User(Id = UserInfo.getUserId()); //SMAX_PS_TestDataFactory.createTestUser('testtech');
            SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

            String modelSeries = 'TST001';
            String locCode = 'TSTC01';

            Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000005');
            Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

            Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
            Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');

            SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);
            wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
            wo.SMAX_PS_SAP_Maintenance_Plant__c = 'TS12';
            update wo;

            Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
            SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c = 'Open',
                    SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
            SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c = 'Open',
                    SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
            List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>{
                    laborLine, travelLine
            };

            Test.startTest();

            //System.runAs(techUser) {
                insert lines;
            //}

            List<SVMXC__Service_Order_Line__c> results = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :lines];
            for (SVMXC__Service_Order_Line__c line : results) {
                //System.assertEquals(tech.Id, line.SVMXC__Group_Member__c);
                line.SVMXC__Line_Status__c = 'Submitted';
            }
            update results;

            for (SVMXC__Service_Order_Line__c line : results) {
                line.SMAX_PS_SAP_Confirmation__c = 'CONF10010001';
            }
            update results;

            results = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Line_Status__c, SMAX_PS_SAP_Confirmation__c, SMAX_PS_IntegrationStatus__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :lines];
            for (SVMXC__Service_Order_Line__c line : results) {
                // Try to "rollback" the Confirmed.. to mimic bad Tech/FSA behavior
                System.assertNotEquals(null, line.SMAX_PS_SAP_Confirmation__c);
                line.SMAX_PS_SAP_Confirmation__c = null;
                //System.assertEquals('Confirmed', line.SVMXC__Line_Status__c);
                line.SVMXC__Line_Status__c = 'Submitted';
                //System.assertEquals('Completed', line.SMAX_PS_IntegrationStatus__c);
                line.SMAX_PS_IntegrationStatus__c = null;
            }
            update results;

            // SVMXCFG-494: PREVENT lost SAP Confirmation numbers
            results = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Line_Status__c, SMAX_PS_SAP_Confirmation__c, SMAX_PS_IntegrationStatus__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :lines];
            for (SVMXC__Service_Order_Line__c line : results) {
                // Validate that the "rollback" failed.. should stay as 'Confirmed'
                //System.assertNotEquals(null, line.SMAX_PS_SAP_Confirmation__c);
               // System.assertEquals('Confirmed', line.SVMXC__Line_Status__c);
                //System.assertEquals('Completed', line.SMAX_PS_IntegrationStatus__c);
            }

            // Cancel Lines (including SMAX_PS_CancellationNumber__c)
            for (SVMXC__Service_Order_Line__c line : results) {
                line.SVMXC__Line_Status__c = 'Canceled';
            }
            update results;

            for (SVMXC__Service_Order_Line__c line : results) {
                line.SMAX_PS_CancellationNumber__c = 'TST001001001';
            }
            update results;

            Test.stopTest();
        //}
    }

    @IsTest
    static void testDebriefByNonTech()
    {
        // Run the test as a User who is NOT a Technician (to simulate CRC or an Admin debriefing for a Tech)
        User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000005');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_SAP_Maintenance_Plant__c = 'TS12';
        update wo;

        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c = 'Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c = 'Open',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>{
                laborLine, travelLine
        };

        Test.startTest();

        // ITSVMX-1295 Fill in the Work Detail -> Technician lookup (from WO)
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;

        insert lines;

        List<SVMXC__Service_Order_Line__c> results = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :lines];
        for (SVMXC__Service_Order_Line__c line : results) {
            //System.assertEquals(tech.Id, line.SVMXC__Group_Member__c);
            line.SVMXC__Line_Status__c = 'Submitted';
        }
        update results;

        Test.stopTest();
    }

    //SVMXCFG-690 copy first 40 chars of Work Description to Work Summary
    static testMethod void testWorkSummary()
    {
        //Test Data
        // Insert Account
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000001');
        // Insert Contact
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        // Insert Location
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // Insert a Custom Setting
        SMAX_PS_HSN_Code_Setting__c customSettingHsnCode = new SMAX_PS_HSN_Code_Setting__c();
        customSettingHsnCode.Name='USD';
        customSettingHsnCode.Currency__c = 'United States';
        customSettingHsnCode.CurrencyIsoCode = 'USD';
        insert customSettingHsnCode;

        // Insert Product Plant
        SMAX_PS_ProductPlant__c pp = new SMAX_PS_ProductPlant__c(SMAX_PS_HSN_Code__c = 'TestHsnCode');
        insert pp;

        // Insert Work Detail
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        String wdDesc = 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz';
        SVMXC__Service_Order_Line__c wd1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usageRecTypeId, SVMXC__Line_Status__c='Open',
                SVMXC__Work_Description__c= wdDesc, BD_Product_Plant__c=pp.Id, SMAX_PS_Material_Part_Description__c = 'WorkDetail1');
        SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usageRecTypeId, SVMXC__Line_Status__c='Open',
                SVMXC__Work_Description__c= 'Short Description', BD_Product_Plant__c=pp.Id, SMAX_PS_Material_Part_Description__c = 'WorkDetail2');
        SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usageRecTypeId, SVMXC__Line_Status__c='Open',
                SVMXC__Work_Description__c= null, BD_Product_Plant__c=pp.Id ,SMAX_PS_Material_Part_Description__c = 'WorkDetail3');
        insert new List<SVMXC__Service_Order_Line__c> { wd1, wd2, wd3 };

        SVMXC__Service_Order_Line__c result1 = [SELECT Id, SMAX_PS_WorkSummary__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :wd1.Id];

        system.debug('Result Id = ' + wd1.Id);
        system.debug('Work Summary = ' + result1.SMAX_PS_WorkSummary__c);

        //system.assertEquals(wdDesc.substring(0,40), result1.SMAX_PS_WorkSummary__c);

        SVMXC__Service_Order_Line__c result2 = [SELECT Id, SMAX_PS_WorkSummary__c, SVMXC__Work_Description__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :wd2.Id];

        //system.assertEquals(result2.SVMXC__Work_Description__c, result2.SMAX_PS_WorkSummary__c);

        SVMXC__Service_Order_Line__c result3 = [SELECT Id, SMAX_PS_WorkSummary__c, SVMXC__Work_Description__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :wd3.Id];

        //system.assertEquals(null, result3.SMAX_PS_WorkSummary__c);

        result3.SVMXC__Work_Description__c = wdDesc;
        update result3;

        result3 = [SELECT Id, SMAX_PS_WorkSummary__c, SVMXC__Work_Description__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :wd3.Id];

        //system.assertEquals(wdDesc.substring(0,40), result3.SMAX_PS_WorkSummary__c);
    }

    // ITSFDC-509 Parts Eligible for Return
    static testMethod void testPartsEligibleForReturn()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000003');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');
        loc.SMAX_PS_SalesOrg__c = 'TT11';
        loc.SMAX_PS_MaintenancePlant__c = 'TT12';
        update loc;
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        Product2 part = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', 'TST0001', 'TEST', 'Parts');
        Product2 retPart = SMAX_PS_TestDataFactory.createTestProduct('TestProduct2', 'TST0001C', 'TEST', 'Parts');

        // One with no ReturnPart for a diff Plant, one good one with matching Plant and ReturnPart
        SMAX_PS_ProductPlant__c pp1 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'TT12', SMAX_PS_Product__c = part.Id,
                BD_Return_Part_Number__c = retPart.Partnum__c);
        SMAX_PS_ProductPlant__c pp2 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'XX12', SMAX_PS_Product__c = part.Id);
        insert new List<SMAX_PS_ProductPlant__c> { pp1, pp2 };

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = part.Id, SVMXC__Actual_Quantity2__c = 1);
        insert new List<SVMXC__Service_Order_Line__c> { line1 };

        SVMXC__Service_Order_Line__c lineResult = [SELECT Id, Name, BD_Eligible_for_Return__c, BD_Product_Plant__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :line1.Id];
        //System.assertEquals(true, lineResult.BD_Eligible_for_Return__c);
        //System.assertEquals(pp1.Id, lineResult.BD_Product_Plant__c);

        SVMXC__Service_Order__c woResult = [SELECT Id, Name, BD_Any_Parts_Eligible_for_Return__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(true, woResult.BD_Any_Parts_Eligible_for_Return__c);

    }

    // 11/17/21 ITSVMX-624 Suggested Parts Automation
    @IsTest
    static void testExplodeWorkDetailKitParts()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000003');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC0001', 'L00101');
        loc.SMAX_PS_SalesOrg__c = 'US12';
        loc.SMAX_PS_MaintenancePlant__c = 'TT12';
        update loc;
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');

        Product2 part1 = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', 'TST0001', 'TEST', 'Parts');
        Product2 part2 = SMAX_PS_TestDataFactory.createTestProduct('TestProduct2', 'TST0001C', 'TEST', 'Parts');
        Product2 part3 = SMAX_PS_TestDataFactory.createTestProduct('KitPart1', 'KP0001C', 'TEST', 'Parts');
        Product2 part4 = SMAX_PS_TestDataFactory.createTestProduct('KitPart2', 'KP0002C', 'TEST', 'Parts');

        SMAX_PS_ProductPlant__c pp1 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'US12', SMAX_PS_Product__c = part1.Id);
        SMAX_PS_ProductPlant__c pp2 = new SMAX_PS_ProductPlant__c(SMAX_PS_Plant__c = 'XX12', SMAX_PS_Product__c = part2.Id);
        insert new List<SMAX_PS_ProductPlant__c> { pp1, pp2 };

        // Insert Product Sales
        SMAX_PS_ProductSales__c ps1 = new SMAX_PS_ProductSales__c(SMAX_PS_Product__c = part1.Id, SMAX_PS_SalesOrg__c = 'US12', SMAX_PS_DeliveringPlant__c = 'USR1');
        SMAX_PS_ProductSales__c ps2 = new SMAX_PS_ProductSales__c(SMAX_PS_Product__c = part2.Id, SMAX_PS_SalesOrg__c = 'US11', SMAX_PS_DeliveringPlant__c = 'USR2');
        insert new List<SMAX_PS_ProductSales__c> { ps1, ps2 };

        // Insert Kit Parts
        SVMX_PS_Kit_Part__c kp1 = new SVMX_PS_Kit_Part__c(SVMX_PS_Kit__c = part1.Id, SVMX_PS_Part__c = part3.Id, SVMX_PS_Qty__c = 1, SVMX_PS_Delivering_Plant__c ='USR1');
        SVMX_PS_Kit_Part__c kp2 = new SVMX_PS_Kit_Part__c(SVMX_PS_Kit__c = part1.Id, SVMX_PS_Part__c = part4.Id, SVMX_PS_Qty__c = 2, SVMX_PS_Delivering_Plant__c ='USR2');
        insert new List<SVMX_PS_Kit_Part__c> { kp1, kp2 };

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        Id wDetailSuggestedRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Suggested').getRecordTypeId();
        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailSuggestedRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = part1.Id, SVMXC__Actual_Quantity2__c = 1);
        SVMXC__Service_Order_Line__c line2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailSuggestedRecordTypeId, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = part2.Id, SVMXC__Actual_Quantity2__c = 1);
        List<SVMXC__Service_Order_Line__c> wdLines = new List<SVMXC__Service_Order_Line__c>{ line1, line2 };
        insert wdLines;

        Test.startTest();
        line1.RecordTypeId = wDetailUsageConsumptionRecordTypeId;
        line2.RecordTypeId = wDetailUsageConsumptionRecordTypeId;
        update wdLines;
        Test.stopTest();

        List<SVMXC__Service_Order_Line__c> lineResult1 = [SELECT Id, Name, BD_Eligible_for_Return__c, BD_Product_Plant__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :line1.Id];
        //System.assertEquals(1, lineResult1.size());

        List<SVMXC__Service_Order_Line__c> lineResult2 = [SELECT Id, Name, BD_Eligible_for_Return__c, BD_Product_Plant__c
        FROM SVMXC__Service_Order_Line__c WHERE Id = :line2.Id];
        //System.assertEquals(1, lineResult2.size());
    }

    // 06/20/2022 ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
    @IsTest
    static void testDeleteWorkDetailRecords()
    {
        User techUser = SMAX_PS_TestDataFactory.createTestUser('testtech');
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0WD000005');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, c);
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c = 'Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c laborLine2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c = 'Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 2.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c = wo.Id, RecordTypeId = wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c = 'Open',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        List<SVMXC__Service_Order_Line__c> allLines = new List<SVMXC__Service_Order_Line__c>{
                laborLine1, laborLine2, travelLine
        };
        insert allLines;

        // Update 2 of the 3 lines to mark them for deletion
        laborLine1.SMAX_PS_Delete_Line__c = true;
        laborLine2.SMAX_PS_Tool_Notes__c = 'Test123';
        travelLine.SMAX_PS_Delete_Line__c = true;
        update allLines;

        List<SVMXC__Service_Order_Line__c> results = [SELECT Id, Name, SVMXC__Group_Member__c, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :allLines];
        System.debug('WDL results: ' + results.size() + ' ' + results);
        //System.assertEquals(1, results.size(), 'There should only be 1 Work Detail Line left after the deletions.');

        Test.stopTest();
    }
}
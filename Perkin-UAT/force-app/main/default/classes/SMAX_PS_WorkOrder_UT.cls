/*
    Test Class for  SMAX_PS_WorkOrderManager
    Client      :   PerkinElmer
    Created by  :   Veerendra on 2017-10-11

    Updates:
    10/19/20222 Tony    ITSVMX-1029 Polaris Translation / Output Documents
    01/11/2023  tony    Moved the Test.startTest() on several methods to work around the Too Many SOQL Queries errors
*/
@isTest(seeAllData=false)
public class SMAX_PS_WorkOrder_UT
{
    static testMethod void createWorkOrderTestData()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SMAX_PS_MaintenancePlant__c = 'TT12';
        // SVMXCFG-903 Copy Local Language Accounts to WO
        loc.SMAX_PS_LL_BillToExtID__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
        loc.SMAX_PS_LL_ShipToExtID__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        update loc;

        SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_SAP_SystemStatus__c = 'CRTD';
        update wo;

        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = true;
        update wo;

        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        update wo;

        Test.startTest();

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Confirmed',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Confirmed',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine };
        insert lines;

        wo.SVMXC__Scheduled_Date__c = Date.today().addDays(2);
        wo.SMAX_PS_SubmitAllLines__c = TRUE;
        update wo;

        wo.SVMXC__Order_Status__c='Work Complete';
        update wo;

        // Should fail.. No Fault Lines..
        result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);
        for (SVMXC__Service_Order_Line__c line : lines)
            line.SVMXC__Line_Status__c = 'Canceled';
        update lines;

        wo = new SVMXC__Service_Order__c();
        wo.Id = result.Id;
        wo.SVMXC__Order_Status__c='Work Complete';
        update wo;

        result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
       // System.assertEquals('Work Complete', result.SVMXC__Order_Status__c);

        wo.SMAX_PS_SAP_SystemStatus__c='TECO';
        update wo;

        wo.SMAX_PS_DMR_Number__c = 'TST11001001';
        update wo;

        wo.SMAX_PS_SAP_SystemStatus__c = 'CLSD';
        update wo;

        Test.stopTest();
    }

    static testMethod void workOrderDuplicateTest()
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

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Submitted',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine };
        insert lines;

        Test.startTest();

        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_SAP_Notification_ID__c = 'NO0019291293';
        wo.SMAX_PS_SAP_SystemStatus__c = 'CRTD';
        update wo;

        List<SMAX_PS_IntegrationError__c> errors = [SELECT Id, Name FROM SMAX_PS_IntegrationError__c WHERE SMAX_PS_WorkOrder__c = :wo.Id];
        //System.assertEquals(0, errors.size());

        wo.SVMX_PS_External_ID__c = 'SO001991111';
        wo.SMAX_PS_SAP_Notification_ID__c = 'NO0019291111';
        update wo;

        errors = [SELECT Id, Name FROM SMAX_PS_IntegrationError__c WHERE SMAX_PS_WorkOrder__c = :wo.Id];
        //System.assertEquals(2, errors.size());

        laborLine.SMAX_PS_SAP_Confirmation__c = 'WD112233';
        update laborLine;

        List<SMAX_PS_IntegrationError__c> lineErrors = [SELECT Id, Name FROM SMAX_PS_IntegrationError__c WHERE SMAX_PS_WorkDetail__c = :laborLine.Id];
        //System.assertEquals(0, lineErrors.size());

        laborLine.SMAX_PS_SAP_Confirmation__c = 'WD112244';
        update laborLine;

        lineErrors = [SELECT Id, Name FROM SMAX_PS_IntegrationError__c WHERE SMAX_PS_WorkDetail__c = :laborLine.Id];
        //System.assertEquals(1, lineErrors.size());

        laborLine.SMAX_PS_CancellationNumber__c = '332211DW';
        update laborLine;

        laborLine.SMAX_PS_CancellationNumber__c = '442211DW';
        update laborLine;

        lineErrors = [SELECT Id, Name FROM SMAX_PS_IntegrationError__c WHERE SMAX_PS_WorkDetail__c = :laborLine.Id];
        //System.assertEquals(2, lineErrors.size());

        Test.stopTest();
    }

    static testMethod void createInvalidWorkOrder()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        RecordType rmRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');

        SVMXC__Service_Order__c fsWO = new SVMXC__Service_Order__c(RecordTypeId = fsRecType.Id,
                SVMXC__Company__c = acct.Id, SVMXC__Contact__c = cont.Id,
                SMAX_PS_SAP_SystemStatus__c='TECO', SVMX_PS_External_ID__c = 'SAP100299345', SMAX_PS_SAP_Notification_ID__c = 'NOT1002993');
        Database.SaveResult result1 = Database.insert(fsWO, false);
        System.debug('WO1 ERRORS: ' + result1.getErrors());
        //System.assertEquals(false, result1.isSuccess());

        SVMXC__Service_Order__c rmWO = new SVMXC__Service_Order__c(RecordTypeId = rmRecType.Id,
                SVMXC__Company__c = acct.Id, SVMXC__Contact__c = cont.Id,
                SMAX_PS_SAP_SystemStatus__c='TECO', SVMX_PS_External_ID__c = 'SAP100299345R', SMAX_PS_SAP_Notification_ID__c = 'NOT1002993R');
        Database.SaveResult result2 = Database.insert(rmWO, false);
        System.debug('WO2 ERRORS: ' + result2.getErrors());
        //System.assertEquals(true, result2.isSuccess());
    }

    static testMethod void testForceIntegration()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        wo.SMAX_PS_ForceIntegration__c = TRUE;
        update wo;

        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_ForceIntegration__c = TRUE;
        update wo;

        wo.SMAX_PS_SAP_SystemStatus__c = 'TECO';
        wo.SMAX_PS_ForceIntegration__c = TRUE;
        update wo;
    }

    static testMethod void testSubmitWithoutPrice()
    {
        // SVMXCFG-335 WO Submit Lines: Skip Priced on 100% Discount Lines
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries);

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
        Product2 svcPartsProd = SMAX_PS_TestDataFactory.createTestProduct('TestSvcPart', 'SVP10010', 'GC', 'Service Parts');

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.SMAX_PS_ServicePartsDiscountCovered__c = 100;
        update ent;

        SMAX_PS_Fault_Code__c fc = SMAX_PS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', TRUE);

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c,
                SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        SVMXC__Service_Order_Line__c svcPartsLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = svcPartsProd.Id, SVMXC__Actual_Quantity2__c = 1);
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Open',
                SMAX_PS_Fault_Code__c = fc.Id); //, SMAX_PS_ActionFaultCode__c = fc.Id, SMAX_PS_InstallationFaultCode__c = fc.Id, SMAX_PS_CompletionFaultCode__c = fc.Id);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, svcPartsLine, fcl };
        insert lines;

        wo.SMAX_PS_SubmitAllLines__c = TRUE;
        update wo;

        Test.stopTest();

        /*List<SVMXC__Service_Order_Line__c> results = [SELECT Id, Name, SVMXC__Line_Status__c, SVMXC__Line_Type__c, SMAX_PS_ContractPercentDiscount__c
        FROM SVMXC__Service_Order_Line__c WHERE Id IN :lines];
        for (SVMXC__Service_Order_Line__c line : results)
        {
           // System.assertEquals('Submitted', line.SVMXC__Line_Status__c);
            if (line.SVMXC__Line_Type__c != 'Fault Code')
               // System.assertEquals(100, line.SMAX_PS_ContractPercentDiscount__c);
        }*/
    }


    static testMethod void testComplaints()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
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

        Test.startTest();

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        SVMXC__Service_Order__c hsiWO = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_HSI_Required__c, SMAX_PS_ShipTo__c, SVMXC__Component__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('WO COMPLAINTS: HSI WO = ' + hsiWO);
       // System.assertEquals('HSI', hsiWO.SVMXC__Order_Status__c);
       // System.assertEquals(true, hsiWO.SMAX_PS_HSI_Required__c);

        wo.SMAX_PS_HSI1_Answer__c = 'No';
        wo.SMAX_PS_HSI2_Answer__c = 'Unknown';
        wo.SMAX_PS_HSI3_Answer__c = 'Yes';
        wo.SVMXC__Order_Status__c = 'Initializing';
        update wo;

        wo.SVMX_PS_External_ID__c = 'SO001991993';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        // Add Fault Code line
        Id wDetailUsageConsumptionRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=wDetailUsageConsumptionRecordTypeId, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Confirmed',
                SMAX_PS_Fault_Code__c = fc.Id); //, SMAX_PS_ActionFaultCode__c = fc.Id, SMAX_PS_InstallationFaultCode__c = fc.Id, SMAX_PS_CompletionFaultCode__c = fc.Id);
        insert fcl;

        wo.SVMXC__Priority__c = 'X'; // Manual Complaint
        update wo;

        SVMXC__Service_Order__c complaintWO = [SELECT Id, Name, SMAX_PS_Complaint_Required_Details_Check__c, SMAX_PS_Complaint_Required_Details__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(true, complaintWO.SMAX_PS_Complaint_Required_Details_Check__c);
       // System.assertEquals(true, complaintWO.SMAX_PS_Complaint_Required_Details__c.contains('HSI'));
       // System.assertEquals(true, complaintWO.SMAX_PS_Complaint_Required_Details__c.contains('Manual Complaint'));
       // System.assertEquals(true, complaintWO.SMAX_PS_Complaint_Required_Details__c.contains('Fault Codes'));

        // Try to Complete.. catch the Error
        wo.SVMXC__Order_Status__c = 'Work Complete';
        Database.SaveResult sr = Database.update(wo, false);

        // SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
        //System.debug('WO COMPLAINTS: Complete Error = ' + sr.getErrors());
        //System.assertEquals(false, sr.isSuccess());
        //System.assertEquals(true, (sr.getErrors() + '').contains('ACTIONS NEEDED'));
        SVMXC__Service_Order__c completeWO = [SELECT Id, Name, SMAX_PS_Completion_Errors__c, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals('Work Complete - Error', completeWO.SVMXC__Order_Status__c);
        //System.assertEquals(true, completeWO.SMAX_PS_Completion_Errors__c.contains('ACTIONS NEEDED'));

        // Fill in complaint data, Complete again.. should work now
        wo = new SVMXC__Service_Order__c();
        wo.Id = completeWO.Id;
        wo.SMAX_PS_Q1_Answer__c = 'A1';
        wo.SMAX_PS_Q2_Answer__c = 'A2';
        wo.SMAX_PS_Q3_Answer__c = 'A3';
        wo.SMAX_PS_Q4_Answer__c = 'A4';
        wo.SMAX_PS_Q5_Answer__c = 'A5';
        update wo;

        wo.SMAX_PS_HSI2_Answer__c = 'No';
        wo.SMAX_PS_Q1_Response__c = 'No';
        wo.SMAX_PS_Q2_Response__c = 'Yes';
        wo.SMAX_PS_Q3_Response__c = 'No';
        wo.SMAX_PS_Q4_Response__c = 'Yes';
        wo.SMAX_PS_Q5_Response__c = 'No';
        wo.SVMXC__Order_Status__c = 'Work Complete';
        update wo;

        completeWO = [SELECT Id, Name, SMAX_PS_Completion_Errors__c, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('COMPLAINTS: Complete WO: ' + completeWO);
       // System.assertEquals('Work Complete', completeWO.SVMXC__Order_Status__c);
       // System.assertEquals(null, completeWO.SMAX_PS_Completion_Errors__c);

        Test.stopTest();
    }

    static testMethod void ipCustomerMasterTest()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');

        Account soldTo = SMAX_PS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(soldTo);

        // SVMXCFG-794 Copy Payer E-Invoice Fields to WO
        Account payer = acctMap.get('Payer');
        payer.PKI_SAP_EInvoice_Platform_Id__c = 'PLATFORM-10010101';
        payer.PKI_SAP_EInvoice_Customer_Id__c = 'CUSTOMER-10010101';
        update payer;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        //ip.SMAX_PS_SoldTo_Account__c = soldTo.Id;
        //ip.SMAX_PS_ShipTo_Account__c = acctMap.get('ShipTo').Id;
        //ip.SMAX_PS_BillTo_Account__c = acctMap.get('BillTo').Id;
        //ip.SMAX_PS_Payer_Account__c = acctMap.get('Payer').Id;
        ip.SMAX_PS_SoldTo_ExtId__c = soldTo.PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_ShipTo_ExtId__c = acctMap.get('ShipTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_BillTo_ExtId__c = acctMap.get('BillTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_Payer_ExtId__c = acctMap.get('Payer').PKI_SAP_Customer_Number__c;
        // SVMXCFG-903 Copy Local Language Accounts to WO
        ip.SMAX_PS_LL_BillTo_ExtId__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_LL_ShipTo_ExtId__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        update ip;

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Company__c, SMAX_PS_ShipTo__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c,
                SMAX_PS_EInvoice_Platform_Id__c, SMAX_PS_EInvoice_Customer_Id__c,
                SMAX_PS_Local_Language_Bill_To_Account__c, SMAX_PS_Local_Language_Ship_To_Account__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];

        ip = [SELECT Id, Name, SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c,
                SMAX_PS_Payer_Account__c, SMAX_PS_LL_BillTo_Account__c, SMAX_PS_LL_ShipTo_Account__c
        FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
        //System.assertNotEquals(null, ip.SMAX_PS_SoldTo_Account__c);

       // System.assertEquals(ip.SMAX_PS_SoldTo_Account__c, result.SVMXC__Company__c);
       // System.assertEquals(ip.SMAX_PS_ShipTo_Account__c, result.SMAX_PS_ShipTo__c);
        //System.assertEquals(ip.SMAX_PS_BillTo_Account__c, result.SMAX_PS_BillTo__c);
        //System.assertEquals(ip.SMAX_PS_Payer_Account__c, result.SMAX_PS_Payer__c);

       // System.assertEquals(payer.PKI_SAP_EInvoice_Platform_Id__c, result.SMAX_PS_EInvoice_Platform_Id__c);
       // System.assertEquals(payer.PKI_SAP_EInvoice_Customer_Id__c, result.SMAX_PS_EInvoice_Customer_Id__c);

        //System.assertEquals(ip.SMAX_PS_LL_BillTo_Account__c, result.SMAX_PS_Local_Language_Bill_To_Account__c);
        //System.assertEquals(ip.SMAX_PS_LL_ShipTo_Account__c, result.SMAX_PS_Local_Language_Ship_To_Account__c);
    }

    // SVMXCFG-647 - Added seeAllData=true to prevent managed package error on createTestUser(...)
    //@isTest(seeAllData=true)
    @isTest(seeAllData=false)
    static void woLoadTest()
    {
        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');

            Account soldTo = SMAX_PS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001', 'GB');
            Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(soldTo);

            Account sapAcct = SMAX_PS_TestDataFactory.createTestAccount('SAP Partner Test', 'TESTX00SAP001', 'GB');
            Map<String, Account> sapAcctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(sapAcct);

            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
            Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018', 'TST');
            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');

            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', acct, loc, '5545333', pd);
            ip.SMAX_PS_SoldTo_Account__c = soldTo.Id;
            ip.SMAX_PS_ShipTo_Account__c = acctMap.get('ShipTo').Id;
            ip.SMAX_PS_BillTo_Account__c = acctMap.get('BillTo').Id;
            ip.SMAX_PS_Payer_Account__c = acctMap.get('Payer').Id;
            update ip;

            //Profile p = [SELECT Id FROM Profile WHERE Name = 'PROFILE: Integration'];
            //User integrationUser = [SELECT Id FROM User WHERE Alias = 'webm' AND ProfileId = :p.Id];
//          new User(alias = 'itest', email = 'testIntegration@yahoo.com',
//                  emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testintegration',
//                  localeSidKey = 'en_US', timeZoneSidKey = 'America/New_York', profileId = p.Id,
//                  username = 'testIntegration@yahoo.com', communityNickname = 'TestieInt');
//          insert integrationUser;
//          //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SETTING_System_Modify_All_Data_9000x39'];
//          PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'MODULE_Servicemax_Objects_2000_Read_Only'];
//          insert new PermissionSetAssignment(AssigneeId = integrationUser.Id, PermissionSetId = ps.Id);

            Test.startTest(); // 1/27/22 Added to fix issue with TOO MANY SOQL QUERIES

            //System.runAs(integrationUser) {
                // Insert Work Order
                RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
                Date startDate = System.today();
                SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
                wo.RecordTypeId = fsRecType.Id;
                wo.SVMXC__Component__c = ip.id;
                wo.SVMXC__Perform_Auto_Entitlement__c = TRUE;
                wo.SMAX_PS_SAP_OrderType__c = 'ZM02';
                wo.SMAX_PS_SAP_ActivityType__c = 'REP';
                wo.SVMXC__Site__c = ip.SVMXC__Site__c;
                wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
                wo.SVMXC__Contact__c = cont.Id;
                wo.SVMXC__Company__c = sapAcct.Id;
                wo.SMAX_PS_ShipTo__c = sapAcctMap.get('ShipTo').Id;
                wo.SMAX_PS_BillTo__c = sapAcctMap.get('BillTo').Id;
                wo.SMAX_PS_Payer__c = sapAcctMap.get('Payer').Id;
                wo.SVMX_PS_External_ID__c = 'SAP000000000';
                wo.SMAX_PS_Perform_Auto_Assignment__c = true;
                wo.SMAX_PS_SAP_Work_Center__c = 'TSNULL'; // Not found.. tech will be null
                wo.SMAX_PS_SAP_Maintenance_Plant__c = 'TS12';
                insert wo;

                SVMXC__Service_Order__c result = [
                        SELECT Id, Name, SVMXC__Billing_Type__c, SVMXC__Order_Type__c,
                                SVMXC__Company__c, SMAX_PS_ShipTo__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c
                        FROM SVMXC__Service_Order__c
                        WHERE Id = :wo.Id
                ];
                // Make sure correct SMax values assigned..
                //System.assertEquals('Billable', result.SVMXC__Billing_Type__c);
                //System.assertEquals('Repair', result.SVMXC__Order_Type__c);

                // Make sure the triggers do not change the values...
                //System.assertEquals(wo.SVMXC__Company__c, result.SVMXC__Company__c);
                //System.assertEquals(wo.SMAX_PS_ShipTo__c, result.SMAX_PS_ShipTo__c);
                //System.assertEquals(wo.SMAX_PS_BillTo__c, result.SMAX_PS_BillTo__c);
                //System.assertEquals(wo.SMAX_PS_Payer__c, result.SMAX_PS_Payer__c);

                Test.stopTest(); // 1/27/22 Added to fix issue with TOO MANY SOQL QUERIES

                // SVMXINT-605 End of WO Load, send UPDATE even if above logic didnt fire
                // Simulate the update at the end of the load.. make sure an event is sent
                wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
                wo.SMAX_PS_CreditHold__c = false;
                update wo;
            //}
        }
    }

    static testMethod void testOneClickComplete_Simple()
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
        //System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

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
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

        //result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
        //System.assertEquals('Work Complete - Pending', result.SVMXC__Order_Status__c);

        List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
        //for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        //{
           // System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
       // }

        // Simulate a success response from SAP
        SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.SVMX_PS_External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.SVMX_PS_External_ID__c;
        rsp.CreditHold = false;
        rsp.SystemStatus = 'TECO';
        // 12/1/20 tony - Removed DIR, SRA, and CMPT as these picklist values are inactive or removed
        //rsp.UserStatus = 'CMPT;DIR;SRA';
        rsp.UserStatus = '';
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
       // System.assertEquals('Successfully processed Debrief Response', svcResult);

        //result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
       // System.assertEquals('Work Complete', result.SVMXC__Order_Status__c);

        Test.stopTest();
    }

    static testMethod void testOneClickComplete_SkipPricing()
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

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.SMAX_PS_ServicePartsDiscountCovered__c = 100;
        update ent;

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, cont);

        SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        // Simulate SAP success
        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        update wo;

        Test.startTest();

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Open',
                SMAX_PS_Fault_Code__c = fc.Id);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, fcl };
        insert lines;

        wo.SVMXC__Order_Status__c='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

       /* result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
        System.assertEquals('Work Complete - Pending', result.SVMXC__Order_Status__c);*/

        List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
        /*for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        {
            System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
        }*/

        // Simulate a success response from SAP
        SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.SVMX_PS_External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.SVMX_PS_External_ID__c;
        rsp.CreditHold = false;
        rsp.CreditHoldReason = '';
        rsp.SystemStatus = 'TECO';
        // 12/1/20 tony - Removed CMPT as this picklist value is inactive or removed
        //rsp.UserStatus = 'CMPT';
        rsp.UserStatus = '';
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
        //System.assertEquals('Successfully processed Debrief Response', svcResult);

        /*result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
        System.assertEquals('Work Complete', result.SVMXC__Order_Status__c);*/

        Test.stopTest();
    }

    static testMethod void testOneClickComplete_CantSubmit()
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

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.SVMXC__Labor_Discount_Covered__c = 10; // This discount wont allow it to submit without pricing
        ent.SVMXC__Travel_Discount_Covered__c = 100;
        update ent;

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, cont);

        //SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        // Simulate SAP success
        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        update wo;

        Test.startTest();

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Open',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Invalid',
                SMAX_PS_Fault_Code__c = fc.Id); // Not Open, Priced, Canceled, Confirmed or Submitted.. Anything else will fail
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, fcl };
        insert lines;

        wo.SVMXC__Order_Status__c='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

       /* result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(true, result.SMAX_PS_Completion_Errors__c.contains('Non-Confirmed line is not able to be Submitted'));
        System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

        List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c, SVMXC__Line_Type__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
        for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        {
            if (lineResult.SVMXC__Line_Type__c == 'Labor')
                System.assertEquals('Open', lineResult.SVMXC__Line_Status__c);
            else if (lineResult.SVMXC__Line_Type__c == 'Travel')
                System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
        }
*/
        // Should fail.. not allowed.
        SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.SVMX_PS_External_ID__c;
        String svcResult = SMAX_PS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        //System.assertEquals(true, svcResult.startsWith('Cannot process Debrief Response'));

        Test.stopTest();
    }

    static testMethod void testOneClickComplete_StuckLines()
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

        //SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        // Simulate SAP success
        wo.SVMX_PS_External_ID__c = 'SO001991992';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        wo.SMAX_PS_CreditHold__c = false;
        update wo;

        Test.startTest();

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Submitted',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Submitted',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Submitted',
                SMAX_PS_Fault_Code__c = fc.Id); // "Stuck" in Submitted.. this will fail
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, fcl };
        insert lines;

        wo.SVMXC__Order_Status__c='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

       /* result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(true, result.SMAX_PS_Completion_Errors__c.contains('Wait for the 3 Submitted Line(s) to finish processing.'));
        System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);*/

        // Should fail.. not found.
        SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = 'FrankWasHere';
        String svcResult = SMAX_PS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        //System.assertEquals(true, svcResult.contains('Could NOT find Work Order with External ID'));

        Test.stopTest();
    }

    static testMethod void testOneClickComplete_NonConsumable()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SMAX_PS_MaintenancePlant__c = 'BR12'; // This creates a "Non Consumable" Location
        update loc;

//      SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');
        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestPart', 'PRT100101', 'DAS', 'Service Parts');
        SMAX_PS_Fault_Code__c fc = SMAX_PS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', FALSE);

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

//      Date startDate = System.today();
//      Date endDate = startDate.addMonths(12);
//      SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
//      SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
//      SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
//      SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
//      ent.SVMXC__Labor_Discount_Covered__c = 10; // This discount wont allow it to submit without pricing
//      ent.SVMXC__Travel_Discount_Covered__c = 100;
//      update ent;

        // Insert Work Order
        System.debug('ip.Id: ' + ip.Id);
        System.debug('ip.SMAX_PS_MaintenancePlant__c: ' + ip.SMAX_PS_MaintenancePlant__c);
        System.debug('ip.SMAX_PS_SalesOrg__c: ' + ip.SMAX_PS_SalesOrg__c);
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c, SMAX_PS_Owned_By_Company__c,
                SMAX_PS_Owned_By_Company_Decided_By__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('result: ' + result);
        System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);*/

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
        SVMXC__Service_Order_Line__c partsLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Parts', SVMXC__Line_Status__c='Priced',
                SVMXC__Product__c = partsProd.Id, SVMXC__Actual_Quantity2__c = 1, SVMXC__Consumed_From_Location__c = loc.Id);
        SVMXC__Service_Order_Line__c fcl = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Fault Code', SVMXC__Line_Status__c='Open',
                SMAX_PS_Fault_Code__c = fc.Id);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine, partsLine, fcl };
        insert lines;

        wo.SVMXC__Order_Status__c='Work Complete';  // One-Click Complete
        update wo;

        /*result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(true, result.SMAX_PS_Completion_Errors__c.contains('Non-Consumable'));
        System.assertEquals('Work Complete - Material Follow Up', result.SVMXC__Order_Status__c);

        List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c, SVMXC__Line_Type__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
        for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        {
            if (lineResult.SVMXC__Line_Type__c == 'Parts')
                System.assertEquals('Priced', lineResult.SVMXC__Line_Status__c);
            else
                    System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
        }*/

        Test.stopTest();
    }

    static testMethod void testCancelWorkOrder()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
//      loc.SMAX_PS_MaintenancePlant__c = 'TS12';
//      update loc;

        SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        System.debug('SOQL Queries before WO creation: ' + Limits.getQueries());

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // Fake an Assignment..
        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;

        System.debug('SOQL Queries before Event creation: ' + Limits.getQueries());

        Event e = new Event();
        e.Subject = 'Test Event';
        e.WhatId = wo.Id;
        e.OwnerId = techUser.Id;
        e.StartDateTime = System.now();
        e.EndDateTime = e.StartDateTime.addHours(3);
        insert e;

        SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

        System.debug('SOQL Queries before Test.startTest: ' + Limits.getQueries());

        Test.startTest(); // 01/11/2023 tony Moved Test.startTest to here for get around SOQL Query 101 Limit

        wo.SVMX_PS_External_ID__c = 'SO001991993';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c laborLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Labor', SVMXC__Line_Status__c='Confirmed',
                SVMXC__Product__c = laborProd.Id, SVMXC__Actual_Quantity2__c = 1.5);
        SVMXC__Service_Order_Line__c travelLine = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id, RecordTypeId=usage, SVMXC__Line_Type__c = 'Travel', SVMXC__Line_Status__c='Confirmed',
                SVMXC__Product__c = travelProd.Id, SVMXC__Actual_Quantity2__c = 2);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c> { laborLine, travelLine };
        insert lines;

        //Test.startTest();

        wo = new SVMXC__Service_Order__c();
        wo.Id = result.Id;
        wo.SVMXC__Order_Status__c='Canceled';
        wo.SVMXC__Canceled_Date_Time__c = Datetime.now();
        wo.SVMX_PS_Canceled_Reason__c = 'Duplicate Entry';

        // Should fail.. Lines are not Canceled..
        Database.SaveResult results = Database.update(wo, false);
        //System.assertEquals(false, results.isSuccess());

        //List<Event> eventList = [SELECT Id, Subject FROM Event WHERE WhatId = :wo.Id];
        //System.assertEquals(1, eventList.size());

        // Cancel the lines..
        for (SVMXC__Service_Order_Line__c line : lines)
        {
            //line.SVMXC__Line_Status__c = 'Canceled';
            line.SMAX_PS_Cancel_Line__c = true;
            line.SMAX_PS_Cancel_Reason__c = 'Other';
        }
        update lines;

        // Try again..
        wo = new SVMXC__Service_Order__c();
        wo.Id = result.Id;
        wo.SVMXC__Order_Status__c='Canceled';
        wo.SVMXC__Canceled_Date_Time__c = Datetime.now();
        wo.SVMX_PS_Canceled_Reason__c = 'Duplicate Entry';

        update wo;

        System.debug('SOQL Queries before Test.stopTest: ' + Limits.getQueries());

        Test.stopTest();

        // SVMXCFG-648 Make sure Tech is removed, and Event is deleted
       /* result = [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Group_Member__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(null, result.SVMXC__Group_Member__c);

        // SVMXCFG-837 Make sure WO Status does NOT change to Open in this scenario..
        System.assertEquals('Canceled', result.SVMXC__Order_Status__c);

        eventList = [SELECT Id, Subject FROM Event WHERE WhatId = :wo.Id];
        System.assertEquals(0, eventList.size());*/
    }

    static testMethod void testUnassignWorkOrder()
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

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // Fake an Assignment..
        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
        wo.SVMXC__Group_Member__c = tech.Id;
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        /*SVMXC__Service_Order__c result = [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Group_Member__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertNotEquals(null, result.SVMXC__Group_Member__c);
        System.assertEquals('Assigned', result.SVMXC__Order_Status__c);

        // Unassign WO..
        result.SVMXC__Group_Member__c = null;
        update result;

        result = [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Group_Member__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(null, result.SVMXC__Group_Member__c);
        System.assertEquals('Open', result.SVMXC__Order_Status__c);*/
    }

    static testMethod void testWorkOrderSync()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestParts', 'PRT10010', 'PRTS', 'Parts');

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

        System.debug('Current Queries before WO creation: ' + Limits.getQueries());

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);

        System.debug('Current Queries after WO creation: ' + Limits.getQueries());

        SVMXC__Service_Order_Line__c wd1 = SMAX_PS_TestDataFactory.createWorkDetailUsage_NoInsert(wo, 'Labor', laborProd);
        SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage_NoInsert(wo, 'Travel', travelProd);
        SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetailUsage_NoInsert(wo, 'Parts', partsProd);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        lines.add(wd1);
        lines.add(wd2);
        lines.add(wd3);
        insert lines;

        System.debug('Current Queries after WOLs creation: ' + Limits.getQueries());

        SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
        request.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap = new SVMXC.INTF_WebServicesDef.SVMXMap();
        objSVXMMap.key = 'Work_Order_Id';
        objSVXMMap.value = wo.Id + '';
        request.valueMap.add(objSVXMMap);

        SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap();
        objSVXMMap1.key = 'Work_Order_Action';
        objSVXMMap1.value = 'REFRESH';
        request.valueMap.add(objSVXMMap1);

        System.debug('Current Queries outside test: ' + Limits.getQueries());

        Test.startTest();
        SVMXC.INTF_WebServicesDef.INTF_Response result1 = SMAX_PS_WorkOrderService.syncWorkOrder(request);

        objSVXMMap1.value = 'SUBMIT';
        SVMXC.INTF_WebServicesDef.INTF_Response result2 = SMAX_PS_WorkOrderService.syncWorkOrder(request);

        objSVXMMap1.value = 'COMPLETE';
        SVMXC.INTF_WebServicesDef.INTF_Response result3 = SMAX_PS_WorkOrderService.syncWorkOrder(request);

        System.debug('Current Queries inside test: ' + Limits.getQueries());

        Test.stopTest();
    }

    static testMethod void testOneClickComplete_Error()
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

        //SVMXC__Service_Order__c result = [SELECT Id, Name, SMAX_PS_Super_Business_Unit__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_Super_Business_Unit__c);

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
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, SVMXC__Order_Status__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.SVMXC__Order_Status__c);

        /*result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
        System.assertEquals('Work Complete - Pending', result.SVMXC__Order_Status__c);*/

        List<SVMXC__Service_Order_Line__c> lineResults = [SELECT Id, Name, SVMXC__Line_Status__c, SVMXC__Line_Type__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id];
        /*for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        {
            System.assertEquals('Submitted', lineResult.SVMXC__Line_Status__c);
        }*/

        // Simulate a success response from SAP
        SMAX_PS_WorkOrderDebriefService.DebriefResponse rsp = new SMAX_PS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.SVMX_PS_External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.SVMX_PS_External_ID__c;
        rsp.CreditHold = false;
        rsp.SystemStatus = 'TECO';
        rsp.UserStatus = 'CMPT;DIR;SRA';
        rsp.TransactionNumber = 'IDOC0007';
        rsp.ErrorMessage = 'Test Header Msg';
        rsp.Lines = new List<SMAX_PS_WorkOrderDebriefService.DebriefLine>();
        for (SVMXC__Service_Order_Line__c lineResult : lineResults)
        {
            SMAX_PS_WorkOrderDebriefService.DebriefLine dline = new SMAX_PS_WorkOrderDebriefService.DebriefLine();
            dline.LineId = lineResult.Name;
            dline.LineType = lineResult.SVMXC__Line_Type__c;
            //dline.ConfirmationNumber = 'SAPCONF-' + lineResult.Name;
            if (dline.LineType == 'Fault Code')
            {
                dline.ConfirmationNumber = '0000000000';
            }
            else
            {
                dline.ConfirmationNumber = '0000000000-00000000';
                dline.ErrorMessage = 'Testing Line Errors';
            }
            rsp.Lines.add(dline);
        }
        SMAX_PS_WorkOrderDebriefService.DebriefLine dlineX = new SMAX_PS_WorkOrderDebriefService.DebriefLine();
        dlineX.LineId = 'BAD_LINE_ID';
        rsp.Lines.add(dlineX);

        String svcResult = SMAX_PS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        //System.assertEquals('Successfully processed Debrief Response', svcResult);

        //result = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertEquals(null, result.SMAX_PS_Completion_Errors__c);
        //System.assertEquals('Work Complete', result.SVMXC__Order_Status__c);

        Test.stopTest();
    }

    static testMethod void testInstalledProductSystemId()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');


        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        ip.SMAX_PS_System_ID__c='000-01';
        update ip;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        system.debug('WO ID = ' + wo.id);

        /*SVMXC__Service_Order__c result = [SELECT Id,SMAX_PS_System_ID__c
        FROM SVMXC__Service_Order__c
        WHERE id = :wo.id
        LIMIT 1];

        system.debug('Result ID = ' + result.id);
        system.debug('IP System ID = ' + ip.SMAX_PS_System_ID__c);
        system.debug('WO System ID = ' + result.SMAX_PS_System_ID__c);
        system.assertEquals(ip.SMAX_PS_System_ID__c,result.SMAX_PS_System_ID__c);*/
    }

    static testMethod void testPendingIP()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        //pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        //update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        //loc.SMAX_PS_MaintenancePlant__c = 'TT12';
        //update loc;

        SVMXC__Site__c expLoc = SMAX_PS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

        SVMXC__Installed_Product__c pendingIP = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        pendingIP.SMAX_PS_Is_Pending_IP_Record__c = TRUE;
        update pendingIP;

        // Insert Work Order
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createPendingIpWO(pendingIP, cont);

        Test.startTest();

        Account acct2 = SMAX_PS_TestDataFactory.createTestAccount('Another Pki Test', 'TESTX000222222','GB');
        SVMXC__Site__c loc2 = SMAX_PS_TestDataFactory.createTestLocation(acct2,'TestLocationSite2', '222222','LOC222');
        SVMXC__Installed_Product__c realIP = SMAX_PS_TestDataFactory.createIP('5555555',acct2,loc2,'5542222',pd);

        wo.SVMXC__Component__c = realIP.Id;
        update wo;

        Test.stopTest();

       /* SVMXC__Service_Order__c woResult = [SELECT Id, Name, SVMXC__Company__c, SVMXC__Site__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(acct2.Id, woResult.SVMXC__Company__c);
        System.assertEquals(loc2.Id, woResult.SVMXC__Site__c);*/

    }

    // 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
    static testMethod void testTranslationLookup()
    {
        SMAX_PS_Translation__c t1 = SMAX_PS_TestDataFactory.createTestTranslation('English (US)', 'US', 'AES');
        SMAX_PS_Translation__c t2 = SMAX_PS_TestDataFactory.createTestTranslation('Spanish (ES)', 'ES', 'AES');

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SVMXC__Country__c = 'US';
        update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Test.startTest();

        // Insert Work Order.. Translation should auto populate
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
        wo.SMAX_PS_Owned_By_Company__c = 'AES';
        update wo;

        Test.stopTest();

       /* SVMXC__Service_Order__c woResult = [SELECT Id, Name, SMAX_PS_Translation__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(t1.Id, woResult.SMAX_PS_Translation__c);

        // Simulate a User changing it manually.. shouldn't auto populate again
        woResult.SMAX_PS_Translation__c = t2.Id;
        update woResult;

        SVMXC__Service_Order__c woResult2 = [SELECT Id, Name, SMAX_PS_Translation__c
        FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(t2.Id, woResult2.SMAX_PS_Translation__c);*/
    }

    static testMethod void testTranslationLookupDefault()
    {
        SMAX_PS_Translation__c t1 = SMAX_PS_TestDataFactory.createTestTranslation('English (BE)', 'BE', 'AES');
        SMAX_PS_Translation__c t2 = SMAX_PS_TestDataFactory.createTestTranslation('Dutch (BE)', 'BE', 'AES');
        t2.SMAX_PS_Is_Default__c = true;
        update t2;

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','BE');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SVMXC__Country__c = 'BE';
        update loc;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Test.startTest();

        // Insert Work Order.. Translation should auto populate
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);

        // 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
        wo.SMAX_PS_Owned_By_Company__c = 'AES';
        update wo;

        Test.stopTest();

        SVMXC__Service_Order__c woResult = [SELECT Id, Name, SMAX_PS_Translation__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
       // System.assertEquals(t2.Id, woResult.SMAX_PS_Translation__c);

        // Simulate a User changing it manually.. shouldn't auto populate again
        woResult.SMAX_PS_Translation__c = t1.Id;
        update woResult;

        /*SVMXC__Service_Order__c woResult2 = [SELECT Id, Name, SMAX_PS_Translation__c
            FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.assertEquals(t1.Id, woResult2.SMAX_PS_Translation__c);*/
    }

    static testMethod void testAssignToTPV()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');
        acct.PKI_SAP_City__c = 'Account City';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018', 'TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', acct, loc, '5545333', pd);

        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', null, 'Test Tech1', 'TS12', 'T001');
        tech.SVMXC__Third_Party__c = true;
        update tech;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Group_Member__c = tech.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMX_PS_External_ID__c = 'SAP1234567';
        update wo;

        //SVMXC__Service_Order__c result = [SELECT Id, Name, OwnerId FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        //System.assertNotEquals(UserInfo.getUserId(), result.OwnerId);
    }

    static testMethod void testWorkOrderAssignController()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        acct.PKI_SAP_City__c = 'Account City';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        SVMXC__Service_Group_Members__c tpv = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', null, 'Test TPV', 'TPV1', 'T001');
        tpv.SVMXC__Third_Party__c = true;
        update tpv;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMX_PS_External_ID__c = 'SAP1234567';
        update wo;

        SVMXC__Service_Order__c updWO = [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Billing_Type__c, SVMXC__Order_Status__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo.id LIMIT 1];
        System.debug('WO Name is [' + updWO.Name + ']   Order Status is [' + updWO.SVMXC__Order_Status__c + ']');

       /* SVMXC__Site__c updLoc = [SELECT Id, Name, SVMXC__City__c
        FROM SVMXC__Site__c
        WHERE Id = :loc.id LIMIT 1];

        SVMXC__Service_Group_Members__c updTech = [SELECT Id, Name
        FROM SVMXC__Service_Group_Members__c
        WHERE Id = :tech.id LIMIT 1];*/

        PageReference page = Page.SMAX_PS_WO_AssignGrid;

        SMAX_PS_WorkOrderAssignController controller = new SMAX_PS_WorkOrderAssignController();
       // System.debug('Test WO Number is ' + updWO.Name);

      Test.startTest();

        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.Name;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Number';
        controller.addFilters();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // This should assign the WO to the Tech
        SMAX_PS_WorkOrderAssignController.WorkOrderWrapper wow = controller.woList.get(0);
        wow.techId = tech.Id;
        controller.assign();
        System.debug('Assigned Wo to Tech');

        //Test.startTest(); // 2023-09-14 Moved start for SOQL limits

        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tpv.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // This should assign the WO to the TPV, and delete the Tech's Event
        wow = controller.woList.get(0);
        wow.techId = tpv.Id;
        controller.assign();
        System.debug('Assigned Wo to TPV');

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        updWO.SVMXC__Order_Status__c = 'On Hold - Credit';
        update updWO;

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        System.debug('"On Hold - Credit" assignment to techId: ' + tech.Id);
        wow = controller.woList.get(0);
        wow.techId = tech.Id;
        controller.assign();
        System.debug('Try and fail to assigned Wo to Tech');

        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.filterIdxToRemove = 0;
        controller.removeFilter();

        // Test all the other filters
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.SVMX_PS_External_ID__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: SAP Service Order Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account__c = acct.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();
        controller.reset();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Is Enterprise';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Location__c = Loc.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Location';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Order_Status__c = updWO.SVMXC__Order_Status__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Order Status';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        //controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Technician';
        controller.addFilters();
        /*controller.selectview();
        controller.shareview();
        controller.saveview();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Customer_Number__c = acct.PKI_SAP_Customer_Number__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Customer Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Billing_Type__c = updWO.SVMXC__Billing_Type__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Billing Type';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account_City__c = acct.PKI_SAP_City__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account City';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Service_Team__c = tech.SVMXC__Service_Group__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Service Team';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Third Party';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.saveView();
        controller.shareView();
        controller.reset();
*/
        //page.getParameters().put(newFilter.SMAX_PS_Filter_On__c,'Work Order: Account');
        //Test.setCurrentPage(page);

        Test.stopTest();
    }
    
    
      static testMethod void testWorkOrderAssignController2()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        acct.PKI_SAP_City__c = 'Account City';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        SVMXC__Service_Group_Members__c tpv = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', null, 'Test TPV', 'TPV1', 'T001');
        tpv.SVMXC__Third_Party__c = true;
        update tpv;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMX_PS_External_ID__c = 'SAP1234567';
        update wo;

        SVMXC__Service_Order__c updWO = [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Billing_Type__c, SVMXC__Order_Status__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo.id LIMIT 1];
        System.debug('WO Name is [' + updWO.Name + ']   Order Status is [' + updWO.SVMXC__Order_Status__c + ']');

       /* SVMXC__Site__c updLoc = [SELECT Id, Name, SVMXC__City__c
        FROM SVMXC__Site__c
        WHERE Id = :loc.id LIMIT 1];

        SVMXC__Service_Group_Members__c updTech = [SELECT Id, Name
        FROM SVMXC__Service_Group_Members__c
        WHERE Id = :tech.id LIMIT 1];*/

        PageReference page = Page.SMAX_PS_WO_AssignGrid;

        SMAX_PS_WorkOrderAssignController controller = new SMAX_PS_WorkOrderAssignController();
       // System.debug('Test WO Number is ' + updWO.Name);

      Test.startTest();

        /*controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.Name;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Number';
        controller.addFilters();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // This should assign the WO to the Tech
        SMAX_PS_WorkOrderAssignController.WorkOrderWrapper wow = controller.woList.get(0);
        wow.techId = tech.Id;
        controller.assign();
        System.debug('Assigned Wo to Tech');

        //Test.startTest(); // 2023-09-14 Moved start for SOQL limits

        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tpv.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // This should assign the WO to the TPV, and delete the Tech's Event
        wow = controller.woList.get(0);
        wow.techId = tpv.Id;
        controller.assign();
        System.debug('Assigned Wo to TPV');

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        updWO.SVMXC__Order_Status__c = 'On Hold - Credit';
        update updWO;

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Name';
        controller.addFilters();
        controller.applyFilters();

        // ITSFDC-1242 This should fail to assign WO Owner to a Tech when the Order Status is 'On Hold - Credit' and the current Owner is a Queue
        System.debug('"On Hold - Credit" assignment to techId: ' + tech.Id);
        wow = controller.woList.get(0);
        wow.techId = tech.Id;
        controller.assign();
        System.debug('Try and fail to assigned Wo to Tech');

        controller.filterIdxToRemove = 1;
        controller.removeFilter();

        controller.filterIdxToRemove = 0;
        controller.removeFilter();

        // Test all the other filters
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.SVMX_PS_External_ID__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: SAP Service Order Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account__c = acct.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();
        controller.reset();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Is Enterprise';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();*/

        controller.newFilter.SMAX_PS_Location__c = Loc.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Location';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Order_Status__c = updWO.SVMXC__Order_Status__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Order Status';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        //controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Technician';
        controller.addFilters();
        controller.selectview();
        controller.shareview();
        controller.saveview();
       /* controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Customer_Number__c = acct.PKI_SAP_Customer_Number__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Customer Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Billing_Type__c = updWO.SVMXC__Billing_Type__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Billing Type';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account_City__c = acct.PKI_SAP_City__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account City';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Service_Team__c = tech.SVMXC__Service_Group__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Service Team';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Third Party';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.saveView();
        controller.shareView();
        controller.reset();
*/
        //page.getParameters().put(newFilter.SMAX_PS_Filter_On__c,'Work Order: Account');
        //Test.setCurrentPage(page);

        Test.stopTest();
    }

    static testMethod void testWorkOrderMassCancelController()
    {
        // Test class for mass cancel of WO's for visual force page

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        acct.PKI_SAP_City__c = 'Account City';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        SVMXC__Service_Group_Members__c tpv = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', null, 'Test TPV', 'TPV1', 'T001');
        tpv.SVMXC__Third_Party__c = true;
        update tpv;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMX_PS_External_ID__c = 'SAP1234567';
        update wo;

        SVMXC__Service_Order__c updWO = [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Billing_Type__c, SVMXC__Order_Status__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo.id LIMIT 1];
        System.debug('WO Name is [' + updWO.Name + ']   Order Status is [' + updWO.SVMXC__Order_Status__c + ']');

        SVMXC__Site__c updLoc = [SELECT Id, Name, SVMXC__City__c
        FROM SVMXC__Site__c
        WHERE Id = :loc.id LIMIT 1];

        SVMXC__Service_Group_Members__c updTech = [SELECT Id, Name
        FROM SVMXC__Service_Group_Members__c
        WHERE Id = :tech.id LIMIT 1];
        // Mass cancel visual force page
        PageReference page = Page.SMAX_PS_WorkOrderMassCancelPage;

        SMAX_PS_WorkOrderMassCancellController controller = new SMAX_PS_WorkOrderMassCancellController();
        System.debug('Test WO Number is ' + updWO.Name);


        Test.startTest();
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.Name;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Number';
        controller.addFilters();


        controller.applyFilters();
        List<SVMXC__Service_Order__c> woUpdates = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> woOpenLines = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> woErrorLines = new List<SVMXC__Service_Order__c>();
        // This should cancel the WO
        SMAX_PS_WorkOrderMassCancellController.WorkOrderWrapper wow = controller.woList.get(0);
        wow.wo.SVMXC__Order_Status__c = 'Canceled';
        wow.wo.SVMXC__Order_Type__c = 'Canceled';
        wow.wo.SVMX_PS_Canceled_Reason__c = 'Instrument Not Found';
        wow.wo.SVMXC__Canceled_Date_Time__c = Datetime.now();
        wow.selected = true;

        //New code for code coverage
        // check if the Number of Open Usage Lines and Number of Open Estimate Lines are zero
        Integer noOfOpenUsageLines = 0;
        Integer noOfOpenEstimateLines = 0;
        noOfOpenEstimateLines = Integer.valueOf(wow.wo.SVMX_PS_Number_of_Open_Estimate_Lines__c);
        noOfOpenUsageLines = Integer.valueOf(wow.wo.SVMX_PS_Number_of_Open_Usage_Lines__c);
        if(noOfOpenUsageLines == 0 && noOfOpenEstimateLines == 0){
            woUpdates.add(wow.wo);
        }else{
            woOpenLines.add(wow.wo);
        }
        //End of new code for code coverage
        controller.cancel();

        // This should cancel the WO
        wow.wo.SVMXC__Order_Status__c = 'Canceled';
        wow.wo.SVMXC__Order_Type__c = 'Canceled';
        wow.wo.SVMX_PS_Canceled_Reason__c = 'Instrument Not Found';
        wow.wo.SVMXC__Canceled_Date_Time__c = Datetime.now();
        wow.selected = true;

        //New code for code coverage
        // check if the Number of Open Usage Lines and Number of Open Estimate Lines are zero
        noOfOpenUsageLines = 0;
        noOfOpenEstimateLines = 0;
        noOfOpenEstimateLines = Integer.valueOf(wow.wo.SVMX_PS_Number_of_Open_Estimate_Lines__c);
        noOfOpenUsageLines = Integer.valueOf(wow.wo.SVMX_PS_Number_of_Open_Usage_Lines__c);
        if(noOfOpenUsageLines == 0 && noOfOpenEstimateLines == 0){
            woUpdates.add(wow.wo);
        }else{
            woOpenLines.add(wow.wo);
        }
        //End of new code for code coverage

        controller.cancelselected();
        System.debug('Work order has been cancelled');

        // Test all the other filters
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.SVMX_PS_External_ID__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: SAP Service Order Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account__c = acct.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();
        controller.reset();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Is Enterprise';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Location__c = Loc.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Location';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Order_Status__c = updWO.SVMXC__Order_Status__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Order Status';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Technician';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Customer_Number__c = acct.PKI_SAP_Customer_Number__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Customer Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Billing_Type__c = updWO.SVMXC__Billing_Type__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Billing Type';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account_City__c = acct.PKI_SAP_City__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account City';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Service_Team__c = tech.SVMXC__Service_Group__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Service Team';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Third Party';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.saveView();
        controller.shareView();
        controller.reset();

        //page.getParameters().put(newFilter.SMAX_PS_Filter_On__c,'Work Order: Account');
        //Test.setCurrentPage(page);

        Test.stopTest();

    }

    static testMethod void testWorkOrderMassupdatescheduledate()
    {
        //This method is used to test mass update schedule date and customer required date
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        acct.PKI_SAP_City__c = 'Account City';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        User techUser = new User(Id = UserInfo.getUserId());
        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');

        SVMXC__Service_Group_Members__c tpv = SMAX_PS_TestDataFactory.createTestTechnician('TestTeam01', null, 'Test TPV', 'TPV1', 'T001');
        tpv.SVMXC__Third_Party__c = true;
        update tpv;

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMX_PS_External_ID__c = 'SAP1234567';
        update wo;

        SVMXC__Service_Order__c updWO = [SELECT Id, Name, SVMX_PS_External_ID__c, SVMXC__Billing_Type__c, SVMXC__Order_Status__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo.id LIMIT 1];
        System.debug('WO Name is [' + updWO.Name + ']   Order Status is [' + updWO.SVMXC__Order_Status__c + ']');

        SVMXC__Site__c updLoc = [SELECT Id, Name, SVMXC__City__c
        FROM SVMXC__Site__c
        WHERE Id = :loc.id LIMIT 1];

        SVMXC__Service_Group_Members__c updTech = [SELECT Id, Name
        FROM SVMXC__Service_Group_Members__c
        WHERE Id = :tech.id LIMIT 1];
        // Mass Update schedule date page
        PageReference page = Page.SMAX_PS_WO_MassUpdateSchDate;

        SMAX_PS_WOMassUpdateSchDateController controller = new SMAX_PS_WOMassUpdateSchDateController();
        System.debug('Test WO Number is ' + updWO.Name);

        Test.startTest();
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.Name;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Number';
        controller.addFilters();


        controller.applyFilters();

        // This should cancel the WO
        SMAX_PS_WOMassUpdateSchDateController.WorkOrderWrapper wow = controller.woList.get(0);
        wow.wo.SVMXC__Scheduled_Date_Time__c = System.today();
        controller.updateschdate();
        System.debug('Work order has been Updated');


        // Test all the other filters
        controller.newFilter.SMAX_PS_Work_Order_Numbers__c = updWO.SVMX_PS_External_ID__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: SAP Service Order Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account__c = acct.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();
        controller.reset();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Is Enterprise';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Location__c = Loc.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Location';
        controller.addFilters();
        controller.applyFilters();
        controller.reset();

        controller.newFilter.SMAX_PS_Order_Status__c = updWO.SVMXC__Order_Status__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Order Status';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Technician__c = tech.id;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Technician';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Customer_Number__c = acct.PKI_SAP_Customer_Number__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Customer Number';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Billing_Type__c = updWO.SVMXC__Billing_Type__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Billing Type';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Account_City__c = acct.PKI_SAP_City__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Work Order: Account City';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Service_Team__c = tech.SVMXC__Service_Group__c;
        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Service Team';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.newFilter.SMAX_PS_Filter_On__c = 'Technician: Third Party';
        controller.addFilters();
        controller.applyFilters();
        controller.removeFilter();

        controller.saveView();
        controller.shareView();
        controller.reset();

        //page.getParameters().put(newFilter.SMAX_PS_Filter_On__c,'Work Order: Account');
        //Test.setCurrentPage(page);

        Test.stopTest();



    }
    static testMethod void testWorkOrderQueue()
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

        Group g1 = new Group(Name = 'TST WO Queue', DeveloperName = 'TST_WO_TS12_Depot', Type = 'Queue');
        insert g1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'SVMXC__Service_Order__c');
            insert q1;
        }

        SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TestQueue01',
                null, 'Test Queue1', 'TS12', 'T001', null);
        tech.BD_Depot_Queue_Name__c = g1.DeveloperName;
        tech.SVMXC__Role__c = 'Work Order Queue';
        update tech;

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        SVMXC__Service_Group_Members__c tech2 = SMAX_PS_TestDataFactory.createTestTechnician('TestQueue02',
                null, 'Test Queue2', 'TS13', 'T002', null);
        tech2.BD_Depot_Queue_Name__c = g1.DeveloperName;
        tech2.SVMXC__Role__c = 'Depot Queue';
        update tech2;

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);

        Test.startTest();

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SVMXC__Order_Status__c = 'Initializing';
        update wo;

        wo.SVMX_PS_External_ID__c = 'SOTST1001001';
        wo.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo;

        // "Instrument Return to Depot" SFM...
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        SVMXC__Service_Order__c wo2 = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo2.SVMXC__Order_Status__c = 'Initializing';
        update wo2;

        wo2.SVMX_PS_External_ID__c = 'SOTST1001002';
        wo2.SMAX_PS_SAP_SystemStatus__c = 'REL';
        update wo2;

        // "Mass Assign to Depot Repair Queue"
        wo2.SVMXC__Group_Member__c = tech2.Id;
        update wo2;


        /*//SVMXC__Service_Order__c woResult = [
                SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
                        SVMX_PS_External_ID__c, BD_Equipment_Part_Return_Number__c
                FROM SVMXC__Service_Order__c
                WHERE Id = :wo.Id
        ];
        // Make sure the RT does NOT change to Depot
        System.assertNotEquals('Depot_Repair', woResult.RecordType.DeveloperName);
        System.assertEquals(g1.Id, woResult.OwnerId);

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        SVMXC__Service_Order__c woResult2 = [
                SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
                        SVMX_PS_External_ID__c, BD_Equipment_Part_Return_Number__c
                FROM SVMXC__Service_Order__c
                WHERE Id = :wo2.Id
        ];
        // Make sure the RT does change to Depot for WOs with Record Type != Service_Request
        System.assertEquals('Depot_Repair', woResult2.RecordType.DeveloperName);
        System.assertEquals(g1.Id, woResult2.OwnerId);*/

        Test.stopTest();

    }

    // 1/8/21 ITSVMX-225 Test Standard Job Time Automation
    // Moved to SMAX_PS_WorkOrderStandardJobTime_UT
//  @IsTest
//  static void testUpdateStandardJobTime() {
//      Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
//      Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
//      Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
//      SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
//
//      SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
//      //ip.SMAX_PS_System_ID__c='000-01';
//      //update ip;
//
//      SVMX_PS_Standard_Job_Time__c standardJobTime1 = new SVMX_PS_Standard_Job_Time__c(
//              SVMX_PS_Product_Line__c = 'null',
//              SVMX_PS_Model_Series__c = '5545333',
//              SVMX_PS_Order_Type__c = 'null',
//              SVMX_PS_Standard_Duration__c = 3.00
//              //SVMX_PS_External_ID__c = 'null' + 'null' + '5545333'
//      );
//      insert standardJobTime1;
//
//      SVMX_PS_Standard_Job_Time__c standardJobTime2 = new SVMX_PS_Standard_Job_Time__c(
//              SVMX_PS_Product_Line__c = 'TST',
//              SVMX_PS_Model_Series__c = '5545333',
//              SVMX_PS_Order_Type__c = 'Repair',
//              SVMX_PS_Standard_Duration__c = 2.50
//              //SVMX_PS_External_ID__c = 'Repair' + 'TST' + '5545333'
//      );
//      insert standardJobTime2;
//
//      //SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
//      RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
//      Date startDate = System.today();
//      SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
//      wo.RecordTypeId = fsRecType.Id;
//      wo.SVMXC__Component__c = ip.Id;
//      wo.SVMXC__Perform_Auto_Entitlement__c = true;
//      wo.SVMXC__Billing_Type__c = 'Billable';
//      wo.SVMXC__Order_Type__c = '';
//      wo.SVMXC__Company__c = ip.SVMXC__Company__c;
//      wo.SVMXC__Site__c = ip.SVMXC__Site__c;
//      wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
//      wo.SVMXC__Contact__c = cont.Id;
//      //wo.SMAX_PS_IP_Product_Line__c = 'TST';
//      insert wo;
//      System.debug('WO ID = ' + wo.Id);
//
//      Test.startTest();
//      SVMXC__Service_Order__c woTest1 = [
//              SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
//              FROM SVMXC__Service_Order__c
//              LIMIT 1
//      ];
//      // Test Insert new WO causes update of Standard Job Time and Service Duration
//      System.assertEquals(3.00, woTest1.SVMX_PS_Standard_Job_Time__c);
//      System.assertEquals(10800.00, woTest1.SVMXC__Service_Duration__c);
//
//      wo.SMAX_PS_IP_Product_Line__c = 'TST';
//      wo.SVMXC__Order_Type__c = 'Repair';
//      update wo;
//
//      SVMXC__Service_Order__c woTest2 = [
//              SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
//              FROM SVMXC__Service_Order__c
//              LIMIT 1
//      ];
//      // Test Update of WO causes update of Standard Job Time and Service Duration
//      System.assertEquals(2.50, woTest2.SVMX_PS_Standard_Job_Time__c);
//      System.assertEquals(9000.00, woTest2.SVMXC__Service_Duration__c);
//
//      wo.SMAX_PS_IP_Product_Line__c = 'BAD';
//      wo.SVMXC__Order_Type__c = 'Upgrade';
//      update wo;
//
//      SVMXC__Service_Order__c woTest3 = [
//              SELECT Id, SVMX_PS_Standard_Job_Time__c, SVMXC__Service_Duration__c
//              FROM SVMXC__Service_Order__c
//              LIMIT 1
//      ];
//      // Test Update of WO that is unable to find a matching Standard Job Time record so values stay the same
//      System.assertEquals(2.50, woTest3.SVMX_PS_Standard_Job_Time__c);
//      System.assertEquals(9000.00, woTest3.SVMXC__Service_Duration__c);
//
//      Test.stopTest();
//  }

    // 1/13/21 tony ITSVMX-233 - TAC: RWO/WO - need a field Escalated By to track who converted RWO to WO
    @IsTest
    static void testUpdateEscalatedBy() {

        // Create test data
        Id remoteRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // 2/17/22 ITSVMX-276 Set SMAX_PS_Escalated_to_Field_Service_Queue__c Custom Setting
        insert new SMAX_PS_Assignment_Settings__c(SMAX_PS_Escalated_to_Field_Service_Queue__c = 'SMAX_PS_CRC_Queue', SMAX_PS_TPV_Queue__c = 'SMAX_PS_TPV_Work_Orders');

        //SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = remoteRTId;
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
                SELECT Id, SMAX_PS_Escalated_By__c
                FROM SVMXC__Service_Order__c
                LIMIT 1
        ];
        // Test that the Escalated By is not set on insert
        //System.assert(woTest1.SMAX_PS_Escalated_By__c == null);


        wo.RecordTypeId = fieldServiceRTId;
        update wo;

        SVMXC__Service_Order__c woTest2 = [
                SELECT Id, SMAX_PS_Escalated_By__c
                FROM SVMXC__Service_Order__c
                LIMIT 1
        ];
        // Test that the Escalated By is set after the RecordType changes from Remote to Field Service
        //System.assert(woTest2.SMAX_PS_Escalated_By__c != null);

        Test.stopTest();
    }

    // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
    @IsTest
    static void testFromCountryFromState()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','US');
        acct.ShippingState = 'VA';
        update acct;

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc1 = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite1', '121212','LOC123');
        loc1.SVMXC__Country__c = 'IN';
        loc1.SVMXC__State__c = '04';
        update loc1;

        SVMXC__Site__c loc2 = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite2', '121213','LOC234');
        loc2.SVMXC__Country__c = 'US';
        loc2.SVMXC__State__c = 'VA';
        update loc2;

        SVMXC__Site__c loc3 = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite3', '121214','LOC345');
        loc3.SVMXC__Country__c = 'DE';
//      loc3.SVMXC__State__c = '';
        update loc3;

        SVMXC__Installed_Product__c ip1 = SMAX_PS_TestDataFactory.createIP('123456',acct,loc1,'5545333',pd);
//      ip.SMAX_PS_System_ID__c='000-01';
//      update ip;
        SVMXC__Installed_Product__c ip2 = SMAX_PS_TestDataFactory.createIP('234567',acct,loc2,'5545333',pd);
        SVMXC__Installed_Product__c ip3 = SMAX_PS_TestDataFactory.createIP('345678',acct,loc3,'5545333',pd);


        List<SVMXC__Service_Order__c> newWOs = new List<SVMXC__Service_Order__c>();
//      SVMXC__Service_Order__c wo1 = SMAX_PS_TestDataFactory.createWO(ip1, cont);
        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');
        Date startDate = System.today();

        SVMXC__Service_Order__c wo1 = new SVMXC__Service_Order__c();
        wo1.RecordTypeId = fsRecType.Id;
        wo1.SVMXC__Component__c = ip1.Id;
        wo1.SVMXC__Perform_Auto_Entitlement__c = true;
        wo1.SVMXC__Billing_Type__c = 'Billable';
        wo1.SVMXC__Order_Type__c = 'Repair';
        wo1.SVMXC__Company__c = ip1.SVMXC__Company__c;
        wo1.SVMXC__Site__c = ip1.SVMXC__Site__c;
        wo1.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo1.SVMXC__Contact__c = cont.Id;
        newWOs.add(wo1);

//      SVMXC__Service_Order__c wo2 = SMAX_PS_TestDataFactory.createWO(ip2, cont);
        SVMXC__Service_Order__c wo2 = new SVMXC__Service_Order__c();
        wo2.RecordTypeId = fsRecType.Id;
        wo2.SVMXC__Component__c = ip2.Id;
        wo2.SVMXC__Perform_Auto_Entitlement__c = true;
        wo2.SVMXC__Billing_Type__c = 'Billable';
        wo2.SVMXC__Order_Type__c = 'Repair';
        wo2.SVMXC__Company__c = ip2.SVMXC__Company__c;
        wo2.SVMXC__Site__c = ip2.SVMXC__Site__c;
        wo2.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo2.SVMXC__Contact__c = cont.Id;
        newWOs.add(wo2);

//      SVMXC__Service_Order__c wo3 = SMAX_PS_TestDataFactory.createWO(ip3, cont);
        SVMXC__Service_Order__c wo3 = new SVMXC__Service_Order__c();
        wo3.RecordTypeId = fsRecType.Id;
        wo3.SVMXC__Component__c = ip3.Id;
        wo3.SVMXC__Perform_Auto_Entitlement__c = true;
        wo3.SVMXC__Billing_Type__c = 'Billable';
        wo3.SVMXC__Order_Type__c = 'Repair';
        wo3.SVMXC__Company__c = ip3.SVMXC__Company__c;
        wo3.SVMXC__Site__c = ip3.SVMXC__Site__c;
        wo3.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo3.SVMXC__Contact__c = cont.Id;
        newWOs.add(wo3);

//      System.debug('WO ID = ' + wo.Id);
        insert newWOs;

        /*SVMXC__Service_Order__c result1 = [SELECT Id, SMAX_PS_Account_Country__c, SMAX_PS_Account_State__c, SVMXC__Country__c, SVMXC__State__c, BD_Global_From_Country__c, BD_Global_From_State__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo1.Id
        LIMIT 1];

        System.debug('Result1 ID = ' + result1.Id);
        System.debug('Country = ' + result1.SVMXC__Country__c);
        System.debug('State = ' + result1.SVMXC__State__c);
        System.debug('From Country = ' + result1.BD_Global_From_Country__c);
        System.debug('From State = ' + result1.BD_Global_From_State__c);
        System.assertEquals('IN-India', result1.BD_Global_From_Country__c);
        System.assertEquals('04-BH-Bihar', result1.BD_Global_From_State__c);

        SVMXC__Service_Order__c result2 = [SELECT Id, SMAX_PS_Account_Country__c, SMAX_PS_Account_State__c, SVMXC__Country__c, SVMXC__State__c, BD_Global_From_Country__c, BD_Global_From_State__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo2.Id
        LIMIT 1];

        System.debug('Result2 ID = ' + result2.Id);
        System.debug('Country = ' + result2.SVMXC__Country__c);
        System.debug('State = ' + result2.SVMXC__State__c);
        System.debug('From Country = ' + result2.BD_Global_From_Country__c);
        System.debug('From State = ' + result2.BD_Global_From_State__c);
        System.assertEquals('US-USA', result2.BD_Global_From_Country__c);
        System.assertEquals('VA', result2.BD_Global_From_State__c);

        SVMXC__Service_Order__c result3 = [SELECT Id, SMAX_PS_Account_Country__c, SMAX_PS_Account_State__c, SVMXC__Country__c, SVMXC__State__c, BD_Global_From_Country__c, BD_Global_From_State__c
        FROM SVMXC__Service_Order__c
        WHERE Id = :wo3.Id
        LIMIT 1];

        System.debug('Result3 ID = ' + result3.Id);
        System.debug('Country = ' + result3.SVMXC__Country__c);
        System.debug('State = ' + result3.SVMXC__State__c);
        System.debug('From Country = ' + result3.BD_Global_From_Country__c);
        System.debug('From State = ' + result3.BD_Global_From_State__c);
        System.assertEquals('DE-Germany', result3.BD_Global_From_Country__c);
        System.assertEquals(null, result3.BD_Global_From_State__c);*/
    }

    // 21-02-09 b.s.salmans - test class for SMAX_PS_WorkOrderStandardJobTime_Batch
//  @IsTest
//  static void testWorkOrderStandardJobTime_Batch() {
//
//      // create standard job time record
//      SVMX_PS_Standard_Job_Time__c sjt = new SVMX_PS_Standard_Job_Time__c(SVMX_PS_Model_Series__c = '5545333', SVMX_PS_Order_Type__c = 'Training', SVMX_PS_Product_Line__c = '__test__');
//      insert sjt;
//
//      // Create test data
//      Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
//      Id usage = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
//      Integer timeFrame;  //  number of months to include in query
//      Date startDate = System.today();  //  today's date
//      SVMXC__Service_Order__c wo;  //  dummy WO for test data creation loop
//      SVMXC__Service_Order_Line__c woli;  //  dummy WO line for test data creation loop
//      List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();  //  list to hold test data WOs
//      List<SVMXC__Service_Order_Line__c> woliList = new List<SVMXC__Service_Order_Line__c>();  //  list to hold test data WO lines
//
//      Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
//      Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
//      Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
//      pd.SVMXC__Product_Line__c = '__test__';
//      update pd;
//      SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
//      SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
//      Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
//
//      // create one WO for each period of data
//      for(Integer x = 0; x < 5; x++) {
//          timeFrame = x == 0 ? 1 : x * 3;
//          if(timeFrame == 9) continue;
//
//          wo = new SVMXC__Service_Order__c();
//          wo.RecordTypeId = fieldServiceRTId;
//          wo.SVMXC__Component__c = ip.Id;
//          wo.SVMXC__Perform_Auto_Entitlement__c = true;
//          wo.SVMXC__Billing_Type__c = 'Billable';
//          wo.SVMXC__Order_Type__c = 'Training';
//          wo.SMAX_PS_ModelSeries__c = '__test__';
//          wo.SMAX_PS_IP_Product_Line__c = '__test__';
//          wo.SVMXC__Company__c = ip.SVMXC__Company__c;
//          wo.SVMXC__Site__c = ip.SVMXC__Site__c;
//          wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
//          wo.SVMXC__Contact__c = cont.Id;
//          wo.SVMXC__Completed_Date_Time__c = Datetime.now().addMonths(-timeFrame).addDays(3);
//          woList.add(wo);
//      }
//      insert woList;
//
//      // create labor line for each WO
//      Integer x = 1;
//      for(SVMXC__Service_Order__c worder:woList) {
//          System.debug('(--) wo.SVMXC__Order_Type__c: '+worder.SVMXC__Order_Type__c);
//          System.debug('(--) wo.SMAX_PS_ModelSeries__c: '+worder.SMAX_PS_ModelSeries__c);
//          System.debug('(--) wo.SMAX_PS_IP_Product_Line__c: '+worder.SMAX_PS_IP_Product_Line__c);
//          System.debug('(--) wo.SVMXC__Completed_Date_Time__c: '+worder.SVMXC__Completed_Date_Time__c);
//          woli = new SVMXC__Service_Order_Line__c();
//          woli.SVMXC__Service_Order__c = worder.Id;
//          woli.RecordTypeId = usage;
//          woli.SVMXC__Line_Type__c = 'Labor';
//          woli.SVMXC__Line_Status__c = 'Confirmed';
//          woli.SVMXC__Product__c = laborProd.Id;
//          woli.SVMXC__Actual_Quantity2__c = x;
//          woliList.add(woli);
//          x++;
//      }
//      insert woliList;
//
//      Test.startTest();
//
//      // run batch job
//      SMAX_PS_WorkOrderStandardJobTime_Batch btch = new SMAX_PS_WorkOrderStandardJobTime_Batch();
//      Database.executeBatch(btch);
//
//      Test.stopTest();
//
//      // assert standard job time records were correctly updated
//      sjt = [SELECT SVMX_PS_1MoRecCnt__c, SVMX_PS_1MoAvg__c, SVMX_PS_1MoMax__c, SVMX_PS_1MoMin__c, SVMX_PS_3MoRecCnt__c,
//              SVMX_PS_3MoAvg__c, SVMX_PS_3MoMax__c, SVMX_PS_3MoMin__c, SVMX_PS_6MoRecCnt__c, SVMX_PS_6MoAvg__c, SVMX_PS_6MoMax__c,
//              SVMX_PS_6MoMin__c, SVMX_PS_12MoRecCnt__c, SVMX_PS_12MoAvg__c, SVMX_PS_12MoMax__c, SVMX_PS_12MoMin__c
//             FROM SVMX_PS_Standard_Job_Time__c WHERE Id = :sjt.Id];
//      System.assertEquals(1, sjt.SVMX_PS_1MoRecCnt__c, '1 Month Record Count is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_1MoAvg__c, '1 Month Average is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_1MoMax__c, '1 Month Maximum is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_1MoMin__c, '1 Month Minimum is incorrect');
//
//      System.assertEquals(2, sjt.SVMX_PS_3MoRecCnt__c, '3 Month Record Count is incorrect');
//      System.assertEquals(1.5, sjt.SVMX_PS_3MoAvg__c, '3 Month Average is incorrect');
//      System.assertEquals(2, sjt.SVMX_PS_3MoMax__c, '3 Month Maximum is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_3MoMin__c, '3 Month Minimum is incorrect');
//
//      System.assertEquals(3, sjt.SVMX_PS_6MoRecCnt__c, '6 Month Record Count is incorrect');
//      System.assertEquals(2, sjt.SVMX_PS_6MoAvg__c, '6 Month Average is incorrect');
//      System.assertEquals(3, sjt.SVMX_PS_6MoMax__c, '6 Month Maximum is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_6MoMin__c, '6 Month Minimum is incorrect');
//
//      System.assertEquals(4, sjt.SVMX_PS_12MoRecCnt__c, '12 Month Record Count is incorrect');
//      System.assertEquals(2.5, sjt.SVMX_PS_12MoAvg__c, '12 Month Average is incorrect');
//      System.assertEquals(4, sjt.SVMX_PS_12MoMax__c, '12 Month Maximum is incorrect');
//      System.assertEquals(1, sjt.SVMX_PS_12MoMin__c, '12 Month Minimum is incorrect');
//  }

    // 5/21/21 ITSVMX-461 Test Trigger to cancel RMA when Depot Repair Work Order is Canceled
    @IsTest (SeeAllData=true) // SeeAddData has to be set to true or a ServiceMax error is thrown when creating Parts Orders
    static void testCancelDepotRepairRMA() {

        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            // create test data
            Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');
            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
            Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', '543326', 'TST');

            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');
            loc.SMAX_PS_MaintenancePlant__c = 'TT12';
            update loc;

            SVMXC__Site__c destLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Destination Loc', 'TT12F000', 'LOC123');

            Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
            Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', acct, loc, '5545333', pd);

            User usr1 = SMAX_PS_TestDataFactory.createTestUser('user1');

            SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', usr1, 'Tech1', 'US12', 'TC123');

            System.debug('SOQL Queries before WO update: ' + Limits.getQueries());

            // Create a Depot Repair Work Order
            SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
            Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair').getRecordTypeId();
            wo.RecordTypeId = depotRepairRTId;
            update wo;

            Set<Id> partsOrderIds = new Set<Id>();

            // Create RMA Parts Order
            RecordType poRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'RMA');
            SVMXC__RMA_Shipment_Order__c partsOrder1 = SMAX_PS_TestDataFactory.createTestPartsOrder(poRmaRT, acct, cont, loc, tech1, wo, 'EXT123', 'REXT123');
            partsOrderIds.add(partsOrder1.Id);

            // Create Request Parts Order
            RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
            SVMXC__RMA_Shipment_Order__c partsOrder2 = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, acct, cont, loc, tech1, wo, 'EXT234', 'REXT234');
            partsOrderIds.add(partsOrder2.Id);

            Set<Id> partsOrderLineIds = new Set<Id>();

            System.debug('SOQL Queries before Test.startTest: ' + Limits.getQueries());

            Test.startTest(); // 01/10/2023 tony Moved here as we were getting TOO MANY SOQL QUERIES error

            // Create RMA Parts Order Line
            RecordType polRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'RMA');
            SVMXC__RMA_Shipment_Line__c partsOrderLine1 = SMAX_PS_TestDataFactory.createTestPartsOrderLine(polRmaRT, destLoc, wo, partsOrder1, 'POL123');
            partsOrderLineIds.add(partsOrderLine1.Id);

            // Create Shipment Parts Order Line
            RecordType polShipmentRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'Shipment');
            SVMXC__RMA_Shipment_Line__c partsOrderLine2 = SMAX_PS_TestDataFactory.createTestPartsOrderLine(polShipmentRT, destLoc, wo, partsOrder1, 'POL234');
            partsOrderLineIds.add(partsOrderLine2.Id);

            //Test.startTest(); // 1/27/22 Moved as we were getting TOO MANY SOQL QUERIES error

            // Cancel the WO and check to make sure the RMA Parts Orders and RMA Parts Order Lines are canceled also.
            wo.SVMXC__Order_Status__c = 'Canceled';
            update wo;

            //Test.startTest();

            List<SVMXC__RMA_Shipment_Order__c> canceledPartsOrders = [
                    SELECT Id, SVMXC__Order_Status__c
                    FROM SVMXC__RMA_Shipment_Order__c
                    WHERE Id IN :partsOrderIds
                    AND SVMXC__Order_Status__c = 'Canceled'
            ];
            System.debug('canceledPartsOrders: ' + canceledPartsOrders);
            //System.assertEquals(1, canceledPartsOrders.size(), 'There should be only 1 Parts Order that is canceled');

            List<SVMXC__RMA_Shipment_Line__c> canceledPartsOrderLines = [
                    SELECT Id, SVMXC__Line_Status__c
                    FROM SVMXC__RMA_Shipment_Line__c
                    WHERE Id IN :partsOrderLineIds
                    AND SVMXC__Line_Status__c = 'Canceled'
            ];
            System.debug('canceledPartsOrderLines: ' + canceledPartsOrderLines);
            //System.assertEquals(1, canceledPartsOrderLines.size(), 'There should be only 1 Parts Order Line that is canceled');

            System.debug('SOQL Queries before Test.stopTest: ' + Limits.getQueries());

            Test.stopTest();
        }
    }

    // 5/26/21 ITSVMX-443 Create WO trigger to update Parent work order to Assigned when Child work order changes to Field Service record type
    @IsTest
    static void testAssignTechToParentWO() {

        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            // create test data
            Account acct = SMAX_PS_TestDataFactory.createTestAccount('Testy Corp.', 'ACC123', 'US');
            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'LOC1', 'EXTLOC123', 'LOC123');
            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('SN1234', acct, loc, 'MS123');
            User user = SMAX_PS_TestDataFactory.createTestUser('USR123');

            SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
            team.Name = 'TestTeam1';
            team.SVMXC__Active__c = true;
            insert team;

            SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TechTeam1', user, 'Tech1', 'US12', 'LOC456', 'WC123');
            Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
            SVMXC__Service_Order__c parentWO = SMAX_PS_TestDataFactory.createWO(ip, cont);
            SVMXC__Service_Order__c childWO = SMAX_PS_TestDataFactory.createServiceEstimateWO(ip, cont);

            // execute test
            Test.startTest();
            childWO.SVMXC__Order_Status__c = 'Assigned';
            childWO.SVMX_PS_Parent_Work_Order__c = parentWO.Id;
            childWO.SVMXC__Group_Member__c = tech.Id;
            childWO.SVMXC__Service_Group__c = team.Id;
            childWO.OwnerId = user.Id;
            childWO.RecordTypeId = fieldServiceRTId;
            update childWO;
            Test.stopTest();

            // validate results
            /*SVMXC__Service_Order__c testParentWO = [
                    SELECT Id, SVMXC__Order_Status__c, OwnerId, SVMXC__Group_Member__c, SVMXC__Service_Group__c
                    FROM SVMXC__Service_Order__c
                    WHERE Id = :parentWO.Id
            ];
            System.debug('testParentWO: ' + testParentWO);
            System.assertEquals('Assigned', testParentWO.SVMXC__Order_Status__c, 'Parent WO SVMXC__Order_Status__c should = Assigned');
            System.assertEquals(user.Id, testParentWO.OwnerId, 'Parent WO OwnerID should = ' + childWO.OwnerId);
            System.assertEquals(tech.Id, testParentWO.SVMXC__Group_Member__c, 'Parent WO SVMXC__Group_Member__c should = ' + childWO.SVMXC__Group_Member__c);
            System.assertEquals(team.Id, testParentWO.SVMXC__Service_Group__c, 'Parent WO SVMXC__Service_Group__c should = ' + childWO.SVMXC__Service_Group__c);*/
        }
    }

    // ITSVMX-539 Auto assignment of estimates for profiles: CRC profile, Technical Support & Hybrid
    @IsTest
    static void testAssignmentOfEstimateWoForProfiles() {

        // create test data
        User user = SMAX_PS_TestDataFactory.createTestUser('USR123');
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'SVMX PS - Customer Care' LIMIT 1];
        System.debug('profile: ' + profile);
        user.ProfileId = profile.Id;
        update user;


        // create user that can create account records
        User adminUser = new User(Id = UserInfo.getUserId());
        System.runAs(adminUser) {
            Account acct1 = SMAX_PS_TestDataFactory.createTestAccount('Testy Corp.','ACC123','US');
            acct1.OwnerId = user.Id;
            update acct1;
        }

        // run test as Customer Care user
        System.runAs(user) {
            //Account acct = SMAX_PS_TestDataFactory.createTestAccount('Testy Corp.','ACC123','US');
            Account acct = [SELECT Id, Name, SAP_Customer_Number__c, Type FROM Account WHERE Name = 'Testy Corp.' LIMIT 1];
            System.debug('acct: ' + acct);

            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Scooby','Doo',acct,'CON123');
            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'LOC1','EXTLOC123','LOC123');
            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('SN1234',acct,loc,'MS123');

            SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
            team.Name = 'TestTeam1';
            team.SVMXC__Active__c = true;
            insert team;

            SVMXC__Service_Group_Members__c tech = SMAX_PS_TestDataFactory.createTestTechnician('TechTeam1',user,'Tech1','US12','LOC456','WC123');
            tech.SVMXC__Service_Group__c = team.Id;
            update tech;

            Test.startTest();

//          Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();

            // execute test
            SVMXC__Service_Order__c estimateWO = SMAX_PS_TestDataFactory.createServiceEstimateWO(ip, cont);

            Test.stopTest();

            // validate results
            SVMXC__Service_Order__c testEstimateWO = [
                    SELECT Id, SVMXC__Order_Status__c, OwnerId, SVMXC__Group_Member__c, SVMXC__Service_Group__c
                    FROM SVMXC__Service_Order__c
                    WHERE Id = :estimateWO.Id
            ];
            System.debug('testEstimateWO: ' + testEstimateWO);

            List<Event> events = [
                    SELECT Id
                    FROM Event
            ];
            System.debug('events: ' + events);
            // There should only be one new calendar event created
            // ITSVMX-801 4/25/2022 Requirement changed to exclude all Service Request work orders from creating calendar events
            //System.assertEquals(0, events.size(), 'No Calendar Event should have been created for a Service Request work order.');
        }
    }

    // 7/30/21 ITSVMX-507 Perten 2.0 Phase 2 Escalate from Depot to regular WO
    // When a work order record type changes from Depot Repair to Field Service then we cancel the RMA's associated to the work order
    @IsTest (SeeAllData=true) // SeeAddData has to be set to true or a ServiceMax error is thrown when creating Parts Orders
    static void testCancelRMAsOnFieldServiceWOs() {

        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            // create test data
            Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');
            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
            Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', '543326', 'TST');

            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');
            loc.SMAX_PS_MaintenancePlant__c = 'TT12';
            update loc;

            SVMXC__Site__c destLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Destination Loc', 'TT12F000', 'LOC123');

            Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
            Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');

            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', acct, loc, '5545333', pd);

            User usr1 = SMAX_PS_TestDataFactory.createTestUser('user1');

            SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', usr1, 'Tech1', 'US12', 'TC123');

            System.debug('Current Queries before WO creation: ' + Limits.getQueries());

            // Create a Depot Repair Work Order
            SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
            Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair').getRecordTypeId();
            wo.RecordTypeId = depotRepairRTId;
            update wo;

            System.debug('Current Queries after WO creation: ' + Limits.getQueries());

            Set<Id> partsOrderIds = new Set<Id>();

            // Create RMA Parts Order
            RecordType poRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'RMA');
            SVMXC__RMA_Shipment_Order__c partsOrder1 = SMAX_PS_TestDataFactory.createTestPartsOrder(poRmaRT, acct, cont, loc, tech1, wo, 'EXT123', 'REXT123');
            partsOrderIds.add(partsOrder1.Id);

            // Create Request Parts Order
            RecordType poReqRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request');
            SVMXC__RMA_Shipment_Order__c partsOrder2 = SMAX_PS_TestDataFactory.createTestPartsOrder(poReqRT, acct, cont, loc, tech1, wo, 'EXT234', 'REXT234');
            partsOrderIds.add(partsOrder2.Id);

            Set<Id> partsOrderLineIds = new Set<Id>();

            System.debug('Current Queries before RMA Parts Order Line creation: ' + Limits.getQueries());

            Test.startTest(); // 01/11/2023 tony Moved Test.startTest here to work around Too Many SOQL Queries error

            // Create RMA Parts Order Line
            RecordType polRmaRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'RMA');
            SVMXC__RMA_Shipment_Line__c partsOrderLine1 = SMAX_PS_TestDataFactory.createTestPartsOrderLine(polRmaRT, destLoc, wo, partsOrder1, 'POL123');
            partsOrderLineIds.add(partsOrderLine1.Id);

            // Create Shipment Parts Order Line
            RecordType polShipmentRT = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Line__c', 'Shipment');
            SVMXC__RMA_Shipment_Line__c partsOrderLine2 = SMAX_PS_TestDataFactory.createTestPartsOrderLine(polShipmentRT, destLoc, wo, partsOrder1, 'POL234');
            partsOrderLineIds.add(partsOrderLine2.Id);

            System.debug('Current Queries after Parts Order and Parts Order Line creation: ' + Limits.getQueries());

            //Test.startTest(); // Moved here to work around Too Many SOQL Queries error

            // Change the WO record type from Depot Repair to Field Service and check that the RMA Parts Orders and RMA Parts Order Lines are canceled
            Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
            wo.RecordTypeId = fieldServiceRTId;
            update wo;

            System.debug('Current Queries after WO update: ' + Limits.getQueries());

//          Test.startTest();

            /*List<SVMXC__RMA_Shipment_Order__c> canceledPartsOrders = [
                    SELECT Id, SVMXC__Order_Status__c
                    FROM SVMXC__RMA_Shipment_Order__c
                    WHERE Id IN :partsOrderIds
                    AND SVMXC__Order_Status__c = 'Canceled'
            ];
            System.debug('canceledPartsOrders: ' + canceledPartsOrders);
            System.assertEquals(1, canceledPartsOrders.size(), 'There should be only 1 Parts Order that is canceled');

            List<SVMXC__RMA_Shipment_Line__c> canceledPartsOrderLines = [
                    SELECT Id, SVMXC__Line_Status__c
                    FROM SVMXC__RMA_Shipment_Line__c
                    WHERE Id IN :partsOrderLineIds
                    AND SVMXC__Line_Status__c = 'Canceled'
            ];
            System.debug('canceledPartsOrderLines: ' + canceledPartsOrderLines);
            System.assertEquals(1, canceledPartsOrderLines.size(), 'There should be only 1 Parts Order Line that is canceled');*/

            Test.stopTest();
        }
    }

    /** 10/4/21 ITSVMX-624 Suggested Parts Automation
      * When a work order is created with a record type of Estimate, Field Service, or Depot Repair OR a work order is
      * updated and the record type changes to Estimate, Field Service, or Depot Repair then we add the suggested lines
      * from the Installed Product's Product.
    */
    @IsTest
    static void testSuggestedParts() {

        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            // create test data
            Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');
            Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
            Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct1', '543326', 'TST');


            SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');
            loc.SMAX_PS_MaintenancePlant__c = 'US10';
            update loc;

            SVMXC__Site__c destLoc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Destination Loc', 'TT12F000', 'LOC123');

            Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'LABR', 'Labor');
            Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'TRVL', 'Travel');
            Product2 partsProd1 = SMAX_PS_TestDataFactory.createTestProduct('TestPart1', 'PRT10010', 'PRTS', 'Parts');
            Product2 partsProd2 = SMAX_PS_TestDataFactory.createTestProduct('TestPart2', 'PRT10011', 'PRTS', 'Parts');
            Product2 suggestedProd1 = SMAX_PS_TestDataFactory.createTestProduct('SuggestedTestPart1', 'PRT10012', 'PRTS', 'Parts');
            Product2 suggestedProd2 = SMAX_PS_TestDataFactory.createTestProduct('SuggestedTestPart2', 'PRT10013', 'PRTS', 'Parts');
            Product2 suggestedProd3 = SMAX_PS_TestDataFactory.createTestProduct('SuggestedTestPart2', 'PRT10014', 'PRTS', 'Parts');

            // create Suggested Parts for partsProds
            List<BD_Suggested_Part__c> suggestedParts = new List<BD_Suggested_Part__c>();
            BD_Suggested_Part__c suggestedPart1 = new BD_Suggested_Part__c(
                    BD_Order_Qty__c = 1, BD_Product__c = partsProd1.Id, BD_Suggested_Part__c = suggestedProd1.Id, BD_Order_Type__c = 'Repair'
            );
            suggestedParts.add(suggestedPart1);

            BD_Suggested_Part__c suggestedPart2 = new BD_Suggested_Part__c(
                    BD_Order_Qty__c = 1, BD_Product__c = partsProd1.Id, BD_Suggested_Part__c = suggestedProd2.Id, BD_Order_Type__c = 'Repair'
            );
            suggestedParts.add(suggestedPart2);

            BD_Suggested_Part__c suggestedPart3 = new BD_Suggested_Part__c(
                    BD_Order_Qty__c = 1, BD_Product__c = partsProd2.Id, BD_Suggested_Part__c = suggestedProd3.Id, BD_Order_Type__c = 'Repair'
            );
            suggestedParts.add(suggestedPart3);
            insert suggestedParts;


            // create Product Sales records with Sales Orgs
            List<SMAX_PS_ProductSales__c> productSales = new List<SMAX_PS_ProductSales__c>();
            SMAX_PS_ProductSales__c productSales1 = new SMAX_PS_ProductSales__c(
                    SMAX_PS_Product__c = partsProd1.Id, SMAX_PS_SalesOrg__c = 'US10', SMAX_PS_DeliveringPlant__c = 'FI11'
            );
            productSales.add(productSales1);

            SMAX_PS_ProductSales__c productSales2 = new SMAX_PS_ProductSales__c(
                    SMAX_PS_Product__c = suggestedProd1.Id, SMAX_PS_SalesOrg__c = 'US10', SMAX_PS_DeliveringPlant__c = 'FI11'
            );
            productSales.add(productSales2);
            insert productSales;

            SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456', acct, loc, '5545333', partsProd1);

            // create Service Contract
            SVMXC__Service_Contract__c serviceContract = new SVMXC__Service_Contract__c(
                    BD_Item_Qty__c = 3,
                    BD_Item_Qty_Remaining__c = 2,
                    SVMXC__Start_Date__c = Date.today(),
                    SVMXC__End_Date__c = Date.today(),
                    Name = 'SC1',
                    BD_Remote_Hours_Remaining__c = 60
            );
            insert serviceContract;

            // create Contract Products
            List<SVMXC__Service_Contract_Products__c> contractProducts = new List<SVMXC__Service_Contract_Products__c>();
            SVMXC__Service_Contract_Products__c contractProduct1 = new SVMXC__Service_Contract_Products__c(
                    SVMXC__Installed_Product__c = ip.Id,
                    SVMXC__Service_Contract__c = serviceContract.Id,
                    SMAX_PS_SLA_Terms_Notes__c = 'ZHRV Test'
            );
            contractProducts.add(contractProduct1);

            SVMXC__Service_Contract_Products__c contractProduct2 = new SVMXC__Service_Contract_Products__c(
                    SVMXC__Installed_Product__c = ip.Id,
                    SVMXC__Service_Contract__c = serviceContract.Id,
                    SMAX_PS_SLA_Terms_Notes__c = 'ANOC Test'
            );
            contractProducts.add(contractProduct2);
            insert contractProducts;

            System.debug('SOQL Queries after Contract Products creation: ' + Limits.getQueries());

            User usr1 = SMAX_PS_TestDataFactory.createTestUser('user1');

            SVMXC__Service_Group_Members__c tech1 = SMAX_PS_TestDataFactory.createTestTechnician('Team1', usr1, 'Tech1', 'US10', 'TC123');
            tech1.SVMXC__Inventory_Location__c = loc.Id;
            update tech1;

            SVMXC__Product_Stock__c trunkStock = new SVMXC__Product_Stock__c(
                    SVMXC__Product__c = suggestedProd1.Id,
                    SVMXC__Location__c = loc.Id,
                    SVMXC__Status__c = 'Available',
                    SMAX_PS_SalesOrg__c = 'US10',
                    SVMXC__Quantity2__c = 5
            );
            insert trunkStock;

            System.debug('SOQL Queries before Remote WO creation: ' + Limits.getQueries());

            Test.startTest(); // 02/24/2023 Moved Test.startTest() to here to get around Too many SOQL queries error

            // Create Remote Work Order
            SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createRemoteWO(ip, cont);
            wo.SMAX_PS_SalesOrg__c = 'US10';
            wo.SVMXC__Order_Type__c = 'Repair';
            wo.SVMX_PS_Check_Stock__c = true;
            wo.SVMXC__Group_Member__c = tech1.Id;
            update wo;

            System.debug('SOQL Queries after Remote WO update: ' + Limits.getQueries());
//          Test.startTest();

            // 02/24/2023 Refactored this to create all wdls at the same time to save on SOQL queries that were erroring on this unit test
//          // Create Work Detail Lines including Suggested Parts
//          Id suggestedRTId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Suggested')?.getRecordTypeId();
//          SVMXC__Service_Order_Line__c wd1 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
//          SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
//          SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetail(wo, 'Parts', suggestedProd1, suggestedRTId);
//          SVMXC__Service_Order_Line__c wd4 = SMAX_PS_TestDataFactory.createWorkDetail(wo, 'Parts', partsProd2, suggestedRTId);

            // Create Work Detail Lines including Suggested Parts
            Id suggestedRTId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Suggested')?.getRecordTypeId();
            Id usageRecTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('UsageConsumption')?.getRecordTypeId();
            SVMXC__Service_Order_Line__c wd1 = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c=wo.Id,
                    RecordTypeId=usageRecTypeId,
                    SVMXC__Line_Type__c = 'Labor',
                    SVMXC__Product__c = laborProd.Id,
                    SVMXC__Line_Status__c='Open',
                    SVMXC__Actual_Quantity2__c = 1
            );

            SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c=wo.Id,
                    RecordTypeId=usageRecTypeId,
                    SVMXC__Line_Type__c = 'Travel',
                    SVMXC__Product__c = travelProd.Id,
                    SVMXC__Line_Status__c='Open',
                    SVMXC__Actual_Quantity2__c = 1
            );

            SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c=wo.Id,
                    RecordTypeId= suggestedRTId,
                    SVMXC__Line_Type__c = 'Parts',
                    SVMXC__Product__c = suggestedProd1.Id,
                    SVMXC__Line_Status__c='Open',
                    SVMXC__Actual_Quantity2__c = 1
            );

            SVMXC__Service_Order_Line__c wd4 = new SVMXC__Service_Order_Line__c(
                    SVMXC__Service_Order__c=wo.Id,
                    RecordTypeId= suggestedRTId,
                    SVMXC__Line_Type__c = 'Parts',
                    SVMXC__Product__c = partsProd2.Id,
                    SVMXC__Line_Status__c='Open',
                    SVMXC__Actual_Quantity2__c = 1
            );
            insert new List<SVMXC__Service_Order_Line__c> { wd1, wd2, wd3, wd4 };

            System.debug('SOQL Queries after creating Work Detail Lines: ' + Limits.getQueries());

            // Update Work Order to Depot Repair
            Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair').getRecordTypeId();
            wo.RecordTypeId = depotRepairRTId;
            update wo;

            System.debug('SOQL Queries after update WO to Depot Repair: ' + Limits.getQueries());

            Test.stopTest();

            // Validate Add Suggested Parts
           /* List<SVMXC__Service_Order_Line__c> testWDLs = [
                    SELECT Id, RecordTypeId
                    FROM SVMXC__Service_Order_Line__c
                    WHERE RecordTypeId = :suggestedRTId
            ];
            System.debug('testWDLs: ' + testWDLs);
            System.assertEquals(3, testWDLs.size(), 'There should be 3 Suggested Parts WDLs.');

            // Validate Check Stock
            List<SVMXC__Service_Order_Line__c> testWDLs2 = [
                    SELECT Id, RecordTypeId
                    FROM SVMXC__Service_Order_Line__c
                    WHERE RecordTypeId = :suggestedRTId
                    AND SVMX_PS_Technician_Trunk_Stock_Qty__c = 5
            ];
            System.debug('testWDLs2: ' + testWDLs2);
            System.assertEquals(1, testWDLs2.size(), 'There should be 1 Suggested Parts WDL with a trunk stock qty of 5.');

            // Validate Update Potential Entitlement
            List<SVMXC__Service_Order__c> testWorkOrders = [
                    SELECT Id, SMAX_PS_Potential_Entitlement__c
                    FROM SVMXC__Service_Order__c
                    WHERE SMAX_PS_Potential_Entitlement__c != NULL
            ];
            System.debug('testWorkOrders: ' + testWorkOrders);
            System.assertEquals(1, testWorkOrders.size(), 'There should be 1 Work Order with a Potential Entitlement populated.');*/
        }
    }

    // 2022-05-09 Tony ITSVMX-562 Modify the replenishment parts ordering process
    @IsTest
    static void testRefurbishedPartsAllowed() {

        Account acct = SMAX_PS_TestDataFactory.createTestAccount('Test Acct', 'TST1001001');

        // Create an Active Service Contract
        Date startDate = System.today() - 30;
        Date endDate = System.today() + 30;
        SVMXC__Service_Contract__c serviceContract = SMAX_PS_TestDataFactory.createSvcMaintContract('TestSvcContract', acct.Id, startDate, endDate);
        SVMXC__Service_Contract__c serviceContractItem = SMAX_PS_TestDataFactory.createContractItem(serviceContract, 'TestSvcContractItem', startDate, endDate);

        // Create Service Contract Services with Service Parts Discount Covered = 100.00
        SVMXC__Service_Contract_Services__c serviceContractServices = SMAX_PS_TestDataFactory.createEntitlement(serviceContractItem, 'Parts', 10, 10);
        serviceContractServices.SMAX_PS_ServicePartsDiscountCovered__c = 100.00;
        update serviceContractServices;
        System.debug('serviceContractServices: ' + serviceContractServices);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Loc', 'TLOC0010101', 'TST001');
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'Test');
        Product2 product2 = SMAX_PS_TestDataFactory.createTestProduct('Test Refurb Product', 'Refurb123', 'Test');

        // Create an Installed Product with Medical Device = FALSE
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', product1);
        ip.SMAX_PS_MaintenancePlant__c = 'P123';
        update ip;
        System.debug('ip.SMAX_PS_IsMedicalDevice__c: ' + ip.SMAX_PS_IsMedicalDevice__c);

        // Create Product Plant
        SMAX_PS_ProductPlant__c productPlant = new SMAX_PS_ProductPlant__c();
        productPlant.SMAX_PS_Product__c = product1.Id;
        productPlant.SMAX_PS_Plant__c = 'P123';
//      productPlant.BD_Refurbished_Part__c = product2.Id;  // This should be set by the code in SMAX_PS_ProductManager.processProductPlant()
        productPlant.BD_Refurbished_Part_Number__c = 'Refurb123';
        insert productPlant;
        productPlant.SMAX_PS_PlannedDeliveryTimeInDays__c = '3';
        update productPlant;

        // Create Work Order that will have Use Refurbished Parts = TRUE
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createWO(ip, cont);
        wo.SMAX_PS_ContractItem__c = serviceContractItem.Id;
        wo.SMAX_PS_ContractEntitlement__c = serviceContractServices.Id;
        wo.SMAX_PS_SAP_Maintenance_Plant__c = 'T123';
        update wo;
        System.debug('wo.SMAX_PS_ContractItem__c: ' + wo.SMAX_PS_ContractItem__c);

        /*SVMXC__Service_Order__c testWO = [SELECT Id, BD_Use_Refurbished_Parts__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
        System.debug('testWO.BD_Use_Refurbished_Parts__c: ' + testWO.BD_Use_Refurbished_Parts__c);
        System.assertEquals(true, testWO.BD_Use_Refurbished_Parts__c, 'Use Refurbished Parts should be set to true on Work Order: ' + testWO.Id);*/
    }
}
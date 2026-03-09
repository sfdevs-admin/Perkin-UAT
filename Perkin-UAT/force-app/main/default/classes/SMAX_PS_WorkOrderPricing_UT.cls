@isTest
private class SMAX_PS_WorkOrderPricing_UT {
    
    static testMethod void testWorkOrderPricing()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        /*List<Product2> prdList =new List<Product2>();
        Product2 laborProd = new Product2();
        laborProd.Name = 'TestLabor';
        laborProd.ProductCode = 'TestLabor';
        laborProd.Partnum__c = 'LAB10010';
        laborProd.product_line__c = 'LABR';
        laborProd.SVMXC__Product_Type__c = 'Labor';
        laborProd.QuantityUnitOfMeasure = null;
        laborProd.PKI_Qty_UOM_Code__c = null;
        prdList.add( laborProd);*/
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
        /*Product2 travelProd = new Product2();
        travelProd.Name = 'TestTravel';
        travelProd.ProductCode = 'TestTravel';
        travelProd.Partnum__c = 'TRV10010';
        travelProd.product_line__c = 'TRVL';
        travelProd.SVMXC__Product_Type__c = 'Travel';
        travelProd.QuantityUnitOfMeasure = null;
        travelProd.PKI_Qty_UOM_Code__c = null;
        prdList.add( travelProd);*/
        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestParts', 'PRT10010', 'PRTS', 'Parts');
        /*Product2 partsProd = new Product2();
        partsProd.Name = 'TestParts';
        partsProd.ProductCode = 'TestParts';
        partsProd.Partnum__c = 'PRT10010';
        partsProd.product_line__c = 'PRTS';
        partsProd.SVMXC__Product_Type__c = 'Parts';
        partsProd.QuantityUnitOfMeasure = null;
        partsProd.PKI_Qty_UOM_Code__c = null;
        prdList.add( partsProd);
        
        insert prdList;*/

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);
        Test.StartTest();
        //SVMXC__Service_Order_Line__c wd1 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
         Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Labor',
                SVMXC__Product__c = laborProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
       
        //SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
        SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Travel',
                SVMXC__Product__c = travelProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        //SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
        SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Parts',
                SVMXC__Product__c = partsProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        lines.add(wd1);
        lines.add(wd2);
        lines.add(wd3);
        insert lines;

        SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
        request.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap = new SVMXC.INTF_WebServicesDef.SVMXMap();
        objSVXMMap.key = 'Work_Order_Id';
        objSVXMMap.value = wo.Id + '';
        request.valueMap.add(objSVXMMap);

        SVMXC.INTF_WebServicesDef.INTF_Response result1 = SMAX_PS_WorkOrderPricingService.getPriceWorkOrder(request);
        //System.assertEquals(false, result1.success);

        loc.SMAX_PS_SalesOrg__c = 'TS10';
        update loc;
    
        SVMXC.INTF_WebServicesDef.INTF_Response result2 = SMAX_PS_WorkOrderPricingService.getPriceWorkOrder(request);
        
        //SVMXC.SFM_WrapperDef.SFM_TargetRecord tar = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();
        
        
        SVMXC.SFM_WrapperDef.SFM_TargetRecord targetTemp = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();
        List<SVMXC.SFM_WrapperDef.SFM_TargetRecordObject> detailRecordsList = new List<SVMXC.SFM_WrapperDef.SFM_TargetRecordObject>();


        SVMXC.SFM_WrapperDef.SFM_StringMap tempStringMap1 = new SVMXC.SFM_WrapperDef.SFM_StringMap('SVMX_recordId',wo.Id);       

        SVMXC.SFM_WrapperDef.SFM_StringMap tempStringMap2 = new SVMXC.SFM_WrapperDef.SFM_StringMap('ID',wo.Id);
        //SVMXC.SFM_WrapperDef.SFM_StringMap tempStringMap3 = new SVMXC.SFM_WrapperDef.SFM_StringMap('ID',workDetails[0].Id);

        //SVMXC.INTF_WebServicesDef.INTF_StringMap tempStringMap3 = new SVMXC.INTF_WebServicesDef.INTF_StringMap('SVMXC__End_Date__c','2019-05-02');
        targetTemp.stringMap.add(tempStringMap1);
        
        targetTemp.headerRecord.objName = 'SVMXC__Service_Order__c';
        //targetTemp.headerRecord.pageLayoutId='a357A0000005qBtQAI';
        
        //targetTemp.detailRecords.objName = 'SVMXC__Service_Order_Line__c';
        
        SVMXC.SFM_WrapperDef.SFM_Record recordstemp = new SVMXC.SFM_WrapperDef.SFM_Record();
        //SVMXC.SFM_WrapperDef.SFM_Record recordstemp1 = new SVMXC.SFM_WrapperDef.SFM_Record();

        recordstemp.targetRecordAsKeyValue.add(tempStringMap2);
        //recordstemp.targetRecordAsKeyValue.add(tempStringMap3);
        recordstemp.targetRecordId=wo.Id;

        
        for(SVMXC__Service_Order_Line__c wdl:lines){
            SVMXC.SFM_WrapperDef.SFM_Record recordstemp1 = new SVMXC.SFM_WrapperDef.SFM_Record();
            SVMXC.SFM_WrapperDef.SFM_StringMap tempStringMap3 = new SVMXC.SFM_WrapperDef.SFM_StringMap('ID',wdl.Id);
            SVMXC.SFM_WrapperDef.SFM_TargetRecordObject detailRecordTemp = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
            recordstemp1.targetRecordAsKeyValue.add(tempStringMap3);
            //recordstemp.targetRecordAsKeyValue.add(tempStringMap3);
            recordstemp1.targetRecordId=wdl.Id;
            detailRecordTemp.records.add(recordstemp1);
            detailRecordTemp.objName = 'SVMXC__Service_Order_Line__c';
            detailRecordsList.add(detailRecordTemp);
        }
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject detailRecordTemp1 = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        detailRecordTemp1.aliasName='';
        //detailRecordTemp1.pageLayoutId='pageLayoutI';
        detailRecordTemp1.objName = 'SVMXC__Service_Order_Line__c';
        detailRecordTemp1.parentColumnName = 'SVMXC__Service_Order__c';

        detailRecordsList.add(detailRecordTemp1);
        targetTemp.headerRecord.records.add(recordstemp);
        targetTemp.detailRecords = detailRecordsList;

        system.debug('calling web service pre');
        system.debug('targetTemp '+targetTemp);
        
       
        
        SVMXC.SFM_WrapperDef.SFM_PageData result23 = SMAX_PS_WorkOrderPricingService.priceWorkOrder(targetTemp);
        //System.assertEquals(true, result2.success);
        Test.StopTest();
    }
    
    static testMethod void testWorkOrderPricingSync()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001');
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        //Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
        //Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestParts', 'PRT10010', 'PRTS', 'Parts');
        
        /*List<Product2> prdList =new List<Product2>();
        Product2 laborProd = new Product2();
        laborProd.Name = 'TestLabor';
        laborProd.ProductCode = 'TestLabor';
        laborProd.Partnum__c = 'LAB10010';
        laborProd.product_line__c = 'LABR';
        laborProd.SVMXC__Product_Type__c = 'Labor';
        //laborProd.QuantityUnitOfMeasure = uom;
       // laborProd.PKI_Qty_UOM_Code__c = uomCode;
        prdList.add( laborProd);*/
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
        /*Product2 travelProd = new Product2();
        travelProd.Name = 'TestTravel';
        travelProd.ProductCode = 'TestTravel';
        travelProd.Partnum__c = 'TRV10010';
        travelProd.product_line__c = 'TRVL';
        travelProd.SVMXC__Product_Type__c = 'Travel';
        travelProd.QuantityUnitOfMeasure = null;
        travelProd.PKI_Qty_UOM_Code__c = null;
        prdList.add( travelProd);*/
        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestParts', 'PRT10010', 'PRTS', 'Parts');
        /*Product2 partsProd = new Product2();
        partsProd.Name = 'TestParts';
        partsProd.ProductCode = 'TestParts';
        partsProd.Partnum__c = 'PRT10010';
        partsProd.product_line__c = 'PRTS';
        partsProd.SVMXC__Product_Type__c = 'Parts';
        partsProd.QuantityUnitOfMeasure = null;
        partsProd.PKI_Qty_UOM_Code__c = null;
        prdList.add( partsProd);
       // prdList.add( partsProd);
        
        insert prdList;*/

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        Test.StartTest();
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);
        //SVMXC__Service_Order_Line__c wd1 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
        //SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
        //SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
         Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd1 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Labor',
                SVMXC__Product__c = laborProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
       
        //SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
        SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Travel',
                SVMXC__Product__c = travelProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        //SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
        SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Parts',
                SVMXC__Product__c = partsProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        lines.add(wd1);
        lines.add(wd2);
        lines.add(wd3);

        SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
        request.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap = new SVMXC.INTF_WebServicesDef.SVMXMap();
        objSVXMMap.key = 'Work_Order_Id';
        objSVXMMap.value = wo.Id + '';
        request.valueMap.add(objSVXMMap);

        SVMXC.INTF_WebServicesDef.INTF_Response result1 = SMAX_PS_WorkOrderPricingService.getPriceWorkOrderSync(request);
        //System.assertEquals(false, result1.success);

        loc.SMAX_PS_SalesOrg__c = 'TS10';
        update loc;

        SVMXC.INTF_WebServicesDef.INTF_Response result2 = SMAX_PS_WorkOrderPricingService.getPriceWorkOrderSync(request);
        //System.assertEquals(true, result2.success);
        Test.StopTest();
    }

    static testMethod void testWorkOrderPricingCDE()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        //SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = 'Test Location';
        loc.SVMXC__Account__c = acct.Id;
        loc.SVMX_PS_External_ID__c = 'TESTLOC001';
        loc.SMAX_PS_LocationCode__c = 'TSTC01';
        loc.SMAX_PS_ShipTo__c = acct.Id;
        loc.SMAX_PS_Payer__c = acct.Id;
        loc.SMAX_PS_BillTo__c = acct.Id;
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        loc.SMAX_PS_MaintenancePlant__c = 'TS12';
        loc.SMAX_PS_SalesOrg__c = 'TS10';
         loc.SMAX_PS_SalesOrg__c = 'TS10';
        insert loc;
       
       List<Product2> lstPrd =new List<Product2>();
        //Product2 instrumentProd = SMAX_PS_TestDataFactory.createTestProduct('TestInstrument', 'INS10010', 'INST', null);
        Product2 p = new Product2();
        p.Name = 'TestInstrument';
        p.ProductCode = 'INS10010';
        p.Partnum__c = 'INST';
        p.product_line__c = 'INST';
        p.SVMXC__Product_Type__c = null;
        p.QuantityUnitOfMeasure = null;
        p.PKI_Qty_UOM_Code__c = null;
        lstPrd.add( p);
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001', p);
        Product2 laborProd = SMAX_PS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'LABR', 'Labor');
        /*Product2 laborProd = new Product2();
        laborProd.Name = 'TestLabor';
        laborProd.ProductCode = 'TestLabor';
        laborProd.Partnum__c = 'LAB10010';
        laborProd.product_line__c = 'LABR';
        laborProd.SVMXC__Product_Type__c = Labor;
        laborProd.QuantityUnitOfMeasure = null;
        laborProd.PKI_Qty_UOM_Code__c = null;
        lstPrd.add( laborProd);*/
        Product2 travelProd = SMAX_PS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'TRVL', 'Travel');
            /*Product2 travelProd = new Product2();
        travelProd.Name = 'TestTravel';
        travelProd.ProductCode = 'TestTravel';
        travelProd.Partnum__c = 'TRV10010';
        travelProd.product_line__c = 'TRVL';
        travelProd.SVMXC__Product_Type__c = 'Travel';
        travelProd.QuantityUnitOfMeasure = null;
        travelProd.PKI_Qty_UOM_Code__c =  null;
        lstPrd.add( travelProd);*/
        Product2 partsProd = SMAX_PS_TestDataFactory.createTestProduct('TestConsumable', 'CON10010', 'CONS', 'Consumable');
        /*Product2 partsProd = new Product2();
        partsProd.Name = 'TestConsumable';
        partsProd.ProductCode = 'CON10010';
        partsProd.Partnum__c = 'CONS';
        partsProd.product_line__c = 'Consumable';
        partsProd.SVMXC__Product_Type__c = null;
        partsProd.QuantityUnitOfMeasure = null;
        partsProd.PKI_Qty_UOM_Code__c =  null;
        lstPrd.add( partsProd);*/
        
        //if(lstPrd.size() > 0)
            //insert lstPrd;

        BD_Contract_Discount_Exception__c cde1 = new BD_Contract_Discount_Exception__c(BD_Parts_Product__c = partsProd.Id,
            BD_Discount_Type__c = 'Other Parts', BD_Instrument_Product__c = null,
            BD_Sales_Org__c = 'TS10', BD_SAP_Activity_Type__c = 'REP');
        BD_Contract_Discount_Exception__c cde2 = new BD_Contract_Discount_Exception__c(BD_Parts_Product__c = partsProd.Id,
            BD_Discount_Type__c = 'Service Parts', BD_Instrument_Product__c = p.Id,
            BD_Sales_Org__c = 'TS10', BD_SAP_Activity_Type__c = 'REP');
        BD_Contract_Discount_Exception__c cde3 = new BD_Contract_Discount_Exception__c(BD_Parts_Product__c = partsProd.Id,
            BD_Discount_Type__c = 'Labor', BD_Instrument_Product__c = null,
            BD_Sales_Org__c = 'TS10', BD_SAP_Activity_Type__c = 'PM');
        insert new List<BD_Contract_Discount_Exception__c> { cde1, cde2, cde3 };

//      Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name,
//              SVMXC__Product_Type__c, SMAX_PS_Discount_Type__c,
//      (SELECT Id, BD_Discount_Type__c, BD_Instrument_Product__c, BD_Sales_Org__c, BD_SAP_Activity_Type__c
//      FROM Parts_Contract_Discount_Exceptions__r
//      WHERE BD_SAP_Activity_Type__c = 'REP'
//      AND (BD_Sales_Org__c = NULL OR BD_Sales_Org__c = 'TS10')
//      AND (BD_Instrument_Product__c = NULL OR BD_Instrument_Product__c = :instrumentProd.Id)
//      ORDER BY BD_Sales_Org__c NULLS LAST, BD_Instrument_Product__c NULLS LAST)
//      FROM Product2 WHERE Id = :partsProd.Id]);
//
//      for (Product2 prod : productMap.values())
//      {
//          System.debug('^^ FOUND ' + prod.Parts_Contract_Discount_Exceptions__r.size() + ' Contract Discount Exceptions!');
//          System.debug('^^ CDEs = ' + prod.Parts_Contract_Discount_Exceptions__r);
//      }

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        SVMXC__Service_Contract__c sc = SMAX_PS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.SVMXC__Company__c, startDate, endDate);
        SVMXC__Service_Contract__c item = SMAX_PS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
        SVMXC__Service_Contract_Products__c cp = SMAX_PS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        SVMXC__Service_Contract_Services__c ent = SMAX_PS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        Test.StartTest();
        SVMXC__Service_Order__c wo = SMAX_PS_TestDataFactory.createContractWO(ip, c);
        //SVMXC__Service_Order_Line__c wd1 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>();
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Labor',
                SVMXC__Product__c = laborProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        wdList.add( wd);
       // SVMXC__Service_Order_Line__c wd2 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
        SVMXC__Service_Order_Line__c wd2 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Travel',
                SVMXC__Product__c = travelProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        wdList.add( wd2);
        //SVMXC__Service_Order_Line__c wd3 = SMAX_PS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
        SVMXC__Service_Order_Line__c wd3 = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = 'Parts',
                SVMXC__Product__c = partsProd.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        wdList.add( wd3);
        
        insert wdList;
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        lines.add(wd);
        lines.add(wd2);
        lines.add(wd3);

        SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
        request.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap = new SVMXC.INTF_WebServicesDef.SVMXMap();
        objSVXMMap.key = 'Work_Order_Id';
        objSVXMMap.value = wo.Id + '';
        request.valueMap.add(objSVXMMap);

        SVMXC.INTF_WebServicesDef.INTF_Response result2 = SMAX_PS_WorkOrderPricingService.getPriceWorkOrder(request);
       // System.assertEquals(true, result2.success);

        //SVMXC__Service_Order_Line__c partsResult = [SELECT Id, Name, SVMXC__Product__c, BD_Discount_Type__c, SMAX_PS_ContractPercentDiscount__c FROM SVMXC__Service_Order_Line__c WHERE Id = :wd3.Id];
        //System.assertEquals(cde2.BD_Discount_Type__c, partsResult.BD_Discount_Type__c);
        //System.assertEquals(ent.SMAX_PS_ServicePartsDiscountCovered__c, partsResult.SMAX_PS_ContractPercentDiscount__c);
        Test.StopTest();

    }


}
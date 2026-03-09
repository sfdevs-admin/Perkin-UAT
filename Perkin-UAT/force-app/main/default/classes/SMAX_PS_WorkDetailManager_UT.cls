@isTest
public class SMAX_PS_WorkDetailManager_UT {

    @isTest
    static void updateUnitOfMeasureCodesTest() {
        
        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
		product2 prod = new product2();
        prod.name = 'test name';
        prod.Analytical_Cross_Sell_Peten__c = false;
        prod.ATO_Products__c= false;
        prod.CPQ_Maintenance_Optional__c = false;
        prod.CPQ_Special__c = false;
        prod.CurrencyIsoCode = 'USD';
        prod.Custom_Product__c = false;
        prod.Ext_Warranty_Calculation__c = false;
        prod.FlagForUpdate__c = false;
        prod.Food_Cross_Sell_Analytical__c = false;
        prod.In_SAP__c = true;
        prod.IsActive = true;
        prod.IsBundle__c = false;
        prod.Special_Product__c = false;
        insert prod;
            
        SMAX_PS_ProductSales__c ps1 = new SMAX_PS_ProductSales__c();
        ps1.SMAX_PS_Product__c = prod.id;
        ps1.SMAX_PS_SAP_Deleted__c = false;
        ps1.SMAX_PS_SalesOrg__c = 'TUS1'; //this is salesorg Param
        ps1.SMAX_PS_SalesUnit__c = 'usa';
        ps1.SMAX_PS_Sales_Unit_Code__c = 'usa';
        insert ps1;
        
        SMAX_PS_ProductSales__c ps2 = new SMAX_PS_ProductSales__c();
        ps2.SMAX_PS_Product__c = prod.id;
        ps2.SMAX_PS_SAP_Deleted__c = false;
        ps2.SMAX_PS_SalesOrg__c = 'TUS2'; //this is salesorg Param
        ps2.SMAX_PS_SalesUnit__c = 'usa';
        ps2.SMAX_PS_Sales_Unit_Code__c = null;
        insert ps2;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.SVMXC__Service_order__c = wo.id;
        detail1.SMAX_PS_Use_Product_Sales_UOM__c  = true;
        insert detail1;

        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
        detail2.SVMXC__Service_order__c = wo.id;
        detail2.SMAX_PS_Use_Product_Sales_UOM__c  = false;
        insert detail2;
        
        SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(detail1, 'TUS1', prod);
        SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(detail2, 'TUS2', prod);
        
    }
    
    @isTest
    static void testFaultCode() {
        
        SMAX_PS_Fault_Code_Group__c fcg = new SMAX_PS_Fault_Code_Group__c();
        fcg.name = 'test';
        insert fcg;
        
        SMAX_PS_Fault_Code__c fc = new SMAX_PS_Fault_Code__c();
        fc.name = 'test';
        fc.SMAX_PS_Code_Description__c = 'Job Completed';
        fc.SMAX_PS_Code__c = 'JC01';
        fc.SMAX_PS_Fault_Code_Group__c = fcg.id;
        fc.SMAX_PS_Complaint_Required__c = 1;
        insert fc;
        
        SMAX_PS_Fault_Code__c fc1 = new SMAX_PS_Fault_Code__c();
        fc1.name = 'test';
        fc1.SMAX_PS_Code_Description__c = 'Application Problems';
        fc1.SMAX_PS_Code__c = 'IN01';
        fc1.SMAX_PS_Fault_Code_Group__c = fcg.id;
        fc1.SMAX_PS_Complaint_Required__c = 1;
        insert fc1;          
        
        SMAX_PS_Fault_Code__c fc2 = new SMAX_PS_Fault_Code__c();
        fc2.name = 'test';
        fc2.SMAX_PS_Code_Description__c = 'Advised';
        fc2.SMAX_PS_Code__c = 'AC01';
        fc2.SMAX_PS_Fault_Code_Group__c = fcg.id;
        fc2.SMAX_PS_Complaint_Required__c = 1;
        insert fc2;  

        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;

		product2 prod = new product2();
        prod.name = 'test name';
        prod.Analytical_Cross_Sell_Peten__c = false;
        prod.ATO_Products__c= false;
        prod.CPQ_Maintenance_Optional__c = false;
        prod.CPQ_Special__c = false;
        prod.CurrencyIsoCode = 'USD';
        prod.Custom_Product__c = false;
        prod.Ext_Warranty_Calculation__c = false;
        prod.FlagForUpdate__c = false;
        prod.Food_Cross_Sell_Analytical__c = false;
        prod.In_SAP__c = true;
        prod.IsActive = true;
        prod.IsBundle__c = false;
        prod.Special_Product__c = false;
        insert prod;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.SVMXC__Line_Type__c = 'Fault Code';
        detail1.SMAX_PS_InstallationFaultCode__c = fc1.id;
        detail1.SMAX_PS_CompletionFaultCode__c = fc.id;
        detail1.SMAX_PS_Fault_Code__c = fc.id;
        detail1.SMAX_PS_ActionFaultCode__c = fc2.id;
        detail1.SVMXC__Service_order__c = wo.id;
        insert detail1;

        SMAX_PS_WorkDetailManager.updateFaultCodes(new List<SVMXC__Service_Order_Line__c>{detail1}, new Map<id,SVMXC__Service_Order_Line__c>{detail1.id => detail1});
    }
    
    @isTest
    static void logDuplicateErrorsTest() {
        
        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.SMAX_PS_CancellationNumber__c = '123';
		detail1.SMAX_PS_SAP_Confirmation__c = 'confirmation';
        detail1.SVMXC__Service_order__c = wo.id;
        insert detail1;
        
        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
        detail2.SMAX_PS_CancellationNumber__c = '456';
		detail2.SMAX_PS_SAP_Confirmation__c = 'pending';
        detail2.SVMXC__Service_order__c = wo.id;
        
        SMAX_PS_WorkDetailManager.logDuplicateErrors( new List<SVMXC__Service_Order_Line__c>{detail1}, new Map<Id, SVMXC__Service_Order_Line__c>{detail1.id => detail2});

        
    }
    
    @isTest
    static void testIntegrationToggle() {

         contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
		detail1.SVMXC__Line_Status__c = 'Submitted';
        detail1.SVMXC__Service_order__c = wo.id;
        insert detail1;
        
        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
		detail2.SVMXC__Line_Status__c = null;
        detail2.SVMXC__Service_order__c = wo.id;
        
        SVMXC__Service_Order_Line__c detail3 = new SVMXC__Service_Order_Line__c();
		detail3.SVMXC__Line_Status__c = 'Canceled';
        detail3.SVMXC__Service_order__c = wo.id;
        insert detail3;
        
        
        SMAX_PS_WorkDetailManager.toggleIntegrationStatus(new List<SVMXC__Service_Order_Line__c>{detail1, detail3}, new Map<Id, SVMXC__Service_Order_Line__c>{detail1.id => detail2, detail3.id => detail2});
    }
    
    @isTest
    static void testDetailLineAndIntegration() {
        
        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
		detail1.SVMXC__Line_Status__c = 'Submitted';
        detail1.SVMXC__Service_order__c = wo.id;
        detail1.SMAX_PS_SAP_Confirmation__c = '';
        insert detail1;
        
        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
		detail2.SVMXC__Line_Status__c = null;
        detail2.SMAX_PS_SAP_Confirmation__c = 'something fun';
		detail2.SVMXC__line_status__c = 'Confirmed';
        detail2.SVMXC__Service_order__c = wo.id;
        
        SMAX_PS_WorkDetailManager.updateDetailLineAndIntegrationStatus(new List<SVMXC__Service_Order_Line__c>{detail1}, new Map<Id, SVMXC__Service_Order_Line__c>{detail1.id => detail2});
	}
    

    @isTest
    static void testCancellation() {
        
         contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
		detail1.SVMXC__Line_Status__c = 'Canceled';
        detail1.SVMXC__Service_order__c = wo.id;
        detail1.SMAX_PS_IntegrationStatus__c = 'Pending';
        insert detail1;
        
        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
		detail2.SVMXC__Line_Status__c = 'Submitted';
        detail2.SVMXC__Service_order__c = wo.id;
        
        
       SMAX_PS_WorkDetailManager.cancelLines(new List<SVMXC__Service_Order_Line__c>{detail1}, new Map<Id, SVMXC__Service_Order_Line__c>{detail1.id => detail2});
    }
    
    
    @isTest
    static void testSummary() {
        
        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.SMAX_PS_CancellationNumber__c = '123';
		detail1.SMAX_PS_SAP_Confirmation__c = 'confirmation';
        detail1.SVMXC__Work_Description__c = 'BJKDNFJILWEJKHNF:KJLWEHDNOI:WRLJKEHFNOU:ILWEJRKHJFNO:WURLJGHNFWE:OUR>LIGHJFNWEPUILK>JHNEW:OIFLKVJWRENMIF:OLJKCDHWN :JWEKL>FM<N JEW:KL<>FNM';
        detail1.SMAX_PS_Concat_Part_Work_Description__c = 'blah';
        detail1.SMAX_PS_Material_Part_Description__c = 'blah blah';
        detail1.SVMXC__Service_order__c = wo.id;
        insert detail1;
        
        SMAX_PS_WorkDetailManager.addWorkSummary(new List<SVMXC__Service_Order_Line__c>{detail1});
    }
    
    @isTest
    static void testGetProductPlant() {
        
        contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
		product2 prod = new product2();
        prod.name = 'test name';
        prod.Analytical_Cross_Sell_Peten__c = false;
        prod.ATO_Products__c= false;
        prod.CPQ_Maintenance_Optional__c = false;
        prod.CPQ_Special__c = false;
        prod.CurrencyIsoCode = 'USD';
        prod.Custom_Product__c = false;
        prod.Ext_Warranty_Calculation__c = false;
        prod.FlagForUpdate__c = false;
        prod.Food_Cross_Sell_Analytical__c = false;
        prod.In_SAP__c = true;
        prod.IsActive = true;
        prod.IsBundle__c = false;
        prod.Special_Product__c = false;
        insert prod;
            
        SMAX_PS_ProductSales__c ps1 = new SMAX_PS_ProductSales__c();
        ps1.SMAX_PS_Product__c = prod.id;
        ps1.SMAX_PS_SAP_Deleted__c = false;
        ps1.SMAX_PS_SalesOrg__c = 'TUS1'; //this is salesorg Param
        ps1.SMAX_PS_SalesUnit__c = 'usa';
        ps1.SMAX_PS_Sales_Unit_Code__c = 'usa';
        insert ps1;
        
        SMAX_PS_ProductSales__c ps2 = new SMAX_PS_ProductSales__c();
        ps2.SMAX_PS_Product__c = prod.id;
        ps2.SMAX_PS_SAP_Deleted__c = false;
        ps2.SMAX_PS_SalesOrg__c = 'TUS2'; //this is salesorg Param
        ps2.SMAX_PS_SalesUnit__c = 'usa';
        ps2.SMAX_PS_Sales_Unit_Code__c = null;
        insert ps2;
        
        SMAX_PS_ProductPlant__c plant = new SMAX_PS_ProductPlant__c();
        plant.SMAX_PS_Product__c = prod.id;
        plant.SMAX_PS_Plant__c = 'test';
        insert plant;
        
        SVMXC__Site__c site = new SVMXC__Site__c();
        site.name = 'testSite';
        site.SMAX_PS_MaintenancePlant__c = 'test';
        insert site;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        wo.SVMXC__Site__c = site.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.SVMXC__Service_order__c = wo.id;
        detail1.SVMXC__Line_Type__c = 'Parts';
        detail1.SVMXC__Product__c = prod.id;
        insert detail1;

        SVMXC__Service_Order_Line__c detail2 = new SVMXC__Service_Order_Line__c();
        detail2.SVMXC__Service_order__c = wo.id;
        detail2.SMAX_PS_Use_Product_Sales_UOM__c  = false;
        insert detail2;
        
        SMAX_PS_WorkDetailManager.lookupProductPlant(new List<SVMXC__Service_Order_Line__c>{detail1}, new Map<Id, SVMXC__Service_Order_Line__c>{detail1.id => detail2});
    }
    
    @isTest
    static void testupdateWorkDetailPlantAndWorkCenter() {
        
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        
         contact c = new contact();
        c.FirstName = 'Garth';
        c.LastName = 'Vader';
        c.SAP_Contact_ID__c = 'testId';
        c.pKI_SAP_Contact_ID__c  = 'testId';
        insert c;
        
        SVMXC__Service_order__c wo = new SVMXC__service_Order__c();
        wo.SVMXC__Contact__c = c.id;
        insert wo;
        
        SVMXC__Service_Order_Line__c detail1 = new SVMXC__Service_Order_Line__c();
        detail1.RecordTypeId = usageRecTypeId;
        detail1.SVMXC__Line_Type__c = 'Labor';
        detail1.SVMXC__Service_order__c = wo.id;
        insert detail1;
        
        
        
        SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(new List<SVMXC__Service_Order_Line__c>{detail1}, null);
    }
}
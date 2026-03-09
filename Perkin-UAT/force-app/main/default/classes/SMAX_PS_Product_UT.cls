/*
    Test Class for  SMAX_PS_ProductManager
    Client      :   PerkinElmer
    Created by  :   Veerendra on 2017-10-11
*/
@IsTest(SeeAllData=false)
public class SMAX_PS_Product_UT
{
    static testMethod void createProductTestData()
    {
        // Insert Product
        Product2 prod = new Product2(Name='Test Product', Description='Test Product Description this is a really long one to make sure we test the truncation logic when the description is too long and to make sure this is a really long one we will keep repeating ourselves repeating ourselves repeating ourselves repeating ourselves repeating ourselves repeating ourselves', 
            Partnum__c='TESTT00100101', SVMXC__Product_Type__c='Service Parts', SMAX_PS_ActivityType__c='ACT001');
        Product2 part = new Product2(Name='Test Part', Description='Test Part Description',
                Partnum__c='TESTP00100101', SVMXC__Product_Type__c='Consumable');
        Product2 returnPart = new Product2(Name='Test Return Part', Description='Test Return Part Description',
                Partnum__c='TESTP00100101C', SVMXC__Product_Type__c='Consumable');
        insert new List<Product2> { prod, part, returnPart };

        // Insert Product Revision
        SMAX_PS_ProductRevision__c prodRev = new SMAX_PS_ProductRevision__c(
                            SMAX_PS_Product__c=prod.Id);
        insert prodRev;

        // Insert Product Classification
        SMAX_PS_ProductClassification__c prodCls = new SMAX_PS_ProductClassification__c(
            SMAX_PS_Product__c=prod.Id,
            SMAX_PS_Characteristic__c = 'PE_MEDICAL_DEVICE',
            SMAX_PS_Value__c = 'Y');
        insert prodCls;
        

        // Insert Product Sales
        SMAX_PS_ProductSales__c prodSales = new SMAX_PS_ProductSales__c(
            SMAX_PS_Product__c=prod.Id);
        insert prodSales;

        // Insert Product Plant
        SMAX_PS_ProductPlant__c prodPlant = new SMAX_PS_ProductPlant__c(
            SMAX_PS_Product__c=prod.Id, SMAX_PS_Plant__c = 'TS12');
        SMAX_PS_ProductPlant__c partPlant = new SMAX_PS_ProductPlant__c(
                SMAX_PS_Product__c=part.Id, SMAX_PS_Plant__c = 'TS12', BD_Return_Part_Number__c = returnPart.Partnum__c);
        insert new List<SMAX_PS_ProductPlant__c> { prodPlant, partPlant };

        // ITSFDC-350 Adding Contract Discount Exception (CDE)
        BD_Contract_Discount_Exception__c cde1 = new BD_Contract_Discount_Exception__c(BD_Parts_Product__c = prod.Id,
            BD_Last_Txn_Number__c = 'Joe', BD_Discount_Type__c = 'Service Parts', BD_SAP_Activity_Type__c = 'PM',
            BD_Sales_Org__c = 'US11', BD_External_ID__c = prod.Partnum__c+'-US11-PM-*');
        BD_Contract_Discount_Exception__c cde2 = new BD_Contract_Discount_Exception__c(BD_Parts_Product__c = prod.Id,
                BD_Last_Txn_Number__c = 'ABC', BD_Discount_Type__c = 'Service Parts', BD_SAP_Activity_Type__c = 'REP',
                BD_Sales_Org__c = 'US11', BD_External_ID__c = prod.Partnum__c+'-US11-REP-*');
        insert new List<BD_Contract_Discount_Exception__c> { cde1, cde2 };

        // ITSFDC-507 Adding Extended Warranty Parts (EWP)
        BD_Extended_Warranty_Part__c ewp1 = new BD_Extended_Warranty_Part__c(BD_Equipment_Product__c = prod.Id,
            BD_Last_Txn_Number__c = 'Joe', BD_Sales_Org__c = 'US11', BD_External_Key__c = prod.Partnum__c+'-US11-'+part.Partnum__c,
            BD_Covered_Part__c = part.Id, BD_Extended_Months__c = 9);
        BD_Extended_Warranty_Part__c ewp2 = new BD_Extended_Warranty_Part__c(BD_Equipment_Product__c = prod.Id,
                BD_Last_Txn_Number__c = 'ABC', BD_Sales_Org__c = null, BD_External_Key__c = prod.Partnum__c+'-*-'+part.Partnum__c,
                BD_Covered_Part__c = part.Id, BD_Extended_Months__c = 15);
        insert new List<BD_Extended_Warranty_Part__c> { ewp1, ewp2 };

        prod.SMAX_PS_CompletedTxnNum__c='ABC';
        update prod;
        
          // Insert Product Classification
        SMAX_PS_ProductClassification__c prodCls2 = new SMAX_PS_ProductClassification__c(
            SMAX_PS_Product__c=prod.Id,
            SMAX_PS_Characteristic__c = 'PE_MEDICAL_DEVICE',
            SMAX_PS_Value__c = 'Y');
        insert prodCls2;
        update prodCls2;
        Product2 updated = [SELECT Id, Name, ProductCode, SMAX_PS_Medical_Classification__c FROM Product2 WHERE Id = :prod.Id];
       // System.assertEquals('Y', updated.SMAX_PS_Medical_Classification__c);

        /*SMAX_PS_ProductSales__c prodSalesResult = [SELECT Id, Name, SMAX_PS_PartDescription__c,
            SMAX_PS_PartNumber__c, SMAX_PS_ProductType__c, SMAX_PS_SAP_ActivityType__c 
            FROM SMAX_PS_ProductSales__c WHERE Id = :prodSales.Id];
        System.assertNotEquals(null, prodSalesResult.SMAX_PS_PartDescription__c);
        System.assertEquals(prod.Partnum__c, prodSalesResult.SMAX_PS_PartNumber__c);
        System.assertEquals(prod.SVMXC__Product_Type__c, prodSalesResult.SMAX_PS_ProductType__c);
        System.assertEquals(prod.SMAX_PS_ActivityType__c, prodSalesResult.SMAX_PS_SAP_ActivityType__c);

        SMAX_PS_ProductPlant__c partPlantResult = [SELECT Id, Name, BD_Return_Part__c
            FROM SMAX_PS_ProductPlant__c WHERE Id = :partPlant.Id];
        //System.assertEquals(returnPart.Id, partPlantResult.BD_Return_Part__c);

        List<BD_Contract_Discount_Exception__c> cdeResults = [SELECT Id, Name FROM BD_Contract_Discount_Exception__c
            WHERE BD_Parts_Product__c = :prod.Id];
        //System.assertEquals(1, cdeResults.size());

        List<BD_Extended_Warranty_Part__c> ewpResults = [SELECT Id, Name, BD_External_Key__c FROM BD_Extended_Warranty_Part__c
            WHERE BD_Equipment_Product__c = :prod.Id AND BD_Is_Deleted__c = FALSE];*/
        //System.assertEquals(1, ewpResults.size());

        delete prod;
    }

    // 2022/07/13 Tony ITSVMX-562 Modify the replenishment parts ordering process
    @IsTest
    static void testProcessProductPlantForRefurbishedParts() {

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
        //System.debug('ip.SMAX_PS_IsMedicalDevice__c: ' + ip.SMAX_PS_IsMedicalDevice__c);

        // Create Product Plant
        SMAX_PS_ProductPlant__c productPlant = new SMAX_PS_ProductPlant__c();
        productPlant.SMAX_PS_Product__c = product1.Id;
        productPlant.SMAX_PS_Plant__c = 'P123';
//      productPlant.BD_Refurbished_Part__c = product2.Id;  // This should be set by the code in SMAX_PS_ProductManager.processProductPlant()
        productPlant.BD_Refurbished_Part_Number__c = 'Refurb123';
        insert productPlant;
        productPlant.SMAX_PS_PlannedDeliveryTimeInDays__c = '3';
        update productPlant;

        List<SMAX_PS_ProductPlant__c> testProductPlants = [SELECT Id, BD_Refurbished_Part_Number__c, BD_Refurbished_Part__c FROM SMAX_PS_ProductPlant__c WHERE BD_Refurbished_Part__c = :product2.Id];
        //System.debug('testProductPlants: ' + testProductPlants.size() + ' ' + testProductPlants);
        //System.assertEquals(1, testProductPlants.size(), 'There should be 1 record that has the correct Refurbished Part associated to it.');

    }
}
/*
** Class:  UnitTests_ServiceContractButton.cls
** Created by OpFocus on 05/09/2012
** Description: This class contains unit tests for the ServiceContractButton.cls and ServiceContract.trigger.
*/
@isTest(SeeAllData=true)
private class UnitTests_ServiceContractButton {

    static testMethod void testServiceContractButton() {

        // Query Standard price book for adding a new product before it can be added to a custom price book
        Pricebook2 standardPB = [select Id from Pricebook2 where isStandard=true];
    
        // Create a new custom price book for a new Service product
        Pricebook2 pb = new Pricebook2(Name = 'Test New Price Book', 
                         Description = 'Test custom price book', 
                         IsActive = true);
        insert pb;
      
        // Add a new Product to Product table
        Product2 prod = new Product2(Name = 'Test Service 1', IsActive = true);
        insert prod;
        
        // Add another new Product to Product table
        Product2 prod2 = new Product2(Name = 'Test Service 2', IsActive = true);
        insert prod2;

        // Add the new product in Product table to Standard price book
        //PricebookEntry standardPrice = [select id from PricebookEntry where Pricebook2Id = :standardPB.Id and Product2Id = :prod.Id limit 1];
        
         // Add the new product2 in Product table to Standard price book
        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                    Product2Id = prod2.Id, 
                                    UnitPrice = 3500, 
                                    IsActive = true, 
                                    UseStandardPrice = false);
        insert standardPrice2;
        
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                    Product2Id = prod.Id, 
                                    UnitPrice = 3500, 
                                    IsActive = true, 
                                    UseStandardPrice = false);
        insert standardPrice1;
        
        // Add the new product in Product table to the custom price book (pb)
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, 
                            Product2Id = prod.Id, 
                            UnitPrice = 3000, 
                            IsActive = true, 
                            UseStandardPrice = false);
        insert pbe;
        
        // Add the new product2 in Product table to the custom price book (pb)
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = pb.Id, 
                            Product2Id = prod2.Id, 
                            UnitPrice = 4000, 
                            IsActive = true, 
                            UseStandardPrice = false);
        insert pbe2;
        // Create a Service Contract to test with
        ServiceContract sc = new ServiceContract(Name = 'Test Service Contract',
         Pricebook2Id  = pb.id,
         StartDate     = System.today(), 
         SpecialTerms  = 'Test',
         EndDate       = System.today()+ 365);
         
        insert sc;

        // Add a ContractLineItem1 to the Service Contract.
        ContractLineItem cli1 = new ContractLineItem(ServiceContractId = sc.Id, 
                                PricebookEntryId = pbe.Id, 
                                Quantity = 1, 
                                UnitPrice = 3000);
        insert cli1;
        
        // Add a ContractLineItem2 to the Service Contract.
        ContractLineItem cli2 = new ContractLineItem(ServiceContractId = sc.Id, 
                                PricebookEntryId = pbe2.Id, 
                                Quantity = 1, 
                                UnitPrice = 4000);
        insert cli2;
        
        String compareResult;

        // Clone the Service Contract  
        compareResult = ServiceContractButton.cloneServiceContract(sc.Id);
        // CloneServiceContract should return '' if the Service Contract was cloned correctly
        System.assertNotEquals('', compareResult);

        sc = [select Id from ServiceContract where Id = :sc.Id];  
        
        // Check to see if the clone record has been created
        List<ServiceContract> lstScs = [select Id, Clone_From_Id__c from ServiceContract where Clone_From_Id__c = :sc.Id];
        System.assertEquals(1, lstScs.size());
        
        // Check to see if the Conract Line Items have been breated for the clone Service Contract
        List<ContractLineItem> lstClis = [select Id, ServiceContractId from ContractLineItem where ServiceContractId = :lstScs[0].Id];
        System.assertEquals(2, lstClis.size());         
    }
}
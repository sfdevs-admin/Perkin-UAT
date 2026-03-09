/*
** Class:  UnitTest_Entitlement
** Created by OpFocus on 05/10/2012
** Description: This class contains unit tests that verify that the Entitlement.Trigger performs properly.
*/
@isTest(seealldata=true)
private class UnitTest_Entitlement {

    static testMethod void simpleTest() {
        Account acct = new Account(Name='ABC Test 1', ShippingCountry='US', ShippingPostalCode='22301');
        insert acct;

        Product2 prod = new Product2(Name = 'Test Service 1', IsActive = true);
        insert prod;
        
        Asset a = new Asset(Name='Test Asset', AccountId = acct.Id, Type__c = 'Asset', Product2Id = prod.Id);
        insert a;
        
        // Create an inactive Entitlement
        Entitlement e = new Entitlement(Name='Test Entitlement1', AccountId=acct.Id, AssetId=a.Id, Type='Test Type', StartDate=system.today()+10, EndDate=system.today()+365);
        insert e;
        // The asset shouldn't have values for Active_Contract_End_Date__c and Active_Contract_Type__c
        // The asset's Contract Status should be 'Inactive'
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id];     
        System.assertEquals(null,a.Active_Contract_End_Date__c);
        System.assertEquals(null,a.Active_Contract_Type__c); 
        System.assertEquals('Inactive',a.Contract_Status__c); 
        
        // Update the Entitlement to have the Active Date
        e.StartDate=system.today();
        update e;
        
        // The asset should have values for Active_Contract_End_Date__c and Active_Contract_Type__c     
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(e.EndDate,a.Active_Contract_End_Date__c);
        System.assertEquals(e.Type,a.Active_Contract_Type__c); 
        System.assertEquals('Active',a.Contract_Status__c); 
        
        delete e;
        // The asset shouldn't have values for Active_Contract_End_Date__c, Active_Contract_Type__c and Contract_Status__c   
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(null,a.Active_Contract_End_Date__c);
        System.assertEquals(null,a.Active_Contract_Type__c); 
        System.assertEquals(null,a.Contract_Status__c); 

        // Create an active Entitlement
        Entitlement e2 = new Entitlement(Name='Test Entitlement2', AccountId=acct.Id, AssetId=a.Id, Type='Test Type', StartDate=system.today(), EndDate=system.today()+365);
        insert e2;

        // The asset should have values for Active_Contract_End_Date__c and Active_Contract_Type__c from Entitlement2   
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(e2.EndDate,a.Active_Contract_End_Date__c);
        System.assertEquals(e2.Type,a.Active_Contract_Type__c); 

        Entitlement e3 = new Entitlement(Name='Test Entitlement3', AccountId=acct.Id, AssetId=a.Id, Type='Test Type', StartDate=system.today(), EndDate=system.today()+375);
        insert e3;

        // The asset should have values for Active_Contract_End_Date__c and Active_Contract_Type__c from Entitlement2 because it has and earlier end date
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(e2.EndDate,a.Active_Contract_End_Date__c);
        System.assertEquals(e2.Type,a.Active_Contract_Type__c); 
        System.assertEquals('Active',a.Contract_Status__c); 

        delete e2;
 
        // When deleted E2, the asset should have values for Active_Contract_End_Date__c and Active_Contract_Type__c from Entitlement3
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(e3.EndDate,a.Active_Contract_End_Date__c);
        System.assertEquals(e3.Type,a.Active_Contract_Type__c); 
        System.assertEquals('Active',a.Contract_Status__c); 
        
        undelete e2;
        // When undeleted, E2 the asset should have values for Active_Contract_End_Date__c and Active_Contract_Type__c from Entitlement2 because it has and earlier end date
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(e2.EndDate,a.Active_Contract_End_Date__c);
        System.assertEquals(e2.Type,a.Active_Contract_Type__c); 
        System.assertEquals('Active',a.Contract_Status__c); 
        
        // Change E3 StartDate to the futrue date so the its status will be 'Inactive'
        e3.StartDate = system.today()+2;
        update e3;
        
        delete e2;
 
        // When deleted E2 (againg), the asset should not have any values for Active_Contract_End_Date__c and Active_Contract_Type__c from Entitlement3
        // And the asset's Contract_Status__c should be 'Inactive'
        a = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c, Contract_Status__c
             from Asset 
             where id = :a.id]; 
        System.assertEquals(null,a.Active_Contract_End_Date__c);
        System.assertEquals(null,a.Active_Contract_Type__c); 
        System.assertEquals('Inactive',a.Contract_Status__c); 
                
    }

    static testMethod void bulkTest() {
        //Test to see if the trigger pass when insert data in bulk
        Account acct = new Account(Name='ABC Test 1', ShippingCountry='US', ShippingPostalCode='22301');
        insert acct;
    
        List<Product2> lstProducts = new List<Product2>();
        for (Integer i=0; i<200; i++){
            Product2 p = new Product2(Name = 'Test Service 1', IsActive = true);
            lstProducts.add(p);
        }   
        insert lstProducts;

        List<Asset> lstAssets = new List<Asset>();
        for (Integer i=0; i<200; i++) {
            Asset a = new Asset(Name='Test Asset', AccountId=acct.Id, Type__c='Asset', Product2Id=lstProducts[i].Id);
            lstAssets.add(a);
        }
        insert lstAssets;

        List<Entitlement> lstEntitlements = new List<Entitlement>();
        for (Integer i=0; i<200; i++){
            Entitlement e = new Entitlement(Name = 'Test Entitlement', AccountId=acct.Id, AssetId=lstAssets[i].Id,
            Type='Test Type', StartDate=system.today(), EndDate=system.today()+365);
            lstEntitlements.add(e);
        }   
        insert lstEntitlements;   
        
        // The Assets' Active_Contract_End_Date__c and Active_Contract_Type__c should have some values in them
        lstAssets = [select id, Name, Active_Contract_End_Date__c, Active_Contract_Type__c
             from Asset 
             where id in :lstAssets];           
        for (Integer i=0; i<50; i++) {
            System.assertNotEquals(null, lstAssets[i].Active_Contract_End_Date__c ); 
            System.assertNotEquals(null, lstAssets[i].Active_Contract_Type__c );
        }    
    }
}
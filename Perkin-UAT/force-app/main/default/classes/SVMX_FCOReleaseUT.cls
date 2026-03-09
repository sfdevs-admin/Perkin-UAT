@isTest
public with sharing class SVMX_FCOReleaseUT {
/*
    static testMethod void myFCOReleaseTest() {
        Account Acc = new Account(Name='ACC001',
                                BillingStreet='ABC',
                                BillingCity='PQR ',
                                BillingState = 'CA',
                                BillingPostalCode='111',
                                BillingCountry='US',
                                Active__c=true);
        insert Acc;         
        
        Contact cont = new Contact(LastName='Test Contact',
                                    PKI_SAP_Contact_ID__c='TestId');
        insert cont;
                
        SVMXC__Site__c loc = new SVMXC__Site__c(Name='Test Location');
        insert loc;
                
        Product2 prod = new Product2(ProductCode='UTProd001',
                                    Name='UTProd001',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod;
        
        Product2 prod1 = new Product2(ProductCode='UTProd002',
                                    Name='UTProd002',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod1;
        Product2 prod2 = new Product2(ProductCode='UTProd003',
                                    Name='UTProd003',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod2;
        Product2 prod3 = new Product2(ProductCode='UTProd004',
                                    Name='UTProd004',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod3;
        
         SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(
                                                Revision__c = 0,
                                                SVMXC__Product__c = prod.id,
                                                Name='101',
                                                SVMXC__Serial_Lot_Number__c = '101',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=null,
                                                Major__c=0,
                                                Minor__c =0,                                                
                                                SVMXC__Top_Level__c=null);
        insert ip;  
         SVMXC__Installed_Product__c ip1 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod1.id,
                                                Name='102',
                                                SVMXC__Serial_Lot_Number__c = '102',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip.id,
                                                Major__c=0,
                                                Minor__c =2,
                                                SVMXC__Top_Level__c=ip.id);
        insert ip1; 
        
        SVMXC__Installed_Product__c ip2 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod.id,
                                                Name='103',
                                                SVMXC__Serial_Lot_Number__c = '103',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip1.id,
                                                Major__c=3,
                                                Minor__c =0,
                                                SVMXC__Top_Level__c=ip.id);
        insert ip2;
        SVMXC__Installed_Product__c ip3 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod3.id,
                                                Name='104',
                                                SVMXC__Serial_Lot_Number__c = '104',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip.id,
                                                Major__c=4,
                                                Minor__c =4,
                                                SVMXC__Top_Level__c=ip2.id);
        insert ip3;
        
      
        FCO__c  fco = new FCO__c(Name='FCO UT',
                                FCO_Type__c='Important Field Safety Notice',
                                PSC_Status__c='New',
                                PSC__c='CMS',
                                Description__c='Description');
        
        insert fco;
        
        FCO_Lines__c  fcoln = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_1__c=ip.id,
                                Status__c='Active',
                                Account__c=Acc.id,
                                Contact__c=cont.id,
                                Location__c=loc.id);        
        insert fcoln;
        FCO_Lines__c  fcoln2 = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_2__c=ip2.id,
                                Status__c='Active', Work_Order_Created__c = false,
                                Account__c=Acc.id,
                                Contact__c=cont.id,     
                                Location__c=loc.id);        
        insert fcoln2;
        FCO_Lines__c  fcoln3 = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_3__c=ip3.id,
                                Status__c='Active', Work_Order_Created__c = false,
                                Account__c=Acc.id,
                                Contact__c=cont.id,    
                                Location__c=loc.id);        
        insert fcoln3;
        
        PageReference pageRef = Page.SVMX_FCOSearch;
        pageRef.getParameters().put('uid',fco.Id);        
        Test.setCurrentPageReference(pageRef);
        SVMX_FCORelease fcorelease = new SVMX_FCORelease();      
        fcorelease.CreateWO(); 
    }
*/
}
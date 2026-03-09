/*
** Class:  ServiceContractButton WebService
** Created by OpFocus on 05/01/2012
** Description: ServiceContractButton is called from a button on Service Contract 
**              to clone the record and copy the products
*/   
global with sharing class ServiceContractButton {
//  This class creates a WebService cloneWithProduct
//  This WebService will be called from Clone with Product button on Service Contract
    WebService static String cloneServiceContract(Id serviceContractId) {
        String retVal = '';
        
        ServiceContract sc =
            [select Name, Id, Pricebook2Id, Term, Tax, Status, StartDate, SpecialTerms, ShippingStreet, ShippingState, 
                    ShippingPostalCode, ShippingHandling, ShippingCountry, ShippingCity, 
                    EndDate, Description, Contract_Type__c, ContactId, 
                    BillingStreet, BillingState, BillingPostalCode, BillingCountry, BillingCity, AccountId
             From   ServiceContract 
             where  Id = :serviceContractId ];  
                    
        ServiceContract scNew = sc.clone(false); 
        scNew.Name                = '***Clone***-'+sc.Name; 
        scNew.Clone_From_ID__c    = sc.Id;
        scNew.Clone_Line_Items__c = true;
        
        try {
            insert scNew;
        }
        catch (Exception ex) {
            
        }
        return retVal=scNew.Id;     
    }
}
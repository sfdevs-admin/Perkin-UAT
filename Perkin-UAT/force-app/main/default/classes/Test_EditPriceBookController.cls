/*
  Class : Test_EditPriceBookController
  Created By  : Lister
  Created Date : 12th Feb 2021
  Description: Test class for EditPriceBookController
*/

@isTest
public class Test_EditPriceBookController {
    public static testmethod void unitTestMethod(){
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        Pricebook2 PB = new Pricebook2();
        PB.Name = 'Informatics';
        PB.IsActive = true;
        insert PB;
        
        List<Product2> lstProduct = new List<Product2>();
         Product2 product = new Product2(
            Name = 'TestProduct',
            IsActive = true, 
            /* SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable', */
            License_Type_INF__c = 'Perpetual',
            Product_Line__c = 'AVS'
        );
        lstProduct.add(product);
         Product2 prod = new Product2(
            Name = 'TestProduct',
            IsActive = true, 
            /* SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable',*/
            License_Type_INF__c = 'Perpetual',
            Product_Line__c = 'AVS',
            Business_Unit__c = 'INFORMATICS'
        );
        lstProduct.add(prod);
        insert lstProduct;
        
        product.product_line__c = 'AVC';
        update product;
        
        List<PricebookEntry> lstPBE = new List<PricebookEntry>();
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 120.00,
            IsActive = true
        );
        lstPBE.add(pbEntry);
        
        PricebookEntry pbEnt = new PricebookEntry(
            Pricebook2Id = PB.Id,
            Product2Id = product.Id,
            UnitPrice = 120.00,
            IsActive = true
        );
        lstPBE.add(pbEnt);
        insert lstPBE;
        
        Test.startTest();
        EditPriceBookController.getRelatedStdPricebooks(product.Id);
        EditPriceBookController.getRelatedPricebooks(product.Id);
        EditPriceBookController.updatePricebook(lstPBE);
        
    }
}
@isTest
public class test_HandlerNewProductCreation {

    @isTest
    static  void testMethod2(){
        
        List<Product_Line_Mapping__c> listPLMap=new List<Product_Line_Mapping__c>();
        Product_Line_Mapping__c pl1=new Product_Line_Mapping__c();
        pl1.name='APS1';
        pl1.Product_Family__c='15-APS';
        pl1.Product_Family_Numbered__c='"15-APS"';
        listPLMap.add(pl1);
        
        Product_Line_Mapping__c pl2=new Product_Line_Mapping__c();
        pl2.name='ARS1';
        pl2.Product_Family__c='35-ARS';
        pl2.Product_Family_Numbered__c='"35-ARS"';
        listPLMap.add(pl2);
        
        insert listPLMap;
        
        Test.startTest();
        Product2 prod=new Product2();
        prod.Name = 'Test Product APS';
        prod.product_line__c = 'APS1';
        prod.isActive = true;
        insert prod;
        
        Product2 prod1=[Select id,Product_Family_Numbered__c,Family from Product2 where id=:prod.id];
        system.debug('&&' +prod1.Product_Family_Numbered__c);
        system.assertequals('"15-APS"',prod1.Product_Family_Numbered__c);
        system.assertequals( '15-APS',prod1.Family);
       
        prod.product_line__c = 'ARS1';
        update prod;
        
        Product2 prodafterudpate=[Select id,Product_Family_Numbered__c,Family from Product2 where id=:prod.id];
        system.assertequals('35-ARS',prodafterudpate.Family);
        system.assertequals( '"35-ARS"',prodafterudpate.Product_Family_Numbered__c);
        Test.stopTest();
    
    }
   
    @isTest
    static  void testMethod3()
    {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        Pricebook2 nonstandardPB=new  Pricebook2();
        nonstandardPB.Name='Informatics';
        insert nonstandardPB;
        
        Test.starttest();
        list<product2> lstprod=new list<product2>();
        Product2 prod=new Product2();
        prod.Name = 'Test Product';
        prod.ProductCode = 'P-1';
        prod.isActive = true;
        prod.Business_Unit__c = 'INFORMATICS';
        lstprod.add(prod);
        insert lstprod;
        
        List<id> lstProdid=new  List<id>();
        lstProdid.add(prod.id);
        HandlerNewProductCreation.createPBEntry(lstProdid);
        list<PricebookEntry> lstPBEntry=[Select id from PricebookEntry where Product2Id = :prod.id];
        //system.assertEquals(0, lstPBEntry.size());
        Test.stoptest();
        
    }
}
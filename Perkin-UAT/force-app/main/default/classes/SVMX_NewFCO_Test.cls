@isTest
private class SVMX_NewFCO_Test {
    private static testMethod void testSave() {        
        Test.startTest();        
        Product2 prod = new Product2(ProductCode='UTProd001',
                                     Name='UTProd001',
                                     Family='Oncology',
                                     SVMXC__Product_Line__c='Desktop',
                                     IsActive=true);
        insert prod;        
        
        FCO__c  fco = new FCO__c(Name='FCO UT',
                                 FCO_Type__c='Important Field Safety Notice',
                                 PSC_Status__c='New',
                                 PSC__c='CMS',
                                 Description__c='Description',
                                 Product__c = prod.Id
                                );        
        
        PageReference pageRef = Page.SVMX_NewFCO;     
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(fco);
        SVMX_NewFCO newController = new SVMX_NewFCO(sc); 
        newController.FCO = fco; 
        newController.setFCO(fco);
        FCO__c s = newController.getFCO();
        System.assertEquals(fco,s);
        newController.save();
        Test.stopTest();
    }    
}
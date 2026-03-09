@isTest(SeeAllData=true)
public class Test_trgCreateStandardPriceBookEntry 
{

    public static testmethod void testMethod1()
    {
        Product2 prod=new Product2();
        prod.Name = 'Test Product';
        prod.ProductCode = 'P-1';
        prod.isActive = true;
        prod.Platform_INF__c= 'INFSOFTWARE';
        insert prod;
    }
    
 }
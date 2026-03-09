@isTest (SeeAllData = true) 
public class StrengthSaleTest {
    static testMethod void radarChartTest() {
        RecordType art=[SELECT Id,Name FROM RecordType WHERE SobjectType='Account' and Name like 'Prospect%'];
        Account a = new Account(name='Test123456787',BillingStreet='100 Main Street',BillingCity='Waltham', BillingState = 'MA',
                                BillingCountry = 'US', BillingPostalCode = '02451',ShippingStreet = '100 Main Street', ShippingCity = 'Waltham', ShippingState = 'MA', ShippingCountry = 'US', ShippingPostalCode = '02451', RecordTypeId=art.Id);
        insert a;
        RecordType ort=[SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' and Name like 'PKI SPI Sales Process'];
        Date CDATE = Date.today();
        Opportunity o=new Opportunity(name='Test123',AccountId=a.Id,Type='Instrument',StageName='Stage 1 - Qualification',
                                      CloseDate=CDATE,RecordTypeId=ort.Id,Site_Readiness__c='Ready',
                                      PAIN__c='2',
                                      POWER__c='4',
                                      VISION__c='5',
                                      VALUE__c='1',
                                      COLLABORATE__c='0',
                                      COMPELLING_REASON_TO_ACT_CRTA__c='3',
                                      Solution_Area_of_Interest__c='Energy');
        insert o;
        
        PageReference pf = Page.StrengthOfSale;
        pf.getParameters().put('id',o.id);
        Test.setCurrentPage(pf);
        StrengthSale s = new StrengthSale();
        System.assertEquals(6,s.data.size());
    }
}
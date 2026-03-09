@isTest (SeeAllData = true)
public class AssetsListCtrlTest {
    static testMethod void Test1() {
        RecordType[] rt=[SELECT Id,Name FROM RecordType WHERE SobjectType='Case' and (Name='Dx Software Services' or Name='DX Support')];
        Case c=new Case(Subject='test1',Status='New',RecordTypeId=rt[0].Id,TypeOfCase__c='Anomaly');
        insert c;
        
        Case c1=new Case(Subject='test1',Status='New',RecordTypeId=rt[1].Id);
        insert c1;
        
        PageReference pf = Page.AssetsListVF;
        pf.getParameters().put('id',c.id);
        Test.setCurrentPage(pf);
        
        AssetsListCtrl actrl = new AssetsListCtrl(new ApexPages.StandardController(c));
        //System.assertEquals(actrl.casts.size(),1);
        
        PageReference pf1 = Page.AssetsListVF;
        pf1.getParameters().put('id',c1.id);
        Test.setCurrentPage(pf1);
        
        AssetsListCtrl actrl1 = new AssetsListCtrl(new ApexPages.StandardController(c1));
        //System.assertEquals(actrl1.casts.size(),1);
        
         Account b = new Account(Name = 'Test123456787',
            Phone = '77778',
            Industry = 'Test', 
            BillingStreet = 'Green Street', 
            BillingCity = 'NY',
            BillingState = 'CA', 
            BillingPostalCode = '95123', 
            BillingCountry = 'US', 
            Type = 'Vendor', 
            Website = 'www.xyz.com',
            ShippingCountry = 'US',
            ShippingStreet = 'Green Street', 
            ShippingCity = 'NY',
            ShippingState = 'CA', 
            ShippingPostalCode = '95123',
            OwnerId=UserInfo.getUserId()
            );
        insert b;
        Asset s=new Asset(name='1234',AccountId=b.Id);
        insert s;
        PKI_AssetCases__c ac=new PKI_AssetCases__c(name='lljasdf',Asset__c=s.Id,Case__c=c.id);
        insert ac;
        
        actrl.asid=ac.Id;
        actrl.Remove();
        
        actrl.nm='xxx';
        actrl.Prod='nnnn';
        actrl.ProdLine='nnn';
        actrl.srlNbr='1212-99393';
        actrl.ASearch();
        System.assertEquals(actrl.aasts.size(),0);
        
        actrl.asid = s.Id;
        actrl.csid = c1.Id;
        PageReference rtPg = actrl.AssignAsset();
        System.assertEquals(rtPg,null);        
    }
}
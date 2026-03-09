@isTest (SeeAllData = true)
public class AssetVFCtrlTest {
    static testMethod void Test1(){
        Account b = new Account(name='Test#54884');
        insert b;
        Asset s=new Asset(name='1234',AccountId=b.Id);
        insert s;
        
        RecordType[] rt=[SELECT Id,Name FROM RecordType WHERE SobjectType='Case' and (Name='Dx Software Services' or Name='DX Support')];
        Case c=new Case(Subject='test1',Status='New',RecordTypeId=rt[0].Id,AccountId=b.Id,TypeOfCase__c='Other');
        insert c;
        
        PageReference pf = Page.AssetsVF;
        pf.getParameters().put('id',c.id);
        Test.setCurrentPage(pf);
        
        AssetsVFCtrl actrl = new AssetsVFCtrl(new ApexPages.StandardController(c));
        System.assertEquals(actrl.ls.size(),0);
        
        actrl.anm=b.Name;
        actrl.ASearch();
        System.assertEquals(actrl.ls.size(),0);
        
        actrl.nm='xxx';
        actrl.Prod='nnnn';
        actrl.ProdLine='nnn';
        actrl.ProdFmly='yyyy';
        actrl.srlNbr='1212-99393';
        actrl.ASearch();
        System.assertEquals(actrl.ls.size(),0);
        
        AssetsVFCtrl.CustAsts cst=new AssetsVFCtrl.CustAsts();
        cst.chk=true;
        cst.a = s;
        actrl.ls.add(cst);
        actrl.Add();
    }
}
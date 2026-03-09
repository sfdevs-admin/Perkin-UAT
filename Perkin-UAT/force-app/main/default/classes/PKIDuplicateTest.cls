@isTest (SeeAllData = true) 
public class PKIDuplicateTest {
    
    static testMethod void findDuplicateTest() {
        RecordType rt=[SELECT Id,Name FROM RecordType WHERE SobjectType='Account' and Name like 'Prospect%'];
        Account a = new Account(name='Test123456787', BillingStreet = '100 Main Street', BillingCity = 'Waltham', BillingState = 'MA', BillingCountry = 'US', BillingPostalCode = '02451', RecordTypeId=rt.Id);
        insert a;
        Account a1 = new Account(name='Test1234567879', BillingStreet = '100 Main Street', BillingCity = 'Waltham', BillingState = 'MA', BillingCountry = 'US', BillingPostalCode = '02451', RecordTypeId=rt.Id);
        insert a1;
        PageReference pf = Page.PKIDuplicateIdentification;
        pf.getParameters().put('id',a.id);
        Test.setCurrentPage(pf);
        pkiduplicate d=new pkiduplicate();
        
        //Delete account
        d.del.Parentid=a.id;
        PageReference r=d.sDelete();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Search Accounts
        d.criteria='Namaste';
        
        List<Account> testAccounts = new List<Account>();
        
        for(Integer i = 0; i<10; i++) {
            Account account = new Account();
            account.Name = 'Namaste ' + i;
            account.PKI_status__c = 'Delete';
            account.RecordTypeId = rt.Id;
            testAccounts.add(account);
        }
        insert testAccounts;
        
        r=d.Search();
//        System.assertEquals(testAccounts.size(),d.rC);
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());

        //Cancel 
        r=d.Cancel();
        System.assertEquals('/' + a.id, r.getUrl());
        
        //Add
        Integer c=0;
        for(Account e : testAccounts){
           pkiduplicate.Dups m=new pkiduplicate.Dups();
           c++;
           if(c==1)
               m.prn=true;
           if(c==4)
               break;
            m.chk=true;
            m.a=e;
            d.res.add(m);
            system.debug(d);
            d.duplis.add(m);
            system.debug(d);
        }
        r=d.Add();
        system.debug(r);
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Approve
        d.duplis[0].prn=false;
        r=d.Approve();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        System.debug('LIsT:' + d.duplis);
        
        //Parent
        d.duplis[0].chk=false;
        d.duplis[1].chk=true;
        d.duplis[2].chk=false;
        r=d.Parent();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //remove
        d.duplis[1].chk=false;
        d.duplis[2].chk=true;
        d.vw='CRA';
        r=d.Remove();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        d.vw='CMFD';
        r=d.Remove();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Approve
        d.duplis[0].chk=true;
        d.duplis[1].chk=true;
        d.vw='CRA';
        r=d.Approve();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        d.vw='CMFD';
        r=d.Approve();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Unselect all
        d.vw='CRA';
        r=d.UnSelectAll();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        d.vw='CMFD';
        r=d.UnSelectAll();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Select All
        d.vw='CRA';
        r=d.SelectAll();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        d.vw='CMFD';
        r=d.SelectAll();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
        
        //Cancel Search
        r=d.ClearSearch();
        System.assertEquals('/apex/PKIDuplicateIdentification?id='+a.id,r.getUrl());
    }
}
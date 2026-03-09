public with sharing class AssetsVFCtrl {
    public List<CustAsts> ls {get; set;}
    public String ProdLine {get; set;}
    public String ProdFmly {get; set;}
    public String srlNbr {get; set;}
    public String Prod {get; set;}
    public String act {get; set;}
    public String nm {get; set;}
    public String anm {get; set;}
    public String id;
    public Case cs {get; set;}
    
    public AssetsVFCtrl(ApexPages.StandardController controller) {
        id=ApexPages.currentPage().getParameters().get('id');
        cs=[Select Id, RecordType.Name,accountid,account.name from Case WHERE Id=:id];
        if(cs.accountid!=null)
            SearchAsts();
    }
    
    public PageReference ASearch() {
        SearchAsts();
        return null;
    }
    
    public PageReference Cancel() {
        return new PageReference('/' + id);
    }

    public PageReference Add() {
        if(ls==null || ls.size()==0)
            return null;
        List<PKI_AssetCases__c> lf = new List<PKI_AssetCases__c>();
        for(CustAsts s:ls){
            if(s.chk==true) {
                PKI_AssetCases__c a = new PKI_AssetCases__c();
                a.Asset__c = s.a.id;
                a.Case__c=id;
                lf.add(a);
            }
        }
        insert lf;
        return new PageReference('/' + id);
    }
    
    /*** FUNCTIONS LOGIC*******/
    public void SearchAsts(){
        String qry = 'SELECT Id,Name,SerialNumber,Account.Name,Product2.Name,Product2.Family,Product2.product_line__c,Software_Version__c FROM Asset';
        List<String> fltr=new List<String>();
        fltr.add('(Product2.product_line__c=\'NEO\' Or Product2.product_line__c=\'PRE\' Or Product2.product_line__c=\'DIA\' Or Product2.product_line__c=\'MDX\' Or Product2.product_line__c=\'VIR\' Or Product2.product_line__c=\'NAP\')');
        if(cs.accountid!=null && (anm==null || anm=='') && (nm==null || nm=='') && (Prod==null || Prod=='') && (ProdLine==null || ProdLine=='') && (srlNbr==null || srlNbr==''))
            fltr.add('AccountId = \'' + cs.accountid + '\'');
        if(anm!=null && anm!='')
            fltr.add('Account.Name like \'' + anm + '%\'');
        if(nm!=null && nm!='')
            fltr.add('Name like \'' + nm + '%\'');
        if(Prod!=null && Prod!='')
            fltr.add('Product2.Name like \'' + Prod + '%\'');
        if(ProdLine!=null && ProdLine!='')
            fltr.add('Product2.product_line__c=\'' + ProdLine + '\'');
        if(srlNbr!=null && srlNbr!='')
            fltr.add('SerialNumber like \'%' + srlNbr + '\'');

        if(fltr.size() > 0)
            qry+=' WHERE ';
        for(Integer c=0;c<fltr.size();c++){
               if(c==fltr.size()-1)
                  qry+=fltr[c];
               else
                  qry+=fltr[c] + ' AND ';
        }
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,qry));
        List<Asset> la=Database.query(qry + ' Order By Account.Name Limit 500');
        ls = new List<CustAsts>();
        for(Asset n:la) {
            CustAsts s=new CustAsts();
            s.chk=false;
            s.a=n;
            ls.add(s);
        }
    }
    
    /*********INNER OBJECT************/
    public class CustAsts {
        public Boolean chk {get; set;}
        public Asset a { get; set; }
    }
}
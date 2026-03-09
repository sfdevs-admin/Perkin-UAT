public with sharing class AssetsListCtrl {
    public List<Asset> asts {get; set;}
    public List<CustAsts> casts {get; set;}
    public List<CustAsts> aasts {get; set;}
    public Case cs {get; set;}
    public String csid {get; set;}
    public String asid {get; set;}
    public String actTb {get; set;}
    public List<Id> aids=new List<Id>();
    Map<Id,Id> maid=new Map<Id,Id>();
    
    public String ProdLine {get; set;}
    public String srlNbr {get; set;}
    public String Prod {get; set;}
    public String nm {get; set;}
    public String anm {get; set;}
    
    
    public AssetsListCtrl(ApexPages.StandardController controller) {
        csid=ApexPages.currentPage().getParameters().get('id');
        casts = new List<CustAsts>();
        aasts = new List<CustAsts>();
        showAssets();
    }
    
    public void showAssets() {
       casts.clear();
       aasts.clear();
       aids.clear();
       maid.clear();
       ProdLine='';
       srlNbr='';
       Prod='';
       nm='';
       anm='';


         cs=[Select Id, RecordType.DeveloperName, accountid, Account.Name from Case WHERE Id=:csid];
      // Id dxsoftwareRecTypeId = Id accountRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dx Software Services').getRecordTypeId(); 
       if(csid!=null && csid!='') {
       
            List<PKI_AssetCases__c> pasts=[Select Id,Asset__c From PKI_AssetCases__c Where Case__c=:csid];
            for(PKI_AssetCases__c c:pasts) {                 
                aids.add(c.Asset__c);
                maid.put(c.Asset__c,c.Id);                
            }
            asts=[Select Id,Name,SerialNumber,status,Account.Name,Product2.Name,Product2.Family,Product2.product_line__c,DX_Version__c From Asset Where Id IN:aids];
            for(Asset a:asts) {
                //if(a.PKI_ActiveAsset__c==true)
                if(cs.RecordType.DeveloperName=='Dx_Software_Services')
                {
                if(a.status!='DISCARDED' && a.status!='NOT IN USE')
                {
                CustAsts c=new CustAsts();
                c.acid=maid.get(a.Id);
                c.a=a;
                casts.add(c);
                }
                }
                
                else
                {
                CustAsts c=new CustAsts();
                c.acid=maid.get(a.Id);
                c.a=a;
                casts.add(c);
                }
            }
            
           
            if(cs.accountid!=null)
                anm=cs.Account.Name;
            if(cs.RecordType.DeveloperName=='Dx_Support')
                actTb='name2';
            else
                actTb='name1';
            
                
            asts=[Select Id,Name,status,SerialNumber,Account.Name,Product2.Name,Product2.Family,Product2.product_line__c,DX_Version__c
                         From Asset Where accountid=:cs.accountid And (Product2.ProductCode like '%5002-0130' Or
                                    Product2.ProductCode like '%5002-0180' Or Product2.ProductCode like '%5002-0370' Or 
                                    Product2.ProductCode like '%5002-0500' Or Product2.ProductCode like '%5003-0320' Or 
                                    Product2.ProductCode like '%5003-0530' Or Product2.ProductCode like '%5002-0530' Or
                                    Product2.ProductCode like 'PRENATAL%'  Or Product2.ProductCode like 'HL7%' Or Product2.ProductCode like '%2028-3010' Or
                                    Product2.ProductCode like 'US OFFICE'  Or Product2.ProductCode like 'PERKINELMER OFFICE' Or
                                    Product2.product_line__c= 'NEO' OR Product2.product_line__c= 'PRE')];
                
            for(Asset a:asts) {
                CustAsts c=new CustAsts();
                c.a=a;
                if(maid.containsKey(a.Id))
                    c.flga = false;
                else
                    c.flga = true;
                    
                //new
                if(cs.RecordType.DeveloperName=='Dx_Software_Services')
                {
                    if(a.status!='DISCARDED' && a.status!='NOT IN USE')
                      {
                        aasts.add(c);
                      }
                }
                else
                aasts.add(c);
            }
        } 
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,actTb));
    }
    
    public PageReference AssignAsset() {
        PKI_AssetCases__c pkas = new PKI_AssetCases__c();
        pkas.Asset__c = asid;
        pkas.Case__c = csid;
        pkas.name=asid+'-'+csid;
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,asid + '-' + csid));
        insert pkas;
        showAssets();
        return null;
    }
    
    public PageReference Remove() {
        PKI_AssetCases__c d=new PKI_AssetCases__c();
        d.id = asid;
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,asid + '-' + csid));
        delete d;
        showAssets();
        return null;
    }
    
    public PageReference Refresh() {
        showAssets();
        return null;
    }
    
    public PageReference ASearch() {
        SearchAsts();
        return null;
    }
    
    public void SearchAsts(){
        aasts.clear();
        String qry = 'SELECT Id,Name,SerialNumber,Account.Name,Product2.Name,Product2.Family,Product2.product_line__c,DX_Version__c FROM Asset';
        List<String> fltr=new List<String>();
        fltr.add('(Product2.product_line__c=\'NEO\' Or Product2.product_line__c=\'PRE\' Or Product2.product_line__c=\'DIA\' Or Product2.product_line__c=\'MDX\' Or Product2.product_line__c=\'VIR\' Or Product2.product_line__c=\'NAP\')');
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
        List<Asset> la=Database.query(qry + ' Order By Account.Name Limit 100');
        for(Asset n:la) {
            CustAsts s=new CustAsts();
            s.a=n;
            if(maid.containsKey(n.id))
                s.flga = false;
            else
                s.flga = true;
            aasts.add(s);
        }
    }
    
    /*********INNER OBJECT************/
    public class CustAsts {
        public ID acid {get; set;}
        public Asset a {get; set;}
        public boolean flga {get; set;}
    }
}
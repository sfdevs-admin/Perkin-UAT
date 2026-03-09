/********************************
 *Created By: Shashi Puttaswamy
 *Date : 4/16/2016
 ********************************/ 
public class pkiduplicate {
    public List<Dups> duplis { get; set; }
    public List<Dups> duplid { get; set; }
    public List<Dups> res { get; set; }
    public Account del {get; set;}
    public String criteria {get; set;}
    public String ctry {get; set;}
    public String state {get; set;}
    public String city {get; set;}
    public Integer rC {get; set;}
    List<Account> lA;
    public String vw='',idd='',url='';
    Map<ID, User> usr;
    
    public List<SelectOption> getFilters() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('CRA','Merge Multiple Accounts'));
        options.add(new SelectOption('CMFD','Delete Single Account'));
        return options;
    }
    
    public String getTheFilter() {
        return vw;
    }
            
    public void setTheFilter(String v) {
        vw=v;
    }
    
    public pkiduplicate()
    {
        vw='CRA';
        duplis = new List<Dups>();
        duplid = new List<Dups>();
        res = new List<Dups>();
        rC = res.size();
        del = new Account();
        idd = ApexPages.currentPage().getParameters().get('id');
        url = '/apex/PKIDuplicateIdentification?id='+ idd;
        lA = [SELECT ID,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,Site,ShippingStreet,ShippingCountry,ShippingState,ShippingCity,RecordType.Name,SAP_Customer_Number__c,No_of_Contacts_INF__c,No_Of_Closed_Won_Opportunities_INF__c,
               PKI_Account_Approvals__c,PKI_Approved_Owners__c FROM Account WHERE PKI_Account_Dup_Key__c!=null OR PKI_Status__c='Delete' ORDER BY PKI_Account_Dup_Key__c LIMIT 800];
        for(Account a:lA) {
            if(a.PKI_Status__c=='Delete')
                duplid.add(setDuplis(a,false,false));
            else
                duplis.add(setDuplis(a,false,false));
        }
        usr = new Map<ID, User>([SELECT Id, Name FROM User WHERE User_SFDC_Group__c='Power User']);
    }
    
    /**********PAGE CALLS***************/
    
    public PageReference sDelete() 
    {
        String did=del.Parentid;
        if(did==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Select account to be deleted'));
            return null;
        }
        
        Account m= [SELECT ID,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,Site,ShippingStreet,ShippingCountry,SAP_Customer_Number__c,No_of_Contacts_INF__c,No_Of_Closed_Won_Opportunities_INF__c,
                     ShippingState,ShippingCity,RecordType.Name,PKI_Account_Approvals__c,PKI_Approved_Owners__c FROM Account WHERE id=:did];
        if(m.SAP_Customer_Number__c!=null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Cannot delete account with SAP Customer number'));
            return null;
        }
        
        for(Dups d:duplis){
            if(d.a.id==del.Parentid){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Account is already part of merge'));
                del.Parentid=null;
                return null;
            }
        }
        
        for(Dups d:duplid){
            if(d.a.id==del.Parentid){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Account is already marked for delete'));
                del.Parentid=null;
                return null;
            }
        }
        
        m.PKI_Status__c = 'Delete';
        m.PKI_Account_Approvals__c = 1;
        m.PKI_Approved_Owners__c = UserInfo.getName();
        
        Dups d = new Dups();
        d.chk = false;
        d.dirty = false;
        d.a = m;
        duplid.add(d);
        update m;
        
        clsSearch();
        del.Parentid = null;
       
        return new pagereference(url);
    }
    
    public PageReference Approve() 
    {
        Set<String> sg = new Set<String>();
        lA = new List<Account>();
        if(vw=='CRA'){
            for(Dups d:duplis) {
                if(d.chk==true) {
                    d.chk=false;
                    if(!sg.contains(d.a.PKI_Account_Dup_Key__c))
                        sg.add(d.a.PKI_Account_Dup_Key__c);
                }
            }
            for(Dups d:duplis) {
                if(sg.contains(d.a.PKI_Account_Dup_Key__c)){
                     if(!d.a.PKI_Approved_Owners__c.contains(UserInfo.getName())){
                         d.a.PKI_Approved_Owners__c += ',' + UserInfo.getName();
                         d.a.PKI_Account_Approvals__c = d.a.PKI_Account_Approvals__c + 1;
                         if(usr.containsKey(UserInfo.getUserId()))
                             d.a.PKI_Status__c='Merge';
                         lA.add(d.a);
                     }
                }
            }
        }
        if(vw=='CMFD') {
            for(Dups d:duplid) {
                 if(d.chk==true) {
                     if(!d.a.PKI_Approved_Owners__c.contains(UserInfo.getName())){
                          d.a.PKI_Approved_Owners__c += ',' + UserInfo.getName();
                          d.a.PKI_Account_Approvals__c = d.a.PKI_Account_Approvals__c + 1;
                          lA.add(d.a);
                    }
                }
            }
        }
        
        update lA;
        
        clsSearch();
        
        return new PageReference(url);
    }
    
    public PageReference Search() {
       try{
        res.clear();
        String qry = 'SELECT ID,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,' +
                     'Site,ShippingStreet,ShippingCountry,ShippingState,ShippingCity,' +
                     'RecordType.Name,PKI_Account_Approvals__c,PKI_Approved_Owners__c,SAP_Customer_Number__c,No_of_Contacts_INF__c,No_Of_Closed_Won_Opportunities_INF__c ' +
                     'FROM Account WHERE (RecordType.Name=\'Prospect\') ';
        if(criteria!='')
            qry += ' AND name like \'' + criteria + '%\'';
        if(ctry!='')
            qry += ' AND shippingCountry=\'' + ctry + '\'';
        if(state!='')
            qry += ' AND shippingstate=\'' + state + '\'';
        if(city!='')
            qry += ' AND shippingcity=\'' + city + '\'';
        
        lA = Database.query(qry + ' Limit 1000');
        for(Account a:lA)
           if(a.PKI_ParentChild__c!='Child')
                res.add(setDuplis(a,false,false));
        rC = res.size();
        }catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
        return new PageReference(url);
    }

    public PageReference Add() {
        String pnt='';
        Integer c=0,skip=0,prnsp=0;
        lA = new List<Account>();
        for(Dups r:res){
            if(r.prn==true){
                pnt=r.a.id;
                if(r.a.SAP_Customer_Number__c!=null) {
                    prnsp=1;
                }
                c++;
            }
            if(r.a.SAP_Customer_Number__c!=null) {
                skip=2;
            }
            if(r.chk==true && r.a.PKI_ParentChild__c != 'Child' && r.a.PKI_ParentChild__c != 'Parent')
                lA.add(r.a);
        }
        if(pnt=='' || c>1) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Choose one parent account'));
            return null;
        }
        
        if(prnsp==0 && skip==2) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Choose parent account with SAP Customer number'));
            return null;
        }
        
        
        
        for(Account r:lA){
            if(r.id == pnt)
                r.PKI_ParentChild__c = 'Parent';
            else       
                r.PKI_ParentChild__c = 'Child'; 
                
             r.PKI_Account_Dup_Key__c = pnt;
             r.PKI_Status__c='Duplicate';
             r.PKI_Status__c = 'Duplicate';
             r.PKI_Account_Approvals__c = 1;
             r.PKI_Approved_Owners__c = UserInfo.getName();
             duplis.add(setDuplis(r,false,false));
        }
        update lA;
        
        clsSearch();
        
        return new pagereference(url);
    }
    
    public PageReference Remove() {
         Set<String> s=new Set<String>();
         lA = new List<Account>();
     try {
            if(vw=='CRA') {
                for(Dups d:duplis) {
                    if(d.chk==true && d.a.PKI_ParentChild__c == 'Parent')
                        s.add(d.a.PKI_Account_Dup_Key__c);
                }
            
                for (Integer i=duplis.size()-1;i>=0;--i) {
                    Dups d = duplis[i];
                    if(d.chk==true || s.contains(d.a.PKI_Account_Dup_Key__c)){
                        d.a.PKI_Account_Dup_Key__c = '';
                        d.a.PKI_Approved_Owners__c = '';
                        d.a.PKI_Account_Approvals__c = 0;
                        d.a.PKI_Status__c = null;
                        d.a.PKI_ParentChild__c=null;
                        d.chk = false;
                        lA.add(d.a);
                        duplis.remove(i);
                    }
                }
            }
            if(vw=='CMFD'){
                for (Integer i=duplid.size()-1;i>=0;--i) {
                    Dups d = duplid[i];
                    if(d.chk==true){
                        d.a.PKI_Account_Dup_Key__c = '';
                        d.a.PKI_Approved_Owners__c = '';
                        d.a.PKI_Account_Approvals__c = 0;
                        d.a.PKI_Status__c = null;
                        d.a.PKI_ParentChild__c=null;
                        d.chk = false;
                        lA.add(d.a);
                        duplid.remove(i);
                    }
                }
            }
            
            update lA;
            clsSearch();
            
      } catch(Exception ex) {
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
      }
      return new PageReference(url);
    }
    
    public PageReference Parent() {
        Map<String, String> pg = new Map<String, String>();
        Set<String> u = new Set<String>();
        lA = new List<Account>();
        for(Dups d:duplis) {
            if(d.chk==true) {
                d.chk=false;
                if(!pg.containsKey(d.a.PKI_Account_Dup_Key__c))
                    pg.put(d.a.PKI_Account_Dup_Key__c,d.a.id);
            }
        }
        for(Dups d:duplis){
            if(pg.containsKey(d.a.PKI_Account_Dup_Key__c)) {
                 if(d.a.id==pg.get(d.a.PKI_Account_Dup_Key__c))
                     d.a.PKI_ParentChild__c='Parent';
                 else
                      d.a.PKI_ParentChild__c='Child'; 
                 d.a.PKI_Account_Dup_Key__c=pg.get(d.a.PKI_Account_Dup_Key__c);  
                if(!u.contains(d.a.Id)) {
                        lA.add(d.a);
                    u.add(d.a.Id);
                }
            }
        }
        update lA;
        
        clsSearch();
        
        return new PageReference(url);
    }
     
    public PageReference SelectAll() {
        if(vw=='CRA'){
            for(Dups d:duplis)
                d.chk=true;
        }
        if(vw=='CMFD'){
            for(Dups d:duplid)
                d.chk=true;
        }
        clsSearch();
        return new PageReference(url);
    }
    
    public PageReference UnSelectAll() {
        if(vw=='CRA'){
            for(Dups d:duplis)
                d.chk=false;
        }
        if(vw=='CMFD'){
            for(Dups d:duplid)
                d.chk=false;
        }
        clsSearch();
        return new PageReference(url);
    }
    
    public PageReference ClearSearch() {
        clsSearch();
        return new PageReference(url);
    }
    
    public PageReference Cancel() {
        return new PageReference('/' + idd);
    }

    /********UTILITY FUNCTIONS******/
    
    public Dups setDuplis(Account m,Boolean c, Boolean y) {
        Dups d = new Dups();
        d.chk = c;
        d.dirty = y;
        d.a = m;
        return d;
    }
    
    public void clsSearch() {
        res.clear();  
        rC=res.size();
        criteria='';
        ctry='';
        state='';
        city='';
    }
    
    /*********INNER OBJECT************/
    public class Dups {
        public Boolean chk {get; set;}
        public Account a {get; set;}
        public Boolean dirty {get; set;}
        public Boolean prn {get; set;}
        public Dups(){}
    }
}
public class MyContactCtrl {
    private Id actid;
    public List<dbContacts> ldbcts {get;set;}

    public MyContactCtrl(){
        ldbcts = new List<dbContacts>();
        actid = ApexPages.currentPage().getParameters().get('id');
        getContacts();
    }
    
    private void getContacts(){
        if(actid!=null) {
            List<Contact> lc=[Select Id,Name,PKI_SAP_Customer_Number__c,Owner.Name,Email From Contact Where accountid=:actid];
            for(Contact c:lc){
                dbContacts d = new dbContacts();
                d.chk = false;
                d.cts = c;
                if(c.PKI_SAP_Customer_Number__c!=null)
                    d.cmts = 'Contact Salesforce Administrator to merge this contact';
                ldbcts.add(d);
            }
        }
    }

    public PageReference Save(){
        List<Contact> lu= new List<Contact>();
        for(dbContacts c:ldbcts){
            if(c.chk==true && c.cts.PKI_SAP_Customer_Number__c==null){
                Contact u = new Contact();
                u.Id = c.cts.Id;
                u.ownerId = UserInfo.getUserId();
                lu.add(u);
            }
        }
        if(lu.size()>0)
            update lu;
        pagereference ref=new PageReference('/' + actid);
        return ref;
    }
    
    public PageReference Cancel() {
        pagereference ref=new PageReference('/' + actid);
        return ref;
    }
    
    /** Database of Contacts **/
    public class dbContacts{
        public Boolean chk {get;set;}
        public Contact cts {get;set;}
        public String cmts {get;set;}
    }
}
/*
Class      : cls_createContactFromCase 
Test class : 
Reason     : Controller to create contact and search contact from case record
VF Page    : SearchCaseContactPage , createContactFromCase

Change History 
******************************************************************************************************************************************
SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
******************************************************************************************************************************************
*/
public with sharing class cls_createContactFromCase {
    public Contact newContact{get;set;} 
    public id caseid {get;set;}
    public Case casetoupdate{get;set;}
    public string Conname {get;set;}
    public string ConEmail {get;set;}
    public list<contact>  listcon {get;set;} 
    public  List < WrapperClass > wrapperTempList {get;set;}
    public boolean IsRender{get;set;}
    public String  pageName ='';
    public List < Contact > selectedCon ;
    
    //constructor
    public cls_createContactFromCase(ApexPages.StandardController controller){
        wrapperTempList = new List < WrapperClass >();
        selectedCon = new List < Contact > ();
        //get the current vf page to populate the email field when necessary
        pageName = ApexPages.currentPage().getUrl().substringBetween('apex/', '?');
        newContact = new contact();
        IsRender = false;
        listcon= new list<contact>();
        caseid = controller.getRecord().id;
        casetoupdate = new Case(Id=caseid);
        //populate the email field value in search contact page
         if(pageName =='SearchCaseContactPage'){
        list<case> caseobj=new list<case>([SELECT SuppliedEmail,id,ContactEmail FROM case where id=: caseid]);
        if(caseobj[0].SuppliedEmail!='' && caseobj[0].SuppliedEmail!=null){
        Conname = '';
        ConEmail = caseobj[0].SuppliedEmail;
        searchcontact(); 
        }else if(caseobj[0].ContactEmail!='' && caseobj[0].ContactEmail!=null){
        Conname = '';
        ConEmail = caseobj[0].ContactEmail;
        searchcontact(); 
        }
        }
    }
    
    //method to create new contact and to check if there are duplicates
    public PageReference createContact(){
      
      list<Contact> dupcon = new list<contact>();
      //do not do the duplicate check if email is value is null
       if(newContact.email!=null){
       dupcon = [select id from contact where email =:newContact.email limit 1] ;
       }
       if(dupcon.isempty()){
        try{
           
            insert newContact;
            if(newContact.id!=null)
                casetoupdate.ContactId = newContact.Id;
            update casetoupdate;
            PageReference pageref = new PageReference('/'+caseid);
            return pageref;
        }catch(Exception e){
            ApexPages.addMessages(e);
        }}
        else{
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'A contact already exists with the same email'));
           }
         return null;
        
    }
    
    //method to redirect to case parent page on cancel action
    public PageReference actionforcancel(){
        PageReference pageref = new PageReference('/'+caseid);
        pageref.setRedirect(true);
        return pageref;
    }  
    
    //method to populate the selected contact in case record
    public pagereference selectedRecords() {
        
        for (WrapperClass wrapRec: wrapperTempList) {
            /*Check if record is selected*/
            if (wrapRec.isSelected) {
                selectedCon.add(wrapRec.ConRec);
            }
        }
        //allow the user to choose only one contact at a time
        if(selectedCon.size()>1){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'You have selected multiple contacts. Please select just one.'));
       
        } 
        else if (selectedCon.size()==0){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Please select atleast one contact.'));
        } 
        else if (  selectedCon.size()==1 ){
        casetoupdate.Contactid=selectedCon [0].id;
        casetoupdate.Accountid=selectedCon [0].Accountid;
        try{
            update casetoupdate;
            PageReference pageref = new PageReference('/'+caseid);
            pageref.setRedirect(true);
            return pageref;
        }
        catch(Exception e)
        {
            String error = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,error));
        } 
        }
        selectedCon.clear();
        return null;
    }
    
    //method to build wrapper and search contacts based on search string input
    public void searchcontact() {
        wrapperTempList.clear();
        isrender = false;
        String qry;
        if(Conname!='' && ConEmail!=''){
            qry = 'select id,firstname,lastname,email,Accountid,Account.name from contact ' +
                'where name LIKE \'%'+Conname+'%\' AND Email =: ConEmail order by name limit 100';
        }else if(Conname!=''){
            qry = 'select id,firstname,lastname,email,Accountid,Account.name from contact ' +
                'where name LIKE \'%'+Conname+'%\' order by name limit 100';
        }else if(ConEmail!=''){
            qry = 'select id,firstname,lastname,email,Accountid,Account.name from contact ' +
                'where Email = :ConEmail order by name limit 100';
        }
        system.debug(qry+'query');
        listcon = Database.query(qry);
        for(Contact ct:listcon){
            wrapperTempList.add(new WrapperClass(ct, false));
        }
        if(wrapperTempList.size()>0){
            isrender = true;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'No Contact Records found'));
        }
    }
    
    
    /*Wrapper class definition*/
    public class WrapperClass {
        public Boolean isSelected {get;set;}
        public Contact ConRec {get;set;}
        public WrapperClass(Contact ConRec , Boolean isSelected) {
            this.ConRec = ConRec ;
            this.isSelected = isSelected;
        }
    }
}
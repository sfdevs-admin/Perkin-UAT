public with sharing class AddBugsandSuggestionsController {
    
    public list<INF_Bugs_Suggestions__c> accountList{get;set;}
    public list<Accountwrapper> accountwrapperList{get;set;}
    public Integer counter{get;set;}
    public List<Case> caserecord {get;set;}
    public Id caseid;
    
    public AddBugsandSuggestionsController(ApexPages.StandardController controller){
      caseid = controller.getId();
      caserecord =[select id,Subject from Case where Id=:caseid];
           counter = 0;
           accountList = new list<INF_Bugs_Suggestions__c>(); 
           accountwrapperList = new list<Accountwrapper>();
           for(Integer i=0;i<1;i++){
               Accountwrapper actWrap = new Accountwrapper(new INF_Bugs_Suggestions__c()); 
               counter++;
               actWrap.counterWrap = counter;
               actWrap.account.INF_Case__c = caseid;
               accountwrapperList.add(actWrap); 
               
           }
       
    }
    
    public PageReference addRow(){
        Accountwrapper actWrap = new Accountwrapper(new INF_Bugs_Suggestions__c()); 
        
        counter++;
        actWrap.counterWrap = counter;
        actWrap.account.INF_Case__c = caseid;  
        accountwrapperList.add(actWrap); 
        return null;    
    }
    public PageReference removingRow(){
    
        Integer param = Integer.valueOf(Apexpages.currentpage().getParameters().get('index'));
        
        for(Integer i=0;i<accountwrapperList.size();i++){
            if(accountwrapperList[i].counterWrap == param ){
                accountwrapperList.remove(i);     
            }
        }
              
        counter--;
        return null;    
    }
    
    public PageReference saving(){
        list<INF_Bugs_Suggestions__c> updateAccountList;
        updateAccountList = new list<INF_Bugs_Suggestions__c>();
        if(!accountwrapperList.isEmpty()){
            for(Accountwrapper accountWrapper:accountwrapperList){
               
                //if(accountWrapper.account.Bug__c!= NULL && accountWrapper.account.INF_Type__c != NULL){
                    /*
                    if(accountWrapper.account.Bug__c.contains('-') && !accountWrapper.account.Bug__c.contains(':')){
                        System.debug('$$$$$'+accountWrapper.account.Bug__c.lastindexOf ('-'));
                        String requiredString = accountWrapper.account.Bug__c.substring(0,accountWrapper.account.Bug__c.lastindexOf ('-'));
                        Integer i = accountWrapper.account.Bug__c.length();
                        accountWrapper.account.INF_Bug_Number__c = requiredString;
                        accountWrapper.account.INF_Title__c = accountWrapper.account.Bug__c.substring(accountWrapper.account.Bug__c.lastindexOf ('-'),i);
                    }
                    if(accountWrapper.account.Bug__c.contains(':') && accountWrapper.account.Bug__c != NULL){
                        String requiredString = accountWrapper.account.Bug__c.substring(0,accountWrapper.account.Bug__c.indexOf (':'));
                        Integer i = accountWrapper.account.Bug__c.length();
                        accountWrapper.account.INF_Bug_Number__c = requiredString;
                        accountWrapper.account.INF_Title__c = accountWrapper.account.Bug__c.substring(accountWrapper.account.Bug__c.lastindexOf (':'),i);
                    }*/
                    
               // updateAccountList.add(accountWrapper.account);
              //  }
                //added on 10 /09
                updateAccountList.add(accountWrapper.account);
            }
            caserecord[0].INF_Categories__c = 'Bug';
            update caserecord;
        }
        if(!updateAccountList.isEmpty()){
            upsert updateAccountList;
        }
       //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Info,'Record Saved Successfully.');
       //ApexPages.addMessage(myMsg); 
       PageReference pr = new PageReference('/'+caseid);
       return pr;
    }
    
    public class Accountwrapper{
        public INF_Bugs_Suggestions__c account{get;set;}
        public Integer counterWrap{get;set;}
        
        public Accountwrapper(INF_Bugs_Suggestions__c act){
            this.account = act;  
             
        }
    }
    
    public PageReference Goback() {
    
    PageReference pref = new PageReference ('/'+caseid);
    pref.setredirect(true);
    return pref;
    
    }
    
}
public class AddProductController{

 public String ProductCode {get;set;}
 public String Name {get;set;}
 public List<INF_Application__c> prodlist{set; get;}
 public Id caseid;
 public List<JPCCProductWrapper> listJPCCProducts { get; set; }
 public Set<String> SelId {get; set;}
 public String searchText { get; set; }
 public Boolean ShowMsgs {get; set;}
 public List<Id> ProductselectedList;
 public String ProdId;
 public String saveSelectedIds{get;set;}
 public String saveSelectedNames{get;set;}
 public String selectedproducts{get;set;}
 public Pagereference addToList(){
     List<String> strings_names = saveSelectedNames.split(',');
           for(String s: strings_names){
               if(selectedproducts  <> Null){
                   selectedproducts = selectedproducts + s +'\n';
               } 
               else if(selectedproducts == null){
                    selectedproducts = s + '\n';
               }
           } 
      return null;
  }
 
    public class JPCCProductWrapper{
        public INF_Application__c prod{get; set;}
        public Boolean selected {get; set;}
        
        public JPCCProductWrapper(INF_Application__c productlist,Boolean s){
            this.prod = productlist;
            this.selected = s;
        }
    }
public ApexPages.StandardSetController standardSetCon{
        get {
            if(standardSetCon == null) {
                standardSetCon = new ApexPages.StandardSetController(prodlist);
                // sets the number of records in each page set
                standardSetCon.setPageSize(300);    
                standardSetCon.setpageNumber(1);            
            }
        return standardSetCon;
        }
    set;
    }
       
    public AddProductController(){ 
        listJPCCProducts = new List<JPCCProductWrapper>();  
        prodlist = new List<INF_Application__c>();
        SelId = new Set<string>();
        searchText = System.currentPageReference().getParameters().get('lksrch');
        caseid= ApexPages.currentPage().getParameters().get('id');
    }
  
    public void searchprods(){
          standardSetCon = null;
          prodlist = [select id,Name,INF_Product_Group__c from INF_Application__c WHERE INF_Default__c=1 ];
          allprodlist();
    }

    public void allprodlist(){
   
        if(standardSetCon.getRecords().size()>0){
            listJPCCProducts = new List<JPCCProductWrapper>(); 
            for(INF_Application__c prodrecord:(List<INF_Application__c>)standardSetCon.getRecords()){
                JPCCProductWrapper wrapper = new JPCCProductWrapper(prodrecord,false);
                listJPCCProducts.add(wrapper);
            }
        }
        else
            listJPCCProducts.clear();    
    
    }

    public List<INF_Application__c> getProducts() {       
        return prodlist;  
    }
 
    public void initialize() {      
        searchproducts();                                                                  
    }

     public PageReference searchproducts(){
       prodlist = new List<INF_Application__c>();
       standardSetCon = null;     
       String soql = 'select id, Name, INF_Product_Group__c, Application_Sequence__c from INF_Application__c WHERE INF_Default__c=1  ORDER BY Application_Sequence__c';
       String whereCondition = '';
        if (Name!= null && Name!= '') {
            Name = Name.replaceAll('\\*','%');
            whereCondition = whereCondition +' where Name LIKE \'' +'%'+ Name+'%\' ';
        }
            soql = soql + whereCondition +' limit 200';
            System.debug('%%%%'+soql);
            try{
                prodlist = database.query(soql);
            }
            catch(Exception e){
                System.debug('Exception'+e.getMessage());
            }
            
        if(prodlist.size()==0){
            listJPCCProducts.clear();
        }
        else{
            listJPCCProducts = new List<JPCCProductWrapper>(); 
            for(INF_Application__c queuerecord:(List<INF_Application__c>)standardSetCon.getRecords()){
                JPCCProductWrapper wrapper = new JPCCProductWrapper(queuerecord,false);
                listJPCCProducts.add(wrapper);
            }
        }
        return null;  
   }
   
    public pagereference SubmitQueue() { 
        ShowMsgs = true; 
        Integer int2 = 0;
        ProductselectedList = new List<Id>();  
        String temp; 
        if(saveSelectedIds == null || saveSelectedIds == ''){
            ShowMsgs = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Product'));
            return null;
        }   
        else if(saveSelectedIds != NULL || saveSelectedIds != ''){
           List<String> strings = saveSelectedIds.split(',');
           for(String s: strings){
               SelId.add(s);
           }         
             for(String newSelId : SelId){
                if(newSelId!=null){
                List<INF_Application__c> prod = [select Id,Name,INF_Product_Group__c from INF_Application__c where Id =:newSelId];
                    if(prod.size()>0)
                        ProductselectedList.add(prod[0].Id);              
                }              
             } 

            caseid = ApexPages.currentPage().getParameters().get('id');
            List<Case> casetoupdate = [select id from Case where id =:caseid];
            List<INF_Case_Application__c> caseapp = new List<INF_Case_Application__c>();
            for(Integer i =0;i<ProductselectedList.size();i++){
                caseapp.add(new INF_Case_Application__c(Application__c = ProductselectedList[i],Case__c =caseid));
            }
             insert caseapp;
            
        }
      PageReference pr = new PageReference('/'+caseid);
      return pr;
    }
   
    public PageReference nullAction() {
       PageReference pr = new PageReference('/'+caseid);
      return pr; 
    } 
}
/********* Modified by   : Lister Technologies **********/
/********* Modified date : 3/27/2015  *******************/
/********* Purpose       : New Controller - updated*******************/

global class SalesRepLookupController {
    
    public List<SalesRep> salesReps {set;get;}
    public String country {get;set;}
    public String zipCode {get;set;}
    public String product {get;set;}
    public boolean searchresult{get;set;}
    public string NoOfRecords{get;set;}
    public Map<String,ProductList__c> mapProductCustomsSettings{get;set;}
    public Map<String,Sales_Rep_Country_List__c> mapOfCountries{get;set;}
    public list<Selectoption> lstProducts {get;set;}
    public list<Selectoption> countryList {get;set;}
    Map<String,SalesRep> salesrepmap=new Map<String,SalesRep>(); // Map to remove duplicates. Email + Product will be the key string


    
    public SalesRepLookupController()
    {
        salesReps = new List<SalesRep>();
        country = ApexPages.currentPage().getParameters().get('CN');
        zipcode = ApexPages.currentPage().getParameters().get('ZC');
        product = ApexPages.currentPage().getParameters().get('PL');
        //String will be set to true when a request is made 
        string str=ApexPages.currentPage().getParameters().get('SR');
       
        mapProductCustomsSettings = ProductList__c.getAll();
        mapOfCountries = Sales_Rep_Country_List__c.getAll();
        PopulateProductPicklist();
        
        if(str=='true'){
            searchresult=true;
            try{
            getReps();
            }
            catch(Exception e){}
        }    
        else
            searchresult=false;    
            
    }
    
    public void PopulateProductPicklist(){

        //Get the product list from custom setting
        lstProducts = new list<SelectOption>();
        list<SelectOption> TempList = new list<SelectOption>();
        //TempList.add(new selectoption('None','Select product line'));
        for(String str : mapProductCustomsSettings.keyset()){
            TempList.add(new selectoption(str,mapProductCustomsSettings.get(str).Product_Name__c));
        }
        lstProducts = sortSelectOptions(TempList,false, 'product');

        //Get the country list from custom setting
        countryList = new list<SelectOption>();
        TempList = new list<SelectOption>();
        //TempList.add(new selectoption('None','Select product line'));
        for(String str : mapOfCountries.keyset()){
            TempList.add(new selectoption(str,mapOfCountries.get(str).Country__c));
        }
        countryList = sortSelectOptions(TempList,false, 'country');

    }
    
      public List<SelectOption> sortSelectOptions(List<SelectOption> sortingList, boolean IsPopup, String type) {
        List<SelectOption> sortedlist = new List<SelectOption>();
        if(IsPopup == false && type == 'product'){
            sortedlist.add(new selectOption('None', 'Select product line'));
        }
        else
        {
            sortedlist.add(new selectOption('None', 'Select Country'));
        }
        for (Integer i =0; i < sortingList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (sortingList[j-1].getLabel() > sortingList[j].getLabel()){
                    SelectOption temp = sortingList[j];
                    sortingList[j] = sortingList[j-1];
                    sortingList[j-1] = temp;
                }
            }
        }
        sortedlist.Addall(sortingList);
        return sortedlist;
    }
    public List<SalesRep> getReps() {
       // getVFPageName();
        if (zipCode != null)
        {
            
            //This is a hack for the fact that the constructor is getting called even when 
            //I close the page and redirect to the parent.
            //It's probably best to have a separate controller for the results page.
            
            salesReps = getSalesReps();
            System.debug('salesReps count = ' + salesReps.size());
        }
        return salesReps;
    }
       //SG Class
    global class SalesRep implements Comparable{
        public String Name {get;set;}
        public String Email {get;set;}
        public String ManagerName {get;set;}
        public String ManagerEmail {get;set;}
        public String AccountName {get;set;}
        public String product{get;set;}
        public String AssignLevel{get;set;}
        public String skill{get;set;}
        public String work{get;set;}
        public string UsableWork{get;set;}
        public String cell{get;set;}
        public string UsableCell{get;set;}
        public String Role{get;set;}
        //public String ProductName{get;set;}
    
        //public SalesRep(String pdtName){
        //    ProductName = pdtName;
        //}

        global Integer compareTo(Object compareTo) {
        system.debug('product+'+product+ '====' + ((SalesRep)compareTo).product);
        if(product == null)
            product = '';

        Integer returnValue = 0;    

        SalesRep repToBeCompared = (SalesRep)compareTo;
        if(product > repToBeCompared.product){
            returnValue = 1;
        }
        else if(product < repToBeCompared.product){
            returnValue = -1; 
        }

        return returnValue;
        //return product.trim().CompareTo(((SalesRep)compareTo).product.trim());
  
    }


       
    }
    
    public string getUsableNumber(string OriginalNumber){
        if(OriginalNumber != null && OriginalNumber != ''){
            system.debug('OriginalNumber+'+OriginalNumber);
            OriginalNumber = OriginalNumber.remove('(');
            OriginalNumber = OriginalNumber.remove(')');
            OriginalNumber = OriginalNumber.remove('-');
            OriginalNumber = OriginalNumber.remove(' ');
            if(OriginalNumber.contains('+')){
                OriginalNumber = OriginalNumber.remove('+'); 
                OriginalNumber = '00' + OriginalNumber;
            }    
        }
        system.debug('OriginalNumber+'+OriginalNumber);
        return OriginalNumber;
    }
    
    // method called by the Visualforce page's submit button
 
    public PageReference submit() {
        searchresult=false;
        pageReference pg = new pageReference('/apex/SalesRepLookupSinglePage?ZC=' + zipcode + '&CN=' + country + '&PL=' + product+'&SR=true');
        pg.setRedirect(true);
        return pg;
    }
    
  
    // method called by the Visualforce page's close button

    public PageReference CloseResultsPage() {
        searchresult=false;
        pageReference pg = new pageReference('/apex/SalesRepLookupSinglePage');
        pg.setRedirect(true);
        return pg;
    }
     
    // call the REST service with the address info
    public SalesRep[] getSalesReps() {
        NoOfRecords = ''; 
        System.debug('zipcode = ' + zipcode + ' product = ' + product + ' country = ' + country);
       
        SalesRepLookupService.WebServices_PESFDCSalesRepLookup_Port service = 
        new SalesRepLookupService.WebServices_PESFDCSalesRepLookup_Port();
        service.clientCertName_x = Label.Sales_Rep_Lookup_Cert;
        if(product == 'None'){
            product = '';
        }
        SalesRepLookupService.SalesReps2[] salesReps = new List<SalesRepLookupService.SalesReps2>();
        system.debug('salesReps '+salesReps);
        system.debug('salesReps '+service.salesRepLookupV2(country, zipcode, product));
        if(service.salesRepLookupV2(country, zipcode, product) != null){
            salesReps = service.salesRepLookupV2(country, zipcode, product);
            system.debug('----'+salesReps);
        }
     
        Set<String> userEmails = new  Set<String>();
        for (SalesRepLookupService.SalesReps2 rep : salesReps) {
            /*TEMP CODE --- LISTER-- TO BE REMOVED
            if(rep.SalesRepEmail.trim() ==  'duane.chase@perkinelmer.com'){
                userEmails.add('duane.chase=perkinelmer.com@example.com');
                rep.SalesRepEmail = 'duane.chase=perkinelmer.com@example.com';
            }
            else
                ------------     ------------*/
                system.debug('rep.SalesRepEmail.trim()+ '+rep.SalesRepEmail.trim());
            userEmails.add(rep.SalesRepEmail.trim());
        }
        
        system.debug('userEmails+++' +userEmails);
        system.debug('userEmails+++' +userEmails.size());
        Map<String, User> map_userEmail_user = new  Map<String, User>();
        for(User u : [Select Id, MobilePhone, Phone, Email from User where Email in : userEmails]){
            map_userEmail_user.put(u.Email, u);
        }
        
        userEmails = new  Set<String>();
        // SalesRep[] salesRepList = new List<SalesRep>();
        system.debug('#####salesReps' + salesReps);
        for (SalesRepLookupService.SalesReps2 rep : salesReps) {
            if(!userEmails.contains(rep.SalesRepEmail)){
                System.debug('Rep = ' + rep);
                SalesRep salesRep = new SalesRep();
                salesRep.Name = rep.SalesRepName;
                salesRep.Email = rep.SalesRepEmail.trim().toLowerCase();
                salesRep.ManagerName = rep.SalesRepsManagerName;
                salesRep.ManagerEmail = rep.SalesRepsManagerEmail.trim().toLowerCase();
                system.debug('ep.AssignLevel' + rep.AssignLevel);
                salesRep.Role = getRole(rep.AssignLevel);
                system.debug('+++++'+rep.SalesRepEmail);
                if(map_userEmail_user.containskey(rep.SalesRepEmail.trim().toLowerCase())){
                    system.debug('inside containskey' + rep.SalesRepEmail.trim());
                    salesRep.work = map_userEmail_user.get(rep.SalesRepEmail.trim().toLowerCase()).Phone;
                    salesRep.cell = map_userEmail_user.get(rep.SalesRepEmail.trim().toLowerCase()).MobilePhone;
                    salesRep.UsableWork = 'tel:' + getUsableNumber(salesRep.work);
                    salesRep.UsableCell = 'tel:' + getUsableNumber(salesRep.cell);
                    system.debug('salesRep.work' + salesRep.work);
                    system.debug('salesRep.cell' + salesRep.cell);
                 }
                // Uncomment once product is mapped
                if(mapProductCustomsSettings.Containskey(rep.ProductLine.trim())){
                     salesRep.product = mapProductCustomsSettings.get(rep.ProductLine.trim()).Product_Name__c.trim(); 
                     //This map removes the duplicates with email - product combination
                     salesrepmap.put(salesRep.Email + '-' +salesRep.product, salesRep);
                     // salesRepList.add(salesRep);   
                 }
                 else{
                     system.debug(salesRep);
                    salesRep.product = rep.ProductLine.trim();
                 }
                 //salesrepmap.put(salesRep.Email + '-' +salesRep.product, salesRep);
                 //salesRepList.add(salesRep);    
              }
         }
             //This is for the hack in the getReps() method, for the fact that the constructor is getting called even when 
        //I close the page and redirect to the parent.
        //It's probably best to have a separate controller for the results page.
        
       /* zipCode = null;
        productLine = null;
        country = null;*/
        if(salesrepmap.values().size() == 0)
            NoOfRecords = 'No records found';
        else if(salesrepmap.values().size() == 1)
            NoOfRecords = '1 record found'; 
        else if(salesrepmap.values().size()>1)
            NoOfRecords = salesrepmap.values().size() + ' records found'; 
        //salesrepmap.values().sort();
        List<SalesRep> TempList = new List<SalesRep>();
        for(SalesRep rep : salesrepmap.values()){
            TempList.add(rep);
        }
        TempList.sort();
        return TempList;
      }       
        
        
      public string getRole(string rolecode){
        system.debug('rc++'+rolecode +'-');
        string strRole = '';
        rolecode = rolecode.trim();
        if(rolecode == 'PS1' || rolecode == 'PS2' || rolecode == 'PS3'){
            strRole = 'Product Specialist';
            }
        else if(rolecode == 'SE1'){
            strRole = 'Sales Rep';
            }
        else if(rolecode == 'SE2'){
            strRole = 'Inside Sales';
            }
        system.debug('strRole++ '+ strRole);
        return  strRole;
    }
    
}
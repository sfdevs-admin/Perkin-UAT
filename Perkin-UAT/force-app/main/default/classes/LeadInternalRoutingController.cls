/********* Modified by   : Lister Technologies **********/
/********* Modified date : 3/27/2015  *******************/
/********* Purpose       : New Controller - updated*******************/

global class LeadInternalRoutingController{
    
    public List<SalesRep> salesReps {set;get;}
    public String country {get;set;}
    public String product {get;set;}
    public String zipcode{get;set;}
    public boolean searchresult{get;set;}
    public string NoOfRecords{get;set;}
    public Map<String,ProductList__c> mapProductCustomsSettings{get;set;}
    public Map<String,Sales_Rep_Country_List__c> mapOfCountries{get;set;}
    public list<Selectoption> lstProducts {get;set;}
    public list<Selectoption> countryList {get;set;}
    Map<String,SalesRep> salesrepmap=new Map<String,SalesRep>(); // Map to remove duplicates. Email + Product will be the key string
    public list<SelectOption> Business_Unit {get;set;}
    public String bu {get;set;}
    public String state {get;set;}
    public Map<String,String> ISO_Codemap{get;set;}
    
    public LeadInternalRoutingController() {
        salesReps = new List<SalesRep>();
        ISO_Codemap = new Map<String,String>();
        country = ApexPages.currentPage().getParameters().get('CN');
        product = ApexPages.currentPage().getParameters().get('PL');
        bu      = ApexPages.currentPage().getParameters().get('BU');
        State   = ApexPages.currentPage().getParameters().get('ST');
        zipcode = ApexPages.currentPage().getParameters().get('ZC');
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
    
    public void PopulateProductPicklist() {
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
            ISO_Codemap.put(mapOfCountries.get(str).Country__c,mapOfCountries.get(str).Name);
        }
        countryList = sortSelectOptions(TempList,false, 'country');
        Business_Unit = new List<SelectOption>();
        Business_Unit.add(new selectOption('None','Select Business Unit'));
        for(Business_Units__c b: Business_Units__c.getAll().values()){
            Business_Unit.add(new selectOption(b.Name,b.BU_Name__c));
        }
    }
    
    public List<SelectOption> sortSelectOptions(List<SelectOption> sortingList, boolean IsPopup, String type) {
        List<SelectOption> sortedlist = new List<SelectOption>();
        if(IsPopup == false && type == 'product'){
            sortedlist.add(new selectOption('None', 'Select product line'));
        }
        else if(IsPopup == false && type == 'BU'){
            sortedlist.add(new selectOption('None', 'Select Business Unit'));
        }
        else
        {
            sortedlist.add(new selectOption('None', 'Select Country'));
            sortedlist.add(new selectOption('Americas', 'Americas'));
            sortedlist.add(new selectOption('APAC', 'APAC'));
            sortedlist.add(new selectOption('EMEA', 'EMEA'));
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
        salesReps = getSalesReps();
        System.debug('salesReps count = ' + salesReps.size());
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
        public String igor_pac{get;set;}
        public String Company{get;set;}
        public String Topic{get;set;}
        public String LeadType{get;set;}
        public String leadSource{get;set;}
        public String JobFunction{get;set;}
        public String Title{get;set;}
        public String SecondaryQualification{get;set;}
        public String State{get;set;}
        public String Description{get;set;}
        public String Queue{get;set;}
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
        pageReference pg = new pageReference('/apex/LeadInternalRoutingPage?&CN=' + country + '&PL=' + product+'&SR=true'+'&BU=' + bu+ '&ST=' + state + '&ZC=' + zipcode);
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
        System.debug('Country::' + Country);
        System.debug('State::' + State);
        System.debug('Product::' + Product);
        System.debug('BU::' + bu);
        Integer i=0;
        List<SalesRep> TempList = new List<SalesRep>();
        String Query = 'select Assigned_To__c,BU__c,Company__c,Description__c,Email__c,Global_Region__c,IGOR_PAC__c,Lead_Type__c,Lead_Source__c,Queue__c,Job_Function__c,State_Province__c,Title__c,Product_Line__c,Seconday_Qualification__c,Topic__c FROM Rep_Assignment_Table__c';
        
        if(country != 'None' || State!=null || Product != 'None' || bu != 'None' || zipcode!= null){
            Query = Query + ' WHERE';
        }
        if(!String.isBlank(State)){
            Query = Query + ' State_Province__c INCLUDES (\'' + State + '\')';
            i=1;
        }
        if(country != 'None'){
            if(i>0){Query = Query + ' AND';}
            if(Country == 'EMEA' || Country == 'Americas' || Country == 'APAC')
                Query = Query + ' Global_Region__c=\'' + Country + '\'';
            else
                Query = Query + ' Country__c INCLUDES (\'' + mapOfCountries.get(Country).Name + '\')';  
            i=2;
        }
                
        if(product != 'None' && !String.isBlank(product)){
            if(i>0){ Query = Query + ' AND'; }
            Query = Query + ' Product_Line__c INCLUDES (\'' + product + '\')';
            i=3;
        }
        if(bu != 'None'){
            if(i>0){ Query = Query + ' AND'; }
            Query = Query + ' BU__c INCLUDES (\'' + bu + '\')' ;
            i = 4;
        }
        if(Country == 'IN'){
            If(zipcode != ''){
            if(i>0){ Query = Query + ' AND'; }
            Query = Query + ' Postal_Code__c =' + zipcode;
            }
            else{
            Query = Query + ' LIMIT 2000';
            }
        }
        
        System.debug('[QUERY]::' + Query);
        
        Map<Id,Rep_Assignment_Table__c> rep_ids = new Map<Id,Rep_Assignment_Table__c>();
        List<Rep_Assignment_Table__c> reps = Database.query(Query);
        for(Rep_Assignment_Table__c r: reps){
            if(r.Assigned_To__c != null){
                rep_ids.put(r.Assigned_To__c,r);
            }
            else{
                SalesRep rep = new SalesRep();
                rep.igor_pac = r.IGOR_PAC__c;
                rep.company = r.Company__c;
                rep.Topic = r.Topic__c;
                rep.SecondaryQualification = r.Seconday_Qualification__c;
                rep.LeadType = r.Lead_Type__c;
                rep.LeadSource = r.Lead_Source__c;
                rep.JobFunction = r.Job_Function__c;
                rep.Title = r.Title__c;
                rep.State = r.State_Province__c;
                rep.Description = r.Description__c;
                rep.product= r.Product_Line__c;
                rep.State = r.State_Province__c;
                rep.Queue = r.Queue__c;
                salesrepmap.put(r.Queue__c,rep);
                
            }
        }
        
        List<user> Rep_Det = [select Name,email,Manager.Name,Manager.Email,Phone,MobilePhone,UserRole.Name from User where Id in :rep_ids.keySet()];
        For(User u: Rep_Det){
            SalesRep rep = new SalesRep();
            rep.Name = u.Name;
            rep.Email = u.Email;
            rep.ManagerName = u.Manager.Name;
            rep.ManagerEmail = u.Manager.Email;
            rep.Role = u.UserRole.Name;
            rep.Work = u.phone;
            rep.Cell = u.MobilePhone;
            rep.igor_pac = rep_ids.get(u.Id).IGOR_PAC__c;
            rep.company = rep_ids.get(u.Id).Company__c;
            if(rep_ids.get(u.Id).Company__c == null)
            rep.company = rep_ids.get(u.Id).Email__c;
            rep.Topic = rep_ids.get(u.Id).Topic__c;
            rep.SecondaryQualification = rep_ids.get(u.Id).Seconday_Qualification__c;
            rep.LeadType = rep_ids.get(u.Id).Lead_Type__c;
            rep.LeadSource = rep_ids.get(u.Id).Lead_Source__c;
            rep.JobFunction = rep_ids.get(u.Id).Job_Function__c;
            rep.Title = rep_ids.get(u.Id).Title__c;
            rep.State = rep_ids.get(u.Id).State_Province__c;
            rep.Description = rep_ids.get(u.Id).Description__c;
            rep.product= rep_ids.get(u.id).Product_Line__c;
            rep.State = rep_ids.get(u.id).State_Province__c;
            salesrepmap.put(rep.Email,rep);
        }
        if(salesrepmap.values().size() == 0)
            NoOfRecords = 'No records found';
        else if(salesrepmap.values().size() == 1)
            NoOfRecords = '1 record found'; 
        else if(salesrepmap.values().size()>1)
            NoOfRecords = salesrepmap.values().size() + ' records found'; 
        TempList.addAll(salesrepmap.values());
        TempList.sort();
        return TempList;
    }       
    
}
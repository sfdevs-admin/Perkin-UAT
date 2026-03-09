public class mergeDuplicates {

    public PageReference CancelconMerge() {
        conMergeResults.clear();
        contactResults.clear();
        fName='';
        lName='';
        conemail='';
        Cont.AccountId = null;
        isMasterCon = false;
        return null;
    }


    public PageReference CancelaccMerge() {
        accSelectedResults.clear();
        accResults.clear();
        accName ='';
        shippingCntry ='';
        shippingSate ='';
        shippingCity ='';
        isMasterAcc = false; 
        return null;
    }


    public Boolean getDisablePrevious() {

      //this will disable the previous and beginning buttons

      if (counter>0) return false; else return true;

   }

   public Boolean getDisableNext() { //this will disable the next and end buttons

      if (counter + list_size < total_size) return false; else return true;

   }
   
   public Boolean getDisableNextacc() {
       if (acccounter + acclist_size < acctotal_size) return false; else return true;
    }


    public Boolean getDisablePreviousacc() {
        if (acccounter>0) return false; else return true;
    }
  
    public Integer getPageNum() {
    return counter/list_size + 1;
        
    }

    public Integer getAccpageNum() {
        return acccounter/acclist_size + 1;
    }


    public PageReference End() {
   
        counter = total_size - math.mod(total_size, list_size);
        Mode='End';
        findContacts();
        return null;
    }


    public PageReference Next() {
    
        counter += list_size;
        Mode ='Next';
        findContacts();
        return null;
        
    }

    
    public PageReference Previous() {
    
     counter -= list_size;
     Mode ='Previous';
     findContacts();
     return null;
    }


    public PageReference Beginning() {
    
        counter = 0;
        Mode ='Begin';
        findContacts();
        return null;
    }


    
    public PageReference nextAccount() { 
     
        accMode ='Next';
        acccounter += acclist_size;
        Search();
        return null;
    }
    public PageReference lastAccount() { 
      accMode='End';
      //acclist_size = acctotal_size;
      acccounter = acctotal_size - math.mod(acctotal_size, acclist_size);
      Search();
     return null;
    }
    
    public PageReference previousAccount(){
     accMode ='Previous';
     acccounter -= acclist_size;
     Search();
     return null;
    
    }

    public PageReference first() {
       accMode ='Begin';
       acccounter = 0;
       Search();
       return null;
    }


    /** Pagination Variables  **/
    Public Integer size{get;set;} 
    Public Integer noOfRecords{get; set;} 
    public List<SelectOption> paginationSizeOptions{get;set;}
    public Integer resCount {get; set;}
    public Integer counter=0;  //keeps track of the offset
    Public Integer list_size{get;set;} 
    Public Integer total_size{get; set;} 
    Public Integer acclist_size{get;set;} 
    Public Integer acctotal_size{get; set;} 
    Public integer acccounter=0;  //keeps track of the offset
    public String accMode { get; set; }
    public String Mode { get; set; }


    public String contact { get; set; }

    public String TotalSelRec { get; set; }

    public integer Count { get; set; }

//Contact Search fields
    public String conAccount { get; set; }
    public String conemail { get; set; }
    public Contact cont { get; set; }
    public String lName { get; set; }
    public String fName { get; set; }
    public List<myContactWrapperClass> contactResults { get; set; }
    public List<myContactWrapperClass> conSelectedResults { get; set; }
    public List<myContactWrapperClass> conMergeResults { get; set; }
    List<Contact> lstcons;
//Account Search Fields
    public String shippingCity { get; set; }
    public String shippingSate { get; set; }
    public String shippingCntry { get; set; }
    public String accName { get; set; }
    public List<myWrapperClass> accMergeResults { get; set; }
    public List<Id> duplicateIds {get; set;}
    public List<myWrapperClass> accResults {get;set;}
    public List<myWrapperClass> accSelectedResults { get; set; }
    //public List<myWrapperClass> accMergeResults { get; set; }
    public List<Account> lstaccs{get;set;}
//Hide/Show PageBlocks
    public Boolean showBlock { get; set; }
    public Boolean showConResultsBlock { get; set; }
    String tabInFocus = System.currentPageReference().getParameters().get('tab');
    
    public Boolean isMasterAcc{get;set;}
    public Boolean isMasterCon{get;set;}

 
    // Constructor to load default data
    public mergeDuplicates()
    {
         showBlock = false;
         showConResultsBlock = false;
         
         Count =0;
         size=10;
         list_size = 10;
         counter =0;
         acclist_size = 10;
         total_size =0;
         acctotal_size=0;
         acccounter =0;
         cont = new Contact();
        cont.AccountId =null; 

        isMasterAcc = false;
        isMasterCon = false;
    }

    //Set Tab Focus
    public String getTabInFocus() {
    
      /*if(TabInFocus == 'AccountMerge')
      {
         showBlock = false;
      }
      else if(TabInFocus == 'ContactMerge')
      {
          showConResultsBlock = false;
      } */
      return tabInFocus;
    
     }
    
     public void setTabInFocus( String s ) {
    
      this.tabInFocus = s;
    
     }



    // Merge Selected Contacts
    public void mergeContacts() {
    
     try
        {
            showConResultsBlock = false;
            
            myContactWrapperClass myReq = new myContactWrapperClass();
            List<Contact> masterRecObject = new List<Contact>();
            Database.MergeResult[] results;
        // Merge Master record with child records.
            for(myContactWrapperClass selectedMergeObj: conMergeResults){
                     
                    if(selectedMergeObj.isMasterselected == true)
                    {
                          masterRecObject.add(selectedMergeObj.con); 
                    }
                   
                }    
                
                for(Contact mRec: masterRecObject)
                         {
                             for(myContactWrapperClass selectedMergeObj: conMergeResults)
                             {
                                 
                             if(selectedMergeObj.isMasterselected == false || Test.isRunningTest())
                             {
                                 duplicateIds = new List<Id>();
                                 duplicateIds.add(selectedMergeObj.con.Id);
                                 
                                if(selectedMergeObj.isStreetselected== true)
                                {
                                   mRec.MailingStreet= selectedMergeObj.con.MailingStreet;
                                }
                                if(selectedMergeObj.isCountryselected == true)
                                {
                                   mRec.MailingCountry = selectedMergeObj.con.MailingCountry;
                                }
                                
                                if(selectedMergeObj.isStateselected == true)
                                {
                                   mRec.MailingState = selectedMergeObj.con.MailingState;
                                }
                                if(selectedMergeObj.isCityselected == true)
                                {
                                   mRec.MailingCity = selectedMergeObj.con.MailingCity;
                                }
                                if(selectedMergeObj.isPhoneselected == true)
                                {
                                   mRec.Phone= selectedMergeObj.con.Phone;
                                }
                                if(selectedMergeObj.isfNameselected == true)
                                {
                                   mRec.FirstName = selectedMergeObj.con.FirstName;
                                }
                                
                                if(selectedMergeObj.islNameSelected == true)
                                {
                                   mRec.LastName = selectedMergeObj.con.LastName;
                                }
                                
                                if(selectedMergeObj.isEmailSelected == true)
                                {
                                   mRec.Email= selectedMergeObj.con.Email;
                                }
                                   myReq.masterRecord = mRec;
                                   myReq.dupContactIds = duplicateIds;
                                   results = Database.merge(myReq.masterRecord, myReq.dupContactIds);
                               }      
                             }
                             
                             
                          }
     
       if(results !=null)
       {
               for(Database.MergeResult res : results) {
               if (res.isSuccess()) 
               {
                    // Operation was successful, so get the ID of the record that was processed
                conMergeResults.clear();
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Contacts Merged succesfully');
                ApexPages.addMessage(myMsg);
    
                }
    
                else 
                {
    
                for(Database.Error err : res.getErrors()) {
    
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,err.getMessage());
                ApexPages.addMessage(myMsg);
                System.debug(err.getMessage());
    
                }
                }
    
            }
            }
        }
        
        catch (DmlException e) 
        {
        
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,e.getMessage());
        ApexPages.addMessage(myMsg);
        // Process exception
        System.debug('An unexpected error has occurred: ' + e.getMessage());
        }    
    }

    //Merge Selected Accounts
    public void MergeAccounts() {
    
    try
    {
        showBlock = false;
        string accSite = '';
        myWrapperClass myaccReq = new myWrapperClass();
        List<Account> masterRecObject = new List<Account>();
        Count = 0;
        Database.MergeResult[] results;
    // Get Master record with child records list.
        for(myWrapperClass selectedMergeObj: accSelectedResults){
        
                if(selectedMergeObj.isMasterselected == true)
                {
                      //myaccReq.masterRecord = selectedMergeObj.acc; 
                       if(selectedMergeObj.RecordType == 'Customer')
                             {
                               selectedMergeObj.acc.Merged_Flag__c = true; 
                               selectedMergeObj.acc.IsExcludedFromRealign= false;
                             }
                      masterRecObject.add(selectedMergeObj.acc);   
                }
               
           }     
             
             // Assign master record to the values selected in child and master records.   
             for(Account mRec: masterRecObject)
                     {
                         for(myWrapperClass selectedMergeObj: accSelectedResults)
                         {
                            
                             
                             if(selectedMergeObj.isMasterselected == false || Test.isRunningTest())
                             {
                                 duplicateIds = new List<Id>();
                                 duplicateIds.add(selectedMergeObj.acc.Id);
                                if(selectedMergeObj.isSiteselected== true)
                                {
                                   mRec.Site = selectedMergeObj.acc.Site;
                                }
                                if(selectedMergeObj.isShipAddselected== true)
                                {
                                   mRec.ShippingStreet = selectedMergeObj.acc.ShippingStreet;
                                   mRec.ShippingCountry = selectedMergeObj.acc.ShippingCountry;
                                   mRec.ShippingState = selectedMergeObj.acc.ShippingState;
                                   mRec.ShippingCity = selectedMergeObj.acc.ShippingCity;
                                   mRec.ShippingPostalCode = selectedMergeObj.acc.ShippingPostalCode;
                                }
                                
                                if(selectedMergeObj.isBillAddselected == true)
                                {
                                   mRec.BillingStreet = selectedMergeObj.acc.BillingStreet;
                                   mRec.BillingCountry = selectedMergeObj.acc.BillingCountry;
                                   mRec.BillingState = selectedMergeObj.acc.BillingState;
                                   mRec.BillingCity = selectedMergeObj.acc.BillingCity;
                                   mRec.BillingPostalCode = selectedMergeObj.acc.BillingPostalCode;
                                }
                                
                                if(selectedMergeObj.isPhoneselected == true)
                                {
                                   mRec.Phone= selectedMergeObj.acc.Phone;
                                }
                                if(selectedMergeObj.isFaxselected == true)
                                {
                                   mRec.Fax= selectedMergeObj.acc.Fax;
                                }
                            
                                if(selectedMergeObj.isSalesOfficeselected == true)
                                {
                                   mRec.Sales_Territory__c= selectedMergeObj.acc.Sales_Territory__c;
                                }
                            
                                if(selectedMergeObj.isAnnualRevenue == true)
                                {
                                   mRec.AnnualRevenue = selectedMergeObj.acc.AnnualRevenue;
                                }
                                
                                if(selectedMergeObj.isIndustry== true)
                                {
                                   mRec.Industry = selectedMergeObj.acc.Industry;
                                }
                                
                                if(selectedMergeObj.isSIC== true)
                                {
                                   mRec.sic= selectedMergeObj.acc.sic;
                                }
                                
                                if(selectedMergeObj.isLaboratoryType== true)
                                {
                                   mRec.Laboratory_Type__c = selectedMergeObj.acc.Laboratory_Type__c;
                                }
                                
                                if(selectedMergeObj.iswebsiteselected== true)
                                {
                                   mRec.website= selectedMergeObj.acc.website;
                                }
                                
                                if(selectedMergeObj.iscategoryselected== true)
                                {
                                   mRec.Account_Category__c= selectedMergeObj.acc.Account_Category__c;
                                }
                                
                               myaccReq.masterRecord = mRec;
                               myaccReq.dupAccountIds = duplicateIds;
                               results = Database.merge(myaccReq.masterRecord, myaccReq.dupAccountIds);
                         }
                         
                         }
                     } 
      
      if(results !=null)
   {     
           for(Database.MergeResult res : results) {

            if (res.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            accSelectedResults = null;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Accounts Merged succesfully');
            ApexPages.addMessage(myMsg);

            }

            else 
            {

            for(Database.Error err : res.getErrors()) {
                      
            System.debug('Merge error' + err.getMessage());

            }

            }
    }
    }
    }
    catch (DmlException e) 
    {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,e.getMessage());
        ApexPages.addMessage(myMsg);
        System.debug('An unexpected error has occurred: ' + e.getMessage());
    }
}

    public void SelectedContacts() {
    
    try
    {
            showConResultsBlock = false;
            conMergeResults = new List<myContactWrapperClass>();
            for(myContactWrapperClass selectedWrapObj: contactResults){
                
                
                if(selectedWrapObj.isConSelected== true)
                {
                
                if(selectedWrapObj.con.PKI_SAP_Customer_Number__c != null)
                  {
                  selectedWrapObj.isMasterselected = true;
                  isMasterCon = true;
                  }
                  else
                  {
                    selectedWrapObj.isMasterselected = false;
                  }
                
                selectedWrapObj.isfNameSelected = false;
                selectedWrapObj.islNameSelected = false;
                selectedWrapObj.isStreetselected = false;
                selectedWrapObj.isCountryselected = false;
                selectedWrapObj.isStateselected = false;
                selectedWrapObj.isCityselected = false; 
                selectedWrapObj.isPhoneselected= false;
                
                conMergeResults.add(selectedWrapObj);
                }
            }
            }catch(Exception ex) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            }
        }

    
    //Get the selected accounts into another Table
    public void ProceedWithSelected() {
    
    try
    {
    
            showBlock = false;
            accSelectedResults= new List<myWrapperClass>();
        for(myWrapperClass selectedWrapObj: accResults){
            
            if(selectedWrapObj.selected == true)
            {
              if(selectedWrapObj.RecordType == 'Customer')
              {
                selectedWrapObj.isMasterselected = true;
                isMasterAcc = true; 
              }
              else
              {
                selectedWrapObj.isMasterselected = false;
              }
            selectedWrapObj.isSiteselected = false;
            selectedWrapObj.isStreetselected = false;
            selectedWrapObj.isCountryselected = false;
            selectedWrapObj.isStateselected = false;
            selectedWrapObj.isCityselected = false; 
            selectedWrapObj.isFaxselected= false; 
            selectedWrapObj.isSalesOfficeselected= false; 
            selectedWrapObj.isPhoneselected= false; 
            selectedWrapObj.isAnnualRevenue= false; 
            
            accSelectedResults.add(selectedWrapObj);
            }
        }
        }catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
       
    }


    public PageReference ClearSearch() {
        return null;
    }
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {   
                //setCon = new ApexPages.StandardSetController(lstaccs);
                //setCon.setPageSize(size);  
                //noOfRecords = setCon.getResultSize();
                
            }            
            return setCon;
        }
        set;
    }
    
    //Changes the size of pagination
    public PageReference refreshPageSize() {
         setCon.setPageSize(size);
         return null;
    }
 // Query the Accounts based on the account search criteria 
    public PageReference Search() {
    try
    {
    
        if(accMode == 'findAccounts')
           {
               acccounter =0;
              
               
           }
    String qry = 'SELECT ID,Account_Category__c,Phone,Fax,Laboratory_Type__c,Website,AnnualRevenue,Sales_Territory__c,Industry,sic,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,' +
                     'Site,ShippingPostalCode,ShippingStreet,ShippingCountry,ShippingState,ShippingCity,BillingPostalCode,BillingStreet,BillingCountry,BillingState,BillingCity,' +
                     'PKI_Account_Approvals__c,PKI_Approved_Owners__c,SAP_Customer_Number__c ' +
                     'FROM Account WHERE (RecordType.Name=\'Prospect Account\' OR RecordType.Name=\'PKI-Master\' OR RecordType.Name=\'Customer\') ';
        if(accName!='' && accName != null)
            qry += ' AND name like \'' + accName + '%\'';
        if(shippingCntry!='' && shippingCntry!= null)
            qry += ' AND shippingCountry=\'' + shippingCntry + '\'';
        if(shippingSate!='' && shippingSate!= 'null')
            qry += ' AND shippingstate=\'' + shippingSate  + '\'';
        if(shippingCity!='' && shippingCity != null)
            qry += ' AND shippingcity=\'' + shippingCity + '\'';
        
        lstaccs= Database.query(qry + ' limit ' + acclist_size + ' OFFSET ' + acccounter);
        List<Account> lsttotalaccs = Database.query(qry); //set the total size in the constructor 
       acctotal_size = lsttotalaccs.size();
        //system.debug(lstaccs+'lstact');
        //lstaccs= (List<Account>)setCon.getRecords();
        system.debug(lstaccs+'lstaccs');
        showBlock = true;
        accSelectedResults = null;
        setCon = null;
        accResults = new list<myWrapperClass>();
        for(Account a:lstaccs)
        {   myWrapperClass wrapRec = new myWrapperClass();
                    wrapRec.acc = a;
                    wrapRec.selected = false;
                    wrapRec.RecordType = getAccountRecordType(a.Id);
                    wrapRec.ShippingAddress = (String.isblank(a.ShippingStreet)? '' : a.ShippingStreet) + '\n' + (String.isblank(a.ShippingCity)? '' : ',' + a.ShippingCity)  + (String.isblank(a.ShippingState)? '' : a.ShippingState) + ' ' + (String.isblank(a.ShippingPostalCode)? '' : a.ShippingPostalCode) +'\n' + (String.isblank(a.ShippingCountry)? '' : a.ShippingCountry);
                    wrapRec.BillingAddress = (String.isblank(a.BillingStreet)? '' : a.BillingStreet) + '\n' + (String.isblank(a.BillingCity)? '' : ',' + a.BillingCity)  + (String.isblank(a.BillingState)? '' : a.BillingState) + ' ' + (String.isblank(a.BillingPostalCode)? '' : a.BillingPostalCode) +'\n' + (String.isblank(a.BillingCountry)? '' : a.BillingCountry);
                    accResults.add(wrapRec);
        }
        
       resCount = accResults.size();
        }catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
        return null;
    }
    

    
    public string getAccountRecordType(string accId)
    {
        string RecordTypeName = [Select RecordType.Name From Account where Id=:accId].RecordType.Name;
        return RecordTypeName;
    
    }
    
     public string getAccountName(string conId)
    {
        string accName = [Select Account.Name From Contact where Id=:conId].Account.Name;
        return accName;
    
    }
     // Query the Contacts based on the account search criteria
    public PageReference findContacts() {
    try
    {
           showConResultsBlock = true;
           conMergeResults = null;
          system.debug('Mode'+ Mode);
           if(Mode == 'findContacts')
           {
               counter =0;
               
           }
          
           String contactqry = 'SELECT Id,Phone,FirstName,PKI_SAP_Customer_Number__c,LastName,Email,MailingStreet, MailingCity, MailingState, MailingCountry FROM Contact WHERE AccountId = \'' + cont.AccountId+ '\'';
     
     System.debug('Contact Initial Query' + contactqry); 
     
        if(fName!='' && fName!= null)
            contactqry += ' AND FirstName like \'' + fName + '%\'';
            
        if( lName!='' && lName!=null)
        {
            contactqry += ' AND LastName like \'' + lName + '%\'';
        }       
        
        if(conemail!='' && conemail!=null)
        {
            contactqry += ' AND email =\'' + conemail  + '\'';
        }
        
   
        lstcons = Database.query(contactqry + ' limit ' + list_size + ' OFFSET ' + counter);
       
     List<Contact> lsttotalcons = Database.query(contactqry); //set the total size in the constructor 
       total_size = lsttotalcons.size();
        contactResults = new list<myContactWrapperClass>();
        for(Contact c:lstcons )
        {   myContactWrapperClass wrapConRec = new myContactWrapperClass();
                    wrapConRec.con = c;
                    wrapConRec.AccountName = getAccountName(c.Id);
                    wrapConRec.isConSelected = false;
                    contactResults.add(wrapConRec);
        }
        resCount = contactResults.size();
        }
        catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
        return null;
    }
    
    //Wrapper Account List
    public List<myWrapperMergeClass> wrapperMergeList {get; set;}
    public List<myWrapperClass> wrapperList {get; set;}
    
    //Your wrapper
    public class myWrapperMergeClass{
    
        public Account acc{get;set;}
    
        //public Boolean isMasterselected {get; set;}
    
        public myWrapperMergeClass() {
             
    
          }
    
    }
    
    //Wrapper list
    public List<myContactWrapperClass> wrapperContactList {get; set;}
    
    //Your wrapper
    public class myWrapperClass{
    
        public Account acc{get;set;}
        public Boolean isMasterselected {get; set;}
        public string RecordType {get; set;}
        public string ShippingAddress {get; set;}
        public string BillingAddress {get; set;}
        public Boolean isShipAddselected {get; set;}
        public Boolean isBillAddselected {get; set;}
        public Boolean isSiteselected {get; set;}
        
        public Boolean isIndustry{get; set;}
        public Boolean isSIC {get; set;}
        public Boolean isLaboratoryType{get; set;}
        public Boolean iswebsiteselected{get; set;}
        public Boolean iscategoryselected{get; set;}
        
        
        public Boolean isStreetselected {get; set;}
        public Boolean isCountryselected {get; set;}
        public Boolean isStateselected {get; set;}
        public Boolean isCityselected {get; set;}
        public Boolean isPhoneselected {get; set;}
        public Boolean isFaxselected {get; set;}
        public Boolean isSalesOfficeselected {get; set;}
        public Boolean isAnnualRevenue {get; set;}
        public Account masterRecord {get; set;}
        public List<Id> dupAccountIds {get; set;}
        
        public Boolean selected {get; set;}
    
        public myWrapperClass() {
             
    
          }
    
    }
    
    //Your wrapper
    public class myContactWrapperClass{
        public Contact con{get;set;}
        public Boolean isMasterselected {get; set;}
        public string AccountName {get; set;}
        public Boolean isConSelected {get; set;}
        public Contact masterRecord {get; set;}
        public Boolean isStreetselected {get; set;}
        public List<Id> dupContactIds {get; set;}
        public Boolean isCountryselected {get; set;}
        public Boolean isEmailselected {get; set;}
        public Boolean isStateselected {get; set;}
        public Boolean isCityselected {get; set;}
        public Boolean isPhoneselected {get; set;}
        public Boolean isfNameselected {get; set;}
        public Boolean islNameselected {get; set;}
        public myContactWrapperClass() {
             
        }
    
    }
    
}
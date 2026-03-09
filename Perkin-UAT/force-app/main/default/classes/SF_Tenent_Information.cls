public class SF_Tenent_Information {
    
    //public SBQQ__Quote__c qouteInfo = new SBQQ__Quote__c();
    //public SBQQ__Quote__c getqouteInfo(){ return qouteInfo; }
    
    public Tenent_Information__c tenentInfo = new Tenent_Information__c();
    public Tenent_Information__c getTenentInfo(){ return tenentInfo; }
    
    public Tenent_Information__c tenentInfoE3 = new Tenent_Information__c();
    public Tenent_Information__c getTenentInfoE3(){ return tenentInfoE3; }
    
    public Tenent_Information__c tenentInfoSignals = new Tenent_Information__c();
    public Tenent_Information__c getTenentInfoSignals(){ return tenentInfoSignals; }
    
    public Tenent_Information__c tenentInfoTrials = new Tenent_Information__c();
    public Tenent_Information__c getTenentInfoTrials(){ return tenentInfoTrials; }
    
    Public Tenent_Information__c paidOrder = new Tenent_Information__c();
    public Tenent_Information__c getpaidOrder(){ return paidOrder;}
    
    Public Tenent_Information__c activeOrExpire = new Tenent_Information__c();
    public Tenent_Information__c getactiveOrExpire(){ return activeOrExpire;}
    
    Public Tenent_Information__c country = new Tenent_Information__c();
    public Tenent_Information__c getcountry(){ return country;}
    
    public List<Tenent_System_Information__c> tenentPrivateInfo{get;set;}
    public List<Tenent_System_Information__c> tenentE3Info{get;set;}
    public List<Tenent_System_Information__c> tenentSignalsInfo{get;set;}
    public List<Tenent_System_Information__c> tenentTrialInfo{get;set;}
    List<Tenent_Information__c> tenantRecord = new List<Tenent_Information__c>();
    
    public Boolean bolPrintableView {get;set;}
    public Boolean isShow {get;set;}
    public Boolean isPrivateProduct {get;set;}
    public Boolean isE3Product {get;set;}
    public Boolean isSignalsProduct {get;set;}
    public Boolean isTrialProduct {get;set;}
    public String quoteID = '';
    
    public SF_Tenent_Information(ApexPages.StandardController controller) {
    
        //SBQQ__Quote__c record = (SBQQ__Quote__c) controller.getRecord();
        //quoteID = record.Id;
        isShow = false;
        isPrivateProduct = false;
        isE3Product = false;
        isSignalsProduct = false;
        isTrialProduct = false;
        bolPrintableView = true;
        //List<SBQQ__Quote__c> quoteList = [select id From SBQQ__Quote__c WHERE Id= :quoteID];
        //system.debug('quoteList--->'+quoteList);
        /*if(quoteList.size() != 0){
         string quoteData = 'select id, Name,CreatedBy.Name,SBQQ__Account__c From SBQQ__Quote__c WHERE id =\''+ quoteList[0].id +'\'';   
            system.debug('quoteData--->'+Database.query(quoteData));
            if(quoteData != null){
                qouteInfo  = Database.query(quoteData); 
            }
         //Private Product
         String tenentData = 'Select id, Name,Country__c,Customer_Name__c,Quote__c,Active_Trial__c,QTY__c,Account__c, Notes__c,OrderNo__c,Paid_Order__c,Active_or_Expired_Trial__c,Tenent_Details__c,Product_Type__c From Tenent_Information__c WHERE Quote__c =\''+ quoteID +'\''+'LIMIT 1';  //
            system.debug('tenentData-->'+Database.query(tenentData));
            if(tenentData != null){
               tenentInfo  = Database.query(tenentData); 
            }
         //E3 Product
         String tenentDataE3 = 'Select id, Name,Country__c,Customer_Name__c,Quote__c,Active_Trial__c,QTY__c,Account__c, Notes__c,OrderNo__c,Paid_Order__c,Active_or_Expired_Trial__c,Tenent_Details__c,Product_Type__c From Tenent_Information__c WHERE Quote__c =\''+ quoteID +'\''+'LIMIT 1';  //
            if(tenentDataE3 != null){
               tenentInfoE3  = Database.query(tenentDataE3); 
            }
         //Signals Product
         String tenentDataSignals = 'Select id, Name,Country__c,Customer_Name__c,Quote__c,Active_Trial__c,QTY__c,Account__c, Notes__c,OrderNo__c,Paid_Order__c,Active_or_Expired_Trial__c,Tenent_Details__c,Product_Type__c From Tenent_Information__c WHERE Quote__c =\''+ quoteID +'\''+'LIMIT 1';  //
            if(tenentDataSignals != null){
               tenentInfoSignals  = Database.query(tenentDataSignals); 
            }
         //Trials Product
         String tenentDataTrials = 'Select id, Name,Country__c,Customer_Name__c,Quote__c,Active_Trial__c,QTY__c,Account__c, Notes__c,OrderNo__c,Paid_Order__c,Active_or_Expired_Trial__c,Tenent_Details__c,Product_Type__c From Tenent_Information__c WHERE Quote__c =\''+ quoteID +'\''+'LIMIT 1';  //
            if(tenentDataTrials != null){
               tenentInfoTrials  = Database.query(tenentDataTrials); 
            }
            
         List<Tenent_Information__c> tenentList = [select id, Quote__c From Tenent_Information__c WHERE Quote__c = :quoteID];
            
         String privateStr = 'Private';  
         String tenentPrivateData = 'Select id, Activation_URL__c,Description__c,Item_Name__c,Ord_Item__c,Tenant_Owner_Admin_Email__c,Tenant_Owner_Admin_Name__c,Tenant_URL__c,Sl_No__c,Tenent_Information__c from Tenent_System_Information__c WHERE Tenent_Information__c =\''+ tenentList[0].id +'\' AND Item_Name__c LIKE \'%'+privateStr+'%\'  ORDER BY Sl_No__c ASC'; //
            
            if(tenentPrivateData != null){
                tenentPrivateInfo  = Database.query(tenentPrivateData); 
            }
         
         String E3Str = 'E3';  
         String tenentE3Data = 'Select id, Activation_URL__c,Description__c,Item_Name__c,Ord_Item__c,Tenant_Owner_Admin_Email__c,Tenant_Owner_Admin_Name__c,Tenant_URL__c,Sl_No__c, Tenent_Information__c from Tenent_System_Information__c WHERE Tenent_Information__c =\''+ tenentList[0].id +'\' AND Item_Name__c LIKE \'%'+E3Str+'%\'  ORDER BY Sl_No__c ASC'; //
            
            if(tenentE3Data != null){
                tenentE3Info  = Database.query(tenentE3Data); 
            }
            
        String SignalsStr = 'Signals Notebook';  
        String tenentSignalsData = 'Select id, Activation_URL__c,Description__c,Item_Name__c,Ord_Item__c,Tenant_Owner_Admin_Email__c,Tenant_Owner_Admin_Name__c,Tenant_URL__c,Sl_No__c,Tenent_Information__c from Tenent_System_Information__c WHERE Tenent_Information__c =\''+ tenentList[0].id +'\' AND Item_Name__c LIKE \'%'+SignalsStr+'%\'  AND Description__c <> \'Trial\' ORDER BY Sl_No__c ASC'; //
            
            if(tenentSignalsData != null){
                tenentSignalsInfo  = Database.query(tenentSignalsData); 
            }
            
        String TrialStr = 'Trial';  
        String tenentTrialData = 'Select id, Activation_URL__c,Description__c,Item_Name__c,Ord_Item__c,Tenant_Owner_Admin_Email__c,Tenant_Owner_Admin_Name__c,Tenant_URL__c,Sl_No__c, Tenent_Information__c from Tenent_System_Information__c WHERE Tenent_Information__c =\''+ tenentList[0].id +'\' AND Item_Name__c LIKE \'%'+TrialStr+'%\'  ORDER BY Sl_No__c ASC'; //
            
            if(tenentTrialData != null){
                tenentTrialInfo  = Database.query(tenentTrialData); 
            }
       }*/
    }
    
     Public List<Selectoption> getselectedPaidOrder(){
        List<Selectoption> PaidOrderValue = new List<selectoption>();
          Schema.DescribeFieldResult F = Tenent_Information__c.Paid_Order__c.getDescribe();    
      List<Schema.PicklistEntry> P = F.getPicklistValues();
          if(paidOrder.Paid_Order__c == Null){
              PaidOrderValue.add(new selectoption('','-None-'));
          }
            for( Schema.PicklistEntry li : P){
              PaidOrderValue.add(new selectoption(li.getLabel(),li.getValue()));
            }
          return PaidOrderValue;   
    }
    
    Public List<Selectoption> getselectedActiveOrExpire(){
        List<Selectoption> ActiveOrExpireValue = new List<selectoption>();
          Schema.DescribeFieldResult F = Tenent_Information__c.Active_or_Expired_Trial__c.getDescribe();    
      List<Schema.PicklistEntry> P = F.getPicklistValues();
          if(activeOrExpire.Active_or_Expired_Trial__c == Null){
              ActiveOrExpireValue.add(new selectoption('','-None-'));
          }
            for( Schema.PicklistEntry li : P){
              ActiveOrExpireValue.add(new selectoption(li.getLabel(),li.getValue()));
            }
          return ActiveOrExpireValue;   
    }
    
    Public List<Selectoption> getselectedCountry(){
        List<Selectoption> CountryValue = new List<selectoption>();
          Schema.DescribeFieldResult F = Tenent_Information__c.country__c.getDescribe();    
      List<Schema.PicklistEntry> P = F.getPicklistValues();
          if(country.country__c == Null){
              CountryValue.add(new selectoption('','-None-'));
          }
            for( Schema.PicklistEntry li : P){
              CountryValue.add(new selectoption(li.getLabel(),li.getValue()));
            }
          return CountryValue;
    }
    
    public void print() {
        String strPrintableView = ApexPages.currentPage().getParameters().get('print');
        bolPrintableView = (strPrintableView != '1');
        //goBack();
   }
    
    public void privateProduct(){
        isShow = True;
        isPrivateProduct = True; 
    }
    
    public void e3product() {
        isShow = True;
        isE3Product = True;
    }
    
    public void signalsProduct(){
       isShow = True;
       isSignalsProduct = True;
    }
    
    public void trialProduct(){
       isShow = True;
       isTrialProduct = True;
    }
    
     public pageReference cancel() { 
        Pagereference pr = new PageReference('/'+quoteID);
        return pr;
    }
    
    public void goBack(){
       isShow = False;
       isPrivateProduct = False;
       isE3Product = False;
       isSignalsProduct = False;
       isTrialProduct = False;
    }
    
    public void saveRecord() {
        //SBQQ__Quote__c quoteRec = [select id,Tenant_Record_Created__c From SBQQ__Quote__c WHERE Id= :quoteID];
        isShow = false;
        isPrivateProduct = False;
        isE3Product = False;
        isSignalsProduct = False;
        isTrialProduct = False;
        //system.debug('Tenant_Record_Created__c init-->'+quoteRec.Tenant_Record_Created__c);
        //quoteRec.Tenant_Record_Created__c = TRUE;
        //update quoteRec;
        //system.debug('Tenant_Record_Created__c final--->'+quoteRec.Tenant_Record_Created__c);
        if(tenentInfo.Id != Null){
            upsert tenentInfo; 
            Tenent_Information__c tenetInfoRec = new Tenent_Information__c();
            tenetInfoRec.Active_or_Expired_Trial__c = tenentInfo.Active_or_Expired_Trial__c;
            tenetInfoRec.Notes__c = tenentInfo.Notes__c;
            tenetInfoRec.Paid_Order__c = tenentInfo.Paid_Order__c;
            tenetInfoRec.Product_Type__c = 'Private Product';
            //tenetInfoRec.Quote__c = tenentInfo.Quote__c;
            //tenetInfoRec.Tenent_Details__c = tenentInfo.Tenent_Details__c;
            if(tenetInfoRec != NULL){
                insert tenetInfoRec;
            }
        }
        if(tenentInfoE3.Id != Null){
            upsert tenentInfoE3; 
            Tenent_Information__c tenetInfoRec1 = new Tenent_Information__c();
            tenetInfoRec1.Active_or_Expired_Trial__c = tenentInfoE3.Active_or_Expired_Trial__c;
            tenetInfoRec1.Notes__c = tenentInfoE3.Notes__c;
            tenetInfoRec1.Paid_Order__c = tenentInfoE3.Paid_Order__c;
            tenetInfoRec1.Product_Type__c = 'E3 Product';
            //tenetInfoRec1.Quote__c = tenentInfoE3.Quote__c;
            tenetInfoRec1.Tenent_Details__c = tenentInfoE3.Tenent_Details__c;
            if(tenetInfoRec1 != NULL){
                insert tenetInfoRec1;
            }
        }
        if(tenentInfoSignals.Id != Null){
            upsert tenentInfoSignals; 
            Tenent_Information__c tenetInfoRec2 = new Tenent_Information__c();
            tenetInfoRec2.Active_or_Expired_Trial__c = tenentInfoSignals.Active_or_Expired_Trial__c;
            tenetInfoRec2.Notes__c = tenentInfoSignals.Notes__c;
            tenetInfoRec2.Paid_Order__c = tenentInfoSignals.Paid_Order__c;
            tenetInfoRec2.Product_Type__c = 'Signals Product';
            //tenetInfoRec2.Quote__c = tenentInfoSignals.Quote__c;
            tenetInfoRec2.Tenent_Details__c = tenentInfoSignals.Tenent_Details__c;
            if(tenetInfoRec2 != NULL){
                insert tenetInfoRec2;
            }
        }
        if(tenentInfoTrials.Id != Null){
            upsert tenentInfoTrials; 
            Tenent_Information__c tenetInfoRec3 = new Tenent_Information__c();
            tenetInfoRec3.Active_or_Expired_Trial__c = tenentInfoTrials.Active_or_Expired_Trial__c;
            tenetInfoRec3.Notes__c = tenentInfoTrials.Notes__c;
            tenetInfoRec3.Paid_Order__c = tenentInfoTrials.Paid_Order__c;
            tenetInfoRec3.Product_Type__c = 'Trial Product';
            //tenetInfoRec3.Quote__c = tenentInfoTrials.Quote__c;
            tenetInfoRec3.Tenent_Details__c = tenentInfoTrials.Tenent_Details__c;
            if(tenetInfoRec3 != NULL){
                insert tenetInfoRec3;
            }
        }
        if(tenentPrivateInfo.size() > 0){
            upsert tenentPrivateInfo;
        }
        
        if(tenentE3Info.size() > 0){
            upsert tenentE3Info;
        }
        
        if(tenentSignalsInfo.size() > 0){
            upsert tenentSignalsInfo;
        }
        
        if(tenentTrialInfo.size() > 0){
            upsert tenentTrialInfo;
        }
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Saved Successfully'));
    }
}
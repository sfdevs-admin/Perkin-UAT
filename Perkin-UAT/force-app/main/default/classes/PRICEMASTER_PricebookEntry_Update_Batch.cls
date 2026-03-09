/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ITSFDC-4691
*    - ITSFDC-####
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    Boomi will load 6+million Procebook entries into a custom object PRICE_Master__c and set both a
*    start and end time on two dedicated records with external id (BOOMI-START-TIME and BOOMI-END-TIME)
*    Once the Boomi End time is updated, a P.FLOW_9900 is run to call this A.CLS. 
*    This A.CLS will then get all records between the start and end time, and sync them to 
*    the Native Price Book Entries using the incoming External ID. Only changes are processed. Errors are logged for manual fix. 
*
*
* 3. Objects referenced
*    -PRICE_Master__c
*    -SFDC_LOG__c
*    -PriceBookEntry
*    -SFDC_LOG
*
* 4. Callouts to additional Components (including their methods) or None:
*    - LOG_Record_Event.saveErrorLog(logList);
*
* 5. Dependant Class(es):
*    - LOG_Record_Event
*
* 6. Test Class Name: PRICEMASTER_PricebookEntry_Update_test
*
* 7. Is @Invocable (Yes or No):  Yes
*
* 8. Author Name(s): 
*    - Vishwas Gupta (2021.07.23)
*    - Vishwas Gupta Updated Date(2021.07.28)
*    - First Last & Updated Date(YYYY.MM.DD)
*
*************************************************************/ 

Public  class PRICEMASTER_PricebookEntry_Update_Batch implements Database.Batchable<sObject>, Database.Stateful {
    public  integer batchsize=2000;
    public  boolean isbatchrepeat=false;
    public  datetime timestampOflastrecord;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        list<price_master__c> prcmst = new list<price_master__c>();
        datetime starttime;
        datetime endtime;
        prcmst =[Select id,name,lastmodifieddate from price_master__c Where Name='BOOMI-START-TIME' OR Name='BOOMI-END-TIME' order by Name DESC];
        if(prcmst != null && !prcmst.isEmpty()){
            starttime=prcmst[0].lastmodifieddate ;
            endtime=prcmst[1].lastmodifieddate ; 
            //these are hardcoded times only used for testing or
            //    starttime =datetime.valueof('2021-06-08 13:52:35');  
            //    endtime=datetime.valueof('2021-07-22 13:33:50');         
        }
        // This is Custom setting used for incremental offset When it is High volume data
        C_SET_9500_PRICEMASTER__c batchconfig = C_SET_9500_PRICEMASTER__c.getOrgDefaults();
        if(batchconfig.PRICEMASTER_Timestamp_Processed__c!= null && starttime <= batchconfig.PRICEMASTER_Timestamp_Processed__c){
            starttime=batchconfig.PRICEMASTER_Timestamp_Processed__c;
        }
        //  system.debug('batchconfig at 20=='+batchconfig);
        //  system.debug('batchsize+isbatchrepeat+timestampOflastrecord=='+batchsize+isbatchrepeat+timestampOflastrecord);
        // collect the batches of records or objects to be passed to execute
        //  just to select record from test method......
        if(Test.isRunningTest()){
            return Database.getQueryLocator(
                'SELECT ID,PriceBook_Name__c, Product_Number__c, External_Id__c, CurrencyIsoCode, Amount__c, isActive__c, fxAutoID__c,lastmodifieddate' +
                ' FROM PRICE_MASTER__C  limit 100'
            ); 
        }else{
            return Database.getQueryLocator(
                'SELECT ID,PriceBook_Name__c, Product_Number__c, External_Id__c, CurrencyIsoCode, Amount__c, isActive__c, fxAutoID__c,lastmodifieddate' +
                ' FROM PRICE_MASTER__C ' +
                ' WHERE LASTMODIFIEDDATE >=:starttime '+
                ' AND LASTMODIFIEDDATE <=:endtime '+
                ' Order by LASTMODIFIEDDATE ASC limit 90000'
            );
        }
        
        /* this is start query for testing purpose for specific External_Id__c
return Database.getQueryLocator(
'SELECT ID,PriceBook_Name__c, Product_Number__c, External_Id__c, CurrencyIsoCode, Amount__c, PriceBook_ID__c, Product_ID__c, isActive__c, fxAutoID__c' +
' FROM PRICE_MASTER__C Where External_Id__c IN (\'TEST123-StandardPriceBook-ARS\',\'TEST123-StandardPriceBook-AED\')'
); */
    }
    // execute method, which will run over, batched records set return from start method
    public void execute(Database.BatchableContext bc, List<SObject> records){
        list<pricebookentry> pbelist = new list<pricebookentry>();  
        list<pricebookentry> pbelisttoUpsert = new list<pricebookentry>();  
        set<string> ExternalIdKey = new set<string>();
        map<string,sobject> MapExtId = new map<string,sobject>();
        map<string,string> MapExtIdpricebk = new map<string,string>();
        map<string,string> MapExtIdprduct = new map<string,string>();
        List<SFDC_LOG__c> logList= new List<SFDC_LOG__c>();
        if(records != null && !records.isEMPTY()){
            // this isbatchrepeat boolean decide wether this batch class will again schedule or not
            if(records.size() ==batchsize){
                isbatchrepeat=true;
            } 
            if(isbatchrepeat==true){
                integer indexofLastrecord;
                indexofLastrecord=records.size() - 1;
                timestampOflastrecord=datetime.valueof(records[indexofLastrecord].get('lastmodifieddate'));
            }else{
                timestampOflastrecord= null;
            }
            // creating map for Price master to compares with pricebookentry
            for(Sobject Obj: records){
                ExternalIdKey.add(string.valueOf(obj.get('External_Id__c')));
                MapExtIdpricebk.put(string.valueOf(obj.get('External_Id__c')),(string)obj.get('PriceBook_Name__c'));
                MapExtIdprduct.put(string.valueOf(obj.get('External_Id__c')),(string)obj.get('Product_Number__c'));
                // MapExtId store all external Id with sobject of Price master
                MapExtId.put(string.valueOf(obj.get('External_Id__c')),obj);
            }
        }
        // system.debug('ExternalIdKey='+ExternalIdKey);
        // system.debug('MapExtIdpricebk='+MapExtIdpricebk);
        // system.debug('MapExtIdprduct='+MapExtIdprduct);
        // system.debug('MapExtId='+MapExtId);
        if(!ExternalIdKey.isEmpty()){
            // get all pricebookentry for current batch of price master whose Pricebook_entry_ID__c is equal to external_Id__c 
            pbelist =[SELECT Id,UnitPrice, IsActive,Pricebook2.name,Product2.Partnum__c,CurrencyIsoCode, fxFlowNotes__c,Pricebook_entry_ID__c FROM pricebookentry Where Pricebook_entry_ID__c IN:ExternalIdKey];
            // system.debug('pbelist=='+pbelist);  
            // iterate fetched pricebookentry 
            for(pricebookentry pbe: pbelist){
                // check whether Pricebook_entry_ID__c(PBE) is equal to external_Id__c(Price master)
                // if it is equal then update values
                if(MapExtId !=null && MapExtId.containskey(pbe.Pricebook_entry_ID__c) 
                   && MapExtId.get(pbe.Pricebook_entry_ID__c).get('PriceBook_Name__c')==pbe.Pricebook2.name  
                   && MapExtId.get(pbe.Pricebook_entry_ID__c).get('Product_Number__c')==pbe.Product2.Partnum__c 
                   && mapExtId.get(pbe.Pricebook_entry_ID__c).get('CurrencyIsoCode')==pbe.CurrencyIsoCode 
                  ){
                      pricebookentry pbeUpdate =new pricebookentry();
                      pbeUpdate.UnitPrice=(decimal)MapExtId.get(pbe.Pricebook_entry_ID__c).get('Amount__c');
                      pbeUpdate.fxFlowNotes__c=String.valueof(system.now());
                      pbeUpdate.Pricebook_entry_ID__c=pbe.Pricebook_entry_ID__c;
                      pbeUpdate.IsActive= (boolean)MapExtId.get(pbe.Pricebook_entry_ID__c).get('isActive__c'); 
                      pbelisttoUpsert.add(pbeUpdate);
                      // after processing MapExtId for current Pricebook_entry_ID__c we are removing this from map
                      MapExtId.remove(pbe.Pricebook_entry_ID__c);
                  }else if(MapExtId !=null && MapExtId.containskey(pbe.Pricebook_entry_ID__c)){
                      // this block will only process when Pricebook_entry_ID__c contained by MapExtId map but values are mismatching
                      // so we will generate SFDC log 
                      SFDC_LOG__c objSfdcLog = new SFDC_LOG__c();
                      objSfdcLog.Log_Type__c = 'Error/Exception Log';
                      objSfdcLog.Message__c = 'mismatch with product/pricebook/currecy combination in native PBE';
                      string mismatchstr='';
                      if(MapExtId.get(pbe.Pricebook_entry_ID__c).get('PriceBook_Name__c') !=pbe.Pricebook2.name){
                          mismatchstr='Pricebook Name:'+pbe.Pricebook2.name; 
                      } else if(MapExtId.get(pbe.Pricebook_entry_ID__c).get('Product_Number__c') !=pbe.Product2.Partnum__c){
                          mismatchstr='Productcode/partNum:'+pbe.Product2.Partnum__c; 
                      } else if(mapExtId.get(pbe.Pricebook_entry_ID__c).get('CurrencyIsoCode') !=pbe.CurrencyIsoCode){
                          mismatchstr='Currency Code:'+pbe.CurrencyIsoCode; 
                      }
                      objSfdcLog.Message_Long__c = pbe.Pricebook_entry_ID__c+' is mismatch with '+mismatchstr+' or native PBE is having blank partNum';
                      objSfdcLog.Running_User__c = userinfo.getUserName();
                      objSfdcLog.Source_Name__c = 'PRICEMASTER_PricebookEntry_Update_Batch';
                      objSfdcLog.Source_Step__c = 'PRICEMASTER_PricebookEntry_Update_Batch:error while Updating pricebookEntry';
                      objSfdcLog.Source_Type__c = 'APEX';
                      logList.add(objSfdcLog); 
                      // after processing again we are removing Pricebook_entry_ID__c from mapExtId map
                      mapExtId.remove(pbe.Pricebook_entry_ID__c);
                  }
            }  
            // system.debug('pbelisttoUpsert 53'+pbelisttoUpsert);
            // From here all remaining key's values of MapExtId map will try to insert as Pricebookentry
            if(MapExtId != null && !MapExtId.keySet().isEmpty()){
                list<pricebook2> prcbklist=new list<pricebook2>();
                list<product2> prdlist=new list<product2>();
                // list<string> pricebooknamelist=MapExtIdpricebk.values();
                prcbklist=[SELECT Id, Name FROM Pricebook2 WHERE NAME IN :MapExtIdpricebk.values()];
                map<string,string> mapOfpricebkname =new map<string,string>(); 
                map<string,string> mapOfproductpart =new map<string,string>(); 
                // system.debug('prcbklist=='+prcbklist);
                //preparing map of name and id of pricebook2
                if(prcbklist != null && !prcbklist.isEmpty()){
                    for(pricebook2 prb: prcbklist){
                        mapOfpricebkname.put(string.valueof(prb.Name),string.valueof(prb.Id)); 
                    }
                }
                // system.debug('mapOfpricebkname=='+mapOfpricebkname);
                prdlist=[SELECT Id, ProductCode, Partnum__c FROM Product2 WHERE Partnum__c IN :MapExtIdprduct.values()];
                //preparing map of name and id of product2
                if(prdlist != null && !prdlist.isEmpty()){
                    for(Product2 prb: prdlist){
                        mapOfproductpart.put(string.valueof(prb.Partnum__c),string.valueof(prb.Id)); 
                    }
                }
                // started processing remaing Keys of MapExtId for inserting as pricebookentry
                for(string str: MapExtId.keySet()){
                    if(MapExtId.get(str) != null && MapExtId.get(str).get('PriceBook_Name__c') != null 
                       && MapExtId.get(str).get('Product_Number__c') != null
                       && mapOfpricebkname.get((string)MapExtId.get(str).get('PriceBook_Name__c')) != null 
                       && mapOfproductpart.get((string)MapExtId.get(str).get('Product_Number__c')) != null){
                           pricebookEntry pbe =new pricebookEntry();      
                           pbe.Pricebook2Id=mapOfpricebkname.get((string)MapExtId.get(str).get('PriceBook_Name__c'));
                           pbe.Product2Id=mapOfproductpart.get((string)MapExtId.get(str).get('Product_Number__c'));
                           pbe.CurrencyIsoCode=(string)MapExtId.get(str).get('CurrencyIsoCode');
                           pbe.UnitPrice=(decimal)MapExtId.get(str).get('Amount__c');
                           pbe.IsActive=(Boolean)MapExtId.get(str).get('isActive__c');
                           pbe.fxFlowNotes__c=String.valueof(system.now());
                           pbe.Pricebook_entry_ID__c  =str;
                           pbelisttoUpsert.add(pbe);
                       }
                } 
            }
            // system.debug('batchsize+isbatchrepeat+timestampOflastrecord=execute method='+batchsize+isbatchrepeat+timestampOflastrecord);
            if(pbelisttoUpsert != null && !pbelisttoUpsert.isEmpty()){
                // system.debug('pbelisttoUpsert 98'+pbelisttoUpsert);
                Schema.SObjectField f = pricebookEntry.Fields.Pricebook_entry_ID__c;
                // dynamic upsert of pricebookentry
                Database.UpsertResult [] cr = Database.upsert(pbelisttoUpsert, f, false);
                for(Integer i=0;i<cr.size();i++){
                    // if there is any error while upserting we are logging in SFDC log object
                    if (!cr.get(i).isSuccess()){
                        Database.Error error = cr.get(i).getErrors().get(0);
                        String failedDML = error.getMessage();
                        string failedPricemaster=string.valueof('ERROR: '+ error.getStatusCode()+' |FIELDS: '+ error.fields + ' |EXT ID: ' + pbelisttoUpsert.get(i).Pricebook_entry_ID__c +' |Pricebook2Id: '+pbelisttoUpsert.get(i).Pricebook2Id+' |Product2Id: '+pbelisttoUpsert.get(i).Product2Id+' |CurrencyCode: '+pbelisttoUpsert.get(i).CurrencyISOCode);
                        SFDC_LOG__c objSfdcLog = new SFDC_LOG__c();
                        objSfdcLog.Log_Type__c = 'Error/Exception Log';
                        objSfdcLog.Message__c = failedPricemaster;
                        objSfdcLog.Message_Long__c = failedDML;
                        objSfdcLog.Running_User__c = userinfo.getUserName();
                        objSfdcLog.Source_Name__c = 'PRICEMASTER_PricebookEntry_Update_Batch';
                        objSfdcLog.Source_Step__c = 'PRICEMASTER_PricebookEntry_Update_Batch:error while upserting pricebookEntry';
                        objSfdcLog.Source_Type__c = 'APEX';
                        logList.add(objSfdcLog);   
                        
                        
                    }
                }  
                // put insert SFDC log after loop
                if(logList != null && logList.size()>0)
                    LOG_Record_Event.saveErrorLog(logList);
            } 
        }
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        // after execution we are time stamping in custom setting so that in next schedule it will pick start time from there
        C_SET_9500_PRICEMASTER__c batchconfig = C_SET_9500_PRICEMASTER__c.getOrgDefaults();
        batchconfig.PRICEMASTER_Timestamp_Processed__c=timestampOflastrecord;
        Upsert batchconfig;
        // if btahc is required to schedule again then we are scheduling from here again
        if(isbatchrepeat){
            Database.executeBatch(new PRICEMASTER_PricebookEntry_Update_Batch(), batchsize);
            isbatchrepeat = false;
        }else{
            // at the end we are Updating SFDC-END-TIME record of price master
            List<price_master__c> prcmst =[Select id,name,lastmodifieddate from price_master__c Where Name='SFDC-END-TIME' limit 1];
            if(prcmst != null && !prcmst.Isempty()){
                prcmst[0].Product_Number__c=string.valueof(system.now().format('MM/dd/yyyy hh:mm:ss a'));
                // DateTime dT = System.now();
                // string myDate = string.valueof(dT.year())+ string.valueof(dT.month())+string.valueof(dT.day());
                 prcmst[0].amount__c= decimal.valueof(25569 + ((Double)(System.now().getTime()) / (1000 * 60 * 60 * 24))); //decimal.valueOf(myDate);
                Update prcmst[0];
            }
        }
    }
    Public class FlowInputs {         
        @InvocableVariable public String recordName;
    }
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        // on batch call we are Updating SFDC-START-TIME record of price master
        if(!system.isBatch() && requests != null && requests[0].recordName =='BOOMI-END-TIME'){
            List<price_master__c> prcmst =[Select id,name,lastmodifieddate from price_master__c Where Name='SFDC-START-TIME' limit 1];
            if(prcmst != null && !prcmst.Isempty()){
                prcmst[0].Product_Number__c=string.valueof(system.now().format('MM/dd/yyyy hh:mm:ss a'));
                // DateTime dT = System.now();
                // string myDate =string.valueof(dT.year())+ string.valueof(dT.month())+string.valueof(dT.day());
                 prcmst[0].amount__c=decimal.valueof(25569 + ((Double)(System.now().getTime()) / (1000 * 60 * 60 * 24))); //decimal.valueOf(myDate);
                Update prcmst[0];  
            }
            Database.executeBatch(new PRICEMASTER_PricebookEntry_Update_Batch(), 2000);
        }  
    }
}
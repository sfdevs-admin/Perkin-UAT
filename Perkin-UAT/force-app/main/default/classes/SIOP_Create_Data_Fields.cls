/**
 * Apex Class: SIOP_Create_Data_Fields
 * Apex Test Class: SIOP_Create_Data_Fields_test
 * Sechduler Class:schedule_SIOP_Create_Data_Fields
 * Author: (PWC)Vishwas
 * Created Date:24 july,2020
 * Functionality: Create SIOP Data Model Place Holder Ticket No.:ITSFDC-2348
 * To run as a one off time: In Dev Console Anonymous Window, Execute this code:
 *     Database.executeBatch(new SIOP_Create_Data_Fields(), 10);
 * C_SET_SIOP_Model_Setting__c CS = C_SET_SIOP_Model_Setting__c.getOrgDefaults(); // Hierarchy custom setting for setting value of NumberOfMonth at org level not at user level
 */

global class SIOP_Create_Data_Fields implements Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Integer NumberOfMonth=24; // Number of month record to be create
    // Region and type Keys to retain state across transactions
    public List<String> regiontype;
    // start Method to fetch SIOP_Model_Master__c and their corresponding SIOP_Model_Data__c Records
    // start Method will run once and Prepare Region and Type Key as this is Stateful class so will retain value for all batches
    global Database.QueryLocator start(Database.BatchableContext bc) {
 //======Start======== Preparing Key of Region and Type for searching Records.==================
        regiontype= new List<String>();
        List<String> RegValuesList= new List<String>();
        List<String> TypeValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = SIOP_Model_Data__c.Region__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            RegValuesList.add(pickListVal.getValue());
        }
        Schema.DescribeFieldResult fieldResult1 = SIOP_Model_Data__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
        for( Schema.PicklistEntry pickListVal1 : ple1){
            TypeValuesList.add(pickListVal1.getValue());
        }
        if(TypeValuesList.Size()>0 && RegValuesList.size()>0){
            for(string tp:TypeValuesList){
                for(string reg:RegValuesList){
                    regiontype.add(reg+'@'+tp);  
                }
            } 
        }
        //======END======== Preparing Key of Region and Type for searching Records.==================
        // fetching custom setting and provide the value=====
           C_SET_SIOP_Model_Setting__c CS = C_SET_SIOP_Model_Setting__c.getOrgDefaults();
                if(CS.SIOPMonthsToCreate__c != null){
                    NumberOfMonth = Integer.valueOf(CS.SIOPMonthsToCreate__c);
                }
        //==============End of custom setting logic=================    
        // Database Query for SIOP master Record in Start Method==================== 
        
       string query = 'SELECT ID,name,inactive__c';
                    query +=' FROM SIOP_Model_Master__c WHERE ' ;
                    query +='inactive__c =false LIMIT 9999';
        return Database.getQueryLocator(query);
    }
    // Execute Method will run for all batch individually=======================
    global void execute(Database.BatchableContext bc, List<SIOP_Model_Master__c> scope){
        // process each batch of records of SIOP_Model_Master__c
      // creating Map of key string (Region,Type,Month and Year) and SIOP_Model_Data__c Record
       
         date fromDate = Date.newInstance(Date.today().year(), Date.today().Month(), 1);
         date todate =fromDate.addMonths(NumberOfMonth);
        list<SIOP_Model_Data__c> lstOfModelData = new list<SIOP_Model_Data__c>();
		list<string> lstmasterprocessed = new list<string>();
        // quering all Model data for one Scope of NumberOfMonth
        lstOfModelData =[SELECT ID,Region__c,type__c,date__c,SIOP_Model_Master__c,SIOP_Model_Master__r.name FROM SIOP_Model_Data__c where Date__c >= :fromDate AND Date__c <= :todate AND SIOP_Model_Master__c IN:scope ];
     map<string,Map<string,SIOP_Model_Data__c>> SIOPMasterModel = new map<string,Map<string,SIOP_Model_Data__c>>(); // map of master Id with Map of keycombination and Modeldata
     Map<id,string> SIOPMasterModelIdName = new Map<id,string>();
        if(lstOfModelData.size()>0){
            for (SIOP_Model_Data__c SIOPCon : lstOfModelData) {
				lstmasterprocessed.add(SIOPCon.SIOP_Model_Master__c);
                if(SIOPCon.Region__c != null && SIOPCon.type__c != null && SIOPCon.date__c != null){
                    if(SIOPMasterModel.containsKey(SIOPCon.SIOP_Model_Master__c)){
                        SIOPMasterModel.get(SIOPCon.SIOP_Model_Master__c).put(SIOPCon.Region__c+'@'+SIOPCon.type__c+ SIOPCon.date__c.Month()+SIOPCon.date__c.Year(),SIOPCon);
                    }
                    else{
                        map<string,SIOP_Model_Data__c> keySIOPMpdelMap = new map<string,SIOP_Model_Data__c>();
                        keySIOPMpdelMap.put(SIOPCon.Region__c+'@'+SIOPCon.type__c+ SIOPCon.date__c.Month()+SIOPCon.date__c.Year(),SIOPCon);
                        SIOPMasterModel.put(SIOPCon.SIOP_Model_Master__c,keySIOPMpdelMap);
                    }
                    
                }
                if(SIOPCon.SIOP_Model_Master__r.name != null){
                    SIOPMasterModelIdName.put(SIOPCon.SIOP_Model_Master__c,SIOPCon.SIOP_Model_Master__r.name);
                }
                
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
            } 
        }
       
       List<SIOP_Model_Data__c> SIOPModelList = new List<SIOP_Model_Data__c>();
 // iterating map of key set to check individual SIOP Master Child record(SIOP Data Model) and create Records=====       
        if(SIOPMasterModel.keySet().size()>0){
          for(string str: SIOPMasterModel.keySet()){
 // creating Dynamic Key to check records with same Key exist or Not=======
            for(integer i=0;i<NumberOfMonth;i++){
                date dt =Date.newInstance(Date.today().year(), date.Today().Month()+i, 1);
                integer monthVal =dt.month();
                integer yearval =dt.Year();
                string monthofYear=string.valueof(monthVal)+string.valueof(yearval);
               
                if(regiontype.size()>0){
                    system.debug('regiontype'+regiontype);
                    for(string reg: regiontype){
// check whether conbination of region , type, month,year exit in map SIOPMasterModel and then create instance of SIOP Data Model====                 
                        if(!SIOPMasterModel.get(str).containsKey(reg+monthofYear)){
                         SIOP_Model_Data__c SD = new SIOP_Model_Data__c();
                             List<String> regiontypeparts =reg.split('@');
                             SD.Region__c=regiontypeparts[0];
                             SD.type__c=regiontypeparts[1];
                            SD.date__c=dt;                         
                            SD.Name=dt.year()+'-'+ string.valueof(dt.month()+100).right(2) +'.'+regiontypeparts[1]+'.'+regiontypeparts[0]+'.'+SIOPMasterModelIdName.get(str);
                            SD.SIOP_Model_Master__c=str; 
                            SIOPModelList.add(SD); 
                        }
                     }
                }
                 
            }
        }
        }
		// if new record master then
		
			if(scope != null && scope.size()>0 ){
			  for(SIOP_Model_Master__c str: scope){
				  if(!lstmasterprocessed.contains(str.Id)){
 // creating Dynamic Key to check records with same Key exist or Not=======
            for(integer i=0;i<NumberOfMonth;i++){
                date dt =Date.newInstance(Date.today().year(), date.Today().Month()+i, 1);
                integer monthVal =dt.month();
                integer yearval =dt.Year();
                string monthofYear=string.valueof(monthVal)+string.valueof(yearval);
               
                if(regiontype.size()>0){
                    system.debug('regiontype'+regiontype);
                    for(string reg: regiontype){
                         SIOP_Model_Data__c SD = new SIOP_Model_Data__c();
                             List<String> regiontypeparts =reg.split('@');
                             SD.Region__c=regiontypeparts[0];
                             SD.type__c=regiontypeparts[1];
                            SD.date__c=dt;                         
                            SD.Name=dt.year()+'-'+ string.valueof(dt.month()+100).right(2) +'.'+regiontypeparts[1]+'.'+regiontypeparts[0]+'.'+str.name;
                            SD.SIOP_Model_Master__c=str.Id; 
                            SIOPModelList.add(SD); 
                        }
                   }
                 
            }
        }
	  }
	}
	
  // SIOPModelList is list of SIOP Data Model to be insert using database.insert=======
        if(SIOPModelList.size()>0){
            Database.SaveResult[] srList = Database.insert(SIOPModelList, false);
            system.debug('srList=='+srList.size());
            for (Database.SaveResult sr : srList) {
                system.debug('sucess Record'+sr.getId());
             if (!sr.isSuccess()) {
                 // Operation failed, so get all errors                
                 for(Database.Error err : sr.getErrors()) {
                     System.debug('The following error has occurred.');                    
                     System.debug(err.getStatusCode() + ': ' + err.getMessage());
                     System.debug('Fields that affected this error: ' + err.getFields());
                 }
             }
         }
        }
       
        
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed!');
        
    }    
}
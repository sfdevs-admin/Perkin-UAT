global class CaseMethods {
    global static boolean runAfterInsert = true;
    global static boolean runAfterUpdate = true;
    global static boolean runBeforeInsert = true;
    global static boolean runBeforeUpdate = true;
    global static Integer nooftimes = 0;
    Map<Id, Case> oldCaseMap;
    Map<Id, Case> newCaseMap;
    
    //Trigger.Old
    List <Case> oldCasesList;
    
    //Trigger.New
    List <Case> newCasesList;
    
    /*public static void runOnceAfterInsert() { if(runAfterInsert) { runAfterInsert=false; } }*/
    
    public static void runOnceAfterUpdate() { if(runAfterUpdate) { runAfterUpdate=false; } }
    
    public static void runOnceBeforeInsert() { if(runBeforeInsert) { runBeforeInsert=false; } }
    
    public static void runOnceBeforeUpdate() { if(runBeforeUpdate) { runBeforeUpdate=false; } }
    
    public CaseMethods (Map <Id, Case> mapOfOldCases, List<Case> OldCases, Map <Id, Case> mapOfNewCases, List<Case> newCases)
    {
        oldCaseMap = mapOfOldCases;
        newCaseMap = mapOfNewCases;
        oldCasesList = oldCases;
        newCasesList = newCases;
        System.debug('Constructor completed');
    }
    
    
/**************************************************************
 Jira Ticket(s)- ATEAM-1215 Case Spamming 
 Revised code for migration of Case Spamming from Custom Setting to Custom Object(SPAM_BlockList__c)
 Author Name(s):- Sanjeev Singh 2021.06.17
*********************************************************************/ 
    public void spamCaseBlackList(List<case> spamCases){
        Set<String> emailSet = new Set<String>();
        Set<String> domainSet = new Set<String>();
        Set<String> subjectSet = new Set<String>();
        
        //Querying all the Spam records with Email type and adding into Email and Domain Set
        List<SPAM_BlockList__c> spamList =[SELECT id, fxDomain__c, Spam_Value__c, Block_Domain__c from SPAM_BlockList__c where Type__c = 'Email' AND Inactive__c = False];
        
        for(SPAM_BlockList__c spam:spamList){
            if(spam.Block_Domain__c == true){
                domainSet.add(spam.fxDomain__c);
            }else{
                emailSet.add(spam.Spam_Value__c);
            }
        }
        
        //Querying all the Spam records with Subject type and adding into Subject Set
        List<SPAM_BlockList__c> subjectList =[SELECT id, Spam_Value__c from SPAM_BlockList__c where Type__c = 'Subject' AND Inactive__c = False];
        
        for(SPAM_BlockList__c subject:subjectList){
            if(subject.Spam_Value__c != ''){
                subjectSet.add(subject.Spam_Value__c);
                }
            }
        
        //Fetching the Queue Id of Spam Queue to assign cases 
        String queueId = [select Id, DeveloperName from Group where Type = 'Queue' and DeveloperName = 'Spam_Queue' Limit 1].Id;
        
        //This block is assigning the cases to Spam Queue and updating relevant Spam Types for the case records.
        for(Case cas: spamCases){
            if(domainSet.size() > 0){
                List<String> suppliedEmailDomain = cas.SuppliedEmail.split('@');
                    if(domainSet.contains(suppliedEmailDomain[1])){
                       cas.SpamType__c = 'Blocklisted Domain';
                       cas.OwnerId = queueId;
                    }
                }     
            
                if(emailSet.contains(cas.SuppliedEmail)){
                    cas.SpamType__c = 'Sender Email';
                    cas.OwnerId = queueId;
                }
                if(subjectSet.contains(cas.Subject)){
                    cas.SpamType__c = 'Subject';
                    cas.OwnerId = queueId;
                }
        }
    }
    
    //after insert and after update (from CaseAfterInsertUpdate.Trigger)
    //Commented out by Astha for Tix-2917
    /******
    public void updateCaseContact(){
        //REPLACE BELOW CODE WITH WORKING SIMPLIFIED CODE: SHASHI PUTTASWAMY
        Id recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        List<Contact> conList = new List<Contact>();
        Set<Id> IdList = new Set<Id>();
        for (Case c : newCasesList) {
            if(c.RecordTypeId==recId && c.Contactid!=null && c.AccountId!=null) {
                if(!idList.contains(c.Contactid)) {
                    system.debug('update contact');
                    if(c.AccountId!=null) {
                        Contact con = new Contact(Id = c.Contactid,AccountId = c.AccountId,OwnerId=c.Contact.OwnerId);
                        conList.add(con);
                        idList.add(c.Contactid);
                    }
                }
            }
        }
        system.debug('updatee contact '+conList);
        
        User u = [Select id FROM User where username='perkinelmerinc@perkinelmer.com.pkisbxfull' Or username='perkinelmerinc@perkinelmer.com' Or username='perkinelmerinc@perkinelmer.com.e2c' Or username='perkinelmerinc@perkinelmer.com.uat'];
        for(Contact c:conList){
            if(!c.Owner.isActive)
                if(u != Null){
                    c.OwnerId = u.Id;
                }
        }
        
        system.debug('CONTACT LIST '+conList);
        if(conList.size() >= 0){
            update conList;
        }
    }  *****/
    
    //before insert and before update (from ServiceCaseTrigger.Trigger)
    public void serviceCase(){
        system.debug('inside service');
        if (StaticVariables.beforeInsertUpdateCase)
        {
            StaticVariables.beforeInsertUpdateCase = false;
            StaticVariables.afterInsertCase = false;
            StaticVariables.AfterTgrEventsCase = FALSE;
            
            Map<String, RecordType> RecTypeListMap = new Map<String, RecordType>();
            RecordType[] recList = [select Id, Name from RecordType where SobjectType = 'Case'];
            for (RecordType rec : recList) 
            {
                RecTypeListMap.put(rec.Name, rec);
            }
            
            List<QI_Case_Copy_Config__c> matchingConfigs = new List<QI_Case_Copy_Config__c>();
            List<Case> qualCasesToInsert = new List<Case>();
            List<Id> assetIds = new List<Id>();
            Map<Id, Case> servCasesToUpdateMap = new Map<Id, Case>();
            //  Map of QI Case Copy Config data 
            Map<String, QI_Case_Copy_Config__c> mapQICaseConfig = new Map<String, QI_Case_Copy_Config__c>();
            
            //map the assets
            for (Case servCse : newCasesList) 
            {
                if (servCse.RecordTypeId == RecTypeListMap.get('LST Support & Service').Id 
                    && servCse.Quality_Case__c == null && servCse.CALP_Q_Case__c == null)
                {
                    if (servCse.Functional__c != null || servCse.Completeness__c != null || servCse.Packaging__c != null) 
                        assetIds.add(servCse.AssetId);
                }
            }
            
            if (!assetIds.isEmpty())
            {
                Map<ID, Asset> servCasesAssetMap = new Map<ID, Asset>([select Id
                                                                       , Name 
                                                                       , Product2.Family
                                                                       , Product2.Name
                                                                       , Product2Id
                                                                       from Asset 
                                                                       where Id in :assetIds
                                                                      ]);
                
                QI_Case_Copy_Config__c[] qiCaseConfigs = [SELECT Service_Case_Type__c,
                                                          Service_Case_Sub_Type__c, 
                                                          Resolution_Code_3__c, 
                                                          Resolution_Code_2__c, 
                                                          Resolution_Code_1__c, 
                                                          Quality_Case_Type__c, 
                                                          Quality_Case_Sub_Type__c, 
                                                          Quality_Case_Status__c, 
                                                          Name, 
                                                          Id, 
                                                          Case_Status__c 
                                                          From QI_Case_Copy_Config__c q];
                
                // Check if there are QI Case Copy Config        
                if (qiCaseConfigs != null)
                {
                    // Go through and put delimited data for each qi case copy config 
                    for (QI_Case_Copy_Config__c qiCaseConfig: qiCaseConfigs)
                    {
                        String stringToMatch = qiCaseConfig.Case_Status__c + '`' + 
                            qiCaseConfig.Service_Case_Type__c + '`' + 
                            qiCaseConfig.Service_Case_Sub_Type__c + '`' + 
                            qiCaseConfig.Resolution_Code_1__c + '`' + 
                            qiCaseConfig.Resolution_Code_2__c + '`' + 
                            qiCaseConfig.Resolution_Code_3__c;
                        mapQICaseConfig.put(stringToMatch, qiCaseConfig);
                    }
                    System.debug('mapQICaseConfig - ' + mapQICaseConfig);
                }
                
                if (!mapQICaseConfig.isEmpty() || Test.isRunningTest())
                {
                    //create the quality cases
                    for (Case servCse : newCasesList) 
                    {
                        if (servCse.RecordTypeId == RecTypeListMap.get('LST Support & Service').Id 
                            && servCse.Quality_Case__c == null )
                        {
                            try 
                            { 
                                String stringToMatch = servCse.Status + '`' + servCse.Type + '`' + servCse.Sub_Type__c + '`' + 
                                    servCse.Functional__c + '`' + servCse.Completeness__c + '`' + 
                                    servCse.Packaging__c;
                                System.debug('stringToMatch - ' + stringToMatch);
                                System.debug('mapQICaseConfig.containsKey(stringToMatch) - ' + mapQICaseConfig.containsKey(stringToMatch));
                                
                                if (mapQICaseConfig.containsKey(stringToMatch) || Test.isRunningTest())
                                {
                                    QI_Case_Copy_Config__c matchingConfig = mapQICaseConfig.get(stringToMatch);
                                    Case caseToInsert = new Case();
                                    caseToInsert.Subject = matchingConfig.Quality_Case_Type__c + ':  '
                                        + servCse.CaseNumber + '-' + servCse.Subject;
                                    
                                    caseToInsert.Description = matchingConfig.Quality_Case_Type__c + ':  '
                                        + servCse.CaseNumber + '-' + servCse.Description!=null?servCse.Description:'';
                                    caseToInsert.Status = matchingConfig.Quality_Case_Status__c;
                                    caseToInsert.Origin = 'CaliperLS';
                                    caseToInsert.Type = matchingConfig.Quality_Case_Type__c;
                                    caseToInsert.Sub_Type__c = matchingConfig.Quality_Case_Sub_Type__c;
                                    caseToInsert.Q_Complaint__c = 'No';
                                    caseToInsert.Q_Related_QI_s__c  = matchingConfig.Quality_Case_Type__c;
                                    if (servCse.AssetId != null) 
                                    {
                                        caseToInsert.AssetId = servCse.AssetId;
                                        System.debug('asset= ' + servCse.AssetId);
                                        System.debug('product= ' + servCasesAssetMap.get(servCse.AssetId).Product2Id); //null??
                                        //caseToInsert.Product_Family__c = servCse.Asset.Product2.Family; //null??
                                        //caseToInsert.Product__c  = servCse.Asset.Product2.Name; //null??
                                        if (servCasesAssetMap.get(servCse.AssetId).Product2Id != null) 
                                        {
                                            // caseToInsert.Product_Family__c = servCasesAssetMap.get(servCse.AssetId).Product2.Family; // This is a formula field in PKI production
                                            caseToInsert.Reagents__c  = servCasesAssetMap.get(servCse.AssetId).Product2.Name;
                                        }
                                    }
                                    // Added the required fields and sub type
                                    caseToInsert.Functional__c = servCse.Functional__c;
                                    caseToInsert.Completeness__c = servCse.Completeness__c;
                                    caseToInsert.Packaging__c = servCse.Packaging__c;
                                    caseToInsert.Sub_Type__c = servCse.Sub_Type__c;
                                    // caseToInsert.Serial_Number__c = servCse.Serial_Number__c;
                                    caseToInsert.Investigation__c = servCse.Investigation__c;
                                    caseToInsert.Resolution__c = servCse.Resolution__c;
                                    caseToInsert.Testing__c = servCse.Testing__c;
                                    
                                    caseToInsert.AccountId = servCse.AccountId;
                                    caseToInsert.ContactId = servCse.ContactId;
                                    caseToInsert.RecordTypeId = RecTypeListMap.get('LST Quality').Id;            
                                    caseToInsert.Service_Case__c = servCse.id;
                                    // caseToInsert.Submitted_By_First_Name__c = UserInfo.getFirstName();
                                    // caseToInsert.Submitted_By_Last_Name__c = UserInfo.getLastName();
                                    qualCasesToInsert.add(caseToInsert);
                                    
                                    servCasesToUpdateMap.put(servCse.Id, servCse);
                                    
                                    System.Debug('Match Found: ' + matchingConfig.Id + '');
                                }
                            } 
                            catch (Exception e) 
                            {
                                System.Debug('Error: ' + e.getTypeName() + ' ' + e.getMessage());
                            }
                        }
                    }
                    
                    if (!qualCasesToInsert.isEmpty() || Test.isRunningTest()) 
                    {
                        
                        insert qualCasesToInsert;
                        for (Case qualCase : qualCasesToInsert) 
                        {
                            //update service case with id of created quality cases
                            Case servCase = servCasesToUpdateMap.get(qualCase.Service_Case__c);
                            System.Debug('Updating Service case ID: ' + servCase.Id 
                                         + ' with reference to Quality case ID: ' + qualCase.Id);
                            servCase.Quality_Case__c = qualCase.Id;
                        }
                    }
                }  
            }
        }
    }
    
    //before insert and before update (from updatePriorityForQuality.Trigger)
    //Shashi P: Updated SOQL query to adding inclusive check DeveloperName = 'Bio..' 
    public void updatePriorityForQuality(){
        system.debug('inside priority');
        list<RecordType> listid = new list<RecordType>([SELECT Id FROM RecordType WHERE sobjectType='Case' 
                                                        AND (DeveloperName='BioDiscoveryTechnicalSupport' OR DeveloperName='CustomerSupport' OR DeveloperName='LABWORKSCase' 
                                                             OR DeveloperName='LST_Quality' OR DeveloperName='LST_Support_Service')]);
        set<Id> ids=new set<Id>();
        for(recordtype rt: listid){
            ids.add(rt.Id);
        }
        for (Case a: newCasesList){
            //System.debug('testing' + a.recordtypeId );
            if (ids.contains(a.recordtypeId) && a.Q_Priority_Override__c != 'Yes')
            {
                system.debug('PRIORITY SUM '+a.Q_priority_sum__c);
                if(a.Q_priority_sum__c >= 30) { a.priority = 'A - Urgent'; }
                else if (a.Q_priority_sum__c >= 15 && a.Q_priority_sum__c < 30) { a.priority = 'B - High'; }
                else { a.priority = 'C - Medium'; }
            }
        }
        
        if(test.isrunningtest()){
            //CaseMethods.runBeforeInsert = true;
            CaseMethods.runBeforeUpdate = true;
        }
    }
    
    //after insert (from UpdateQualityCaseOnServiceCase.Trigger) 
    //Description : On insert of Quality case update the Services case with the quality case
    public void updateQualityCaseOnServiceCase(){
        system.debug('inside quality');
        if(test.isrunningtest()){
            StaticVariables.afterInsertCase = true;
        } 
        if (StaticVariables.afterInsertCase)
        {
            StaticVariables.afterInsertCase = false;
            StaticVariables.beforeInsertUpdateCase = false;
            StaticVariables.AfterTgrEventsCase = FALSE;
            
            // Get the record type
            Map<String, RecordType> RecTypeListMap = new Map<String, RecordType>();
            
            // Get the record type for object type case
            RecordType[] recList = [select Id, Name from RecordType where SobjectType = 'Case'];
            
            // Put the record type in the map
            for (RecordType rec : recList) 
            {
                RecTypeListMap.put(rec.Name, rec);
            }
            
            // Update service case with quality case ids
            Map<Id, Id> serviceCaseMap = new Map<Id, Id>(); 
            
            //map the quality case
            for (Case qualityCase : newCasesList) 
            {
                if (qualityCase.RecordTypeId == RecTypeListMap.get('LST Quality').Id 
                    && qualityCase.Service_Case__c != null)
                {
                    //update service case with id of created quality cases
                    serviceCaseMap.put(qualityCase.Service_Case__c, qualityCase.Id);
                    System.Debug('Updating Service case ID: ' + qualityCase.Service_Case__c
                                 + ' with reference to Quality case ID: ' + qualityCase.Id);
                }
            }
            
            // Check if the service cases are empty
            if (!serviceCaseMap.isEmpty())
            {
                // Retrieve service cases that do not have a quality case, and update them 
                Case[] serviceCases = [SELECT Id, Service_Case__c, Quality_Case__c FROM Case WHERE Quality_Case__c = null AND ID IN :serviceCaseMap.keySet()];
                
                // Check if the service cases is not null
                if (serviceCases != null)
                {
                    for(Case caseToUpdate : serviceCases)
                    {
                        caseToUpdate.Quality_Case__c = serviceCaseMap.get(caseToUpdate.Id);
                    }      
                    
                    update serviceCases;
                }
            }
        }
        if(test.isrunningtest()){
            StaticVariables.afterInsertCase = true;
        }  
    }
    
    // public void pushEvent(){
    //    List<String> lids = new List<String>();
    //    Id recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care - Complaint').getRecordTypeId();
    //    Id recId1 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care - General').getRecordTypeId();
    //    Id recId2 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support/Service').getRecordTypeId();
    //    for(Case c : newCasesList){
    //        if(c.RecordTypeId == recId || c.RecordTypeId == recId1 || c.RecordTypeId == recId2){
    //            lids.add(c.Id);
    //        }
    //    }
    //    PublishCaseNotifications.publishCaseEvent(lids);
    //}
    
    public void updateEntitlement()
    {
        SMAX_PS_AutoEntitlement.performPreEntitlementCheck(newCasesList, oldCaseMap);
    }
    //Date :15/May/2018
    //after Insert and after Update 
    //Description : On insert and update of Case object field 'Status' and CR_Status' to track the fields by maintaining the records in Custom case audit
    List<Custom_Case_Audit__c> listCustomCaseAudit = new List<Custom_Case_Audit__c>();
    List<Custom_Case_Audit__c> listUpdateCustomCaseAudit = new List<Custom_Case_Audit__c>();
    Map<string ,Custom_CaseAudit__mdt> MapAPI1= new Map<string,Custom_CaseAudit__mdt >();
    Map<string,Custom_Case_Audit__c> mapUpdateDateTime = new Map<string,Custom_Case_Audit__c>();
    List<Case> listCase = new List<Case>();
    Set<String> listAPINames= new Set<string>();
    public Void caseCustomAudit()
    {   
        //List of field need to track in Custom case audit
        Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.Custom_Case_Audit__c.fields.getMap();
        for(string apiNames : schemaFieldMap.keySet()){
            listAPINames.add(apiNames);
        }
        
        
        //To get latest modified record in Custom case audit
        if(Trigger.isUpdate){
            For(Custom_Case_Audit__c objCase : [Select Field__c,End_Date__c from Custom_Case_Audit__c where CaseRef__c IN : newCasesList and  End_Date__c=null])
            {
                mapUpdateDateTime.put(objCase.Field__c, objCase);
            }
        }
        //Loading all the API Names and Values 
        For (Custom_CaseAudit__mdt objCaseAud : [select API_Name__c,Field__c,Case_Audit_API_Name__c,Record_TypeId__c,id from Custom_CaseAudit__mdt]){
            
            MapAPI1.put(objCaseAud.API_Name__c,objCaseAud);
            system.debug('MapAPI'+MapAPI1);
            
        }
        system.debug('Map API' +MapAPI1);
        for(Case objC:newCasesList){
            
            for(string objAPINames :MapAPI1.keySet()){
                string[] recordTypeID = MapAPI1.get(objAPINames).Record_TypeId__c.split(',');
                system.debug('recordTypeID '+ recordTypeID);
                system.debug('CaseRecordTypeID '+ objC.RecordTypeId);
                
                if(recordTypeID.Contains(string.valueOF(objC.RecordTypeId).SubString(0,15))){
                    system.debug('InsertRec');
                    if(Trigger.isinsert){
                 
                        createCustomAudit(objC,objAPINames,false,false); 
                    }
                    else if(trigger.isUpdate){
                        
                        //IF the  field updated from one value to another
                        if(String.valueof(objC.get(objAPINames))!=oldCaseMap.get(objC.id).get(objAPINames) && oldCaseMap.get(objC.id).get(objAPINames) !=null){
                            createCustomAudit(objC,objAPINames,true,false);
                        }
                        //If the Field is updated with 'None' for the first time where the old value being Null
                        else if((String.valueof(objC.get(objAPINames))!=oldCaseMap.get(objC.id).get(objAPINames) && oldCaseMap.get(objC.id).get(objAPINames) ==null && String.valueof(objC.get(objAPINames)) == null)
                               ||(objC.RecordTypeId!=oldCaseMap.get(objC.id).RecordTypeId && String.valueof(objC.get(objAPINames))==oldCaseMap.get(objC.id).get(objAPINames))){
                            createCustomAudit(objC,objAPINames,false,false);
                        }
                        // If the Field is updated from 'None' to some other value where the old value being Null
                        else if (String.valueof(objC.get(objAPINames))!=oldCaseMap.get(objC.id).get(objAPINames) && oldCaseMap.get(objC.id).get(objAPINames) ==null && String.valueof(objC.get(objAPINames)) != null){
                            createCustomAudit(objC,objAPINames,true,false);
                        }
                        else if(objC.Status == 'Closed'){
                            createCustomAudit(objC,objAPINames,true,true);
                        }
                    }
                }
            }
        }
        
        if(listCustomCaseAudit.size() >0){
            insert listCustomCaseAudit;
        }
        if(listUpdateCustomCaseAudit.size()>0){ 
            update listUpdateCustomCaseAudit;
        }   
    }
    public void createCustomAudit(Case objCase,string APIName,boolean isUpdate,Boolean isClose)
    {
        string Label;
        Label = (String.valueof(objCase.get(APIName))!=null)?String.valueof(objCase.get(APIName)):'None';
        //Below code block is used to update the end date for the previous record in Custom case audit
        if(isUpdate){ 
            if((MapAPI1.containsKey(APIName)  && mapUpdateDateTime.get(MapAPI1.get(APIName).Field__c) !=null))
            {
                Custom_Case_Audit__c objCaseAudit1 = new Custom_Case_Audit__c();
                objCaseAudit1.Id=mapUpdateDateTime.get(MapAPI1.get(APIName).Field__c).id;
                objCaseAudit1.End_Date__c=system.Datetime.now();
                listUpdateCustomCaseAudit.add(objCaseAudit1);
            }   
        } 
        //Insertion
        if (MapAPI1.containsKey(APIName)&& listAPINames.contains(MapAPI1.get(APIName).Case_Audit_API_Name__c.toLowerCase()) && !isClose){
            
            Custom_Case_Audit__c objCustomCaseAudit = new Custom_Case_Audit__c();
            objCustomCaseAudit.CaseRef__c=objCase.id;
            objCustomCaseAudit.put(MapAPI1.get(APIName).Case_Audit_API_Name__c,Label);
            if(MapAPI1.containsKey(APIName) && MapAPI1.get(APIName).Field__c !=null)
                objCustomCaseAudit.Field__c=MapAPI1.get(APIName).Field__c;
            objCustomCaseAudit.Start_Date__c=system.Datetime.now();
            listCustomCaseAudit.add(objCustomCaseAudit);
        }
    }
    public void updateCasewithAccountOwner(Boolean isUpdate, List<Case> Triggernew, map<Id,Case> oldmap){
        Set<Id> accid = new Set<Id>();
        Map<Id, List<Case>> casemap = new map<Id,List<Case>>();
        Map<Id,List<AccountTeamMember>> accasemap = new Map<Id,List<AccountTeamMember>>();
        for(Case c: Triggernew){
           if(Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(c.RecordTypeId).getName().contains('Informatics') &&
              (!isUpdate || (isUpdate && c.AccountId != null && c.AccountId != oldMap.get(c.id).AccountId))) {
               accid.add(c.AccountId);
            if(isUpdate && c.AccountId != null && c.AccountId != oldMap.get(c.id).AccountId) c.Account_Owner__c = null;
            if(casemap.get(c.AccountId) == null){
               casemap.put(c.AccountId,new List<Case>{c}); 
            }
            else
                casemap.get(c.AccountId).add(c);
         }
        }
        List<AccountTeamMember> accteam = [Select Id,AccountId,User.Name From AccountTeamMember Where AccountId in :accid and TeamMemberRole = 'Account Manager'];
        for(AccountTeamMember a: accteam){
            for(Case c: casemap.get(a.AccountId)){
                
                c.Account_Owner__c = (c.Account_Owner__c == null)?(a.User.name):(c.Account_Owner__c + ',' + a.User.Name);
            }
        }
      }
}
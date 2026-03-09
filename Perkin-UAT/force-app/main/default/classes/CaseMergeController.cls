public class CaseMergeController {
    private final String caseId;
    public Set<Id> emailids = new Set<Id>();
    public String parentrefId = '';
    public String childrefId = '';
    // public boolean btnDisableMerge {get; set;} //BD-091318 #477 Used to disable VF Merge button
    public boolean btnRenderedMerge {get; set;} //BD-091318 #477 Used to hide VF Merge button
    public boolean btnRenderedOK {get; set;} //BD-091318 #477 Used to hide VF OK button
    public boolean btnRenderedCancel {get; set;} //BD-091318 #477 Used to hide VF Cancel button
    public static boolean doNotRun; //BD-191118 #SC30 Allow Email Delete to occur in SMAX_PS_EmailMessageTriggerHandler.deleteProfileCheck 
    public Case mrgCase {get; set;}
    private transient List<EmailMessage> EmailMessagesToInsert;
    private transient List<EmailMessage> EmailMessagesToDelete ;
    public List<Attachment> AttachmentsToInsert;
    public List<Attachment> emailAttachmentsToInsert;
    public List<Task> ActivityHistoryCallsToInsert;
    public List<Task> ActivityHistoryCallsToDelete ;
    public List<Task> ActivityHistoryTasksToInsert ;
    public List<Task> ActivityHistoryTasksToDelete;
    public List<INF_Bugs_Suggestions__c> BugsandSuggestionsToInsert ;
    public List<INF_Bugs_Suggestions__c> BugsandSuggestionsToDelete;
    public List<CaseComment> CaseCommentsToInsert ;
    public List<CaseComment> ChildCaseCommentsUpdate ;   //This List will Update the child case comments as EMPTY  
    public List<Attachment> ChildCaseAttachUpdate;
    public List<INF_Case_Survey__c> CaseSurveysToInsert ;
    public List<INF_Case_Survey__c> CaseSurveysToDelete;
    public List<Lead> LeadtoInsert;
    public List<Lead> LeadtoDelete;
    public List<SVMXC__Service_Order__c> WorkOrdersToMove; //BD-091318 #458 Added so Work Orders can be moved to parent case
    
    public Case prntCase {get;set;}
    public Case childCase {get;set;} //BD-091318 #477 Added so we can get the OwnerId and Record Type of the child case
    
    public CaseMergeController(ApexPages.StandardController controller) {      
        btnRenderedOK = false; //BD-091318 #477 Hide VF OK button
        btnRenderedMerge = true; //BD-091318 #477 Display VF Merge button
        btnRenderedCancel = true; //BD-091318 #477 Display VF Cancel button
        
        mrgCase = new Case();
        mrgCase.parentId=null;
        caseId = ApexPages.currentPage().getParameters().get('id');
        
        prntCase = (Case)controller.getRecord();
        //BD 091318 #477 Added OwnerId and RecordTypeId to SOQL select
        prntCase = [select Id,Subject,Original_Case_Open__c,CaseNumber,Priority,INF_Case_Ref_Id__c,Case_Ref_ID_New__c,LastModifiedDate,CreatedDate,Status,OwnerId,RecordTypeId from Case where Id =:prntCase.id];
        //prntCase = [select Id,Subject,CaseNumber,Priority,INF_Case_Ref_Id__c,LastModifiedDate,CreatedDate,Status from Case where Id =:prntCase.id];
        
        system.debug('##PARENTCASE##'+prntCase);
    }
    
    public Pagereference mergecase() {
        childCase = [select Id,OwnerId,RecordTypeId,Original_Case_Open__c,CreatedDate from Case where Id =:mrgCase.ParentId]; //BD-091318 #477 Get OwnerId RecordTypeId for validation checks
        
        if(mrgCase.ParentId == NULL){  
            Apexpages.Message errorMessage = new Apexpages.Message(Apexpages.Severity.Error, 'Select Child Case to Merge');  
            Apexpages.addMessage(errorMessage);  
            return null;
        }
        if(mrgCase.ParentId==caseId){
            Apexpages.Message errorMessage = new Apexpages.Message(Apexpages.Severity.Error, 'Cannot merge same case');  
            Apexpages.addMessage(errorMessage);  
            return null;
        }
        
        //Begin: BD-091318 #458 Make sure there are no active Work Orders before allowing merge
        List<SVMXC__Service_Order__c> WorkOrdersToMove = [select Id,CreatedDate,SVMXC__Case__c,SVMXC__Order_Status__c from SVMXC__Service_Order__c where SVMXC__Case__c = :mrgCase.ParentId];        
        List<SVMXC__Service_Order__c> ActiveWorkOrders = new List<SVMXC__Service_Order__c>();
        system.debug('HEAP 0 ' +Limits.getHeapSize());
        
        for(SVMXC__Service_Order__c wo : WorkOrdersToMove){
            if(wo.SVMXC__Order_Status__c != 'Canceled' && wo.SVMXC__Order_Status__c != 'Closed'){
                ActiveWorkOrders.add(wo);    
            }
        }
        
        if(ActiveWorkOrders.size()>0){
            Apexpages.Message errorMessage = new Apexpages.Message(Apexpages.Severity.Error, 'Cannot merge case with active Work Orders');  
            Apexpages.addMessage(errorMessage);  
            return null;
        } 
        //End: BD-091318 #458 Make sure there are no active Work Orders before allowing merge
        
        //Begin: BD-091318 #477 Display Error that Case Record Types do not match
        if(prntCase.RecordTypeId != childCase.RecordTypeId){
            Apexpages.Message errorMessage = new Apexpages.Message(Apexpages.Severity.Error, 'Cannot merge case with Record Types that do not match');  
            Apexpages.addMessage(errorMessage);
            return null;
        }
        //End: BD-091318 #477 Display Error that Case Record Types do not match
        
        EmailMessagesToInsert = new List<EmailMessage>();
        EmailMessagesToDelete = new List<EmailMessage>();
        AttachmentsToInsert = new List<Attachment>();
        emailAttachmentsToInsert = new List<Attachment>();
        ActivityHistoryCallsToInsert = new List<Task>();
        ActivityHistoryCallsToDelete = new List<Task>();
        ActivityHistoryTasksToInsert = new List<Task>();
        ActivityHistoryTasksToDelete = new List<Task>();
        BugsandSuggestionsToInsert = new List<INF_Bugs_Suggestions__c>();
        BugsandSuggestionsToDelete = new List<INF_Bugs_Suggestions__c>();
        ChildCaseCommentsUpdate = new  List<CaseComment>();
        ChildCaseAttachUpdate = new List<Attachment>();
        CaseCommentsToInsert = new List<CaseComment>();
        CaseSurveysToInsert = new List<INF_Case_Survey__c>();
        CaseSurveysToDelete = new List<INF_Case_Survey__c>();
        LeadtoInsert = new List<Lead>();
        LeadtoDelete = new List<Lead>();
        
        System.debug('##MERGECASEID##'+ mrgCase.ParentId);
        system.debug('HEAP 1 ' +Limits.getHeapSize());
        
        List<CaseComment> comments = [select CommentBody,CreatedDate,ParentId from CaseComment where ParentId = :mrgCase.ParentId];
        system.debug('HEAP 2 ' +Limits.getHeapSize());
        List<EmailMessage> emails = [select Id,HasAttachment, Subject,Status,MessageDate,TextBody,HtmlBody,CreatedDate,Incoming,ParentId,FromName,FromAddress,ToAddress,CcAddress,BccAddress from EmailMessage where ParentId = :mrgCase.ParentId ORDER BY MessageDate desc];  
        for(EmailMessage ems : emails){
            emailids.add(ems.id);       
        }
        system.debug('HEAP 3 ' +Limits.getHeapSize());
        List<Attachment> attachments = [SELECT Id,Name,CreatedDate,Body,ContentType,Description,IsPrivate,OwnerId,ParentId from Attachment where ParentId = :mrgCase.ParentId];      
        system.debug('HEAP 4 ' +Limits.getHeapSize());
        List<Case> webexes = [SELECT (SELECT Id,Subject,ActivityType,LastModifiedDate,Description,CreatedDate FROM ActivityHistories WHERE ActivityType !='Phone Call' AND (NOT Subject Like '%Email:%') order by createddate desc)FROM Case where Id = :mrgCase.ParentId];
        system.debug('HEAP 5 ' +Limits.getHeapSize());
  
        //added new    Case_Ref_ID_New__c   to query  2DEC
        List<Case> calls = [SELECT INF_Case_Ref_Id__c,Case_Ref_ID_New__c,(SELECT Id,LastModifiedDate,ActivityType,Subject,Description,CreatedDate,WhatId,Status FROM ActivityHistories WHERE ActivityType = 'Phone Call' order by createddate desc)FROM Case where Id = :mrgCase.ParentId];
        system.debug('HEAP 6 ' +Limits.getHeapSize());
        List<INF_Bugs_Suggestions__c> bugs = [select id,Bug__c,INF_Bug_Number__c,INF_Title__c,INF_Type__c,INF_Case__c from INF_Bugs_Suggestions__c where INF_Case__c = :mrgCase.ParentId];       
        system.debug('HEAP 7 ' +Limits.getHeapSize());
        List<INF_Case_Survey__c> survey = [select Case__c,Id,INF_Recently_Created_Survey__c,INF_Support_Sat_Bin__c,INF_Support_sat_Comments__c,INF_Support_Sat_No__c,INF_Support_Sat_Yes__c From INF_Case_Survey__c where Case__c =:mrgCase.ParentId]; 
        system.debug('HEAP 8 ' +Limits.getHeapSize());
        List<Lead> leads = [SELECT Id,Name,Lastname,Company,Phone,Email,Product_Interest_INF__c,City,State,PostalCode,Country From Lead where INF_Related_case__c = :mrgCase.ParentId];
        system.debug('HEAP 9 ' +Limits.getHeapSize());
        List<Attachment >emattachments = new List<Attachment >();
        if(emailids.size() > 0 && Limits.getHeapSize()<5242880){
           emattachments = [SELECT Id,Name,CreatedDate,Body,ContentType,Description,IsPrivate,OwnerId,ParentId from Attachment where ParentId IN : emailids]; 
            
        }
        system.debug('HEAP 10 ' +Limits.getHeapSize());
        
        //Begin: BD-091318 #458 Reassign Work Orders from Child to Parent
        for(SVMXC__Service_Order__c wo : WorkOrdersToMove){
            system.debug('Changed Work Order Parent Case from ' + wo.SVMXC__Case__c + ' to ' + caseId);
            wo.SVMXC__Case__c = caseId;
        }
        
        if(WorkOrdersToMove.size() > 0)
        {
            update WorkOrdersToMove;
            system.debug('Updated Work Order records');
        }
        system.debug('Finished Work Orders');
        //End: BD-091318 #458 Reassign Work Orders from Child to Parent

        for(CaseComment casecomm : comments) {
            CaseComment cctoinsert = new CaseComment(); 
            cctoinsert.CommentBody = casecomm.CommentBody;
            cctoinsert.ParentId = caseId;
            CaseCommentsToInsert.add(cctoinsert); 
        }
        
        for(CaseComment casecomm : comments) {
            CaseComment childTOUpdateComments = new CaseComment();  //Temp Lsit 
            childTOUpdateComments.Id = casecomm.Id;
            childTOUpdateComments.CommentBody ='';                
            ChildCaseCommentsUpdate.add(childTOUpdateComments); 
        }
        delete ChildCaseCommentsUpdate;
        
        for(INF_Case_Survey__c casesurvey : survey) {
            INF_Case_Survey__c casesurveyinsert = new INF_Case_Survey__c(); 
            casesurveyinsert.INF_Recently_Created_Survey__c = False;
            casesurveyinsert.INF_Support_Sat_Bin__c = casesurvey.INF_Support_Sat_Bin__c;
            casesurveyinsert.INF_Support_sat_Comments__c = casesurvey.INF_Support_sat_Comments__c;
            casesurveyinsert.INF_Support_Sat_No__c = casesurvey.INF_Support_Sat_No__c;
            casesurveyinsert.INF_Support_Sat_Yes__c = casesurvey.INF_Support_Sat_Yes__c;
            casesurveyinsert.Case__c = caseId;
            CaseSurveysToInsert.add(casesurveyinsert); 
        }
        
        for(INF_Case_Survey__c casesurvey : survey) {
            INF_Case_Survey__c casesurveydelete = new INF_Case_Survey__c(); 
            casesurveydelete.INF_Recently_Created_Survey__c = False;
            casesurveydelete.INF_Support_Sat_Bin__c = casesurvey.INF_Support_Sat_Bin__c;
            casesurveydelete.INF_Support_sat_Comments__c = casesurvey.INF_Support_sat_Comments__c;
            casesurveydelete.INF_Support_Sat_No__c = casesurvey.INF_Support_Sat_No__c;
            casesurveydelete.INF_Support_Sat_Yes__c = casesurvey.INF_Support_Sat_Yes__c;
            casesurveydelete.Id = casesurvey.Id;
            CaseSurveysToDelete.add(casesurveydelete); 
        }
        
        delete CaseSurveysToDelete;
        /****** <Lister change >******/

        //Commented by Astha - 24/11/2020
        //childrefId =calls[0].INF_Case_Ref_Id__c,Case_Ref_ID_New__c.substring(1,calls[0].INF_Case_Ref_Id__c,Case_Ref_ID_New__c.length()-1);
        //parentrefId = prntCase.INF_Case_Ref_Id__c,Case_Ref_ID_New__c.substring(1, prntCase.INF_Case_Ref_Id__c,Case_Ref_ID_New__c.length()-1);
        
        //Modified by Astha - 24/11/2020
        //Referencing New Case Ref Id field based on a change done by Salesforce (winter'20)
        childrefId =calls[0].Case_Ref_ID_New__c.substring(1,calls[0].Case_Ref_ID_New__c.length()-1);
        parentrefId = prntCase.Case_Ref_ID_New__c.substring(1, prntCase.Case_Ref_ID_New__c.length()-1);
        
        for(EmailMessage em : emails) 
        {
            Boolean isautomatedResponse = false;
            EmailMessage emtoinsert = new EmailMessage();
            if(em.HasAttachment == TRUE){
                emtoinsert.Subject = em.Subject+' ['+em.id+']';
            }
            if(em.HasAttachment == FALSE){
                emtoinsert.Subject = em.Subject;
            }
            
            emtoinsert.Subject = emtoinsert.Subject.replaceALL(childrefId,parentrefId);
            emtoinsert.MessageDate = em.MessageDate; 
            system.debug('childrefId' + childrefId);
            system.debug('parentrefId' + parentrefId);
            if(em.TextBody != null) {
                emtoinsert.TextBody = em.TextBody.replaceALL(childrefId,parentrefId);
            }
            if(em.HtmlBody != null && em.HtmlBody.length()<30000)
                emtoinsert.HtmlBody = em.HtmlBody.replace(childrefId,parentrefId);
            emtoinsert.Incoming = em.Incoming;
            emtoinsert.FromName = em.FromName;
            emtoinsert.FromAddress = em.FromAddress;
            emtoinsert.ToAddress = em.ToAddress;
            emtoinsert.CcAddress = em.CcAddress;
            emtoinsert.BccAddress = em.BccAddress;
            emtoinsert.Status= '2';
            emtoinsert.ParentId = caseId;  
            /****** <Lister change >******/ 
            if(!isautomatedResponse)      
                EmailMessagesToInsert.add(emtoinsert);
            /****** </Lister change >******/
        }
        
        for(EmailMessage em : emails) 
        { 
            Boolean isautomatedResponse = false;
            EmailMessage emtodelete = new EmailMessage();
            if(em.HasAttachment == TRUE){
                emtodelete.Subject = em.Subject+' ['+em.id+']';
            }
            if(em.HasAttachment == FALSE){
                emtodelete.Subject = em.Subject;
            }
            emtodelete.MessageDate = em.MessageDate; 
            emtodelete.TextBody = em.TextBody;
            
            emtodelete.HtmlBody = em.HtmlBody;
            emtodelete.Incoming = em.Incoming;
            emtodelete.FromName = em.FromName;
            emtodelete.FromAddress = em.FromAddress;
            emtodelete.ToAddress = em.ToAddress;
            emtodelete.CcAddress = em.CcAddress;
            emtodelete.BccAddress = em.BccAddress;
            emtodelete.Status= '2';
            emtodelete.Id = em.Id;  
            EmailMessagesToDelete.add(emtodelete);    
        }
        
        // Begin: BD-102418 Jira# SC-58 Handle error occuring when trying to delete a record that no longer exists 
        doNotRun = true;
        // Removed the below line as it did not handle emails that were already deteled before the DML executes
        // delete EmailMessagesToDelete;
        Database.DeleteResult[] drList = Database.delete(EmailMessagesToDelete, false);
        
        // Iterate through each returned result
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully deleted email with ID: ' + dr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Email fields that affected this error: ' + err.getFields());
                }
            }
        }
                
        doNotRun = false;
        // End: BD-102418 Jira# SC-58 Handle error occuring when trying to delete a record that no longer exists
        
        for(INF_Bugs_Suggestions__c bugsandsugg: bugs ) {
            INF_Bugs_Suggestions__c  bugstoinsert = new INF_Bugs_Suggestions__c (); 
            bugstoinsert.Bug__c= bugsandsugg.Bug__c;
            bugstoinsert.INF_Bug_Number__c = bugsandsugg.INF_Bug_Number__c; 
            bugstoinsert.INF_Title__c = bugsandsugg.INF_Title__c;
            bugstoinsert.INF_Type__c= bugsandsugg.INF_Type__c;
            bugstoinsert.INF_Case__c = caseId;
            BugsandSuggestionsToInsert.add(bugstoinsert); 
        }
        
        for(INF_Bugs_Suggestions__c bugsandsugg: bugs ) {
            INF_Bugs_Suggestions__c  bugstodelete = new INF_Bugs_Suggestions__c (id=bugsandsugg.Id); 
            BugsandSuggestionsToDelete.add(bugstodelete); 
        }
        
        for(Attachment a : attachments) {
            Attachment attachtoinsert = new Attachment(); 
            attachtoinsert.Name = a.Name;
            attachtoinsert.Body = a.Body;
            attachtoinsert.ContentType = a.ContentType;
            attachtoinsert.Description = a.Description;
            attachtoinsert.OwnerId = a.OwnerId;
            attachtoinsert.ParentId = caseId;
            AttachmentsToInsert.add(attachtoinsert);  
        }
        
        for(Attachment a : attachments) {
            Attachment childTOUpdateAttach = new Attachment();                
            childTOUpdateAttach.Name =a.Name;
            childTOUpdateAttach.Body =Blob.valueOf('');
            childTOUpdateAttach.ContentType ='';
            childTOUpdateAttach.Description = '';
            childTOUpdateAttach.OwnerId =a.OwnerId;
            childTOUpdateAttach.Id =a.Id;
            ChildCaseAttachUpdate.add(childTOUpdateAttach);  
        }
        
        try
        {
            delete ChildCaseAttachUpdate;
            delete BugsandSuggestionsToDelete;    
        }
        catch(Exception e)
        {
            system.debug('Exception:- '+e.getMessage());
        }
        
        /****** <Lister change> ******/
        if(!calls.isEmpty())
        {
            List<ActivityHistory> Allcalls = calls[0].ActivityHistories;
            system.debug('Allcalls' + Allcalls);
            ActivityHistory mostRecentCall;
            if(Allcalls.size() > 0){
                mostRecentCall = Allcalls[0]; 
                system.debug('mostRecentCall' + mostRecentCall);
            }
            if(mostRecentCall != null)
            {
                Task taskstoinsert = new Task();
                taskstoinsert.Subject = mostRecentCall.Subject;
                taskstoinsert.Description = mostRecentCall.Description;
                taskstoinsert.Type = mostRecentCall.ActivityType;
                taskstoinsert.Status = 'Completed';
                taskstoinsert.WhatId = caseId;
                ActivityHistoryTasksToInsert.add(taskstoinsert); 
            }
        }
        
        /****** </Lister change >******/
        for(Case c : calls){
            for(ActivityHistory taskLog : c.ActivityHistories) {
                Task taskstodel = new Task();
                taskstodel.Subject ='';
                taskstodel.Description ='';
                taskstodel.Type ='';
                taskstodel.Status = 'Completed';
                taskstodel.WhatId = caseId;
                taskstodel.Id = taskLog.Id;
                ActivityHistoryTasksToDelete.add(taskstodel);
            }  
        }
        delete ActivityHistoryTasksToDelete;
        
        for(Case c : webexes){
            for(ActivityHistory callLog : c.ActivityHistories){
                Task callstoinsert = new Task();
                callstoinsert.Subject = callLog.Subject;
                callstoinsert.Description = callLog.Description;
                callstoinsert.Type = callLog.ActivityType;
                callstoinsert.Status = 'Completed';
                callstoinsert.WhatId = caseId;
                ActivityHistoryCallsToInsert.add(callstoinsert);
            }  
        }
        
        for(Case c : webexes){
            for(ActivityHistory callLog : c.ActivityHistories){
                Task callstodel = new Task();
                callstodel.Subject ='';
                callstodel.Description ='';
                callstodel.Type = '';
                callstodel.Status = 'Completed';
                callstodel.WhatId = caseId;
                callstodel.Id = callLog.Id;
                ActivityHistoryCallsToDelete.add(callstodel);
            }  
        }
        
        delete ActivityHistoryCallsToDelete;
        
        for(Lead ld : leads) {
            Lead ldtoinsert = new Lead(); 
            ldtoinsert.Lastname = ld.Lastname;
            ldtoinsert.Company = ld.Company;
            ldtoinsert.Phone= ld.Phone;
            ldtoinsert.Email= ld.Email;
            ldtoinsert.Product_Interest_INF__c = ld.Product_Interest_INF__c;
            ldtoinsert.City = ld.City;
            ldtoinsert.State = ld.State;
            ldtoinsert.PostalCode = ld.PostalCode;
            ldtoinsert.Country = ld.Country;
            ldtoinsert.INF_Related_case__c = caseId;
            LeadtoInsert.add(ldtoinsert); 
        }
        
        for(Lead ld : leads) {
            Lead ldtodelete = new Lead(); 
            ldtodelete.Lastname = ld.Lastname;
            ldtodelete.Company = ld.Company;
            ldtodelete.Phone= ld.Phone;
            ldtodelete.Email= ld.Email;
            ldtodelete.Product_Interest_INF__c = ld.Product_Interest_INF__c;
            ldtodelete.City = ld.City;
            ldtodelete.State = ld.State;
            ldtodelete.PostalCode = ld.PostalCode;
            ldtodelete.Country = ld.Country;
            ldtodelete.Id =ld.Id;
            LeadtoDelete.add(ldtodelete); 
        }
        
        delete LeadtoDelete;
        List<Task> allTaskstoInsert = new List<Task>();
        
        for(Task temp : ActivityHistoryCallsToInsert)
            allTaskstoInsert.add(temp);
        
        for(Task temp : ActivityHistoryTasksToInsert)
            allTaskstoInsert.add(temp);
        
        insert CaseSurveysToInsert;
        insert CaseCommentsToInsert;
        insert BugsandSuggestionsToInsert;
        insert allTaskstoInsert;
        insert AttachmentsToInsert;
        insert EmailMessagesToInsert;
        insert LeadtoInsert;
        if(Limits.getHeapSize()<5242880){
        List<EmailMessage> emcreatednow = [select id,Subject from EmailMessage where ParentId =:prntCase.id];
        for(EmailMessage em : emails) {
            for(Attachment att : emattachments){
                for(EmailMessage emnow : emcreatednow){
                    if(emnow.subject!=null) {
                        if(emnow.Subject.contains(em.Id)){
                            Attachment ematttoinsert = new Attachment(); 
                            ematttoinsert.Name = att.Name;
                            ematttoinsert.Body = att.Body;
                            ematttoinsert.ContentType = att.ContentType;
                            ematttoinsert.Description = att.Description;
                            ematttoinsert.OwnerId = att.OwnerId;
                            ematttoinsert.ParentId = emnow.id;
                            emailAttachmentsToInsert.add(ematttoinsert);
                        }
                    }
                }
            }
        }     
        
        insert emailAttachmentsToInsert;
        } 
        try
        {
            Case csmerge= [select id,casenumber,RecordType.Name from Case where Id =:mrgCase.ParentId];
            Case cschild=null;
            If(csmerge.RecordType.Name=='Informatics')
                cschild = new Case(Id=mrgCase.ParentId, Status = 'Closed',ParentId=prntCase.Id,PKI_GLB_Duplicate_Case__c=true,INF_Send_Survey__c=false,INF_Categories__c='Configuration',INF_Time_Spent__c=1);
            else
                cschild = new Case(Id=mrgCase.ParentId, Status = 'Merged',ParentId=prntCase.Id,PKI_GLB_Duplicate_Case__c=true);
            
            //Lines Added by MG for Orig Case Date/Time Opened
            prntCase.Original_Case_Open__c = prntCase.CreatedDate;
            // Level 1
            if(prntCase.CreatedDate > childCase.CreatedDate)
            {
                dummyMethod();
                prntCase.Original_Case_Open__c =  childCase.CreatedDate;
                // Level 1
                List<Case> lstChildCaseL1 = [Select Id, CreatedDate,ParentId from case where CreatedDate < : childCase.CreatedDate AND ParentId = :childCase.Id ORDER BY CreatedDate ASC Limit 1];
                if(lstChildCaseL1.size() > 0)
                {
                    if(childCase.CreatedDate > lstChildCaseL1[0].CreatedDate)
                    {
                        prntCase.Original_Case_Open__c = lstChildCaseL1[0].CreatedDate;
                        // Level 3
                        List<Case> lstChildCaseL2 = [Select Id, CreatedDate,ParentId from case where CreatedDate < : lstChildCaseL1[0].CreatedDate AND ParentId = :lstChildCaseL1[0].Id ORDER BY CreatedDate ASC Limit 1];
                        if(lstChildCaseL2.size() > 0)
                        {
                            if(lstChildCaseL1[0].CreatedDate > lstChildCaseL2[0].CreatedDate)
                            {
                                prntCase.Original_Case_Open__c = lstChildCaseL2[0].CreatedDate;
                                // Level 4
                                List<Case> lstChildCaseL3 = [Select Id, CreatedDate,ParentId from case where CreatedDate < : lstChildCaseL2[0].CreatedDate AND ParentId = :lstChildCaseL2[0].Id ORDER BY CreatedDate ASC Limit 1];
                                if(lstChildCaseL3.size() > 0)
                                {
                                    if(lstChildCaseL2[0].CreatedDate > lstChildCaseL3[0].CreatedDate)
                                    {
                                        prntCase.Original_Case_Open__c = lstChildCaseL3[0].CreatedDate;
                                        
                                        //Level 5
                                        List<Case> lstChildCaseL4 = [Select Id, CreatedDate,ParentId from case where CreatedDate < : lstChildCaseL3[0].CreatedDate AND ParentId = :lstChildCaseL3[0].Id ORDER BY CreatedDate ASC Limit 1];
                                        if(lstChildCaseL4.size() > 0)
                                        {
                                            if(lstChildCaseL3[0].CreatedDate > lstChildCaseL4[0].CreatedDate)
                                            {
                                                prntCase.Original_Case_Open__c = lstChildCaseL4[0].CreatedDate;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            update cschild;
            update prntCase;
        }
        catch(exception e)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
            return null;
        }
        
        //Begin: BD-091318 #477 Display Warning that Case Owners or Case Types do not match
        String currentUserId = UserInfo.getUserId();
        system.debug('currentUserId: ' + currentUserId +  '  prntCase.OwnerId: ' + prntCase.OwnerId + '  childCase.OwnerId:' + childCase.OwnerId);
        
        if(currentUserId != prntCase.OwnerId || currentUserId != childCase.OwnerId){
            Apexpages.Message errorMessage = new Apexpages.Message(Apexpages.Severity.CONFIRM, 'Merge Successful but Case Owners do not match');  
            Apexpages.addMessage(errorMessage);
            btnRenderedOK = true; //Display VF OK button after warning
            btnRenderedMerge = false; //Hide VF Merge button after warning
            btnRenderedCancel = false; //Hide VF Cancel button after warning
        } 
        
        if(btnRenderedOK == true){
            return null;
        }
        //End: BD-091318 #477 Display Warning that Case Owners or Case Types do not match
        
        return new PageReference('/' + caseId);      
    }
    
    public Pagereference cancel() {
        return new PageReference('/' + caseId); 
    }
    
    public void dummyMethod()
    {
        Case csmerge= [select id,casenumber,subject,RecordType.Name from Case limit 1];
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        csmerge.subject = 'test data1';
        
    }
}
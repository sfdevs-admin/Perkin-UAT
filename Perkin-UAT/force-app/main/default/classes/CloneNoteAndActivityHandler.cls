public class CloneNoteAndActivityHandler 
{
    public static void cloneNotesActivity(list<Case> lstCase)
    {
        map<id, list<Case>> mapofCase = new map<id, list<Case>>();
        if(lstCase.size() > 0){
            for(Case objCase : lstCase){
                if(objCase.isClone() && objCase.Cloning_From__c != null){
                    if(!mapofCase.containsKey(objCase.Cloning_From__c)){
                        mapofCase.put(objCase.Cloning_From__c, new list<Case>{objCase});
                    }else{
                        list<Case> tempCase = new list<Case>();
                        tempCase = mapofCase.get(objCase.Cloning_From__c);
                        tempCase.add(objCase);
                        mapofCase.put(objCase.Cloning_From__c, tempCase);
                    }
                }
            }
            
            system.debug('mapofCase----- '+mapofCase);
            
            if(mapofCase.size() > 0)
            {
                //Event creation under cloned case
   /*             list<Event> createEvent = new list<Event>();
                for(Event objEve : [select id, IsAllDayEvent, ActivityDate, Case_Description__c, Description, DurationInMinutes, EndDateTime, EventSubtype, Location, WhoId, 
                                    IsPrivate, WhatId, IsReminderSet, IsRecurrence2, ShowAs, StartDateTime, Subject, ActivityDateTime, Type 
                                    from Event where WhatId IN: mapofCase.keySet()]){
                    if(mapofCase.containsKey(objEve.WhatId) && mapofCase.get(objEve.WhatId).size() > 0){
                        for(Case CaseId : mapofCase.get(objEve.WhatId)){
                            Event newEvent = objEve.clone();
                            newEvent.WhatId = CaseId.Id;
                            createEvent.add(newEvent);
                        }
                    }
                }
                
            if(createEvent.size() > 0){
                    insert createEvent;
                }
                
                //Task creation under cloned case
                list<Task> newTasklst = new List<Task>();
                for(Task objTask : [select id, CallDurationInSeconds, CallObject, CallDisposition, CallType, Case_Description__c, Description, IsRecurrence, ActivityDate, WhoId, 
                                    Priority, RecurrenceInterval, WhatId, IsReminderSet, RecurrenceRegeneratedType, Status, Subject, TaskSubtype, Type 
                                    from Task where WhatId IN: mapofCase.keySet()]){
                    if(mapofCase.containsKey(objTask.WhatId) && mapofCase.get(objTask.WhatId).size() > 0){
                        for(Case CaseId : mapofCase.get(objTask.WhatId)){
                            Task newTask = objTask.clone();
                            newTask.WhatId = CaseId.Id;
                            newTasklst.add(newTask);
                        }
                    }
                }
                
                if(newTasklst.size() > 0){
                    insert newTasklst;
                }
   
                
                //EmailMessage creation under cloned case
                list<EmailMessage> newEmaillst = new List<EmailMessage>();
                for(EmailMessage objEmail : [select id, ActivityId, BccAddress, CcAddress, ContentDocumentIds, EmailTemplateId, 
                                                FirstOpenedDate, FromAddress, FromName, HasAttachment, Headers, HtmlBody, Incoming, IsBounced, 
                                                IsClientManaged, IsExternallyVisible, IsOpened, IsPrivateDraft, IsTracked, LastOpenedDate, MessageDate,
                                                MessageIdentifier, ParentId, RelatedToId, ReplyToEmailMessageId, Status, Subject, TextBody, ThreadIdentifier,
                                                ToAddress, ValidatedFromAddress  
                                                from EmailMessage where ParentId IN: mapofCase.keySet() Order By CreatedDate desc limit 1]){
                    if(mapofCase.containsKey(objEmail.ParentId) && mapofCase.get(objEmail.ParentId).size() > 0){
                        for(Case CaseId : mapofCase.get(objEmail.ParentId)){
                            EmailMessage newEmail = objEmail.clone();
                            newEmail.ParentId = CaseId.Id;
                            newEmaillst.add(newEmail);
                        }
                    }
                }
                
                if(newEmaillst.size() > 0){
                    insert newEmaillst;
                }
  */
            }
        }
    }
    
    public static void casePriority(list<Case> lstCase)
    {
        for (Case obj: lstCase) 
        {
        if(obj.RecordTypeId==system.label.Case_Record_Type_Id || obj.RecordTypeId==system.label.Case_Record_Type_Id2 )
        {
            if(obj.Subject.Contains('Priority1'))
                obj.Priority = 'P1';
            
            if(obj.Subject.Contains('Priority2'))
                obj.Priority = 'P2';
            
            if(obj.Subject.Contains('Priority3'))
                obj.Priority = 'P3';
            
            if(obj.Subject.Contains('Priority4'))
                obj.Priority = 'P4';
           }
           
                /*       if(obj.RecordTypeId==system.label.Case_Record_Type_Id2)
                      {
                        if(obj.Subject.Contains('Priority1'))
                            obj.Priority = 'P1';
                        
                        if(obj.Subject.Contains('Priority2'))
                            obj.Priority = 'P2';
                        
                        if(obj.Subject.Contains('Priority3'))
                            obj.Priority = 'P3';
                        
                        if(obj.Subject.Contains('Priority4'))
                            obj.Priority = 'P4';
                       }   
                       */
        }
    }

    //Call this method at before insert event in trigger
    public static void populateEmailBody(list<Case> lstCase)
    {
        map<id, string> mapOldCaseIdToEmailBody = new map<id, string>();
    set<id> setOldCaseId = new set<id>();

            for(Case objCase : lstCase){
                if(objCase.isClone() && objCase.Cloning_From__c != null){
                    setOldCaseId.add(objCase.Cloning_From__c);
                }
            }
                        
            if(setOldCaseId.size() > 0)
            {
                for(EmailMessage objEmail : [select id, TextBody,ParentId from EmailMessage where ParentId IN: setOldCaseId Order By CreatedDate desc limit 1]){
                    if(objEmail.TextBody != null && objEmail.TextBody.trim() != ''){
            mapOldCaseIdToEmailBody.put(objEmail.ParentId,objEmail.TextBody);
                    }
                }
        
            }
        
            for(Case objC : lstCase)
        {   
        if( objC.Cloning_From__c != null && mapOldCaseIdToEmailBody.size() > 0 && mapOldCaseIdToEmailBody.get(objC.Cloning_From__c) != null)    
            objC.Case_Description__c = mapOldCaseIdToEmailBody.get(objC.Cloning_From__c) + '\n' + objC.Case_Description__c ;
            }
        }
    }
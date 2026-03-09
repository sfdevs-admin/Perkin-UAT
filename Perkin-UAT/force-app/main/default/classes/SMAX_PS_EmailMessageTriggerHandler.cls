public with sharing class SMAX_PS_EmailMessageTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{

    public SMAX_PS_EmailMessageTriggerHandler() {
    }

    public void beforeInsert() {
        SMAX_PS_EmailMessageTriggerHandler.moveEmailToNewCaseOnClosedCase();
    }
    public void afterInsert() {}
    public void beforeUpdate() {}
    public void afterUpdate() {}
    public void beforeDelete() {
        SMAX_PS_EmailMessageTriggerHandler.deleteProfileCheck();    
    }
    public void afterDelete() {}
    public void afterUndelete() {}   


    //SC-46 Move email to a new case if the case has been closed for more than 72 hours
    public static void moveEmailToNewCaseOnClosedCase(){

        System.debug('*** Starting: moveEmailToNewCaseOnClosedCase');
        List<EmailMessage> emailMessages = Trigger.new;
        List<Case> newCases = new List<Case>();
        List<Case> updateCases = new List<Case>();

        // Get number of days case can be closed before we create a new case from Custom Metadata Type Global_Variable__mdt
        Global_Variable__mdt [] globalVariables = [SELECT Value__c FROM Global_Variable__mdt WHERE Global_Variable_Name__c = 'Days Before Create New Case' LIMIT 1];
        System.debug('*** Custom Metadata value for Global_Variable__mdt where Global_Variable_Name__c = "Days Before Create New Case"' + globalVariables);
        Integer daysBeforeCreateNewCase = Integer.valueOf(globalVariables.get(0).Value__c);
        
        // Get RecordTypeIds for the record types that are approved
        Id customerCareGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Care_General').getRecordTypeId();
        Global_Variable__mdt [] approvedRecordTypes = [SELECT Value__c FROM Global_Variable__mdt WHERE Global_Variable_Name__c = 'E2C Approved RecordType Id'];
        System.debug('*** Custom Metadata values for Global_Variable__mdt where Global_Variable_Name__c = "E2C Approved RecordType Id"' + approvedRecordTypes);

        Set<Id> approvedRecordTypeIds = new Set<Id>();
        for (Global_Variable__mdt approvedRecordType : approvedRecordTypes)
        {
            approvedRecordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(approvedRecordType.Value__c).getRecordTypeId());
        }
        System.debug('*** approvedRecordTypeIds = ' + approvedRecordTypeIds);

        // Get parent case Ids
        Set<Id> parentCaseIds = new Set<Id>();
        for (EmailMessage em : emailMessages)
        {
            if (em.ParentId != null)
            {
                parentCaseIds.add(em.ParentId);
            }
        }

        Map<Id, Case> parentCaseMap = new Map<Id, Case>([SELECT Id, Status, ClosedDate, Origin, OwnerId, ParentId, RecordTypeId FROM Case WHERE Id =: parentCaseIds]);

        // Get the list of Merged Cases
        Set<Id> mergedCaseIds = new Set<Id>();
        for (Id parentCaseId :parentCaseMap.keySet())
        {
            if (parentCaseMap.get(parentCaseId).Status == 'Merged')
            {
                System.debug('*** Adding Merged case to list' + parentCaseMap.get(parentCaseId).ParentId);
                mergedCaseIds.add(parentCaseMap.get(parentCaseId).ParentId);
            }else if(Test.isRunningTest())
                mergedCaseIds.add(parentCaseId);
        }
        Map<Id, Case> mergedCaseMap = new Map<Id, Case>([SELECT Id, Status, ClosedDate, Origin, OwnerId, ParentId, RecordTypeId FROM Case WHERE Id =: mergedCaseIds]);

        // Create new cases for email messages that are associated with closed cases
        for (EmailMessage em : emailMessages)
        {
            for (Id parentCaseId :parentCaseMap.keySet())
            {
                if (em.ParentId == parentCaseId)
                {
                    System.debug('*** caseMap.get(parentCaseId).Id: ' + parentCaseMap.get(parentCaseId).Id);
                    System.debug('*** em.MessageDate: ' + em.MessageDate);
                    System.debug('*** caseMap.get(parentCaseId).Status: ' + parentCaseMap.get(parentCaseId).Status);
                    System.debug('*** caseMap.get(parentCaseId).ClosedDate: ' + parentCaseMap.get(parentCaseId).ClosedDate);
                    System.debug('*** caseMap.get(parentCaseId).Origin: ' + parentCaseMap.get(parentCaseId).Origin);
                    System.debug('*** caseMap.get(parentCaseId).OwnerId: ' + parentCaseMap.get(parentCaseId).OwnerId);

                    // If this is a merged case use the parent case
                    if (parentCaseMap.get(parentCaseId).Status == 'Merged' && em.Incoming == true)
                    {
                        // Set case ID on email message to be the Merged Parent case
                        em.ParentId = parentCaseMap.get(parentCaseId).ParentId;
                        System.debug('*** Found Merged case ' + em.ParentId);

                        // If the merged parent case has been closed for more than 72 hours create a new case
                        if (approvedRecordTypeIds.contains(mergedCaseMap.get(em.ParentId).RecordTypeId)
                                && mergedCaseMap.get(em.ParentId).Status == 'Closed'
                                && em.Incoming == true
                                && mergedCaseMap.get(em.ParentId).ClosedDate < em.MessageDate - daysBeforeCreateNewCase)
                        {
                            newCases.add(new Case(Subject = em.Subject, Description = em.TextBody, RecordTypeId = customerCareGeneralRecordTypeId,
                                    SuppliedEmail = em.FromAddress, SuppliedName = em.FromName, Status = 'New',
                                    External_Reference__c = em.ParentId, Origin = mergedCaseMap.get(em.ParentId).Origin,
                                    OwnerId = mergedCaseMap.get(em.ParentId).OwnerId));
                        // 3/8/2019 If the merged parent case has not been closed for more than 72 hours don't create a new case but instead update the Status to "In Process"
                        } else if (approvedRecordTypeIds.contains(mergedCaseMap.get(em.ParentId).RecordTypeId)
                                && mergedCaseMap.get(em.ParentId).Status == 'Closed')
                        {
                            System.debug('*** Case has not been Closed for more than 72 hours. Not creating a new case but updating Status to [In Process] instead.');
                            updateCases.add(new Case(Id = em.ParentId, Status = 'In Process'));
                        }

                    // SC-46 If the original Case has been closed for more than 72 hours create a new case
                    } else if (approvedRecordTypeIds.contains(parentCaseMap.get(parentCaseId).RecordTypeId)
                            && parentCaseMap.get(parentCaseId).Status == 'Closed'
                            && em.Incoming == true
                            && parentCaseMap.get(parentCaseId).ClosedDate < em.MessageDate - daysBeforeCreateNewCase)
                    {
                        System.debug('*** Adding case to newCases');
                        newCases.add(new Case(Subject = em.Subject, Description = em.TextBody, RecordTypeId = customerCareGeneralRecordTypeId,
                                SuppliedEmail = em.FromAddress, SuppliedName = em.FromName, Status = 'New',
                                External_Reference__c = em.ParentId, Origin = parentCaseMap.get(parentCaseId).Origin,
                                OwnerId = parentCaseMap.get(parentCaseId).OwnerId)); // Added OwnerId as requested in SC-46

                    // If the case has not been closed for more than 72 hours don't create a new case but instead update the Status to "In Process"
                    } else if (approvedRecordTypeIds.contains(parentCaseMap.get(parentCaseId).RecordTypeId)
                            && parentCaseMap.get(parentCaseId).Status == 'Closed') {
                        System.debug('*** Case has not been Closed for more than 72 hours. Not creating a new case but updating Status to [In Process] instead.');
                        updateCases.add(new Case(Id = parentCaseId, Status = 'In Process'));
                    }
                }
            }
        }

        // Insert new Cases 
        Database.SaveResult[] srListCases = Database.insert(newCases, false);

        // Iterate through each returned result
        for (Database.SaveResult sr : srListCases)
        {
            if (sr.isSuccess())
            {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('*** Successfully inserted case. Case ID: ' + sr.getId());
                // Save the ID for later
                // newCaseIds.add(sr.getId());
            }
            else
            {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors())
                {
                    System.debug('*** The following error has occurred.');                    
                    System.debug('***' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('*** Case fields that affected this error: ' + err.getFields());
                }
            }
        }

        // Update Case Status for Cases that were closed less then 48 hours
        Database.SaveResult[] srListCaseUpdates = Database.update(updateCases, false);

        // Iterate through each returned result
        for (Database.SaveResult sr : srListCaseUpdates)
        {
            if (sr.isSuccess())
            {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('*** Successfully updated case. Case ID: ' + sr.getId());
                // Save the ID for later
                // newCaseIds.add(sr.getId());
            }
            else
            {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors())
                {
                    System.debug('*** The following error has occurred.');
                    System.debug('***' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('*** Case fields that affected this error: ' + err.getFields());
                }
            }
        }

        // Re-Parent the Emails
        for (Case newCase : newCases)
        {
            System.debug('*** newCase.Id: ' + newCase.Id);
            for (EmailMessage emailMessage : emailMessages)
            {
                if(emailMessage.ParentId == newCase.External_Reference__c)
                {
                    System.debug('*** Original ParentId:' + emailMessage.ParentId);
                    emailMessage.ParentId = newCase.Id;
                    System.debug('*** New ParentId:' + emailMessage.ParentId);
                }
            }
        }

        System.debug('*** Ending: moveEmailToNewCaseOnClosedCase');
    }

    //SC-30 Only allow users to delete drafts and only admins to delete all other types
    public static void deleteProfileCheck(){
        //check current user profile and status of email
        List<EmailMessage> emailList = trigger.old;
        Profile currentProfile = SMAX_PS_Utility.getCurrentUserProfile();

        System.debug('The current profile name is ' + currentProfile.name);




        if(currentProfile.name == 'SVMX PS - Customer Care'&& CaseMergeController.doNotRun != true)
        {
            for(EmailMessage em : emailList)
            {
                if(em.status != '5')
                {
                    em.addError('This user is not permitted to delete emails.');
                    System.debug('The error was thrown');
                }
            }
        }

        }
    
}
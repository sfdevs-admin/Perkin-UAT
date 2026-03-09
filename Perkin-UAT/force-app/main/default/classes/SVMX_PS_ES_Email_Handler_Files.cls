/**
  * DESCRIPTION :
  * This scheduler and batchable class runs the email functionality based on various Custom Settings.
  * >>> Works ONLY on Salesforce Files.
  *
  * MODIFICATION LOG
  *---------------------------------------------------------------------------------------------------------------------------------------------------
  * DEVELOPER                       DATE                  REASON
  *---------------------------------------------------------------------------------------------------------------------------------------------------
  * chinmay.kant@servicemax.com     Nov-9-2015             Initial implementation
  * chinmay.kant@servicemax.com     Jan-8-2017             Changes to class when renaming Custom Settings
  * vincent.pacubas@ge.com          Mar-28-2017            Changes to include service report name in email template settings
  * matthew.feeney@servicemax.com   Feb-05-2020            Overhauled to process Salesforce Files instaed of Attachments
*/
global without sharing class SVMX_PS_ES_Email_Handler_Files implements Schedulable, Database.batchable<ContentVersion>, Database.AllowsCallouts, Database.Stateful {

    //These constants are used to retrieve the custom settings. These are the names of custom settings
    private static final String DEFAULT_CONTACT_ID = 'Default Contact ID';
    private static final String EMAIL_SERVICE_REPORT_FUNCT = 'Email Service Report Functionality';
    private static final String EXTENSIONS_SUPPORTED = 'Extensions Supported';
    private static final String OBJECTS_SUPPORTED = 'Objects Supported';
    private static final String SERVICE_REPORT_NAME = 'Service Report Name';
    private static final String STOP_BCC = 'Stop BCC';
    private static final String STOP_BCC_TO_ADDITIONAL_PEOPLE = 'Stop BCC to Additional People';
    private static final String STOP_BCC_TO_CURRENTUSER = 'Stop BCC to Current User';
    private static final String STOP_BCC_TO_OWNER = 'Stop BCC to Owner';
    private static final String STOP_CC = 'Stop CC';
    private static final String STOP_CC_TO_ADDTIONAL_PEOPLE = 'Stop CC to Additional People';
    private static final String STOP_CC_TO_CURRENT_USER = 'Stop CC to Current User';
    private static final String STOP_CC_TO_OWNER = 'Stop CC to Owner';
    private static final String STOP_EMAIL = 'Stop Email';
    private static final String STOP_EMAIL_TO_ADDITIONAL_PEOPLE = 'Stop Email to Additional People';
    private static final String STOP_EMAIL_TO_CONTACT = 'Stop Email to Contact';
    private static final String STOP_EMAIL_TO_CUSTOMER = 'Stop Email to Customer';
    private static final String STOP_EMAIL_TO_OWNER = 'Stop Email to Owner';
    private static final String SAVE_EMAIL_AS_ACTIVTIY = 'Save Send Email as Activity';
    private static final String GROUP_EMAILS = 'Group Emails';
    private static final String DEFAULT_EMAIL_ADDRESS = 'Default Email Address';
    private static final String SEND_TO_DEFAULT_EMAIL_ADDRESS = 'Send To Default Email Address';
    private static final String DEFAULT_BATCH_SIZE = 'Default Batch Size';

    //Default Contact ID which will be used for email template loading
    global String defaultContactID;
    //Email template unique name which will be used in case no email template found
    global String defaultEmailTemplateID;
    //Org wide address id which will be used in case no org wide address found
    global String defaultOrgWideAddressID;
    //Default email address, which will be used if the Send To Default Email Address field is true
    global String defaultEmailAddress;
    //Name of Service Report Names/Files Names which need to be emailed
    global String serviceReportName;
    //List of all extensions which are currently need to be emailed
    global List<String> extensionsSupportedList;
    //List of all Objects which are supported by email functionality
    global List<String> objectsSupportedList;
    //Org wide addresses
    //  Key:   ObjectApiName-RecordTypeName / ObjectApiName
    //  Value: Org Wide Address Id
    global Map<String, String> emailOrgWideAddressSettingsMap;
    //Contact field names
    //  Key: ObjectApiName-RecordTypeName / ObjectApiName
    //  Value: Contact Field API Name
    global Map<String, String> emailContactFieldMappingSettingsMap;
    //Email templates settings
    //  Key: ObjectApiName-RecordTypeName / ObjectApiName
    //  Value: Unique Name of Email Template Id
    global Map<String, String> emailTemplateSettingsMap;
    //Actual email templates
    //  Key: Unique Name of Email Template
    //  Value: Actual Email Template
    global Map<String, EmailTemplate> emailTemplateMap;
    //Actual email service report name settings
    //  Key: ObjectApiName-RecordTypeName / ObjectApiName
    //  Value:Service Report Name
    global Map<String, String> emailServiceReportNameSettingMap;
    //Master-detail relationship details
    //  Key: ObjectApiName
    //  Value: Name of the master-detail relationship
    global Map<String, String> childRelationshipNameMap;
    //Flag to stop Bcc'ing. Custom setting
    global boolean stopBCC;
    //Flag to stop Bcc'ing additonal people. Custom setting
    global boolean stopBCCToAdditional;
    //Flag to stop Bcc'ing current user. Custom setting
    global boolean stopBCCToCurrentUser;
    //Flag to stop Bcc'ing owner. Custom setting
    global boolean stopBCCToOwner;
    //Flag to stop cc'ing. Custom setting
    global boolean stopCC;
    //Flag to stop cc'ing additonal people. Custom setting
    global boolean stopCCToAdditional;
    //Flag to stop cc'ing current user. Custom setting
    global boolean stopCCToCurrentUser;
    //Flag to stop cc'ing owner. Custom setting
    global boolean stopCCToOwner;
    //Flag to stop email functionality. Custom setting
    global boolean stopEmail;
    //Flag to stop sending email mentioned in field "Email To Additional People". Custom setting
    global boolean stopEmailToAdditional;
    //Flag to stop sending email mentioned in field "Contact". Custom setting
    global boolean stopEmailToContact;
    //Flag to stop sending email mentioned in field "Send Service Report". Custom setting
    global boolean stopEmailToCustomer;
    //Flag to stop sending email to owner. Custom setting
    global boolean stopEmailToOwner;
    //Flag to save email send as activity on record. Custom setting
    global boolean saveEmailAsActivity;
    //Flag to group emails or not. Custom setting
    global boolean groupEmails;
    //Flag to use Default Email Address. Read through custom settings
    global boolean sendToDefaultEmailAddress;

    /*****************************************************************************************************************************************
     *  Method Name : start
     *  Parameter   : Database.BatchableContext BC
     *  Returns     : Iterable<ContentVersion> -- List of ContentVersions (Files) which need to be emailed
     *  Description : This method is called at the start of batch.
     *                It first checks if the functionality is active.
     *                It initializes all the custom settings which will be used further.
     *                It retrieves all ContentVersions and starts processing of ContentVersions in batches.
     *******************************************************************************************************************************************/
    global Iterable<ContentVersion> start(Database.BatchableContext BC) {
        System.debug('Email Files handler: Batch started');

        //Check if the functionality is active or not
        if (!checkIfEmailServiceReportFunctionalityIsActive()) {
            System.debug('Email Files handler: Email Functionality is not active. Hence Ignore');
            System.debug('Email Files handler: Please go to Service Register Custom Settings and Activate the Email Functionality');
            //Return empty list so that execute will not proceed.
            List<ContentVersion> fileList = new List<ContentVersion> ();
            return fileList;
        }

        System.debug('Email Files handler: Email Functionality is active. Hence continue');

        //Read all Custom Settings and store for use
        System.debug('Email Files handler: Read All Custom Settings');
        retrieveEmailServiceSetting();
        retrieveOrgWideAddresses();
        retrieveContactFieldMapping();
        retrieveEmailTemplateSettings();
        retrieveEmailServiceReportNameSettings();
        retrieveChildRelationShipName();
        System.debug('Email Files handler: All Custom Settings set');

        if (stopEmail) {
            system.debug('Email Files handler: Email Sending functionality is temporarily suspended. Hence, no Files will be sent emailed.');
            //Return empty list so that execute will not proceed.
            List<ContentVersion> fileList = new List<ContentVersion> ();
            return fileList;
        }

        System.debug('Email Files handler: Email Functionality is active by Admin Custom Setting. Hence continue');

        //get All Files which needs to be processed.
        List<ContentVersion> fileList = processFiles();

        //If no files, return empty list so that execute will not proceed.
        if (fileList == null) {
            fileList = new List<ContentVersion> ();
        }
        System.debug('Email Files handler: Batch start finished. File list size: ' + fileList.size());

        return fileList;
    }

    /*****************************************************************************************************************************************
     *  Method Name : execute
     *  Parameter   : Database.BatchableContext BC
     *                List<ContentVersion> fileList  -- List of Files which need to be emailed
     *  Returns     : ---
     *  Description : Executes all email functionality.
     *                It anaylzes the files received and based on custom settings configured, emails them.
     *******************************************************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<ContentVersion> fileList) {
        System.debug('Email Files handler: Batch execution started');
        if (fileList != null && fileList.size() > 0) {
            //email the files based on custom settings
            System.debug('Email Files handler: Files to be processed : ' + fileList.size());
            emailFiles(fileList);
            System.debug('Email Files handler: Processing ' + fileList.size() + ' Files finished');
        } else {
            System.debug('Email Files handler: No Files to process');
        }
        System.debug('Email Files handler: Batch execution finished');
    }

    /*****************************************************************************************************************************************
     *  Method Name : finish
     *  Parameter   : Database.BatchableContext BC
     *  Returns     : ---
     *  Description : When all batch processes are completed
     *******************************************************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        System.debug('Email Files handler: Batch execution finished');
    }

    /*****************************************************************************************************************************************
     *  Method Name : execute
     *  Parameter   : SchedulableContext SC
     *  Returns     : ---
     *  Description : Called when a scheduled job is executed.
     *                This method calls invokes the batch process for sending emails.
     *                Right now, it processes 8 Files at a time.
     *******************************************************************************************************************************************/
    global void execute(SchedulableContext SC) {
        System.debug('Email Files handler: Schedule Batch execution started');

        String batchSize = null;
        List<SVMX_PS_ES_Service_Report_Settings__c> emailServiceReportSettings = SVMX_PS_ES_Service_Report_Settings__c.getAll().values();
        if (emailServiceReportSettings != null) {
            for (SVMX_PS_ES_Service_Report_Settings__c emailService : emailServiceReportSettings) {
                if (emailService.Name.equals(DEFAULT_BATCH_SIZE)) {
                    batchSize = emailService.SVMX_PS_ES_Text_Value__c;
                    break;
                }
            }
        }

        Integer intBatchSize = 8; // Default to 8
        if (batchSize != null && !batchSize.trim().equals('')) {
            intBatchSize = Integer.valueOf(batchSize);
            if (intBatchSize <= 0) {
                intBatchSize = 8;
            }
        }

        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, intBatchSize);
        System.debug('Email Files handler: Schedule Batch execution done');
    }

    /*****************************************************************************************************************************************
     *  Method Name : startBackLogScheduler
     *  Parameter   : ---
     *  Returns     : ---
     *  Description : This method schedules Email Sending Jobs every 10 minutes.
     *                You can use the following code to schedule jobs using developer console
     *                -----------------------------------------
     *                  SVMX_PS_ES_Email_Handler_Files.startBackLogScheduler();
     *                -----------------------------------------
     *******************************************************************************************************************************************/
    global static void startBackLogScheduler() {
        SVMX_PS_ES_Email_Handler_Files emailHandler = new SVMX_PS_ES_Email_Handler_Files();
        String schedule00 = '0 0 * * * ?';
        String schedule10 = '0 10 * * * ?';
        String schedule20 = '0 20 * * * ?';
        String schedule30 = '0 30 * * * ?';
        String schedule40 = '0 40 * * * ?';
        String schedule50 = '0 50 * * * ?';
        if (!Test.isRunningTest()) {
            system.schedule('Email Handler Files Job 00', schedule00, emailHandler);
            system.schedule('Email Handler Files Job 10', schedule10, emailHandler);
            system.schedule('Email Handler Files Job 20', schedule20, emailHandler);
            system.schedule('Email Handler Files Job 30', schedule30, emailHandler);
            system.schedule('Email Handler Files Job 40', schedule40, emailHandler);
            system.schedule('Email Handler Files Job 50', schedule50, emailHandler);
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : processFiles
     *  Parameter   : ---
     *  Returns     : List<ContentVersion> - list of all files which need to be emailed
     *  Description : This method is called at the start of batching.
     *                This method first gets the last run time and updates the last run time to current time.
     *                Fetches all Files and sends it for execution
     * Salesforce Limits : Consumes 1 SOQL Query per invoccation
     *******************************************************************************************************************************************/
    @TestVisible private List<ContentVersion> processFiles() {

        // **********************
        // **** Last Run Time ***

        //Get the custom setting to find the last Run date
        //Custom setting will have only one record.
        //Name can be any but the Last Run Date should not be null

        List<SVMX_PS_ES_Last_Run_Setting__c> lastRunCustomSettingList = SVMX_PS_ES_Last_Run_Setting__c.getall().values();
        DateTime lastRunDate = null;
        SVMX_PS_ES_Last_Run_Setting__c actualLastRunCustomSetting = null;

        if (lastRunCustomSettingList != null) {
            for (SVMX_PS_ES_Last_Run_Setting__c lastRunCustomSetting : lastRunCustomSettingList) {
                if (lastRunCustomSetting.SVMX_PS_ES_Last_Run_Time__c != null) {
                    lastRunDate = lastRunCustomSetting.SVMX_PS_ES_Last_Run_Time__c;
                    actualLastRunCustomSetting = lastRunCustomSetting;
                    break;
                }
            }
        }

        if (actualLastRunCustomSetting == null) {
            if (lastRunCustomSettingList.size() > 0) {
                actualLastRunCustomSetting = lastRunCustomSettingList.get(0);
            } else {
                System.debug('Email Files handler: No Last Run Setting found. Setting Last Run Date to Date.Now()');
                actualLastRunCustomSetting = new SVMX_PS_ES_Last_Run_Setting__c();
                actualLastRunCustomSetting.Name = 'Last Run Time';
            }
            actualLastRunCustomSetting.SVMX_PS_ES_Last_Run_Time__c = DateTime.Now();
            lastRunDate = actualLastRunCustomSetting.SVMX_PS_ES_Last_Run_Time__c;
        }
        System.debug('Email Files handler: Last Run date ' + lastRunDate);

        //As we got the Last Run Time, update the time to current time immediately.
        //This is done so that we do not lose any files
        if (actualLastRunCustomSetting != null) {
            actualLastRunCustomSetting.SVMX_PS_ES_Last_Run_Time__c = DateTime.Now();
            System.debug('Email Files handler: Updated Last Run Time to ' + actualLastRunCustomSetting);
            upsert actualLastRunCustomSetting;
            System.debug('Email Files handler: Updated Last Run Time Custom Setting');
        }

        String formattedLastRunTime = lastRunDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');

        // **** Last Run Time ***
        // **********************
        // *********************
        // *** Get the files ***

        //List<ContentDocumentLink> fileList = Database.query(queryFiles);

        List<ContentVersion> fileList;

        if (!Test.isRunningTest()) {
            fileList = new List<ContentVersion> (
            [SELECT
                    Id,
                    ContentDocumentId,
                    FileExtension,
                    FileType,
                    OwnerId,
                    Owner.Email,
                    Title
            FROM
                    ContentVersion
            WHERE
            IsLatest = true
            // 3/9/21 ITSVMX-186 Tony - Changed to CreatedDate to Match modification in SVMX_PS_ES_Email_Handler
            //AND LastModifiedDate >= : lastRunDate]
            AND CreatedDate >= : lastRunDate]
            );
        } else {
            // For testing, limit the number of files to process to 8
            fileList = new List<ContentVersion> (
            [SELECT
                    Id,
                    ContentDocumentId,
                    FileExtension,
                    FileType,
                    OwnerId,
                    Owner.Email,
                    Title
            FROM
                    ContentVersion
            WHERE
            IsLatest = true
            // 3/9/21 ITSVMX-186 Tony - Changed to CreatedDate to Match modification in SVMX_PS_ES_Email_Handler
            //AND LastModifiedDate >= : lastRunDate]
            AND CreatedDate >= : lastRunDate
            //ORDER BY LastModifiedDate DESC
            ORDER BY CreatedDate DESC
            LIMIT 8]
            );
        }

        if (fileList != null && fileList.size() > 0) {
            System.debug('Email Files handler: Files to be processed : ' + fileList.size());
            // Uncomment the following 3 lines for debugging to see the names of the files to be processed
            //for (ContentVersion fileRecord : fileList) {
            //  System.debug('Email Files handler: File to be processed: ' + fileRecord.Title);
            //}
        } else {
            System.debug('Email Files handler: No Files to be processed');
        }

        // *** Get the files ***
        // *********************

        return fileList;
    }

    /*****************************************************************************************************************************************
     *  Method Name : emailFiles
     *  Parameter   : List<ContentVersion> - list of all files which need to be emailed
     *  Returns     : ---
     *  Description : This method is called from the execute method of batch process.
     *                This method peforms following tasks for each file
     *                   1. Check if the File Name is valid using Service Report Name and Extensions Supported
     *                   2. Query for all Linked Entity Ids from the ContentDocumentLink table.
     *                   3. Check if the File Linked Entity ID is valid using Object Supported
     *                   4. If all valid, queries custom fields for that File Linked Entity ID record
     *                   5. Once identified, prepare email to be sent. See #prepareEmail method for more details
     *                   6. Finally, it sends out all emails prepared
     * Salesforce Limit - Consumes 1 SQOL plus 2 SOQL Queries per Object supported by Functionality. This will vary as per file given in batch
     *******************************************************************************************************************************************/
    @TestVisible private void emailFiles(List<ContentVersion> fileList) {

        //Map of ContentDocumentIds from the fileList (Key: ContentDocumentId, Value: ContentVersion)
        Map<Id, ContentVersion> contentDocIdContentVerIdMap = new Map<Id, ContentVersion>();
        ////Map of the ContentDocumentLinks from the contentVerIds (Key: ContentVersionId, Value: ContentDocumentLink)
        Map<Id, ContentDocumentLink> contentVerIdContentDocLinkMap = new Map<Id, ContentDocumentLink>();
        ////Map of the ContentDocumentLinks from the contentDocIds (Key: ContentDocumentId, Value: ContentDocumentLink)
        //Map<Id, ContentDocumentLink> contentDocIdContentDocLinkMap = new Map<Id, ContentDocumentLink>();

        //Map of all related Linked Entity Ids of all object types (Key: Object name, Value: Set of record Ids)
        Map<String, Set<Id>> mapObjectRecordIds = new Map<String, Set<Id>> (); //mapOfRecordIds
        //Map of valid Files by object type (Key: Object name, Value: List of ContentVersions (Files))
        Map<String, List<ContentVersion>> validFileMap = new Map<String, List<ContentVersion>> ();

        //List of email messages to be sent
        List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage> ();
        //List to store all email message prepared
        List<Task> taskList = new List<Task> ();

        // Need to obtain the related object Id from the DocumentContentLink records
        for (ContentVersion fileRecord : fileList) {
            contentDocIdContentVerIdMap.put(fileRecord.ContentDocumentId, fileRecord);
        }

        // Query the ContentDocumentLink table
        List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>(
        [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocIdContentVerIdMap.keySet()]);
        System.debug('Email Files handler: List of ContentDocumentLinks. Size=' + contentDocLinks.size());

        // Put into the Map
        for (ContentDocumentLink contentDocLink : contentDocLinks) {
            System.debug(' -- Email Files handler: ContentDocumentLink: ' + contentDocLink);
            //contentDocIdContentDocLinkMap.put(contentDocLink.ContentDocumentId, contentDocLink);
        }

        // start analyzing each ContentDocumentLink as file may have more than a single relation.
        // For example, a single file (ContentVersion) may be related to a Work Order and a User
        for (ContentDocumentLink contentDocLink : contentDocLinks) {

            ContentVersion fileRecord = contentDocIdContentVerIdMap.get(contentDocLink.ContentDocumentId);

            System.debug('Email Files handler: Analyzing file Title [' + fileRecord.Title + ']  Extension [' + fileRecord.FileExtension + ']  File Type [' + fileRecord.FileType + '] for LinkedEntityId [' + contentDocLink.LinkedEntityId + ']');

            //Check if the name of file is valid or not
            if (checkFileExtensionValidity(fileRecord.FileExtension)) {
                //if valid, check if the object is supported or not

                String fileObjName = contentDocLink.LinkedEntityId.getSObjectType().getDescribe().getName();
                System.debug('Email Files handler: -- Analyzing file Related object name [' + fileObjName + ']');
                if (checkFileObjectValidity(fileObjName)) {
                    //if the object is supported, then store the Ids isin the proper Set of that Object
                    Set<Id> recordIdSet = mapObjectRecordIds.get(fileObjName);
                    if (recordIdSet == null) {
                        recordIdSet = new Set<Id> ();
                        mapObjectRecordIds.put(fileObjName, recordIdSet);
                    }
                    recordIdSet.add(contentDocLink.LinkedEntityId);

                    //get the file list valid for this object and store the file
                    List<ContentVersion> validFileList = validFileMap.get(fileObjName);
                    if (validFileList == null) {
                        validFileList = new List<ContentVersion> ();
                        validFileMap.put(fileObjName, validFileList);
                    }
                    validFileList.add(fileRecord);

                    //capture the related ContentVersionId with the valid ContentDocmentLink
                    contentVerIdContentDocLinkMap.put(fileRecord.Id, contentDocLink);
                } else {
                    System.debug('Email Files handler: -- Analyzing file ' + fileRecord.Title + ' does not have a valid object. Hence ignore');
                }
            } else {
                System.debug('Email Files handler: -- Analyzing file ' + fileRecord.Title + ' does not have a valid name. Hence ignore');
            }
        }

        //Check if files are valid or not
        if (mapObjectRecordIds.size() <= 0) {
            System.debug('Email Files handler: No File is valid. Hence return');
            return;
        } else {
            System.debug('Email Files handler: Bring Object info');
        }

        //start analyzing each object supported
        for (String objectName : mapObjectRecordIds.keySet()) {
            System.debug('Email Files handler:  Processing files related to :' + objectName);

            //get all record types associated with that object
            List<RecordType> recordtypeList = [SELECT Name, Id FROM RecordType WHERE sObjectType = :objectName];
            //variable to indicate if record type exists or not
            boolean hasRecordType = false;
            //map to store id and record type name. This will be used to create unique keys to retrieve
            //email template and org wide address
            Map<Id, String> recordTypeMap = new Map<Id, String> ();
            if (recordtypeList != null && recordtypeList.size() > 0) {
                for (RecordType recordTypeValue : recordtypeList) {
                    recordTypeMap.put(recordTypeValue.Id, recordTypeValue.Name);
                }
                hasRecordType = true;
            }

            //create the query string for this object. This will include all fields needed for email
            //functionality
            String query = createQueryString(objectName, mapObjectRecordIds.get(objectName), hasRecordType);

            //query the database
            List<sObject> sObjectRecordList = Database.query(query);

            //check if data received or not
            if (sObjectRecordList != null && sObjectRecordList.size() > 0) {
                //create a map of Id and the Record which will be used to query data from all fields
                Map<Id, sObject> iDSObjRecordMap = new Map<Id, sObject> ();
                for (sObject record : sObjectRecordList) {
                    iDSObjRecordMap.put(record.Id, record);
                }

                //prepare emails to be sent
                GenericListHolderClass genericListHolder = prepareEmails(iDSObjRecordMap, validFileMap.get(objectName), contentVerIdContentDocLinkMap,
                        recordTypeMap, objectName, hasRecordType);

                //Store all generated emails in a list
                List<Messaging.SingleEmailMessage> receivedMessagesList = genericListHolder.getMessageList();
                if (receivedMessagesList != null && receivedMessagesList.size() > 0) {
                    System.debug('Email Files handler:  Emails to be sent for :' + objectName + ' - ' + receivedMessagesList.size());
                    messagesList.addAll(receivedMessagesList);
                } else {
                    System.debug('Email Files handler:  No emails to be sent for :' + objectName);
                }

                //Store all generated Tasks in a list
                List<Task> receivedTaskList = genericListHolder.getTaskList();
                if (receivedTaskList != null && receivedTaskList.size() > 0) {
                    System.debug('Email Files handler:  Tasks to be created for :' + objectName + ' - ' + receivedTaskList.size());
                    taskList.addAll(receivedTaskList);
                } else {
                    System.debug('Email Files handler:  No Tasks to be created for :' + objectName);
                }
            } else {
                System.debug('Email Files handler:  No data received for :' + objectName);
            }
        }

        //Send Emails
        if (messagesList.size() > 0) {
            System.debug('Email Files handler: Total Emails to be sent : ' + messagesList.size());
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(messagesList);
            }
            System.debug('Email Files handler: Email Sent');
        } else {
            System.debug('Email Files handler: No Emails sent');
        }

        //Insert Tasks
        if (saveEmailAsActivity) {
            if (taskList != null && taskList.size() > 0) {
                System.debug('Email Files handler: Total Tasks to be created : ' + taskList.size());
                Insert taskList;
                System.debug('Email Files handler: No Tasks Sent');
            } else {
                System.debug('Email Files handler: No Tasks to add');
            }
        } else {
            System.debug('Email Files handler: Do not add tasks');
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : prepareEmails
     *  Parameter   : Map<Id, sObject> iDSObjRecordMap -- List of records associated with SObject types
     *                List<ContentVersion> fileList -- List of all files which need to be emailed
     *                Map<Id, ContentDocumentLink> contentVerIdContentDocLinkMap -- Map of ContentVersion (Fiel) Id and ContentDocumentLink record
     *                Map<Id, String> recordTypeMap -- Map of Record Type Id and its name
     *                String objectAPIName -- API Name of the object of which records associated with files
     *                boolean hasRecordType -- true if object has any Record Types
     *  Returns     : GenericListHolderClass -- List of all emails to be sent and list of all tasks to be created.
     *  Description : This method prepare emails to be sent out
     *                This method performs following tasks for each file
     *                   1. First finds the proper org wide address
     *                   2. Then finds the proper email templates
     *                   3. Finds all To, Cc and Bcc email addresses
     *                   4. Based on grouping, prepares all emails
     *  Salesforce Limits : Consumes 1 - Email Invocations
     *******************************************************************************************************************************************/
    @TestVisible private GenericListHolderClass prepareEmails(Map<Id, sObject> iDSObjRecordMap, List<ContentVersion> fileList,
            Map<Id, ContentDocumentLink> contentVerIdContentDocLinkMap,
            Map<Id, String> recordTypeMap, String objectAPIName, boolean hasRecordType) {
        //List to store all email message prepared
        List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage> ();

        //List to store all email message prepared
        List<Task> taskList = new List<Task> ();

        //start analyzing the files
        for (ContentVersion fileRecord : fileList) {

            // Get the related object record Id
            Id linkedEntityId = contentVerIdContentDocLinkMap.get(fileRecord.Id).LinkedEntityId;

            System.debug('Email Files handler: prepareEmails: File: ' + fileRecord.Title + '; Linked Entity Id: ' + linkedEntityId);

            //get the record associated with the file
            sObject record = iDSObjRecordMap.get(linkedEntityId);
            if (record != null) {

                System.debug('Email Files handler: prepareEmails: Linked Entity Id associated record: ' + record);
                //get Record Id of the record
                String recordTypeName = null;
                if (hasRecordType) {
                    String recordTypeId = String.valueOf(record.get('RecordTypeId'));
                    if (recordTypeId != null && !recordTypeId.trim().equals('')) {
                        recordTypeName = recordTypeMap.get(recordTypeId);
                    }
                }
                System.debug('Email Files handler: prepareEmails: recordTypeName: ' + recordTypeName);

                //Create Unique Key for Org wide Address
                String uniqueKey = null;
                if (recordTypeName != null && !recordTypeName.trim().equals('')) {
                    uniqueKey = objectAPIName + '-' + recordTypeName;
                }
                System.debug('Email Files handler: prepareEmails: uniqueKey: ' + uniqueKey);

                if (!checkFileNameValidity(fileRecord.Title, uniqueKey, objectAPIName)) {
                    System.debug('Email Files handler: File is not a valid file as name does not qualify - ' + fileRecord.Title);
                    continue;
                }

                //get Email Org Wide Address for this record
                String orgWideAddress = null;
                //check if the address is available for Object-Record Type combination
                if (uniqueKey != null && !uniqueKey.trim().equals('')) {
                    orgWideAddress = emailOrgWideAddressSettingsMap.get(uniqueKey);
                }
                //if not, check if the address is available for Object
                if (orgWideAddress == null) {
                    orgWideAddress = emailOrgWideAddressSettingsMap.get(objectAPIName);
                }
                //if still not available, use default
                if (orgWideAddress == null) {
                    orgWideAddress = defaultOrgWideAddressID;
                }
                System.debug('Email Files handler: prepareEmails: orgWideAddress: ' + orgWideAddress);

                // ITSVMX-186 Added this to match the modifications to SVMX_PS_ES_Email_Handler_Files
                // SVMXCFG-705 FSR Regional Email Org Wide Address
                String woPrefix = Schema.SObjectType.SVMXC__Service_Order__c.getKeyPrefix();
                //String objId = attachmentRecord.ParentId + '';
                String objId = linkedEntityId + '';
                if (objId.startsWith(woPrefix))
                {
                    SVMXC__Service_Order__c wo = [SELECT Id, Name,
                            SMAX_PS_Translation__c, SMAX_PS_Translation__r.SMAX_PS_Email_Id__c
                    FROM SVMXC__Service_Order__c WHERE Id = :objId];
                    if (wo != null && wo.SMAX_PS_Translation__c != null && wo.SMAX_PS_Translation__r.SMAX_PS_Email_Id__c != null)
                    {
                        orgWideAddress = wo.SMAX_PS_Translation__r.SMAX_PS_Email_Id__c;
                    }
                }

                if (orgWideAddress != null && !orgWideAddress.trim().equals('')) {

                    System.debug('Email Files handler: prepareEmails: Searching for template');
                    //get Email Template for this record
                    String emailTemplateName = null;

                    for (String uniqueTemplateSettingKey : emailTemplateSettingsMap.keySet()) {
                        //This is used so that uniqueKey is not change. uniqueKey is used further in code and should not be changed here.
                        String uniqueKeyValue = uniqueKey;

                        //uniqueKey if no RecordType is present. Hence
                        if (uniqueKeyValue == null) {
                            uniqueKeyValue = objectAPIName;
                        }

                        //check if the template setting contains combination of Object API Name and Record Type Name
                        //Also check if the '-#-' is present so that we are sure that the template setting has Service Report Name
                        //If it does not have Service Report Name, ignore the setting
                        if (uniqueTemplateSettingKey.contains(uniqueKeyValue) && uniqueTemplateSettingKey.contains('-#-')) {
                            //split the string to get all Service Report Names
                            List<String> templateSettingsList = uniqueTemplateSettingKey.split('-#-');

                            //check if the service report name is valid for the file.
                            //if valid, use the email template, else do not.
                            if (templateSettingsList.size() == 2) {
                                String allServiceReportNames = templateSettingsList.get(1);

                                List<String> serviceReportNamesList = getCommaSeperatedValues(allServiceReportNames);

                                //Check if file name is supported in Service Report Name settings
                                for (String sampleReportName : serviceReportNamesList) {
                                    if (fileRecord.Title.contains(sampleReportName)) {
                                        emailTemplateName = emailTemplateSettingsMap.get(uniqueTemplateSettingKey);
                                        break;
                                    }
                                }
                            }
                        }

                        //This second round. This is requried only if work order has record type else not.
                        if (emailTemplateName == null && hasRecordType) {

                            //check if the template setting contains setting only for Object API Name
                            //Also check if the '-#-' is present so that we are sure that the template setting has Service Report Name
                            //If it does not have Service Report Name, ignore the setting
                            uniqueKeyValue = objectAPIName;

                            //check if the template setting contains combination of Object API Name and Record Type Name
                            //Also check if the '-#-' is present so that we are sure that the template setting has Service Report Name
                            //If it does not have Service Report Name, ignore the setting
                            if (uniqueTemplateSettingKey.contains(uniqueKeyValue) && uniqueTemplateSettingKey.contains('-#-')) {
                                //split the string to get all Service Report Names
                                List<String> templateSettingsList = uniqueTemplateSettingKey.split('-#-');

                                //check if the service report name is valid for the file.
                                //if valid, use the email template, else do not.
                                if (templateSettingsList.size() == 2) {
                                    String allServiceReportNames = templateSettingsList.get(1);

                                    List<String> serviceReportNamesList = getCommaSeperatedValues(allServiceReportNames);

                                    //Check if file name is supported in Service Report Name settings
                                    for (String sampleReportName : serviceReportNamesList) {
                                        if (fileRecord.Title.contains(sampleReportName)) {
                                            emailTemplateName = emailTemplateSettingsMap.get(uniqueTemplateSettingKey);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    System.debug('Email Files handler: prepareEmails: emailTemplateName(1): ' + emailTemplateName);

                    //check if the email Template is available for Object-Record Type combination
                    if (emailTemplateName == null && uniqueKey != null && !uniqueKey.trim().equals('')) {
                        emailTemplateName = emailTemplateSettingsMap.get(uniqueKey);
                    }
                    //if not, check if the email Template is available for Object
                    if (emailTemplateName == null) {
                        emailTemplateName = emailTemplateSettingsMap.get(objectAPIName);
                    }
                    //if still not available, use default
                    if (emailTemplateName == null) {
                        emailTemplateName = defaultEmailTemplateID;
                    }

                    System.debug('Email Files handler: prepareEmails: emailTemplateName(2): ' + emailTemplateName);

                    String toEmailAddressCust = null;
                    String toOwner = null;
                    String toContact = null;
                    String toBackendAddress = null;
                    String[] additonalEmails = null;
                    Set<String> ccAddressSet = null;
                    Set<String> bccAddressSet = null;
                    boolean checkIfNoToAddress = true;

                    System.debug('Email Files handler: prepareEmails: Finding email addresses');
                    //Check Admin has not stopped emails to customer
                    if (!stopEmailToCustomer) {
                        //Now check if Tech has properly filled the values and not stopped emails to customer
                        Boolean sendServiceReportToCust = Boolean.valueOf(record.get('SVMX_PS_ES_Send_Service_Report_To_Cust__c'));
                        String emailAddressForCust = String.valueOf(record.get('SVMX_PS_ES_Email_To_Customer__c'));
                        System.debug('Email Files handler: prepareEmails: email to Customer: ' + sendServiceReportToCust + ' :: ' + emailAddressForCust);
                        if (sendServiceReportToCust && emailAddressForCust != null && !emailAddressForCust.trim().equals('')) {
                            toEmailAddressCust = emailAddressForCust;
                            if (toEmailAddressCust != null) {
                                checkIfNoToAddress = false;
                            }
                        }
                    }

                    //Check if email needs to be sent to Owner
                    if (!stopEmailToOwner) {
                        ///Now check if Tech has properly filled the values and not stopped emails to Owner
                        Boolean sendServiceReportToOwner = Boolean.valueOf(record.get('SVMX_PS_ES_Send_Service_Report_To_Owner__c'));
                        System.debug('Email Files handler: prepareEmails: email to Owner: ' + sendServiceReportToOwner);
                        if (sendServiceReportToOwner) {
                            toOwner = retrieveOwnersEmail(objectAPIName, record);
                            if (toOwner != null) {
                                checkIfNoToAddress = false;
                            }
                        }
                    }

                    //Check if email needs to be sent to contact field on object
                    Boolean sendServiceReportToContact = Boolean.valueOf(record.get('SVMX_PS_ES_Send_Service_ReportTo_Contact__c'));
                    System.debug('Email Files handler: prepareEmails: email to Contact: ' + sendServiceReportToContact);
                    if (!stopEmailToContact && sendServiceReportToContact) {
                        String emailContactField = emailContactFieldMappingSettingsMap.get(objectAPIName);
                        if (emailContactField != null) {
                            toContact = String.valueOf(record.get(emailContactField));

                            String contactEmailField = null;
                            if (emailContactField.endsWith('__c')) {
                                contactEmailField = emailContactField.replace('__c', '__r');
                            } else if (emailContactField.endsWith('Id')) {
                                contactEmailField = emailContactField.replace('Id', '');
                            }

                            Sobject contactObject = record.getSObject(contactEmailField);
                            if (contactObject != null) {
                                String contactEmail = String.valueOf(contactObject.get('Email'));
                                if (contactEmail != null && !contactEmail.trim().equals('')) {
                                    System.debug('Email Files handler: Found Contact Email - ' + contactEmail);
                                    toContact = contactEmail;
                                } else {
                                    System.debug('Email Files handler: Could not Found Contact Email, Use Contact Id - ' + toContact);
                                }
                            } else {
                                System.debug('Email Files handler: Could not Found Contact Object, Use Contact Id - ' + toContact);
                            }

                            if (toContact != null) {
                                checkIfNoToAddress = false;
                            }
                        } else {
                            System.debug('Email Files handler: Unable to find Contact Mapping');
                        }
                    }

                    //Check Admin has not stopped emails to additional people
                    if (!stopEmailToAdditional) {
                        //Now check if Tech has properly filled the values and not stopped emails to additional people
                        Boolean sendServiceReportToAdditional = Boolean.valueOf(record.get('SVMX_PS_ES_Send_To_Additional_People__c'));
                        String emailAddressForAdditional = String.valueOf(record.get('SVMX_PS_ES_Email_To_Additional_People__c'));
                        System.debug('Email Files handler: prepareEmails: email to Additional: ' + sendServiceReportToAdditional + ' :: ' + emailAddressForAdditional);
                        if (sendServiceReportToAdditional && emailAddressForAdditional != null
                                && !emailAddressForAdditional.trim().equals('')) {
                            additonalEmails = getCommaSeperatedValues(emailAddressForAdditional);

                            if (additonalEmails != null && additonalEmails.size() > 0) {
                                checkIfNoToAddress = false;
                            }
                        }
                    }

                    //Checks if send to default email address is needed. Validates the default email address field and Sets toBackend Address field if Validation comes back as true.
                    if (sendToDefaultEmailAddress && defaultEmailAddress != null && !defaultEmailAddress.trim().equals('')) {
                        toBackendAddress = defaultEmailAddress;
                        checkIfNoToAddress = false;
                    }

                    if (checkIfNoToAddress) {
                        System.debug('Email Files handler: No To Address found for sending ContentVersion.' +
                                'Hence do not send the email for file - ' + fileRecord.Id);
                        continue;
                    }

                    //get all BCC Email Address
                    if (!stopBCC) {
                        bccAddressSet = getAllBCCAddresses(record, fileRecord.Owner.Email, objectAPIName);
                    }

                    //get all CC Email Address
                    if (!stopCC) {
                        ccAddressSet = getAllCCAddresses(record, fileRecord.Owner.Email, objectAPIName);
                    }

                    System.debug('Email Files handler: Email Template Name to be used -' + emailTemplateName);
                    System.debug('Email Files handler: List of Templates available ' + emailTemplateMap);

                    // Construct the Email Message
                    Messaging.SingleEmailMessage message = null;
                    EmailTemplate baseTemplate = null;

                    if (emailTemplateName != null && !emailTemplateName.trim().equals('')) {
                        baseTemplate = emailTemplateMap.get(emailTemplateName);
                    }

                    if (baseTemplate != null) {
                        System.debug('Email Files handler: Create Dummy Email using template : ' + baseTemplate.Name);
                        message = new Messaging.SingleEmailMessage();
                        message.setTemplateId(baseTemplate.Id);
                        message.setTargetObjectId(defaultContactID);
                        message.setEntityAttachments(new Id[] { fileRecord.Id });
                        message.setSaveAsActivity(false);
                        message.setWhatId(linkedEntityId);

                        // Send the emails in a transaction, then roll it back in order to use the template with external email addresses
                        // This will count against DML limits so we must be certain that an iPad/offline user will sync (insert/update)
                        // no more than 75 Service Report files in a single sync.
                        if (!Test.isRunningTest()) {
                            Savepoint sp = Database.setSavepoint();
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
                            Database.rollback(sp);
                        }

                    }

                    //Array to store all cc Addresses
                    String[] ccAddresses = null;
                    //Array to store all Bcc Addresses
                    String[] bccAddresses = null;

                    //Get all Cc Address
                    if (ccAddressSet != null && !ccAddressSet.isEmpty()) {
                        System.debug('Email Files handler: get All Cc Addresses');
                        ccAddresses = new List<String> ();
                        ccAddresses.addAll(ccAddressSet);
                    }

                    //Get all Bcc Address
                    if (bccAddressSet != null && !bccAddressSet.isEmpty()) {
                        System.debug('Email Files handler: get All Bcc Addresses');
                        bccAddresses = new List<String> ();
                        bccAddresses.addAll(bccAddressSet);
                    }

                    //Check if mails need to be grouped or not
                    if (groupEmails) {
                        System.debug('Email Files handler: Group All Emails');
                        //If yes, then send a single emails
                        //Array to store all To Addresses
                        String[] toAddresses = new List<String> ();
                        //Get all To Address
                        toAddresses = new List<String> ();
                        if (toEmailAddressCust != null) {
                            toAddresses.add(toEmailAddressCust);
                        }
                        if (toOwner != null) {
                            toAddresses.add(toOwner);
                        }
                        if (toContact != null) {
                            toAddresses.add(toContact);
                        }
                        //Validates toBackendAddress and adds it to the Toaddresses list
                        if (toBackendAddress != null) {
                            toAddresses.add(toBackendAddress);
                        }
                        if (additonalEmails != null && additonalEmails.size() > 0) {
                            toAddresses.addAll(additonalEmails);
                        }
                        System.debug('Email Files handler: To Addresses - ' + toAddresses);
                        //create message
                        Messaging.SingleEmailMessage message1 = createMessage(toAddresses, ccAddresses, bccAddresses, fileRecord.Id, message, orgWideAddress);
                        messagesList.add(message1);
                        Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, toAddresses, ccAddresses,
                                bccAddresses, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                        taskList.add(task);
                    } else {
                        System.debug('Email Files handler: Do not Group Emails');
                        //If no, then create multiple emails
                        //Create message to send to customer and include Bcc and Cc
                        if (toEmailAddressCust != null) {
                            String[] toAddresses = new String[] { toEmailAddressCust };
                            System.debug('Email Files handler: To Customer - ' + toAddresses);
                            Messaging.SingleEmailMessage message1 = createMessage(toAddresses, ccAddresses, bccAddresses, fileRecord.Id, message, orgWideAddress);
                            messagesList.add(message1);
                            Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, toAddresses, ccAddresses,
                                    bccAddresses, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                            taskList.add(task);
                        }
                        //Create message to send to owner
                        if (toOwner != null) {
                            String[] toAddresses = new String[] { toOwner };
                            System.debug('Email Files handler: To Owner - ' + toAddresses);
                            Messaging.SingleEmailMessage message1 = createMessage(toAddresses, null, null, fileRecord.Id, message, orgWideAddress);
                            messagesList.add(message1);
                            Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, toAddresses, null,
                                    null, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                            taskList.add(task);
                        }
                        //Creates seperate message to backend address
                        if (toBackendAddress != null) {
                            String[] toAddresses = new String[] { toBackendAddress };
                            System.debug('Email Files handler: To Backend Address - ' + toAddresses);
                            Messaging.SingleEmailMessage message1 = createMessage(toAddresses, null, null, fileRecord.Id, message, orgWideAddress);
                            messagesList.add(message1);
                            Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, toAddresses, null,
                                    null, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                            taskList.add(task);
                        }
                        //Create message to send to contact
                        if (toContact != null) {
                            String[] toAddresses = new String[] { toContact };
                            System.debug('Email Files handler: To Contact - ' + toAddresses);
                            Messaging.SingleEmailMessage message1 = createMessage(toAddresses, null, null, fileRecord.Id, message, orgWideAddress);
                            messagesList.add(message1);
                            Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, toAddresses, null,
                                    null, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                            taskList.add(task);
                        }
                        //Create message to send to additional email addresses
                        if (additonalEmails != null && additonalEmails.size() > 0) {
                            System.debug('Email Files handler: To additional people - ' + additonalEmails);
                            Messaging.SingleEmailMessage message1 = createMessage(additonalEmails, null, null, fileRecord.Id, message, orgWideAddress);
                            messagesList.add(message1);
                            Task task = createActivityForLogging(fileRecord.OwnerId, linkedEntityId, additonalEmails, null,
                                    null, fileRecord.Title, message1.getPlainTextBody(), message1.getSubject());
                            taskList.add(task);
                        }
                    }
                } else {
                    System.debug('Email Files handler: no Org Wide Address received for File ' + fileRecord.Id + '. Hence cannot send it');
                }
            } else {
                System.debug('Email Files handler: no record received for File ' + fileRecord.Id + '. Hence Ignore');
            }
            //} else {
            //System.debug('Email Files handler: File ' + fileRecord.Id + '. could not load body');
            //}
        } //End of For Loop of Files

        GenericListHolderClass genericListHolder = new GenericListHolderClass(messagesList, taskList);
        return genericListHolder;
    }

    /*****************************************************************************************************************************************
     *  Method Name : createMessage
     *  Parameter   : String[] toAddresses -- Array of To Addresses
     *                String[] ccAddresses -- Array of Cc Addresses
     *                String[] bccAddresses -- Array of Bcc Addresses
     *                Messaging.EmailFileAttachment emailAttachment -- files which needs to be attached to email
     *                Messaging.SingleEmailMessage message -- message loaded with email template
     *                String orgWideAddress  -- Org Wide Address which will be From Address
     *  Returns     : Messaging.SingleEmailMessage -- Message which needs to be sent out
     *  Description : This method creates the Message object to be sent out
     *                This method peforms following tasks for each file
     *                   1. fills org wide address
     *                   2. fills subject and body of message
     *                   3. fills all To, Cc and Bcc email addresses
     *                   4. Based on custom setting 'Save Send Email as Activity'
     *******************************************************************************************************************************************/
    @TestVisible private Messaging.SingleEmailMessage createMessage(String[] toAddresses, String[] ccAddresses, String[] bccAddresses,
            ID currentVersionId, Messaging.SingleEmailMessage message,
            String orgWideAddress) {
        //create a new message
        Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
        //fill from address
        message1.setOrgWideEmailAddressId(orgWideAddress);
        //fill to addresses
        message1.setToAddresses(toAddresses);
        //fill bcc addresses if any
        if (bccAddresses != null && bccAddresses.size() > 0) {
            message1.setBccAddresses(bccAddresses);
        }
        //fill cc addresses if any
        if (ccAddresses != null && ccAddresses.size() > 0) {
            message1.setCcAddresses(ccAddresses);
        }
        ////set attachment in message
        //message1.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });
        // Set entity attachments
        message1.setEntityAttachments(new Id[] { currentVersionId });

        //set the body and Subject
        if (message != null) {
            message1.setSubject(message.getSubject());
            message1.setPlainTextBody(message.getPlainTextBody());
            message1.setHtmlBody(message.getHTMLBody());
        } else {
            message1.setSubject('Work Order Service Report');
            message1.setPlainTextBody('');
            message1.setHtmlBody('');
        }

        //set if emails needs to be saved as activity on record
        if (saveEmailAsActivity) {
            message1.setSaveAsActivity(true);
        } else {
            message1.setSaveAsActivity(false);
        }

        System.debug('Email Files handler: Message created : ' + message1);
        return message1;
    }

    /*****************************************************************************************************************************************
     *  Method Name : getAllBCCAddresses
     *  Parameter   : sObject record -- record to from which to fetch the Bcc addresses
     *                String fileOwner - email address of file owner
     *                String objectAPIName - api name of the object being processed
     *  Returns     : Set<String> -- Set of email addresses which needed to Bcc'ed
     *  Description : Finds all email addresses which need to be Bcc'ed
     *                Uses the flags of Bcc and the record sent to find all email addresses
     *******************************************************************************************************************************************/
    @TestVisible private Set<String> getAllBCCAddresses(sObject record, String fileOwner, String objectAPIName) {
        Set<String> bccAddressList = new Set<String> ();

        //Check if Owner needs to be Cc'ed or not
        Boolean sendReportBccOwner = Boolean.valueOf(record.get('SVMX_PS_ES_Bcc_Owner__c'));
        if (!stopBCCToOwner && sendReportBccOwner) {
            String toOwner = retrieveOwnersEmail(objectAPIName, record);
            if (toOwner != null) {
                bccAddressList.add(toOwner);
            }
        }

        //Check if Current User needs to be CC'ed or not
        Boolean sendReportBccUser = Boolean.valueOf(record.get('SVMX_PS_ES_Bcc_Current_User__c'));
        if (!stopBCCToCurrentUser && sendReportBccUser && fileOwner != null) {
            bccAddressList.add(fileOwner);
        }

        //Check Admin has not stopped Cc'ing to additional people
        if (!stopBCCToAdditional) {
            //Now check if Tech has properly filled the values and not stopped Cc'ing to additional people
            Boolean sendReportBccAdditional = Boolean.valueOf(record.get('SVMX_PS_ES_Bcc_Additional_People__c'));
            String emailAddressForBccAdditional = String.valueOf(record.get('SVMX_PS_ES_Bcc_Email_Additional_People__c'));
            if (sendReportBccAdditional && emailAddressForBccAdditional != null
                    && !emailAddressForBccAdditional.trim().equals('')) {
                List<String> additonalEmails = getCommaSeperatedValues(emailAddressForBccAdditional);
                bccAddressList.addAll(additonalEmails);
            }
        }

        if (bccAddressList.size() > 0) {
            System.debug('Email Files handler: Bcc Addresses : ' + bccAddressList);
        } else {
            System.debug('Email Files handler: No Bcc Addresses');
        }

        return bccAddressList;
    }

    /*****************************************************************************************************************************************
     *  Method Name : getAllCCAddresses
     *  Parameter   : sObject record -- record to from which to fetch the Cc addresses
     *                String fileOwner - email address of file owner
     *                String objectAPIName - api name of the object being processed
     *  Returns     : Set<String> -- Set of email addresses which needed to Cc'ed
     *  Description : Finds all email addresses which need to be Cc'ed
     *                Uses the flags of Cc and the record sent to find all email addresses
     *******************************************************************************************************************************************/
    @TestVisible private Set<String> getAllCCAddresses(sObject record, String fileOwner, String objectAPIName) {
        Set<String> ccAddressList = new Set<String> ();

        //Check if Owner needs to be Cc'ed or not
        Boolean sendReportCcOwner = Boolean.valueOf(record.get('SVMX_PS_ES_Cc_Owner__c'));
        if (!stopCCToOwner && sendReportCcOwner) {
            String toOwner = retrieveOwnersEmail(objectAPIName, record);
            if (toOwner != null) {
                ccAddressList.add(toOwner);
            }
        }

        //Check if Current User needs to be CC'ed or not
        Boolean sendReportCcUser = Boolean.valueOf(record.get('SVMX_PS_ES_Cc_Current_User__c'));
        if (!stopCCToCurrentUser && sendReportCcUser && fileOwner != null) {
            ccAddressList.add(fileOwner);
        }

        //Check Admin has not stopped Cc'ing to additional people
        if (!stopCCToAdditional) {
            //Now check if Tech has properly filled the values and not stopped Cc'ing to additional people
            Boolean sendReportCcAdditional = Boolean.valueOf(record.get('SVMX_PS_ES_Cc_Additional_People__c'));
            String emailAddressForCcAdditional = String.valueOf(record.get('SVMX_PS_ES_Cc_Email_Additional_People__c'));
            if (sendReportCcAdditional && emailAddressForCcAdditional != null
                    && !emailAddressForCcAdditional.trim().equals('')) {
                List<String> additonalEmails = getCommaSeperatedValues(emailAddressForCcAdditional);
                ccAddressList.addAll(additonalEmails);
            }
        }

        if (ccAddressList.size() > 0) {
            System.debug('Email Files handler: Cc Addresses : ' + ccAddressList);
        } else {
            System.debug('Email Files handler: No Cc Addresses');
        }

        return ccAddressList;
    }

    /*****************************************************************************************************************************************
     *  Method Name : createQueryString
     *  Parameter   : String objectAPIName -- API Name of the object
     *                Set<Id> idSet - Set of Ids for which data needs to be fetched
     *                boolean hasRecordType - true if object had any record types
     *  Returns     : String -- query which will be used to fetch data
     *  Description : Creates SOQL Query which will be used to fetch data from the required object.
     *                The fields queried are the various email settings on the object.
     *******************************************************************************************************************************************/
    @TestVisible private String createQueryString(String objectAPIName, Set<Id> idSet, boolean hasRecordType) {
        //Include the Basic Strings
        String queryString = 'SELECT ID, Name, SVMX_PS_ES_Send_Service_Report_To_Cust__c, ' +
                'SVMX_PS_ES_Email_To_Customer__c, SVMX_PS_ES_Send_Service_Report_To_Owner__c, SVMX_PS_ES_Send_Service_ReportTo_Contact__c, ' +
                'SVMX_PS_ES_Email_To_Additional_People__c, SVMX_PS_ES_Send_To_Additional_People__c, ' +
                'SVMX_PS_ES_Cc_Current_User__c,SVMX_PS_ES_Cc_Owner__c,SVMX_PS_ES_Cc_Email_Additional_People__c , ' +
                'SVMX_PS_ES_Cc_Additional_People__c,SVMX_PS_ES_Bcc_Current_User__c,SVMX_PS_ES_Bcc_Owner__c , ' +
                'SVMX_PS_ES_Bcc_Email_Additional_People__c,SVMX_PS_ES_Bcc_Additional_People__c';

        String ownerFieldString = 'OwnerId, Owner.Email';

        String childRelationshipName = childRelationshipNameMap.get(objectAPIName);
        if (childRelationshipName != null && !childRelationshipName.trim().equals('')) {
            ownerFieldString = childRelationshipName + '.OwnerId,' + childRelationshipName + '.Owner.Email';
        }

        queryString += ',' + ownerFieldString;

        //Include contact field if specified
        String emailContactField = emailContactFieldMappingSettingsMap.get(objectAPIName);
        if (emailContactField != null && !emailContactField.trim().equals('')) {
            queryString += ',' + emailContactField;

            String contactEmailField = null;
            if (emailContactField.endsWith('__c')) {
                contactEmailField = emailContactField.replace('__c', '__r.Email');
            } else if (emailContactField.endsWith('Id')) {
                contactEmailField = emailContactField.replace('Id', '.Email');
            }

            if (contactEmailField != null && !contactEmailField.trim().equals('')) {
                queryString += ',' + contactEmailField;
            }
        }

        //Include Record Type field if object has record types
        if (hasRecordType) {
            queryString += ',' + 'RecordTypeId';
        }

        //Include All record Ids
        queryString += ' FROM ' + objectAPIName + ' WHERE ID IN (';
        for (Id idValue : idSet) {
            queryString += '\'' + idValue + '\',';
        }

        //finalize the string
        queryString = queryString.substring(0, queryString.length() - 1);
        queryString += ')';

        System.debug('Email Files handler: Query String : ' + queryString);

        return queryString;
    }

    /*****************************************************************************************************************************************
     *  Method Name : createActivityForLogging
     *  Parameter   : String fileOwnerId -- User Id of the file owner
     *                String workOrderId -- Work Order id for this Task to be associated
     *                String[] toAddresses -- Array of To addresses
     *                String[] ccAddresses -- Array of Cc addresses if any
     *                String[] bccAdddresses -- Array of Bcc addresses if any
     *                String fileName -- Name of the file sent
     *                String body -- Body of the email
     *                String subject -- Subject of the email
     *  Returns     : Task -- tasks which needs to be saved
     *  Description : Creates a salesforce Task to store the email as an "Activity History"
     *******************************************************************************************************************************************/
    @TestVisible private Task createActivityForLogging(String fileOwnerId, String workOrderId, String[] toAddresses, String[] ccAddresses,
            String[] bccAdddresses, String fileName, String body, String subject) {

        String comments = 'To: ' + toAddresses + '\r\n\r\n';

        if (ccAddresses != null && ccAddresses.size() > 0) {
            comments += 'CC: ' + ccAddresses + '\r\n\r\n';
        } else {
            comments += 'CC: ' + '\r\n\r\n';
        }

        if (bccAdddresses != null && bccAdddresses.size() > 0) {
            comments += 'BCC: ' + bccAdddresses + '\r\n\r\n';
        } else {
            comments += 'BCC: ' + '\r\n\r\n';
        }

        comments += 'File attachment: ' + fileName + '\r\n\r\n';
        comments += 'Subject: ' + subject + '\r\n\r\n';
        comments += 'Body: ' + '\r\n\r\n';

        if (body != null) {
            comments += body;
        }

        Task emailTask = new Task();
        emailTask.Type = 'Email';
        emailTask.Status = 'Completed';
        emailTask.ActivityDate = Date.today();
        emailTask.Description = comments;
        emailTask.OwnerId = fileOwnerId;
        emailTask.WhatId = workOrderId;
        emailTask.Subject = 'Email: ' + subject;
        return emailTask;
    }

    /*****************************************************************************************************************************************
     *  Method Name : checkFileExtensionValidity
     *  Parameter   : String fileExtension -- extension of the File
     *  Returns     : boolean -- true if fileExtension is valid else false
     *  Description : Checks if the file extension is valid or name
     *                Extensions supported are mentioned in "EXTENSION SUPPORTED" record in "Email Service Report Setting".
     *******************************************************************************************************************************************/
    @TestVisible private boolean checkFileExtensionValidity(String fileExtension) {
        boolean isFileExtensionValid = false;

        //Check if file name is null
        if (fileExtension != null && !fileExtension.trim().equals('')) {
            //Check if file extension is supported in extension support settings
            for (String extensionSupported : extensionsSupportedList) {
                extensionSupported = extensionSupported.toLowerCase();
                if (fileExtension.toLowerCase().contains(extensionSupported)) {
                    System.debug('Email Files handler: File name extension is valid.');
                    isFileExtensionValid = true;
                    break;
                }
            }
        } else {
            System.debug('Email Files handler: fileExtension is null.');
        }
        if (!isFileExtensionValid) System.debug('Email Files handler: File name extension is invalid. Hence ignore file');

        return isFileExtensionValid;
    }

    /*****************************************************************************************************************************************
     *  Method Name : checkFileNameValidity
     *  Parameter   : String fileName -- Name of the file
     *                String uniqueKey -- Unique key is the combination of Object API Name - Record Type or Object API Name
     *                String objectAPIName - Object API name
     *  Returns     : boolean -- true if file name is valid
     *  Description : This method checks if the file name is valid.
     *                It first finds the valid service report name list
     *                Valid Names are stored in "Email Service Report Name Setting" using object API Name and Record Type Name
     *                If not found, uses the "SERVICE REPORT NAME" record in "Email Service Report Setting"
     *                If found, returns true.
     *******************************************************************************************************************************************/
    @TestVisible private boolean checkFileNameValidity(String fileName, String uniqueKey, String objectAPIName) {

        System.debug('Email Files handler: fileName: ' + fileName + ' | uniqueKey: ' + uniqueKey + ' | objectAPIName ' + objectAPIName);

        boolean isFileNameValid = false;

        //Check if file name is null
        if (fileName != null && !fileName.trim().equals('')) {
            //get valid Service Report Name for this record
            String validServiceReportName = null;
            //check if the address is available for Object-Record Type combination
            if (uniqueKey != null && !uniqueKey.trim().equals('')) {
                validServiceReportName = emailServiceReportNameSettingMap.get(uniqueKey);
            }
            //if not, check if the address is available for Object
            if (validServiceReportName == null) {
                validServiceReportName = emailServiceReportNameSettingMap.get(objectAPIName);
            }
            //if still not available, use default
            if (validServiceReportName == null) {
                validServiceReportName = serviceReportName;
            }

            List<String> validServiceReportNameList = getCommaSeperatedValues(validServiceReportName);
            System.debug('Email Files handler: validServiceReportNameList: ' + validServiceReportNameList);

            //Check if file name is supported in Service Report Name settings
            for (String sampleReportName : validServiceReportNameList) {
                if (fileName.contains(sampleReportName)) {
                    isFileNameValid = true;
                    System.debug('Email Files handler: File name ' + fileName + ' is valid.');
                    break;
                }
            }
        } else {
            System.debug('Email Files handler: File name is null. Hence ignore file.');
        }
        if (!isFileNameValid) System.debug('Email Files handler: File name is not valid. Hence ignore file.');

        return isFileNameValid;
    }

    /*****************************************************************************************************************************************
     *  Method Name : checkFileObjectValidity
     *  Parameter   : String linkEntityName -- API Name of the linked entity of the file
     *  Returns     : boolean -- true if file's link entity Object is supported else false
     *  Description : This method checks if the file's linked entity object is valid or not
     *                It checks that the name of linked entity object of file is mentioned in "OBJECT SUPPORTED" record in "Email Service Report Setting".
     *                If yes, returns true.
     *******************************************************************************************************************************************/
    @TestVisible private boolean checkFileObjectValidity(String linkedEntityName) {
        boolean isFileObjectValid = false;

        if (linkedEntityName != null && !linkedEntityName.trim().equals('')) {
            for (String objectSupported : objectsSupportedList) {
                if (linkedEntityName.equals(objectSupported)) {
                    isFileObjectValid = true;
                    System.debug('Email Files handler: File object name is valid.');
                    break;
                }
            }
        } else {
            System.debug('Email Files handler: File object name is null.');
        }
        if (!isFileObjectValid) System.debug('Email Files handler: File object name is not valid. Hence ignore file.');

        return isFileObjectValid;
    }

    /*****************************************************************************************************************************************
     *  Method Name : checkIfEmailServiceReportFunctionalityIsActive
     *  Parameter   : --
     *  Returns     : boolean -- true if Email Functionality is active else false
     *  Description : Checks the ServiceMax Service Register to see if the Service Report Functionality is Active.
     *******************************************************************************************************************************************/
    @TestVisible private boolean checkIfEmailServiceReportFunctionalityIsActive() {
        boolean isActive = false;
        List<SVMX_PS_Services_Register__c> serviceRegistryList = SVMX_PS_Services_Register__c.getAll().values();
        if (serviceRegistryList != null && serviceRegistryList.size() > 0) {
            for (SVMX_PS_Services_Register__c item : serviceRegistryList) {
                if (item.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)) {
                    isActive = item.SVMX_PS_Is_Active__c;
                    break;
                }
            }
        }
        return isActive;
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveEmailServiceSetting
     *  Parameter   : --
     *  Returns     : --
     *  Description : Get All Email Service Report Settings which control the email functionality and store it in global variables
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveEmailServiceSetting() {
        List<SVMX_PS_ES_Service_Report_Settings__c> emailServiceReportSettings = SVMX_PS_ES_Service_Report_Settings__c.getAll().values();

        if (emailServiceReportSettings != null) {
            for (SVMX_PS_ES_Service_Report_Settings__c emailService : emailServiceReportSettings) {
                if (emailService.Name.equals(DEFAULT_CONTACT_ID)) {
                    defaultContactID = emailService.SVMX_PS_ES_Text_Value__c;
                    validateDummyContact(emailService);
                }
                else if (emailService.Name.equals(EXTENSIONS_SUPPORTED)) {
                    String extensionsSupported = emailService.SVMX_PS_ES_Text_Value__c;
                    System.debug('Email Files handler: extensionsSupported  -' + extensionsSupported);
                    extensionsSupportedList = getCommaSeperatedValues(extensionsSupported);
                }
                else if (emailService.Name.equals(OBJECTS_SUPPORTED)) {
                    String objectsSupported = emailService.SVMX_PS_ES_Text_Value__c;
                    System.debug('Email Files handler: objectsSupported  -' + objectsSupported);
                    objectsSupportedList = getCommaSeperatedValues(objectsSupported);
                }
                else if (emailService.Name.equals(SERVICE_REPORT_NAME)) {
                    serviceReportName = emailService.SVMX_PS_ES_Text_Value__c;
                    System.debug('Email Files handler: serviceReportName  -' + serviceReportName);
                }
                else if (emailService.Name.equals(DEFAULT_EMAIL_ADDRESS)) {
                    defaultEmailAddress = emailService.SVMX_PS_ES_Text_Value__c;
                }
                else if (emailService.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)) {
                    sendToDefaultEmailAddress = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_BCC)) {
                    stopBCC = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)) {
                    stopBCCToAdditional = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_BCC_TO_CURRENTUSER)) {
                    stopBCCToCurrentUser = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_BCC_TO_OWNER)) {
                    stopBCCToOwner = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_CC)) {
                    stopCC = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)) {
                    stopCCToAdditional = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_CC_TO_CURRENT_USER)) {
                    stopCCToCurrentUser = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_CC_TO_OWNER)) {
                    stopCCToOwner = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_EMAIL)) {
                    stopEmail = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)) {
                    stopEmailToAdditional = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_EMAIL_TO_CONTACT)) {
                    stopEmailToContact = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_EMAIL_TO_CUSTOMER)) {
                    stopEmailToCustomer = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(STOP_EMAIL_TO_OWNER)) {
                    stopEmailToOwner = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(GROUP_EMAILS)) {
                    groupEmails = emailService.SVMX_PS_ES_Value__c;
                }
                else if (emailService.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)) {
                    saveEmailAsActivity = emailService.SVMX_PS_ES_Value__c;
                }
            }
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveChildRelationShipName
     *  Parameter   : --
     *  Returns     : --
     *  Description : For all objects supported, if there exists a master-detail relationship, get that so that owner field is queried accordingly
     *                This is done by giving a describe call for all objects supported.
     *                Then we find all fields, check if it is a reference and has relationship order of 1.
     *                If we get that, store the relationship name in the map.
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveChildRelationShipName() {
        childRelationshipNameMap = new Map<String, String> ();

        Schema.DescribeSobjectResult[] describeSobjectList = Schema.describeSObjects(objectsSupportedList);
        for (Schema.DescribeSobjectResult sObjectDescribe : describeSobjectList) {
            Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap();
            for (Schema.SObjectField sfield : fieldMap.Values()) {
                Schema.DescribeFieldResult dfield = sfield.getDescribe();
                if (dfield.getType() == Schema.DisplayType.Reference && dfield.getRelationshipOrder() != null && dfield.getRelationshipOrder() == 0) {
                    childRelationshipNameMap.put(sObjectDescribe.getName(), dfield.getRelationshipName());
                    break;
                }
            }
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : validateDummyContact
     *  Parameter   : SVMX_PS_ES_Service_Report_Settings__c emailService - Email Functionality settings in Custom Settings.
     *  Returns     : --
     *  Description : Makes sure that a dummy contact exists and is not empty. If not Creates a dummyContact.
     *  Salesforce Limits: Consumes 1 SOQL query on the Contact table.
     *******************************************************************************************************************************************/
    @TestVisible private void validateDummyContact(SVMX_PS_ES_Service_Report_Settings__c emailService) {
        if (defaultContactID != null && !defaultContactID.trim().equals('')) {
            List<Contact> contactList = [Select Id, Name From Contact Where Id = :defaultContactID];
            if (contactList != null && contactList.size() > 0) {
                System.debug('Email Files handler: Default contact id is valid. Hence return.');
                return;
            }
        }

        try {
            System.debug('Email Files handler: Create new default contact');
            Contact dummyContact = new Contact(FirstName = 'DO NOT DELETE',
                    LastName = 'DUMMY CONTACT',
                    Email = 'donotdelete@gmail.com',
                    Description = 'Enables email service report functionality');
            insert dummyContact;
            System.debug('Email Files handler: inserted new default contact');
            emailService.SVMX_PS_ES_Text_Value__c = dummyContact.Id;
            update emailService;
            System.debug('Email Files handler: updated custom setting with new default contact');
            defaultContactID = dummyContact.Id;
            System.debug('Email Files handler: New default contact id : ' + defaultContactID);
        } catch(Exception smaxException) {
            System.debug('Email Files handler: could not create new contact. ' + smaxException.getMessage());
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveOrgWideAddresses
     *  Parameter   : --
     *  Returns     : --
     *  Description : Gets all Org Wide Addresses from custom settings and store it in global variables.
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveOrgWideAddresses() {
        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> emailOrgWideAddressSettingsList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getAll().values();
        emailOrgWideAddressSettingsMap = new Map<String, String> ();

        if (emailOrgWideAddressSettingsList != null && emailOrgWideAddressSettingsList.size() > 0) {
            for (SVMX_PS_ES_Org_Wide_Address_Settings__c emailOrgWideSetting : emailOrgWideAddressSettingsList) {
                if (emailOrgWideSetting.SVMX_PS_ES_Object_API_Name__c != null && !emailOrgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailOrgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null && !emailOrgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('')) {
                    String keyValue = null;
                    if (emailOrgWideSetting.SVMX_PS_ES_Record_Type_Name__c != null && !emailOrgWideSetting.SVMX_PS_ES_Record_Type_Name__c.trim().equals('')) {
                        keyValue = emailOrgWideSetting.SVMX_PS_ES_Object_API_Name__c + '-' + emailOrgWideSetting.SVMX_PS_ES_Record_Type_Name__c;
                    } else {
                        keyValue = emailOrgWideSetting.SVMX_PS_ES_Object_API_Name__c;
                    }
                    emailOrgWideAddressSettingsMap.put(keyValue, emailOrgWideSetting.SVMX_PS_ES_Org_Wide_Address__c);
                }
                if (emailOrgWideSetting.SVMX_PS_ES_Default__c) {
                    defaultOrgWideAddressID = emailOrgWideSetting.SVMX_PS_ES_Org_Wide_Address__c;
                }
            }
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveContactFieldMapping
     *  Parameter   : --
     *  Returns     : --
     *  Description : Gets all Contact Field Mapping Settings from custom settings and stores in global variables
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveContactFieldMapping() {
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> emailContactFieldMappingSettingsList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getAll().values();
        emailContactFieldMappingSettingsMap = new Map<String, String> ();

        if (emailContactFieldMappingSettingsList != null && emailContactFieldMappingSettingsList.size() > 0) {
            for (SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : emailContactFieldMappingSettingsList) {
                if (emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('')) {
                    emailContactFieldMappingSettingsMap.put(emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c,
                            emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c);
                }
            }
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveEmailTemplateSettings
     *  Parameter   : --
     *  Returns     : --
     *  Description : Gets all Email Template Settings from custom settings and stores in global variables
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveEmailTemplateSettings() {
        List<SVMX_PS_ES_Template_Settings__c> emailTemplateSettingsList = SVMX_PS_ES_Template_Settings__c.getAll().values();
        emailTemplateSettingsMap = new Map<String, String> ();
        Set<String> emailTemplatesNameSet = new Set<String> ();

        if (emailTemplateSettingsList != null && emailTemplateSettingsList.size() > 0) {
            for (SVMX_PS_ES_Template_Settings__c emailTemplateSetting : emailTemplateSettingsList) {
                if (emailTemplateSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailTemplateSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')) {
                    String keyValue = emailTemplateSetting.SVMX_PS_ES_Object_API_Name__c;
                    if (emailTemplateSetting.SVMX_PS_ES_Record_Type_Name__c != null
                            && !emailTemplateSetting.SVMX_PS_ES_Record_Type_Name__c.trim().equals('')) {
                        keyValue += '-' + emailTemplateSetting.SVMX_PS_ES_Record_Type_Name__c;
                    }
                    if (emailTemplateSetting.SVMX_PS_ES_Service_Report_Name__c != null
                            && !emailTemplateSetting.SVMX_PS_ES_Service_Report_Name__c.trim().equals('')) {
                        keyValue += '-#-' + emailTemplateSetting.SVMX_PS_ES_Service_Report_Name__c;
                    }
                    emailTemplateSettingsMap.put(keyValue, emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c);
                    emailTemplatesNameSet.add(emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c);
                }
                if (emailTemplateSetting.SVMX_PS_ES_Default__c) {
                    defaultEmailTemplateID = emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c;
                }
            }
            retrieveAllEmailTemplate(emailTemplatesNameSet);
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveEmailServiceReportNameSettings
     *  Parameter   : --
     *  Returns     : --
     *  Description : Gets all Email Service Report Name settings from custom settings and store it in global variables
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveEmailServiceReportNameSettings() {
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        emailServiceReportNameSettingMap = new Map<String, String> ();

        if (emailServiceReportSettingsList != null && emailServiceReportSettingsList.size() > 0) {
            for (SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList) {
                if (emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')) {
                    String keyValue = null;
                    if (emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c != null
                            && !emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c.trim().equals('')) {
                        keyValue = emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c + '-'
                                + emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c;
                    } else {
                        keyValue = emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c;
                    }
                    emailServiceReportNameSettingMap.put(keyValue, emailServiceReportNameSetting.SVMX_PS_ES_Service_Report_Name__c);
                }
            }
        }
    }


    /*****************************************************************************************************************************************
     *  Method Name : retrieveAllEmailTemplate
     *  Parameter   : Set<String> emailTemplatesNameSet: Set of template names from the Custom Settings
     *  Returns     : --
     *  Description : Gets all Email Templates and store it in global variables
     *******************************************************************************************************************************************/
    @TestVisible private void retrieveAllEmailTemplate(Set<String> emailTemplatesNameSet) {
        emailTemplateMap = new Map<String, EmailTemplate> ();

        // Load email template used for all e-mails
        System.debug('Email Files handler: Get Email Templates for email templates : ' + emailTemplatesNameSet);
        List<EmailTemplate> emailTemplateBaseList = [Select Id, Name, Subject, Body, HtmlValue, DeveloperName
        from EmailTemplate where DeveloperName IN :emailTemplatesNameSet];
        if (emailTemplateBaseList != null) {
            for (EmailTemplate emailTemplate : emailTemplateBaseList) {
                emailTemplateMap.put(emailTemplate.DeveloperName, emailTemplate);
            }
        }
    }

    /*****************************************************************************************************************************************
     *  Method Name : getCommaSeperatedValues
     *  Parameter   : String valueString -- value string to be processed
     *  Returns     : List<String>: List of values
     *  Description : Processes the valueString passed, splits the string by comma and returns the list of all strings which are seperated by comma
     *******************************************************************************************************************************************/
    @TestVisible private List<String> getCommaSeperatedValues(String valueString) {
        List<String> valueStringList = new List<String> ();
        if (valueString != null && !valueString.trim().equals('')) {
            valueStringList = valueString.split(',');
        }

        if (valueStringList.size() <= 0) {
            valueStringList.add(valueString);
        }

        System.debug('Email Files handler: After seperating commas, Names found :' + valueStringList.size());
        System.debug('Email Files handler: After seperating commas, Names are :' + valueStringList);
        return valueStringList;
    }

    /*****************************************************************************************************************************************
     *  Method Name : retrieveOwnersEmail
     *  Parameter   : String objectAPIName -- API name of the object in process
     *                sObject record -- the actual record
     *  Returns     : String -- Owner email address found from Child's Parent.
     *  Description : Owner email address found from record or the record's Master record if in a Master-Detail relationship
     *******************************************************************************************************************************************/
    @TestVisible private String retrieveOwnersEmail(String objectAPIName, sObject record) {
        String toOwner = null;
        Sobject ownerObject = null;

        String childRelationshipName = childRelationshipNameMap.get(objectAPIName);
        if (childRelationshipName != null && !childRelationshipName.trim().equals('')) {
            Sobject parentObject = record.getSObject(childRelationshipName);
            ownerObject = parentObject.getSObject('Owner');
        } else {
            toOwner = String.valueOf(record.get('OwnerId'));
            ownerObject = record.getSObject('Owner');
        }

        if (ownerObject != null) {
            String ownerEmail = String.valueOf(ownerObject.get('Email'));
            if (ownerEmail != null && !ownerEmail.trim().equals('')) {
                System.debug('Email Files handler: Found Owner Email - ' + ownerEmail);
                toOwner = ownerEmail;
            } else {
                System.debug('Email Files handler: Could not Found Owner Email, Use Owner Id - ' + toOwner);
            }
        } else {
            System.debug('Email Files handler: Could not Found Owner Object, Use Owner Id - ' + toOwner);
        }
        return toOwner;
    }

    /*****************************************************************************************************************************************
     *  InnerClass Name : GenericListHolderClass
     *  Description : class to hold message list and task list. This will be used to send from prepare emails method
     *******************************************************************************************************************************************/
    @TestVisible private class GenericListHolderClass {
        //List to store all email message prepared
        List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage> ();

        //List to store all email message prepared
        List<Task> taskList = new List<Task> ();

        //constructor for initiliazation fo lists
        GenericListHolderClass(List<Messaging.SingleEmailMessage> messagesList, List<Task> taskList) {
            this.messagesList = messagesList;
            this.taskList = taskList;
        }

        //method to return messages list
        List<Messaging.SingleEmailMessage> getMessageList() {
            return this.messagesList;
        }

        //method to return tasks list
        List<Task> getTaskList() {
            return this.taskList;
        }
    }
}
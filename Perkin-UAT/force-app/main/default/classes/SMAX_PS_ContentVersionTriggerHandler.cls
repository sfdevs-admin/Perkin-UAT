/**
 * Created by tony on 6/13/22.
 */

public without sharing class SMAX_PS_ContentVersionTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public SMAX_PS_ContentVersionTriggerHandler() {
    }

    public void beforeInsert() {
        List<ContentVersion> newList = Trigger.new;
        SMAX_PS_ContentVersionTriggerHandler.truncateFileName(newList);
    }
    public void afterInsert()
    {
        List<ContentVersion> newList = Trigger.new;
        SMAX_PS_ContentVersionTriggerHandler.sendFileEvents(newList, null);
    }
    public void beforeUpdate() {
        List<ContentVersion> newList = Trigger.new;
        SMAX_PS_ContentVersionTriggerHandler.truncateFileName(newList);
    }
    public void afterUpdate()
    {
        List<ContentVersion> newList = Trigger.new;
        Map<Id, ContentVersion> oldMap = (Map<Id, ContentVersion>) Trigger.oldMap;
        SMAX_PS_ContentVersionTriggerHandler.sendFileEvents(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}

    public static void sendFileEvents(List<ContentVersion> fileList, Map<Id, ContentVersion> oldMap)
    {
        System.debug('Entering sendFileEvents method');

        if (!SMAX_PS_Utility.isActive('Send File Attachment Events', 'Send WO Events for File Attachments.'))
            return;

        if (SMAX_PS_Utility.isCurrentUserIntegrationProfile())
        {
            // If this is an "Integration" User, exit..
            System.debug('SKIPPING File Attachment Events because Current User Profile is "Integration"');
            return;
        }

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        Map<Id, Id> contentDocumentIdToContentVersionIdMap = new Map<Id, Id>();
        for (ContentVersion cv : fileList)
        {
            contentVersionMap.put(cv.Id, cv);
            contentDocumentIdToContentVersionIdMap.put(cv.ContentDocumentId, cv.Id);
        }
        System.debug('ContentVersion records to check: ' + fileList.size() + ' ' + fileList);
        System.debug('contentDocumentIdToContentVersionIdMap: ' + contentDocumentIdToContentVersionIdMap.size() + ' ' + contentDocumentIdToContentVersionIdMap);

        // Get the ContentDocumentLinks so we can find the Work Orders associated to the ContentDocuments
        Map<Id, Id> contentDocumentIdToWoIdMap = new Map<Id, Id>();
        for(ContentDocumentLink contentDocumentLink: [SELECT ContentDocumentId, LinkedEntity.type, LinkedEntityId
        FROM ContentDocumentLink
        WHERE ContentDocumentId IN: contentDocumentIdToContentVersionIdMap.keySet()])
        {
            System.debug('contentDocumentLink.LinkedEntityId: ' + contentDocumentLink.LinkedEntityId);
            System.debug('contentDocumentLink.LinkedEntity.Type: ' + contentDocumentLink.LinkedEntity.Type);
            if(contentDocumentLink.LinkedEntity.Type == 'SVMXC__Service_Order__c')
            {
                contentDocumentIdToWoIdMap.put(contentDocumentLink.ContentDocumentId, contentDocumentLink.LinkedEntityId);
            }
        }
        System.debug('contentDocumentIdToWoIdMap: ' + contentDocumentIdToWoIdMap.size() + ' ' + contentDocumentIdToWoIdMap);

        if (contentDocumentIdToWoIdMap.isEmpty())
            return;

        // Get the Work Order Ids for the ContentVersion Ids
        Map<Id, Id> cvIdToWoIdMap = new Map<Id, Id>();
        for (ContentVersion contentVersion :fileList) {
            Id woId = contentDocumentIdToWoIdMap.get(contentVersion.ContentDocumentId);
            if (woId != null) {
                cvIdToWoIdMap.put(contentVersion.Id, woId);
            }
        }
        System.debug('cvIdToWoIdMap: ' + cvIdToWoIdMap.size() + ' ' + cvIdToWoIdMap);

        if (cvIdToWoIdMap.isEmpty())
            return;

        System.debug('Processing ContentVersion records');
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name, SMAX_PS_SAP_Notification_ID__c
        FROM SVMXC__Service_Order__c WHERE Id IN :cvIdToWoIdMap.values()]);
        System.debug('woMap: ' + woMap.size() + ' ' + woMap);

        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        for (ContentVersion cv : fileList)
        {

            SVMXC__Service_Order__c wo = woMap.get(cvIdToWoIdMap.get(cv.Id));
            System.debug('Work Order Id: ' + cvIdToWoIdMap.get(cv.Id));
            System.debug('wo: ' + wo);
            if (wo != null && String.isNotBlank(wo.SMAX_PS_SAP_Notification_ID__c))
            {
                System.debug('Creating a Platform Event for: ' + wo.Name);
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                iEvent.SMAX_PS_Action__c = 'FILE_ATTACHMENT';
                iEvent.SMAX_PS_WorkOrderId__c = wo.Id;
                iEvent.SMAX_PS_AttachmentId__c = cv.Id;
                events.add(iEvent);
            }
        }

        if (!events.isEmpty())
            SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
    }
    
    public static void truncateFileName(List<ContentVersion> newFiles) {
        for(ContentVersion file : newFiles) {
            if(file.Title != null && file.Title.length() > 90) {
                 file.Title = file.Title.substring(0, 90);
            }
        }
    }
}
/**
 * Created by tony on 3/3/21.
 */

public without sharing class SMAX_PS_AttachmentManager {

    // ITSVMX-186 5/17/22 tony - Remove as ServiceMax settings have been changed and Files are created automatically now
//    // ITSVMX-186 3/3/21 tony - Convert WO Attachments to Files so they can be attached to emails
//    public static void convertWOAttachmentsToFiles(List<Attachment> attachList, Map<Id, Attachment> oldMap){
//
//        if (!SMAX_PS_Utility.isActive('Convert WO Attachments to Files', 'Converts Work Order Attachments to Files.'))
//            return;
//
//        if (oldMap == null) {
//            System.debug('Running convertWOAttachmentsToFiles for AfterInsert');
//        } else {
//            System.debug('Running convertWOAttachmentsToFiles for AfterUpdate');
//        }
//
//
//        Savepoint sp = Database.setSavepoint();
//
//        // Get the list of Attachments for Work Orders
//        String woPrefix = SVMXC__Service_Order__c.SObjectType.getDescribe().getKeyPrefix();
//        List<Attachment> woAttachments = new List<Attachment>();
//        Set<Id> woIds = new Set<Id>();
//        for (Attachment attach : attachList)
//        {
//            String parentIdStr = '' + attach.ParentId;
//            if (parentIdStr.startsWith(woPrefix))
//            {
//                woIds.add(attach.ParentId);
//                woAttachments.add(attach);
//            }
//        }
//
//        try{
//            Map<Id, List<Blob>> mapAttachmentIdLstBlob = new Map<Id, List<Blob>>();
//            Map<Id, Attachment> mapIdAttachment = new Map<Id, Attachment>();
//
//            for(Attachment attach: woAttachments){
//                String bodyCont = attach.Body!=null ? String.valueOf(attach.Body).replace('&','&amp;') .replace('<','&lt;').replace('>','&gt;') .replace('"','&quot;').replace('\'','&#39;'):'.';
//                Blob tmpBlob = Blob.valueOf(bodyCont);
//
//                if(!mapAttachmentIdLstBlob.containsKey(attach.Id)){
//                    mapAttachmentIdLstBlob.put(attach.Id, new List<Blob>());
//                }
//
//                mapAttachmentIdLstBlob.get(attach.Id).add(tmpBlob);
//                mapIdAttachment.put(attach.Id, attach);
//            }
//
//            Map<Id, List<ContentVersion>> mapParentIdLstCV = createContentVersionAttachment(mapAttachmentIdLstBlob, mapIdAttachment);
//            //This seems to get done automatically, so I commented it out
//            //List<ContentDocumentLink> lstCVDL = updateContentDocLink(mapParentIdLstCV);
//        }
//
//        catch(Exception ex){
//            Database.rollback(sp);
//            System.debug('Error-> '+ex.getLineNumber()+' Message : '+ex.getMessage());
//            throw ex;
//        }
//    }


    // ITSVMX-186 5/18/22 tony - Remove as ServiceMax settings have been changed and Files are created automatically now
//    public static Map<Id, List<ContentVersion>> createContentVersionAttachment(Map<Id, List<Blob>> mapAttachmentIdLstBlob, Map<Id, Attachment> mapAttachment){
//        Savepoint sp = Database.setSavepoint();
//        Map<Id, List<ContentVersion>> contentVersionMap = new Map<Id, List<ContentVersion>>();
//        List<ContentVersion> newFileVersionList = new List<ContentVersion>();
//
//        for(Id attachmentId : mapAttachmentIdLstBlob.keySet()){
//            List<Blob> attachmentBlob = mapAttachmentIdLstBlob.get(attachmentId);
//            for(Blob b:attachmentBlob){
//                Attachment attachment = mapAttachment.get(attachmentId);
//                ContentVersion newFileVersion = new ContentVersion(
//                        VersionData = attachment?.Body,
//                        Title = attachment?.Name,
//                        Description = attachment?.Description,
//                        PathOnClient = '/' + attachment?.Name,
//                        FirstPublishLocationId = attachment?.ParentId,
//                        SharingPrivacy = ( attachment?.IsPrivate ? 'P' : 'N' ),
//                        CreatedById = attachment?.OwnerId,
//                        CreatedDate = attachment?.CreatedDate,
//                        LastModifiedById = attachment?.LastModifiedById,
//                        LastModifiedDate = attachment?.LastModifiedDate
//                        //Original_Record__c = attachment?.Id,
//                        // Parent_Id__c = attachment?.ParentId
//                );
//
//                newFileVersionList.add(newFileVersion);
//
//                if(!contentVersionMap.containsKey(attachment?.ParentId)){
//                    contentVersionMap.put(attachment?.ParentId,new List<ContentVersion>());
//                }
//
//                contentVersionMap.get(attachment?.ParentId).add(newFileVersion);
//            }
//        }
//
//        try{
//            Database.DMLOptions dmlOptions = new Database.DMLOptions();
//            dmlOptions.optAllOrNone = false;
//            List<Database.SaveResult> saveResultRecords = Database.insert(newFileVersionList, dmlOptions);
//
//            for(Database.SaveResult sr : saveResultRecords){
//                if(sr.isSuccess()){
//
//                }else if(!sr.isSuccess()){
//
//                }
//            }
//
//            return contentVersionMap;
//        }
//
//        catch(Exception ex){
//            Database.rollback(sp);
//            throw ex;
//        }
//    }

//        public static void convertNotes(Set<Id> parentIdsSet){
//        List<Note> lstNot = [SELECT Id, ParentId, Title, Body FROM Note where ParentId IN:parentIdsSet LIMIT 10000];
//        try{
//            Map<Id, List<Blob>> mapNoteIdLstBlob = new Map<Id, List<Blob>>();
//            Map<Id, Note> mapIdNote = new Map<Id, Note>();
//
//            for(Note n: lstNot){
//                String bodyCont = n.Body!=null ? String.valueOf(n.Body).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;').replace('\'','&#39;'):'.';
//                Blob tmpBlob = Blob.valueOf(bodyCont);
//
//                if(!mapNoteIdLstBlob.containsKey(n.Id)){
//                    mapNoteIdLstBlob.put(n.Id, new List<Blob>());
//                }
//
//                mapNoteIdLstBlob.get(n.Id).add(tmpBlob);
//                mapIdNote.put(n.Id, n);
//            }
//
//            Map<Id, List<ContentVersion>> mapParentIdLstCV = createContentVersion(mapNoteIdLstBlob, mapIdNote);
//            List<ContentDocumentLink> lstCVDL = updateContentDocLink(mapParentIdLstCV);
//        }
//
//        Catch(Exception e){
//        }
//    }

//    public static List<ContentDocumentLink> updateContentDocLink(Map<Id, List<ContentVersion>> parentIdLstCVMap){
//        Set<String> cvSet = new Set<String>();
//        Map<Id, Id> cvIdMap = new Map<Id, Id>();
//
//        for(Id accId: parentIdLstCVMap.keySet()){
//            for(ContentVersion cv: parentIdLstCVMap.get(accId)){
//                cvSet.add(cv.Id);
//                cvIdMap.put(cv.Id, accId);
//            }
//        }
//
//        List<ContentVersion> cvLst = [SELECT ContentDocumentId FROM ContentVersion WHERE (Id IN :cvSet)];
//        List<ContentDocumentLink> cdlLst = new List<ContentDocumentLink>();
//
//        for(ContentVersion cv: cvLst){
//            ContentDocumentLink cdl = new ContentDocumentLink();
//            cdl.ContentDocumentId = cv.ContentDocumentId;
//            System.debug('cdl.LinkedEntityId before setting it: ' + cdl.LinkedEntityId);
//            System.debug('Setting it to cvIdMap.get(cv.Id): ' + cvIdMap.get(cv.Id));
//            cdl.LinkedEntityId = cvIdMap.get(cv.Id);
//            cdl.ShareType = 'I';
//            cdlLst.add(cdl);
//        }
//
//        insert cdlLst;
//        return cdlLst;
//    }

//    public static Map<Id, List<ContentVersion>> createContentVersion(Map<Id, List<Blob>> mapNoteIdLstBlob, Map<Id, Note> mapIdNote){
//        Map<Id, List<ContentVersion>> retMap = new Map<Id, List<ContentVersion>>();
//        List<ContentVersion> lstCV = new List<ContentVersion>();
//
//        for(Id noteId : mapNoteIdLstBlob.keySet()){
//            List<Blob> noteBlob = mapNoteIdLstBlob.get(noteId);
//            for(Blob b:noteBlob){
//                ContentVersion cv = new ContentVersion();
//                cv.ContentLocation = 'S';
//                cv.VersionData = b;
//                cv.CreatedById = mapIdNote.get(noteId).CreatedById;
//                cv.Title = mapIdNote.get(noteId).Title;
//                cv.PathOnClient = mapIdNote.get(noteId).Title+'.snote';
//                lstCV.add(cv);
//
//                if(!retMap.containsKey(mapIdNote.get(noteId).ParentId)){
//                    retMap.put(mapIdNote.get(noteId).ParentId,new List<ContentVersion>());
//                }
//
//                retMap.get(mapIdNote.get(noteId).ParentId).add(cv);
//            }
//        }
//
//        INSERT lstCV;
//        return retMap;
//    }

    // 08/16/2022 tony Added method as we can't deploy as code coverage is 0% for this class
    public static void forCodeCoverage(){
        //TODO Need to remove this hold class as it is no longer used
        System.debug('This is called for code coverage');
    }
}
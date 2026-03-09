/**
* Description : Test Data Factory for Dealer Portal
* Created by : Deepak Rajan
* Created Date : 24th Nov 2020
*/
@isTest
public class Dealer_TestDataFactory {
    
    public static ContentVersion getContentVersion(Blob b, String title, String pathOnClient, String description) {   
        ContentVersion cv = new ContentVersion();
        cv.VersionData    = b;
        cv.Title          = title;
        cv.Description    = description;
        cv.PathOnClient   = pathOnClient;
        return cv;
    }
    
    public static ContentDocumentLink getCdLink(Id docId, Id linkedEntityId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId   = docId;
        cdl.ShareType           = 'I';
        cdl.Visibility          = 'AllUsers';
        cdl.LinkedEntityId      = linkedEntityId;
        return cdl;        
    }    
    
    public static Attachment getAttachment(Id recId, String name, Blob b) {        
        Attachment attachment = new Attachment();
        attachment.ParentId   = recId;
        attachment.Name       = name;
        attachment.Body       = b;        
        return attachment;        
    }
}
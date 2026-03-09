/************************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 ATEAM-1912
* 2. Description - Utility class for merging attachments on Case Merge
*				   Functionality from Email Messages & Case
* 3. Objects referenced
*    -EmailMessage
*	 -Attachment
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es):
* 6. Invocable: True
*
* 7. Test Class Name: UTIL_Merge_Attachments_On_Case_EM_Test
*
* 8. Author Name(s): 
*    - Aakash 04-04-2023
*
************************************************************************/ 
public without sharing class UTIL_Merge_Attachments_On_Case_EM {
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        if(requests != null && !requests.isEmpty()){
            //this block uses the old email Id that exist in the subject of new emails
            //this acts as an identifier to know which attachment from old email goes to which new email
            if(requests[0].newEMList != null && !requests[0].newEMList.isEmpty() 
               && requests[0].oldAttachmentList != null && !requests[0].oldAttachmentList.isEmpty()){
                   Map<String, String> mapOldEMIdWithNewEMId = new Map<String, String>();
                   for(EmailMessage em : requests[0].newEMList) {
                       //if the email contains '02s' which are first 3 characters of an email msg record Id
                       //this means that an attachment is needed on this record
                       if (em.Subject.contains('02s')) {
                           Integer startIndex = em.Subject.indexOf('02s');
                           String oldEmailId = em.Subject.subString(startIndex, startIndex + 18);
                           //this is a map of old email ids with new email ids, old email id will be parentId of attachment
                           mapOldEMIdWithNewEMId.put(oldEmailId, em.id); 
                       }  
                   }
                   if(!mapOldEMIdWithNewEMId.keySet().isEmpty()) {
                       List<Attachment> emAttachList = new List<Attachment>();
                       for (Attachment attch : requests[0].oldAttachmentList) {
                           //if old email id in map matches with attachment's parentId, then
                           //then this attachment will go to new email in key-value pair
                           if(attch.parentId != NULL && mapOldEMIdWithNewEMId.containsKey(attch.parentId)) {
                               Attachment attachmentToInsert = new Attachment(); 
                               attachmentToInsert.Name = attch.Name;
                               attachmentToInsert.Body = attch.Body;
                               attachmentToInsert.ContentType = attch.ContentType;
                               attachmentToInsert.Description = attch.Description;
                               attachmentToInsert.OwnerId = attch.OwnerId;
                               attachmentToInsert.ParentId = mapOldEMIdWithNewEMId.get(attch.parentId);
                               emAttachList.add(attachmentToInsert);
                           }
                       }
                       if(!emAttachList.isEmpty()) {
                           try {
                               insert emAttachList; 
                               delete requests[0].oldAttachmentList;
                           }
                           catch(Exception e) {
                               System.debug('error' + e.getMessage());
                           }
                       }
                   }  
               }
            //this is a scenario where old attachments from child case need to be transferred to parent case
            else if(requests[0].parentCaseId != null && requests[0].parentCaseId != '' 
                    && requests[0].oldAttachmentList != null && !requests[0].oldAttachmentList.isEmpty()){
                        List<Attachment> attachList = new List<Attachment>();
                        for (Attachment attch : requests[0].oldAttachmentList) {
                            if(attch.parentId != NULL) {
                                Attachment attachmentToInsert = new Attachment(); 
                                attachmentToInsert.Name = attch.Name;
                                attachmentToInsert.Body = attch.Body;
                                attachmentToInsert.ContentType = attch.ContentType;
                                attachmentToInsert.Description = attch.Description;
                                attachmentToInsert.OwnerId = attch.OwnerId;
                                attachmentToInsert.ParentId = requests[0].parentCaseId;
                                attachList.add(attachmentToInsert);
                            }
                        }
                        if(!attachList.isEmpty()) {
                            try {
                                insert attachList; 
                                delete requests[0].oldAttachmentList;
                            }
                            catch(Exception e) {
                                System.debug('error' + e.getMessage());
                            }
                        }
                    }
        }
    }
    Public class FlowInputs {
        @InvocableVariable public List<EmailMessage> newEMList; 
        @InvocableVariable public List<Attachment> oldAttachmentList; 
        @InvocableVariable public String parentCaseId;
    }
    Public class FlowOutputs {         
    }
}
/*
Class:        EmailMessageMethods
@Author:        
@Created Date:  11/10/2013
@Description:   Handler class for Email Message Trigger
Change History
****************************************************************************************************************************
ModifiedBy      Date        Jira         Requested By                            Description                           Tag
****************************************************************************************************************************
11/10/2013  Shashi Merge Email Message triggers with changes done in Full SB    <T01>
*/
public class EmailMessageMethods {
    
    //added by (PwC) Deepak for tix - ITSFDC-3720
    private static final Map<String,String> sgsCiscoMappingMap = new Map<String, String>{'sgsupportusa@mx1.perkinelmer.com'=>'specimen.gate.support@perkinelmer.com'};
    
    public void Trg_emailmessage(List<EmailMessage> TriggerNew) {
        List<id> caseids=new List<id>();
        for(EmailMessage  iter: TriggerNew){
            caseids.add(iter.ParentId);
        }
        /********<T01>*******/
        
        // added  Case_Ref_ID_New__c
        Map<id,Case> caselist = new Map<id,case>([SELECT id,caseNumber,parentId,parent.INF_Case_Ref_Id__c,INF_Case_Ref_Id__c,parent.Case_Ref_ID_New__c,Case_Ref_ID_New__c,Subject,Description,RecordType.Name FROM Case WHERE Id = :caseids]);
        /********</T01>*******/
        map<Id,String> childToParent = new Map<Id,String>();
        map<Id,String> idToRefId = new Map<Id,String>();
        
        for(case iterable : caselist.values())
        {
            /*
            if(iterable.ParentId != null)
                childToParent.put(iterable.Id,iterable.ParentId+';'+iterable.parent.INF_Case_Ref_Id__c);
            if(iterable.INF_Case_Ref_Id__c != null)
                idToRefId.put(iterable.id,iterable.INF_Case_Ref_Id__c);
            */

            //Modified by Astha - 24/11/2020
            //Referencing New Case Ref Id field based on a change done by Salesforce (winter'20)
            if(iterable.ParentId != null)
                childToParent.put(iterable.Id,iterable.ParentId+';'+iterable.parent.Case_Ref_ID_New__c);
            if(iterable.Case_Ref_ID_New__c != null)
                idToRefId.put(iterable.id,iterable.Case_Ref_ID_New__c);
        }
        
        system.debug('childToParent'+childToParent+'idToRefId'+idToRefId);
        
        for(EmailMessage em: TriggerNew){ 
            String refId = '';
            String childrefId = idToRefId.get(em.parentid);
            if(childrefId!=null && childrefId.length() > 0)
                childrefId = childrefId.substring(1,childrefId.length()-1);
            if(em.parentid != null)
            {
                if(childToParent.get(em.ParentId) != null)
                {
                    Id newParentId = childToParent.get(em.ParentId).split(';')[0];
                    refId = childToParent.get(em.ParentId).split(';')[1];
                    refId = refId.substring(1,refid.length()-1);
                    em.ParentId = newParentId;
                    em.Subject = em.Subject.replace(childrefId,refId);
                }
            }
            system.debug('em.ParentId' + em.ParentId + 'childrefId' + childrefId);
        }
    }

    public void ParseEmail(List<EmailMessage> TriggerNew,Boolean isInsert) {
        Set<Id> caseIds = new Set<Id>();
        map<Id,EmailMessage> caseToEmail=new Map<Id,EmailMessage>();
        List<Case> csToUptd = new List<Case>();
        Set<String> EmailList = new Set<String>();
        
        List<Incoming_Email_PKI__c> CustomSet =[select Email__c from Incoming_Email_PKI__c where BU__c='DX' OR BU__c='INF'];
        for(EmailMessage em : TriggerNew){ 
            caseIds.add(em.ParentId);
            caseToEmail.put(em.ParentId,em);
        }
        for(Incoming_Email_PKI__c p:CustomSet){
            EmailList.add(p.Email__c);
        }
        
        for(Case cs: [Select id,Contact.Email,RecordType.Name,subject from Case where id in :caseIds]) {
            if(cs.RecordType.Name=='Dx Software Services EMEA L2' || cs.RecordType.Name=='DX Software Services' || cs.RecordType.Name=='DX Support' || cs.RecordType.Name=='Informatics') {
                EmailMessage e=caseToEmail.get(cs.Id);
                if(e!=null){
                    String eAddr=e.FromAddress + ';' + e.ToAddress + ';';
                    if(e.CcAddress!=null)
                        system.debug('E.CCADDRESS'+e.CcAddress);
                      system.debug('Subject'+e.subject);
                        eAddr+=e.CcAddress + ';';
                        
                    System.debug('##EADDR:##' + eAddr);
                   
                    List<String> ToList = eAddr.split(';');
                    Set<Id> csIds = new Set<Id>();
                    
                    for(String Adr:ToList) {
                        Adr=Adr.replaceAll(' ','');
                         //if(EmailList.contains(Adr)){  
                           if(EmailList.contains(Adr) || sgsCiscoMappingMap.containsKey(Adr)) { //Modified by (PwC) Deepak for tix - ITSFDC-3720  
                           // cs.External_Email_Inbox__c= Adr;
                              // System.debug('##Adr:## ' + Adr);                    
                               //System.debug('##sgsCiscoMappingMap.containsKey(Adr):## ' + sgsCiscoMappingMap.containsKey(Adr));
                    
                            cs.External_Email_Inbox__c= EmailList.contains(Adr) ? Adr : sgsCiscoMappingMap.get(Adr);//Modified by (PwC) Deepak for tix - ITSFDC-3720
                            if(!csIds.contains(cs.Id)) {
                                csToUptd.add(cs);
                                csIds.add(cs.Id);
                                break;
                            }
                        }
                    }                    
                    
                }
            }
        }
        if(csToUptd.size()>0)
            update csToUptd;
    }
    
    public void AppendCaseNumberToSubject (List<EmailMessage> TriggerNew,Boolean isInsert) {
        List<id> parentCaseIDs = new List<id>();
        string subject = '';
        for(EmailMessage email : TriggerNew){
             parentCaseIDs.add(email.parentID);
        }
        
        if(parentCaseIDs.size()>0){
            List<Case> parentCases = [Select CaseNumber,RecordType.DeveloperName from Case where id in:parentCaseIDs];
            Map<id,String> mapIdToCaseNumber = new Map<id,String>();
            for(Case c : parentCases){
                system.debug('****RecordType***'+c.RecordType.DeveloperName);
                if(c.RecordType!=null){
                    if(c.RecordType.DeveloperName=='Dx_Software_Services_EMEA_L2' || c.RecordType.DeveloperName == 'Dx_Software_Services' || c.RecordType.DeveloperName == 'Dx_Support' || c.RecordType.DeveloperName == 'Informatics')
                        mapIdToCaseNumber.put(c.id,c.CaseNumber);
                }
            }
            
            for(EmailMessage email : TriggerNew){
                if(mapIdToCaseNumber.containskey(email.parentID)){
                    String casenumber = mapIdToCaseNumber.get(email.parentID);
                    subject = email.subject;
                    if(subject != null && subject != '' && !subject.contains(casenumber))
                        email.subject = 'Case# ['+casenumber+'] '+ email.subject;  
                    else if(subject == null || subject == '')
                        email.subject = 'Case# ['+casenumber+'] ';  
                }
                if(email.subject!=null)
                    email.subject  = email.subject.replace('[]', '');    
            }
        }
    }
    
    
}
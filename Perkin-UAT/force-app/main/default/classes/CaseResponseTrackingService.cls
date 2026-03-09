/****************************************************************
* Description : Service class to Calculate Handle time for a case
* Created Date : 9th Feb 2020
*/
public class CaseResponseTrackingService {
    
    //Class level variables
    static Id INFORMATICS_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Informatics').getRecordTypeId();
    static Map<Id,User> USER_MAP       = new Map<Id,User>();
    static Map<Id,Group> GROUP_MAP     = new Map<Id,Group>();    
    
    
    /********************************************************************
    * Description - method that executes when a case record gets inserted.
    * Parameter - caseList list of cases
    * Return - void
    */    
    public static void CRTInsert(List<Case> caseList) {
        Set<Id> caseOwnerId = new Set<Id>();
        for(Case c:caseList) {
            if(c.RecordtypeId == INFORMATICS_RECORDTYPEID) {
                 caseOwnerId.add(c.OwnerId);   
            }                    
        }
        if(caseOwnerId.isEmpty()) return;
        
        List<Case_Response_Tracking__c> CRTInsertionList =  caseResponseInsertAction(caseList,caseOwnerId);
        if(!CRTInsertionList.isEmpty()) {
            insert CRTInsertionList;
        }
    }    
    
    /***************************************************************************************************
    * Description - Method to call helper methods for calculating the handle time when either Case fields 
    * Status|Owner|Business Hours changes.
    * Parameter -  oldCaseMap and newCaseMap 
    * Return - void
    */    
    public static void caseResponseUpdateAction(Map<Id,Case> oldCaseMap, Map<Id,Case> newCaseMap) {
        List<Case_Response_Tracking__c> CRTList = new List<Case_Response_Tracking__c>(); 
        Map<Id,Case> filteredCaseMap            = new Map<Id,Case>();
        Set<Id> caseOwnerIdSet                  = new Set<Id>();
        
        for(Case eachCase : newCaseMap.values()) {
            if(INFORMATICS_RECORDTYPEID.equals(eachCase.RecordTypeId) && (
               (eachCase.Status          <> oldCaseMap.get(eachCase.Id).Status) || 
               (eachCase.OwnerId         <> oldCaseMap.get(eachCase.Id).OwnerId) || 
               (eachCase.BusinessHoursId <> oldCaseMap.get(eachCase.Id).BusinessHoursId)))
            {   
                filteredCaseMap.put(eachCase.Id,eachCase);
                caseOwnerIdSet.add(eachCase.OwnerId);
            }
        }
        if(filteredCaseMap.isEmpty()) return;
        
        List<Case_Response_Tracking__c> CRTInsertionList      = caseResponseInsertAction(filteredCaseMap.values(), caseOwnerIdSet);

        if(!CRTInsertionList.isEmpty()) {
            CRTList.addAll(CRTInsertionList);
        }
        
        Map<String,List<Case_Response_Tracking__c>> caseRTMap = getCaseResponseTrackingRecords(filteredCaseMap.keySet());        
        
        for(Case eachCase : filteredCaseMap.values()) {
            if(caseRTMap.containsKey(eachCase.Id) && !caseRTMap.get(eachCase.Id).isEmpty()) {  
                Case_Response_Tracking__c CRT = new Case_Response_Tracking__c(); 
                CRT.Id                        = caseRTMap.get(eachCase.Id)[0].Id;               
                CRT.EndTime__c                = System.now(); 
                CRT.Business_Seconds__c       = (BusinessHours.diff(caseRTMap.get(eachCase.Id)[0].Business_Hours__c,caseRTMap.get(eachCase.Id)[0].StartTime__c,System.now()))/1000.0;
                if(eachCase.Status <> oldCaseMap.get(eachCase.Id).Status) 
                    CRT.Updated_Status__c     = eachCase.Status;
                CRTList.add(CRT);
            }
        }
        
        if(!CRTList.isEmpty()) {
            upsert CRTList;
        }       
    }      
    
    
    /***************************************************************************
    * Description - helper method that executes when a case record gets inserted.
    * Parameter - caseList list of cases
    * Return - CRTList (a list of Case_Response_Tracking__c records)
    */
    public static List<Case_Response_Tracking__c> caseResponseInsertAction(List<Case> caseList, Set<Id> caseOwnerIdSet) {
        List<Case_Response_Tracking__c> CRTList = new List<Case_Response_Tracking__c>();    
        for(User u : [SELECT Id, Name FROM User WHERE Id IN: caseOwnerIdSet]) {
            USER_MAP.put(u.Id, u);
        }        
        for(Group g : [SELECT Id, Name FROM Group where Id IN: caseOwnerIdSet]) {
            GROUP_MAP.put(g.Id, g);
        }        
        for(Case c : caseList) {
            Case_Response_Tracking__c newCRT = new Case_Response_Tracking__c();
            newCRT.Case__c                   = c.Id;
            newCRT.Status__c                 = c.Status;
            newCRT.Business_Hours__c         = c.BusinessHoursId;
            newCRT.StartTime__c              = System.now();
            if(c.ownerId.getSobjectType()   == Schema.User.SObjectType) {
               newCRT.Owner__c               = c.OwnerId;
               newCRT.Owner_Name__c          = USER_MAP.get(c.OwnerId)?.Name;
            }
            else {
                newCRT.IsQueue__c            = true;
                newCRT.Owner_Name__c         = GROUP_MAP.get(c.OwnerId)?.Name;
                newCRT.NativeQueueID__c	     = GROUP_MAP.get(c.OwnerId)?.Id;
            }
            CRTList.add(newCRT);
        }
        return CRTList;        
    }
     
    /************************************************************************************************************
    * Description - used to pull the Case Response Tracking	records for case recIds.
    * Parameter - caseRecId (A set of case Ids) 
    * Return - caseToResponseTrackingMap that consists, list of Case Response Tracking records linked to the case.
    */
    @testVisible
    private static Map<String,List<Case_Response_Tracking__c>> getCaseResponseTrackingRecords(Set<Id> caseRecId) {
        Map<String,List<Case_Response_Tracking__c>> caseToResponseTrackingMap = new Map<String,List<Case_Response_Tracking__c>>();
        for(Case_Response_Tracking__c eachTracker : [SELECT Id, Business_Hours__c, Case__c, StartTime__c, EndTime__c, Updated_Status__c 
                                                     FROM Case_Response_Tracking__c 
                                                     WHERE Case__c IN: caseRecId AND EndTime__c = NULL 
                                                     ORDER BY LastModifiedDate DESC])
        {
            List<Case_Response_Tracking__c> relatedRecords = caseToResponseTrackingMap.containsKey(eachTracker.Case__c) ?  
                                                             caseToResponseTrackingMap.get(eachTracker.Case__c) : 
                                                             new List<Case_Response_Tracking__c>();
            relatedRecords.add(eachTracker);
            caseToResponseTrackingMap.put(eachTracker.Case__c,relatedRecords);
        }
        return caseToResponseTrackingMap; 
    }

}
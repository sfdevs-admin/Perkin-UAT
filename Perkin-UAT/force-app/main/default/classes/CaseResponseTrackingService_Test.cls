@isTest
private class CaseResponseTrackingService_Test {
    
    @testsetup
    static void testSetupData() {
        //insert account
        Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        
        //insert contact
        Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
        
        //insert case
        Case casetoinsert = CT_TestDataSetupUtility.createTestCase('Informatics','New','test','Phone',acc.id,con.id);
        insert casetoinsert;
    }
    
    @isTest
    static void testInsertMethod() {
        
        List<case> caseList = [SELECT Id, recordTypeId, OwnerId, BusinessHoursId, Status FROM Case];
        CaseResponseTrackingService.CRTInsert(caseList);
        
    }
    
    @isTest
    static void testUpdate() {
        
        List<case> caseList = [SELECT Id, recordTypeId, OwnerId, BusinessHoursId, Status FROM Case];
        map<id, case> oldMap = new map<id, case>(caseList);
        case c = caseList[0];
        c.Status = 'New Info';
        c.OwnerId = UserInfo.getUserId();
        
        map<id, case> newMap = new map<id, case>();
        newMap.put(c.id, c);

        CaseResponseTrackingService.caseResponseUpdateAction(oldMap, newMap);
    }
    
    @isTest
    static void testInsertHelper() {

        List<case> caseList = [SELECT Id, recordTypeId, OwnerId, BusinessHoursId, Status FROM Case];
        Set<id> caseOwnerIdSet = new Set<id>{UserInfo.getUserId()};

        CaseResponseTrackingService.caseResponseInsertAction(caseList, caseOwnerIdSet);
    }
    
    @isTest
    static void testGetRecords() {
        case c = [SELECT Id, recordTypeId, OwnerId, BusinessHoursId, Status FROM Case limit 1];

        Set<id> caseIds = new set<id>{c.id};
		Case_Response_Tracking__c crt = new Case_Response_Tracking__c(case__c = c.id);
        insert crt;
        CaseResponseTrackingService.getCaseResponseTrackingRecords(caseIds);
    }
}
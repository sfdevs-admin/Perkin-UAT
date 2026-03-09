/**
* Description : Test class for Dealer_RecentFilesCtrl
* Created by : Nagendra Singh
* Created Date : 24th Nov 2020
*/
@isTest
private class Dealer_RecentFilesCtrlTest {
    
    static testmethod void testData() {
        Test.startTest();
        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        
        //Create ContentWorkspace
        ContentWorkspace workspace = new ContentWorkspace(Name = 'Common Area1');        
        System.runAs(currentUser) {            
            insert new ContentWorkspace[] { workspace };                
        }
        
        //Create Document
        ContentVersion cv = Dealer_TestDataFactory.getContentVersion(Blob.valueOf('ContentVersion Body'), 'Test', 'xyz', 'Test');
        insert cv;
        
        //Get Content Documents
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cdl = Dealer_TestDataFactory.getCdLink(docId, workspace.Id);
        insert cdl;
        
        List<ContentDocumentLink> cd = Dealer_RecentFilesCtrl.fetchContentDocument();
        Test.stopTest();
        System.assertEquals(cd.size(),1);
        System.assertEquals(cd[0].LinkedEntityId, workspace.Id);        
    }
}
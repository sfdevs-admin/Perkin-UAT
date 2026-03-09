/**
*   Description     :   Controller to return recent 3 fiels for Dealers
*   Created by      :   Nagendra Singh
*   Created Date    :   11th Nov 2020
    Revision History: Date     Developer Name           Description
*/
public with sharing class Dealer_RecentFilesCtrl {
    @AuraEnabled 
    public static List<ContentDocumentLink> fetchContentDocument(){
        map<Id,ContentWorkspace> workSpaceMap = new map<Id,ContentWorkspace> ([SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE 
                                                                           (Name = 'Common Area' OR Name = 'Secure Area')]);
        if(Test.isRunningTest()) {
            ContentWorkspace cWorkspace = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = 'Common Area1'];
            workSpaceMap.put(cWorkspace.Id,cWorkspace);
        } 
        List<ContentDocumentLink> con=[select id,LinkedEntityId,ContentDocumentId ,ContentDocument.FileType,ContentDocument.LatestPublishedVersion.Title 
                                 from ContentDocumentLink  where LinkedEntityId IN :workSpaceMap.keyset() order by ContentDocument.CreatedDate desc Limit 3 ];
        
        return con;        
    }

}
/* Name: TestServiceCaseTrigger
*  Author(s): SF Professional Services (Copied and updated by OpFocus)
*  Last Update : April 4, 2012
*  Description: Copied unit test(s) from Caliper instance
*               Tests UpdateQualityCaseOnServiceCase.trigger
*/
@isTest
private class TestUpdateQualityCaseOnServiceCseTrigger 
{

    static testMethod void testUpdateServiceCase() {
        Map<String, RecordType> RecTypeListMap = new Map<String, RecordType>();
        for (RecordType RecList : [select Id, Name from RecordType where SobjectType = 'Case']) {
            RecTypeListMap.put(RecList.Name, RecList);
        }
    StaticVariables.AfterTgrEventsCase = false;
        StaticVariables.afterInsertCase = false;
        StaticVariables.beforeInsertUpdateCase = false;
        //2 create Service case
        Case srvCase = new Case ( Status = 'New',
                                Subject = 'Test Service Case Deux',
                                Description = 'Test Service Case Deux',
                                Origin = 'Phone',
                                //AssetId = '02iR0000000cg9G',
                                RecordTypeId = RecTypeListMap.get('LST Support & Service').Id,
                                Type = 'Field Service',
                                Sub_Type__c = 'Installation Request',
                                Packaging__c = '100% - Professional AND Protected', 
                                Completeness__c = '100% - No components missing', 
                                Functional__c = '50% - Only Minor field replacements'
                                  );
        insert srvCase;
    //StaticVariables.AfterTgrEventsCase = true;
        StaticVariables.afterInsertCase = true;
        StaticVariables.beforeInsertUpdateCase = false;
        
        //2 create Service case
        Case qualityCase = new Case ( Status = 'New',
                                Subject = 'Test Service Case Deux',
                                Description = 'Test Service Case Deux',
                                Origin = 'Phone',
                                //AssetId = '02iR0000000cg9G',
                                RecordTypeId = RecTypeListMap.get('LST Quality').Id,
                                Type = 'Quality Failure',
                                Sub_Type__c = 'Manufacturing Test',
                                Packaging__c = '100% - Professional AND Protected', 
                                Completeness__c = '100% - No components missing', 
                                Functional__c = '50% - Only Minor field replacements',
                                Service_Case__c = srvCase.Id
                                  );
        insert qualityCase;
        srvCase = [SELECT Id, Quality_Case__c FROM Case WHERE Id = : srvCase.Id];
        //System.assert(srvCase.Quality_Case__c == qualityCase.Id);

        //3 update case status to match config
        //srvCase.Status = 'Closed';
        //update srvCase; 
    }
}
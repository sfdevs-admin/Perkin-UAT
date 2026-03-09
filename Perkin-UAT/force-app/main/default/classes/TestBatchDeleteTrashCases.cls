@isTest()
public class TestBatchDeleteTrashCases {

static testMethod void method1(){

    QueueSobject qid = [SELECT QueueId,Queue.Name  FROM QueueSobject where Queue.Name = 'TRASH CASES' limit 1];
    system.debug('QUEUE ID IS '+qid);
    
    Account acc = CT_TestDataSetupUtility.createTestAccount('TEST','77778','Test');
        insert acc;
        
    Contact con = CT_TestDataSetupUtility.createTestContact(acc.id,'test','test','test@test.com');
        insert con;
    
     Case cs = new Case(
            AccountId = acc.Id, ContactId = con.Id,
            OwnerId = qid.QueueId, Priority = 'Medium',
            Description = 'test');
    
    insert cs;

    Test.startTest();
            BatchDeleteTrashCases batch = new BatchDeleteTrashCases();
            database.Executebatch(batch);
       Test.stopTest();
}
}
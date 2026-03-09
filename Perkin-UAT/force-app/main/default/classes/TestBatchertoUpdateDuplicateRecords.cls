@isTest
public class TestBatchertoUpdateDuplicateRecords {
    /*public static DSE__DS_DuplicateBean__c record1;
    public static DSE__DS_DuplicateBean__c record2;
    public static DSE__DS_DuplicateBean__c record3;
    public static DSE__DS_DuplicateBean__c record4;
    public static DSE__DS_DuplicateBean__c record5;
    static
        {
            record1 = new DSE__DS_DuplicateBean__c();
            record2 = new DSE__DS_DuplicateBean__c();
            record3 = new DSE__DS_DuplicateBean__c();
            record4 = new DSE__DS_DuplicateBean__c();
            record5 = new DSE__DS_DuplicateBean__c();
            
            insert new List<DSE__DS_DuplicateBean__c>{record1,record2,record3,record4,record5};
            
        }
    
    static testmethod void testAssignmentRules(){
        BatchertoUpdateDuplicateRecords Batcher = new BatchertoUpdateDuplicateRecords();
            test.startTest();
             Id apexJobId = DataBase.executeBatch(Batcher);
             AsyncApexJob a = [SELECT Status, NumberOfErrors,TotalJobItems FROM AsyncApexJob WHERE Id =:apexJobId];
      
            if(a.Status == 'Completed')
            {
                /*for(DSE__DS_DuplicateBean__c t: [Select id,DSE__DS_Toggle_Master__c,DSE__DS_No_Duplicate__c from DSE__DS_DuplicateBean__c where id in (:record1.Id,:record1.Id,:record2.Id,:record3.Id,:record4.Id,:record5.Id)])
                {
                    system.assertEquals(t.DSE__DS_Toggle_Master__c, false);
                   system.assertEquals(t.DSE__DS_No_Duplicate__c, true);
                }
            }
            Test.stopTest();
        
    }
*/
}
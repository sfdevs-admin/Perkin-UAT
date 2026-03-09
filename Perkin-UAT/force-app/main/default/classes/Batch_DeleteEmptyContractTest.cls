@isTest
public class Batch_DeleteEmptyContractTest {
    public static testmethod void testDeleteEmptyContract(){
        Id conRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Accountwide Contract').getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        
        Contract con1 = new Contract();
        con1.Name = 'TestContract1';
        con1.AccountId = acc.Id;
        con1.StartDate = System.today();
        con1.EndDate = System.today() + 60;
        con1.ContractTerm = 12;
        con1.Status = 'Draft';
        con1.RecordTypeId = conRecTypeId;
        insert con1;
        
        Batch_DeleteEmptyContract deleteBatch = new Batch_DeleteEmptyContract();
        Database.executeBatch(deleteBatch);
    }
    
    public static testmethod void testSchedularClass(){
        Test.startTest();
        Batch_DeleteEmptyContract_Scheduler schedularClass = new Batch_DeleteEmptyContract_Scheduler();
        String schedularTime = '0 0 23 * * ?'; 
        system.schedule('DeleteEmptyContract', schedularTime, schedularClass); 
        Test.stopTest(); 
    } 
}
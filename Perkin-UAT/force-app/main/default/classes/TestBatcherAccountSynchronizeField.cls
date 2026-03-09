@isTest
public class TestBatcherAccountSynchronizeField {
    
    public static ID RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
    public static Account acc1;
    public static Account acc2;
    public static Account acc3;
    public static Account acc4;
    public static Account acc5;
    
        static
        {
            acc1 = new Account();
            acc1.RecordtypeId = RecordtypeId;
            acc1.Name = 'test-1';
            acc1.ShippingPostalCode='600094';
            acc1.ShippingState='TN';
            acc1.ShippingStreet='MountRoad';
            
            acc2 = new Account();
            acc2.RecordtypeId = RecordtypeId;
            acc2.Name = 'test-2';
            acc2.ShippingPostalCode='600094';
            acc2.ShippingState='TN';
            acc2.ShippingStreet='MountRoad';
            
            acc3 = new Account();
            acc3.RecordtypeId = RecordtypeId;
            acc3.Name = 'test-3';
            acc3.ShippingPostalCode='600094';
            acc3.ShippingState='TN';
            acc3.ShippingStreet='MountRoad';
            
            acc4 = new Account();
            acc4.RecordtypeId = RecordtypeId;
            acc4.Name = 'test-4';
            acc4.ShippingPostalCode='600094';
            acc4.ShippingState='TN';
            acc4.ShippingStreet='MountRoad';
            
            acc5 = new Account();
            acc5.RecordtypeId = RecordtypeId;
            acc5.Name = 'test-5';
            acc5.ShippingPostalCode='600094';
            acc5.ShippingState='TN';
            acc5.ShippingStreet='MountRoad';
            
            insert new List<Account>{acc1,acc2,acc3,acc4,acc5};
        }
        
    static testMethod void myUnitTest() {
        test.startTest();
		BatcherAccountSynchronizeField batchable = new BatcherAccountSynchronizeField();
        Database.executeBatch(batchable);
        test.stopTest();
    }

}
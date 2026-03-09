@istest
public class TestBatchEmailValidate {
    public static testmethod void unittest(){
        contact con= new contact(Email='test@gmail.com',FirstName='ABC',LastName='CDF');
        insert con;
        Test.startTest();
        BatchEmailValidate batch=new BatchEmailValidate();
        database.executebatch(batch);
        test.stopTest();
    }

}
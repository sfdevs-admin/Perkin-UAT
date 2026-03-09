@isTest
public class Test_AccountTrigger_PreventDelete{
    public static TestMethod void unitTest01(){
        
    Profile p = [select Id,name from Profile where Name ='System Administrator'];
         User newUser = new User(
            profileId = p.id,
            username = 'newUserxxxxx@yahoo.com',
            email = 'pb@ff.com',
              emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuser',
            lastname='lastname'
        );
        insert newUser;
    Account testAcc = new Account();
    testAcc.Name = 'AccountName';
    testAcc.Account_Email__c = 'test@test.com';
    
    insert testAcc;
    
    System.runAs(newUser){
        boolean isException =false;
        try{
            delete testAcc;
        }
        Catch(Exception e){
            isException = true;
        }
       
        
    }
     
    }
}
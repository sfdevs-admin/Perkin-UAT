@isTest
public class ContractNumber_TEST {
    
    public static testmethod void contractTriggersTest(){
        UserRole r = new UserRole(DeveloperName = 'Global_Sales_and_Service1', Name = 'Global Sales and Service');
        insert r;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@test.com',
            Username = 'puser000@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = r.Id,
            PKICountry__c = 'Brazil'
        );
        System.runAs(u) {
            Account acc = new Account();
            acc.name = 'Test Account';
            insert acc;
            
            Contract con = new Contract();
            con.Name = 'test Contract';
            con.AccountId = acc.Id;
            insert con;
        }
        
    }
    
}
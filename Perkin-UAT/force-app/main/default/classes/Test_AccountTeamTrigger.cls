@isTest
public class Test_AccountTeamTrigger {
    @isTest
    public static void AddNewAccountteamMember(){
        Profile profile1 = [Select Id from Profile where name = 'System Administrator']; 
        User manager1 = new User(
                    Username = System.now().millisecond() + 'test2@test.com1',
             		profileid = profile1.id,
                    Alias = 'batman',
                    Email='bruce.wayne@wayneenterprises.com',
                    EmailEncodingKey='UTF-8',
                    Firstname='Bruce',
                    Lastname='Wayne',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    TimeZoneSidKey='America/Chicago'
        );
        insert manager1;
        User manager2 = new User(
                    Username = System.now().millisecond() + 'test3@test.com1',
            		profileid = profile1.id,
                    Alias = 'batman',
                    Email='bruce.wayne@wayneenterprises.com',
                    EmailEncodingKey='UTF-8',
                    Firstname='Bruce',
                    Lastname='Wayne',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    TimeZoneSidKey='America/Chicago'
        );
        insert manager2;
        Account a = new Account();
        a.name = 'Test Account';
        a.ShippingCity = 'test city';
        a.ShippingCountry = 'US';
        a.ShippingPostalCode = '12345678';
        a.ShippingState = 'AX';
        a.ShippingStreet = 'Test Street';
        Insert A;
        
        case c1 = new Case();
        c1.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        c1.AccountId = a.id;
        c1.subject = 'Test Subject';
        insert c1;
        
        AccountTeamMember am = new AccountTeamMember();
        am.AccountId = a.id;
        am.UserId = manager1.id;
        am.AccountAccessLevel = 'Edit';
        am.CaseAccessLevel = 'Edit';
        am.TeamMemberRole= 'Account manager';
        insert am;
        
        case c = new Case();
        c.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        c.AccountId = a.id;
        c.subject = 'Test Subject';
        insert c;
        
        AccountTeamMember am2 = new AccountTeamMember();
        am2.AccountId = a.id;
        am2.UserId = manager2.id;
        am2.AccountAccessLevel = 'Edit';
        am2.CaseAccessLevel = 'Edit';
        am2.TeamMemberRole= 'Account manager';
        insert am2;
        
        am2.TeamMemberRole = 'Marketing';
        update am2;
        
        am2.TeamMemberRole = 'Account Manager';
        update am2;
        
        delete am2;
    }

}
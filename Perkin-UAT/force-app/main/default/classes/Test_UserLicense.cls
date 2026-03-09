@isTest(seeAllData=true)
public class Test_UserLicense {
    static testmethod void licenseTest()
    {
        User u = [select id,IsActive,License_type__c from User where alias='tadmi' LIMIT 1];
        u.IsActive = false;
        update u;
        User standardUser = new User();
            standardUser.FirstName = 'Test';
            standardUser.LastName = 'Standard User 1';
            standardUser.Email = 'pkedev@test.com1243fdrgws';
            standardUser.Alias = 'std';
            standardUser.Username = standardUser.Email;
            standardUser.CommunityNickname = 'standard';
            standardUser.TimeZoneSidKey = 'America/Chicago';
            standardUser.LocaleSidKey = 'en_US';
            standardUser.EmailEncodingKey = 'ISO-8859-1';
            standardUser.LanguageLocaleKey = 'en_US';
            standardUser.IsActive = true;
            standardUser.ProfileId = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
           insert standardUser;
       
    }

}
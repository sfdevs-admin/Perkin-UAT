/**
 * Simple Test Class to Cover UserTrigger
 */
@IsTest public with sharing class BD_User_Test
{
    @isTest static void codeCoverage()
    {
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        User techUser = new User();
        techUser.Alias = 'smax-xxx';
        techUser.Email='standarduser@testorg.com';
        techUser.EmailEncodingKey='UTF-8';
        techUser.LastName='Testing';
        techUser.LanguageLocaleKey='en_US';
        techUser.LocaleSidKey='en_US';
        techUser.ProfileId = systemAdminProfile.Id;
        techUser.TimeZoneSidKey='America/Los_Angeles';
        techUser.UserName='standard@testorg.servicemax.com';
        insert techUser;

        techUser.LastName='Testing2';
        update techUser;

    }

}
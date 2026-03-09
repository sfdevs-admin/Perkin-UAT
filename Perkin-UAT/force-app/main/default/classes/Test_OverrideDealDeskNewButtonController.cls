@isTest 
public class Test_OverrideDealDeskNewButtonController {
    public static testMethod void testMethodforCntrl(){
        Id opprtRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
        
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
            PKICountry__c = 'Brazil'
        );
        
        System.runAs(u) {
            Account acc= new Account();
            acc.Name='Test Account';
            insert acc;        
            
            Opportunity op = new Opportunity(Name='opp1',AccountId=acc.Id,RecordTypeId=opprtRecTypeId,
                                             Renewal_Required_INF__c='Yes',Account_Type_INF__c='Academic',
                                             StageName='Stage 1 - Create/Plan',CloseDate=Date.today(),
                                             Strategic_Market_INF__c='Clinical',Type='New Account',
                                             ForecastCategoryName='Pipeline',CurrencyIsoCode = 'USD',
                                             Solution_Area_of_Interest__c='Energy');        
            insert op;
            
            Deal_Desk__c dealDesk = new Deal_Desk__c(OwnerId = UserInfo.getUserId(), Opportunity__c = op.id, Request_For__c = 'Signals Notebook deal that is E3 or Private Cloud');
            insert dealDesk;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(dealDesk);
            ApexPages.currentPage().getParameters().put('Id',dealDesk.Id);
            OverrideDealDeskNewButtonController d = new OverrideDealDeskNewButtonController (sc);
            
            OverrideDealDeskNewButtonController.getRequestForValues();
            OverrideDealDeskNewButtonController.checkAvailableDealDesk(op.Id);
            OverrideDealDeskNewButtonController.currentDDStatus(dealDesk.Id);
            OverrideDealDeskNewButtonController.currentUserProfile();
        }
    }
}
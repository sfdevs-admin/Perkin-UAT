@isTest
private class TestRejectPage{
    @isTest
    private static void testClass()
    {
    
    Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator']; //Querying for the profile to assign to the user.
        
//Creating the test user
User objUsr_INF = new User(alias = 'sINFUser', Business__c = 'Informatics' , Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerINF.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITEST.com');

insert objUsr_INF; //creating the user

System.runAs(objUsr_INF){

       Opportunity opp = new Opportunity();
        opp.Name='TestOpp';
        opp.StageName='Prospecting';
        opp.CloseDate=Date.NewInstance(2013,8,23);
        opp.Solution_Area_of_Interest__c='Energy';
        insert opp;

        // Add parameters to page URL 
        ApexPages.currentPage().getParameters().put('oppId', opp.id);
        ApexPages.currentPage().getParameters().put('oopOwner', 'basavaiah.gorikapudi@perkinelmer.com');
        ApexPages.currentPage().getParameters().put('body', 'TestEmail');
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        SendEmail sm= new SendEmail(sc);
        try{
            sm.navigateToRecord();
             sm.send();
             }catch(Exception e){} 
            
         }

     

       }

}
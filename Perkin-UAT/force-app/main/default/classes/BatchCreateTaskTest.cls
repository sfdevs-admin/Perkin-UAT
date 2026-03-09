@isTest
private class BatchCreateTaskTest {
static testMethod void BatchTest(){

Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator']; //Querying for the profile to assign to the user.
        
//Creating the test user
User objUsr_INF = new User(alias = 'sINFUser', Business__c = 'Informatics' , Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerINF.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITEST.com');

insert objUsr_INF; //creating the user

System.runAs(objUsr_INF){

// Create a Lead
Lead newLead = new Lead(LastName='Test', Company='ABC',Email='test@gmail.com',Status='Open');
try {
insert newLead;
System.debug('new lead'+ newLead.Id);

// Create a Task
Task newTask = new Task(Subject='Open Task', Status='Not Started', WhoId=newLead.Id);
test.startTest();
insert newTask;
test.stopTest();
}catch (DmlException e) { 

   System.assert(e.getMessage().contains('Insert failed. First exception '+
      'on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION'), e.getMessage()); 

//Assert Status Code
   System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION'  , 
                        e.getDmlStatusCode(0));
          }

}
}
}
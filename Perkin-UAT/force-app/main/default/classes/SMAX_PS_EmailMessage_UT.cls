@isTest(seeAllData=true)
private class SMAX_PS_EmailMessage_UT {
  
  static testMethod void deleteCRCProfile()
  {
        profile target = [Select id from profile where name = 'SVMX PS - Customer Care' LIMIT 1];
    User user1= new User(
       //set profile as 'SVMX PS - Customer Care'
       ProfileId = target.id,
       LastName = 'last',
       Email = 'puser000@amamama.com',
       Username = 'puser000@amamama.com' + System.currentTimeMillis(),
       CompanyName = 'TEST',
       Title = 'title',
       Alias = 'alias',
       TimeZoneSidKey = 'America/Los_Angeles',
       EmailEncodingKey = 'UTF-8',
       LanguageLocaleKey = 'en_US',
       LocaleSidKey = 'en_US'
    );
    insert user1;
  
    System.debug('This is the ' + user1.profileid + 'profile.');

    RecordType[] rt=[SELECT Id,Name FROM RecordType WHERE SobjectType='Case' and Name='Customer Care - General'];
        Case cs = new Case(Subject='Test1',Status='New',Priority='Medium',Origin='Email',RecordTypeId=rt[0].id);
        insert cs;

      System.debug('Case ID = ' + cs.id);


      System.runAs(user1){
      /*List<EmailMessage> msgList = new List<EmailMessage>();
          EmailMessage msg1 = new EmailMessage(FromAddress='fakeFrom1@address.com',ToAddress='fakeTo1@address.com',Subject='Test1',TextBody='qwerty',ParentId=cs.Id,status='1');*/
           List<EmailMessage> msgList = new List<EmailMessage>();
          EmailMessage msg1 = new EmailMessage(FromAddress='fakeFrom1@address.com',ToAddress='fakeTo1@address.com',Subject='Test1',TextBody='qwerty',status='1');
        
           insert msg1;

      System.debug('Current User is ' + UserInfo.getUserName());

      Test.startTest();
        try {
          delete msg1;
          List<EmailMessage> delList = [SELECT Id, IsDeleted FROM EmailMessage WHERE Id=:msg1.Id];
          System.assertEquals(0, delList.size());
        }
        catch(DmlException e) {
          System.debug('^^^' + e.getMessage());
          System.assert(e.getMessage().contains('This user is not permitted to delete emails.'));
        }
      Test.stopTest();

    }

  }

  static testMethod void deleteNonCRCProfile()
  {
        
        profile target = [Select id from profile where name = 'SVMX PS - Dispatcher' LIMIT 1];

    User user2= new User(
       //set profile as ''
       ProfileId = target.id,
       LastName = 'last',
       Email = 'puser001@amamama.com',
       Username = 'puser001@amamama.com' + System.currentTimeMillis(),
       CompanyName = 'TEST',
       Title = 'title',
       Alias = 'alias',
       TimeZoneSidKey = 'America/Los_Angeles',
       EmailEncodingKey = 'UTF-8',
       LanguageLocaleKey = 'en_US',
       LocaleSidKey = 'en_US'
    );
    insert user2;

    System.debug('This is the ' + user2.profileid + 'profile.');


    RecordType[] rt=[SELECT Id,Name FROM RecordType WHERE SobjectType='Case' and Name='Customer Care - General'];
        Case cs = new Case(Subject='Test1',Status='New',Priority='Medium',Origin='Email',RecordTypeId=rt[0].id);
        insert cs;

      System.debug('Case ID = ' + cs.id);


    System.runAs(user2){
          /*EmailMessage msg2 = new EmailMessage(FromAddress='fakeFrom1@address.com',ToAddress='fakeTo1@address.com',Subject='Test1',TextBody='asdfgh',ParentId=cs.Id,status='1');*/
          EmailMessage msg2= new EmailMessage(FromAddress='fakeFrom1@address.com',ToAddress='fakeTo1@address.com',Subject='Test1',TextBody='asdfgh',status='1');
          insert msg2;

      System.debug('Current User is ' + UserInfo.getUserName());

      Test.startTest();
        try {
          delete msg2;
          List<EmailMessage> delList = [SELECT Id, IsDeleted FROM EmailMessage WHERE Id=:msg2.Id];
          System.assertEquals(0, delList.size());
        }
        catch(DmlException e) {
          System.assert(e.getMessage().contains('This user is not permitted to delete emails.'));
        }
      Test.stopTest();

    }

  }

  @isTest static void testCaseNotClosed()
  {
    //Get RecordTypeId for the "Customer Care - General" record type
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Care_General').getRecordTypeId();

    // Create a case that is not Closed
    // Case newCase = new Case(Subject = 'Test1', Status = 'New', Priority = 'Medium', Origin = 'Email - MX', RecordTypeId = recordTypeId);
    Case newCase = new Case(Subject = 'Test1', Status = 'In Process', Priority = 'Medium', Origin = 'Email - MX', RecordTypeId = recordTypeId,
        CreatedDate = System.now() - 1);
    insert newCase;

    System.debug('Case ID = ' + newCase.Id);
    System.assert(newCase.Id != null, 'Unable to create case record for testing');

    EmailMessage emailMessage = new EmailMessage(FromAddress = 'User@test.com', ToAddress = 'User@test.com', Subject = 'Test Inbound Email',
        TextBody = 'Test Test Test', ParentId = newCase.Id, Incoming = true, MessageDate = System.now());

    System.debug('Inserting email message' + emailMessage);

    try
    {
      insert emailMessage;
    } catch (DmlException e)
    {
      System.debug('*** ' + e.getMessage());
      // System.assert(e.getMessage().contains('This user is not permitted to delete emails.'));
    }

    EmailMessage queriedEmailMessage = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId = :emailMessage.ParentId];
    System.assertNotEquals(queriedEmailMessage.Id, null, 'Unable to get Id for Email Message inserted');
    System.assertEquals(newCase.Id, queriedEmailMessage.ParentId, 'Error assigning email message to open case');
  }

  @isTest static void testCaseClosedLessThan72Hours()
  {
    //Get RecordTypeId for the "Customer Care - General" record type
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Care_General').getRecordTypeId();

    // Create a case that was Closed less than 72 hours ago
    Case newCase = new Case(Subject = 'Test1', Status = 'Closed', Priority = 'Medium', Origin = 'Email - MX', RecordTypeId = recordTypeId,
        CreatedDate = System.now() - 3, ClosedDate = System.now() - 1, DX_Resolution__c = 'Just Because');
    insert newCase;

    System.debug('Case ID = ' + newCase.Id);
    System.assert(newCase.Id != null, 'Unable to create case record for testing');

    EmailMessage emailMessage = new EmailMessage(FromAddress = 'User@test.com', ToAddress = 'User@test.com', Subject = 'Test Inbound Email',
        TextBody = 'Test Test Test', ParentId = newCase.Id, Incoming = true, MessageDate = System.now());

    System.debug('Inserting email message' + emailMessage);

    try
    {
      insert emailMessage;
    } catch (DmlException e)
    {
      System.debug('*** ' + e.getMessage());
      // System.assert(e.getMessage().contains('This user is not permitted to delete emails.'));
    }

    EmailMessage queriedEmailMessage = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId = :emailMessage.ParentId];
    System.assertNotEquals(queriedEmailMessage.Id, null, 'Unable to get Id for Email Message inserted');

    Case queriedCase = [SELECT Id, Status FROM Case WHERE Id = :newCase.Id];
    System.assertEquals('In Process', queriedCase.Status, 'Error case Status was not changed to [In Process]');

    System.assertEquals(newCase.Id, queriedEmailMessage.ParentId, 'Error assigning email message to case closed less than 72 hours');
  }

  @isTest static void testCaseClosedMoreThan72Hours()
  {
    //Get RecordTypeId for the "Customer Care - General" record type
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Care_General').getRecordTypeId();

    // Create a case that was Closed more than 72 hours ago
    Case newCase = new Case(Subject = 'Test1', Status = 'Closed', Priority = 'Medium', Origin = 'Email - MX', RecordTypeId = recordTypeId,
        CreatedDate = System.now() - 6, ClosedDate = System.now() - 4, DX_Resolution__c = 'Just Because');
    insert newCase;

    System.debug('Case ID = ' + newCase.Id);
    System.assert(newCase.Id != null, 'Unable to create case record for testing');

    EmailMessage emailMessage = new EmailMessage(FromAddress = 'User@test.com', ToAddress = 'User@test.com', Subject = 'Test Inbound Email',
        TextBody = 'Test Test Test', ParentId = newCase.Id, Incoming = true, MessageDate = System.now());

    System.debug('Inserting email message' + emailMessage);

    try
    {
      insert emailMessage;
    } catch (DmlException e)
    {
      System.debug('*** ' + e.getMessage());
      // System.assert(e.getMessage().contains('This user is not permitted to delete emails.'));
    }

    EmailMessage queriedEmailMessage = [SELECT Id, ParentId FROM EmailMessage WHERE Id = :emailMessage.Id];
    System.assertNotEquals(queriedEmailMessage.Id, null, 'Unable to get Id for Email Message inserted');
    System.assertNotEquals(newCase.Id, queriedEmailMessage.ParentId, 'Error email message is still assigned to case closed more than 72 hours ago');
  }
}
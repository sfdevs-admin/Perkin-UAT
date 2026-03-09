@isTest
private class test_revenue_rec_date_populate
{
   public static opportunity opp;
   public static user user2;
  static testMethod void testinsert() {
    //create opportunity
    opportunity test_o = new opportunity();
    test_o.Name = 'Test';
    test_o.StageName = 'Stage 1 - Qualification';
    test_o.CloseDate = date.parse('3/10/2012');
    test_o.Revenue_rec_date__c = date.parse('3/1/2012');
    test_o.Market_Segment__c = 'Duplicate';
    test_o.Type = 'New Business';  
    test_o.Dealer_Portal_Opp__c = true;                                     
     insert test_o;                                    
    }
  static testmethod void testDealerPortal(){
    //Create user
        //UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
                   // UserRoleId = portalRole.Id,
                    ProfileId = profile1.Id,
                    Username = System.now().millisecond() + 'test2@test.com1',
                    Alias = 'batman',
                    Email='bruce.wayne@wayneenterprises.com',
                    EmailEncodingKey='UTF-8',
                    Firstname='Bruce',
                    Lastname='Wayne',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    TimeZoneSidKey='America/Chicago'
        );
        
        Database.insert(portalAccountOwner1);
        Account portalAccount1;
        Contact contact1;
        System.runAs(portalAccountOwner1){
        //Create account
        portalAccount1 = new Account(
                        Name = 'TestAccount',
            			ShippingStreet = 'Test',
            			ShippingCity = 'Test',
            			ShippingPostalCode = '123456',
            			ShippingState = 'test',
            			ShippingCountry = 'IN',
                        OwnerId = portalAccountOwner1.Id
        );
        Database.insert(portalAccount1);
        
        //Create contact
        contact1 = new Contact(
        FirstName = 'Test',
        Lastname = 'McTesty',
        AccountId = portalAccount1.Id,
        Email = System.now().millisecond() + 'test@test.com'
		);
		Database.insert(contact1);
		}      
		//Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Dx Partner Community User' Limit 1];
		User user1 = new User(
   			Username = System.now().millisecond() + 'test12345@test.com1',
//    		ContactId = contact1.Id,
    		ProfileId = profile1.Id,
    		Alias = 'test123',
    		Email = 'test12345@test.com',
    		EmailEncodingKey = 'UTF-8',
    		LastName = 'McTesty',
    		CommunityNickname = 'test12345',
    		TimeZoneSidKey = 'America/Los_Angeles',
    		LocaleSidKey = 'en_US',
    		LanguageLocaleKey = 'en_US'
		);
		Database.insert(user1);
        Exception msg;
        Opportunity O = new Opportunity();
    //    RecordType r = [select Id from RecordType Where DeveloperName = 'Dx_EMEA_Record_Type']; removing reference for Dx_EMEA_Record_Type
    RecordType r = [SELECT SobjectType, Id, Name FROM RecordType where SobjectType ='opportunity' AND developername='PKI_Americas_SPI' limit 1];
        test.startTest();
        System.runAs(user1){
            o.name = 'test opp';
            O.StageName = 'Stage 1 - Create/Plan';
            o.RecordTypeId = r.id;
            o.CloseDate = Date.today().adddays(5);
            insert o;
            o.stageName = 'Stage 4 - prove';
         
            update o; 
        }
       test.stopTest();
        List<ProcessInstance> pi = [Select Id,(Select Id From Workitems) From ProcessInstance Where TargetObjectId = :o.id];
      if(pi != null && pi.size()>0){
          Id WorkItemId = pi[0].WorkItems[0].Id;
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
		req2.setComments('Approving request.');
		req2.setAction('Approve');
        req2.setWorkitemId(WorkItemId);
        Approval.ProcessResult result2 =  Approval.process(req2);
      }  
      
      /* this.opp = o;
       this.user2 = user1;
      System.runAs(user1){
		 try{
               o.stageName = 'Closed/Won';
               update o; 
            }
         catch(Exception e){
                msg = e;
            }*/
		
     // }
     }
    static testmethod void testDealerPortal2(){
       Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
                   // UserRoleId = portalRole.Id,
                    ProfileId = profile1.Id,
                    Username = System.now().millisecond() + 'test2@test.com1',
                    Alias = 'batman',
                    Email='bruce.wayne@wayneenterprises.com',
                    EmailEncodingKey='UTF-8',
                    Firstname='Bruce',
                    Lastname='Wayne',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    TimeZoneSidKey='America/Chicago'
        );
        
        Database.insert(portalAccountOwner1);
        Account portalAccount1;
        Contact contact1;
        System.runAs(portalAccountOwner1){
        //Create account
        portalAccount1 = new Account(
                        Name = 'TestAccount',
            			ShippingStreet = 'Test',
            			ShippingCity = 'Test',
            			ShippingPostalCode = '123456',
            			ShippingState = 'test',
            			ShippingCountry = 'IN',
                        OwnerId = portalAccountOwner1.Id
        );
        Database.insert(portalAccount1);
        
        //Create contact
        contact1 = new Contact(
        FirstName = 'Test',
        Lastname = 'McTesty',
        AccountId = portalAccount1.Id,
        Email = System.now().millisecond() + 'test@test.com'
		);
		Database.insert(contact1);
		}      
		//Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Dx Partner Community User' Limit 1];
		User user1 = new User(
   			Username = System.now().millisecond() + 'test12345@test.com1',
//    		ContactId = contact1.Id,
    		ProfileId = profile1.Id,
    		Alias = 'test123',
    		Email = 'test12345@test.com',
    		EmailEncodingKey = 'UTF-8',
    		LastName = 'McTesty',
    		CommunityNickname = 'test12345',
    		TimeZoneSidKey = 'America/Los_Angeles',
    		LocaleSidKey = 'en_US',
    		LanguageLocaleKey = 'en_US'
		);
		Database.insert(user1);
        Exception msg;
        Opportunity O = new Opportunity();
     //   RecordType r = [select Id from RecordType Where DeveloperName = 'Dx_EMEA_Record_Type']; removing reference for Dx_EMEA_Record_Type 
        RecordType r = [SELECT SobjectType, Id, Name FROM RecordType where SobjectType ='opportunity' AND developername='PKI_Americas_SPI' limit 1];
        System.runAs(user1){
            o.name = 'test opp';
            O.StageName = 'Stage 1 - Create/Plan';
            o.RecordTypeId = r.id;
            o.CloseDate = Date.today().adddays(5);
            insert o;
            o.stageName = 'Stage 4 - prove';
         
            update o; 
        }
       test.startTest();
        List<ProcessInstance> pi = [Select Id,(Select Id From Workitems) From ProcessInstance Where TargetObjectId = :o.id];
        if(pi != null && pi.size()>0){
        Id WorkItemId = pi[0].WorkItems[0].Id;
         Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
		req2.setComments('Approving request.');
		req2.setAction('Approve');
        req2.setWorkitemId(WorkItemId);
        Approval.ProcessResult result2 =  Approval.process(req2);
        }
	   system.debug('Stage now' + o.StageName);
        
        
       System.runAs(user1){
		 try{
               o.stageName = 'Closed Won';
               update o; 
            }
         catch(Exception e){
                msg = e;
            }
		
     }
        Attachment att = new Attachment();
        att.parentId = o.id;
        att.Name ='Quote';
        att.body = Blob.valueof('Empty test');
        insert att;
        
        ContentVersion contentVersion = new ContentVersion(
  			 Title = 'Quote New',
 			 PathOnClient = 'Quote.docx',
  			 VersionData = Blob.valueOf('Test Content')
			);
			insert contentVersion;    
		List<ContentDocument> cd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = cd[0].id;
        cl.LinkedEntityId = o.id;
        cl.ShareType = 'V';
        upsert cl;
        o.StageName = 'Closed Won';
        update o;
	 test.stopTest();
    }
  }
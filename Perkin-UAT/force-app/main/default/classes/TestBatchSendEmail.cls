@isTest
private class TestBatchSendEmail {
    
    static testMethod void myUnitTest() { 
        Lead myLead = new Lead();
        myLead.FirstName = 'Jack';
        myLead.LastName = 'T Ripper';
        myLead.Email = 'Jack@Ripper.net';
        myLead.Company = 'Rippers & Co.';
        myLead.Status = 'Open';
        insert myLead;
        
        Lead myLead2 = new Lead();
        myLead2.FirstName = 'Omar';
        myLead2.LastName = 'Little';
        myLead2.Email = 'Omar@Little.com';
        myLead2.Company = 'Stick Em Up';
        myLead2.Status = 'Open';
        insert myLead2;
        
             test.startTest();  
            //custom settings insertion Open_Lead_Notice__c 
            Open_Lead_Notice__c leadNotice = new Open_Lead_Notice__c();
            leadNotice.Name = '2';
            leadNotice.Id1__c = myLead.id;
            leadNotice.Id2__c = mylead2.id;
            insert leadNotice;
            
            //Send_mail_settings insertion
            Send_Mail_Settings__c sm = new Send_Mail_Settings__c();
            sm.name = 'mail settings';
            sm.bcc_mails__c = 'test@testmail.com;sendmail@mail.com';
            sm.allowed_productlines__c = 'AA; AMS; ASO; GC; ICP; IR; LC; LCM; MAS; One Source: Multi-vendor; One Source: Qualification; One Source: Relocation; One Source: Training; RAM; Service Contract; SVC; TEA; TOF; UVS';
            insert sm;
            
            //Lead  insertion
            String countryNames = Label.CountryEmailInclude;
            List<String> countriesInclude = countryNames.split(',');
            List<Lead> leadsToInsert = new List<Lead>();
            for(Integer i=0;i<5;i++)
            {
                Lead leadRec = new Lead();
                leadRec.LastName = 'Name'+i;
                leadRec.product_Line__c='AA';
                leadRec.Company='Company'+i;
                leadRec.Country=countriesInclude.get(i);
                leadRec.Status='Open';
                
                Date myDate = Date.today().addDays(-7);
                Time myTime = Time.newInstance(8, 0, 0, 0);
                DateTime dt1 = DateTime.newInstanceGMT(myDate, myTime);
                
                leadRec.CreatedDate=dt1;
                leadRec.LastModifiedDate=dt1;
                // serializing the sobject to string.
                string leadJSON=JSON.serialize(leadRec);
                // De-serializing the string back to sobject
                Lead ll = (Lead) JSON.deserialize(leadJSON, Lead.class );
                leadsToInsert.add(ll);									
                
            }
        insert leadsToInsert;
        //System.debug('**** leadsToInsert before '+[ select id,name,LastModifiedDate,createddate from lead where name='Name0']);
        //Lead l = [ select id,name,LastModifiedDate from lead where name='Name0'];
       
        //call batch method
            BatchSendMail bse = new BatchSendMail();
            Database.executeBatch(bse);
            
        test.stopTest();
    }
    
    static testMethod void testScheduleSendEmail(){
        test.startTest();
            //Send_mail_settings insertion
            Send_Mail_Settings__c sm = new Send_Mail_Settings__c();
            sm.name = 'mail settings';
            sm.bcc_mails__c = 'test@testmail.com;sendmail@mail.com';
            sm.Schedule_send_mail__c = false;
            insert sm; 
            
            Schedule_BatchSendEmail sh1 = new Schedule_BatchSendEmail();
            String sch = '0 0 23 * * ?';
            System.Schedule('Test Schedule', sch, sh1);
        test.stopTest();
    }
}
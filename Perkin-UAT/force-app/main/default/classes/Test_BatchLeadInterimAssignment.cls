@isTest
public class Test_BatchLeadInterimAssignment {

    public static testmethod void testBatch()
    {
       id pid = [Select id from profile where name = 'System Administrator' limit 1].id;
        User u = [select id from User where isActive = true and profileid =: pid limit 1];
        
        Lead_Interim_Assignment__c ll = new Lead_Interim_Assignment__c();
        ll.Start_Date__c = Date.today().addDays(-2);
        ll.End_Date__c = date.today().addDays(7);
        ll.Originial_Owner__c=UserInfo.getUserId();
         ll.Replacement_Owner__c=u.Id;
        insert ll;
        
        Lead l=new lead();
        l.Firstname='test';
        l.lastname='test';
        l.company='test';
        l.phone='123';
        l.status='Open';
        l.Country = 'DE';
        l.OwnerId = UserInfo.getUserId();
        l.CreatedDate = date.today();
        

        insert l;
        system.debug('lead has been inserted '+l);
        
        Test.startTest();
        Batch_LeadinterimAssignment sh1 = new Batch_LeadinterimAssignment();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Territory Check', sch, sh1);
        Test.stopTest();
        
    }
}
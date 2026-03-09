@isTest
public class TestUpdateLeadStatus {
    static testMethod void TestforTask () {
        //create a lead
        Lead l=new lead();
        l.Firstname='test';
        l.lastname='test';
        l.company='test';
        l.phone='123';
        l.status='Open';
        l.Country = 'US';
        l.street = 'test';
        l.city = 'City A';
        insert l;
        
        Task t = new task ();
        t.WhoID = l.id;
        t.Subject='Call';
        t.Status='Completed';
        t.Priority='Normal';
        insert t; 
    }
    
    static testMethod void TestforNote () {
        //create a lead
        Lead l=new lead();
        l.Firstname='test';
        l.lastname='test';
        l.company='test';
        l.phone='123';
        l.status='Open';
        l.Country = 'US';
        l.street = 'test';
        l.city = 'City A';
        insert l;
        
        Note n = new Note();
        n.ParentId = l.Id;
        n.Body = 'Test Note';
        n.Title = 'Test Note';
        insert n;
    }     
}
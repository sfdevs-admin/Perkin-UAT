@isTest
public class CT_TestDataSetupUtility 
{ 

public static Account createTestAccount(String Name, String Phone, String Industry) {
        Account accAccount = new Account(Name = Name,
            Phone = Phone,
            Industry = Industry, 
            BillingStreet = 'Green Street', 
            ShippingStreet = 'Green Street',
            BillingCity = 'NY',
            ShippingCity = 'NY',
            BillingState = 'CA', 
            ShippingState = 'CA',
            BillingPostalCode = '95123', 
            ShippingPostalCode = '95123',
            BillingCountry = 'US', 
            ShippingCountry = 'US',
            Type = 'Vendor', 
            Website = 'www.xyz.com');
        return accAccount;        
    }
    
    public static Case createTestCase(String RTName, String Status, String Subject, String Origin,
         Id AccountId, Id ContactId) {
         Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(RTName).getRecordTypeId();
        //-----------------------------------------------------------------------------------------------T01
        Case cs = new Case(Subject = Subject, Origin = Origin, Status = Status,
            AccountId = AccountId, ContactId = ContactId,
            OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId,INF_Time_Spent__c=11);
        //---------------------------------------------------------------------------------------------- -T01    
        return cs;
    }
    
    public static Contact createTestContact(Id AccountId, String LastName, 
        String FirstName, String Email) {
        Contact conContact = new Contact(AccountId = AccountId,
            LastName = LastName,
            FirstName = FirstName,
            Email = Email);
        return conContact;
    }
    
    public static User createTestUser(String FistName, String LastName, Id ProfileId) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User usr = new User(Email = uniqueName + '@test' + orgId + '.org',
            Username = uniqueName + '@test' + orgId + '.org',            
            Alias = uniqueName.substring(18, 23),
            EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = ProfileId, isActive = true, 
            TimeZoneSidKey='America/Los_Angeles');
        return usr;
    }
    
    public static Lead createTestLead() {
        Lead ldLead = new Lead( LastName = 'Test User',
            Company = 'Test Company',
            Phone = '8005551212',
            Fax = '8005551212',
            Email = 'sumit.shingavi@cloudsherpas.com',
            Street = '123 Main Street',
            City = 'Pleasantville',
            State = 'New Jersey',
            PostalCode = '66666',
            Country = 'US',
            Status = 'New');        
        return ldLead;
    }
    
     public static CaseComment createTestCaseComment(String ParId,String Comments) {
        
        CaseComment cc = new CaseComment(ParentId = ParId,CommentBody = Comments);
        return cc;
    }
}
@isTest
private class DemoClass_Test {    
    
    @testSetup
    static void setupData() {
        Opportunity opportunity_Obj = new Opportunity(name='test demo class opty',closedate= date.newinstance(2015,11,11),stagename='Prospecting',Solution_Area_of_Interest__c='Energy');
         insert opportunity_Obj;
       
        //Create Attachment
        Attachment attachment   = getAttachment(opportunity_Obj.Id, 'Quote Test Attachment', Blob.valueOf('Test Data')); 
        insert attachment;
        
    }    
    
    private testmethod static void testGetAttachments() {
        List<Opportunity> optyList = DemoClass.getAttachments();
        Attachment attachment   =  [SELECT Id FROM Attachment LIMIT 1];
        List<Attachment> attachmentList = DemoClass.getOppAttachments(attachment.Id);
        System.assertEquals(1, attachmentList.size());        
    }
    
    private testmethod static void testUtility() {
        SAI_Lead_Routing_Values__c cc =new SAI_Lead_Routing_Values__c();
        cc.SAI_Values__c = 'Applied Genomics, Maternal Fetal Health, Newborn Screening';
        insert cc;
        Lead LeadRecord = new Lead();
        LeadRecord.FirstName = 'TestUser: ';
        LeadRecord.LastName  = 'Class: ';
        LeadRecord.Title     =  'UnitTest';
        LeadRecord.Street = '225 Blvd';
        LeadRecord.City  = 'Montgomery';                
        LeadRecord.Status = 'Open';
        LeadRecord.Country = 'US';  
        LeadRecord.Company = 'Test';
        LeadRecord.Email = 'usertest-class-@test.com';
        //LeadRecord.BE__c = 'Dx';
        test.startTest();
        insert LeadRecord;
        Utility_Informatics.assignLeads_Informatics(new List<Id>{LeadRecord.Id} );
        test.stopTest();
        
        
    }
    
    private static Attachment getAttachment(Id recId, String name, Blob b) {        
        Attachment attachment = new Attachment();
        attachment.ParentId   = recId;
        attachment.Name       = name;
        attachment.Body       = b;        
        return attachment;        
    }
    
}
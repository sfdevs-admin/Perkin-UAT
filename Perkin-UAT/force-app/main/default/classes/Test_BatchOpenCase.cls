@isTest
public class Test_BatchOpenCase {

   public static testMethod void Opencases()
        {
            Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dx Software Services').getRecordTypeId();
            Case c = new Case();
            c.status='Active';
            c.Subject = 'Test';
            c.RecordtypeId = devRecordTypeId;//'0123A000001GhBbQAK' ;
            c.PKI_GLB_Duplicate_Case__c =false;
            c.DX_Change_Request__c ='Minor';
            c.External_Email_Inbox__c = 'specimen.gate.support.fi@perkinelmer.com';
            c.Ownerid = Userinfo.getUserid();
            c.ClosedDate = Date.today();
            insert c;
            system.debug('case created is c '+c.Owner.Name);
            Test.startTest();
            Schedule_Batch_FetchOpenCases sh1 = new Schedule_Batch_FetchOpenCases();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Territory Check', sch, sh1);
            Test.stopTest();
            
        }
    
    public static testmethod void DeleteCase()
    {
        Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dx Software Services').getRecordTypeId();
        Case c = new Case();
        c.status='In Progress';
        c.Subject = 'Test';
        c.RecordtypeId = devRecordTypeId;//'0123A000001GhBbQAK' ;
        insert c;
        
        Cases_snapshot__c cp = new Cases_snapshot__c();
        cp.Case_Status__c='Open';
        cp.CreatedDate = Date.today().addDays(-93);
        cp.CaseRef__c = c.Id;
        insert cp;
        
        Test.startTest();
        Schedule_Batch_DeletePast3MonthsData shh1 = new Schedule_Batch_DeletePast3MonthsData();
        String schh = '0 0 23 * * ?';
        system.schedule('Test Territory Check', schh, shh1);
        Test.stopTest();
        
    }
}
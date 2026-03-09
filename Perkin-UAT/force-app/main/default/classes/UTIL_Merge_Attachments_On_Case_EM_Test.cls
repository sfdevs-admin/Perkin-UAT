/************************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 ATEAM-1912
* 2. Description - Test class for UTIL_Merge_Attachments_On_Case_EM
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es):
* 6. Invocable: False
*
* 7. Test Class Name: UTIL_Merge_Attachments_On_Case_EM_Test
*
* 8. Author Name(s): 
*    - Aakash 13-04-2023
*
************************************************************************/ 
@isTest
public class UTIL_Merge_Attachments_On_Case_EM_Test {
    @isTest static void testEmailAttachments() {
        UTIL_Merge_Attachments_On_Case_EM.FlowInputs varInputClass= new UTIL_Merge_Attachments_On_Case_EM.FlowInputs();
        varInputClass.newEMList=new list<EmailMessage>();
        varInputClass.oldAttachmentList=new list<Attachment>();
        
        EmailMessage testEmailMessage = new EmailMessage (Subject='test',ccAddress='test@perkinelmer.com.invalid;',MessageDate=Date.Today(),TextBody='test',HtmlBody='test',Incoming = true,Status ='3');
        varInputClass.newEMList.add(testEmailMessage);
        insert varInputClass.newEMList;
        
        varInputClass.newEMList[0].Subject = varInputClass.newEMList[0].Subject + varInputClass.newEMList[0].Id;
        update varInputClass.newEMList;
        
        Attachment testAttachment = new Attachment(Name='test',Body=Blob.valueof('test'),Parentid=varInputClass.newEMList[0].Id);
        varInputClass.oldAttachmentList.add(testAttachment);
        insert varInputClass.oldAttachmentList;
        
        UTIL_Merge_Attachments_On_Case_EM.flowcalled(new list<UTIL_Merge_Attachments_On_Case_EM.FlowInputs>{varInputClass});
    }
    @isTest static void testCaseAttachments() {
        UTIL_Merge_Attachments_On_Case_EM.FlowInputs varInputClass= new UTIL_Merge_Attachments_On_Case_EM.FlowInputs();
        varInputClass.oldAttachmentList=new list<Attachment>();
        varInputClass.parentCaseId = '';
        Account testAccount = new Account(Name = 'testAcc', Phone = '123456789', Industry = 'Industry', BillingStreet = 'Green Street',
                                          ShippingStreet = 'Green Street', BillingCity = 'NY', ShippingCity = 'NY', BillingState = 'CA', 
                                          ShippingState = 'CA', BillingPostalCode = '95123', ShippingPostalCode = '95123', 
                                          BillingCountry = 'US', ShippingCountry = 'US', Type = 'Vendor', Website = 'www.xyz.com');
        insert testAccount;
        
        Contact testContact = new Contact(AccountId = testAccount.Id, LastName = 'LastName', FirstName = 'FirstName', Email = 'Email@email.com');
        insert testContact;
        
        Id testRecordtypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care - General').getRecordTypeId();
        Case testCase = new Case(Subject = 'Subject', Origin = 'Email', Status = 'New', AccountId = testAccount.Id, 
                                 ContactId = testContact.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium', Description = 'test'
                                 ,RecordTypeId = testRecordtypeID);
        insert testCase;
        varInputClass.parentCaseId = testCase.Id;
        
        Attachment testAttachment = new Attachment(Name='test',Body=Blob.valueof('test'),Parentid=varInputClass.parentCaseId);
        varInputClass.oldAttachmentList.add(testAttachment);
        insert varInputClass.oldAttachmentList;
        
        UTIL_Merge_Attachments_On_Case_EM.flowcalled(new list<UTIL_Merge_Attachments_On_Case_EM.FlowInputs>{varInputClass});
    }
}
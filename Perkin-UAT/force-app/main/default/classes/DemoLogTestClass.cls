/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    INC0341178
  * 2. Description - 
  *    Test class for apex class(DemoLogExpirationController).
  *
  *
  * 3. Objects referenced
  *    - Demo Log
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *
  * 6. Test Class Name: DemoLogTestClass
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Roshank Mehra(PWC) 2023.06.19
  * 
  * 
  * 9. Coverage Percentage - 100%
*************************************************************/ 
@isTest
public class DemoLogTestClass {
	@isTest
    public static void TestDemoLogExpiration(){
        PageReference p = Page.DemoLogExpiration;
        test.setCurrentPage(p);
        
        Demo_Log__c d = new Demo_Log__c();
        d.RecordTypeId = Schema.getGlobalDescribe().get('Demo_log__c').getDescribe().getRecordTypeInfosbyName().get('System Request').getRecordTypeid();
		d.Primary_Product_INF__c = 'Registration';
        d.Expiration_Date__c = Date.today();
        d.Assigned_To__c = 'Daniel Ubilla';
        d.System_Days_Active__c = '30 Days';
        insert d;
        
       ApexPages.currentPage().getParameters().put('Id',d.id);
       ApexPages.currentPage().getParameters().put('Days','30 Days');
       ApexPages.currentPage().getParameters().put('typ','Parked'); 
       ApexPages.currentPage().getParameters().put('Status','OFF');  
        
        DemoLogExpirationController dc = new DemoLogExpirationController();
        dc.submit();
        
    }
}
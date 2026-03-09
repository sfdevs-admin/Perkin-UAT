/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1556
  *
  * 2. Description - This class is a test class for sbx_activate
  *
  * 3. Objects referenced
  *    - None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: Test_sbx_activate
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal (2022.01.07)
  *	   - Aakash Pal (2022.01.10)
  *
*************************************************************/ 
@isTest
class Test_sbx_activate {

    @isTest
    static void testMySandboxPrep() {
        
        Test.startTest();

        Test.testSandboxPostCopyScript(
            new sbx_activate(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

        Test.stopTest();
    }
}
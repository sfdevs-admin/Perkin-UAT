/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Delete_AsyncRecord Apex class
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None 
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: true
  *    FutureMethod=true
  *
  * 7. Test Class Name: UTIL_Delete_AsyncRecord_Test
  *
  * 8. Author Name(s): 
  *    - Vishwas 22-02-2023
  *
*************************************************************/
@isTest
public class UTIL_Delete_AsyncRecord_Test {
		@isTest static void testflowcalled() {
        test.startTest();
        UTIL_Delete_AsyncRecord.FlowInputs varInputClass= new UTIL_Delete_AsyncRecord.FlowInputs();
        varInputClass.RecId='123456789abcdef';
        UTIL_Delete_AsyncRecord.flowcalled(new list<UTIL_Delete_AsyncRecord.FlowInputs>{varInputClass});
        test.stopTest();
   }
}
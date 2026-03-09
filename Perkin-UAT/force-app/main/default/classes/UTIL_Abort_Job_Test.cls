/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Abort_Job Apex class
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None 
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: False
  *
  * 7. Test Class Name: UTIL_Abort_Job_Test
  *
  * 8. Author Name(s): 
  *    - Aakash/Vishwas 31-01-2023
  *
*************************************************************/
@isTest
public class UTIL_Abort_Job_Test {

	@isTest static void testflowcalled() {
        test.startTest();
        UTIL_Abort_Job.FlowInputs varInputClass= new UTIL_Abort_Job.FlowInputs();
        varInputClass.JobId='123456789abcdef';
        UTIL_Abort_Job.flowcalled(new list<UTIL_Abort_Job.FlowInputs>{varInputClass});
        test.stopTest();
   }
}
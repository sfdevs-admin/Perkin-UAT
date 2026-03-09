/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Convert_Collection_to_String Apex class
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
  * 7. Test Class Name: UTIL_Convert_Collection_to_String_Test
  *
  * 8. Author Name(s): 
  *    - Aakash/Vishwas 22-09-2022 
  *
*************************************************************/ 
@isTest
public class UTIL_Convert_Collection_to_String_Test {
	  @testSetup static void methodName() {

     }
    @isTest static void testsemicolon() {
        UTIL_Convert_Collection_to_String.FlowInputs varInputClass= new UTIL_Convert_Collection_to_String.FlowInputs();
        varInputClass.liststring=new list<string>{'abc','xyz','def'};
        UTIL_Convert_Collection_to_String.flowcalled(new list<UTIL_Convert_Collection_to_String.FlowInputs>{varInputClass});
   }
  
}
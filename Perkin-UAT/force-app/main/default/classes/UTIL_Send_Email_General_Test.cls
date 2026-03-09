/************************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 ATEAM-1995, INC0372679
* 2. Description - test class for Utility class (UTIL_Send_Email_General) for sending email
* 3. Objects referenced
*    -EmailMessage
*	 -Attachment
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es): UTIL_Send_Email_General
* 6. Invocable: True
*
* 7. Test Class Name: UTIL_Send_Email_General_Test
*
* 8. Author Name(s): 
*    - AP/VG 09-08-2023
*
************************************************************************/ 
@isTest
public class UTIL_Send_Email_General_Test {
	  @testSetup static void methodName() {

     }
    @isTest static void testEmailMethodPositive() {
        UTIL_Send_Email_General.FlowInputs varInputClass= new UTIL_Send_Email_General.FlowInputs();
        varInputClass.varFromAddress='sfdc@perkinelmer.com';
        varInputClass.multiToAddress=new list<string>{'abc@test.com','xyz@test.com','def@test.com'};
        varInputClass.multiCcAddress=new list<string>{'abc@test.com','xyz@test.com','def@test.com'};
        varInputClass.varSubject='test Subject';
        varInputClass.varBody='test body'; 
        UTIL_Send_Email_General.flowcalled(new list<UTIL_Send_Email_General.FlowInputs>{varInputClass});
    }
      @isTest static void testEmailMethodNegative() {
        UTIL_Send_Email_General.FlowInputs varInputClass= new UTIL_Send_Email_General.FlowInputs();
        varInputClass.varFromAddress=null;
        varInputClass.multiToAddress=null;
        varInputClass.multiCcAddress=null;
        varInputClass.varSubject='test Subject';
        varInputClass.varBody='test body'; 
        UTIL_Send_Email_General.flowcalled(new list<UTIL_Send_Email_General.FlowInputs>{varInputClass});
    }
}
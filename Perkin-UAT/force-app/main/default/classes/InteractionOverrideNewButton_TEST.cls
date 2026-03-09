/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - SSE-40
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    
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
* 6. Main Class Name: InteractionOverrideNewButtonController
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s): 
*    - First Last & Updated Date(2021.10.08) 
*    - (PWC) Abhijit  (2024.05.07)
*
*************************************************************/ 

@isTest
public class InteractionOverrideNewButton_TEST {
    
    
    @isTest
    static void testCheckInfinteractionUserPermisson() {
        Test.startTest();
        Boolean hasPermission = InteractionOverrideNewButtonController.checkInfInteractionUserPermisson();
        Test.stopTest();
    }

}
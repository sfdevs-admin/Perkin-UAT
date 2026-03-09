/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - OPP-121
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    We need to override the default "New" Opportunity button on list views. Certain users are allowed to create
*    opportunities uing the legacy method, while others are required to use a S.FLOW 2000 method. This is controlled by a user
*    P.SET "CUSTOM: C.PERM 8040 Create Opp using Legacy New Button".  
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
* 6. Test Class Name: oppOverrideNewButtonController_TEST
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s): 
*    - (PwC Amiya Das) (2021.09.24)
*    - First Last & Updated Date(2021.10.08) 
*
*************************************************************/ 
public class oppOverrideNewButtonController {
    
    /*
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────-------
* @description      Returns true when User is assigned custom permission as 'C_PERM_8040_New_Opp_Legacy'
* @parameter        None
* @returnValue      Boolean
* @example          FeatureManagement.checkPermission('C_PERM_8040_New_Opp_Legacy');(this will check custom permission)
* ──────────────────────────────────────────────────────────────────────────────────────────────────────────────--------
*/
    // to be used in aura component
    @AuraEnabled
    public static boolean checkInfOppUsrPermisson(){
        
        
            // to check the custom permission
            Boolean checkBool = FeatureManagement.checkPermission('C_PERM_8040_New_Opp_Legacy');
            
            // return boolean if custom permission is assigned
            return checkBool;
        
    }
    
}
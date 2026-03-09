/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - SSE-40
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    We need to override the default "New" Interaction button on list views. Certain users are allowed to create
*    Interaction uing the legacy method, while others are required to use a "https://info.revvity.com/LP=13732"link. This is controlled by a user
*    P.SET "CUSTOM: C.PERM 2530: Create Interaction Using Legacy New Button".  
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
* 6. Test Class Name: InteractionOverrideNewButton_TEST 
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s): 
*    - (PwC) Abhijit Shelake (2024.05.02)
*    
*
*************************************************************/ 
public class InteractionOverrideNewButtonController {
    
    /*
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────-------
* @description      Returns true when User is assigned custom permission as 'C_PERM_2530_New_Interaction_Legacy	' and running user obc !=LSDX
* @parameter        None
* @returnValue      Boolean
* @example          FeatureManagement.checkPermission('C_PERM_2530_New_Interaction_Legacy');(this will check custom permission)
* ──────────────────────────────────────────────────────────────────────────────────────────────────────────────--------
*/
    // to be used in aura component
    @AuraEnabled
    public static boolean checkInfInteractionUserPermisson(){
        
         // Get the Id of the current user
        Id currentUserId = UserInfo.getUserId();

        // Query for the user details
        User userDetails = [SELECT Id, Name, Owned_by_Company__c FROM User WHERE Id = :currentUserId LIMIT 1];        
       // to check the custom permission
       Boolean checkBool = FeatureManagement.checkPermission('C_PERM_2530_New_Interaction_Legacy');


        if (userDetails.Owned_by_Company__c!='LSDX' || checkBool==TRUE )
        {
           

             // return boolean if custom permission is assigned Or Current user OBC is not LSDX
            return TRUE;          
        }
        else
        {
         
          return FALSE;  
        }
      
        
                
    }
    
}
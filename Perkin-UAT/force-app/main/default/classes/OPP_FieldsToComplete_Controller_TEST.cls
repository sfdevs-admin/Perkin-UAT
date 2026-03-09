/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - INC0294925 - Used to show Field to complete Values on Community Portal for Dealers
  * 
  *
  * 2. Description - INC0294925 - Used to show Field to complete Values on Community Portal for Dealers 
  *      becuase quick actions, field sets, and lighthning grid are not useable in Portal
  *
  *
  * 3. Objects referenced
  *    -Opportunity
  *    
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *    - Component.Method  
  *    - Component.Method
  *
  * 5. Dependant Class(es):
  *    - OPP_FieldsToComplete_Controller
  *  
  *
  * 6. Test Class Name: OPP_FieldsToComplete_Controller_TEST
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Avinash Kumar(PWC)
  *
*************************************************************/ 
@isTest
public class OPP_FieldsToComplete_Controller_TEST {
    
    public static testmethod void testOPP_FieldsToComplete_Controller(){
        
        test.startTest();
      //create test data for user object
  
       Id profileId = PKI_Data_Factory.getProfileId('System Administrator');

       /*Start--User Creation */
        User userRecord = (User) PKI_Data_Factory.createSObject(
          new User(ProfileId = profileId),
          false 
        );
        PKI_Data_Factory.createSObject(userRecord, true);
       /*End--User Creation */ 
        //Create Mock permissions
        
        system.runAs(userRecord){
            OPP_FieldsToComplete_Controller opp = new OPP_FieldsToComplete_Controller();
            opp.showOpp(); 
            
        }
        test.stopTest();
    }

}
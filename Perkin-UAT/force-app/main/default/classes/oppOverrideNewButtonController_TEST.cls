/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ITSFDC-####
  *    - ITSFDC-####
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *
  *
  *
  * 3. Objects referenced
  *    -Object Name
  *    -Object Name
  *    -Object Name
  *    -Object Name 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *    - Component.Method  
  *    - Component.Method
  *
  * 5. Dependant Class(es):
  *    - ClassName
  *    - ClassName
  *    - ClassName
  *
  * 6. Test Class Name: Test_Class_Name
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Amiya Das(PWC)
  *
*************************************************************/ 
@isTest
public class oppOverrideNewButtonController_TEST {
    
    public static testmethod void testcheckInfOppUsrPermisson(){
        
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
        PermissionSet ps = new PermissionSet(Label = 'mockPs', Name = 'mockPs');
        insert ps;

        // Given custom permission associated to the mocked PermissionSet
        SetupEntityAccess sea = new SetupEntityAccess(
                                    ParentId = ps.Id,
                                    SetupEntityId = [SELECT Id FROM CustomPermission
                                    WHERE DeveloperName = 'C_PERM_8040_New_Opp_Legacy'][0].Id
                                    );
        insert sea;
        // Given mocked Permission Set assigned to user for test
        PermissionSetAssignment psa = new PermissionSetAssignment(
                                            AssigneeId = userRecord.id,
                                            PermissionSetId = ps.Id
                                            );
        insert psa;
        system.runAs(userRecord){
            oppOverrideNewButtonController.checkInfOppUsrPermisson(); 
            
        }
        test.stopTest();
    }

}
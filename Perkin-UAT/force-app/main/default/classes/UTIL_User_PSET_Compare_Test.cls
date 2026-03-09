/**************************************************************
* 1. Jira Ticket(s) that relates to this class- ATEAM-1860
*
* 2. Description - This class does this work:
				   LKUP PermissionSetAssignment for User 1 as lstPSAUserA_id
				   LKUP PermissionSetAssignment for user 2 as  lstPSAUserB_id
				   LKUP PermissionSet.Label where in lstPSAUserA_id as lstPSAUserA_label
				   LKUP PermissionSet.Label where in lstPSAUserB_id as lstPSAUserB_label 
				   Compare lstPSAUserA to lstPSAUserB
*
*
*
* 3. Objects referenced-PermissionSet
* 	 				   -user
* 	 				   -PermissionSetAssignment
* 	 
*
* 4. Callouts to additional Components (including their methods) or None:- None
* 
*
* 5. Dependant Class(es):- None
*
* 6. Test Class Name: UTIL_User_PSET_Compare_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):- Sumit Sourav & Updated Date(2022.11.11)
*
*************************************************************/
@isTest
public class UTIL_User_PSET_Compare_Test {
    static testMethod void psetcompare() {
        Profile p = [select id 
                     from 
                     Profile 
                     where 
                     Name LIKE '%DAS Operations%']; 
        User User1 = new user(alias = 'test123', email='test123@noemail.com',emailencodingkey='UTF-8', 
                              firstName='Nahush', lastname='Testing', languagelocalekey='en_US',
                              localesidkey='en_IN', profileid = p.Id, country='India',
                              timezonesidkey='Asia/Kolkata', username='test_g1@noemail.com'); 
        insert User1;
        User User2 = new user(alias = 'test1234', email='test1234@noemail.com',emailencodingkey='UTF-8', 
                              firstName='Nahush', lastname='Testing', languagelocalekey='en_US',
                              localesidkey='en_IN', profileid = p.Id, country='India',
                              timezonesidkey='Asia/Kolkata', username='test_g2@noemail.com'); 
        insert User2;
        
        PermissionSet ps1 = new PermissionSet(Label = 'mockPs1', Name = 'mockPs1');
        insert ps1;
        PermissionSet ps2 = new PermissionSet(Label = 'mockPs2', Name = 'mockPs2');
        insert ps2;
        PermissionSet ps3 = new PermissionSet(Label = 'mockPs3', Name = 'mockPs3');
        insert ps3;
        PermissionSet ps4 = new PermissionSet(Label = 'mockPs4', Name = 'mockPs4');
        insert ps4;
        PermissionSetAssignment psa1 = new PermissionSetAssignment(AssigneeId = User1.Id,PermissionSetId = ps1.Id);
        insert psa1;
        PermissionSetAssignment psa2 = new PermissionSetAssignment(AssigneeId = User2.Id,PermissionSetId = ps2.Id);
        insert psa2;
        PermissionSetAssignment psa3 = new PermissionSetAssignment(AssigneeId = User1.Id,PermissionSetId = ps3.Id);
        insert psa3;
        PermissionSetAssignment psa4 = new PermissionSetAssignment(AssigneeId = User2.Id,PermissionSetId = ps3.Id);
        insert psa4;
        UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Input wrprinpt=new UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Input();
        List<UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Input> wrprinptlst=new List<UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Input>();
        UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Output wrprotpt=new UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Output();
        List<UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Output> wrprotptlst=new List<UTIL_User_PSET_Compare.UTIL_User_PSET_Compare_Wrapperclass_Output>();
        
        wrprinpt.User1=User1.Id;
        wrprinpt.User2=User2.Id;
        wrprinptlst.add(wrprinpt);
        wrprotptlst=UTIL_User_PSET_Compare.psacompare(wrprinptlst);
    }
    
}
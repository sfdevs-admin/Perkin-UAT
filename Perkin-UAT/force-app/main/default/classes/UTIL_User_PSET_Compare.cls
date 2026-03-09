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
public class UTIL_User_PSET_Compare {
    public class UTIL_User_PSET_Compare_Wrapperclass_Input{
        
        @InvocableVariable(required=true) public Id User1;
        @InvocableVariable(required=true) public ID User2;
        
    }
    public class UTIL_User_PSET_Compare_Wrapperclass_Output{
        
        @InvocableVariable public List<ID>inAnotB_ids=new List<ID>();
        @InvocableVariable public List<ID>inBnotA_ids=new List<ID>();
        @InvocableVariable public List<ID>inAandB_ids=new List<ID>();
        @InvocableVariable public List<ID>notinAandB_ids=new List<ID>();
        @InvocableVariable public List<String>inAnotB_labels=new List<String>();
        @InvocableVariable public List<String>inBnotA_labels=new List<String>();
        @InvocableVariable public List<String>inAandB_labels=new List<String>();
        @InvocableVariable public List<String>notinAandB_labels=new List<String>();
    }
    
    @InvocableMethod(label='UTIL_User_PSET_Compare')
    public static List<UTIL_User_PSET_Compare_Wrapperclass_Output> psacompare(List<UTIL_User_PSET_Compare_Wrapperclass_Input> useridlst) {
        List<UTIL_User_PSET_Compare_Wrapperclass_Output> psetidandlabellst=new List<UTIL_User_PSET_Compare_Wrapperclass_Output>();
        UTIL_User_PSET_Compare_Wrapperclass_Output psetidandlabelsingleInstance=new UTIL_User_PSET_Compare_Wrapperclass_Output(); 
        id usr1id;
        id usr2id;
        IF(useridlst.size()==1){
            usr1id=useridlst[0].User1;
            usr2id=useridlst[0].User2;
        }
        List<permissionsetassignment> user1psa=new List<permissionsetassignment>();
        List<permissionsetassignment> user2psa=new List<permissionsetassignment>();
        user1psa=[SELECT Id, PermissionSetId, PermissionSet.label, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId=:usr1id AND PermissionSet.IsOwnedByProfile = false];
        user2psa=[SELECT Id, PermissionSetId, PermissionSet.label, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId=:usr2id AND PermissionSet.IsOwnedByProfile = false];
        for(permissionsetassignment psa1:user1psa)
        {
            String psetid=psa1.PermissionSetId;
            String psetlabel=psa1.PermissionSet.label;
            Boolean foundinpsa2=false;
            for(permissionsetassignment psa2:user2psa)
            {
                If(psetid==psa2.PermissionSetId)
                {
                    foundinpsa2=true;
                    psetidandlabelsingleInstance.inAandB_ids.add(psetid);
                    psetidandlabelsingleInstance.inAandB_labels.add(psetlabel);
                }
            }
            
            If(foundinpsa2==false)
            { 
                psetidandlabelsingleInstance.inAnotB_ids.add(psetid);
                psetidandlabelsingleInstance.inAnotB_labels.add(psetlabel);
            }
        }
        
        for(permissionsetassignment psa2:user2psa)
        {
            String pset2id=psa2.PermissionSetId;
            String pset2label=psa2.PermissionSet.label;
            Boolean foundinpsa1=false;
            for(permissionsetassignment psa1:user1psa)
            {
                If(pset2id==psa1.PermissionSetId)
                {
                    foundinpsa1=true;
                }
            }
            If(foundinpsa1==false)
            { 
                psetidandlabelsingleInstance.inBnotA_ids.add(pset2id);
                psetidandlabelsingleInstance.inBnotA_labels.add(pset2label);
            }
        }
        
        Set<ID> notinAandB_idsSet=new Set<Id>();
        Set<String> notinAandB_labelsSet=new Set<String>();
        for(Id i:psetidandlabelsingleInstance.inAnotB_ids){
            notinAandB_idsSet.add(i) ;
        }
        for(Id i:psetidandlabelsingleInstance.inBnotA_ids){
            notinAandB_idsSet.add(i) ;
        }
        
        psetidandlabelsingleInstance.notinAandB_ids.addAll(notinAandB_idsSet);
        
        for(String i:psetidandlabelsingleInstance.inAnotB_labels){
            notinAandB_labelsSet.add(i) ;
        }
        for(String i:psetidandlabelsingleInstance.inBnotA_labels){
            notinAandB_labelsSet.add(i) ;
        }
        psetidandlabelsingleInstance.notinAandB_labels.addAll(notinAandB_labelsSet);
        psetidandlabellst.add(psetidandlabelsingleInstance);
        return psetidandlabellst;
        
    }
}
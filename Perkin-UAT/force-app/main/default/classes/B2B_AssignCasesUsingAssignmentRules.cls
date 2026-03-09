/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 10-01-2025
 * @last modified by  : Swati Chilap
 * @TestClass         : B2B_AssignCasesUsingAssignmentRulesTest
**/
public without sharing class B2B_AssignCasesUsingAssignmentRules {
    @InvocableMethod(Label='B2B Assign Cases Using Assignment Rules' Description='Set up the option to trigger assignemtn rules on case creation')
    public static void CaseAssign(List<Id> caseIds) {
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
                 
        Case cases = [SELECT Id FROM Case WHERE Id IN :caseIds];
        cases.setOptions(dmo);
        update cases;
    }
}
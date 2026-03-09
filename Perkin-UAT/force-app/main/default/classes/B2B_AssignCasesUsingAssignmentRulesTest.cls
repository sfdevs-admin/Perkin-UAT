/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 10-01-2025
 * @last modified by  : Swati Chilap
**/
@IsTest
public with sharing class B2B_AssignCasesUsingAssignmentRulesTest {
    @TestSetup
    static void makeData(){
        Account acc = B2B_TestDataFactory.createAccount('TestAccount', true);
        Contact con = B2B_TestDataFactory.createContact('TestContact', acc.Id, true);
        Case testCase = new Case(
            Subject = 'Test Case',
            Origin = 'Email',
            Status = 'New',
            AccountId = acc.Id,
            ContactId = con.Id
        );
        insert testCase;

    }
    @IsTest
    static void testCaseAssign() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        B2B_AssignCasesUsingAssignmentRules.CaseAssign(new List<Id>{c.Id});
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];
        
        System.assertNotEquals(null, updatedCase.OwnerId, 'Case should have an Owner assigned (assignment rule executed)');
    }
}
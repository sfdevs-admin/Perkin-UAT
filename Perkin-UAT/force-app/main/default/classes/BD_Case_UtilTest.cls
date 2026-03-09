@isTest
public class BD_Case_UtilTest {
    @isTest
    public static void testGetCaseThreadTokens(){
        Case c = new Case();
        insert c;
        
        BD_Case_Util.FlowInput input = new BD_Case_Util.FlowInput();
        input.caseId = c.Id;
        List<BD_Case_Util.FlowInput> inputs = new List<BD_Case_Util.FlowInput>{input};

        Test.startTest();
        BD_Case_Util.getCaseThreadTokens(inputs);
        Test.stopTest();
    }
}
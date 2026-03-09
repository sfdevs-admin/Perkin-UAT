public class BD_Case_Util {
    public static String getCaseThreadToken(Id caseId){
        return EmailMessages.getFormattedThreadingToken(caseId);
    }

    public class FlowInput {
        @InvocableVariable(label='Case ID' required=true)
        public Id caseId;
    }

    @InvocableMethod(label='Get Case Thread Token' description='Get Case Thread Token')
    public static List<String> getCaseThreadTokens(List<FlowInput> inputs) {
        List<String> threadTokens = new List<String>();
        for (FlowInput input: inputs) {
            threadTokens.add(getCaseThreadToken(input.caseId));
        }
        return threadTokens;
    }
}
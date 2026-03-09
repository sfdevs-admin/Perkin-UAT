/**
 * Created by Tony Herrington on 2019-06-04 per SC-107.
 */

public class BD_Auto_Reply_Utils {
   
    @InvocableMethod
    public static List<FlowOutputs> sendAutoReplies(List<FlowInputs> requests) {
        System.debug('BD_Auto_Reply_Utils.sendAutoReplies: ' + requests);
        FlowOutputs output = new FlowOutputs();
        List<FlowOutputs> results = new List<FlowOutputs>();
        
        // Get the individual string values from the Label named DB_No_AutoReply_Email_Values 
        String noAutoReplyEmailValues = System.Label.BD_No_AutoReply_Email_Values;
        System.debug('BD_No_AutoReply_Email_Values: ' + noAutoReplyEmailValues);
        List<String> lstNoAutoReplyEmailValues = noAutoReplyEmailValues.Split(',');
        
        // Get the individual string values from the Label named BD_No_AutoReply_Subjects_Values 
        String noAutoReplySubjectsValues = System.Label.BD_No_AutoReply_Subjects_Values;
        System.debug('BD_No_AutoReply_Subjects_Values: ' + noAutoReplySubjectsValues);
        List<String> lstNoAutoReplySubjectsValues = noAutoReplySubjectsValues.Split(',');
        
        for (FlowInputs request : requests) {
            System.debug('request :' + request);
            Boolean match = false;
            
            // Check if this request contains any of the values in DB_No_AutoReply_Email_Values
            System.debug('Checking DB_No_AutoReply_Email_Values');
            for (String noAutoReplyEmailValue : lstNoAutoReplyEmailValues){
                noAutoReplyEmailValue = noAutoReplyEmailValue.trim();
                
                if (request.emailAddress.containsIgnoreCase(noAutoReplyEmailValue)){
                    System.debug('Match Found for: [' + noAutoReplyEmailValue + '] in [' + request.emailAddress + ']');
                    match = true;
                } else {
                    System.debug('No Match for: [' + noAutoReplyEmailValue + '] in [' + request.emailAddress + ']');
                }
            }
            
            // Check if this request contains any of the values in BD_No_AutoReply_Subjects_Values
            System.debug('Checking BD_No_AutoReply_Subjects_Values');
            for (String noAutoReplySubjectsValue : lstNoAutoReplySubjectsValues){
                noAutoReplySubjectsValue = noAutoReplySubjectsValue.trim();
                
                if (request.subjectLine.containsIgnoreCase(noAutoReplySubjectsValue)){
                    System.debug('Match Found for: [' + noAutoReplySubjectsValue + '] in [' + request.subjectLine + ']');
                    match = true;
                } else {
                    System.debug('No Match for:  [' + noAutoReplySubjectsValue + '] in [' + request.subjectLine + ']');
                }
            }
            
            if (match){
                output.result = false;
            } else {
                output.result = true;
            }
            results.add(output);
        }
        System.debug('BD_Auto_Reply_Utils.sendAutoReplies: ' + results);
        return results;
    }
    
    //input details that comes to apex from flow
    public class FlowInputs{
    
        @InvocableVariable(required=true)
        public String emailAddress;
        
        @InvocableVariable(required=true)
        public String subjectLine;
        
    }
    
    //output details which goes from apex to flow
    public class FlowOutputs{
        
        @InvocableVariable
        public Boolean result;
    }
}
/**
 * Created by Tony Herrington on 2019-06-06 per SC-107.
 */

@IsTest
private class BD_Auto_Reply_Utils_UT {

    @isTest
    static void testInvalidEmailAddressValue()
    {
        // Setup variables and test values
        String emailAddress = 'pleasedonotreply@test.com';
        String subjectLine = 'This is a subject line';
        BD_Auto_Reply_Utils.FlowInputs request = new BD_Auto_Reply_Utils.FlowInputs();
        List<BD_Auto_Reply_Utils.FlowInputs> requests = new List<BD_Auto_Reply_Utils.FlowInputs>();
        request.emailAddress = emailAddress;
        request.subjectLine = subjectLine;
        requests.add(request);
        System.debug('Input: ' + requests);
        BD_Auto_Reply_Utils.FlowOutputs output = new BD_Auto_Reply_Utils.FlowOutputs();
        List<BD_Auto_Reply_Utils.FlowOutputs> outputs = new List<BD_Auto_Reply_Utils.FlowOutputs>();


        // Call the sendAutoReplies method
        outputs = BD_Auto_Reply_Utils.sendAutoReplies(requests);
        System.debug('Outputs: ' + outputs);

        output = outputs[0];
        System.assert(output.result == false, 'Output should have been false for emailAddress = ' + emailAddress);
    }

    @isTest
    static void testValidEmailAddressValue()
    {
        // Setup variables and test values
        String emailAddress = 'pleasedoreply@test.com';
        String subjectLine = 'This is a subject line';
        BD_Auto_Reply_Utils.FlowInputs request = new BD_Auto_Reply_Utils.FlowInputs();
        List<BD_Auto_Reply_Utils.FlowInputs> requests = new List<BD_Auto_Reply_Utils.FlowInputs>();
        request.emailAddress = emailAddress;
        request.subjectLine = subjectLine;
        requests.add(request);
        System.debug('Input: ' + requests);
        BD_Auto_Reply_Utils.FlowOutputs output = new BD_Auto_Reply_Utils.FlowOutputs();
        List<BD_Auto_Reply_Utils.FlowOutputs> outputs = new List<BD_Auto_Reply_Utils.FlowOutputs>();


        // Call the sendAutoReplies method
        outputs = BD_Auto_Reply_Utils.sendAutoReplies(requests);
        System.debug('Outputs: ' + outputs);

        output = outputs[0];
        System.assert(output.result == true, 'Output should have been true for emailAddress = ' + emailAddress);
    }

    @isTest
    static void testInvalidSubjectValue()
    {
        // Setup variables and test values
        String emailAddress = 'pleasedoreply@test.com';
        String subjectLine = 'This is a no reply subject line';
        BD_Auto_Reply_Utils.FlowInputs request = new BD_Auto_Reply_Utils.FlowInputs();
        List<BD_Auto_Reply_Utils.FlowInputs> requests = new List<BD_Auto_Reply_Utils.FlowInputs>();
        request.emailAddress = emailAddress;
        request.subjectLine = subjectLine;
        requests.add(request);
        System.debug('Input: ' + requests);
        BD_Auto_Reply_Utils.FlowOutputs output = new BD_Auto_Reply_Utils.FlowOutputs();
        List<BD_Auto_Reply_Utils.FlowOutputs> outputs = new List<BD_Auto_Reply_Utils.FlowOutputs>();


        // Call the sendAutoReplies method
        outputs = BD_Auto_Reply_Utils.sendAutoReplies(requests);
        System.debug('Outputs: ' + outputs);

        output = outputs[0];
        System.assert(output.result == false, 'Output should have been false for subjectLine = ' + subjectLine);
    }

    @isTest
    static void testValidSubjectValue()
    {
        // Setup variables and test values
        String emailAddress = 'pleasedoreply@test.com';
        String subjectLine = 'This is a subject line';
        BD_Auto_Reply_Utils.FlowInputs request = new BD_Auto_Reply_Utils.FlowInputs();
        List<BD_Auto_Reply_Utils.FlowInputs> requests = new List<BD_Auto_Reply_Utils.FlowInputs>();
        request.emailAddress = emailAddress;
        request.subjectLine = subjectLine;
        requests.add(request);
        System.debug('Input: ' + requests);
        BD_Auto_Reply_Utils.FlowOutputs output = new BD_Auto_Reply_Utils.FlowOutputs();
        List<BD_Auto_Reply_Utils.FlowOutputs> outputs = new List<BD_Auto_Reply_Utils.FlowOutputs>();


        // Call the sendAutoReplies method
        outputs = BD_Auto_Reply_Utils.sendAutoReplies(requests);
        System.debug('Outputs: ' + outputs);

        output = outputs[0];
        System.assert(output.result == true, 'Output should have been true for subjectLine = ' + subjectLine);
    }
}
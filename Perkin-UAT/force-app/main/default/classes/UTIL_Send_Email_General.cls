/************************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 ATEAM-1995, INC0372679
* 2. Description - Utility class for sending email
* 3. Objects referenced
*    -EmailMessage
*	 -Attachment
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es):
* 6. Invocable: True
*
* 7. Test Class Name: UTIL_Send_Email_General_Test
*
* 8. Author Name(s): 
*    - AP/VG 31-07-2023
*
************************************************************************/ 
public class UTIL_Send_Email_General {
    @InvocableMethod
    public static void flowCalled(List<FlowInputs> requests){
        //validRequest depends on 3 parameters (varFromAddress, multiToAddress, multiCcAddress)
        boolean validRequest=True;
        if(requests != null && !requests.isEmpty()){
            If(requests[0].varFromAddress ==null){
                validRequest=false;
            }
            If(requests[0].multiToAddress ==null && requests[0].multiCcAddress ==null){
                validRequest=false;
            }
        }
        
        if(validRequest){ 
            //Creating SingleEmailMessage instance to send email
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage(); 
            //Checking if OrgWideAddress exists for service address if fromAddress is Blank in Custom Data
            //if OrgWideAddress is NOT found, then email will be sent from Service Admin's(Support setting default automation user) address
            List<OrgWideEmailAddress> orgwideaddreslist= [select Id,Address from OrgWideEmailAddress where Address=:requests[0].varFromAddress AND IsVerified = true limit 1];
            if(orgwideaddreslist != null && !orgwideaddreslist.isEmpty()){
                message.setOrgWideEmailAddressId(orgwideaddreslist[0].Id);
            }
            message.setToAddresses(requests[0].multiToAddress !=null ? requests[0].multiToAddress : New List<string>());
            message.setCcAddresses(requests[0].multiCcAddress !=null ? requests[0].multiCcAddress : New List<string>());
            //message.setBccAddresses(requests[0].multiBccAddress !=null ? requests[0].multiBccAddress : New List<string>());
            message.setHtmlBody(requests[0].varBody !=null ? requests[0].varBody : ' ');
            message.subject = requests[0].varSubject !=null ? requests[0].varSubject : ' ';
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: '
                             + results[0].errors[0].message);
            }
            
        }
    }
    Public class FlowInputs {
        @InvocableVariable public String varFromAddress;
        @InvocableVariable public List<String> multiToAddress;
        @InvocableVariable public List<String> multiCcAddress;
        //@InvocableVariable public List<String> multiBccAddress;
        @InvocableVariable public String varSubject;
        @InvocableVariable public String varBody;        
    }
}
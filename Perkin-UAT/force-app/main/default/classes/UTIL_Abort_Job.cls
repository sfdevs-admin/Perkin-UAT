/**************************************************************
* 1. Jira Ticket(s) that relates to this class
     
*
* 2. Description - This class aborts the apex job based on job Id on Mass Action log.
*
*
*
* 3. Objects referenced
*    -Mass Action log
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
     - None
*
* 6. Test Class Name: UTIL_Abort_Job_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Aakash/Vishwas 31-01-2023
*************************************************************/
public class UTIL_Abort_Job {
    Public class FlowInputs {             
        @InvocableVariable public String JobId;     
    }
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        String abort = '';
        String request = '';
        Integer count = 0;
        if(requests != null && !requests.isEmpty()){
            for ( AsyncApexJob aJob : [ Select id ,Status from AsyncApexJob where Id =:requests[0].JobId  ] ){
            	System.AbortJob(aJob.Id);
            }
        }
    }
}
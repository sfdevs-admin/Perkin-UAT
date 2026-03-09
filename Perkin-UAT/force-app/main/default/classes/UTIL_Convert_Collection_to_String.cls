/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Utillity class for conversion of collection to String
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: True
  *
  * 7. Test Class Name: UTIL_Convert_Collection_to_String_Test
  *
  * 8. Author Name(s): 
  *    - Aakash/Vishwas 22-09-2022
  *
*************************************************************/ 
public class UTIL_Convert_Collection_to_String {
	    @InvocableMethod
    public static list<FlowOutputs> flowcalled(List<FlowInputs> requests){
       list<FlowOutputs> fOutlist = new list<FlowOutputs>();
        if(requests != null && !requests.isEmpty()){
            for(FlowInputs finpt: requests){
                string  outputString ;
                FlowOutputs fout = new FlowOutputs();
                    if(finpt.liststring != null && !finpt.liststring.isEmpty()){
                        outputString= string.join( finpt.liststring,',');
                    }
                fout.varString= outputString;
                fOutlist.add(fout);    
            }
            
        }
     return fOutlist;
    }
     Public class FlowInputs { 
           @InvocableVariable public List<String> liststring; 
                
    }
    Public class FlowOutputs {         
       @InvocableVariable public String varString;         
    }
}
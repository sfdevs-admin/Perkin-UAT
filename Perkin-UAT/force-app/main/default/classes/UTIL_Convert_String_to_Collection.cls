/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Utillity class for conversion of String to Collection
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
  * 7. Test Class Name: UTIL_Convert_String_to_Collection_Test
  *
  * 8. Author Name(s): 
  *    - Aakash/Vishwas 22-09-2022
  *
*************************************************************/ 
public class UTIL_Convert_String_to_Collection {
    
    @InvocableMethod
    public static list<FlowOutputs> flowcalled(List<FlowInputs> requests){
       list<FlowOutputs> fOutlist = new list<FlowOutputs>();
        if(requests != null && !requests.isEmpty()){
            for(FlowInputs finpt: requests){
                list<string>  outputlist = new List<string>();
                list<string>  outputlist2 = new List<string>();
                FlowOutputs fout = new FlowOutputs();
                    if(finpt.varString != null && finpt.varString.contains(';') && finpt.varString.containsIgnoreCase(';')){
                        outputlist= finpt.varString.split(';');
                    }else if(finpt.varString != null && finpt.varString.contains(',')){
                        outputlist= finpt.varString.split(','); 
                    }
                for(string str:outputlist){
                   outputlist2.add(str.trim());
                }
                fout.liststring= outputlist2;
                fOutlist.add(fout); 
            }
            
        }
     return fOutlist;
    }
     Public class FlowInputs {         
        @InvocableVariable public String varString;         
    }
    Public class FlowOutputs {         
        @InvocableVariable public List<String> liststring;         
    }

}
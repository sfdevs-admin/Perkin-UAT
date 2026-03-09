/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Utillity class for conversion of collection to String
  * 3. Objects referenced:
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: True
  *
  * 7. Test Class Name: UTIL_Convert_Rec_Collection_to_Str_Test
  *
  * 8. Author Name(s): 
  *    - Vishwas 25-08-2023
  *
*************************************************************/ 
public class UTIL_Convert_Rec_Collection_to_Str {
   @InvocableMethod
    public static list<FlowOutputs> flowcalled(List<FlowInputs> requests){
       list<FlowOutputs> fOutlist = new list<FlowOutputs>();
        if(requests != null && !requests.isEmpty()){
                string  outputString ;
            list<string> collectionstring=new list<string>();
                FlowOutputs fout = new FlowOutputs();
                    if(requests[0].sobjectList != null && !requests[0].sobjectList.isEmpty()){
                        for(sObject Obj: requests[0].sobjectList){
                           collectionstring.add(string.valueof(Obj.get(requests[0].fieldApi) != null ? Obj.get(requests[0].fieldApi) : '')); 
                        }
                    }
                fout.varString= string.join( collectionstring,',');
                fOutlist.add(fout);    
            
            
        }
     return fOutlist;
    }
     Public class FlowInputs { 
           @InvocableVariable public List<Sobject> sobjectList; 
           @InvocableVariable public string fieldApi; 
         
                
    }
    Public class FlowOutputs {         
       @InvocableVariable public String varString;         
    }
}
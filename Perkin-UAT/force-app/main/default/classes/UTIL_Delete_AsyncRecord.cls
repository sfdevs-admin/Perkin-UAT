/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Delete_AsyncRecord Apex class
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None 
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: true
  *    futureMethod: true
  *
  * 7. Test Class Name: UTIL_Delete_AsyncRecord_Test
  *
  * 8. Author Name(s): 
  *    -Vishwas 22-02-2023
  *
*************************************************************/
public class UTIL_Delete_AsyncRecord {
	Public class FlowInputs { 
        
        @InvocableVariable public String RecId;     
    }
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        if(requests != null && !requests.isEmpty()){
           List<string> Ids= new list<string>(); 
            for(FlowInputs fin: requests){
                Ids.add(fin.RecId);
            }
            if(Ids != null && !Ids.isEmpty()){
               deleteSobjectrecord(Ids);  
            }
           
        }
        
    }
        @future
    public static void deleteSobjectrecord( List <String> RecId ) {
        try{
            Database.DeleteResult[] dlresult=database.delete(RecId); 
        }catch(exception ex){
            system.debug('ex'+ex.getMessage());
        }
         
     }
}
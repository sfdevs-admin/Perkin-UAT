/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Convert_Collection_to_String Apex class
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None 
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: False
  *
  *
  * 7. Author Name(s): 
  *    - Aakash/Vishwas 25-08-2023 
  *
*************************************************************/ 
@isTest
public class UTIL_Convert_Rec_Collection_to_Str_Test {
        
    @isTest static void testSObjectCollection() {
      //UTIL_Convert_Record_Collection_to_String.FlowInputs varInputClass= new UTIL_Convert_Record_Collection_to_String.FlowInputs();
        UTIL_Convert_Rec_Collection_to_Str.FlowInputs varInputClass= new UTIL_Convert_Rec_Collection_to_Str.FlowInputs();
        List<Sobject> objlist= new List<Sobject>();
        contact objcontact= new  contact(LastName='test acc');
            insert objcontact;
        objList.add(objcontact);
        varInputClass.sobjectList=objList;
        varInputClass.fieldApi='LastName';   
      //UTIL_Convert_Record_Collection_to_String.flowcalled(new list<UTIL_Convert_Record_Collection_to_String.FlowInputs>{varInputClass});
     UTIL_Convert_Rec_Collection_to_Str.flowcalled(new list<UTIL_Convert_Rec_Collection_to_Str.FlowInputs>{varInputClass});
   }
}
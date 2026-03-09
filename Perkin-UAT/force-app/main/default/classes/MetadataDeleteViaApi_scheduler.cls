/**************************************************************
  * 1. Jira Ticket(s) that relates to Apex class "MetadataDeleteViaApi_scheduler"
  *    - ATEAM-264 APEX to modify Metadata via API to for cleanup of unused items
  *
  * 2. Description - This scheduler class will be used to schedule the MetadataDeleteViaApi apex class with parameters.
  *                -// Three parameter constructor will use to pass Folder, list of folder id and folder type
  *                -// Two parameter constructor will use to pass ObjectName and set of object id (Dashoard,set of dashboard ids)
  *               -// if typestring is there then it will folder delete else assuming that, this call will be for report /dashboard/emailtemlpate/listview deletion
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    MetadataDeleteViaApi batch class which will be called from this scheduler class
  * 5. Dependant Class(es):
  *    - MetadataDeleteViaApi
  *    
  *
  * 6. Test Class Name: MetaDataDeleteViaApi_BatchTest
  *
  * 7. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(4/21/2021)
  *
*************************************************************/ 
global class MetadataDeleteViaApi_scheduler implements Schedulable {
    public final set<Id> ids;
    public final string sobjname;
    public final String typestring;
    // Three parameter constructor will use to pass Folder, list of folder id and folder type
   global MetadataDeleteViaApi_scheduler(string sobjnamestr,set<Id> lststring, string typstr){
       ids =lststring;
       sobjname=sobjnamestr;
       typestring=typstr;
    } 
    // Two parameter constructor will use to pass ObjectName and set of object id (Dashoard,set of dashboard ids)
    global MetadataDeleteViaApi_scheduler(string sobjnamestr,set<Id> lststring){
       ids =lststring;
       sobjname=sobjnamestr;
    }
    global void execute(SchedulableContext sc) {
        // if typestring is there then it will folder delete else assuming that, this call will be for report /dashboard/emailtemlpate/listview deletion
        if(typestring != null)
            Database.executeBatch(new MetadataDeleteViaApi(sobjname,ids,typestring), 10);
        else
            Database.executeBatch(new MetadataDeleteViaApi(sobjname,ids), 10);            
    }
    
}
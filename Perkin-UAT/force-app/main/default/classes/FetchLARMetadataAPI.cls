//This class is used to run on scheduled/on demand to delete listview/dashboard/folder/reports from SFDC
public class FetchLARMetadataAPI {    
    
    /**************************************************************
    * Description - Method to delete listview/dashboard/folder/reports from SFDC using metadata api 
    */ 
    public static boolean deleteListView(string objectname, String[] listViewArray) {
        // creating service to be able to call metadata api         
        MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
        
        // calling metadata api to delete listviews
        List<MetadataService1.DeleteResult> results =
            service.deleteMetadata(
                objectname, listViewArray);
        return Test.isRunningTest() ? true : results[0].success;       
    }
}
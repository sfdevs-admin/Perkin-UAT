/***********************************************************
Created By          : Lister technologies
Purpose             : To ensure that employees with record type - Non Officer should not be deletable
Created Date        : 19th November 2013
Last Modified Date  : 19th November 2013
Test Class Name     : 
Version             : 1.0 -- 19th November 2013 - First Version
************************************************************/
public class cls_employeeNonOfficerDeletable {
    
    //variable intialisation 
    public Employee__c runnning_employee;
    map<Id, String> map_EmployeeRecordType = new map<Id,String>();
    //public Boolean bln_isError{get; set;} 
    public String VF_page_old_URL{get; set;}
    public String VF_page_new_URL{get; set;}
    public Id result;
    List<User> userProfile = new List<User>();
    // The extension constructor initializes the public member
    // variable runnning_employee by using the getRecord method from the standard
    // controller.
    public cls_employeeNonOfficerDeletable(ApexPages.StandardController stdController) {
        
        runnning_employee = (Employee__c)stdController.getRecord();
        bln_isError      = false;
        
        PageReference pageRef   = ApexPages.currentPage();
        VF_page_old_URL  = pageRef.getParameters().get('retURL');
        VF_page_new_URL  = '/setup/own/deleteredirect.jsp?delID=' + runnning_employee.Id + '&retURL=%2Fa1p%2Fo&nooverride=1';
        
        //Querying the Account record type details
        for(RecordType iterating_RecordType : [SELECT ID, DeveloperName FROM RecordType WHERE sObjectType='Employee__c' AND DeveloperName = 'Officer']){
            map_EmployeeRecordType.put(iterating_RecordType.Id, iterating_RecordType.DeveloperName);
        }
    }
    

    public Boolean bln_isError{
        get{
            if(map_EmployeeRecordType.containsKey(runnning_employee.RecordTypeId) && userProfile.get(0).profile.Name != 'System Administrator')
                bln_isError = true;
                
            return bln_isError;
         }
         set{}
    }
}
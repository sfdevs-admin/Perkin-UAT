/***********************************************************
Created By          : Lister technologies
Purpose             : To ensure that Account with record type - Perkin Entities should not be editable
Created Date        : 18th November 2013
Last Modified Date  : 18th November 2013
Test Class Name     : 
Version             : 1.0 -- 18th November 2013 - First Version
************************************************************/
public class cls_entityNotBeDeletable {
    
    //variable intialisation 
    public Account runnning_account;
    map<Id, String> map_AccountRecordType = new map<Id,String>();
    //public Boolean bln_isError{get; set;} 
    public String VF_page_old_URL{get; set;}
    public String VF_page_new_URL{get; set;}
    List<User> userProfile = new List<User>();
    public Id result;
     
    // The extension constructor initializes the public member
    // variable runnning_account by using the getRecord method from the standard
    // controller.
    public cls_entityNotBeDeletable(ApexPages.StandardController stdController) {
        
        runnning_account = (Account)stdController.getRecord();
        bln_isError      = false;
        result = UserInfo.getUserId();
        userProfile = [Select profile.Name from User where Id =: result];
        PageReference pageRef   = ApexPages.currentPage();
        VF_page_old_URL  = pageRef.getParameters().get('retURL');
        VF_page_new_URL  = '/setup/own/deleteredirect.jsp?delID=' + runnning_account.Id + '&retURL=%2F001%2Fo&nooverride=1';
        
        //Querying the Account record type details
        for(RecordType iterating_RecordType : [SELECT ID, DeveloperName FROM RecordType WHERE sObjectType='Account' AND DeveloperName = 'PerkinElmer_Entities']){
            map_AccountRecordType.put(iterating_RecordType.Id, iterating_RecordType.DeveloperName);
        }
    }
    

    public Boolean bln_isError{
        get{
            if(map_AccountRecordType.containsKey(runnning_account.RecordTypeId) && userProfile.get(0).profile.Name != 'System Administrator')
                bln_isError = true;
                
            return bln_isError;
         }
         set{}
    }
}
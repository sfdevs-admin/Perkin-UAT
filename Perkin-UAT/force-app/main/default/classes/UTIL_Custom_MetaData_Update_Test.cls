/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*     - OM-316
* 2. Description - This Test Class for Apex Class:UTIL_Custom_MetaData_Update 
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
* 5. Dependant Class(es):UTIL_Custom_MetaData_Update
* 6. Invocable: True
*
* 7. Class Name: UTIL_Custom_MetaData_Update_Test
*
* 8. Author Name(s): 
* -    Vishwas 22-01-2024
*************************************************************/
@isTest
public class UTIL_Custom_MetaData_Update_Test {
    
    @testSetup static void methodName() {
        
    }
    @isTest static void testmethod1() {
        
        List<UTIL_Custom_MetaData_Update.ActionRequest> requestList= new List<UTIL_Custom_MetaData_Update.ActionRequest>();
        UTIL_Custom_MetaData_Update.ActionRequest request= new UTIL_Custom_MetaData_Update.ActionRequest();
        List<C_META_PKI_Countries__mdt> MetadataList = new List<C_META_PKI_Countries__mdt>();
        
        MetadataList.add(new C_META_PKI_Countries__mdt(MasterLabel='gmail_com', DeveloperName = 'gmail_com', CountryISOAlpha2__c='US'));
        MetadataList.add(new C_META_PKI_Countries__mdt(MasterLabel='Demo 2',Label='Demo 2', CountryISOAlpha2__c='IN'));
        // MetadataList.add(new C_META_Domains__mdt(MasterLabel='Demo 3',Domain__c='Hotmail2.com', Status__c='Public' ));
        
        request.data=MetadataList;
        requestList.add(request);
        UTIL_Custom_MetaData_Update.invokeService(requestList);
        UTIL_Custom_MetaData_Update callback= new UTIL_Custom_MetaData_Update();
        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();
        
        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);
    }
    /* @description DeployCallbackContext subclass for testing that returns myJobId */
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}
/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*     - OM-316
* 2. Description - This Class can be invoked from Flow and Create/Update Custom Metadata by passing Record instance of custom metadata
*  	a. label of custommetadata required for insertion of custom MetaData
*     b. DeveloperName is required for Updation of Custom Metadata
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
* 5. Dependant Class(es):
* 6. Invocable: True
*
* 7. Test Class Name: UTIL_Custom_MetaData_Update_Test
*
* 8. Author Name(s): 
*      Base: Unknown
* -    Vishwas 22-01-2024
*************************************************************/
global class UTIL_Custom_MetaData_Update implements Metadata.DeployCallback{
    
    /*An invocable variable used as input or output variables in the process builder*/
    global class ActionRequest {
        @InvocableVariable(required = true)
        public List<sObject> data;
    }
    //This invocable method is used for processing the business by taking the input from process builder/flow
    @InvocableMethod(label = 'Create/Update Custom Metadata')
    global static void invokeService(List <ActionRequest> requests) {
        for (ActionRequest requestObj: requests) {
            //Accessing the values from process builder/flow when record is inserted
            for(sObject obj : requestObj.data){
                System.debug('requestObj.sObject@@:' + obj);
                //System.debug('requestObj.ObjectType@@:' + obj.getSObjectType());
                // Getting all the Populated fields in a Map
                Map<String, Object> fieldsToValue = obj.getPopulatedFieldsAsMap();
                Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
                String MetadataDevName; // To Store Custom Metadata Record API/Developer name
                String MetadataLabel; // To Store Custom Metadata Label name
                // Looping on all the populated fields
                for (String fieldName : fieldsToValue.keySet()){
                    // System.debug('field name is ' + fieldName + ', value is ' + fieldsToValue.get(fieldName));
                    // We don't want to add system fields to the Map for update, so here is some simple logic
                    if(fieldName == 'Label'){
                        MetadataLabel = (String)fieldsToValue.get(fieldName);
                    } else if(fieldName == 'DeveloperName'){
                        MetadataDevName = (String)fieldsToValue.get(fieldName);
                    } else if(fieldName != 'Id' && fieldName != 'Language' && fieldName != 'MasterLabel' && fieldName != 'NamespacePrefix' && fieldName != 'QualifiedApiName' && fieldName != 'SystemModstamp') {
                        // Populating Map for Processing later
                        metadataFieldValueMap.put(fieldName, fieldsToValue.get(fieldName));
                         system.debug('metadataFieldValueMap'+metadataFieldValueMap);
                    }
                }
                
                //System.debug('Label is ' + MetadataLabel + '& DeveloperName is ' + MetadataDevName);
                // Making sure to have either Label or Developer Name for the CMD record to process
                if(String.isBlank(MetadataDevName) && String.isBlank(MetadataLabel)){
                    throw createCustomException('Make sure to add "Label" attribute in assignemnt for Create and "DeveloperName" for update.');
                } else { 
                    //if MetadataDevName available, which means the record exists already - Processing UPDATE
                    if(!String.isBlank(MetadataDevName)){
                        system.debug('Update Call');
                        UTIL_Custom_MetaData_Update.updateCustomMetadata(String.valueof(obj.getSObjectType()),MetadataDevName, MetadataLabel,metadataFieldValueMap);
                    } else { // Creating a new Custom Metadata record
                        //if ID not available - CREATE
                         system.debug('Craete Call');
                        UTIL_Custom_MetaData_Update.createCustomMetadata(String.valueof(obj.getSObjectType()), MetadataLabel, metadataFieldValueMap);
                    }
                }
                // END
            }
        }
    }
    
    /* Custom Metadata Deploy Methods */
    /* ============================================================*/
    //Inteface method 
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result != null && result.status == Metadata.DeployStatus.Succeeded) {
            //Success
             System.debug('Success Result-' + result);
        } else {
            //Failed
            IF(!Test.isRunningTest())
                throw createCustomException(String.valueof(result));
            else
                createCustomException(String.valueof(result));    
        }
    }
    
    //Create Custom Metadata record
    /*Passing 
* Custom Metadata Object API
* Label
* Map of Field API with value
*/
    public static void createCustomMetadata(String metdataName, String label, Map<String, Object> metadataFieldValueMap){
        String recordDevName = label.replaceAll(' ', '_');
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        // Updating value in Custom metaData's Fields
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            if(key=='Requested_By__c'){
                cMetadataValue.Value=userinfo.getUserName(); 
            }else{
                cMetadataValue.Value = metadataFieldValueMap.get(key);  
            }
            
            cMetadata.values.add(cMetadataValue);
        }
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        UTIL_Custom_MetaData_Update callback = new UTIL_Custom_MetaData_Update();
        IF(!Test.isRunningTest())
            Id jobId =Metadata.Operations.enqueueDeployment(mdContainer, callback);
        
    }
    
    //Update Custom Metadata record
    /*Passing 
* Custom Metadata Object API
* DeveloperName ( As record identifier)
* Label
* Map of Field API with value
*/
    public static void updateCustomMetadata(String metdataName, String recordDevName, String label, Map<String, Object> metadataFieldValueMap){
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            if(key=='Requested_By__c'){
                cMetadataValue.Value=userinfo.getUserName(); 
            }else{
                cMetadataValue.Value = metadataFieldValueMap.get(key);  
            }
            cMetadata.values.add(cMetadataValue);
        }
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        UTIL_Custom_MetaData_Update callback = new UTIL_Custom_MetaData_Update();
        IF(!Test.isRunningTest())
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
       
       
    }
    
    /* Flow Exception Handling */
    /* ============================================================*/
    public class CustomException extends Exception {}
    
    static CustomException createCustomException(String message) {
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }
}
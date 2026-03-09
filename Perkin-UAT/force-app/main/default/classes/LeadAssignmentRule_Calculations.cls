/*********************************************************************************
* Description : Service class to Calculate assignment rule record count for a user
* Created Date : 16th Feb 2020
* https://github.com/financialforcedev/apex-mdapi
*/
public class LeadAssignmentRule_Calculations {
     
    /*********************************************************************************
    * Description - used to pull the Lead Assignmnet Rules using metadata api where assignedTo is a User
    * and put the count in Lead_Assignment_Rules__c field on user record.
    */   
    public static void getAssignmentRule() {
        // map to store username with Lead asssignment rule count pulled using metadata api
        Map<String,Integer> usernameToLARCount  = new Map<String,Integer>(); 
        
        // map to store username with Lead asssignment rule count pulled from SFDC database
        Map<String,User> existingLeadAssignmentCount = new Map<String,User>();  
        
        // set to store all usernames
        Set<String> allUserNames = new Set<String>();
        
        // list to store updated user , whom will later be updated in SFDC database
        List<User> userList = new List<User>();
        
        // creating service to be able to call metadata api
        MetadataService1.MetadataPort service   = createService();
        
        //Storing the result read from metadata api
        MetadataService1.IReadResult readResult = new MetadataService1.ReadAssignmentRulesResult();        
        readResult = service.readMetadata('AssignmentRules', new String[]{'Lead'}); 
        MetadataService1.Metadata[] mdInfo      = readResult.getRecords(); 
        MetadataService1.AssignmentRules TempAssignmentRules = (MetadataService1.AssignmentRules) mdInfo[0];
        
        //getting the hostName for current sandbox        
        String hostName = URL.getSalesforceBaseUrl().getHost().substringBetween('--','.');
        
        //populating usernameToLARCount map based on data pulled from metadata api    
        if(TempAssignmentRules.AssignmentRule[0].active) {
            for( MetadataService1.RuleEntry entry : TempAssignmentRules.AssignmentRule[0].ruleEntry) {     
                if(entry.assignedToType <> null && entry.assignedToType <> 'Queue') {
                    String newString     = String.isNotBlank(hostName) ?  entry.assignedTo + '.' + hostName : entry.assignedTo;                                     
                    Integer relatedCount = usernameToLARCount.containsKey(newString) ? 
                                           usernameToLARCount.get(newString) + 1 :
                   					       1;
                    usernameToLARCount.put(newString,relatedCount);
                }
            }          
        }  
        
        System.debug('usernameToLARCount  :---> '+usernameToLARCount.size());
        
        //populating existingLeadAssignmentCount map based on data pulled from database    
        for(User u : [SELECT Id, Username, Lead_Assignment_Rules__c FROM USER 
                      WHERE Lead_Assignment_Rules__c >= 1]) {
            existingLeadAssignmentCount.put(u.userName, u);
        }
         
        System.debug('existingLeadAssignmentCount  :---> '+existingLeadAssignmentCount.size()); 

        //adding usernames to set allUserNames
        allUserNames.addAll(usernameToLARCount.keyset());
        allUserNames.addAll(existingLeadAssignmentCount.keySet());
        
        // query to pull data for all usernames fetched so far        
        Map<Id,User> usernameToUserIdMap = new Map<Id,User>([SELECT Id, Username, Lead_Assignment_Rules__c FROM USER 
                                                             WHERE Username IN: allUserNames]);
        System.debug('usernameToUserIdMap  :---> '+usernameToUserIdMap.size());         
        
        //iterating records and updating the Lead assignment count for user and storing it in a final list- userList
        for(Id userId : usernameToUserIdMap.keySet()) {
            User tempUser = usernameToUserIdMap.get(userId);
            if(usernameToLARCount.containsKey(tempUser.Username) && 
               (tempUser.Lead_Assignment_Rules__c <> usernameToLARCount.get(tempUser.Username))) {
                   User u = new User (
                       Id = tempUser.Id,
                       Lead_Assignment_Rules__c = usernameToLARCount.get(tempUser.Username)
                   );     
                   userList.add(u);
               }
            if(!usernameToLARCount.containsKey(tempUser.Username) && existingLeadAssignmentCount.containsKey(tempUser.Username)) {
                User u = new User ( 
                    Id = tempUser.Id,
                    Lead_Assignment_Rules__c = 0
                );     
                userList.add(u);
            }            
        }
        
        system.debug('*** userList size  -- '+userList.size());  
        
        //updating final user list with updated count
        if(!userList.isEmpty() && !Test.isRunningTest()) {
            Database.SaveResult[] drList =  Database.update(userList, false); 
            for(Database.SaveResult dr : drList) {
                if (dr.isSuccess()) {
                    
                }
                else {
                    // Operation failed, so get all errors 
                    System.debug('** dr.getErrors() '+dr.getErrors());                      
                }
            }
        }        
    }
    
    /**************************************************************
    * Description - Method to create a Service Request 
    * Parameter -  NA 
    * Return - MetadataService1.MetadataPort instance
    */     
    public static MetadataService1.MetadataPort createService() {     
        /*** Reason for an extra callout - 
        * https://help.salesforce.com/articleView?id=000313355&type=1&mode=1 
        ***/
        String restUrl   = 'callout:Internal_SFDC/services/data/v39.0/limits';
        Http h           = new Http();
        HttpRequest req  = new HttpRequest();
        req.setEndpoint(restUrl);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        MetadataService1.MetadataPort service = new MetadataService1.MetadataPort();
        service.endpoint_x                    = 'callout:Internal_SFDC/services/Soap/m/38.0';        
        service.SessionHeader                 = new MetadataService1.SessionHeader_element();
        service.SessionHeader.sessionId       = '{!$Credential.OAuthToken}';
        return service;
    }   
    
}
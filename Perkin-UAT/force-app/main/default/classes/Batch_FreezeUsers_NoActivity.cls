/*
 Batch class to Freeze users, who are not active for more than 30 Days / days specified in custom setting.
*/
public class Batch_FreezeUsers_NoActivity implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        CSET_9900__c customsetting= CSET_9900__c.getOrgDefaults();
        Integer daysToFreeze = (Integer)customsetting.Days_to_Freeze_Inactive_Users__c;
        if(daysToFreeze== null){
            daysToFreeze=30;
        }
        string query = 'SELECT Id  FROM User WHERE IsActive = TRUE AND Profile.UserLicense.Name=\'Salesforce\' AND Do_Not_Deactivate__c = FALSE AND Id NOT IN (SELECT UserId FROM LoginHistory WHERE LoginTime = LAST_N_DAYS:'+daysToFreeze+')';
        if(Test.isRunningTest()){
            query += ' Limit 10';
        }
        return  Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<User> userList){
        
        List<UserLogin> userLoginList = [Select IsFrozen From UserLogin Where UserId IN :userList and IsFrozen=false];
        for(UserLogin userLog : userLoginList){
            userLog.IsFrozen=true;
        }
       	Database.update(userLoginList,false);
        
    }
    public void finish(Database.BatchableContext BC) {
    }

}
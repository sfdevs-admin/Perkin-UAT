global class UserJobFamily_Batch implements Database.Batchable<sObject>, Schedulable 
{	
	// schedulable
    global void execute(SchedulableContext sc) 
    {
        UserJobFamily_Batch batch = new UserJobFamily_Batch();
        Database.executeBatch(batch,200);
    }

	global UserJobFamily_Batch() {  }
	
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{	
		if (Test.isRunningTest())
			return Database.getQueryLocator([SELECT Id, PKI_GBL_Job_Family__c FROM User WHERE alias = 'testies' AND PKI_GBL_Job_Family__c != null LIMIT 10]);
		return Database.getQueryLocator([SELECT Id, PKI_GBL_Job_Family__c FROM User WHERE PKI_GBL_Job_Family__c != null]);
	}

   	global void execute(Database.BatchableContext BC, List<User> users) 
   	{
   		Map<String,List<Id>> updateUsers = new Map<String,List<Id>>();
   		for(User u:users)
   		{
   			String groupName = 'Job Family: '+u.PKI_GBL_Job_Family__c;
			if(!updateUsers.containsKey(groupName))
			{
				updateUsers.put(groupName, new List<Id> { u.Id });
			}
			else
			{
				updateUsers.get(groupName).add(u.Id);
			}
		}

		UserJobFamily.jobFamily_deleteMembers(updateUsers);

		UserJobFamily.jobFamily_createMembers(updateUsers);
	}
	
	global void finish(Database.BatchableContext BC) {  }
}
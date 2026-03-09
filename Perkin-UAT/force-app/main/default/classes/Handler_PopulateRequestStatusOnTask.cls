/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Title           : Handler_PopulateRequestStatusOnTask
Author          : Lister Technologies
Description     : This is a handler class which populates the status of the request field on the correct task
                    from opportunity.
Test Class      : Test_Handler_PopulateRequestStatusOnTask
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---------------------------------------------------------------------------------------------------------------
/***********************************************************************************************************/
/*|S.N0|-----------Description---------|--Modified On--|--Modified By--|--Tag--|-----------Test Class-------|
/***********************************************************************************************************/
/*|    |                               |               |               |       |                            |
/*************************************************************************************************************/
public class Handler_PopulateRequestStatusOnTask{
    private list<Opportunity> newOpportunityList;
    private map<id,Opportunity> oldMap;
    private map<id,Opportunity> newMap;
    public list<id> listOfOppIds = new list<id>();
   
    public Handler_PopulateRequestStatusOnTask(List<Opportunity> newOpportunityList,map<id,Opportunity> oldMap,map<id,Opportunity> newMap)
    {
        this.newOpportunityList= newOpportunityList;
        this.oldMap= oldMap;
        this.newMap = newMap;
    }
    public void updateLastModified(List<Opportunity> Opps){
      for(Opportunity o: Opps){
        if(Userinfo.getUserid() == o.OwnerId)
           o.Last_Modified_by_Owner__c = DateTime.Now();
      }
    }
    public void updateTask(){
        for(Opportunity tempOpp : newOpportunityList){
            if(tempOpp.Status_of_the_Request__c != null && tempOpp.Status_of_the_Request__c != oldMap.get(tempOpp.id).Status_of_the_Request__c){
                listOfOppIds.add(tempOpp.id);
            }
        }
        if(listOfOppIds != null && listOfOppIds.size() > 0){
            map<id,list<task>> mapOfOppToListOfTasks = new map<id,list<task>>();
            list<task> listOfTasks = new list<task>();
            list<task> listOfTasksToUpdate = new list<task>();
            for(task tempTask : [Select id,Status_of_the_Request__c,whatId,createdDate
                                        from task
                                        where whatId in:listOfOppIds and Event_Category__c = 'Presales'
                                        ORDER BY createdDate ASC]){
                if(mapOfOppToListOfTasks != null && mapOfOppToListOfTasks.size() > 0 && mapOfOppToListOfTasks.containsKey(tempTask.whatId)){
                    listOfTasks = mapOfOppToListOfTasks.get(tempTask.whatId);
                    listOfTasks.add(tempTask);
                    mapOfOppToListOfTasks.put(tempTask.whatId,listOfTasks);
                }
                else{
                    listOfTasks = new list<task>();
                    listOfTasks.add(tempTask);
                    mapOfOppToListOfTasks.put(tempTask.whatId,listOfTasks);
                }
            }
            if(mapOfOppToListOfTasks != null && mapOfOppToListOfTasks.size() > 0){
                for(id oppId : mapOfOppToListOfTasks.keyset()){
                    listOfTasks = mapOfOppToListOfTasks.get(oppId);
                    system.debug('**listOfTasks '+listOfTasks);
                    for(task tempTask : listOfTasks){
                        if(tempTask.Status_of_the_Request__c != 'Rejected by Sales Leader' 
                            && tempTask.Status_of_the_Request__c != 'Specialist Assigned' 
                            && tempTask.Status_of_the_Request__c != 'Rejected by Specialist Leader' ){
                            tempTask.Status_of_the_Request__c = newMap.get(oppId).Status_of_the_Request__c;
                            listOfTasksToUpdate.add(tempTask);
                            break;
                        }
                    }
                }
                system.debug('**mapOfOppToListOfTasks '+mapOfOppToListOfTasks);
            }
            system.debug('**listOfTasksToUpdate '+listOfTasksToUpdate);
            if(listOfTasksToUpdate != null && listOfTasksToUpdate.size() > 0){
                try{
                    update listOfTasksToUpdate;
                }catch(exception e){
                    system.debug('***Error while updating the task '+e.getmessage());
                }
            }
        }
    }
}
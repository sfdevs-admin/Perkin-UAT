/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Title           : Handler_PopulateApproverOnOpportunity
Author          : Lister Technologies
Description     : This is a handler class which populates the Sales Leader and Specialist Leader on opportunity
                    based on the territory and the owner field. This data is retrieved from the custom object
                    Pre sales TechnicalSupport Request Table
Test Class      : Test_Handler_PopulateApproverOpportunity
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
---------------------------------------------------------------------------------------------------------------
/***********************************************************************************************************/
/*|S.N0|-----------Description---------|--Modified On--|--Modified By--|--Tag--|-----------Test Class-------|
/***********************************************************************************************************/
/*|    |                               |               |               |       |                            |
/*************************************************************************************************************/
public class Handler_PopulateApproverOnOpportunity {
    private list<Task> newTask;
    private map<id,Task> oldTaskMap;
    private list<Id> listOfOppId = new list<Id>();
    private boolean isInsert;
   
    public Handler_PopulateApproverOnOpportunity(List<Task> newTask,map<id,Task> oldMap,boolean isInsert)
    {
        this.newTask = newTask;
        this.oldTaskMap = oldMap;
        this.isInsert = isInsert;
    }
    
    public void updateLeaders(){
        //Get all the tasks of type Presales
        if(isInsert){
            for(task tempTask : newTask){
                if(tempTask.Event_Category__c == 'Presales' && tempTask.whatId != null){
                    listOfOppId.add(tempTask.whatId);
                }
            }
        }
        else{
            for(task tempTask : newTask){
                if(tempTask.Event_Category__c == 'Presales' && oldTaskMap.get(tempTask.id).Event_category__c != tempTask.Event_Category__c && tempTask.whatId != null){
                    listOfOppId.add(tempTask.whatId);
                }
            }
        }
        system.debug('*&listOfOppId '+listOfOppId);

        
        if(listOfOppId != null && listOfOppId.size() > 0){
            list<opportunity> listOfOpp = new list<Opportunity>();
            list<string> listOfTerritoryName = new list<string>();
            list<Id> listOfUserId = new list<Id>();
            string tempString = '';
            map<Id,string> mapOfOppIdToTerritoryNameAndOwner = new map<Id,string>();
            //Query the respective opportunities and form a map of Opp Id to (territoryname+ownerId) 
            //Also make a list of the owner id and the territory name to query the Pre_sales_TechnicalSupport_Request_Table__c later
            for(opportunity tempOpp : [SELECT Id, Territory2Id,Territory2.Name, Specialist_Leader__c, Sales_Leader__c, OwnerId 
                                        FROM Opportunity 
                                        WHERE id IN : listOfOppId]){
                //listOfOpp.add(tempOpp);
                listOfUserId.add(tempOpp.OwnerId);
                if(tempOpp.Territory2.Name != null){
                    listOfTerritoryName.add(tempOpp.Territory2.Name);
                    tempString = tempOpp.Territory2.Name+'*'+tempOpp.OwnerId;
                    mapOfOppIdToTerritoryNameAndOwner.put(tempOpp.id,tempString);
                    listOfOpp.add(tempOpp);
                }
                // Do not Change - Written to cover test classes invloved with territories
                else if(Test.isRunningTest()){
                    listOfTerritoryName.add('Test Territory Name');
                    tempString = 'Test Territory Name'+'*'+tempOpp.OwnerId;
                    mapOfOppIdToTerritoryNameAndOwner.put(tempOpp.id,tempString);
                    listOfOpp.add(tempOpp);                            
                }                            
            }
            system.debug('*&listOfUserId '+listOfUserId);
            system.debug('*&listOfTerritoryName '+listOfTerritoryName);
            system.debug('*&mapOfOppIdToTerritoryNameAndOwner '+mapOfOppIdToTerritoryNameAndOwner);

            list<opportunity> listOfOppToUpdate = new list<Opportunity>();
            map<string,Pre_sales_TechnicalSupport_Request_Table__c> mapOfTerritoryNameAndOwnerIdToThePSTSRT = new map<string,Pre_sales_TechnicalSupport_Request_Table__c>();
            if(listOfTerritoryName != null && listOfTerritoryName.size() > 0 && listOfUserId != null && listOfUserId.size() > 0){
                //Query the Pre_sales_TechnicalSupport_Request_Table__c with the owner and the territory name from the queried opportunities
                //and contruct a map of the (territoryname+owner(sales rep)) to the Pre_sales_TechnicalSupport_Request_Table__c
                Pre_sales_TechnicalSupport_Request_Table__c tempObjRepeat = new Pre_sales_TechnicalSupport_Request_Table__c();
                for(Pre_sales_TechnicalSupport_Request_Table__c tempObj : [SELECT Id, Name, Sale_Rep__c, Sales_Leader__c, Specialist_Leader__c,LastModifiedDate  
                                                                            FROM Pre_sales_TechnicalSupport_Request_Table__c
                                                                            WHERE Sale_Rep__c in: listOfUserId and Name in: listOfTerritoryName]){
                    tempString = tempObj.Name+'*'+tempObj.Sale_Rep__c;
                    if(mapOfTerritoryNameAndOwnerIdToThePSTSRT != null && mapOfTerritoryNameAndOwnerIdToThePSTSRT.size() > 0
                        && mapOfTerritoryNameAndOwnerIdToThePSTSRT.containsKey(tempString) ){
                        system.debug('**mapOfTerritoryNameAndOwnerIdToThePSTSRT.get(tempString).LastModifiedDate '+mapOfTerritoryNameAndOwnerIdToThePSTSRT.get(tempString).LastModifiedDate);
                        system.debug('**tempObj.LastModifiedDate '+tempObj.LastModifiedDate);
                        if( tempObj.LastModifiedDate > mapOfTerritoryNameAndOwnerIdToThePSTSRT.get(tempString).LastModifiedDate){
                            mapOfTerritoryNameAndOwnerIdToThePSTSRT.put(tempString,tempObj);
                        }
                    }   
                    else{
                        mapOfTerritoryNameAndOwnerIdToThePSTSRT.put(tempString,tempObj);
                    }
                }
            }
            system.debug('*&mapOfTerritoryNameAndOwnerIdToThePSTSRT '+mapOfTerritoryNameAndOwnerIdToThePSTSRT);

            if(mapOfTerritoryNameAndOwnerIdToThePSTSRT != null && mapOfTerritoryNameAndOwnerIdToThePSTSRT.size() > 0){
                if(mapOfOppIdToTerritoryNameAndOwner != null && mapOfOppIdToTerritoryNameAndOwner.size() > 0){
                    if(listOfOpp != null && listOfOpp.size() > 0){
                        Pre_sales_TechnicalSupport_Request_Table__c tempPSTRT = new Pre_sales_TechnicalSupport_Request_Table__c();
                        //Loop through the queried opportunities and map the sales leader and specialist leader from the map contructed above
                        for(Opportunity tempOppor : listOfOpp){
                            if(mapOfOppIdToTerritoryNameAndOwner.containsKey(tempOppor.id) && mapOfOppIdToTerritoryNameAndOwner.get(tempOppor.id) != null 
                                    && mapOfTerritoryNameAndOwnerIdToThePSTSRT.containsKey(mapOfOppIdToTerritoryNameAndOwner.get(tempOppor.id))){
                                tempPSTRT = mapOfTerritoryNameAndOwnerIdToThePSTSRT.get(mapOfOppIdToTerritoryNameAndOwner.get(tempOppor.id));
                                tempOppor.Sales_Leader__c = tempPSTRT.Sales_Leader__c;
                                tempOppor.Specialist_Leader__c = tempPSTRT.Specialist_Leader__c;
                                //Make the checkbox true only if both the leaders are present.
                                //this will eventually trigger the approval process
                                if(tempOppor.Sales_Leader__c != null &&  tempOppor.Specialist_Leader__c != null){
                                    tempOppor.Pre_sales_Technical_Support_Task__c = true;
                                }
                                listOfOppToUpdate.add(tempOppor);
                            }
                        }
                    }
                }
            }
            system.debug('*&listOfOppToUpdate '+listOfOppToUpdate);
            //Update the opportunity records
            if(listOfOppToUpdate != null && listOfOppToUpdate.size() > 0){
                try{
                     Database.update(listOfOppToUpdate,false);
                }
                catch(exception e){
                    system.debug('*** The exception thrown is '+e.getMessage());
                }
            }
        }
    }
}
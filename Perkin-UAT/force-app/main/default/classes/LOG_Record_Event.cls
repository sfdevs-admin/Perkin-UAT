/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ATEAM-1244
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*   - This apex class is used to create records for 'SFDC_LOG' object.
*   - This apex class will handle all logic for error/exception log creation.
*   - This can be invoked in other class to handle error/exception logging framework.
*
* 3. Objects referenced
*    -SFDC_LOG__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: LOG_Record_Event_Test
*
* 7. Author Name(s): 
*    - Amiya 2021.06.03
*    - First Last & Updated Date(YYYY.MM.DD)
*    - First Last & Updated Date(YYYY.MM.DD)
*
*********************************************************************/ 
public with sharing class LOG_Record_Event {
    
    public static void addErrorLogs(string sourceType, string sourceName, string sourceStep, string runningUser, string shortMsg, string longMsg,
                                    string logType ){
                                        system.debug('sourceType='+sourceType);
                                        list<SFDC_LOG__c> logList = new list<SFDC_LOG__c>();
                                        // creating 'SFDC_LOG' records
                                        SFDC_LOG__c objSfdcLog = new SFDC_LOG__c();
                                        objSfdcLog.Log_Type__c = logType;
                                        objSfdcLog.Message__c = shortMsg;
                                        objSfdcLog.Message_Long__c = longMsg;
                                        objSfdcLog.Running_User__c = runningUser;
                                        objSfdcLog.Source_Name__c = sourceName;
                                        objSfdcLog.Source_Step__c = sourceStep;
                                        objSfdcLog.Source_Type__c = sourceType;
                                        logList.add(objSfdcLog);
                                        saveErrorLog(logList);                            
                                    }
    
    Public class FlowInputs {         
        @InvocableVariable public String sourceType;         
        @InvocableVariable public String sourceName;
        @InvocableVariable public String sourceStep;
        @InvocableVariable public String runningUser;
        @InvocableVariable public String shortMsg;
        @InvocableVariable public String longMsg;
        @InvocableVariable public String logType;
    }
    
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        system.debug('requests==>'+requests);
        string varSourceType;
        String varSourceName;
        String varSourceStep;
        String varRunningUser;
        String varShortMsg;
        String varLongMsg;
        String varLogType;
        
        if(!requests.isEmpty()){
            varSourceType =requests[0].sourceType;
            varSourceName=requests[0].sourceName;
            varSourceStep=requests[0].sourceStep;
            varRunningUser=requests[0].runningUser;
            varShortMsg=requests[0].shortMsg;
            varLongMsg=requests[0].longMsg;
            varLogType=requests[0].logType;
            
        }
        addErrorLogs(varSourceType, varSourceName, varSourceStep, varRunningUser, varShortMsg, varLongMsg, varLogType);
        
    }
    
    public static void saveErrorLog(list<SFDC_LOG__c> logList){
        system.debug('logList='+logList);
        // checking if list is not null or empty
        if(logList != null){
            // using database.insert for bulk insetion
            try{
              Database.SaveResult[] srList=Database.insert(logList, false); // inserting list of error logs records  
                for (Database.SaveResult sr : srList){
                    if(sr.isSuccess())
                    System.debug(sr.getId());
                    else
                        system.debug(sr.errors);
                }
                
            }catch(exception ex){
                system.debug('ex'+ex.getCause()+ex.getMessage());
            }
            
        }
    }
}
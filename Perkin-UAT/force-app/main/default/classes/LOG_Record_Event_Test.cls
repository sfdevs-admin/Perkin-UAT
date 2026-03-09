/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1244
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *   - This is test class for :- LOG_Record_Event
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
  * 6. Test Class Name: NA
  *
  * 7. Author Name(s): 
  *    - Amiya Das 2021.06.03
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*********************************************************************/ 
@isTest
public with sharing class LOG_Record_Event_Test {
    
    public static testmethod void testaddErrorLogs(){

        list<SFDC_LOG__c> logLst = new list<SFDC_LOG__c>();

        SFDC_LOG__c objLog;

        for(Integer i =0; i<3; i ++){
            objLog = new SFDC_LOG__c();
          //  objLog.Name = 'testlog1'+string.valueof(i);
            objLog.Log_Type__c  = 'Error/Exception Log';
            objLog.Message__c = 'TestMesg'+string.valueof(i);
            objLog.Message_Long__c = 'testMsgLong'+string.valueof(i);
            objLog.Running_User__c = 'Current User Name'+string.valueof(i);
            objLog.Source_Name__c = 'Apex Class'+string.valueof(i);
            objLog.Source_Step__c = 'L.FLOW Node'+string.valueof(i);
            objLog.Source_Type__c = 'L.FLOW';

            logLst.add(objLog);
            // system.assert(objLog.Id != null);

        }
        insert logLst;
        system.assert(logLst[0].Id != null);

        test.startTest();
       // LOG_Record_Event logRcrdEvt = new LOG_Record_Event();
       List<LOG_Record_Event.FlowInputs> listRequest =new List<LOG_Record_Event.FlowInputs>();
      LOG_Record_Event.FlowInputs req = new LOG_Record_Event.FlowInputs();
        req.SourceType='APEX';
         req.SourceName='Apex Class';
         req.SourceStep='L.FLOW Node';
         req.RunningUser='Amiya';
         req.ShortMsg='Logs Gen';
         req.LongMsg='Logs generated in system';
         req.LogType='Error/Exception Log';
        listRequest.add(req);
        LOG_Record_Event.flowcalled(listRequest);
      //  LOG_Record_Event.addErrorLogs('APEX', 'Apex Class', 'L.FLOW Node', 'Amiya', 'Logs Gen', 'Logs generated in system',
       //                                 'Error/Exception Log');
        test.stopTest();
    }

    public static testmethod void testsaveErrorLog(){

        test.startTest();
       // LOG_Record_Event.saveErrorLog();
        test.stopTest();

    }
}
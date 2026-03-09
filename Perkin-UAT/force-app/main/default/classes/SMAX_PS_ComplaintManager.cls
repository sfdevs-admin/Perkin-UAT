/*
 *  Apex Class for Complaint [SMAX_PS_Complaint__c] Business Logic.
 *  2017-10-04      Veerendra Moodbidri       Initial creation, for Complaint Outbound Integration.
 *  1. Delete all the child records related to the Complaints if the Completed Transaction number after update do not match with the Last Transaction Number of the child records.
 */
public with sharing class SMAX_PS_ComplaintManager {

    private SMAX_PS_ComplaintManager() {
    }

    public static void deleteComplaintChildRecords(List<SMAX_PS_Complaint__c> newComplaintList, Map<Id, SMAX_PS_Complaint__c> oldComplaintMap)
    {        
        Set<Id> cmpntIds = new Set<Id>();

        List<SMAX_PS_ComplaintPart__c> cPartDeleteList = new List<SMAX_PS_ComplaintPart__c>();
        List<SMAX_PS_ComplaintFaultCode__c> cfCodeDeleteList = new List<SMAX_PS_ComplaintFaultCode__c>();
        List<SMAX_PS_ComplaintTask__c> cTaskDeleteList = new List<SMAX_PS_ComplaintTask__c>();

        Map<id, list<SMAX_PS_ComplaintPart__c>> cPartMap = new Map<id, list<SMAX_PS_ComplaintPart__c>>();
        Map<id, list<SMAX_PS_ComplaintFaultCode__c>> cfCodeMap = new Map<id, list<SMAX_PS_ComplaintFaultCode__c>>();
        Map<id, list<SMAX_PS_ComplaintTask__c>> cTaskMap = new Map<id, list<SMAX_PS_ComplaintTask__c>>();

        if (!newComplaintList.isEmpty()) {
            for (SMAX_PS_Complaint__c cmpnt : newComplaintList) {
                if ( oldComplaintMap.get(cmpnt.id) != null && oldComplaintMap.get(cmpnt.id).SMAX_PS_CompletedTxnNum__c != cmpnt.SMAX_PS_CompletedTxnNum__c )
                    cmpntIds.add(cmpnt.id);
            }
        }
        if (cmpntIds.isEmpty())
            return;

        ///////////////////// Fill in Complaint Parts Map
        List<SMAX_PS_ComplaintPart__c> cPartList = new List<SMAX_PS_ComplaintPart__c>([SELECT Id, Name, SMAX_PS_Complaint__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ComplaintPart__c WHERE SMAX_PS_Complaint__c IN :cmpntIds]);
        if (!cPartList.isEmpty()) {
            for (SMAX_PS_ComplaintPart__c cp : cPartList) {
                List<SMAX_PS_ComplaintPart__c> listCPart = new List<SMAX_PS_ComplaintPart__c>();                
                if(cPartMap.containskey(cp.SMAX_PS_Complaint__c)) {
                    listCPart = cPartMap.get(cp.SMAX_PS_Complaint__c);
                }
                listCPart.add(cp);
                cPartMap.put(cp.SMAX_PS_Complaint__c, listCPart);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( SMAX_PS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Parts
                List<SMAX_PS_ComplaintPart__c> listCPart = new List<SMAX_PS_ComplaintPart__c>();
                if ( cPartMap.ContainsKey(cmplnt.Id) ) {
                    listCPart = cPartMap.get(cmplnt.Id);
                    if (!listCPart.isEmpty()) {
                        for (SMAX_PS_ComplaintPart__c cp : listCPart) {
                            if (cp.SMAX_PS_LastTxnNum__c != cmplnt.SMAX_PS_CompletedTxnNum__c)
                                cPartDeleteList.add(cp);
                        }
                    }
                }
            }
            // delete Complaint Parts
            if (!cPartDeleteList.isEmpty())
                delete cPartDeleteList;
        }

        ///////////////////// Fill in Complaint Fault Code Map
        List<SMAX_PS_ComplaintFaultCode__c> cfCodeList = new List<SMAX_PS_ComplaintFaultCode__c>([SELECT Id, Name, SMAX_PS_Complaint__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ComplaintFaultCode__c WHERE SMAX_PS_Complaint__c IN :cmpntIds]);
        if (!cfCodeList.isEmpty()) {
            for (SMAX_PS_ComplaintFaultCode__c cp : cfCodeList) {
                List<SMAX_PS_ComplaintFaultCode__c> cfcList = new List<SMAX_PS_ComplaintFaultCode__c>();                
                if(cfCodeMap.containskey(cp.SMAX_PS_Complaint__c)) {
                    cfcList = cfCodeMap.get(cp.SMAX_PS_Complaint__c);
                }
                cfcList.add(cp);
                cfCodeMap.put(cp.SMAX_PS_Complaint__c, cfcList);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( SMAX_PS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Fault codes
                List<SMAX_PS_ComplaintFaultCode__c> cfcList = new List<SMAX_PS_ComplaintFaultCode__c>();
                if ( cfCodeMap.ContainsKey(cmplnt.Id) ) {
                    cfcList = cfCodeMap.get(cmplnt.Id);
                    if (!cfcList.isEmpty()) {
                        for (SMAX_PS_ComplaintFaultCode__c cp : cfcList) {
                            if (cp.SMAX_PS_LastTxnNum__c != cmplnt.SMAX_PS_CompletedTxnNum__c)
                                cfCodeDeleteList.add(cp);
                        }
                    }
                }
            }
            // delete Complaint Fault codes
            if (!cfCodeDeleteList.isEmpty())
                delete cfCodeDeleteList;
        }

        ///////////////////// Fill in Complaint Task Map
        List<SMAX_PS_ComplaintTask__c> cTaskList = new List<SMAX_PS_ComplaintTask__c>([SELECT Id, Name, SMAX_PS_Complaint__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ComplaintTask__c WHERE SMAX_PS_Complaint__c IN :cmpntIds]);
        if (!cTaskList.isEmpty()) {
            for (SMAX_PS_ComplaintTask__c cp : cTaskList) {
                List<SMAX_PS_ComplaintTask__c> listTask = new List<SMAX_PS_ComplaintTask__c>();                
                if(cTaskMap.containskey(cp.SMAX_PS_Complaint__c)) {
                    listTask = cTaskMap.get(cp.SMAX_PS_Complaint__c);
                }
                listTask.add(cp);
                cTaskMap.put(cp.SMAX_PS_Complaint__c, listTask);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( SMAX_PS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Tasks
                List<SMAX_PS_ComplaintTask__c> listTask = new List<SMAX_PS_ComplaintTask__c>();
                if ( cTaskMap.ContainsKey(cmplnt.Id) ) {
                    listTask = cTaskMap.get(cmplnt.Id);
                    if (!listTask.isEmpty()) {
                        for (SMAX_PS_ComplaintTask__c cp : listTask) {
                            if (cp.SMAX_PS_LastTxnNum__c != cmplnt.SMAX_PS_CompletedTxnNum__c)
                                cTaskDeleteList.add(cp);
                        }
                    }
                }
            }
            // delete Complaint Tasks
            if (!cTaskDeleteList.isEmpty())
                delete cTaskDeleteList;
        }
/*        cfCodeMap=fillMap(cfCodeList, 'SMAX_PS_ComplaintFaultCode__c');
    }

    private static Map<id, list<sObject>> fillMap(List<sObject> inList, String vObjectName) {

        Map<id, list<sObject>> xxMap = new Map<id, list<sObject>>();
        integer    flag=0;
        if (!inList.isEmpty()) {
            for (Sobject cp : inList) {
                List<sObject> xxList = new List<sObject>();
                SMAX_PS_ComplaintFaultCode__c TempSobj = (SMAX_PS_ComplaintFaultCode__c)cp;               
                if(xxMap.containskey(TempSobj.SMAX_PS_Complaint__c)) {
                    xxList = xxMap.get(TempSobj.SMAX_PS_Complaint__c);
                }
                xxList.add(TempSobj);
                xxMap.put(TempSobj.SMAX_PS_Complaint__c, xxList);
            }
        }
        return xxMap; */
    }
}
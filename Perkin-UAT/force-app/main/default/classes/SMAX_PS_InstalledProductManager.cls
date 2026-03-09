/*
 *  Apex Class for Installed Product [SVMXC__Installed_Product__c] Business Logic.
 *  2017-08-11      Veerendra Moodbidri       Initial creation, for IB Outbound Integration.
 *  1. Fetch locaion address from Location object and update in IP when a new IP is created.
 *  2. When a location address is changed, update the new location address in all related IPs of that location.
 */
public with sharing class SMAX_PS_InstalledProductManager {

    private SMAX_PS_InstalledProductManager() {
    }

    public static void updateIPAddressFields(List<SVMXC__Installed_Product__c> newIPList, Map<Id, SVMXC__Installed_Product__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Installed Product Address', 'Get the address from Location and update in Installed Product.'))
            return;

        List<SVMXC__Installed_Product__c> ipList = new List<SVMXC__Installed_Product__c>();
        Set<Id> locIds = new Set<Id>();
        for (SVMXC__Installed_Product__c ip : newIPList)
        {
            SVMXC__Installed_Product__c old = (oldMap == null) ? null : oldMap.get(ip.Id);
            if (ip.SVMXC__Site__c != null && (old == null || ip.SVMXC__Site__c != old.SVMXC__Site__c))
            {
                ipList.add(ip);
                locIds.add(ip.SVMXC__Site__c);
            }
        }

        if (locIds.isEmpty())
            return;

        Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SVMXC__Street__c, SVMXC__City__c, 
            SVMXC__State__c, SVMXC__Zip__c, SVMXC__Country__c FROM SVMXC__Site__c WHERE Id IN :locIds]);

        for (SVMXC__Installed_Product__c ip : ipList) 
        {
            SVMXC__Site__c loc = locMap.get(ip.SVMXC__Site__c);
            if (loc != null)
            {
                ip.SVMXC__Street__c = loc.SVMXC__Street__c;
                ip.SVMXC__City__c = loc.SVMXC__City__c;
                ip.SVMXC__State__c = loc.SVMXC__State__c;
                ip.SVMXC__Zip__c = loc.SVMXC__Zip__c;
                ip.SVMXC__Country__c = loc.SVMXC__Country__c;
            }
        }
    }

    public static void updateLookups(List<SVMXC__Installed_Product__c> newIpList, Map<Id, SVMXC__Installed_Product__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Lookups', 'Update Preferred and Secondary Technician in Installed Product from the Technician.'))
            return;

        Set<String> techIds = new Set<String>();
        List<SVMXC__Installed_Product__c> preferredIps = new List<SVMXC__Installed_Product__c>();
        List<SVMXC__Installed_Product__c> secondaryIps = new List<SVMXC__Installed_Product__c>();
        // SVMXINT-516 - Add Partner Accounts to IP
        Set<String> accountIds = new Set<String>();
        List<SVMXC__Installed_Product__c> accountIps = new List<SVMXC__Installed_Product__c>();
        for (SVMXC__Installed_Product__c ip : newIpList)
        {
            SVMXC__Installed_Product__c old = (oldMap == null) ? null : oldMap.get(ip.Id);
            if (ip.SMAX_PS_PreferredTechnicianNumber__c != null &&
                (ip.SVMXC__Preferred_Technician__c == null || 
                    (old != null && ip.SMAX_PS_PreferredTechnicianNumber__c != old.SMAX_PS_PreferredTechnicianNumber__c)))
            {
                techIds.add(ip.SMAX_PS_PreferredTechnicianNumber__c);
                preferredIps.add(ip);
            }
            // IT-SFDC 578 - Blank out technican name if number is blank
            if (ip.SMAX_PS_PreferredTechnicianNumber__c == null)
            {
             ip.SVMXC__Preferred_Technician__c = null;
            }
            if (ip.SMAX_PS_SecondaryTechnicianNumber__c != null &&
                (ip.SMAX_PS_Secondary_Technician__c == null || 
                    (old != null && ip.SMAX_PS_SecondaryTechnicianNumber__c != old.SMAX_PS_SecondaryTechnicianNumber__c)))
            {
                techIds.add(ip.SMAX_PS_SecondaryTechnicianNumber__c);
                secondaryIps.add(ip);
            }
            // IT-SFDC 578 - Blank out technican name if number is blank
             if (ip.SMAX_PS_SecondaryTechnicianNumber__c == null)
            {
             ip.SMAX_PS_Secondary_Technician__c = null;
            }
            
            if (ip.SMAX_PS_SoldTo_ExtId__c != null &&
                (ip.SMAX_PS_SoldTo_Account__c == null || (old != null && ip.SMAX_PS_SoldTo_ExtId__c != old.SMAX_PS_SoldTo_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_SoldTo_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_SoldTo_Account__c = null;
            }

            if (ip.SMAX_PS_ShipTo_ExtId__c != null &&
                (ip.SMAX_PS_ShipTo_Account__c == null || (old != null && ip.SMAX_PS_ShipTo_ExtId__c != old.SMAX_PS_ShipTo_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_ShipTo_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_ShipTo_Account__c = null;
            }

            if (ip.SMAX_PS_BillTo_ExtId__c != null &&
                (ip.SMAX_PS_BillTo_Account__c == null || (old != null && ip.SMAX_PS_BillTo_ExtId__c != old.SMAX_PS_BillTo_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_BillTo_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_BillTo_Account__c = null;
            }

            if (ip.SMAX_PS_Payer_ExtId__c != null &&
                (ip.SMAX_PS_Payer_Account__c == null || (old != null && ip.SMAX_PS_Payer_ExtId__c != old.SMAX_PS_Payer_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_Payer_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_Payer_Account__c = null;
            }

            // SVMXINT-624 Local Language Partner on Equipment
            if (ip.SMAX_PS_LL_ShipTo_ExtId__c != null &&
                (ip.SMAX_PS_LL_ShipTo_Account__c == null
                    || (old != null && ip.SMAX_PS_LL_ShipTo_ExtId__c != old.SMAX_PS_LL_ShipTo_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_LL_ShipTo_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_LL_ShipTo_Account__c = null;
            }

            if (ip.SMAX_PS_LL_BillTo_ExtId__c != null &&
                (ip.SMAX_PS_LL_BillTo_Account__c == null
                    || (old != null && ip.SMAX_PS_LL_BillTo_ExtId__c != old.SMAX_PS_LL_BillTo_ExtId__c)))
            {
                accountIds.add(ip.SMAX_PS_LL_BillTo_ExtId__c);
                accountIps.add(ip);
                ip.SMAX_PS_LL_BillTo_Account__c = null;
            }

            // SVMXINT-576 Installed Product : Partner (blanks)
            if (ip.SMAX_PS_SoldTo_ExtId__c == null && ip.SMAX_PS_SoldTo_Account__c != null)
                ip.SMAX_PS_SoldTo_Account__c = null;
            if (ip.SMAX_PS_ShipTo_ExtId__c == null && ip.SMAX_PS_ShipTo_Account__c != null)
                ip.SMAX_PS_ShipTo_Account__c = null;
            if (ip.SMAX_PS_BillTo_ExtId__c == null && ip.SMAX_PS_BillTo_Account__c != null)
                ip.SMAX_PS_BillTo_Account__c = null;
            if (ip.SMAX_PS_Payer_ExtId__c == null && ip.SMAX_PS_Payer_Account__c != null)
                ip.SMAX_PS_Payer_Account__c = null;
            if (ip.SMAX_PS_LL_ShipTo_ExtId__c == null && ip.SMAX_PS_LL_ShipTo_Account__c != null)
                ip.SMAX_PS_LL_ShipTo_Account__c = null;
            if (ip.SMAX_PS_LL_BillTo_ExtId__c == null && ip.SMAX_PS_LL_BillTo_Account__c != null)
                ip.SMAX_PS_LL_BillTo_Account__c = null;
        }

        if (!techIds.isEmpty())
        {
            Map<String, SVMXC__Service_Group_Members__c> techMap = new Map<String, SVMXC__Service_Group_Members__c>();
            for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMX_PS_External_ID__c 
                FROM SVMXC__Service_Group_Members__c WHERE SVMX_PS_External_ID__c IN :techIds])
            {
                techMap.put(tech.SVMX_PS_External_ID__c, tech);
            }

            // ITSVMX-1678 Lookup the Additional Work Centers as an alternate way to find the Technician
            Map<String, SMAX_PS_Additional_Work_Centers__c> awcMap = new Map<String, SMAX_PS_Additional_Work_Centers__c>();
            for (SMAX_PS_Additional_Work_Centers__c awc : [SELECT Id, Name, SMAX_PS_Plant_Work_Center__c, SMAX_PS_Technician_Equipment__c
                FROM SMAX_PS_Additional_Work_Centers__c WHERE SMAX_PS_Plant_Work_Center__c IN :techIds])
            {
                awcMap.put(awc.SMAX_PS_Plant_Work_Center__c, awc);
            }

            for (SVMXC__Installed_Product__c ip : preferredIps)
            {
                if (techMap.containsKey(ip.SMAX_PS_PreferredTechnicianNumber__c)) {
                    ip.SVMXC__Preferred_Technician__c = techMap.get(ip.SMAX_PS_PreferredTechnicianNumber__c).Id;
                } else if (awcMap.containsKey(ip.SMAX_PS_PreferredTechnicianNumber__c)) {
                    ip.SVMXC__Preferred_Technician__c = awcMap.get(ip.SMAX_PS_PreferredTechnicianNumber__c).SMAX_PS_Technician_Equipment__c;
                }
            }

            for (SVMXC__Installed_Product__c ip : secondaryIps)
            {
                if (techMap.containsKey(ip.SMAX_PS_SecondaryTechnicianNumber__c)) {
                    ip.SMAX_PS_Secondary_Technician__c = techMap.get(ip.SMAX_PS_SecondaryTechnicianNumber__c).Id;
                } else if (awcMap.containsKey(ip.SMAX_PS_SecondaryTechnicianNumber__c)) {
                    ip.SMAX_PS_Secondary_Technician__c = awcMap.get(ip.SMAX_PS_SecondaryTechnicianNumber__c).SMAX_PS_Technician_Equipment__c;
                }
            }
        }

        if (!accountIds.isEmpty())
        {
            Map<String, Account> acctMap = new Map<String, Account>();
            for (Account acct : [SELECT Id, Name, PKI_SAP_Customer_Number__c 
                FROM Account WHERE PKI_SAP_Customer_Number__c IN :accountIds])
            {
                acctMap.put(acct.PKI_SAP_Customer_Number__c, acct);
            }

            for (SVMXC__Installed_Product__c ip : accountIps)
            {
                if (ip.SMAX_PS_SoldTo_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_SoldTo_ExtId__c))
                {
                    ip.SMAX_PS_SoldTo_Account__c = acctMap.get(ip.SMAX_PS_SoldTo_ExtId__c).Id;
                }
                if (ip.SMAX_PS_ShipTo_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_ShipTo_ExtId__c))
                {
                    ip.SMAX_PS_ShipTo_Account__c = acctMap.get(ip.SMAX_PS_ShipTo_ExtId__c).Id;
                }
                if (ip.SMAX_PS_BillTo_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_BillTo_ExtId__c))
                {
                    ip.SMAX_PS_BillTo_Account__c = acctMap.get(ip.SMAX_PS_BillTo_ExtId__c).Id;
                }
                if (ip.SMAX_PS_Payer_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_Payer_ExtId__c))
                {
                    ip.SMAX_PS_Payer_Account__c = acctMap.get(ip.SMAX_PS_Payer_ExtId__c).Id;
                }
                // SVMXINT-624 Local Language Partner on Equipment
                if (ip.SMAX_PS_LL_ShipTo_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_LL_ShipTo_ExtId__c))
                {
                    ip.SMAX_PS_LL_ShipTo_Account__c = acctMap.get(ip.SMAX_PS_LL_ShipTo_ExtId__c).Id;
                }
                if (ip.SMAX_PS_LL_BillTo_ExtId__c != null && acctMap.containsKey(ip.SMAX_PS_LL_BillTo_ExtId__c))
                {
                    ip.SMAX_PS_LL_BillTo_Account__c = acctMap.get(ip.SMAX_PS_LL_BillTo_ExtId__c).Id;
                }
            }
        }
    }

    public static void deleteIPclassifications(List<SVMXC__Installed_Product__c> newIpList, Map<Id, SVMXC__Installed_Product__c> oldIpMap)
    {        
        if (!SMAX_PS_Utility.isActive('Delete IP Classifications', 'Deletes the records in IP Classifications.'))
            return;

        List<SMAX_PS_InstalledProductClassification__c> ipcDeleteList = new List<SMAX_PS_InstalledProductClassification__c>();
        Map<id, list<SMAX_PS_InstalledProductClassification__c>> ipcMap = new Map<id, list<SMAX_PS_InstalledProductClassification__c>>();
        Set<Id> ipIds = new Set<Id>();

        if (!newIpList.isEmpty()) {
            for (SVMXC__Installed_Product__c ip : newIpList)
            {
                if ( oldIpMap.get(ip.id) != null && oldIpMap.get(ip.id).SMAX_PS_CompletedTxnNum__c != ip.SMAX_PS_CompletedTxnNum__c )
                    ipIds.add(ip.id);
            }
        }
        if (ipIds.isEmpty())
            return;

        List<SMAX_PS_InstalledProductClassification__c> ipcList = new List<SMAX_PS_InstalledProductClassification__c>([SELECT Id, Name, SMAX_PS_InstalledProduct__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_InstalledProductClassification__c WHERE SMAX_PS_InstalledProduct__c IN :ipIds]);

        // Fill in Installed Product Classification Map
        if (!ipcList.isEmpty()) {
            for (SMAX_PS_InstalledProductClassification__c ipc : ipcList) {
                List<SMAX_PS_InstalledProductClassification__c> listIPC = new List<SMAX_PS_InstalledProductClassification__c>();                
                if(ipcMap.containskey(ipc.SMAX_PS_InstalledProduct__c)) {
                    listIPC = ipcMap.get(ipc.SMAX_PS_InstalledProduct__c);
                }
                listIPC.add(ipc);
                ipcMap.put(ipc.SMAX_PS_InstalledProduct__c, listIPC);
            }
        }

        // Main process
        if (!newIpList.isEmpty()) {
            for ( SVMXC__Installed_Product__c ip : newIpList ) {
                // create list of records to be deleted in Installed Product Classifications
                List<SMAX_PS_InstalledProductClassification__c> listIPC = new List<SMAX_PS_InstalledProductClassification__c>();
                if ( ipcMap.ContainsKey(ip.Id) ) {
                    listIPC = ipcMap.get(ip.Id);
                    if (!listIPC.isEmpty()) {
                        for (SMAX_PS_InstalledProductClassification__c ipc : listIPC) {
                            if (ipc.SMAX_PS_LastTxnNum__c != ip.SMAX_PS_CompletedTxnNum__c)
                                ipcDeleteList.add(ipc);
                        }
                    }
                }
            }
            if (!ipcDeleteList.isEmpty())
                delete ipcDeleteList;
        }
    }

    public static void calibratedToolChangeLog(List<SVMXC__Installed_Product__c> ipList, Map<Id, SVMXC__Installed_Product__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('CalibratedTool ChangeLog', 'Creates a change log record every time a Calibrated Tool is changed.'))
            return;

        List<SMAX_PS_MTE_Change_Log__c> changeLogs = new List<SMAX_PS_MTE_Change_Log__c>();
        RecordType calToolRecType = SMAX_PS_Utility.getRecordType('SVMXC__Installed_Product__c', 'SMAX_PS_Calibrated_Tools');
        for (SVMXC__Installed_Product__c ip : ipList)
        {
            if (ip.RecordTypeId == calToolRecType.Id && ip.SMAX_PS_MTE_Change_Reason__c != null)
            {
                // Found one.. create a Change Log and blank out fields.
                SMAX_PS_MTE_Change_Log__c log = new SMAX_PS_MTE_Change_Log__c();
                log.SMAX_PS_Installed_Product__c = ip.Id;
                log.SMAX_PS_MTE_Change_Reason__c = ip.SMAX_PS_MTE_Change_Reason__c;
                log.SMAX_PS_MTE_Change_Description__c = ip.SMAX_PS_MTE_Change_Description__c;

                ip.SMAX_PS_MTE_Change_Reason__c = null;
                ip.SMAX_PS_MTE_Change_Description__c = null;

                String summary = 'Summary of changes made:';
                SVMXC__Installed_Product__c old = oldMap.get(ip.Id);
                Map<String, Schema.SObjectField> fieldMap = SMAX_PS_Utility.getFields('SVMXC__Installed_Product__c');
                for (String fieldName : fieldMap.keySet())
                {
                    Schema.DescribeFieldResult fieldInfo = fieldMap.get(fieldName).getDescribe();
                    if (ip.get(fieldName) != old.get(fieldName))
                    {
                        summary += '\nChanged ' + fieldInfo.getLabel() + ' from ' + old.get(fieldName) + ' to ' + ip.get(fieldName) + '.';
                    }
                }
                log.SMAX_PS_Summary_of_Changes__c = summary;
                changeLogs.add(log);
            }
        }

        if (!changeLogs.isEmpty())
            insert changeLogs;
    }
}
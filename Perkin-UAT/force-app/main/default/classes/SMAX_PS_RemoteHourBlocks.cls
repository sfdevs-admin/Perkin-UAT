/**
 * Created by tony on 8/10/21.
 */

public without sharing class SMAX_PS_RemoteHourBlocks {

    public class RemoteHourBlock {
        @AuraEnabled public Boolean remoteHourBlock {get;set;}
        @AuraEnabled public Boolean selectedCoveredProduct {get;set;}
        @AuraEnabled public String installedProduct {get;set;}
        @AuraEnabled public String slaTermsNotes {get;set;}
        @AuraEnabled public String itemQty {get;set;}
        @AuraEnabled public String itemQtyRemaining {get;set;}
        @AuraEnabled public String remoteHoursRemaining {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public String coveredProduct {get;set;}
        @AuraEnabled public String serviceMaintenanceContract {get;set;}
        @AuraEnabled public String installedProductId {get;set;}
        @AuraEnabled public String coveredProductId {get;set;}
        @AuraEnabled public String serviceMaintenanceContractId {get;set;}
        // 10/5/21 ITSVMX-620 CONTRACTS ENTITLEMENT IMPROVEMENTS
        @AuraEnabled public String salesOrg {get;set;}
                // 4/6/22 ITSVMX-710 Contract Description
        @AuraEnabled public String description {get;set;}
    }

    // 9/13/21 Tony ITSVMX-408 Added so we can show indicator for the entitlement that is selected on the WO
    @AuraEnabled(Cacheable=true)
    public static List<RemoteHourBlock> getRemoteHourBlocksForRecord(Id recordId) {
        return getRemoteHourBlocksForRecord(recordId, null);
    }

    // ITSVMX-408 Used by the SmaxRemoteHourBlocks LWC
    @AuraEnabled(Cacheable=true)
    public static List<RemoteHourBlock> getRemoteHourBlocksForRecord(Id recordId, Id selectedEntitlementId) {

        System.debug('recordId: ' + recordId);

        List<SVMXC__Service_Contract__c> newContractItems = new List<SVMXC__Service_Contract__c>();
        List<RemoteHourBlock> remoteHourBlocks = new List<RemoteHourBlock>();

        // Determine what object we are dealing with from the recordId
        SObjectType workOrderType = Schema.SVMXC__Service_Order__c.SObjectType;
        SObjectType caseType = Schema.Case.SObjectType;
        SObjectType installedProductType = Schema.SVMXC__Installed_Product__c.SObjectType;
        SObjectType objectType = recordId.getSobjectType();

        if (objectType == workOrderType) {

            System.debug('Work Order Object Type: ' + recordId);
            // 8/24/21 Tony - Request was made to include all record types
//            Id remoteRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();
            List<SVMXC__Service_Order__c> wos = [
                    SELECT  Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_CoveredProduct__c,
                            RecordTypeId, SVMXC__Component__c
                    FROM SVMXC__Service_Order__c
                    WHERE Id = :recordId
                    // 8/24/21 Tony - Request was made to include all record types
//                    AND RecordTypeId = :remoteRecordTypeId
            ];
            System.debug('wos: ' + wos);

            if (wos.size() > 0) {
                Id ipId = wos[0].SVMXC__Component__c;
                System.debug('Work Order Found.  Installed Product for RWO: ' + ipId);
                if (ipId != null) {
                    // 9/13/21 Tony - Updated so we can send the selected entitlement
                    return getRemoteHourBlocksForRecord(ipId, wos[0]?.SMAX_PS_CoveredProduct__c);
                }
            } else {

                System.debug('Work Order not found.  Stop Remote Hour Block processing.');
                return null;
            }

        }  else if (objectType == caseType) {

            System.debug('Case Object Type: ' + recordId);
            List<Case> caseRecord = [
                    SELECT  Id, SVMXC__Component__c, RecordTypeId
                    FROM Case
                    WHERE Id = :recordId
            ];
            System.debug('caseRecord: ' + caseRecord);

            if (caseRecord.size() > 0) {
                Id ipId = caseRecord[0].SVMXC__Component__c;
                System.debug('Case Found.  Installed Product for Case: ' + ipId);
                if (ipId != null) {
                    return getRemoteHourBlocksForRecord(ipId);
                }
            } else {

                System.debug('Case not found.  Stop Remote Hour Block processing.');
                return null;
            }

        } else if (objectType == installedProductType) {

            System.debug('Installed Product Object Type: ' + recordId);
            List<SVMXC__Installed_Product__c> ips = [
                    SELECT Id, Name, SVMXC__Service_Contract__c, SVMXC__Service_Contract_Line__c
                    FROM SVMXC__Installed_Product__c
                    WHERE Id = :recordId
            ];
            System.debug('ip: ' + ips);

            // Use the Contract Products to get the Contract Item info associated to this Installed Product
            List<SVMXC__Service_Contract_Products__c> contractProducts = [
                    SELECT Id, Name, SMAX_PS_SLA_Terms_Notes__c, SMAX_PS_IsDeleted__c, SVMXC__Service_Contract__c, SVMX_PS_Contract_Active__c,
                            SVMXC__Service_Contract__r.BD_Item_Qty__c, SVMXC__Service_Contract__r.BD_Item_Qty_Remaining__c,
                            SVMXC__Installed_Product__r.Name, SVMXC__Service_Contract__r.SVMXC__Start_Date__c,
                            SVMXC__Service_Contract__r.SVMXC__End_Date__c, SVMXC__Service_Contract__r.Name,
                            SVMXC__Service_Contract__r.BD_Remote_Hours_Remaining__c, SVMXC__Installed_Product__c,
                            // 10/5/21 ITSVMX-620 CONTRACTS ENTITLEMENT IMPROVEMENTS
//                            SVMXC__Installed_Product__r.SMAX_PS_SalesOrg__c
                            // 12/9/21 ITSMVX-620 updated that we should get the Sales Org from the Parent Service Contract
                            SMAX_PS_Parent_Contract__r.SMAX_PS_SalesOrg__c,
                           // 4/6/22 ITSVMX-710 Contract Description
                            SMAX_PS_Parent_Contract__r.SMAX_PS_Description__c      
                    FROM SVMXC__Service_Contract_Products__c
                    WHERE SVMXC__Installed_Product__c = :recordId
            ];
            System.debug('contractProducts: ' + contractProducts);

            // Fill out the RemoteHourBlock list from the contract products
            Date today = Date.today();
            for (SVMXC__Service_Contract_Products__c contractProduct :contractProducts) {

                // Only do this for Remote Support Hours and current date is in the active range
                if (contractProduct.SMAX_PS_SLA_Terms_Notes__c != null
                        && contractProduct.SMAX_PS_IsDeleted__c == False
//                        && contractProduct.SMAX_PS_SLA_Terms_Notes__c.contains('ZHRS-Remote Support Hours')
                        && contractProduct.SVMXC__Service_Contract__r.SVMXC__Start_Date__c <= today
                        && contractProduct.SVMXC__Service_Contract__r.SVMXC__End_Date__c >= today) {

                    RemoteHourBlock rhb = new RemoteHourBlock();

                    if (contractProduct.SMAX_PS_SLA_Terms_Notes__c.contains('ZHRS-Remote Support Hours')) {
                        rhb.remoteHourBlock = true;
                    } else {
                        rhb.remoteHourBlock = false;
                    }

                    // 9/13/21 Tony - Added to support the highlighting of the selected entitlement
                    if (contractProduct.Id == selectedEntitlementId) {
                        rhb.selectedCoveredProduct = true;
                    } else {
                        rhb.selectedCoveredProduct = false;
                    }

                    rhb.installedProductId = contractProduct.SVMXC__Installed_Product__c;
                    rhb.installedProduct = contractProduct.SVMXC__Installed_Product__r.Name;
                    rhb.slaTermsNotes = contractProduct.SMAX_PS_SLA_Terms_Notes__c;
                    rhb.itemQty = String.valueOf(contractProduct.SVMXC__Service_Contract__r.BD_Item_Qty__c);
                    rhb.itemQtyRemaining = String.valueOf(contractProduct.SVMXC__Service_Contract__r.BD_Item_Qty_Remaining__c);
                    rhb.remoteHoursRemaining = String.valueOf(contractProduct.SVMXC__Service_Contract__r.BD_Remote_Hours_Remaining__c);
                    rhb.startDate = contractProduct.SVMXC__Service_Contract__r.SVMXC__Start_Date__c;
                    rhb.endDate = contractProduct.SVMXC__Service_Contract__r.SVMXC__End_Date__c;
                    rhb.coveredProductId = contractProduct.Id;
                    rhb.coveredProduct = contractProduct.Name;
                    rhb.serviceMaintenanceContractId = contractProduct.SVMXC__Service_Contract__c;
                    rhb.serviceMaintenanceContract = contractProduct.SVMXC__Service_Contract__r.Name;
                    // 10/5/21 ITSVMX-620 CONTRACTS ENTITLEMENT IMPROVEMENTS
//                    rhb.salesOrg = contractProduct.SVMXC__Installed_Product__r.SMAX_PS_SalesOrg__c;
                    // 12/9/21 ITSMVX-620 updated that we should get the Sales Org from the Parent Service Contract
                    rhb.salesOrg = contractProduct.SMAX_PS_Parent_Contract__r.SMAX_PS_SalesOrg__c;
                    // 4/6/22 ITSVMX-710 Contract Description
                    rhb.description = contractProduct.SMAX_PS_Parent_Contract__r.SMAX_PS_Description__c;
                    
                    remoteHourBlocks.add(rhb);
                }
            }
            System.debug('remoteHourBlocks: ' + remoteHourBlocks);

        } else {
            System.debug('Error: The Smax Remote Hour Blocks LWC only works for Work Order and Install Product object types.');
            return null;
        }

        return remoteHourBlocks;
    }
}
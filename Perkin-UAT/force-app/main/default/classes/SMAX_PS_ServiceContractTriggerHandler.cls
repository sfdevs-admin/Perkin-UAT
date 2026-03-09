/*
 *  Trigger Handler for Service Contract [SVMXC__Service_Contract__c]
 *  2017-09-01      Veerendra Moodbidri         Initial creation, for Service Contract Integration.
 *  2017-10-11                                  Added call method "updateRenewedFromAndRenewedTo"
 *  2022-10-27      Bolt Data - Eugene Ross     Modifications for Polaris project.           
 */
public with sharing class SMAX_PS_ServiceContractTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public SMAX_PS_ServiceContractTriggerHandler() {
    }

    public void beforeInsert() {
        List<SVMXC__Service_Contract__c> newContractList = Trigger.new;

        SMAX_PS_ServiceContractManager.updateIsDeletedByCancelNotes(newContractList, null);
        SMAX_PS_ServiceContractManager.updateRenewedFromAndRenewedTo(newContractList, null);
        SMAX_PS_ServiceContractManager.copyRemoteHoursRemaining(newContractList);

        // ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
        SMAX_PS_ServiceContractManager.updateContractItemContractType(newContractList);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newContractList, null);
    }
    public void afterInsert() {}

    public void beforeUpdate() {
        List<SVMXC__Service_Contract__c> newContractList = Trigger.new;
        Map<Id, SVMXC__Service_Contract__c> oldContractMap = (Map<Id, SVMXC__Service_Contract__c>) Trigger.oldMap;
        SMAX_PS_ServiceContractManager.updateIsDeletedByCancelNotes(newContractList, oldContractMap);
        SMAX_PS_ServiceContractManager.updateRenewedFromAndRenewedTo(newContractList, oldContractMap);
        SMAX_PS_ServiceContractManager.copyRemoteHoursRemaining(newContractList);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newContractList, oldContractMap);
    }
    public void afterUpdate() {
        List<SVMXC__Service_Contract__c> newContractList = Trigger.new;
        Map<Id, SVMXC__Service_Contract__c> oldContractMap = (Map<Id, SVMXC__Service_Contract__c>) Trigger.oldMap;
        SMAX_PS_ServiceContractManager.updateIsDeleted(newContractList, oldContractMap);
    }

    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}
/*
 *  Trigger Handler for Inventory Count [SMAX_PS_InventoryCount__c]
 *  2017-09-07      Veerendra Moodbidri       Initial creation, for Product Stock Integration.
 *  2022-10-24      Bolt Data - E. Ross      MOdifications for Polaris Project.
 */

public with sharing class SMAX_PS_InventoryCountTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public SMAX_PS_InventoryCountTriggerHandler() {
    }

    public void beforeInsert() 
    {
        List<SMAX_PS_InventoryCount__c> invCountList = Trigger.new;

        copyInventoryCountTechs(invCountList);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(invCountList, null);
    }

    public void afterInsert() {}

    public void beforeUpdate()
    {
        List<SMAX_PS_InventoryCount__c> invCountList = Trigger.new;
        Map<Id, SMAX_PS_InventoryCount__c> oldInvCountMap = (Map<Id, SMAX_PS_InventoryCount__c>) Trigger.oldMap;

        validateStatusChanges(invCountList, oldInvCountMap);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(invCountList, oldInvCountMap);
    }

    public void afterUpdate()
    {
        List<SMAX_PS_InventoryCount__c> invCountList = Trigger.new;
        Map<Id, SMAX_PS_InventoryCount__c> oldInvCountMap = (Map<Id, SMAX_PS_InventoryCount__c>) Trigger.oldMap;

        createInventoryCountEvents(invCountList, oldInvCountMap);
    }

    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}

    public static void copyInventoryCountTechs(List<SMAX_PS_InventoryCount__c> invCountList)
    {
        if (!SMAX_PS_Utility.isActive('Copy Inventory Count Techs', 'Copy Inventory Count Technicians on Create.')) {
            return;
        }

        Set<Id> locIds = new Set<Id>();
        for (SMAX_PS_InventoryCount__c invCount : invCountList)
        {
            if (invCount.SMAX_PS_RequestedFrom__c != null) {
                locIds.add(invCount.SMAX_PS_RequestedFrom__c);
            }
        }

        if (locIds.isEmpty()) {
            return;
        }

        // ITSVMX-392 Don't assign Owner if NOT IsActive
        Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SVMXC__Service_Engineer__c,
                SVMXC__Service_Engineer__r.Id, SVMXC__Service_Engineer__r.IsActive
            FROM SVMXC__Site__c WHERE Id IN :locIds]);
        Set<Id> userIds = new Set<Id>();
        for (SMAX_PS_InventoryCount__c invCount : invCountList)
        {
            if (invCount.SMAX_PS_RequestedFrom__c != null)
            {
                SVMXC__Site__c loc = locMap.get(invCount.SMAX_PS_RequestedFrom__c);
                if (loc.SVMXC__Service_Engineer__c != null)
                {
                    User u = loc.SVMXC__Service_Engineer__r;
                    if (u != null && u.IsActive == true) {
                        invCount.SMAX_PS_Service_Engineer__c = u.Id;
                        // Also make the engineer the Owner
                        invCount.OwnerId = u.Id;
                        userIds.add(u.Id);
                    }
                }
            }
        }

        if (userIds.isEmpty()) {
            return;
        }

        Map<Id, SVMXC__Service_Group_Members__c> userTechMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c tech : [SELECT Id, Name, SVMXC__Salesforce_User__c,
                SVMXC__Salesforce_User__r.ManagerId, SVMXC__Salesforce_User__r.IsActive,
                SVMXC__Salesforce_User__r.Manager.Id, SVMXC__Salesforce_User__r.Manager.IsActive
            FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c IN :userIds])
        {
            userTechMap.put(tech.SVMXC__Salesforce_User__c, tech);
        }

        for (SMAX_PS_InventoryCount__c invCount : invCountList)
        {
            if (invCount.SMAX_PS_Service_Engineer__c != null)
            {
                SVMXC__Service_Group_Members__c tech = userTechMap.get(invCount.SMAX_PS_Service_Engineer__c);
                if (tech != null)
                {
                    invCount.SMAX_PS_RequestedTechnician__c = tech.Id;
                    if (tech.SVMXC__Salesforce_User__r != null) {
                        User mgr = tech.SVMXC__Salesforce_User__r.Manager;
                        if (mgr != null && mgr.IsActive == true) {
                            invCount.BD_Service_Manager__c = mgr.Id;
                        }
                    }
                }
            }
        }
    }

    public static void validateStatusChanges(List<SMAX_PS_InventoryCount__c> invCountList, Map<Id, SMAX_PS_InventoryCount__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('InventoryCount Status Changes', 'Validate changes to Inventory Count Status.')) {
            return;
        }

        for (SMAX_PS_InventoryCount__c invCount : invCountList)
        {
            SMAX_PS_InventoryCount__c old = (oldMap == null) ? null : oldMap.get(invCount.Id);
            if (old != null && invCount.SMAX_PS_Status__c != old.SMAX_PS_Status__c)
            {
                if (invCount.SMAX_PS_Status__c == 'Approved' && old.SMAX_PS_Status__c != 'Confirmed') {
                    invCount.addError('Inventory Count must be Confirmed before it can be Approved');
                }
            }
        }
    }

    public static void createInventoryCountEvents(List<SMAX_PS_InventoryCount__c> invCountList, Map<Id, SMAX_PS_InventoryCount__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('InventoryCount Events', 'Create Inventory Platform Events when Inventory Counts are Submitted.')) {
            return;
        }

        List<SMAX_PS_Inventory_Event__e> events = new List<SMAX_PS_Inventory_Event__e>();
        for (SMAX_PS_InventoryCount__c invCount : invCountList)
        {
            SMAX_PS_InventoryCount__c old = (oldMap == null) ? null : oldMap.get(invCount.Id);
            if (invCount.SMAX_PS_Status__c == 'Approved'
                    && old != null && invCount.SMAX_PS_Status__c != old.SMAX_PS_Status__c)
            {
                SMAX_PS_Inventory_Event__e iEvent = new SMAX_PS_Inventory_Event__e();
                iEvent.SMAX_PS_Action__c = 'COUNT';
                iEvent.SMAX_PS_CountDocumentId__c = invCount.Id;
                events.add(iEvent);
            }
        }

        SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_CountDocumentId__c', 'SMAX_PS_Action__c');
    }

}
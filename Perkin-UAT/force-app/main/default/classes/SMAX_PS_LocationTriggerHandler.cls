/**
 *  Trigger Handler for Location [SVMXC__Site__c]
 *  2017-07-03      Frank VanLoon       Initial creation, for Location Integration.
 *  2017-11-28      Frank VanLoon       Added Geography Lookup
 *  2018-03-20      Frank VanLoon       Added Storage Address Lookup [SVMXCFG-401]
 */
public with sharing class SMAX_PS_LocationTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
    public SMAX_PS_LocationTriggerHandler() {
    }

    public void beforeInsert()
    {
        List<SVMXC__Site__c> newList = Trigger.new;

        SMAX_PS_LocationManager.lookupLocationCustomers(newList, null);
        SMAX_PS_LocationManager.lookupLocationGeography(newList, null);
        SMAX_PS_LocationManager.lookupStorageAddress(newList, null);
        BD_Address_i18n.formatAddressTrigger(newList, null);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
    }

    public void afterInsert()
    {
        List<SVMXC__Site__c> newList = Trigger.new;
    }

    public void beforeUpdate()
    {
        List<SVMXC__Site__c> newList = Trigger.new;
        Map<Id, SVMXC__Site__c> oldMap = (Map<Id, SVMXC__Site__c>) Trigger.oldMap;

        SMAX_PS_LocationManager.lookupLocationCustomers(newList, oldMap);
        SMAX_PS_LocationManager.lookupLocationGeography(newList, oldMap);
        SMAX_PS_LocationManager.lookupStorageAddress(newList, oldMap);
        BD_Address_i18n.formatAddressTrigger(newList, oldMap);
        SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
    }

    public void afterUpdate()
    {
        List<SVMXC__Site__c> newList = Trigger.new;
        Map<Id, SVMXC__Site__c> oldMap = (Map<Id, SVMXC__Site__c>) Trigger.oldMap;

        // Added by Veerendra 2017-08-14
        SMAX_PS_LocationManager.updateIPAddressFieldsWhenLocAdrChanged(newList, oldMap);
    }

    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}

}
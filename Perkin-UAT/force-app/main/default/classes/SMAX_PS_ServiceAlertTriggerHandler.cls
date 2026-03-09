/**
 * Created by tony on 11/9/20.
 * Modified for Polaris project on 10/27/2022 by Bolt Data - Eugene Ross.
 */

public with sharing class SMAX_PS_ServiceAlertTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{

    public void beforeInsert()
    {
        List<SVMX_PS_Service_Alert__c> newList = Trigger.new;
        SMAX_PS_ServiceAlertManager.updateServiceAlerts(newList, null);
        SMAX_PS_ServiceAlertManager.updatePath(newList, null);
        SMAX_PS_OwnedByCompanyManager.updateServiceAlertObject(newList, null);
    }

    public void afterInsert()
    {
        List<SVMX_PS_Service_Alert__c> newList = Trigger.new;

        // ITSVMX-242 tony - Service Alert Notification Setup
        SMAX_PS_ServiceAlertManager.sendServiceAlertCreationNotifications(newList);
    }

    public void beforeUpdate()
    {
        List<SVMX_PS_Service_Alert__c> newList = Trigger.new;
        Map<Id, SVMX_PS_Service_Alert__c> oldMap = (Map<Id, SVMX_PS_Service_Alert__c>) Trigger.oldMap;
        SMAX_PS_ServiceAlertManager.updateServiceAlerts(newList, oldMap);
        SMAX_PS_ServiceAlertManager.updatePath(newList, oldMap);
        SMAX_PS_OwnedByCompanyManager.updateServiceAlertObject(newList, oldMap);
    }

    public void afterUpdate()
    {
        List<SVMX_PS_Service_Alert__c> newList = Trigger.new;
        Map<Id, SVMX_PS_Service_Alert__c> oldMap = (Map<Id, SVMX_PS_Service_Alert__c>) Trigger.oldMap;

        // ITSVMX-209 tony - Service Alerts Customer Care Email Notification
        SMAX_PS_ServiceAlertManager.sendServiceAlertNotifications(newList, oldMap);
        // ITSVMX-242 tony - Service Alert Notification Setup
        SMAX_PS_ServiceAlertManager.submitServiceAlertForApproval(newList, oldMap);
        
    }

    public void beforeDelete() {}

    public void afterDelete()
    {
        //List<SVMX_PS_Service_Alert__c> oldList = Trigger.old;
    }

    public void afterUndelete()
    {
        //List<SVMX_PS_Service_Alert__c> newList = Trigger.new;
    }
}
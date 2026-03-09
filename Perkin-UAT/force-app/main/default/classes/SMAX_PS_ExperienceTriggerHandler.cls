/**
 * Created by tony on 4/13/21.
 */

public with sharing class SMAX_PS_ExperienceTriggerHandler implements SMAX_PS_Utility.ITriggerHandler{

    public SMAX_PS_ExperienceTriggerHandler() {
    }

    public void beforeInsert() {
        List<BD_Experience__c> newList = Trigger.new;
        SMAX_PS_ExperienceManager.updateFinalScore(newList, null);
    }

    public void afterInsert() {}

    public void beforeUpdate() {
        List<BD_Experience__c> newList = Trigger.new;
        Map<Id, BD_Experience__c> oldMap = (Map<Id, BD_Experience__c>) Trigger.oldMap;
        SMAX_PS_ExperienceManager.updateFinalScore(newList, oldMap);
    }

    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}
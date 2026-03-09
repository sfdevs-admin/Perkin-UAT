public class BD_QuoteEventHandler {
    public static void createPlatformEventLog(List<BD_Quote_Event__e> quoteEvents) {
        List<SMAX_PS_Platform_Event_Log__c> logs = new List<SMAX_PS_Platform_Event_Log__c>();
        for(BD_Quote_Event__e event : quoteEvents) {
            SMAX_PS_Platform_Event_Log__c platformEventLog = new SMAX_PS_Platform_Event_Log__c();
            platformEventLog.SMAX_PS_Action__c = 'ACCEPTED';
            platformEventLog.SMAX_PS_Replay_Id__c = Decimal.valueOf(event.ReplayId);
            platformEventLog.SMAX_PS_Platform_Event_Type__c = 'SBQQ__Quote__c';
            platformEventLog.SMAX_PS_Related_Element_Id__c = event.BD_Quote_Id__c;
            platformEventLog.SMAX_PS_Event_JSON__c = JSON.serialize(event);
            logs.add(platformEventLog);            
        }
        
        insert logs;
    }
}
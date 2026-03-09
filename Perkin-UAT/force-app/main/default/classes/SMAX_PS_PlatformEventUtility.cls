public with sharing class SMAX_PS_PlatformEventUtility {
	private SMAX_PS_PlatformEventUtility() { }

	public static SMAX_PS_Platform_Event_Log__c createEventLog(SObject evt, String elementId, String action)
	{
		SMAX_PS_Platform_Event_Log__c log = new SMAX_PS_Platform_Event_Log__c();
		log.SMAX_PS_Related_Element_Id__c = elementId;
		log.SMAX_PS_Action__c = action;
		log.SMAX_PS_Platform_Event_Type__c = evt.getSObjectType().getDescribe().getName();
		log.SMAX_PS_Event_JSON__c = JSON.serialize(evt);
		log.SMAX_PS_Replay_Id__c =  Integer.valueOf((String)evt.get('ReplayId'));
		return log;
	}


	public static void publishEvents(List<SObject> events, String idField, String actionField)
	{
        System.debug( LoggingLevel.INFO, 'ENTERED publishEvents() - events=' + events );

        if (!events.isEmpty())
        {
            List<SMAX_PS_Platform_Event_Log__c> logs = new List<SMAX_PS_Platform_Event_Log__c>();
            Database.SaveResult[] results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++)
            {
                Database.SaveResult result = results[i];
                if (!result.isSuccess())
                {
                    SObject iEvent = events[i];
                    SMAX_PS_Platform_Event_Log__c log = new SMAX_PS_Platform_Event_Log__c();
                    log.SMAX_PS_Error_Message__c = 'Error publishing Event: ' + result.getErrors();
                    if (log.SMAX_PS_Error_Message__c.length() > 255)
                    	log.SMAX_PS_Error_Message__c = log.SMAX_PS_Error_Message__c.substring(0,250) + '...';
					log.SMAX_PS_Event_JSON__c = JSON.serialize(iEvent);
					log.SMAX_PS_Platform_Event_Type__c = iEvent.getSObjectType().getDescribe().getName();
					log.SMAX_PS_Related_Element_Id__c = (String)iEvent.get(idField);
					if (actionField != null)
						log.SMAX_PS_Action__c = (String)iEvent.get(actionField);
					logs.add(log);
                }
            }
            if (!logs.isEmpty())
                insert logs;
        }

        System.debug( LoggingLevel.INFO, 'EXITING publishEvents()...' );
    }

    public static String resendEvent(String evtName)
    {
        List<SMAX_PS_Platform_Event_Log__c> logs = [SELECT Id, Name, SMAX_PS_Platform_Event_Type__c, SMAX_PS_Event_JSON__c 
            FROM SMAX_PS_Platform_Event_Log__c WHERE Name = :evtName];
        return resendEvents(logs);
    }

    public static String resendEvents(List<SMAX_PS_Platform_Event_Log__c> logs)
    {
        List<SObject> events = new List<SObject>();
        for (SMAX_PS_Platform_Event_Log__c log : logs)
        {
            String eventType = log.SMAX_PS_Platform_Event_Type__c;
            String jsonStr = log.SMAX_PS_Event_JSON__c;
            System.debug('EVENT JSON: ' + jsonStr);
            Type t = Type.forName(eventType);
            // Schema.getGlobalDescribe().get(eventType)
            SObject deserialized = (SObject) JSON.deserialize(jsonStr, t);
            System.debug('DESERIALIZED EVENT: ' + deserialized);
            Map<String,Object> fieldMap = deserialized.getPopulatedFieldsAsMap();
            SObject iEvent = Schema.getGlobalDescribe().get(eventType).newSObject();
            for (String field : fieldMap.keySet())
            {
                if (field.endsWith('__c'))
                {
                    iEvent.put(field, fieldMap.get(field));
                }
            }
            System.debug('EVENT TO SEND: ' + iEvent);
            events.add(iEvent);
        }

        String retVal = '';
        if (!events.isEmpty())
        {
            Database.SaveResult[] results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++)
            {
                Database.SaveResult result = results[i];
                if (!result.isSuccess())
                {
                    SObject iEvent = events[i];
                    System.debug('Error publishing Event: ' + result.getErrors());
                    retVal += 'Error publishing Event: ' + result.getErrors() + '\n';
                }
            }
        }
        return retVal;
    }
}
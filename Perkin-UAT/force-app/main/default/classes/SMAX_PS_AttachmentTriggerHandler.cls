public with sharing class SMAX_PS_AttachmentTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
	public SMAX_PS_AttachmentTriggerHandler() {
	}

	public void beforeInsert() {}
	public void afterInsert()
	{
		List<Attachment> newList = Trigger.new;
		SMAX_PS_AttachmentTriggerHandler.sendAttachmentEvents(newList, null);

		// ITSVMX-186 5/18/22 tony - Remove as ServiceMax settings have been changed and Files are created automatically now
		// ITSVMX-186 3/3/21 tony - Convert WO Attachments to Files so they can be attached to emails
//		SMAX_PS_AttachmentManager.convertWOAttachmentsToFiles(newList, null);
	}
	public void beforeUpdate() {}
	public void afterUpdate()
	{
		List<Attachment> newList = Trigger.new;
		Map<Id, Attachment> oldMap = (Map<Id, Attachment>) Trigger.oldMap;
		SMAX_PS_AttachmentTriggerHandler.sendAttachmentEvents(newList, oldMap);

		// ITSVMX-186 5/18/22 tony - Remove as ServiceMax settings have been changed and Files are created automatically now
		// ITSVMX-186 3/3/21 tony - Convert WO Attachments to Files so they can be attached to emails
//		SMAX_PS_AttachmentManager.convertWOAttachmentsToFiles(newList, oldMap);
	}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

	public static void sendAttachmentEvents(List<Attachment> attachList, Map<Id, Attachment> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Send Attachment Events', 'Send WO Events for Attachments.'))
			return;

		if (SMAX_PS_Utility.isCurrentUserIntegrationProfile())
		{
			// If this is an "Integration" User, exit..
			System.debug('SKIPPING Attachment Events because Current User Profile is "Integration"');
			return;
		}

		String woPrefix = SVMXC__Service_Order__c.SObjectType.getDescribe().getKeyPrefix();
		List<Attachment> woAttachments = new List<Attachment>();
		Set<Id> woIds = new Set<Id>();
		for (Attachment attach : attachList)
		{
			String parentIdStr = '' + attach.ParentId;
			if (parentIdStr.startsWith(woPrefix))
			{
				woIds.add(attach.ParentId);
				woAttachments.add(attach);
			}
		}

		if (woIds.isEmpty())
			return;

		Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name, SMAX_PS_SAP_Notification_ID__c
		FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
		List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
		for (Attachment attach : woAttachments)
		{
			SVMXC__Service_Order__c wo = woMap.get(attach.ParentId);
			if (wo != null && String.isNotBlank(wo.SMAX_PS_SAP_Notification_ID__c))
			{
				SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
				iEvent.SMAX_PS_Action__c = 'ATTACHMENT';
				iEvent.SMAX_PS_WorkOrderId__c = attach.ParentId;
				iEvent.SMAX_PS_AttachmentId__c = attach.Id;
				events.add(iEvent);
			}
		}

		if (!events.isEmpty())
			SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
	}

}
/**
 *  This Web Service handles the "Debrief Response" from SAP for a One-Click Complete transaction.
 *  This class handles all of the logic for transitioning the Work Order from "Work Complete - Pending" to "Work Complete".
 *
 *  Frank VanLoon 		2018-05-11
 */
global class SMAX_PS_WorkOrderDebriefService 
{
	global class DebriefResponse 
	{
		webService String NotificationNumber { get; set; }
		webService String ServiceOrderNumber { get; set; }
		webService Boolean CreditHold { get; set; }
		webService String CreditHoldReason { get; set; }
		webService String SystemStatus { get; set; }
		webService String UserStatus { get; set; }
		webService String ErrorMessage { get; set; }
		webService String TransactionNumber { get; set; }

		webService List<DebriefLine> Lines { get; set; }
	}

	global class DebriefLine
	{
		webService String LineType { get; set; }
		webService String LineId { get; set; }
		webService String ConfirmationNumber { get; set; }
		webService string ErrorMessage { get; set; }
	}

	public SMAX_PS_WorkOrderDebriefService() {
	}

	webservice static String submitDebriefResponse(DebriefResponse debrief)
	{
		String soNum = debrief.ServiceOrderNumber;
		List<SVMXC__Service_Order__c> woList = [SELECT Id, Name, SVMXC__Order_Status__c, SMAX_PS_Completion_Errors__c,
			SMAX_PS_SAP_Notification_ID__c, SVMX_PS_External_ID__c, SMAX_PS_CreditHold__c, SMAX_PS_CreditHoldReason__c,
			SMAX_PS_SAP_SystemStatus__c, SMAX_PS_SAP_Order_Status__c, SMAX_PS_SAP_Activity_Status__c
			FROM SVMXC__Service_Order__c WHERE SVMX_PS_External_ID__c = :soNum];
		SVMXC__Service_Order__c wo = (woList != null && woList.size() == 1) ? woList.get(0) : null;

		System.debug('DEBRIEF-RESPONSE Loaded WO: ' + wo);

		return processDebriefResponse(wo, debrief);
	}

	public static String processDebriefResponse(SVMXC__Service_Order__c wo, DebriefResponse debrief)
	{
		// Set this flag so the One-Click Complete logic doens't run again at end
		SMAX_PS_WorkOrderDebriefManager.IS_PROCESSING_DEBRIEF_RESPONSE = true;

		List<SMAX_PS_IntegrationError__c> intErrors = new List<SMAX_PS_IntegrationError__c>();

		System.debug('DEBRIEF-RESPONSE Started: ' + debrief);
		String soNum = debrief.ServiceOrderNumber;

		if (wo == null)
		{
			String msg = 'Could NOT find Work Order with External ID: ' + soNum;
			intErrors.add(createIntegrationError(debrief, 'Submit Debrief Response Error: ' + msg));
		}
		else if (wo.SVMXC__Order_Status__c != SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_PENDING
			&& wo.SVMXC__Order_Status__c != SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR) // SVMXCFG-869
		{
			String msg = 'Cannot process Debrief Response. Work Order NOT "Work Complete - Pending". Order Status = "' + wo.SVMXC__Order_Status__c + '"';
			intErrors.add(createIntegrationError(debrief, msg));
		}
		else
		{
			wo.SMAX_PS_Completion_Errors__c = null;
			wo.SMAX_PS_CreditHold__c = debrief.CreditHold;
			if (debrief.CreditHoldReason != null)
				wo.SMAX_PS_CreditHoldReason__c = debrief.CreditHoldReason;
			wo.SMAX_PS_SAP_SystemStatus__c = debrief.SystemStatus;
			if (String.isNotBlank(debrief.UserStatus))
			{
				Integer firstSemi = debrief.UserStatus.indexOf(';');
				if (firstSemi > 0)
				{
					wo.SMAX_PS_SAP_Order_Status__c = debrief.UserStatus.substring(0, firstSemi);
					wo.SMAX_PS_SAP_Activity_Status__c = debrief.UserStatus.substring(firstSemi+1);
				}
				else
				{
					wo.SMAX_PS_SAP_Order_Status__c = debrief.UserStatus;
					wo.SMAX_PS_SAP_Activity_Status__c = null;
				}
			}
			if (String.isNotBlank(debrief.ErrorMessage))
			{
				if (!debrief.ErrorMessage.contains('status changed to TECO successfully'))
					intErrors.add(createIntegrationError(debrief, debrief.ErrorMessage));
			}

			Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
			// ITSFDC-1047 Also look for "Remote Support" Record Type
			Id remoteRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'SMAX_PS_Remote_Support').Id;

			// Select the Work Detail lines which qualify for updation
			Map<String, SVMXC__Service_Order_Line__c> lineMap = new Map<String, SVMXC__Service_Order_Line__c>();
			for(SVMXC__Service_Order_Line__c line : [SELECT Id, Name, 
				SVMXC__Line_Status__c, SVMXC__Line_Type__c, SVMXC__Service_Order__c,
				SMAX_PS_SAP_Confirmation__c
				FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id 
				AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId) AND SVMXC__Line_Status__c!='Canceled'])
			{
				lineMap.put(line.Name, line);
			}

			List<SVMXC__Service_Order_Line__c> linesToUpdate = new List<SVMXC__Service_Order_Line__c>();
			if (debrief.Lines != null)
			{
				for (DebriefLine dLine : debrief.Lines)
				{
					SVMXC__Service_Order_Line__c line = lineMap.get(dLine.LineId);
					if (line == null)
					{
						String msg = 'Could NOT find Work Detail with External ID: ' + dLine.LineId;
						intErrors.add(createIntegrationError(debrief, 'Submit Debrief Response Error: ' + msg));
					}
					else
					{
						String confNum = String.isNotBlank(dLine.ConfirmationNumber) ? dLine.ConfirmationNumber : null;
						if (confNum != null && (confNum == '0000000000' || confNum == '0000000000-00000000'))
							confNum = null;

						if (confNum != null)
						{
							line.SMAX_PS_SAP_Confirmation__c = confNum;
							linesToUpdate.add(line);
						}
						else if (String.isNotBlank(dLine.ErrorMessage))
						{
							String msg = dLine.ErrorMessage;
							intErrors.add(createIntegrationError(debrief, line, msg));
						}
						else if (line.SVMXC__Line_Type__c == 'Fault Code')
						{
							line.SVMXC__Line_Status__c = 'Confirmed';
							linesToUpdate.add(line);
						}
					}
				}
			}

			if (!linesToUpdate.isEmpty())
			{
				Database.SaveResult[] results = Database.update(linesToUpdate, false);
				for (Integer i = 0; i < results.size(); i++)
				{
					Database.SaveResult result = results[i];
					if (!result.isSuccess())
					{
						SVMXC__Service_Order_Line__c line = linesToUpdate[i];
						String msg = 'Debrief Response Error while Updating Work Detail: ' + result.getErrors();
						intErrors.add(createIntegrationError(debrief, line, msg));
					}
				}
			}

			// Lookup lines not "done" (Canceled or Confirmed).. 
			List<SVMXC__Service_Order_Line__c> linesNotDone = [SELECT Id, Name,
					SVMXC__Line_Status__c, SVMXC__Line_Type__c, SMAX_PS_IntegrationStatus__c, SVMXC__Service_Order__c
				FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :wo.Id
					AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId)
					AND SVMXC__Line_Status__c = 'Submitted'
					AND SMAX_PS_IntegrationStatus__c != 'Error'];
			
			if (!linesNotDone.isEmpty())
			{
				String msg = 'Debrief Response processed, but there are still ' + linesNotDone.size() + ' Debrief line(s) not Confirmed or Canceled.';
				intErrors.add(createIntegrationError(debrief, msg));

				// Added June4: If Debrief Response received, move any Submitted lines to Error.. assume error if not included in response
				List<SVMXC__Service_Order_Line__c> errorLines = new List<SVMXC__Service_Order_Line__c>();
				for (SVMXC__Service_Order_Line__c line : linesNotDone)
				{
					if (line.SVMXC__Line_Status__c == 'Submitted' && line.SMAX_PS_IntegrationStatus__c != 'Error')
					{
						line.SMAX_PS_IntegrationStatus__c = 'Error';
						errorLines.add(line);
					}
				}

				if (!errorLines.isEmpty())
					update errorLines;
			}

			// if ANY lines OR header Error from SAP, push to "Error", else go to "Work Complete"
			if (!intErrors.isEmpty())
			{
				wo.SVMXC__Order_Status__c = SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
				wo.SMAX_PS_Completion_Errors__c = 'Error Processing Debrief Response. One or more Integration Errors were received.  Please review and correct.';
			}
			else
			{
				wo.SVMXC__Order_Status__c = SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE;
			}

			//update wo;
			Database.SaveResult woResult = Database.update(wo, false);
			if (!woResult.isSuccess())
			{
				// Probably a problem with input status values, etc.. 
				String msg = 'Debrief Response Error while Updating Work Order: ' + woResult.getErrors();
				intErrors.add(createIntegrationError(debrief, msg));

				SVMXC__Service_Order__c errorWo = new SVMXC__Service_Order__c();
				errorWo.Id = wo.Id;
				errorWo.SVMXC__Order_Status__c = SMAX_PS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
				Database.update(errorWo, false);
			}
		}

		if (!intErrors.isEmpty())
			insert intErrors;

		String result = null;
		for (SMAX_PS_IntegrationError__c ie : intErrors)
		{
			result = (result == null) ? '' : result + ', ';
			result += ie.SMAX_PS_ErrorMessage__c;
		}
		return (result == null) ? 'Successfully processed Debrief Response' : result;
	}

	private static SMAX_PS_IntegrationError__c createIntegrationError(DebriefResponse debrief, String msg)
	{
		return new SMAX_PS_IntegrationError__c( SMAX_PS_ErrorMessage__c = msg, 
			SMAX_PS_TrackingNumber__c = debrief.TransactionNumber, 
			SMAX_PS_RelatedElementType__c = 'ServiceOrderNumber', 
			SMAX_PS_RelatedElementIdentifier__c = debrief.ServiceOrderNumber );
	}
	private static SMAX_PS_IntegrationError__c createIntegrationError(DebriefResponse debrief, SVMXC__Service_Order_Line__c line, String msg)
	{
		return new SMAX_PS_IntegrationError__c( SMAX_PS_ErrorMessage__c = msg, 
			SMAX_PS_TrackingNumber__c = debrief.TransactionNumber, 
			SMAX_PS_RelatedElementType__c = 'WorkDetailId', 
			SMAX_PS_RelatedElementIdentifier__c = line.Id );
	}

	//public static void handleDebriefResponseXML(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	//{
	//	// Process XML when SMAX_PS_Debrief_Response_XML__c changes...
	//	for (SVMXC__Service_Order__c wo : woList)
	//	{
	//		SVMXC__Service_Order__c old = oldMap.get(wo.Id);
	//		if (wo.SMAX_PS_Debrief_Response_XML__c != null && old != null && wo.SMAX_PS_Debrief_Response_XML__c != old.SMAX_PS_Debrief_Response_XML__c)
	//		{
	//			String debriefXml = wo.SMAX_PS_Debrief_Response_XML__c;
	//			DebriefResponse debriefRsp = parseDebriefXML(debriefXml);
	//			processDebriefResponse(wo, debriefRsp);
	//			// QUESTION.. should we clear out the XML field?
	//		}
	//	}
	//}

	//public static void handleDebriefResponseObject(List<SMAX_PS_Work_Order_Debrief_Response__c> rspList, Map<Id, SMAX_PS_Work_Order_Debrief_Response__c> oldMap)
	//{
	//	Map<Id, SMAX_PS_Work_Order_Debrief_Response__c> rspMap = new Map<Id, SMAX_PS_Work_Order_Debrief_Response__c>();
	//	for (SMAX_PS_Work_Order_Debrief_Response__c rsp : rspList)
	//	{
	//		SMAX_PS_Work_Order_Debrief_Response__c old = oldMap.get(rsp.Id);
	//		if (rsp.SMAX_PS_Status__c == 'Complete' && rsp.SMAX_PS_Status__c != old.SMAX_PS_Status__c)
	//		{
	//			rspMap.put(rsp.Id, rsp);
	//		}
	//	}

	//	if (rspMap.isEmpty())
	//		return;

	//	Map<Id, List<SMAX_PS_Work_Order_Debrief_Line__c>> lineMap = new Map<Id, List<SMAX_PS_Work_Order_Debrief_Line__c>>();
	//	List<SMAX_PS_Work_Order_Debrief_Line__c> allLines = [SELECT Id, Name, SMAX_PS_LineId__c, 
	//		SMAX_PS_ConfirmationNumber__c, SMAX_PS_ErrorMessage__c, SMAX_PS_Debrief_Response__c 
	//		FROM SMAX_PS_Work_Order_Debrief_Line__c WHERE SMAX_PS_Debrief_Response__c IN :rspMap.keySet()];
	//	for (SMAX_PS_Work_Order_Debrief_Line__c line : allLines)
	//	{
	//		if (!lineMap.containsKey(line.SMAX_PS_Debrief_Response__c))
	//			lineMap.put(line.SMAX_PS_Debrief_Response__c, new List<SMAX_PS_Work_Order_Debrief_Line__c>());
	//		lineMap.get(line.SMAX_PS_Debrief_Response__c).add(line);
	//	}

	//	for (Id rspId : rspMap.keySet())
	//	{
	//		SMAX_PS_Work_Order_Debrief_Response__c rsp = rspMap.get(rspId);
	//		List<SMAX_PS_Work_Order_Debrief_Line__c> lines = lineMap.get(rspId);

	//		// TODO: Map Custom Objects to WebService Objects..

	//		// TODO: Call handleDebriefResponse
	//	}
	//}

	/**
	 *  We could use this method to post XML into a long text field on the WO.. cheesy, but it'd work...
	 */
	//public static DebriefResponse parseDebriefXML(String xmlString)
	//{
	//	DebriefResponse result = null;
	//	XmlStreamReader reader = new XmlStreamReader(xmlString);
	//	boolean hasMore = true;
	//	while(hasMore) {
	//		// Start at the beginning of the book and make sure that it is a book
	//		if (reader.getEventType() == XmlTag.START_ELEMENT) {
	//			if ('DebriefResponse' == reader.getLocalName()) {
	//				result = new DebriefResponse();
	//				result.NotificationNumber = reader.getAttributeValue(null, 'NotificationNumber');
	//				result.ServiceOrderNumber = reader.getAttributeValue(null, 'ServiceOrderNumber');
	//				result.CreditHold = Boolean.valueOf(reader.getAttributeValue(null, 'CreditHold'));
	//				result.CreditHoldReason = reader.getAttributeValue(null, 'CreditHoldReason');
	//				result.SystemStatus = reader.getAttributeValue(null, 'SystemStatus');
	//				result.UserStatus = reader.getAttributeValue(null, 'UserStatus');
	//				result.ErrorMessage = reader.getAttributeValue(null, 'ErrorMessage');
	//				result.TransactionNumber = reader.getAttributeValue(null, 'TransactionNumber');
	//				result.Lines = new List<DebriefLine>();
	//			}
	//			if ('DebriefLine' == reader.getLocalName()) {
	//				DebriefLine dline = new DebriefLine();
	//				dline.LineId = reader.getAttributeValue(null, 'LineId');
	//				dline.ConfirmationNumber = reader.getAttributeValue(null, 'ConfirmationNumber');
	//				dline.ErrorMessage = reader.getAttributeValue(null, 'ErrorMessage');
	//				result.Lines.add(dline);
	//			}
	//		}
	//		// Always use hasNext() before calling next() to confirm that we have not reached the end of the stream
	//		if (reader.hasNext()) {
	//			reader.next();
	//		} else {
	//			hasMore = false;
	//			break;
	//		}
	//	}
	//	return result;
	//}
}
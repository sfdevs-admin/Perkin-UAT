/**
 *  This Apex Class contains all of the Work Order logic related to Complaints/HSI/FaultCodes.
 *  Author: Frank VanLoon
 *  Date: 2018-03-02
 */
public with sharing class SMAX_PS_WorkOrderComplaints {

	private static String WORK_COMPLETE = 'Work Complete';
	private static String HSI_YES = 'Yes';
	private static String HSI_NO = 'No';

	private SMAX_PS_WorkOrderComplaints() {
	}

	public static void healthSafetyCheck(List<SVMXC__Service_Order__c> woList)
	{
		if (!SMAX_PS_Utility.isActive('Work Order HSI', 'Move Work Order Status to Status of HSI when appropriate.'))
			return;

		// SVMXINT-484 : Skip HSI for Batch Jobs
		if (System.isBatch())
		{
			// If this is an "Batch" Job, exit.. 
			System.debug('SKIPPING HSI because these Work Orders are being created in a BATCH Transaction.');
			return;
		}

		// SVMXINT-484 : Skip HSI for WO Load (Integration Profile)
        Profile prof = SMAX_PS_Utility.getCurrentUserProfile();
		if (prof != null && prof.Name.containsIgnoreCase('Integration'))
		{
			// If this is an "Integration" User, exit.. 
			System.debug('SKIPPING HSI because Current User Profile is "Integration"');
			return;
		}

		RecordType estimateRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');

		List<SVMXC__Service_Order__c> woToCheck = new List<SVMXC__Service_Order__c>();
		Set<Id> ipIds = new Set<Id>(); 
		Set<Id> acctIds = new Set<Id>();

		for (SVMXC__Service_Order__c wo : woList)
		{
			// Are the 3 HSI Answers filled in?
			Boolean hsiNotDone = (wo.SMAX_PS_HSI1_Answer__c == null) || (wo.SMAX_PS_HSI2_Answer__c == null) || (wo.SMAX_PS_HSI3_Answer__c == null);
			if (hsiNotDone && wo.RecordTypeId != estimateRecType.Id && wo.SVMXC__Order_Status__c == 'Initializing' && wo.SVMXC__Component__c != null && wo.SMAX_PS_ShipTo__c != null)
			{
				woToCheck.add(wo);
				ipIds.add(wo.SVMXC__Component__c);
				acctIds.add(wo.SMAX_PS_ShipTo__c);
			}
		}
        
		if (woToCheck.isEmpty())
			return;
        
		Set<String> hsiKeys = new Set<String>();
		for (SMAX_PS_HSI_Settings__c hsi : SMAX_PS_HSI_Settings__c.getAll().values())
		{
			if (hsi.SMAX_PS_Active__c == TRUE)
				hsiKeys.add(hsi.SMAX_PS_Product_Line__c + '-' + hsi.SMAX_PS_Country_Code__c);
		}
		Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>([SELECT Id, Name, 
			SVMXC__Product__c, SVMXC__Product__r.product_line__c FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds]);
		Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, PKI_SAP_Country_Code__c 
			FROM Account WHERE Id IN :acctIds]);
		for (SVMXC__Service_Order__c wo : woToCheck)
		{
			SVMXC__Installed_Product__c ip = ipMap.get(wo.SVMXC__Component__c);
			Account acct = acctMap.get(wo.SMAX_PS_ShipTo__c);
			
			String productLine = (ip != null && ip.SVMXC__Product__c != null) ? ip.SVMXC__Product__r.product_line__c : null;
			String countryCode = (acct != null) ? acct.PKI_SAP_Country_Code__c : null;
			System.debug('~~ HSI: Product Line is ' + productLine + ' and Country Code is ' + countryCode);
			if (productLine != null && countryCode != null)
			{
				String hsiKey = productLine + '-' + countryCode;
				String hsiWildcardKey = productLine + '-*';
				System.debug('~~ HSI: Checking for key: ' + hsiKey);
				if (hsiKeys.contains(hsiKey) || hsiKeys.contains(hsiWildcardKey))
				{
					System.debug('~~ HSI: Found matching entry. Changing Order Status to HSI.');
					wo.SVMXC__Order_Status__c = 'HSI';
					wo.SMAX_PS_HSI_Required__c = TRUE;
				}
			}
		}
	}

	private static Set<String> COMPLAINT_PRIORITIES = new Set<String> { 'Complaint', 'X' };

	public static void updateManualComplaint(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Work Order Manual Complaint', 'Update the Manual Complaint field when Priority is set to Complaint.'))
			return;

		for (SVMXC__Service_Order__c wo : woList)
		{
			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.SVMXC__Priority__c != null && COMPLAINT_PRIORITIES.contains(wo.SVMXC__Priority__c))
			{
				wo.SMAX_PS_ManualComplaint__c = TRUE;
			}
		}
	}

	/*
		Use the Custom Setting: SMAX_PS_Complaint_Rules__c... 
		to conditionally apply the following business rules (based on Super Business Unit):
		1. If the Work Order Priority had a value of “Complaint”
		2. If any of the HSI Questions had answers of “Yes”
		3. If the Fault Code(s) selected on the Debrief are configured as “Complaint Required”
		4. If the IP is a Medical Device
		.. and update the "Complaint Required Details" fields.
		NOTE: MUST be called BEFORE validateComplaintAnswers(...)
	*/
	public static void updateComplaintDetails(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Work Order Complaint Details', 'Update the Complaint Required Details (and Check).'))
			return;

		Map<Id, List<SVMXC__Service_Order_Line__c>> faultCodeMap = new Map<Id, List<SVMXC__Service_Order_Line__c>>();
		for (SVMXC__Service_Order__c wo : woList)
		{
			faultCodeMap.put(wo.Id, new List<SVMXC__Service_Order_Line__c>());
		}

		List<SVMXC__Service_Order_Line__c> allFaultCodes = [SELECT Id, Name, SVMXC__Line_Type__c, SVMXC__Line_Status__c, SVMXC__Service_Order__c,
			SMAX_PS_Fault_Code__c, SMAX_PS_Fault_Code__r.SMAX_PS_Complaint_Required__c,
			SMAX_PS_Fault_Code_Group__c, SMAX_PS_Fault_Code_Group__r.SMAX_PS_Code_Group__c,
			SMAX_PS_ActionFaultCode__c, SMAX_PS_ActionFaultCode__r.SMAX_PS_Complaint_Required__c,
			SMAX_PS_InstallationFaultCode__c, SMAX_PS_InstallationFaultCode__r.SMAX_PS_Complaint_Required__c,
			SMAX_PS_CompletionFaultCode__c, SMAX_PS_CompletionFaultCode__r.SMAX_PS_Complaint_Required__c
			FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c IN :faultCodeMap.keySet() AND SVMXC__Line_Type__c = 'Fault Code'];
		for (SVMXC__Service_Order_Line__c faultCodeLine : allFaultCodes)
		{
			faultCodeMap.get(faultCodeLine.SVMXC__Service_Order__c).add(faultCodeLine);
		}

		for (SVMXC__Service_Order__c wo : woList)
		{
			// SVMXCFG-361 - Complaints: DAS vs DX Rules
			SMAX_PS_Complaint_Rules__c rules = getComplaintRules(wo);

			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.id);
			if (old != null)
			{
				List<String> conditionMsgs = new List<String>();
				if (rules.SMAX_PS_Condition_Manual_Complaint__c == TRUE && wo.SMAX_PS_ManualComplaint__c == TRUE)
				{
					conditionMsgs.add('The Work Order was marked as a Manual Complaint.');
				}

				if (rules.SMAX_PS_Condition_HSI_Yes__c == TRUE && anyHsiYes(wo))
				{
					conditionMsgs.add('One or more HSI Answer was "Yes".');
				}

				Boolean fcRequiresComplaint = FALSE;
				if (rules.SMAX_PS_Condition_Fault_Code_Com_Reqd__c == TRUE)
				{
					// Loop through Fault Codes, looking at Action, Completion and Installation Codes
					for (SVMXC__Service_Order_Line__c fcLine : faultCodeMap.get(wo.Id))
					{
						fcRequiresComplaint = fcRequiresComplaint 
							|| isComplaintRequired(fcLine.SMAX_PS_ActionFaultCode__r)
							|| isComplaintRequired(fcLine.SMAX_PS_InstallationFaultCode__r)
							|| isComplaintRequired(fcLine.SMAX_PS_CompletionFaultCode__r);
					}
				}

				if (rules.SMAX_PS_Condition_Restrict_PC_Com_Reqd__c == FALSE)
				{
					// Loop through Fault Codes, looking at Problem Codes
					for (SVMXC__Service_Order_Line__c fcLine : faultCodeMap.get(wo.Id))
					{
						fcRequiresComplaint = fcRequiresComplaint 
							|| isComplaintRequired(fcLine.SMAX_PS_Fault_Code__r);
					}
				}
				else
				{
					// ONLY look at the Problem Code if Indicator(s) are true AND Problem Group matches
					List<String> indicatorFields = rules.SMAX_PS_Condition_Restrict_PC_Indicators__c.split(',');
					Boolean indicators = FALSE;
					for (String indicatorField : indicatorFields)
					{
						Boolean indicatorValue = (Boolean)wo.get(indicatorField);
						indicators = indicators || indicatorValue;
					}

					if (indicators)
					{
						String probGroup = rules.SMAX_PS_Condition_Restrict_PC_Group__c;
						// Loop through Fault Codes, looking at Problem Codes
						for (SVMXC__Service_Order_Line__c fcLine : faultCodeMap.get(wo.Id))
						{
							if (fcLine.SMAX_PS_Fault_Code_Group__r != null &&
								fcLine.SMAX_PS_Fault_Code_Group__r.SMAX_PS_Code_Group__c == probGroup)
							{
								fcRequiresComplaint = fcRequiresComplaint 
									|| isComplaintRequired(fcLine.SMAX_PS_Fault_Code__r);
							}
						}
					}
				}

				if (fcRequiresComplaint)
				{
					conditionMsgs.add('One or more of the Fault Codes debriefed are marked as "Complaint Required".');
				}

				if (rules.SMAX_PS_Condition_Medical_Device__c == TRUE && wo.SMAX_PS_IsMedicalDevice__c == TRUE)
				{
					conditionMsgs.add('The Installed Product is a Medical Device.');
				}

				if (!conditionMsgs.isEmpty())
				{
					String details = 'The Complaint data must be captured because: ';
					for (String conditionMsg : conditionMsgs)
						details += '\n' + conditionMsg;
					wo.SMAX_PS_Complaint_Required_Details__c = details;
					wo.SMAX_PS_Complaint_Required_Details_Check__c = TRUE;
				}
				else
				{
					wo.SMAX_PS_Complaint_Required_Details__c = null;
					wo.SMAX_PS_Complaint_Required_Details_Check__c = FALSE;
				}
			}
		}
	}

	/*
		Use the Custom Setting: SMAX_PS_Complaint_Rules__c... 
		to conditionally apply the following business rules (based on Super Business Unit):
		If the "Complaint Required Details" are not blank, validate the following:
		1. All of the 3 HSI questions are Yes or No, if any are filled in.
		2. All of the 5 Regulatory questions are answered (sometimes tied to HSI)
		3. All of the 5 Additional Information fields are answered
		NOTE: MUST be called AFTER updateComplaintDetails(...)
	*/
	public static void validateComplaintAnswers(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Work Order Validate Complaints', 'Validate that the required Complaints data has been entered if necessary.'))
			return;

		for (SVMXC__Service_Order__c wo : woList)
		{
			// SVMXCFG-361 - Complaints: DAS vs DX Rules
			SMAX_PS_Complaint_Rules__c rules = getComplaintRules(wo);

			SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.id);
			if (old != null && old.SVMXC__Order_Status__c != wo.SVMXC__Order_Status__c && wo.SVMXC__Order_Status__c == WORK_COMPLETE)
			{
				List<String> errorMsgs = new List<String>();

				// SVMXCFG-841 HSI - Must Answer to Complete
				Boolean hsiStarted = (wo.SMAX_PS_HSI_Required__c == TRUE) || (wo.SMAX_PS_HSI1_Answer__c != null) || (wo.SMAX_PS_HSI2_Answer__c != null) || (wo.SMAX_PS_HSI3_Answer__c != null);
				Boolean hsiDone = isValidHsiAnswer(wo.SMAX_PS_HSI1_Answer__c) && isValidHsiAnswer(wo.SMAX_PS_HSI2_Answer__c) && isValidHsiAnswer(wo.SMAX_PS_HSI3_Answer__c);
				if (rules.SMAX_PS_Validation_HSI_Answered__c == TRUE && hsiStarted && (!hsiDone))
				{
					errorMsgs.add('The HSI Questions must be answered with a Yes or No value before Completing the Work Order.');
				}

				if (wo.SMAX_PS_Complaint_Required_Details__c != null)
				{
					Boolean anyRegulatoryBlank = (String.isBlank(wo.SMAX_PS_Q1_Response__c)
						|| String.isBlank(wo.SMAX_PS_Q2_Response__c)
						|| String.isBlank(wo.SMAX_PS_Q3_Response__c)
						|| String.isBlank(wo.SMAX_PS_Q4_Response__c)
						|| String.isBlank(wo.SMAX_PS_Q5_Response__c));
					Boolean anyHsiYes = anyHsiYes(wo);
					if ((rules.SMAX_PS_Validation_Regulatory_Answered__c == TRUE && anyRegulatoryBlank)
						|| (rules.SMAX_PS_Validation_Regulatory_When_HSI__c == TRUE && anyHsiYes && anyRegulatoryBlank))
					{
						errorMsgs.add('The Regulatory Questions must be answered before Completing the Work Order.');
					}

					Boolean anyGuidanceBlank = (String.isBlank(wo.SMAX_PS_Q1_Answer__c)
						|| String.isBlank(wo.SMAX_PS_Q2_Answer__c)
						|| String.isBlank(wo.SMAX_PS_Q3_Answer__c)
						|| String.isBlank(wo.SMAX_PS_Q4_Answer__c)
						|| String.isBlank(wo.SMAX_PS_Q5_Answer__c));
					if (rules.SMAX_PS_Validation_Guidance_Not_Blank__c == TRUE && anyGuidanceBlank)
					{
						errorMsgs.add('The Guidance Questions must be answered before Completing the Work Order.');
					}
				}

				if (!errorMsgs.isEmpty())
				{
					String errorMsg = '\nACTIONS NEEDED:\n' + errorMsgs;
					if (wo.SMAX_PS_Complaint_Required_Details__c != null)
					{
						errorMsg = errorMsg + '\nNOTE: ' + wo.SMAX_PS_Complaint_Required_Details__c;
					}
					// SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
					//wo.addError(errorMsg);
					wo.SMAX_PS_Completion_Errors__c = errorMsg;
					wo.SVMXC__Order_Status__c = 'Work Complete - Error';
				}
				else
				{
					wo.SMAX_PS_Completion_Errors__c = null;
				}
			}
		}
	}

	private static SMAX_PS_Complaint_Rules__c getComplaintRules(SVMXC__Service_Order__c wo)
	{
		String superBU = wo.SMAX_PS_Super_Business_Unit__c;
		if (superBU == null)
		{
			superBU = 'ZZZ';
			System.debug('COMPLAINTS: No Super Business Unit Found.. Using Default: ' + superBU);
		}

		SMAX_PS_Complaint_Rules__c rules = SMAX_PS_Complaint_Rules__c.getInstance(superBU);
		if (rules == null)
		{
			rules = new SMAX_PS_Complaint_Rules__c();
			// Default Conditions..
			rules.SMAX_PS_Condition_HSI_Yes__c = TRUE;
			rules.SMAX_PS_Condition_Manual_Complaint__c = TRUE;
			rules.SMAX_PS_Condition_Fault_Code_Com_Reqd__c = TRUE;
			rules.SMAX_PS_Condition_Restrict_PC_Com_Reqd__c = FALSE;
			rules.SMAX_PS_Condition_Medical_Device__c = FALSE;
			// Default Validations..
			rules.SMAX_PS_Validation_HSI_Answered__c = TRUE;
			rules.SMAX_PS_Validation_Regulatory_Answered__c = TRUE;
			rules.SMAX_PS_Validation_Guidance_Not_Blank__c = TRUE;
			rules.SMAX_PS_Validation_Regulatory_When_HSI__c = FALSE;
			System.debug('COMPLAINTS: No Complaint Rules Found for: ' + superBU + '.. Using Default: ' + rules);
		}
		return rules;
	}

	private static Boolean isComplaintRequired(SMAX_PS_Fault_Code__c fc)
	{
		if (fc != null && fc.SMAX_PS_Complaint_Required__c != null)
		{
			return fc.SMAX_PS_Complaint_Required__c > 0;
		}
		return false;
	}

	private static Boolean anyHsiYes(SVMXC__Service_Order__c wo)
	{
		return (wo.SMAX_PS_HSI1_Answer__c == HSI_YES || wo.SMAX_PS_HSI2_Answer__c == HSI_YES || wo.SMAX_PS_HSI3_Answer__c == HSI_YES);
	}

	private static Boolean isValidHsiAnswer(String val)
	{
		return (val != null && (val == HSI_YES || val == HSI_NO));
	}
}
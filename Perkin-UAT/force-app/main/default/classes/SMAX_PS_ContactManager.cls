/**
 *  Apex Class for Contact [Contact] Business Logic.
 *  2017-07-14      Frank VanLoon       Initial creation, for Contact Outbound Integration.
 *  2017-11-02      Frank VanLoon       Removed references to Partner Site
 */
public with sharing class SMAX_PS_ContactManager {
	private SMAX_PS_ContactManager() {
	}

	/*
		Used for Outbound Contact Integration to SAP.
		Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
		Syncs the PKI_SAP_Customer_Number__c field to the Account.
	 */
	public static void updateSAPFields(List<Contact> contacts, Map<Id, Contact> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update SAP Fields', 'Syncs the PKI_SAP_Customer_Number__c field from the Account.'))
			return;

		Set<Id> acctIds = new Set<Id>();
		for (Contact c : contacts)
		{
			if (c.AccountId != null && String.isBlank(c.PKI_SAP_Customer_Number__c))
				acctIds.add(c.AccountId);
		}

		if (acctIds.isEmpty())
			return;

		Map<Id, Account> acctMap = (acctIds.isEmpty()) ? new Map<Id, Account>() : 
			new Map<Id, Account>([SELECT Id, Name, PKI_SAP_Customer_Number__c FROM Account WHERE Id IN :acctIds]);
		for (Contact c : contacts)
		{
			if (c.AccountId != null && acctMap.containsKey(c.AccountId))
			{
				Account acct = acctMap.get(c.AccountId);
				c.PKI_SAP_Customer_Number__c = acct.PKI_SAP_Customer_Number__c;
			}
		}
	}

	public static void updateContactAccount(List<Contact> contacts, Map<Id, Contact> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Update Contact Account', 'Updates AccountId field in Contact.'))
			return;

		List<Contact> contactsToUpdate = new List<Contact>();
		Set<String> contactIds = new Set<String>();
		for(Contact c: contacts) 
		{
			Contact old = (oldMap == null) ? null : oldMap.get(c.Id);
			Boolean sapNumChanged = (old != null && c.PKI_SAP_Customer_Number__c != old.PKI_SAP_Customer_Number__c);
			if (c.PKI_SAP_Customer_Number__c != null && (c.AccountId == null || sapNumChanged) )
			{
				contactIds.add(c.PKI_SAP_Customer_Number__c);
				contactsToUpdate.add(c);
			}
		}

		if (contactsToUpdate.isEmpty())
			return;

		Map<String, Account> parentAccountMap = new Map<String, Account>();
		for(Account parentAcct : [SELECT Id, PKI_SAP_Customer_Number__c FROM Account 
			WHERE PKI_SAP_Customer_Number__c IN :contactIds])
		{
			parentAccountMap.put(parentAcct.PKI_SAP_Customer_Number__c, parentAcct);
		}

		for(Contact c : contactsToUpdate)
		{
			String acctId = c.PKI_SAP_Customer_Number__c;
			Account parentAcct = (parentAccountMap.containsKey(acctId)) ? parentAccountMap.get(acctId) : null;
			if (parentAcct != null)
			{
				c.AccountId = parentAcct.Id;
			}
		}
	}

	/*
		Used for Outbound Contact Integration to SAP.
		Should be called from the AFTER-INSERT and AFTER-UPDATE Triggers.
		Create Contact Platform Events when Contacts are Created or Updated, and related to an SAP Customer Account.
	 */
	public static void createContactEvents(List<Contact> contacts, Map<Id, Contact> oldMap)
	{
		System.debug( LoggingLevel.INFO, 'ENTERED createContactEvents()...' );

		if (!SMAX_PS_Utility.isActive('Create Contact Events', 'Create Contact Platform Events when Contacts are Created or Updated, and related to an SAP Customer Account.'))
			return;

		Id profileID = UserInfo.getProfileId();
		Profile p = [SELECT Id, Name, Description FROM Profile WHERE Id = :profileID];
		if (p != null && p.Name != null && p.Name.containsIgnoreCase('Integration'))
		{
			// If this is an "Integration" User, exit.. 
			System.debug('SKIPPING Contact Events because Current User Profile is "Integration"');
			return;
		}

		SMAX_PS_Contact_Integration__c settings = SMAX_PS_Contact_Integration__c.getInstance();
		if (settings == null || Test.isRunningTest())
		{
			settings = new SMAX_PS_Contact_Integration__c();
			settings.SMAS_PS_Create_Contacts_on_Update__c = FALSE;
			settings.SMAX_PS_Send_Contact_Create_Events__c = TRUE;
			settings.SMAX_PS_Send_Contact_Update_Events__c = TRUE;
			System.debug('DEFAULTED Contact Integration Settings: ' + settings);
		}

		// SVMXINT-467 - Do not send events when modified by User X,Y,Z
		String username = UserInfo.getUserName().toLowerCase();
		String ignoreVal = settings.SMAX_PS_Ignore_Users__c;
		List<String> ignoreTokens = (String.isBlank(ignoreVal)) ? new List<String>() : ignoreVal.toLowerCase().split(',');
		for (String ignoreToken : ignoreTokens)
		{
			if (username.contains(ignoreToken))
			{
				System.debug('SKIPPING Contact Events because Current Username: "' + username + '"" contains "' + ignoreToken + '"');
				return;
			}
		}

		Set<Id> accountIds = new Set<Id>();
		Boolean isDelete = Trigger.isDelete;
		for (Contact c : contacts)
		{
			accountIds.add(c.AccountId);
		}
		Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name, BillingCountry FROM Account WHERE Id IN :accountIds]);

		List<SMAX_PS_Contact_Event__e> contactEvents = new List<SMAX_PS_Contact_Event__e>();
		for (Contact c : contacts)
		{
			Contact old = (oldMap == null) ? null : oldMap.get(c.Id);
			if (c.PKI_SAP_Customer_Number__c != null)
			{
				// SVMXINT-466 - Do not "CREATE" updated Contacts
				if (settings.SMAS_PS_Create_Contacts_on_Update__c == FALSE
					&& String.isBlank(c.PKI_SAP_Contact_ID__c)
					&& old != null)
				{
					System.debug('SKIPPING Contact Event because SAP Contact ID is blank.');
					continue;
				}

				if (settings.SMAX_PS_Send_Contact_Create_Events__c == FALSE && old == null)
				{
					System.debug('SKIPPING Contact Event because "Send Contact Create Events" is disabled.');
					continue;
				}

				if (settings.SMAX_PS_Send_Contact_Update_Events__c == FALSE && old != null)
				{
					System.debug('SKIPPING Contact Event because "Send Contact Update Events" is disabled.');
					continue;
				}

				if (old == null || contactUpdated(c, old))
				{
					SMAX_PS_Contact_Event__e cEvent = new SMAX_PS_Contact_Event__e();
					cEvent.SMAX_PS_SFDC_Contact_Id__c = c.Id;
					cEvent.SMAX_PS_SAP_Customer_Number__c = c.PKI_SAP_Customer_Number__c;
					cEvent.SMAX_PS_SAP_Contact_ID__c = c.PKI_SAP_Contact_ID__c;
					cEvent.SMAX_PS_Title__c = c.Title; //c.PKI_SAP_Contact_Title__c;
					cEvent.SMAX_PS_First_Name__c = c.FirstName;
					cEvent.SMAX_PS_Last_Name__c = c.LastName;
					cEvent.SMAX_PS_Email__c = c.Email;
					cEvent.SMAX_PS_Phone__c = c.Phone;
					cEvent.SMAX_PS_Fax__c = c.Fax;
					cEvent.SMAX_PS_MobilePhone__c = c.MobilePhone;
					cEvent.SMAX_PS_Language__c = c.PKI_SAP_Language__c;
					cEvent.SMAX_PS_Type__c = c.Type__c;
					cEvent.SMAX_PS_Salutation__c = c.Salutation;
					cEvent.SMAX_PS_Function__c = c.Function__c;
					// ITSFDC-1389: Adding Suffix to event
					cEvent.SMAX_PS_Suffix__c = c.Suffix__c;

					cEvent.SMAX_PS_Is_Active__c = c.SVMX_PS_Active__c;
					cEvent.SMAX_PS_Is_Deleted__c = isDelete;

					Account acct = accountMap.get(c.AccountId);
					cEvent.SMAX_PS_Country__c = (acct == null) ? null : acct.BillingCountry;
					
					contactEvents.add(cEvent);
				}
			}
		}

		SMAX_PS_PlatformEventUtility.publishEvents(contactEvents, 'SMAX_PS_SAP_Contact_ID__c', null);

		System.debug( LoggingLevel.INFO, 'EXITING createContactEvents()...' );
	}

	public static Boolean contactUpdated(Contact c, Contact old)
	{
		return (old != null && 
			(c.Title != old.Title || c.FirstName != old.FirstName || c.LastName != old.LastName || c.Salutation != old.Salutation
			|| c.Email != old.Email || c.Phone != old.Phone || c.Fax != old.Fax || c.MobilePhone != old.MobilePhone
			|| c.PKI_SAP_Language__c != old.PKI_SAP_Language__c || c.Type__c != old.Type__c || c.Function__c != old.Function__c
			|| c.Suffix__c != old.Suffix__c));
	}

	/*
		SVMXINT-613 Used for Outbound Contact Integration to SAP... truncate fields to ensure SAP is successful.
		Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
	 */
	public static void truncateFields(List<Contact> contacts, Map<Id, Contact> oldMap)
	{
		if (!SMAX_PS_Utility.isActive('Contact Truncate Fields', 'Truncates fields on Contacts that will be sent to SAP.'))
			return;

		for (Contact c : contacts)
		{
			if (c.PKI_SAP_Customer_Number__c != null)
			{
				if (c.Title != null && c.Title.length() > 40)
				{
					c.Title = c.Title.left(40);
				}
				if (c.LastName != null && c.LastName.length() > 40)
				{
					c.LastName = c.LastName.left(40);
				}
			}
		}
	}

	// TODO: ITSVMX-230 Create an InvocableMethod as seen here:
	// https://help.salesforce.com/articleView?id=release-notes.rn_apex_flow_flag_invocable_methods_callouts.htm&release=230&type=5

	public class ContactCreateRQ {
		@InvocableVariable(Required=true) public String CustomerNumber;
		@InvocableVariable(Required=true) public String FirstName;
		@InvocableVariable(Required=true) public String LastName;
		@InvocableVariable(Required=true) public String Email;
		@InvocableVariable(Required=false) public String Title;
		@InvocableVariable(Required=false) public String Suffix;
		@InvocableVariable(Required=false) public String Salutation;
		@InvocableVariable(Required=false) public String Phone;
		@InvocableVariable(Required=false) public String Fax;
		@InvocableVariable(Required=false) public String Mobile;
	}
	public class ContactCreateRS {
		@InvocableVariable public String ContactNumber;
		@InvocableVariable public String Error;
	}

	@InvocableMethod(Label='Create Contact Integration') // Callout=true,
	public static List<ContactCreateRS> callContactCreate(List<ContactCreateRQ> requests) {

		SVMXC.COMM_Utils_ManageSettings settings = new SVMXC.COMM_Utils_ManageSettings();
		Map<String, String> mySettings = settings.SVMX_getSettingList('WORD009', 'GET_PRICE_URL');
		System.debug('~ WORD009 Settings: ' + mySettings);
		String getPriceURL = mySettings.get('GET_PRICE_URL');
		String boomi_auth = (getPriceURL == null) ? '' : getPriceURL.substring(getPriceURL.indexOf('boomi_auth'));

		//String serviceURL = 'callout:PKI_BOOMI_ServiceMax/Query/CreateContact;boomi_auth=c2Vydml...YmZk';
		String serviceURL = 'callout:PKI_BOOMI_ServiceMax/Query/CreateContact;' + boomi_auth;
		List<ContactCreateRS> results = new List<ContactCreateRS>();
		for (ContactCreateRQ rq: requests) {

			//String jsRQ = '{ "CustomerNumber": "0100642891", "FirstName": "Frank", "LastName": "TestTwo", "Email": "frank.testtwo@merck.com" }';
			String jsRQ = JSON.serialize(rq, true);
			System.debug('Sending Contact Create RQ: ' + jsRQ);

			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setBody(jsRQ);
			req.setHeader('Content-Type', 'application/json; charset=UTF-8');
			req.setHeader('Accept', 'application/json');
			req.setTimeout(60000);

			req.setEndpoint(serviceURL);
			Http http = new Http();
			HttpResponse res = http.send(req);
			String jsRS = res.getBody();
			System.debug('CONTACT CREATE RESPONSE JSON: ' + jsRS);
			if (res.getStatusCode() != 200) {
				ContactCreateRS result = new ContactCreateRS();
				result.Error = res.getStatusCode() + ': ' + res.getStatus();
				results.add(result);
				System.debug('Received HTTP Error Code: ' + result.Error);
			} else {
				ContactCreateRS result = (ContactCreateRS) JSON.deserialize(jsRS, ContactCreateRS.class);
				results.add(result);
			}
		}
		return results;
	}

}
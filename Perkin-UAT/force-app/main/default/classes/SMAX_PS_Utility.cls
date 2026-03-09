/**
 *  Apex Class containing misc Utility methods.
 *  2017-07-03		Frank VanLoon		Initial creation.
 *  2022-12-23		Tony Herrington		Added check for Triggers.areDisabled to the isActive() method
 */
global class SMAX_PS_Utility {
	private SMAX_PS_Utility() { }

	/**
		The following methods cache the RecordType lookups, by DeveloperName (i18n safe)
	*/

	/**
	 * RecordType caching by DeveloperName.. needed for i18n Record Types.
	 */
	private static Map<String, Map<String, RecordType>> rtMap  = new Map<String, Map<String, RecordType>>();
	
	//Gets a record type by a given developer name and the object it is associated
	//with, the dev name and object are assumed to be unique
	public static RecordType getRecordType(String objectTypeName, String recordTypeDevName){
		return getRecTypeDevNameMap(objectTypeName).get(recordTypeDevName);
	}
	
	public static Map<String, RecordType> getRecTypeDevNameMap(String sObjectType)
	{
		if (! rtMap.containsKey(sObjectType))
		{
			rtMap.put(sObjectType, new Map<String, RecordType>());
			
			for (RecordType rt : [SELECT Id, Name, DeveloperName, SOBjectType 
				FROM RecordType WHERE SOBjectType = :sObjectType])
			{
				rtMap.get(sObjectType).put(rt.DeveloperName, rt);
			}
		}
		
		return rtMap.get(sObjectType);
	}


	/**
		The following methods retrieve User and Profile data
	*/
	private static Map<Id, Profile> profileMap = new Map<Id, Profile>();

	public static Profile getCurrentUserProfile()
	{
		Id profileId = UserInfo.getProfileId();
		if (profileMap.containsKey(profileId))
			return profileMap.get(profileId);

		Profile result = [Select Id, Name, UserType from Profile where Id = :profileId];
		profileMap.put(profileId, result);
		return result;
	}

	public static Boolean isCurrentUserIntegrationProfile()
	{
		Profile p = SMAX_PS_Utility.getCurrentUserProfile();
		return (p != null && p.Name != null && p.Name.containsIgnoreCase('Integration'));
	}

	/**
		The following methods assist in creating dynamic SOQL to load full SObjects.
		(Very useful if cloning an SObject or debugging)
	*/
	private static Map<String, Map<String, Schema.SObjectField>> fieldMap = new Map<String, Map<String, Schema.SobjectField>>();
	
	public static List<SObject> loadFullObjects(String objectName, String whereClause, Set<Id> idSet)
	{
		String query = 'SELECT ';
		Date todayDate = system.today();
		Map<String, Schema.SObjectField> objectFields = getFields(objectName);

		// Grab the fields from the describe method and append them to the queryString one by one.
		Integer count = 0;
		for(String s : objectFields.keySet()) {
			if (count++ > 0)
			{
				query += ' ,';
			}
		   query += s;
		}

		// Add FROM statement
		query += ' FROM ' + objectName;

		if (idSet != null)
		{
			String listOfIds = null;
			for (Id idVal : idSet)
			{
				if (listOfIds == null)
					listOfIds = '';
				else
					listOfIds += ', ';
				listOfIds += '\'' + idVal + '\'';
			}
			if (listOfIds != null)
			{
				if (String.isBlank(whereClause))
					whereClause = ' WHERE Id IN (' + listOfIds + ')';
				else
					whereClause += ' (' + listOfIds + ')'; // Assume it ends with " IN "
			}
		}

		// Add on a WHERE/ORDER/LIMIT statement as needed
		if (String.isNotBlank(whereClause))
			query += ' ' + whereClause;
  
		return database.query(query);
	}
	
	public static Map<String, Schema.SObjectField> getFields(String objectname)
	{
		if (! fieldMap.containsKey(objectName))
		{
			fieldMap.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
		}
		
		return fieldMap.get(objectName);
	}

	/**
		DEBUGGING method --> Print out all of the values that have changed.  Call from last entry of "after update".
	 */
	public static void logDeltas(List<SObject> newList, Map<Id, SObject> oldMap)
	{
		SObject sample = newList[0];
		String objType = sample.getSObjectType().getDescribe().getName();
		Map<String, Schema.SObjectField> fields = getFields(objType);
		for (SObject sobj : newList)
		{
			System.debug('FINDING DELTAS FOR: ' + objType + ' (' + sobj.Id + ')');
			SObject old = oldMap.get(sobj.Id);
			for (String fieldName : fields.keySet())
			{
				Object newValue = sobj.get(fieldName);
				Object oldValue = old.get(fieldName);
				if (newValue != oldValue)
				{
					System.debug('DELTA FOUND: ' + fieldName + ', OLD=' + oldValue + ', NEW=' + newValue);
				}
			}
		}
	}

	/**
		The following methods can be used to ensure sections of code are only executed once per transaction.
	*/

	private static Set<String> runSet = new Set<String>();

	/*
	 *  Use this method sparingly.. it will reset all run-once variables and allow all functionality to run again.
	 */
	public static void clearCache()
	{
		runSet.clear();
	}

	/*
	 *  Use this method only inside Unit Tests, to allow functionality to run again.
	 */
	public static void reset(String name){
		if (runSet.contains(name))
			runSet.remove(name);
	}

	/*
	 *  Use this method to limit execution of trigger code to once per transaction.
		// Typical Usage:
		if (!SMAX_PS_Utility.isFirstrun('WorkOrder_OnCloseUpdates'))
			return;
	 */
	public static boolean isFirstRun(String name)
	{
		//System.debug('In RunOnce: ' + name + ' -- SOQL: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
		Boolean hasRun = runSet.contains(name);
		if(hasRun){
			return false;
		}
		else{
			runSet.add(name);
			return true;
		}
	}

	/**
		The following interface and method can be used to simplify Trigger Handler code.
	*/

	public interface ITriggerHandler {
		void beforeInsert();
		void afterInsert();
		void beforeUpdate();
		void afterUpdate();
		void beforeDelete();
		void afterDelete();
		void afterUndelete();
	}

	/*
	 *  This method houses the controller logic and invokes appropriate handler class methods.
		// Typical Usage:
		SMAX_PS_Utility.executeHandler(new SMAX_PS_Location_TriggerHandler());
	 */
	public static void executeHandler(ITriggerHandler handler) {

		// 2024.11.12 - ives - Check if custom permission is present on user and skip automation if found
		if( FeatureManagement.checkPermission( 'BD_Bypass_Automation' ) ) {
			System.debug( LoggingLevel.WARN, 'Bypassing triggers, custom permission BD_Bypass_Automation on user ' + User.Name );
			return;
		}

		if(Trigger.isBefore && Trigger.isInsert)
		{
			handler.beforeInsert();
		}
		else if (Trigger.isAfter && Trigger.isInsert)
		{ 
			handler.afterInsert();
		}
		else if (Trigger.isBefore && Trigger.isUpdate)
		{
			handler.beforeUpdate();
		}
		else if (Trigger.isAfter && Trigger.isUpdate)
		{
			handler.afterUpdate();
		}
		else if (Trigger.isBefore && Trigger.isDelete)
		{
			handler.beforeDelete();
		}
		else if (Trigger.isAfter && Trigger.isDelete)
		{
			handler.afterDelete();
		}
		else if (Trigger.isAfter && Trigger.isUndelete)
		{
			handler.afterUndelete();
		}
	}

	/**
		The following methods help with Testing PlatformEvents
	*/
	private static Map<String, List<SObject>> TEST_EVENT_CACHE = new Map<String, List<SObject>>();
	public static void saveTestEvents(String eventName, List<SObject> events)
	{
		if (!TEST_EVENT_CACHE.containsKey(eventName))
			TEST_EVENT_CACHE.put(eventName, new List<SObject>());
		TEST_EVENT_CACHE.get(eventName).addAll(events);
	}
	public static List<SObject> retrieveTestEvents(String eventName)
	{
		return TEST_EVENT_CACHE.get(eventName);
	}

	/**
		The following methods check / add to the SVMX_PS_Services_Register__c Custom Setting
	*/

	// Used to disable methods that use the SMAX_PS_Utility.isActive() method
	public static Boolean triggersDisabled = false;

	/*
		Added this overloaded method for compatibility.
		DEPRECATED.. please use the method with 2 parameters instead.
	 */
	public static boolean isActive(String serviceName)
	{
		return isActive(serviceName, 'Please enter a valid description for: ' + serviceName);
	}

	// ADDED to support batch jobs that want to ONLY run 1 Service Register function. (Or 0 if set to a 'N/A' value)
	public static String SVC_REGISTER_SINGLETON = null;

	/*
		All extensions will check if the service is active before running it:
		serviceName: The name of the service. Each extension should have a unique name.
		serviceDescription: The high level overview of the service.
	*/   
	public static boolean isActive(String serviceName, String serviceDescription)
	{
		if (SVC_REGISTER_SINGLETON != null) {
			return serviceName.equalsIgnoreCase(SVC_REGISTER_SINGLETON);
		}

		// Retrieve the extension from the custom settings.
		SVMX_PS_Services_Register__c registeredService = SVMX_PS_Services_Register__c.getInstance(serviceName);
		
		if (registeredService == null)
		{
			registeredService = registerService(serviceName, serviceDescription); 
			
			//error has already been logged in register service if null is being returned.
			if (registeredService == null)
				return false;           
		}
		
		// When the Service Register is called during Test Execution, it should always return true unless Triggers.areDisabled = true
		if (Test.isRunningTest() && !SMAX_PS_Utility.triggersDisabled) {
			System.debug('SMAX_PS_Utility.triggersDisabled = ' + SMAX_PS_Utility.triggersDisabled);
			return true;
		} else if (Test.isRunningTest() && SMAX_PS_Utility.triggersDisabled) {
			System.debug('SMAX_PS_Utility.triggersDisabled = ' + SMAX_PS_Utility.triggersDisabled);
			return false;
		}

		return registeredService.SVMX_PS_Is_Active__c;
	}
	   
	private static SVMX_PS_Services_Register__c registerService(String serviceName, String serviceDescription)
	{
		try
		{
			SVMX_PS_Services_Register__c newRegisteredExtension = new  SVMX_PS_Services_Register__c(Name=serviceName, SVMX_PS_Description__c=serviceDescription, SVMX_PS_Is_Active__c = true); 
		
			insert newRegisteredExtension;
		
			return newRegisteredExtension;
		}
		catch (Exception insertException)
		{
			System.debug('Service, ' + serviceName + ', could not registered because of the following exception: ' + insertException.getMessage());
		}
		return null;
	}

	/**
		The following methods are misc. helper functions
	*/

	public static string getDateInSOQLFormat(Date d)
	{
		if (d != null)
		{
			String day = String.valueOf(d.day());
			String month = String.valueOF(d.month());
			String year = String.valueOf(d.year());
		
			return year+'-'+month+'-'+day;
		}
		return '';
	}

	public static Boolean doDatesOverlap(Date s1, Date e1, Date s2, Date e2)
	{
		if (s1 == null || e1 == null || s2 == null || e2 == null)
			return FALSE; // Really invalid.. but we'll let it through

		return ((s1 <= e1 && s2 <= e2) && (s1 <= e2 && s2 <= e1));
		//return !((s1 < e1 && e1 < s2 && s2 < e2) || (s2 < e2 && e2 < s1 && s1 < e1));
	}

	public static String getCronString(Datetime dt)
	{
		string hour = string.valueOf(dt.hour());
		string minute = string.valueof(dt.minute());
		string second = '0';
		string cronvalue = second+' '+minute+' '+hour+' * * ?' ;
		return cronvalue;
	}
	
	/**
		The following methods help in converting field values
	*/
	public static void updateMappedValues(String sobjName, List<SObject> newList, Map<Id, SObject> oldMap)
	{
		updateMappedValues(sobjName, newList, oldMap, false);
	}

	public static void updateMappedValues(String sobjName, List<SObject> newList, Map<Id, SObject> oldMap, Boolean reverseValues)
	{
		List<SMAX_PS_AutoFieldMapping__mdt> mappings = [Select DeveloperName, 
			SMAX_PS_SourceField__r.QualifiedApiName, SMAX_PS_SourceValue__c,
			SMAX_PS_TargetField__r.QualifiedApiName, SMAX_PS_TargetValue__c
			FROM SMAX_PS_AutoFieldMapping__mdt WHERE SMAX_PS_SObject__r.QualifiedApiName = :sobjName];
		Map<String, Map<String, Map<String, String>>> sourceFieldMap = new Map<String, Map<String, Map<String, String>>>();
		for (SMAX_PS_AutoFieldMapping__mdt mapping : mappings)
		{
			String sourceField = mapping.SMAX_PS_SourceField__r.QualifiedApiName;
			String targetField = mapping.SMAX_PS_TargetField__r.QualifiedApiName;
			if (!sourceFieldMap.containsKey(sourceField))
			{
				sourceFieldMap.put(sourceField, new Map<String, Map<String, String>>());
			}
			Map<String, Map<String, String>> targetFieldMap = sourceFieldMap.get(sourceField);
			if (!targetFieldMap.containsKey(targetField))
			{
				targetFieldMap.put(targetField, new Map<String, String>());
			}
			Map<String, String> values = targetFieldMap.get(targetField);
			if (reverseValues == FALSE)
				values.put(mapping.SMAX_PS_SourceValue__c, mapping.SMAX_PS_TargetValue__c);
			else
				values.put(mapping.SMAX_PS_TargetValue__c, mapping.SMAX_PS_SourceValue__c);
		}

		for (SObject sobj : newList)
		{
			SObject old = (oldMap == null) ? null : oldMap.get(sobj.Id);
			System.debug('Trying to AutoMap Fields for SObject: ' + sobj);
			for (String sourceField : sourceFieldMap.keySet())
			{
				String sourceValue = (String) sobj.get(sourceField);
				System.debug('Trying to AutoMap Field: ' + sourceField + ' with source value of: ' + sourceValue);
				String sourceOldValue = (old == null) ? null : (String) old.get(sourceField);
				Map<String, Map<String, String>> targetFieldMap = sourceFieldMap.get(sourceField);
				for (String targetField : targetFieldMap.keySet())
				{
					String targetValue = (String) sobj.get(targetField);
					String targetOldValue = (old == null) ? null : (String) old.get(targetField);
					if (reverseValues == FALSE && sourceField != null && (old == null || targetValue == null || sourceValue != sourceOldValue))
					{
						Map<String, String> values = targetFieldMap.get(targetField);
						String newTargetValue = values.get(sourceValue);
						sobj.put(targetField, newTargetValue);
						System.debug('Auto-Mapped Field: ' + targetField + ' with value of: ' + newTargetValue);
					}
					else if (reverseValues == TRUE && targetField != null && (old == null || sourceValue == null || targetValue != targetOldValue))
					{
						Map<String, String> values = targetFieldMap.get(targetField);
						String newSourceValue = values.get(targetValue);
						sobj.put(sourceField, newSourceValue);
						System.debug('Auto-Mapped Field: ' + sourceField + ' with value of: ' + newSourceValue);
					}
				}
			}
		}
	}

	//public static void copyAutoFieldMappings(Id fromMappingId, Id toMappingId, String prefix, Boolean reverseValues)
	//{
	//	// Example usage:
	//	// SMAX_PS_Utility.copyAutoFieldMappings('m06g00000008Ssl', 'm06g00000008T7b', 'CE EntitlementType', true);

	//	SMAX_PS_AutoFieldMapping__mdt fromMapping = [SELECT MasterLabel, DeveloperName, 
	//		SMAX_PS_SObject__c, SMAX_PS_SourceField__c, SMAX_PS_TargetField__c,
	//		SMAX_PS_SObject__r.QualifiedApiName, SMAX_PS_SourceField__r.QualifiedApiName, SMAX_PS_TargetField__r.QualifiedApiName
	//		FROM SMAX_PS_AutoFieldMapping__mdt WHERE Id = :fromMappingId];
	//	System.debug('TRYING to COPY AutoFieldMapping FROM: ' + fromMapping);
	//	SMAX_PS_AutoFieldMapping__mdt toMapping = [SELECT MasterLabel, DeveloperName, 
	//		SMAX_PS_SObject__c, SMAX_PS_SourceField__c, SMAX_PS_TargetField__c,
	//		SMAX_PS_SObject__r.QualifiedApiName, SMAX_PS_SourceField__r.QualifiedApiName, SMAX_PS_TargetField__r.QualifiedApiName
	//		FROM SMAX_PS_AutoFieldMapping__mdt WHERE Id = :toMappingId];
	//	System.debug('TRYING to COPY AutoFieldMapping TO: ' + toMapping);

	//	String oName = fromMapping.SMAX_PS_SObject__r.QualifiedApiName;
	//	String sName = fromMapping.SMAX_PS_SourceField__r.QualifiedApiName;
	//	String tName = fromMapping.SMAX_PS_TargetField__r.QualifiedApiName;
	//	System.debug('TRYING to FIND AutoFieldMappings: ' + oName + ', ' + sName + ', ' + tName);
	//	List<SMAX_PS_AutoFieldMapping__mdt> toCopy = [Select DeveloperName, 
	//		SMAX_PS_SourceValue__c, SMAX_PS_TargetValue__c,
	//		SMAX_PS_SourceField__r.QualifiedApiName, SMAX_PS_TargetField__r.QualifiedApiName
	//		FROM SMAX_PS_AutoFieldMapping__mdt WHERE SMAX_PS_SObject__r.QualifiedApiName = :oName];
	//	System.debug('FOUND ' + toCopy.size() + ' AutoFieldMappings to Copy.');
		
	//	// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_namespace_Metadata.htm
	//	Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
	//	for (SMAX_PS_AutoFieldMapping__mdt m : toCopy)
	//	{
	//		if (m.SMAX_PS_SourceField__r.QualifiedApiName != sName || m.SMAX_PS_TargetField__r.QualifiedApiName != tName)
	//		{
	//			System.debug('SKIPPING AutoFieldMapping because Source and Target not matching: ' + m.DeveloperName);
	//			continue;
	//		}

	//		String sourceValue = (reverseValues ? m.SMAX_PS_TargetValue__c : m.SMAX_PS_SourceValue__c);
	//		String targetValue = (reverseValues ? m.SMAX_PS_SourceValue__c : m.SMAX_PS_TargetValue__c);
	//		String label = prefix + ' ' + sourceValue;
	//		String developerName = label.replace(' ', '_');

	//		if (developerName == toMapping.DeveloperName)
	//		{
	//			System.debug('SKIPPING AutoFieldMapping: ' + developerName);
	//			continue;
	//		}

	//		// Set up custom metadata to be created in the subscriber org.
	//		Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
	//		customMetadata.fullName = 'SMAX_PS_AutoFieldMapping__mdt.' + developerName;
	//		customMetadata.label = label;
	//		customMetadata.values.add(createFieldValue('SMAX_PS_SourceValue__c', sourceValue));
	//		customMetadata.values.add(createFieldValue('SMAX_PS_TargetValue__c', targetValue));
	//		customMetadata.values.add(createFieldValue('SMAX_PS_SObject__c', toMapping.SMAX_PS_SObject__r.QualifiedApiName));
	//		customMetadata.values.add(createFieldValue('SMAX_PS_SourceField__c', toMapping.SMAX_PS_SourceField__r.QualifiedApiName));
	//		customMetadata.values.add(createFieldValue('SMAX_PS_TargetField__c', toMapping.SMAX_PS_TargetField__r.QualifiedApiName));

	//		System.debug('COPIED AutoFieldMapping: ' + customMetadata.fullName);

	//		mdContainer.addMetadata(customMetadata);
	//	}

	//	MyDeployCallback callback = new MyDeployCallback();
	//	Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
	//}

	//public class MyDeployCallback implements Metadata.DeployCallback {
	//    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
	//        if (result.status == Metadata.DeployStatus.Succeeded) {
	//            // Deployment was successful
	//            System.debug('DEPLOY was SUCCESSFUL!!');
	//        } else {
	//            // Deployment was not successful
	//            System.debug('DEPLOY was NOT SUCCESSFUL :(');
	//        }
	//    }
	//}

	//private static Metadata.CustomMetadataValue createFieldValue(String fieldName, String value)
	//{
	//	Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
	//	customField.field = fieldName;
	//	customField.value = value;
	//	return customField;
	//}

	/**
 * // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
 * The following Gets a Map of the controlling field values and the dependent picklist values for a provided dependent field
 */
	public static Map<String, List<String>> getDependentPicklistValues(Schema.SObjectField dependToken) {
		Schema.DescribeFieldResult depend = dependToken.getDescribe();
		Schema.SObjectField controlToken = depend.getController();
		if (controlToken == null) {
			return new Map<String, List<String>>();
		}

		Schema.DescribeFieldResult control = controlToken.getDescribe();
		List<Schema.PicklistEntry> controlEntries;
		if(control.getType() != Schema.DisplayType.BOOLEAN) {
			controlEntries = control.getPicklistValues();
		}

		String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
		for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
			if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
				List<String> base64chars =
						String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
				for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
					Object controlValue =
							(controlEntries == null
									?   (Object) (index == 1)
									:   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
							);
					Integer bitIndex = index / 6;
					if (bitIndex > base64chars.size() - 1) {
						break;
					}
					Integer bitShift = 5 - Math.mod(index, 6);
					if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
						continue;
					if (!dependentPicklistValues.containsKey((String) controlValue)) {
						dependentPicklistValues.put((String) controlValue, new List<String>());
					}
					dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
				}
			}
		}
		return dependentPicklistValues;
	}

	@AuraEnabled(Cacheable=true)
	global static Blob getComplaintForm() {
		ContentDocument cdoc = [SELECT Id, Title FROM ContentDocument WHERE Title = 'PKI_COMPLAINTFORM' LIMIT 1];
//		ContentAsset cass = [SELECT Id, DeveloperName, ContentDocumentId
//			FROM ContentAsset WHERE DeveloperName = 'PKIComplaintForm' LIMIT 1];
		ContentVersion cver = [SELECT Id, VersionData
			FROM ContentVersion WHERE ContentDocumentId = :cdoc.Id AND IsLatest = TRUE];
		return cver.VersionData;
	}

	@AuraEnabled(Cacheable=true)
	global static String getComplaintFormString() {
		Blob bob = getComplaintForm();
		return bob.toString();
	}
}
/**
 *  Apex Class containing Utility methods for creating records in the Error Log object [SMAX_PS_ErrorLog__c].
 *  2017-07-07		Frank VanLoon		Initial creation.
 */
global class SMAX_PS_LogUtility 
{
	public static string DEBUG = 'Debug';
	public static string ERROR  = 'Error';
	public static string WARNING  = 'Warning';
	public static string INFO  = 'Info';
	
	public static SMAX_PS_ErrorLog__c createLog(String type, String msg, String method, Exception objException, Id culpritId)
	{
		SMAX_PS_ErrorLog__c log = new SMAX_PS_ErrorLog__c(); 
		log.SMAX_PS_Message__c = msg;
		if (objException != null)
			log.SMAX_PS_Message__c += 'Exception: ' + objException.getMessage() + 
				'\n Stack Trace: ' + objException.getStackTraceString() + 
				'\n Line Number: ' + objException.getLineNumber() + 
				'\n Exception Type: ' + objException.getTypeName();
		log.SMAX_PS_Type__c = type;
		log.SMAX_PS_Link__c = createLink(culpritId);
		log.SMAX_PS_Method__c = method;
		
		return log;
	}

	public static void logError(Exception objException, Id culpritId, String method)
	{
		String link = URL.getSalesforceBaseUrl().toExternalForm() + '/' + culpritId;
		SMAX_PS_ErrorLog__c log = new SMAX_PS_ErrorLog__c(); 
		log.SMAX_PS_Message__c = 'Message: ' + objException.getMessage() + '\n Stack Trace: ' + objException.getStackTraceString() + '\n Line Number: ' + objException.getLineNumber() + '\n Exception Type: ' + objException.getTypeName();
		log.SMAX_PS_Type__c = ERROR;
		log.SMAX_PS_Link__c = createLink(culpritId);
		log.SMAX_PS_Method__c = method;
		
		insert log;
	}

	public static void logInfo(String message, Id culpritId, String method)
	{
		SMAX_PS_ErrorLog__c log = new SMAX_PS_ErrorLog__c(); 
		log.SMAX_PS_Message__c = message;
		log.SMAX_PS_Type__c = INFO;
		log.SMAX_PS_Link__c = createLink(culpritId);
		log.SMAX_PS_Method__c = method;
		
		insert log;   
	}

	private static String createLink(Id culpritId)
	{
		return URL.getSalesforceBaseUrl().toExternalForm() + '/' + culpritId;
	}
}
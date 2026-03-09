public without sharing class LogEntryController {
  public static void log(
    String requestBody,
    HttpResponse response,
    String apiName,
    Id cartId
  ) {
    String responseBody = response != null ? response.getBody() : 'No Response';
    String statusCode = response != null
      ? String.valueOf(response.getStatusCode())
      : 'N/A';

    logAsync(requestBody, responseBody, statusCode, apiName, cartId);
  }

  @future(callout=true)
  public static void logAsync(
    String requestBody,
    String responseBody,
    String statusCode,
    String apiName,
    Id cartId
  ) {
    List<Custom_Exception__c> existingLogs = [
      SELECT Id
      FROM Custom_Exception__c
      WHERE Cart_Id__c = :cartId
      LIMIT 1
    ];

    if (!existingLogs.isEmpty()) {
      Custom_Exception__c existingLog = existingLogs[0];
      existingLog.Request_JSON__c = requestBody;
      existingLog.Response_JSON__c = responseBody;
      existingLog.Extended_Status__c = statusCode;
      existingLog.Exception_Type__c = apiName;
      update existingLog;
    } else {
      Custom_Exception__c newLog = new Custom_Exception__c();
      newLog.Cart_Id__c = cartId;
      newLog.Request_JSON__c = requestBody;
      newLog.Response_JSON__c = responseBody;
      newLog.Extended_Status__c = statusCode;
      newLog.Exception_Type__c = apiName;
      insert newLog;
    }
  }
}
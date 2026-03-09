public class B2BLogCustomException extends Exception {
    //Comment to force git diff
  public static void LogException(
    Exception e,
    String category,
    String subcategory
  ) {
    try {
      String stackTrace = e.getStackTraceString().substringBefore('\n');
      String className = stackTrace.substringAfter('.').substringBefore('.');
      String methodName = stackTrace.substringBefore(':')
        .substringAfter(className)
        .substringAfter('.');

      //Governer Limit of executingQuery
      String QueryLimit =
        '1. SOQL Queries used / SOQL Queries allowed: ' +
        Limits.getQueries() +
        '/' +
        Limits.getLimitQueries();
      String DMLimit =
        '2. Number of records queried so far /  Number allowed: ' +
        Limits.getDmlRows() +
        '/' +
        Limits.getLimitDmlRows();
      String DMLStat =
        '3. Number of DML statements used so far / Number allowed: ' +
        Limits.getDmlStatements() +
        '/' +
        Limits.getLimitDmlStatements();
      String CPUT =
        '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' +
        Limits.getCpuTime() +
        '/' +
        Limits.getLimitCpuTime();

      //Log information in object
      Custom_Exception__c exc = new Custom_Exception__c();
      exc.Name = e.getTypeName();
      exc.Govt_Limit_in_Executing_Code__c = String.format(
        '{0}\n{1}\n{2}\n{3}',
        new List<string>{ QueryLimit, DMLimit, DMLStat, CPUT }
      );
      exc.Exception_Messages__c = e.getMessage();
      exc.Exception_Type__c = e.getTypeName();
      exc.Line_Number__c = String.valueOf(e.getLineNumber());
      exc.Stack_Trace__c = e.getStackTraceString();
      exc.Method_Name__c = methodName;
      exc.Class_Name__c = className;
      exc.Category__c = category;
      exc.Sub_Category__c = subcategory;
      database.insert(exc);
    } finally {
    }
  }
}
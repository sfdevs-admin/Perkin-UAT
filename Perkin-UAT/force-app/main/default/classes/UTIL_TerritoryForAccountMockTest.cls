/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1862
  *    - ITSFDC-####
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    this will allow running Account Territories via Q.ACTION & M.ACTION which is otherwise not possible via native execution.
  *    This allows it to run as a system user so that default users do not need elevated permissions on accounts. (i.e. Public Read Only is all that is needed)
  *
  * 3. Objects referenced
  *    -Account
  *    -Object Name
  *    -Object Name
  *    -Object Name 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *    - Component.Method  
  *    - Component.Method
  *
  * 5. Dependant Class(es):
  *    - UTIL_RunTerritoryRules
  *    - UTIL_TerritoryForAccount  (<--is Invocable)
  *    - UTIL_TerritoryForAccountMockTest
  *    - UTIL_TerritoryForAccountTest
  *
  * 6. Test Class Name: UTIL_TerritoryForAccountMockTest, UTIL_TerritoryForAccountTest
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - (KPMG)Yakup Garayev - 2022.12.12
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest
global class UTIL_TerritoryForAccountMockTest implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
            //  docSample.EchoStringResponse_element respElement = 
            //     new docSample.EchoStringResponse_element();
            // respElement.EchoStringResult = 'Mock response';
            string response_x = '<body>Success</body>';
            response.put('response_x',response_x);   
        }

}
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

public class UTIL_RunTerritoryRules implements Queueable, Database.AllowsCallouts {
    public Set<String> accntIds = null;
    private String sessionId = null;    
    public void execute(QueueableContext context) {
    sessionId =UserInfo.getSessionId();     
        List<String> lstAccString = new List<String>();
        if(accntIds != null){
            for(String accId:accntIds){
                lstAccString.add(accountTag.replace('{ACCID}', accId)); 
            }
        } 
        requestTemplate = requestTemplate.replace('{ACCLISTS}', String.join(lstAccString, ' ')) ;
        requestTemplate = requestTemplate.replace('{SESSID}', sessionId) ;        
        HttpRequest request = new HttpRequest();
    request.setEndpoint(System.URL.getSalesforceBaseUrl().toExternalForm()+
                '/services/Soap/u/41.0/'+UserInfo.getOrganizationId());
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
    request.setHeader('SOAPAction', '""');
        request.setBody(requestTemplate);
        system.debug('@@body'+requestTemplate);
        String s = '';
        if(!test.isRunningTest()){
             s = String.valueOf(new Http().send(request).getBodyDocument());
        System.debug(new Http().send(request));
            system.debug(s);
       }
    }
    String accountTag = '<urn:sObjects> '+
                            '<urn1:type>Account</urn1:type>  '+
                    '<urn1:Id>{ACCID}</urn1:Id>   '+
                        '</urn:sObjects> ' ;    
    String requestTemplate = '<soapenv:Envelope '+
                'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'+
                ' xmlns:urn="urn:partner.soap.sforce.com"'+
                ' xmlns:urn1="urn:sobject.partner.soap.sforce.com">'+
                                '<soapenv:Header> '+
                                  '<urn:AssignmentRuleHeader> '+ 
                                     '<urn:useDefaultRule>true</urn:useDefaultRule> '+
                                     '<urn:assignmentRuleId></urn:assignmentRuleId> '+
                                  '</urn:AssignmentRuleHeader>  '+
                                  '<urn:SessionHeader> '+
                        '<urn:sessionId>{SESSID}</urn:sessionId> '+
                                  '</urn:SessionHeader> '+
                               '</soapenv:Header> '+
                               '<soapenv:Body> '+
                      '<urn:update> '+
                       ' {ACCLISTS}'+ 
                                  '</urn:update> '+
                               '</soapenv:Body> '+
                            '</soapenv:Envelope>';

}
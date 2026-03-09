/****************************************************************
* https://github.com/financialforcedev/apex-mdapi
* https://andyinthecloud.com/2013/05/11/code-coverage-for-wsdl2apex-generated-classes/
*/
@IsTest
private class MetaDataService1_Test {
    
    private class WebServiceMockImpl implements WebServiceMock  {   
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
                if(request instanceof  MetadataService1.deleteMetadata_element) {
                     response.put('response_x', new MetadataService1.deleteMetadataResponse_element());
                }                   
                else  if(request instanceof  MetadataService1.readMetadata_element) {
                    MetadataService1.Metadata mdInfo = new MetadataService1.Metadata();
                    mdInfo.fullName = 'Test';                    
                    MetadataService1.RuleEntry ruleEntry = new MetadataService1.RuleEntry();
                    ruleEntry.assignedTo = 'abc@pki-user-test.com';
                    ruleEntry.assignedToType = 'User';                    
                    MetadataService1.AssignmentRule  rule = new MetadataService1.AssignmentRule();
                    rule.active = true;
                    rule.fullName = 'Test';                
                    rule.ruleEntry = new List<MetadataService1.RuleEntry>{ruleEntry};                        
                    MetadataService1.AssignmentRules TempAssignmentRules = new MetadataService1.AssignmentRules();                    
                    TempAssignmentRules.assignmentRule = new List< MetadataService1.AssignmentRule>{rule};                        
                    MetadataService1.ReadAssignmentRulesResult reslt = new MetadataService1.ReadAssignmentRulesResult();
                    reslt.records  = new List<MetadataService1.AssignmentRules>{TempAssignmentRules};                    
                    MetadataService1.IReadResult readResult = reslt; 
                    MetadataService1.readAssignmentRulesResponse_element finalRes = new MetadataService1.readAssignmentRulesResponse_element();
                    finalRes.result = reslt;
                    response.put('response_x', finalRes);
                }   
                return;                
            }        
    }
    
    private class RestRequestMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');        
            res.setBody('{"body" : "dummyAPIResult"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private static testMethod void coverTypes() { 
        Test.startTest();
        new MetaDataService1.AssignmentRule();
        new MetaDataService1.AssignmentRules();
        new MetaDataService1.SessionHeader_element();
        new MetaDataService1.DebuggingInfo_element();
        new MetaDataService1.LogInfo();
        new MetaDataService1.DebuggingHeader_element();
        new MetaDataService1.CallOptions_element();
        new MetaDataService1.AllOrNoneHeader_element();
        new MetaDataService1.Error();
        new MetaDataService1.ExtendedErrorDetails();
        new MetaDataService1.DeleteResult();
        new MetaDataService1.deleteMetadata_element();
        new MetaDataService1.deleteMetadataResponse_element();
        new MetaDataService1.readMetadata_element();
        new MetaDataService1.ReadAssignmentRulesResult();
        new MetaDataService1.RuleEntry();
        new MetaDataService1.FilterItem();
        new MetaDataService1.readAssignmentRulesResponse_element();
        new MetaDataService1.EscalationAction();
        new MetaDataService1.Metadata();
        new MetadataService1.ReadAssignmentRulesResult().getRecords();
        new MetadataService1.readAssignmentRulesResponse_element().getResult();       
        Test.stopTest();
    }
    
    private static testMethod void coverGeneratedCode() {       
        MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        Test.startTest();    
       
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        
        Boolean result = FetchLARMetadataAPI.deleteListView('Test1',new List<String>{'Test2'});
        Test.stopTest();
    }  
    
    private static testMethod void coverAccessToken() {
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        Test.startTest();
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MetadataService1 metaDataService = new MetadataService1();
        
        MetadataService1.MetadataPort metaDataPort = new MetadataService1.MetadataPort();
        metaDataPort.readMetadata(null, null);       
        Test.stopTest();     
    }   
    
    static user createStandardUser(Integer randNo, String userName) {
        User standardUser = new User();
        System.runAs(new User(Id=userinfo.getUserId()))
        {            
            standardUser.FirstName = 'Test';
            standardUser.LastName = 'test User ' + randNo;
            standardUser.Email = 'test_user11' + randNo + '@pkedev.test.com';
            standardUser.Alias = 'test' + randNo;
            standardUser.Username = userName;
            standardUser.CommunityNickname = 'standard'+randNo;
            standardUser.TimeZoneSidKey = 'America/Chicago';
            standardUser.LocaleSidKey = 'en_US'; 
            standardUser.EmailEncodingKey = 'ISO-8859-1';
            standardUser.LanguageLocaleKey = 'en_US'; 
            standardUser.IsActive = true;
            standardUser.ProfileId = [ SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;            
            insert standardUser;           
        }
        return standardUser;
    }
    
    private static testMethod void coverscheduledBatchable() {
        String hostName  = URL.getOrgDomainUrl().getHost().substringBetween('--','.');
        String newString = String.isNotBlank(hostName) ?  'abc@pki-user-test.com' + '.' + hostName : 'abc@pki-user-test.com';                                     
        
        User u = createStandardUser(11,newString);
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        Test.startTest();
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());         
         
        String hour = String.valueOf(Datetime.now().hour());
        String min  = String.valueOf(Datetime.now().minute() + 1); 
        String ss   = String.valueOf(Datetime.now().second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        LeadAssignmentRule_Scheduler sc = new LeadAssignmentRule_Scheduler();
        system.schedule('Lead Assignment Rule Immediate Calculation',nextFireTime,sc);
        Test.stopTest();     
    } 
    
    private static testMethod void coverDailyScheduledBatchable() {
        String hostName  = URL.getOrgDomainUrl().getHost().substringBetween('--','.');
        String newString = String.isNotBlank(hostName) ?  'abc@pki-user-test.com' + '.' + hostName : 'abc@pki-user-test.com';                                     
        
        User u = createStandardUser(11,newString);
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        Test.startTest();
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());         
        
        String hour = String.valueOf(Datetime.now().hour()); 
        String min  = String.valueOf(Datetime.now().minute() + 1); 
        String ss   = String.valueOf(Datetime.now().second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        LeadAssignmentRule_Batch.scheduledBatchable sc = new LeadAssignmentRule_Batch.scheduledBatchable();
        system.schedule('Lead Assignment Rule Daily Total',nextFireTime,sc);
        Test.stopTest();     
    } 
}
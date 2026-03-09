@isTest
private class LimitsAppTest {
       
    @isTest static void testlimitCreatedInLastMinute() {
        Test.startTest();
        Limit_LimitsApp__c l2 = new Limit_LimitsApp__c(DailyApiRequests_Max__c = 5000, DailyApiRequests_Remaining__c = 4937, Latest__c = True);
        insert l2;
        Test.stopTest();
        //Boolean createdInLastMin = LimitsApp.limitCreatedInLastMinute();
        //System.assertEquals(true,createdInLastMin);
        System.assert(LimitsApp.limitCreatedInLastMinute() == True);
    }
    
    @isTest static void testgetLimitsRecordId() {
        Test.startTest();
        Limit_LimitsApp__c l3 = new Limit_LimitsApp__c(DailyApiRequests_Max__c = 5000, DailyApiRequests_Remaining__c = 4937, Latest__c = True);
        insert l3;
        //String l3ID = [SELECT Id FROM Limit_LimitsApp__c WHERE Latest__c = true].Id;
        Test.stopTest();
        System.assert(LimitsApp.getLimitsRecordId() == l3.Id);
    }

    @isTest static void testgetLimitsRecordIdOnClick() {
        Test.startTest();
        Limit_LimitsApp__c l4 = new Limit_LimitsApp__c(DailyApiRequests_Max__c = 5000, DailyApiRequests_Remaining__c = 4937, Latest__c = True);
        insert l4;
        //String l3ID = [SELECT Id FROM Limit_LimitsApp__c WHERE Latest__c = true].Id;
        Test.stopTest();
        System.assert(LimitsApp.getLimitsRecordIdOnClick() == l4.Id);
    }

    
    @isTest static void TestLimitsAppTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LimitsAppMockImpl());
        LimitsApp.getLimits();
        //Verify response received contains fake values
        //String contentType = res.getHeader('Content-Type');
        //System.assert(contentType == 'application/json');
        //String actualValue = res.getBody();
        //String expectedValue = '{"example":"test"}';
        //System.assertEquals(actualValue, expectedValue);
        //System.assertEquals(200, res.getStatusCode());
		String expectedValue = '{"DailyApiRequests": {"Max": 5000, "Remaining": 4937 }}';
        Limit_LimitsApp__c l1 = new Limit_LimitsApp__c(DailyApiRequests_Max__c = 5000, DailyApiRequests_Remaining__c = 4937, Latest__c = True);
        insert l1;
        Test.stopTest();
        //Boolean createdInLastMin = LimitsApp.limitCreatedInLastMinute();
        //System.assertEquals(true,createdInLastMin);
        System.assert(l1.Latest__c == True);
    }
    
    @isTest static void TestLimitsAppAdHoc(){
        List<LimitsApp.Results> lar = new List<LimitsApp.Results>();
        Test.setMock(HttpCalloutMock.class, new LimitsAppMockImpl());
        lar = LimitsApp.getLimitsAdHoc();
        Limit_LimitsApp__c ll = [SELECT DailyApiRequests_Max__c 
                                 FROM Limit_LimitsApp__c 
                                 WHERE Latest__c = True];
        System.assert(ll.DailyApiRequests_Max__c == 5000);
        System.assert(lar[0].limitCreatedInLastMinute == False);
    }  
}
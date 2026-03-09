@isTest
global class LimitsAppMockImpl implements HttpCalloutMock{
	// Implement this interface method 
    global HTTPResponse respond(HTTPRequest req){
        // Optionally, only send a mock response for a specific endpoint and method.
        System.assertEquals('callout:LimitsAppAPI_NC/services/data/v56.0/limits', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        //String expectedValue = '{"example":"test"}';
        res.setBody('{"DailyApiRequests": {"Max": 5000, "Remaining": 4937 }}');   
        res.setStatusCode(200);
        return res;
   }   
}
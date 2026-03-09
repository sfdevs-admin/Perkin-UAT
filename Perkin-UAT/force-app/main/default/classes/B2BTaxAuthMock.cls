@IsTest
public class B2BTaxAuthMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"sessionId": "mockSession123"}');
        return res;
    }
}
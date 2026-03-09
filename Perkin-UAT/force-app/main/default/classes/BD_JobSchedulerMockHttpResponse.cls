/*********************************************************************************************************************
 * MOCK CLASS: BD_JobSchedulerMockHttpResponse
 * @author Bolt Data Consulting Group
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
@IsTest public class BD_JobSchedulerMockHttpResponse implements HttpCalloutMock
{
    static List<Mock> mocks;

    public static BD_JobSchedulerMockHttpResponse builder()
    {
        mocks = new List<Mock>
        {
                new Mock()
        };
        return new BD_JobSchedulerMockHttpResponse();
    }

    public BD_JobSchedulerMockHttpResponse contentType( String contentType )
    {
        getCurrentResponse().setHeader( 'Content-Type', contentType );
        return this;
    }

   public BD_JobSchedulerMockHttpResponse body( String body )
    {
        getCurrentResponse().setBody( body );
        return this;
    }

    public HttpResponse respond( HttpRequest req )
    {
        return mocks.remove( 0 ).res;
    }

    static HttpResponse getCurrentResponse()
    {
        return mocks[ mocks.size() - 1 ].res;
    }

    class Mock
    {
        HttpResponse res;

        Mock()
        {
            res = new HttpResponse();
            res.setStatusCode( 200 );
        }
    }
}
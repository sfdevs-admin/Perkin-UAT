/*********************************************************************************************************************
 * CLASS: BD_Invocable_QueryRecords
 * @author Bolt Data Consulting Group
 * @description Invocable method to run a custom query of records for a given object.
 *
 * -----CHANGE LOG-----
 * 2025.03.26 - ives - Created class.
 *********************************************************************************************************************/
public without sharing class BD_Invocable_QueryRecords
{
    /**----------------------------------------------------------------------------------------------------------------
     * INVOCABLE METHOD: runQuery
     * @author Bolt Data Consulting Group
     * @param requests A List of Queries to run.
     * @return A list of records returned by the query.
     * @description Run the given SOQL statement to query records.
     *
     * -----CHANGE LOG-----
     * 2025.03.26 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @InvocableMethod( Category='BD Utilities' Label='Query Records' )
    public static List<QueryResponse> runQuery( List<QueryRequest> requests )
    {
        System.debug( LoggingLevel.INFO, 'ENTERED runQuery() with reqs=' + requests );

        List<QueryResponse> responses = new List<QueryResponse>();
        for( QueryRequest req : requests )
        {
            QueryResponse rsp = new QueryResponse();
            rsp.records = Database.query( req.soqlQuery );
            rsp.recordCount = rsp.records != null ? rsp.records.size() : 0;
            responses.add( rsp );
        }

        System.debug( LoggingLevel.INFO, 'EXITING runQuery() with rsps=' + responses );
        return responses;
    }


    /*********************************************************************************************************************
     * CLASS: QueryRequest
     * @author Bolt Data Consulting Group
     * @description Value object for the query request.
     *
     * -----CHANGE LOG-----
     * 2025.03.26 - ives - Created class.
     *********************************************************************************************************************/
    public class QueryRequest
    {
        @InvocableVariable( Label = 'SOQL Query' Description = 'The SOQL Query String to Execute' Required = true )
        public String soqlQuery;
    }


    /*********************************************************************************************************************
     * CLASS: QueryResponse
     * @author Bolt Data Consulting Group
     * @description Value object for the queried records.
     *
     * -----CHANGE LOG-----
     * 2025.03.26 - ives - Created class.
     *********************************************************************************************************************/
    public class QueryResponse
    {
        @InvocableVariable( Label = 'Query Result Count' Description = 'The number of Query Results' Required = false )
        public Integer recordCount;

        @InvocableVariable( Label = 'Query Results' Description = 'The Query Results' Required = false )
        public SObject[] records;
    }
}
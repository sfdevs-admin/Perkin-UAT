/*********************************************************************************************************************
 * TEST CLASS: BD_Invocable_QueryRecords_Test
 * @author Bolt Data Consulting Group
 * @description Unit Tests for BD_QueryRecordIDs.
 *
 * -----CHANGE LOG-----
 * 2025.03.26 - ives - Created class.
 *********************************************************************************************************************/
@IsTest private class BD_Invocable_QueryRecords_Test
{
    @IsTest static void testBehavior()
    {
        Account a = new Account();
        a.Name = 'Test Acount';
        insert a;

        BD_Invocable_QueryRecords.QueryRequest req = new BD_Invocable_QueryRecords.QueryRequest();
        req.soqlQuery = 'SELECT Id, Name FROM Account WHERE Id = \'' + a.Id + '\'';

        BD_Invocable_QueryRecords.QueryResponse[] rsps = BD_Invocable_QueryRecords.runQuery( new List<BD_Invocable_QueryRecords.QueryRequest>{ req } );
        BD_Invocable_QueryRecords.QueryResponse rsp = rsps.get( 0 );

        Account a2 = (Account) rsp.records.get( 0 );
        System.assertEquals( a.Name, a2.Name, 'Names do not match' );
        System.assertEquals( 1, rsp.recordCount, 'Record Count does not match' );
    }
}
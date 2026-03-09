/*********************************************************************************************************************
* TEST CLASS: BD_Batch_OrgLimitChecker_Test
* @author Bolt Data Consulting Group
* @description Unit tests for BD_Batch_OrgLimitChecker.
*
* -----CHANGE LOG-----
* 2025.09.11 - ives - Created class.
*********************************************************************************************************************/
@IsTest private class BD_Batch_OrgLimitChecker_Test
{

    @IsTest static void test_batch()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_Batch_OrgLimitChecker checker = new BD_Batch_OrgLimitChecker();

        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            checker.start( null );
            checker.execute( null, null );
            checker.finish( null );

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
    }
}
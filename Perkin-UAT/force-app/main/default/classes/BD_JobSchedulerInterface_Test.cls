/*********************************************************************************************************************
 * UNIT TEST: BD_JobSchedulerInterface_Test
 * @author Bolt Data Consulting Group
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
@IsTest private class BD_JobSchedulerInterface_Test
{

    @IsTest static void test_Interface()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        Id expected = null;

        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            expected = CronTrigger.sObjectType.getDescribe().getKeyPrefix().rightPad( 15, '0' );

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
        
        /*
         * VALIDATE TEST RESULTS
         */

        System.assertEquals( expected, new BD_JobSchedulerInterface().getTriggerId() );
    }


}
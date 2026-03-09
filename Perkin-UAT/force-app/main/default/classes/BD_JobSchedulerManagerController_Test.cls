/*********************************************************************************************************************
 * UNIT TEST: BD_JobSchedulerManagerController_Test
 * @author Bolt Data Consulting Group
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
@IsTest(SeeAllData=true) private class BD_JobSchedulerManagerController_Test
{

    @IsTest static void test_Init()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_JobSchedulerManagerController con = null;

        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            con = new BD_JobSchedulerManagerController();
            con.parseJobType();
            con.parseSchedType();

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }

        /*
         * VALIDATE TEST RESULTS
         */


    }

    @IsTest static void test_Flow()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_JobSchedulerManagerController con = new BD_JobSchedulerManagerController();
        con.selectedJobType = 'flow';
        con.selectedSchedType = 'recurring';


        /*
         * RUN TEST
         */

        try
        {
            Test.setMock(
                HttpCalloutMock.class,
                BD_JobSchedulerMockHttpResponse.builder()
                        .contentType( 'application/json' )
                        .body(
                                '{' +
                                        '"totalSize": 1,' +
                                        '"done": true,' +
                                        '"records": [' +
                                        '{' +
                                        '"attributes": {' +
                                        '"type": "FlowDefinitionView",' +
                                        '"url": "/services/data/v61.0/sobjects/FlowDefinitionView/300P00000008tgsIAA"' +
                                        '},' +
                                        '"Label": "Test Flow",' +
                                        '"ApiName": "Some_Flow",' +
                                        '"NamespacePrefix": null' +
                                        '},' +
                                        '{' +
                                        '"attributes": {' +
                                        '"type": "FlowDefinitionView",' +
                                        '"url": "/services/data/v61.0/sobjects/FlowDefinitionView/300P00000008tgsIAB"' +
                                        '},' +
                                        '"Label": "Even More Flow",' +
                                        '"ApiName": "Some__Other_Flow",' +
                                        '"NamespacePrefix": null' +
                                        '}' +
                                        ']' +
                                        '}'
                        )
            );

            Test.startTest();

            con.parseJobType();
            con.parseSchedType();
            con.startDateTime = Datetime.now().addHours( 1 );
            con.repeatInterval = 30;
            con.endDateTime = con.startDateTime.addHours( 5 );

            List<SelectOption> options = con.getFlowList();
            con.selectedFlow = 'TestFlow';
            con.scheduleJob();

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
    }


    @IsTest static void test_Class()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_JobSchedulerManagerController con = new BD_JobSchedulerManagerController();
        con.selectedJobType = 'class';
        con.selectedSchedType = 'recurring';
        con.selectedClassType = 'batchable';


        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            con.parseJobType();
            con.parseSchedType();
            con.startDateTime = Datetime.now().addHours( 1 );
            con.repeatInterval = 30;
            con.endDateTime = con.startDateTime.addHours( 5 );
            con.selectedClass = 'BD_BatchableTest';

            con.parseClassType();
            con.scheduleJob();

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
    }



    @IsTest static void test_Class2()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_JobSchedulerManagerController con = new BD_JobSchedulerManagerController();
        con.selectedJobType = 'class';
        con.selectedSchedType = 'scheduled';
        con.selectedClassType = 'schedulable';


        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            con.parseJobType();
            con.parseSchedType();
            con.startDateTime = Datetime.now().addHours( 1 );
            con.repeatInterval = 30;
            con.endDateTime = con.startDateTime.addHours( 5 );
            con.selectedClass = 'BD_SchedulableTest';

            con.parseClassType();
            con.scheduleJob();

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
    }

     @IsTest static void test_AnonApex()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_JobSchedulerManagerController con = new BD_JobSchedulerManagerController();
        con.selectedJobType = 'apex';
        con.selectedSchedType = 'recurring';


        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            con.parseJobType();
            con.parseSchedType();
            con.startDateTime = Datetime.now().addHours( 1 );
            con.repeatInterval = 30;
            con.endDateTime = con.startDateTime.addHours( 5 );
            con.anonApex = 'System.debug(\'Testing!!!\');';
            con.scheduleJob();

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }
    }


}
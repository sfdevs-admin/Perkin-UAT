/*********************************************************************************************************************
 * UNIT TEST: BD_JobScheduler_Test
 * @author Bolt Data Consulting Group
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
@IsTest private class BD_JobScheduler_Test
{
    @IsTest
    static void shouldExecuteJobOnce()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            insert e;

            Test.startTest();
            BD_JobScheduler.schedule( 'Test Job', e.BD_Start__c, e.Id );
            e = [ SELECT BD_Start__c, BD_Number_of_Executions__c FROM BD_Job_Scheduler_Entry__c ];
            System.assertEquals( 0, e.BD_Number_of_Executions__c );
            Test.stopTest();
        }

        BD_Job_Scheduler_Entry__c res =
        [
                SELECT BD_Start__c, BD_Number_of_Executions__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE Id = :e.Id
        ];
        System.assertEquals( e.BD_Start__c, res.BD_Start__c );
        System.assertEquals( 1, res.BD_Number_of_Executions__c );
    }

    @IsTest
    static void shouldExecuteJobOnceAndRescheduleIn5()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            e.BD_Repeat_Interval__c = 5;
            insert e;

            Test.startTest();
            BD_JobScheduler.schedule( 'Test Job', e.BD_Start__c, e.Id );
            Test.stopTest();
        }

        BD_Job_Scheduler_Entry__c res =
        [
                SELECT BD_Start__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE Id = :e.Id
        ];
        System.assertEquals(
                Datetime.now().addMinutes( 5 ).minute(),
                res.BD_Start__c.minute()
        );
    }

    @IsTest
    static void shouldExecuteJobOnceAndRescheduleForTomorrow()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            e.BD_Is_Daily__c = true;
            insert e;

            Test.startTest();
            BD_JobScheduler.schedule( 'Test Job', e.BD_Start__c, e.Id );
            Test.stopTest();
        }

        BD_Job_Scheduler_Entry__c res =
        [
                SELECT BD_Start__c, BD_Daily_Start_Date_Time__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE Id = :e.Id
        ];
        System.assertEquals( e.BD_Start__c.addDays( 1 ), res.BD_Start__c );
        System.assertEquals(
                e.BD_Daily_Start_Date_Time__c.addDays( 1 ),
                res.BD_Daily_Start_Date_Time__c
        );
    }

    @IsTest
    static void shouldKnowIfItShouldRunAgainToday()
    {
        BD_JobScheduler s = new BD_JobScheduler( null );

        s.entry = getStarterEntry();
        System.assert( s.isBeforeOrNoEndDateTime() );

        s.entry.BD_End__c = Datetime.now().addDays( 1 );
        System.assert( s.isBeforeOrNoEndDateTime() );

        s.entry.BD_Is_Daily__c = true;
        System.assert( s.isBeforeOrNoEndDateTime() );

        s.entry.BD_Daily_End__c = Date.today().addDays( 2 );
        System.assert( s.isBeforeOrNoEndDateTime() );

        s.entry.BD_Daily_End__c = Date.today().addDays( -1 );
        System.assert( !s.isBeforeOrNoEndDateTime() );

        s.entry.BD_End__c = Datetime.now().addDays( -1 );
        System.assert( !s.isBeforeOrNoEndDateTime() );


    }

    @IsTest static void shouldNotCrashIfEntryIsDeleted()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            insert e;
        }

        delete e;

        Test.startTest();
        BD_JobScheduler.schedule( 'Test Entry', e.BD_Start__c, e.Id );
        Test.stopTest();

        System.assertEquals( 0, [ SELECT COUNT() FROM BD_Job_Scheduler_Entry__c ] );
    }


    @IsTest
    static void markAsComplete()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            e.BD_Repeat_Interval__c = 5;
            insert e;

            Test.startTest();
            BD_JobScheduler job = new BD_JobScheduler( e.Id );
            job.entry = e;
            job.completeEntry();
            Test.stopTest();
        }

        BD_Job_Scheduler_Entry__c res =
        [
                SELECT BD_Job_Status__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE Id = :e.Id
        ];
        System.assertEquals( 'Complete', res.BD_Job_Status__c );
    }

    @IsTest static void codeCoverage()
    {
        try
        {
            Test.startTest();

            try {
                BD_JobScheduler.executeSchedulable( 'JobSchedulableTest' );
            } catch( Exception ee ) {
                System.debug( 'Expected Error: ' + ee );
            }

            try {
                BD_JobScheduler.executeSchedulable( 'Prefix__JobSchedulableTest' );
            } catch( Exception ee ) {
                System.debug( 'Expected Error: ' + ee );
            }

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug( '\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n' );
            System.assert( false, 'Exception caught - ' + e );
        }

    }


    static Profile standardUserProfile;

    public static User createStandardUser( String name )
    {
        return createTestUser( name, getStandardUserProfile() );
    }

    static Profile getStandardUserProfile()
    {
        if( standardUserProfile == null )
        {
            standardUserProfile = getProfile( 'Standard User' );
        }
        return standardUserProfile;
    }

    static Profile getProfile( String name )
    {
        return [ SELECT Id FROM Profile WHERE Name = :name ];
    }

    static User createTestUser( String name, Profile p )
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf( Datetime.now() )
                .replace( ' ', '' )
                .replace( ':', '' )
                .replace( '-', '' );
        Integer randomInt = Integer.valueOf( Math.rint( Math.random() * 1000000 ) );
        String uniqueName = orgId + dateString + randomInt;

        return new User(
                LastName = name,
                Username = uniqueName + '@test' + orgId + '.org',
                Email = uniqueName + '@test' + orgId + '.org',
                EmailEncodingKey = 'ISO-8859-1',
                Alias = uniqueName.substring( 18, 23 ),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
        );
    }

    static public BD_Job_Scheduler_Entry__c getStarterEntry()
    {
        Datetime start = Datetime.now().addMinutes( 5 );

        return new BD_Job_Scheduler_Entry__c(
                BD_Class__c = 'hey',
                BD_Is_Batchable__c = true,
                BD_Start__c = start,
                BD_Daily_Start_Date_Time__c = start,
                BD_Repeat_Interval__c = 0,
                BD_Reschedule_Interval__c = 5
        );
    }

    @IsTest
    static void shouldIncrementExecutionsBy1()
    {
        BD_JobScheduler s = new BD_JobScheduler( null );

        s.entry = getStarterEntry();
        s.incrementExecutions();
        System.assertEquals( 1, s.entry.BD_Number_of_Executions__c );

        s.incrementExecutions();
        System.assertEquals( 2, s.entry.BD_Number_of_Executions__c );
    }

    @IsTest
    static void shouldRescheduleForTomorrow()
    {
        BD_JobScheduler s = new BD_JobScheduler( null );
        Datetime start = Datetime.now().addMinutes( 5 );
        Datetime endd = Datetime.now().addDays( 1 );

        BD_Job_Scheduler_Entry__c e = getStarterEntry();
        e.BD_Start__c = start;
        e.BD_Daily_Start_Date_Time__c = start;
        e.BD_End__c = endd;
        insert e;
        s.entry = e;

        s.rescheduleForTomorrow();
        System.assertEquals( start.addDays( 1 ), s.entry.BD_Start__c );
        System.assertEquals( start.addDays( 1 ), s.entry.BD_Daily_Start_Date_Time__c );
        System.assertEquals( endd.addDays( 1 ), s.entry.BD_End__c );
    }

    @IsTest
    static void shouldExecuteAnonymousWithoutCrashing()
    {
        Test.setMock( HttpCalloutMock.class, BD_JobSchedulerMockHttpResponse.builder() );

        User u = createStandardUser( 'blah' );
        insert u;

        Test.startTest();
        System.runAs( u )
        {
            BD_JobScheduler.executeAnonymous( 'System.debug(\'hey!\')' );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldLogErrorIfUserInactive()
    {
        User u = createStandardUser( 'Tester' );
        insert u;

        BD_Job_Scheduler_Entry__c e;

        System.runAs( u )
        {
            e = getStarterEntry();
            insert e;
        }

        u.IsActive = false;
        update u;

        Test.startTest();
        BD_JobScheduler.schedule( 'Test Entry', e.BD_Start__c, e.Id );
        e = [ SELECT BD_Number_of_Executions__c FROM BD_Job_Scheduler_Entry__c ];
        System.assertEquals( 0, e.BD_Number_of_Executions__c );
        Test.stopTest();

        BD_Job_Scheduler_Entry__c res =
        [
                SELECT BD_Number_of_Executions__c, BD_Execution_Error__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE Id = :e.Id
        ];
        System.assertEquals( 0, res.BD_Number_of_Executions__c );
        System.assertEquals(
                BD_JobScheduler.EXECUTION_ERROR_INACTIVE_OWNER,
                res.BD_Execution_Error__c
        );
    }


    @IsTest
    static void shouldReturnListOfFlows()
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

        User u = createStandardUser( 'Tester' );
        insert u;

        List<Map<String, Object>> flows;

        Test.startTest();
        System.runAs( u )
        {
            flows = (List<Map<String, Object>>) BD_JobScheduler.getFlows();
            System.assert( !flows.isEmpty(), 'Expected a list of flows' );
        }
        Test.stopTest();
    }





    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    class JobSchedulableTest implements Schedulable
    {
        public void execute( SchedulableContext SC )
        {
            System.debug( 'Schedulable Test Ran!' );
        }
    }

}
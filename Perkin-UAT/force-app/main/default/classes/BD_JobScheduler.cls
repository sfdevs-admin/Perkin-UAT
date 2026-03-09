/*********************************************************************************************************************
 * CLASS: BD_JobScheduler
 * @author Bolt Data Consulting Group
 * @description Job Scheduler logic.
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
public with sharing class BD_JobScheduler implements Schedulable
{
    // Constants
    public static final String EXECUTION_ERROR_INACTIVE_OWNER = 'Inactive owner';
    public static final String EXECUTION_ERROR_INVALID_CLASS = 'Invalid class';
    public static final Type BATCHABLE_TYPE = Type.forName( 'Database.Batchable' );
    public static final Type SCHEDULABLE_TYPE = Type.forName( 'Schedulable' );
    public static final String ASYNC_JOB_COMPLETED_STATUSES = '~Completed~Failed~Aborted~';
    public static final Integer MAX_BATCH_JOBS = 99;

    // Instance Variables
    public Id entryId = null;
    public BD_Job_Scheduler_Entry__c entry = null;
    public Type classToExecute = null;


    /**----------------------------------------------------------------------------------------------------------------
     * CONSTRUCTOR: BD_JobScheduler
     * @author Bolt Data Consulting Group
     * @param entryId The entry id for the job to run.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public BD_JobScheduler( Id entryId )
    {
        this.entryId = entryId;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: execute
     * @author Bolt Data Consulting Group
     * @param sc the SchedulableContext to run.
     * @description Starts the job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void execute( SchedulableContext sc )
    {
        start( sc.getTriggerId() );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: start
     * @author Bolt Data Consulting Group
     * @param jobId the Id of the job to run.
     * @description Runs the job and reschedules the next run if appropriate.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void start( Id jobId )
    {
        System.abortJob( jobId );

        try
        {
            this.entry =
            [
                    SELECT Name, BD_Anonymous_Code__c, BD_Async_Apex_Job_Id__c, BD_Batch_Size__c, BD_Class__c, BD_Daily_End__c,
                            BD_Daily_Start_Date_Time__c, BD_End__c, BD_Flow__c, BD_Is_Batchable__c, BD_Is_Daily__c,
                            BD_Is_Schedulable__c, BD_Number_Of_Executions__c, BD_Repeat_Interval__c, BD_Reschedule_Interval__c,
                            BD_Start__c, OwnerId, Owner.IsActive, BD_Descriptive_Name__c, BD_Job_Status__c
                    FROM BD_Job_Scheduler_Entry__c
                    WHERE Id = :entryId
            ];

            if( !this.entry.Owner.IsActive )
            {
                logExecutionError( entryId, EXECUTION_ERROR_INACTIVE_OWNER, 'Canceled' );
                return;
            }

            if( this.entry.BD_Job_Status__c == 'Complete' || this.entry.BD_Job_Status__c == 'Canceled' )
            {
                logExecutionError( entryId, 'Job canceled by user.', 'Canceled' );
                return;
            }

        } catch( QueryException e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );
            return;
        }

        if( isBeforeOrNoEndDateTime() )
        {
            if( String.isNotBlank( entry.BD_Class__c ) )
            {
                String c = entry.BD_Class__c;
                String namespacePrefix;
                String name;

                if( c.contains( '__' ) )
                {
                    namespacePrefix = c.substringBefore( '__' );
                    name = c.substringAfter( '__' );
                } else
                {
                    namespacePrefix = null;
                    name = c;
                }

                classToExecute = Test.isRunningTest() ? BATCHABLE_TYPE : Type.forName( namespacePrefix, name );

                if( classToExecute == null )
                {
                    logExecutionError( entry.Id, EXECUTION_ERROR_INVALID_CLASS, 'Canceled' );
                    return;
                } else if( !( entry.BD_Is_Batchable__c && BATCHABLE_TYPE.isAssignableFrom( classToExecute ) || entry.BD_Is_Schedulable__c && SCHEDULABLE_TYPE.isAssignableFrom( classToExecute ) ) )
                {
                    logExecutionError( entry.Id, EXECUTION_ERROR_INVALID_CLASS, 'Canceled' );
                    return;
                }
            }

            if( String.isNotBlank( entry.BD_Class__c ) || String.isNotBlank( entry.BD_Flow__c ) || String.isNotBlank( entry.BD_Anonymous_Code__c ) )
            {
                if( canStartMore() )
                {
                    executeJob();

                    if( isPositiveInteger( entry.BD_Repeat_Interval__c ) )
                    {
                        entry.BD_Start__c = Datetime.now().addMinutes( (Integer) entry.BD_Repeat_Interval__c );
                        incrementExecutions();
                        reschedule();
                    } else if( entry.BD_Is_Daily__c )
                    {
                        incrementExecutions();
                        rescheduleForTomorrow();
                    } else
                    {
                        // Run once
                        entry.BD_Job_Status__c = 'Complete';
                        incrementExecutions();
                        updateEntry();
                    }
                } else if( isPositiveInteger( entry.BD_Reschedule_Interval__c ) )
                {
                    entry.BD_Start__c = Datetime.now().addMinutes( (Integer) entry.BD_Reschedule_Interval__c );
                    reschedule();
                } else completeEntry(); // All done
            }
        } else if( entry.BD_Is_Daily__c ) rescheduleForTomorrow();
        else completeEntry(); // All doneß
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: isBeforeOrNoEndDateTime
     * @author Bolt Data Consulting Group
     * @return true if entry is before now or has no end date
     * @description Helper to determine if the job should be rescheduled.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public Boolean isBeforeOrNoEndDateTime()
    {
        return ( null == entry.BD_End__c || ( System.now() < entry.BD_End__c && ( !entry.BD_Is_Daily__c || entry.BD_Daily_End__c == null || System.now() < entry.BD_Daily_End__c ) ) );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: canStartMore
     * @author Bolt Data Consulting Group
     * @return true if entry is before now or has no end date
     * @description Helper to determine if the job should be rescheduled.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public Boolean canStartMore()
    {
        if( String.isNotBlank( entry.BD_Anonymous_Code__c ) || String.isNotBlank( entry.BD_Flow__c ) || entry.BD_Is_Schedulable__c ) return true;

        if( String.isNotBlank( entry.BD_Async_Apex_Job_Id__c ) )
        {
            AsyncApexJob jobInfo = [ SELECT Status FROM AsyncApexJob WHERE Id = :entry.BD_Async_Apex_Job_Id__c ];
            if( !ASYNC_JOB_COMPLETED_STATUSES.containsIgnoreCase( jobInfo.Status ) ) return false;
        }

        return [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE JobType = 'BatchApex' AND Status = 'Holding'
        ] < MAX_BATCH_JOBS;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: canStartMore
     * @author Bolt Data Consulting Group
     * @description Runs the job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void executeJob()
    {
        if( String.isNotBlank( entry.BD_Class__c ) )
        {
            if( entry.BD_Is_Batchable__c ) executeBatch();
            else executeSchedulable( entry.BD_Class__c );

        } else if( String.isNotBlank( entry.BD_Flow__c ) ) executeFlow( entry.BD_Flow__c );
        else if( String.isNotBlank( entry.BD_Anonymous_Code__c ) ) executeAnonymous( entry.BD_Anonymous_Code__c );
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: isPositiveInteger
     * @author Bolt Data Consulting Group
     * @param value the decimal to validate
     * @return True if the decimal is positive.
     * @description Validates the given decimal is not null and a positive value.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public Boolean isPositiveInteger( Decimal value )
    {
        return value != null && value > 0;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: executeBatch
     * @author Bolt Data Consulting Group
     * @description Runs the batch job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void executeBatch()
    {
        if( !Test.isRunningTest() )
        {
            Object o = classToExecute.newInstance();

            if( isPositiveInteger( entry.BD_Batch_Size__c ) )  entry.BD_Async_Apex_Job_Id__c = Database.executeBatch( (Database.Batchable<SObject>) o, (Integer) entry.BD_Batch_Size__c );
            else entry.BD_Async_Apex_Job_Id__c = Database.executeBatch( (Database.Batchable<SObject>) o );
        }
    }


    /**----------------------------------------------------------------------------------------------------------------
     * FUTURE METHOD: executeSchedulable
     * @author Bolt Data Consulting Group
     * @param schedulable The Schedulable to run.
     * @description Runs the schedulable job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @Future( Callout=true )
    @TestVisible private static void executeSchedulable( String schedulable )
    {
        String namespacePrefix;
        String name;

        if( schedulable.contains( '__' ) )
        {
            namespacePrefix = schedulable.substringBefore( '__' );
            name = schedulable.substringAfter( '__' );
        } else
        {
            namespacePrefix = null;
            name = schedulable;
        }

        Type t = Type.forName( namespacePrefix, name );
        if( t != null )
        {
            Object o = t.newInstance();
            ( (Schedulable) o ).execute( new BD_JobSchedulerInterface() );
        }
    }

    /**----------------------------------------------------------------------------------------------------------------
     * FUTURE METHOD: executeFlow
     * @author Bolt Data Consulting Group
     * @param flowToExecute The flow to run.
     * @description Runs the schedulable job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @Future( Callout=true )
    @TestVisible private static void executeFlow( String flowToExecute )
    {
        List<String> nameParts = flowToExecute.split( '__' );
        if( !Test.isRunningTest() )
        {
            Flow.Interview f = nameParts.size() == 1 ? Flow.Interview.createInterview( nameParts[ 0 ], new Map<String, Object>() ) : Flow.Interview.createInterview( nameParts[ 0 ], nameParts[ 1 ], new Map<String, Object>() );
            f.start();
        }
    }


    /**----------------------------------------------------------------------------------------------------------------
     * FUTURE METHOD: executeAnonymous
     * @author Bolt Data Consulting Group
     * @param body The anonymous apex code to run.
     * @description Runs the anonymous apex job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @future( callout=true )
    @TestVisible private static void executeAnonymous( String body )
    {
        String path = '/tooling/executeAnonymous/?anonymousBody=' + EncodingUtil.urlEncode( body, 'UTF-8' );
        HttpResponse res = sendHttpRequest( path, UserInfo.getSessionId() );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: incrementExecutions
     * @author Bolt Data Consulting Group
     * @description Increments the run count.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private void incrementExecutions()
    {
        entry.BD_Number_of_Executions__c = entry.BD_Number_of_Executions__c == null ? 1 : entry.BD_Number_of_Executions__c + 1;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: rescheduleForTomorrow
     * @author Bolt Data Consulting Group
     * @description Reschedules the job for the following day.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private void rescheduleForTomorrow()
    {
        if( entry.BD_End__c != null )
        {
            entry.BD_End__c = entry.BD_End__c.addDays( 1 );
        }
        entry.BD_Daily_Start_Date_Time__c = entry.BD_Daily_Start_Date_Time__c.addDays( 1 );
        entry.BD_Start__c = entry.BD_Daily_Start_Date_Time__c;
        reschedule();
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: reschedule
     * @author Bolt Data Consulting Group
     * @description Reschedules the job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void reschedule()
    {
        updateEntry();
        BD_JobScheduler.schedule( entry.Name + '_' + entry.BD_Descriptive_Name__c, entry.BD_Start__c, entry.Id );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: updateEntry
     * @author Bolt Data Consulting Group
     * @description Updates the Job Scheduler Entry record.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private void updateEntry()
    {
        update new BD_Job_Scheduler_Entry__c(
                Id = entry.Id,
                BD_Async_Apex_Job_Id__c = entry.BD_Async_Apex_Job_Id__c,
                BD_Daily_Start_Date_Time__c = entry.BD_Daily_Start_Date_Time__c,
                BD_End__c = entry.BD_End__c,
                BD_Number_Of_Executions__c = entry.BD_Number_Of_Executions__c,
                BD_Start__c = entry.BD_Start__c,
                BD_Job_Status__c = entry.BD_Job_Status__c
        );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: completeEntry
     * @author Bolt Data Consulting Group
     * @description Completes the Job Scheduler Entry record.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private void completeEntry()
    {
        update new BD_Job_Scheduler_Entry__c(
                Id = entry.Id,
                BD_Job_Status__c = 'Complete'
        );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: logExecutionError
     * @author Bolt Data Consulting Group
     * @param entryId The job scheduler entry id
     * @param error The error message to log
     * @param status The statys of the Job.
     * @description Logs an error message on the Job Scheduler Entry record.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    private static void logExecutionError( Id entryId, String error, String status )
    {
        update new BD_Job_Scheduler_Entry__c( Id = entryId, BD_Execution_Error__c = error, BD_Job_Status__c = status );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getFlows
     * @author Bolt Data Consulting Group
     * @return a list of flows
     * @description Returns a list of auto launchable flows.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public static List<Map<String, Object>> getFlows()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getFlows()...' );

        String queryString =
                'SELECT Label, ApiName, NamespacePrefix ' +
                        'FROM FlowDefinitionView ' +
                        'WHERE ProcessType = \'AutoLaunchedFlow\' ' +
                        'AND IsActive = TRUE ' +
                        'ORDER BY Label';

        String path = '/query/?q=' + EncodingUtil.urlEncode( queryString, 'UTF-8' );

        HttpResponse res = sendHttpRequest( path, getSessionId() );
        System.debug( 'HttpResponse Body=' + res.getBody() );
        Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );
        List<Object> records = (List<Object>) o.get( 'records' );
        List<Map<String, Object>> flows = new List<Map<String, Object>>();
        for( Object r : records )
        {
            Map<String, Object> m = (Map<String, Object>) r;
            flows.add(
                    new Map<String, String>
                    {
                            'value' => (String) m.get( 'ApiName' ),
                            'label' => (String) m.get( 'Label' ),
                            'NamespacePrefix' => (String) m.get( 'NamespacePrefix' )
                    }
            );
        }

        System.debug( LoggingLevel.INFO, 'EXITING getFlows()...' );
        return flows;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getApiVersion
     * @author Bolt Data Consulting Group
     * @return the API version
     * @description Looks up the current API version.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public static Double getApiVersion()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getApiVersion()...' );

        Decimal api = [ SELECT ApiVersion FROM ApexClass ORDER BY ApiVersion DESC LIMIT 1 ].ApiVersion;

        System.debug( LoggingLevel.INFO, 'EXITING getApiVersion() with api=' + api );
        return api;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getSessionId
     * @author Bolt Data Consulting Group
     * @return the current API version
     * @description Looks up the current session id.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public static String getSessionId()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getSessionId()...' );

        String session = Test.isRunningTest() ? '' : Page.BD_JobSchedulerHelper.getContent().toString().trim();

        System.debug( LoggingLevel.INFO, 'EXITING getSessionId() with Id=' + session );
        return Test.isRunningTest() ? '' : session;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: sendHttpRequest
     * @author Bolt Data Consulting Group
     * @param path The path to use
     * @param sessionId The current session id to use
     * @return the http response
     * @description Looks up the current session id.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public static HttpResponse sendHttpRequest( String path, String sessionId )
    {
        System.debug( LoggingLevel.INFO, 'ENTERED sendHttpRequest()...' );

        Double apiVersion = getApiVersion();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint( Url.getOrgDomainUrl().toExternalForm() + '/services/data/v' + apiVersion + path );
        req.setMethod( 'GET' );
        req.setHeader( 'Authorization', 'Bearer ' + sessionId );

        HttpResponse rsp = null;
        if( !Test.isRunningTest() ) rsp = h.send( req );
        else
        {
            rsp = new HttpResponse();
            rsp.setBody( '{"totalSize":1,"done":true,"records":[{"attributes":{"type":"FlowDefinitionView","url":"/services/data/v61.0/sobjects/FlowDefinitionView/3004o0000009b10AAA"},"Label":"Test Flow","ApiName":"Test_Flow","NamespacePrefix":null}]}' );
        }

        System.debug( LoggingLevel.INFO, 'EXITING sendHttpRequest()...' );
        return rsp;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: schedule
     * @author Bolt Data Consulting Group
     * @param jobName A descriptive name of the job to schedule
     * @param startDatetime The start date time for the job
     * @param entryId The Job Schedule Entry Id
     * @return the scheduled job id (Cron Trigger Id)
     * @description Calls System.schedule to schedule a new job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public static String schedule( String jobName, Datetime startDatetime, Id entryId )
    {
        return System.schedule( jobName, startDatetime.format( 's m H d M \'?\' yyyy' ), new BD_JobScheduler( entryId ) );
    }
}
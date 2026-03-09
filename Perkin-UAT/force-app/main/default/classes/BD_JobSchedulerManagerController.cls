/*********************************************************************************************************************
 * CLASS: BD_JobSchedulerManagerController
 * @author Bolt Data Consulting Group
 * @description Controller for the Job Scheduler Manager UI.
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
public with sharing class BD_JobSchedulerManagerController
{
    public class JobSchedulerException extends Exception {}

    // Common
    public BD_Job_Scheduler_Entry__c[] jobs { get; set; }
    public List<SelectOption> jobTypeList { get; set; }
    public List<SelectOption> schedTypeList { get; set; }
    public String selectedJobType { get; set;}
    public String selectedSchedType { get; set;}
    public Datetime startDateTime { get; set; }
    public Datetime endDateTime { get; set; }
    public Integer repeatInterval { get; set; }
    public Boolean runDaily { get; set; }
    public Boolean showRecurringSection { get; set; }
    public Boolean showScheduledSection { get; set; }
    public Boolean showFlowFields { get; set; }
    public Boolean showClassFields { get; set; }
    public Boolean showApexFields { get; set; }
    public Boolean showRunFields { get; set; }
    public Boolean saveBtnActive { get; set; }

    // Flow
    public String selectedFlow { get; set;}

    // Class
    public List<SelectOption> classTypeList { get; set; }
    public String selectedClassType { get; set;}
    public String selectedClass { get; set;}
    public Boolean showBatchableSection { get; set; }
    public Integer batchSize { get; set; }
    public Integer rescheduleInterval { get; set; }

    // Anon Apex
    public String anonApex { get; set;}


    /**----------------------------------------------------------------------------------------------------------------
     * CONSTRUCTOR: BD_JobSchedulerManagerController
     * @author Bolt Data Consulting Group
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public BD_JobSchedulerManagerController()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED BD_JobSchedulerManagerController()...' );

        getJobTypeList();
        getSchedTypeList();
        getClassTypeList();
        init();

        System.debug( LoggingLevel.INFO, 'EXITING BD_JobSchedulerManagerController()...' );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: init
     * @author Bolt Data Consulting Group
     * @description Initializes the controller.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void init()
    {
        saveBtnActive = false;

        getJobs();

        runDaily = false;
        repeatInterval = null;
        endDateTime = null;

        // Round to future half hour mark
        Datetime now = Datetime.now();
        if( now.minute() <= 30 ) now = now.addMinutes( 30 - now.minute() );
        else now = now.addMinutes( 60 - now.minute() );
        startDateTime = now;

        showRunFields = false;
        showFlowFields = false;
        showClassFields = false;
        showApexFields = false;

        showRecurringSection = false;
        showScheduledSection = false;

        showBatchableSection = false;
        batchSize = 200;
        rescheduleInterval = 5;

        selectedJobType = 'none';
        selectedSchedType = 'none';
        selectedFlow = null;
        selectedClass = null;
        anonApex = null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getJobs
     * @author Bolt Data Consulting Group
     * @return a list of BD_Job_Scheduler_Entry__c records
     * @description Queries the active jobs.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public BD_Job_Scheduler_Entry__c[] getJobs()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getJobs()...' );

        try
        {
            jobs = [
                SELECT Id, Name, BD_Anonymous_Code__c, BD_Async_Apex_Job_Id__c, BD_Batch_Size__c, BD_Class__c,
                        BD_Daily_End__c, BD_Daily_Start_Date_Time__c, BD_End__c, BD_Flow__c, BD_Is_Batchable__c,
                        BD_Is_Daily__c, BD_Is_Schedulable__c, BD_Number_Of_Executions__c, BD_Repeat_Interval__c,
                        BD_Reschedule_Interval__c, BD_Start__c, BD_Execution_Error__c, BD_Descriptive_Name__c,
                        LastModifiedDate, LastModifiedBy.Name, BD_Job_Status__c
                FROM BD_Job_Scheduler_Entry__c
                WHERE BD_Job_Status__c = 'Active'
                    OR LastModifiedDate = LAST_N_DAYS:5
                ORDER BY BD_Job_Status__c, Name
            ];

        } catch( Exception e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );
        }

        if( jobs == null ) jobs = new BD_Job_Scheduler_Entry__c[]{};

        System.debug( LoggingLevel.INFO, 'EXITING getJobs()...' );
        return jobs;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getJobTypeList
     * @author Bolt Data Consulting Group
     * @description Builds a list of job types.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void getJobTypeList()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getJobTypeList()...' );

        List<SelectOption> values = new List<SelectOption>();
        values.add( new SelectOption( 'none', 'Select a Job Type...' ) );
        values.add( new SelectOption( 'flow', 'Schedule a Flow' ) );
        values.add( new SelectOption( 'class', 'Schedule a Class' ) );
        values.add( new SelectOption( 'apex', 'Schedule Anonymous Apex' ) );

        jobTypeList = values;

        System.debug( LoggingLevel.INFO, 'EXITING getJobTypeList() with: ' + values );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getSchedTypeList
     * @author Bolt Data Consulting Group
     * @description Builds a list of schedule types.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void getSchedTypeList()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getSchedTypeList()...' );

        List<SelectOption> values = new List<SelectOption>();
        values.add( new SelectOption( 'none', 'Select a Schedule Type...' ) );
        values.add( new SelectOption( 'recurring', 'Recurring: Run every ## minutes' ) );
        values.add( new SelectOption( 'scheduled', 'Scheduled: Run daily at a specified time' ) );

        schedTypeList = values;

        System.debug( LoggingLevel.INFO, 'EXITING getSchedTypeList() with: ' + values );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getClassTypeList
     * @author Bolt Data Consulting Group
     * @description Builds a list of class types.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void getClassTypeList()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getClassTypeList()...' );

        List<SelectOption> values = new List<SelectOption>();
        values.add( new SelectOption( 'none', 'Select a Class Type...' ) );
        values.add( new SelectOption( 'batchable', 'Batchable: Implements the Database.Batchable interface' ) );
        values.add( new SelectOption( 'schedulable', 'Schedulable: Implements the Schedulable interface' ) );

        classTypeList = values;

        System.debug( LoggingLevel.INFO, 'EXITING getClassTypeList() with: ' + values );
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: parseJobType
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Sets component visibility based on selected job type.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference parseJobType()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED parseJobType() with selectedJobType=' + selectedJobType );

        if( selectedJobType == 'none' )
        {
            showRunFields = false;

            showFlowFields = false;
            showClassFields = false;
            showApexFields = false;

        } else if( selectedJobType == 'flow' )
        {
            showRunFields = true;

            showFlowFields = true;
            showClassFields = false;
            showApexFields = false;

        } else if( selectedJobType == 'class' )
        {
            showRunFields = true;

            showFlowFields = false;
            showClassFields = true;
            showApexFields = false;

        } else if( selectedJobType == 'apex' )
        {
            showRunFields = true;

            showFlowFields = false;
            showClassFields = false;
            showApexFields = true;
        }

        // Enable the Save Button
        if( selectedJobType != 'none' && selectedSchedType != 'none' ) saveBtnActive = true;
        else saveBtnActive = false;

        System.debug( LoggingLevel.INFO, 'EXITING parseJobType()...' );
        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: parseSchedType
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Sets component visibility based on selected schedule type.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference parseSchedType()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED parseSchedType() with selectedSchedType=' + selectedSchedType );

        if( selectedSchedType == 'none' )
        {
            runDaily = false;
            showRecurringSection = false;
            showScheduledSection = false;

        } else if( selectedSchedType == 'recurring' )
        {
            runDaily = false;
            showRecurringSection = true;
            showScheduledSection = false;

        } else if( selectedSchedType == 'scheduled' )
        {
            runDaily = true;
            showRecurringSection = false;
            showScheduledSection = true;
        }

        // Enable the Save Button
        if( selectedJobType != 'none' && selectedSchedType != 'none' ) saveBtnActive = true;
        else saveBtnActive = false;

        System.debug( LoggingLevel.INFO, 'EXITING parseSchedType()...' );
        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: parseClassType
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Sets component visibility based on selected class type.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference parseClassType()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED parseClassType() with selectedJobType=' + selectedJobType + ' and selectedClassType=' + selectedClassType );

        if( selectedJobType == 'class' )
        {
            if( selectedClassType == 'none' )
            {
                showBatchableSection = false;

            } else if( selectedClassType == 'batchable' )
            {
                showBatchableSection = true;

            } else if( selectedClassType == 'schedulable' )
            {
                showBatchableSection = false;
            }

        } else
        {
            showBatchableSection = false;
        }

        System.debug( LoggingLevel.INFO, 'EXITING parseClassType() with showBatchableSection=' + showBatchableSection );
        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getFlowList
     * @author Bolt Data Consulting Group
     * @return list of Select Options
     * @description Builds a list of Select Options for each Flow that can be scheduled.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public List<SelectOption> getFlowList()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getFlowList...' );

        String msg = null;
        ApexPages.Message apm = null;
        List<SelectOption> values = new List<SelectOption>();

        try
        {
            List<Map<String, Object>> flows = BD_JobScheduler.getFlows();
            values.add( new SelectOption( '', 'Select a Flow' ) );

            for( Map<String, Object> flowMap : flows )
            {
                String s = flowMap.get( 'label' ) + ' (' + flowMap.get( 'value' ) + ')';
                values.add( new SelectOption( flowMap.get( 'value' ).toString(), s ) );
            }

        } catch( Exception e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );

            msg = 'There was an error getting the list of flows -- ' + e.getMessage();
            apm = new ApexPages.Message( ApexPages.Severity.ERROR, msg );
            ApexPages.addMessage( apm );
        }

        System.debug( LoggingLevel.INFO, 'EXITING getFlowList with ' + values.size() + ' flows...' );
        return values;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: scheduleJob
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Schedules the job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference scheduleJob()
    {
        if( selectedJobType == 'flow' ) scheduleFlowJob();
        else if( selectedJobType == 'class' ) scheduleClassJob();
        else if( selectedJobType == 'apex' ) scheduleAnonApexJob();

        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: scheduleFlowJob
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Schedules the Flow job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference scheduleFlowJob()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED scheduleFlowJob...' );

        String msg = null;
        ApexPages.Message apm = null;

        try
        {
            // Create the Entry Record
            BD_Job_Scheduler_Entry__c job = new BD_Job_Scheduler_Entry__c();
            job.BD_Job_Status__c = 'Active';
            job.BD_Flow__c = selectedFlow;
            job.BD_Start__c = startDateTime;
            job.BD_Daily_Start_Date_Time__c = startDateTime;

            if( String.isBlank( job.BD_Flow__c ) ) throw new JobSchedulerException( 'You must select a flow to schedule.' );
            if( job.BD_Start__c == null || job.BD_Start__c < Datetime.now() ) throw new JobSchedulerException( 'Start Date/Time must be in the future.' );

            if( runDaily )
            {
                job.BD_Is_Daily__c = true;
                job.BD_Daily_End__c = endDateTime != null ? endDateTime.date() : null;

            } else
            {
                System.debug( '>>>endDateTime=' + endDateTime );
                job.BD_Repeat_Interval__c = repeatInterval;
                job.BD_End__c = endDateTime;

                if( job.BD_Repeat_Interval__c == null ) throw new JobSchedulerException( 'Repeat Interval is required.' );
            }

            // Build Descriptive Name
            String jobName = 'FLOW_' + selectedFlow;
            job.BD_Descriptive_Name__c = jobName.left( 69 ) + '_' + Datetime.now().format( 'yyyy-MM-dd' );

            // Insert the Entry Job
            insert job;
            job = [
                    SELECT Id, Name, BD_Descriptive_Name__c
                    FROM BD_Job_Scheduler_Entry__c
                    WHERE Id = :job.Id
            ];

            // Schedule the Job
            BD_JobScheduler.schedule( job.Name + '_' + job.BD_Descriptive_Name__c, startDateTime, job.Id );

            msg = 'Scheduled Job for ' + selectedFlow + ' has been created!';
            apm = new ApexPages.Message( ApexPages.Severity.CONFIRM, msg );
            ApexPages.addMessage( apm );

            // Reset the fields
            init();

        } catch( Exception e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );

            msg = 'There was an error scheduling the job -- ' + e.getMessage() + ', line=' + e.getLineNumber();
            apm = new ApexPages.Message( ApexPages.Severity.ERROR, msg );
            ApexPages.addMessage( apm );
        }

        System.debug( LoggingLevel.INFO, 'EXITING scheduleFlowJob...' );
        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: scheduleClassJob
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Schedules the Class job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference scheduleClassJob()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED scheduleClassJob...' );

        String msg = null;
        ApexPages.Message apm = null;

        try
        {
            // Create the Entry Record
            BD_Job_Scheduler_Entry__c job = new BD_Job_Scheduler_Entry__c();
            job.BD_Job_Status__c = 'Active';
            job.BD_Class__c = selectedClass;
            job.BD_Start__c = startDateTime;
            job.BD_Daily_Start_Date_Time__c = startDateTime;

            if( String.isBlank( job.BD_Class__c ) ) throw new JobSchedulerException( 'You must enter a class to schedule.' );
            if( job.BD_Start__c == null || job.BD_Start__c < Datetime.now() ) throw new JobSchedulerException( 'Start Date/Time must be in the future.' );

            Type t = null;
            Object o = null;
            String namespacePrefix = null;
            String name = null;

            if( selectedClass.contains( '__' ) )
            {
                namespacePrefix = selectedClass.substringBefore( '__' );
                name = selectedClass.substringAfter( '__' );
            } else
            {
                namespacePrefix = null;
                name = selectedClass;
            }

            t = Type.forName( namespacePrefix, name );

            // Is there a no-arg constructor?
            o = t.newInstance();

            if( selectedClassType == 'batchable' )
            {
                if( !BD_JobScheduler.BATCHABLE_TYPE.isAssignableFrom( t ) ) throw new JobSchedulerException( 'Class not Batchable' );
                job.BD_Is_Batchable__c = true;
                job.BD_Batch_Size__c = batchSize;
                job.BD_Reschedule_Interval__c = rescheduleInterval;

            } else if( selectedClassType == 'schedulable' )
            {
                if( !BD_JobScheduler.SCHEDULABLE_TYPE.isAssignableFrom( t ) ) throw new JobSchedulerException( 'Class not Schedulable' );
                job.BD_Is_Schedulable__c = true;
            }

            if( runDaily )
            {
                job.BD_Is_Daily__c = true;
                job.BD_Daily_End__c = endDateTime != null ? endDateTime.date() : null;

            } else
            {
                job.BD_Repeat_Interval__c = repeatInterval;
                job.BD_End__c = endDateTime;

                if( job.BD_Repeat_Interval__c == null ) throw new JobSchedulerException( 'Repeat Interval is required.' );
            }

            // Build Descriptive Name
            String jobName = 'CLASS_' + selectedClass;
            job.BD_Descriptive_Name__c = jobName.left( 69 ) + '_' + Datetime.now().format( 'yyyy-MM-dd' );

            // Insert the Entry Job
            insert job;
            job = [
                    SELECT Id, Name, BD_Descriptive_Name__c
                    FROM BD_Job_Scheduler_Entry__c
                    WHERE Id = :job.Id
            ];

            // Schedule the Job
            BD_JobScheduler.schedule( job.Name + '_' + job.BD_Descriptive_Name__c, startDateTime, job.Id );

            msg = 'Scheduled Job for ' + selectedClass + ' has been created!';
            apm = new ApexPages.Message( ApexPages.Severity.CONFIRM, msg );
            ApexPages.addMessage( apm );

            // Reset the fields
            init();

        } catch( Exception e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );

            msg = 'There was an error scheduling the job -- ' + e.getMessage();
            apm = new ApexPages.Message( ApexPages.Severity.ERROR, msg );
            ApexPages.addMessage( apm );
        }

        System.debug( LoggingLevel.INFO, 'EXITING scheduleClassJob...' );
        return null;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: scheduleAnonApexJob
     * @author Bolt Data Consulting Group
     * @return the page reference
     * @description Schedules the Anonymous Apex job.
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public PageReference scheduleAnonApexJob()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED scheduleAnonApexJob...' );

        String msg = null;
        ApexPages.Message apm = null;

        try
        {
            // Create the Entry Record
            BD_Job_Scheduler_Entry__c job = new BD_Job_Scheduler_Entry__c();
            job.BD_Job_Status__c = 'Active';
            job.BD_Anonymous_Code__c = anonApex;
            job.BD_Start__c = startDateTime;
            job.BD_Daily_Start_Date_Time__c = startDateTime;

            if( String.isBlank( job.BD_Anonymous_Code__c ) ) throw new JobSchedulerException( 'You must enter anonymous apex to save job.' );
            if( job.BD_Start__c == null || job.BD_Start__c < Datetime.now() ) throw new JobSchedulerException( 'Start Date/Time must be in the future.' );

            if( runDaily )
            {
                job.BD_Is_Daily__c = true;
                job.BD_Daily_End__c = endDateTime != null ? endDateTime.date() : null;

            } else
            {
                job.BD_Repeat_Interval__c = repeatInterval;
                job.BD_End__c = endDateTime;

                if( job.BD_Repeat_Interval__c == null ) throw new JobSchedulerException( 'Repeat Interval is required.' );
            }

            // Build Descriptive Name
            String jobName = 'ANONAPEX_' + anonApex.left( 100 ).replaceAll( '\n', ' ' ).normalizeSpace();
            job.BD_Descriptive_Name__c = jobName.left( 69 ) + '_' + Datetime.now().format( 'yyyy-MM-dd' );

            // Insert the Entry Job
            insert job;
            job = [
                    SELECT Id, Name, BD_Descriptive_Name__c
                    FROM BD_Job_Scheduler_Entry__c
                    WHERE Id = :job.Id
            ];

            // Schedule the Job
            BD_JobScheduler.schedule( job.Name + '_' + job.BD_Descriptive_Name__c, startDateTime, job.Id );

            msg = 'Scheduled Job for ' + selectedFlow + ' has been created!';
            apm = new ApexPages.Message( ApexPages.Severity.CONFIRM, msg );
            ApexPages.addMessage( apm );

            // Reset the fields
            init();

        } catch( Exception e )
        {
            System.debug( 'Exception caught - Message=' + e.getMessage() + ', Line=' + e.getLineNumber() + ', Stack=' + e.getStackTraceString() );

            msg = 'There was an error scheduling the job -- ' + e.getMessage() + ', line=' + e.getLineNumber();
            apm = new ApexPages.Message( ApexPages.Severity.ERROR, msg );
            ApexPages.addMessage( apm );
        }

        System.debug( LoggingLevel.INFO, 'EXITING scheduleAnonApexJob...' );
        return null;
    }

}
/*********************************************************************************************************************
* CLASS: BD_Batch_OrgLimitChecker
* @author Bolt Data Consulting Group
* @description Batch job to check on org limits and send a notification if they reach a threshold.
*
* -----CHANGE LOG-----
* 2025.09.03 - ives - Created class.
*********************************************************************************************************************/
public without sharing class BD_Batch_OrgLimitChecker implements Database.Batchable<SObject>, Database.AllowsCallouts
{
    private static final String DATE_FORMAT = 'yyyy-MM-dd hh:mm:ss a z';
    private Map<String, Id> orgWideEmail2IdMap = new Map<String, Id>();

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: start
     * @author Bolt Data Consulting Group
     * @param bc the BatchableContext to run.
     * @return The QueryLocator for the batch job.
     * @description Starts the batch job, query not used.
     *
     * -----CHANGE LOG-----
     * 2025.09.03 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public Database.QueryLocator start( Database.BatchableContext bc )
    {
        System.debug( LoggingLevel.INFO, 'STARTING BD_Batch_OrgLimitChecker batch...' );
        return Database.getQueryLocator( 'SELECT Id FROM User LIMIT 1' ); // Bogus query (not used)...
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: execute
     * @author Bolt Data Consulting Group
     * @param bc the BatchableContext to run.
     * @param scope the BD_Org_Limit_Check__mdt records to alert on.
     * @description Runs the batch logic.
     *
     * -----CHANGE LOG-----
     * 2025.09.03 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void execute( Database.BatchableContext bc, List<SObject> scope )
    {
        System.debug( LoggingLevel.INFO, 'ENTERED BD_Batch_OrgLimitChecker.execute()...' );

        runBatch();

        System.debug( LoggingLevel.INFO, 'EXITING BD_Batch_OrgLimitChecker.execute()...' );
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: finish
     * @author Bolt Data Consulting Group
     * @param bc the BatchableContext to run.
     * @description The end of the fun.
     *
     * -----CHANGE LOG-----
     * 2025.09.03 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public void finish( Database.BatchableContext bc )
    {
        System.debug( LoggingLevel.INFO, 'FINISHED BD_Batch_OrgLimitChecker batch...' );
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: runBatch
     * @author Bolt Data Consulting Group
     * @description Runs the batch, sending alerts for any Org Limits that have exceeded the threshold set in the metadata.
     *
     * -----CHANGE LOG-----
     * 2025.09.03 - ives - Created method.
     * 2025.09.16 - ives - Added support for Active flag.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private void runBatch()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED runBatch()...' );

        BD_Org_Limit_Check__mdt[] limitsMetaDataRecs = [
                SELECT Id, DeveloperName, BD_Limit_Name__c, BD_Reply_To_Email_Address__c, BD_Send_As_Org_Email_Address__c,
                        BD_Error_Threshold__c, BD_Error_Notification_List__c, BD_Warning_Threshold__c,
                        BD_Warning_Notification_List__c, BD_Info_Threshold__c, BD_Info_Notification_List__c
                FROM BD_Org_Limit_Check__mdt
                WHERE BD_Active__c = TRUE
        ];

        // Organize the Limit Metadata records
        Map<String, BD_Org_Limit_Check__mdt> limitMDMap = new Map<String, BD_Org_Limit_Check__mdt>();
        for( BD_Org_Limit_Check__mdt rec : limitsMetaDataRecs ) limitMDMap.put( rec.BD_Limit_Name__c, rec );
        if( limitMDMap == null || limitMDMap.isEmpty() )
        {
            System.debug( 'Exiting execute() early, no BD_Org_Limit_Check__mdt records found.' );
            return;
        }

        // Get current API version for the Org
        String apiVersion = getCurrentApiVersion();

        // Build the Request message
        HttpRequest req = new HttpRequest();
        String endpoint = System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/v' + apiVersion + '/limits';
        System.debug( 'Limits Endpoint URL=' + endpoint );
        req.setEndpoint( endpoint );
        req.setMethod( 'GET' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        // Query the API Limits
        Http http = new Http();
        HttpResponse rsp = null;
        if( Test.isRunningTest() )
        {
            rsp = new HttpResponse();
            rsp.setStatusCode( 200 );
            rsp.setStatus( 'OK' );
            rsp.setHeader( 'Content-Type', 'application/json' );
            rsp.setBody( '{"AnalyticsExternalDataSizeMB":{"Max":40960,"Remaining":40960},"CdpAiInferenceApiMonthlyLimit":{"Max":500000000,"Remaining":500000000},"ConcurrentAsyncGetReportInstances":{"Max":200,"Remaining":199},"UnitTestLimit":{"Max":100,"Remaining":75}}' );

        } else  rsp = http.send( req );
        System.debug( 'Limits Response=' + rsp + ' - Rsp Body=' + rsp.getBody() );

        if( rsp.getStatusCode() == 200 )
        {
            // Put the actual limit values into a map
            Map<String, Object> limitsActualsMap = (Map<String, Object>) JSON.deserializeUntyped( rsp.getBody() );
            System.debug( 'limitsActualsMap=' + limitsActualsMap );

            // Process the limit records
            List<BD_Invocable_SendEmail.SendEmailRequest> reqs = new List<BD_Invocable_SendEmail.SendEmailRequest>();
            for( String limitName : limitMDMap.keySet() )
            {
                BD_Org_Limit_Check__mdt meta = limitMDMap.get( limitName );
                if( limitsActualsMap.containsKey( limitName ) )
                {
                    Map<String, Object> limitValMap = ( Map<String, Object> ) limitsActualsMap.get( limitName );
                    System.debug( 'LimitName=' + limitName + ' - Data=' + limitValMap );

                    Decimal max = (Decimal) limitValMap.get( 'Max' );
                    Decimal remaining = (Decimal) limitValMap.get( 'Remaining' );
                    Decimal used = max - remaining;
                    Decimal percentUsed = (used / max) * 100;
                    percentUsed = percentUsed.setScale( 0 );

                    Decimal maxErrorThreshold = meta.BD_Error_Threshold__c;
                    Decimal maxWarningThreshold = meta.BD_Warning_Threshold__c;
                    Decimal maxInfoThreshold = meta.BD_Info_Threshold__c;
                    System.debug( 'used=' + used + ', percentUsed=' + percentUsed + ', error threshold=' + maxErrorThreshold + ', warning threshold=' + maxWarningThreshold + ', info threshold=' + maxInfoThreshold );
                    if( percentUsed >= maxErrorThreshold )
                    {
                        // ---ERROR ALERT
                        System.debug( 'ERROR ALERT for ' + limitName + ': ' + percentUsed + ' exceeds threshold of ' + maxErrorThreshold );
                        reqs.add( buildEmailReq( limitName, meta, 'ERROR', percentUsed, remaining, max ) );

                    } else if( maxWarningThreshold != null && percentUsed >= maxWarningThreshold )
                    {
                        // ---WARNING ALERT
                        System.debug( 'WARNING ALERT for ' + limitName + ': ' + percentUsed + ' exceeds threshold of ' + maxWarningThreshold );
                        reqs.add( buildEmailReq( limitName, meta, 'WARNING', percentUsed, remaining, max ) );

                    } else if( maxInfoThreshold != null && percentUsed >= maxInfoThreshold )
                    {
                        // ---INFO ALERT
                        System.debug( 'INFO ALERT for ' + limitName + ': ' + percentUsed + ' exceeds threshold of ' + maxInfoThreshold );
                        reqs.add( buildEmailReq( limitName, meta, 'INFO', percentUsed, remaining, max ) );
                    }

                } else System.debug( 'No limit found for BD_Org_Limit_Check__mdt.BD_Limit_Name__c=' + limitName );
            }

            // Send the email alerts!
            if( !reqs.isEmpty() ) BD_Invocable_SendEmail.sendEmail( reqs );

        } else System.debug( 'Error: ' + rsp.getStatusCode() + ' ' + rsp.getBody() );

        System.debug( LoggingLevel.INFO, 'EXITING runBatch()...' );
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: buildEmailReq
     * @author Bolt Data Consulting Group
     * @param limitName The name of the Limit to alert on.
     * @param meta The Org Limit Check metadata record.
     * @param alertType The alert type: ERROR, WARNING, INFO.
     * @param percentUsed The percent of the limit used.
     * @param  remaining The amount of the limit not used.
     * @param max The maximum amount of the limit.
     * @return The Send Email Request message.
     * @description Builds a SendEmailRequest message.
     *
     * -----CHANGE LOG-----
     * 2025.09.08 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    private BD_Invocable_SendEmail.SendEmailRequest buildEmailReq( String limitName, BD_Org_Limit_Check__mdt meta, String alertType, Decimal percentUsed, Decimal remaining, Decimal max )
    {
        System.debug( LoggingLevel.INFO, 'ENTERED buildEmailReq() for ' + limitName + ':' + alertType );

        // Look up the Org Wide Email address to use as the Sender Email.
        if( String.isNotBlank( meta.BD_Send_As_Org_Email_Address__c ) && !orgWideEmail2IdMap.containsKey( meta.BD_Send_As_Org_Email_Address__c ) )
        {
            OrgWideEmailAddress orgEmail = null;
            try
            {
                orgEmail = [
                        SELECT Id
                        FROM OrgWideEmailAddress
                        WHERE Address = :meta.BD_Send_As_Org_Email_Address__c
                        LIMIT 1
                ];
                orgWideEmail2IdMap.put( meta.BD_Send_As_Org_Email_Address__c , orgEmail.Id );

            } catch( Exception e )
            {
                System.debug( 'Error caught looking up org wide email for "' + meta.BD_Send_As_Org_Email_Address__c + '" - ' + e );
            }
        }

        // Build the email request wrapper
        BD_Invocable_SendEmail.SendEmailRequest req = new BD_Invocable_SendEmail.SendEmailRequest();
        if( String.isNotBlank( meta.BD_Send_As_Org_Email_Address__c ) ) req.orgWideEmailId = orgWideEmail2IdMap.get( meta.BD_Send_As_Org_Email_Address__c );
        req.replyToEmail = meta.BD_Reply_To_Email_Address__c;
        if( alertType.equals( 'INFO' ) ) req.toAddresses = meta.BD_Info_Notification_List__c;
        else if( alertType.equals( 'WARNING' ) ) req.toAddresses = meta.BD_Warning_Notification_List__c;
        else req.toAddresses = meta.BD_Error_Notification_List__c;
        req.subject = alertType + ' - Salesforce Org Limit "' + limitName + '" has reached ' + percentUsed + '% capacity.';
        req.plainTextBody = 'An Org Limit has reached a designated threshold. Please take appropriate action.'
            + '\n\nLimit Name: ' + limitName
            + '\nOrg: ' + UserInfo.getOrganizationName() + ' / ' + UserInfo.getOrganizationId()
            + '\nDatetime: ' + Datetime.now().format( DATE_FORMAT ) + ' (' + Datetime.now().formatGmt( DATE_FORMAT ) + ')'
            + '\nPercent Used: ' + percentUsed + '%'
            + '\nRemaining: ' + remaining
            + '\nMaximum: ' + max
            + '\n\nThe monitored Org Limits and threshold alerts are configured in the Org Limit Check (BD_Org_Limit_Check__mdt) Custom Metadata.';

        System.debug( LoggingLevel.INFO, 'EXITING buildEmailReq with ' + req );
        return req;
    }

    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getCurrentApiVersion
     * @author Bolt Data Consulting Group
     * @return The current API version for REST API calls.
     * @description Makes a REST call the data API to get the current API Version supported for the Org.
     *
     * -----CHANGE LOG-----
     * 2025.09.03 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @TestVisible private String getCurrentApiVersion()
    {
        System.debug( LoggingLevel.INFO, 'ENTERED getCurrentApiVersion()...' );

        String apiVersion = '63';
        try
        {
            HttpRequest req = new HttpRequest();
            String endpoint = System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/';
            System.debug( 'Data Endpoint URL=' + endpoint );
            req.setEndpoint( endpoint );
            req.setMethod( 'GET' );
            req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

            Http http = new Http();
            HttpResponse rsp = null;
            if( Test.isRunningTest() )
            {
                rsp = new HttpResponse();
                rsp.setStatusCode( 200 );
                rsp.setStatus( 'OK' );
                rsp.setHeader( 'Content-Type', 'application/json' );
                rsp.setBody( '{"label":"Summer \'14","url":"/services/data/v31.0","version":"31.0"},{"label":"Winter \'15","url":"/services/data/v32.0","version":"32.0"},{"label":"Spring \'15","url":"/services/data/v33.0","version":"33.0"},{"label":"Summer \'15","url":"/services/data/v34.0","version":"34.0"},{"label":"Winter \'16","url":"/services/data/v35.0","version":"35.0"},{"label":"Spring \'16","url":"/services/data/v36.0","version":"36.0"},{"label":"Summer \'16","url":"/services/data/v37.0","version":"37.0"},{"label":"Winter \'17","url":"/services/data/v38.0","version":"38.0"},{"label":"Spring \'17","url":"/services/data/v39.0","version":"39.0"},{"label":"Summer \'17","url":"/services/data/v40.0","version":"40.0"},{"label":"Winter \'18","url":"/services/data/v41.0","version":"41.0"},{"label":"Spring ’18","url":"/services/data/v42.0","version":"42.0"},{"label":"Summer \'18","url":"/services/data/v43.0","version":"43.0"},{"label":"Winter \'19","url":"/services/data/v44.0","version":"44.0"},{"label":"Spring \'19","url":"/services/data/v45.0","version":"45.0"},{"label":"Summer \'19","url":"/services/data/v46.0","version":"46.0"},{"label":"Winter \'20","url":"/services/data/v47.0","version":"47.0"},{"label":"Spring \'20","url":"/services/data/v48.0","version":"48.0"},{"label":"Summer \'20","url":"/services/data/v49.0","version":"49.0"},{"label":"Winter \'21","url":"/services/data/v50.0","version":"50.0"},{"label":"Spring \'21","url":"/services/data/v51.0","version":"51.0"},{"label":"Summer \'21","url":"/services/data/v52.0","version":"52.0"},{"label":"Winter \'22","url":"/services/data/v53.0","version":"53.0"},{"label":"Spring \'22","url":"/services/data/v54.0","version":"54.0"},{"label":"Summer \'22","url":"/services/data/v55.0","version":"55.0"},{"label":"Winter \'23","url":"/services/data/v56.0","version":"56.0"},{"label":"Spring \'23","url":"/services/data/v57.0","version":"57.0"},{"label":"Summer \'23","url":"/services/data/v58.0","version":"58.0"},{"label":"Winter \'24","url":"/services/data/v59.0","version":"59.0"},{"label":"Spring \'24","url":"/services/data/v60.0","version":"60.0"},{"label":"Summer \'24","url":"/services/data/v61.0","version":"61.0"},{"label":"Winter \'25","url":"/services/data/v62.0","version":"62.0"},{"label":"Spring \'25","url":"/services/data/v63.0","version":"63.0"},{"label":"Summer \'25","url":"/services/data/v64.0","version":"64.0"},{"label":"Winter \'26","url":"/services/data/v65.0","version":"65.0"}' );

            } else
            {
                rsp = http.send( req );
            }
            System.debug( 'Response=' + rsp + ' - Rsp Body=' + rsp.getBody() );

            if( rsp.getStatusCode() == 200 )
            {
                List<Object> versions = (List<Object>) JSON.deserializeUntyped( rsp.getBody() );
                if( !versions.isEmpty() )
                {
                    Map<String, Object> latest = (Map<String, Object>) versions[ versions.size() - 1 ];
                    apiVersion = (String) latest.get( 'version' );
                }

            } else System.debug( 'Error retrieving API versions: ' + rsp.getStatusCode() + ' ' + rsp.getBody() );

        } catch( Exception e )
        {
            System.debug( LoggingLevel.ERROR, 'Error retrieving API versions - msg=' + e.getMessage() + ', line=' + e.getLineNumber() + ', stack=' + e.getStackTraceString() );
        }

        System.debug( LoggingLevel.INFO, 'EXITING getCurrentApiVersion() with API Version=' + apiVersion );
        return apiVersion;
    }
}
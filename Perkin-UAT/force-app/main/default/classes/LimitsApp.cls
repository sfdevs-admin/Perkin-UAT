public with sharing class LimitsApp {
    
    @AuraEnabled
    public static void scheduleAlert(){ 
        String everyThirtyMinsCron = '0 0 * * * ?';
        String jobName = 'Limits_App_Hourly_Job';
        LimitsAppScheduler job = new LimitsAppScheduler();
        if(!Test.isRunningTest()){
            System.schedule(jobName, everyThirtyMinsCron, job);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getLimitsRecordId() {
        String limitsRecordId;
        try {
            limitsRecordId = [SELECT Id FROM Limit_LimitsApp__c WHERE Latest__c = true].Id;
        } catch(QueryException e) {
            limitsRecordId = null; // set to null if there is no matching record
            // Log the error message for debugging purposes
            System.debug('Error querying LimitsApp record: ' + e.getMessage());
        }
        return limitsRecordId;
    }
    
    @AuraEnabled
    public static String getLimitsRecordIdOnClick() {
        String limitsRecordId;
        try {
            limitsRecordId = [SELECT Id FROM Limit_LimitsApp__c WHERE Latest__c = true].Id;
        } catch(QueryException e) {
            limitsRecordId = null; // set to null if there is no matching record
            // Log the error message for debugging purposes
            System.debug('Error querying LimitsApp record: ' + e.getMessage());
        }
        return limitsRecordId;
    }
    
    
    
    @future(callout=true) 
    public static void getLimits(){       
        List<String> limitsList = new List<String>{
            'SingleEmail',
                'StreamingApiConcurrentClients',
                'AnalyticsExternalDataSizeMB',
                'ConcurrentAsyncGetReportInstances',
                'ConcurrentSyncReportRuns',
                'HourlyAsyncReportRuns',
                'HourlySyncReportRuns',
                'HourlyDashboardRefreshes',
                'HourlyDashboardResults',
                'HourlyDashboardStatuses',
                'MassEmail',
                'DailyApiRequests',
                'DailyAsyncApexExecutions',
                'DailyAsyncApexTests',
                'DailyBulkApiBatches',
                'DailyBulkV2QueryFileStorageMB',
                'DailyBulkV2QueryJobs',
                'HourlyPublishedPlatformEvents',
                'HourlyPublishedStandardVolumePlatformEvents',
                'DailyStandardVolumePlatformEvents',
                'DailyDeliveredPlatformEvents',
                //'MonthlyPlatformEvents',  
                'MonthlyPlatformEventsUsageEntitlement',
                'PrivateConnectOutboundCalloutHourlyLimitMB',
                'HourlyLongTermIdMapping',
                'HourlyODataCallout',
                'HourlyShortTermIdMapping',
                'ActiveScratchOrgs',
                'DailyScratchOrgs',
                'Package2VersionCreates',
                'Package2VersionCreatesWithoutValidation',
                'DailyFunctionsApiCallLimit',
                'DataStorageMB',
                'FileStorageMB',
                'DailyDurableGenericStreamingApiEvents',
                'DailyDurableStreamingApiEvents',
                'DurableStreamingApiConcurrentClients',
                'DailyGenericStreamingApiEvents',
                'DailyStreamingApiEvents',
                'DailyWorkflowEmails',
                'HourlyTimeBasedWorkflow'};
                    
                    
                    Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        httpReq.setMethod('GET');
        httpReq.setHeader('Content-Type', 'application/json');
        String actionsRestURL = 'callout:LimitsAppAPI_NC/services/data/v56.0/limits';
        
        httpReq.setEndpoint(actionsRestURL);
        httpResponse = http.send(httpReq);
        httpResponse.getStatusCode();            
        
        Map<String, Object> values = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());                    
        System.debug('*****values --- '+ httpResponse.getBody());
        Limit_LimitsApp__c lla = new Limit_LimitsApp__c(Latest__c = True);
        
        for(String currentLimit : limitsList){
            Map<String, Object> dailyLimits = (Map<String, Object>)values.get(currentLimit);
            System.debug('*****currentLimit --- '+ currentLimit);
            
            String maxField = currentLimit + '_Max__c';
            if(maxField.length() > 40 ){
                maxField = maxField.substring(0, 40);
                maxField += '__c';
            }         
            String remainingField = currentLimit + '_Remaining__c';
            if(remainingField.length() > 40 ){
                remainingField = remainingField.substring(0, 40);
                remainingField += '__c';
            } 
            //StreamingApiConcurrentClients_Remaining___c
            //DailyBulkV2QueryFileStorageMB_Remaining___c 
            //HourlyPublishedPlatformEvents_Remaining___c 
            if(currentLimit == 'HourlyPublishedPlatformEvents'){
                maxField = 'HourlyPublishedPlatformEvents_Max__c'; 
                remainingField = 'HourlyPublishedPlatformEvents_Remaining__c'; 
            }if(currentLimit == 'DailyBulkV2QueryFileStorageMB'){
                maxField = 'DailyBulkV2QueryFileStorageMB_Max__c'; 
                remainingField = 'DailyBulkV2QueryFileStorageMB_Remaining__c'; 
            }if(currentLimit == 'StreamingApiConcurrentClients'){
                maxField = 'StreamingApiConcurrentClients_Max__c'; 
                remainingField = 'StreamingApiConcurrentClients_Remaining__c'; 
            }
            // other use cases of remnaming the fields 
            if(currentLimit == 'HourlyPublishedStandardVolumePlatformEvents'){
                maxField = 'HourlyPSVPlatformEvents_Max__c'; 
                remainingField = 'HourlyPSVPlatformEvents_Rem__c'; 
            }
            if(currentLimit == 'PrivateConnectOutboundCalloutHourlyLimitMB'){
                maxField = 'PrivateConnectOutboundCalloutHourly_Max__c';
                remainingField = 'PrivateConnectOutboundCalloutHourly_Rem__c';
            }
            if(currentLimit == 'Package2VersionCreatesWithoutValidation'){
                maxField = 'Package2VersionCreatesWOV_Max__c';
                remainingField = 'Package2VersionCreatesWOV_Rem__c';
            }
            if(currentLimit == 'DailyDeliveredPlatformEvents'){
                maxField = 'DailyDeliveredPlatformEvents_Max__c';
                remainingField = 'DailyDeliveredPlatformEvents_Remaining__c';
            }
            try {
                System.debug('*****dailyLimits.Max --- '+ dailyLimits.get('Max'));
                String max = (String)lla.put(maxField, (Integer)dailyLimits.get('Max'));
            } catch (Exception e){
                System.debug('***** ERROR Max ---  '+ e);
            }
            try {
                System.debug('*****dailyLimits.Remaining --- '+ dailyLimits.get('Remaining'));
                String remaining = (String)lla.put(remainingField,(Integer)dailyLimits.get('Remaining'));
            } catch (Exception e){
                System.debug('***** ERROR Remaining ---  '+ e);
            }
        }
        
        //Schema.DescribeSObjectResult limitsObject  = Limit_LimitsApp__c.SObjectType.getDescribe();
        if (objectFieldIsCreatablePermCheck()){
        {
            insert lla;
        }           
            //Set all other limit values to latest = false
            try{
                for(List<Limit_LimitsApp__c> oldLimits : [SELECT Latest__c 
                                                          FROM Limit_LimitsApp__c
                                                          WHERE Id !=: lla.Id])
                {
                    for(Limit_LimitsApp__c oldLimit : oldLimits){
                        oldLimit.Latest__c = false;
                    }
                    if (objectFieldIsUpdatablePermCheck())
                    {
                    update oldLimits;
                }
                    
                }
            } catch(Exception e) {
                System.debug('***** ERROR Updating Existing Limits to Latest__c = False ---' + e);
            }
    }  
    }
    
    
    public static Boolean limitCreatedInLastMinute(){
        
        List<Limit_LimitsApp__c> llas = [SELECT Minutes_Since_Created__c 
                                         FROM Limit_LimitsApp__c
                                         WHERE Latest__c = True
                                         AND Minutes_Since_Created__c  <= 1];
        Boolean createdInLastMin;
        if(llas.size() > 0){
            createdInLastMin = true;
        } else {
            createdInLastMin = false;
        }
        return createdInLastMin;
    }
    
        // Permission Check for IsUpdatable()
    public static Boolean objectFieldIsUpdatablePermCheck(){
        Schema.DescribeSObjectResult limitsObject  = Limit_LimitsApp__c.SObjectType.getDescribe();
        if (limitsObject.isUpdateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Latest__c.isUpdateable())
        {
            return true; 
        } else {
            return false;
        }
    }
    
        // Permission Check for IsCreatable()
    public static Boolean objectFieldIsCreatablePermCheck(){
        Schema.DescribeSObjectResult limitsObject  = Limit_LimitsApp__c.SObjectType.getDescribe();
        if (limitsObject.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Latest__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.SingleEmail_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.StreamingApiConcurrentClients_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.AnalyticsExternalDataSizeMB_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ConcurrentAsyncGetReportInstances_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ConcurrentSyncReportRuns_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyAsyncReportRuns_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlySyncReportRuns_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardRefreshes_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardResults_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardStatuses_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.MassEmail_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyApiRequests_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyAsyncApexExecutions_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyAsyncApexTests_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkApiBatches_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkV2QueryFileStorageMB_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkV2QueryJobs_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyPublishedPlatformEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyPSVPlatformEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyStandardVolumePlatformEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDeliveredPlatformEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.MonthlyPlatformEventsUsageEntitlement_Ma__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.PrivateConnectOutboundCalloutHourly_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyLongTermIdMapping_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyODataCallout_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyShortTermIdMapping_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ActiveScratchOrgs_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyScratchOrgs_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Package2VersionCreates_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Package2VersionCreatesWOV_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyFunctionsApiCallLimit_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DataStorageMB_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.FileStorageMB_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDurableGenericStreamingApiEvents_Ma__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDurableStreamingApiEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DurableStreamingApiConcurrentClients_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyGenericStreamingApiEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyStreamingApiEvents_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyWorkflowEmails_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyTimeBasedWorkflow_Max__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.SingleEmail_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.StreamingApiConcurrentClients_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.AnalyticsExternalDataSizeMB_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ConcurrentAsyncGetReportInstances_Remain__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ConcurrentSyncReportRuns_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyAsyncReportRuns_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlySyncReportRuns_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardRefreshes_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardResults_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyDashboardStatuses_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.MassEmail_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyApiRequests_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyAsyncApexExecutions_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyAsyncApexTests_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkApiBatches_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkV2QueryFileStorageMB_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyBulkV2QueryJobs_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyPublishedPlatformEvents_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyPSVPlatformEvents_Rem__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyStandardVolumePlatformEvents_Remain__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDeliveredPlatformEvents_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.MonthlyPlatformEventsUsageEntitlement_Re__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.PrivateConnectOutboundCalloutHourly_Rem__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyLongTermIdMapping_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyODataCallout_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyShortTermIdMapping_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.ActiveScratchOrgs_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyScratchOrgs_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Package2VersionCreates_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.Package2VersionCreatesWOV_Rem__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyFunctionsApiCallLimit_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DataStorageMB_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.FileStorageMB_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDurableGenericStreamingApiEvents_Re__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyDurableStreamingApiEvents_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DurableStreamingApiConcurrentClients_Rem__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyGenericStreamingApiEvents_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyStreamingApiEvents_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.DailyWorkflowEmails_Remaining__c.isCreateable() &&
            Schema.sObjectType.Limit_LimitsApp__c.fields.HourlyTimeBasedWorkflow_Remaining__c.isCreateable()
           )
        {
            return true; 
        } else {
            return false;
        }
    }
    
    @InvocableMethod(label='Get Limits')
    public static List<Results> getLimitsAdHoc(){ 
        
        List<Results> results = new List<Results>();
        LimitsApp.Results lar = new LimitsApp.Results();
        Boolean limitCreated = limitCreatedInLastMinute();
        results.add(lar);
        results[0].limitCreatedInLastMinute = limitCreated;
        
        if(limitCreated == false){            
            List<String> limitsList = new List<String>{
                'SingleEmail',
                    'StreamingApiConcurrentClients',
                    'AnalyticsExternalDataSizeMB',
                    'ConcurrentAsyncGetReportInstances',
                    'ConcurrentSyncReportRuns',
                    'HourlyAsyncReportRuns',
                    'HourlySyncReportRuns',
                    'HourlyDashboardRefreshes',
                    'HourlyDashboardResults',
                    'HourlyDashboardStatuses',
                    'MassEmail',
                    'DailyApiRequests',
                    'DailyAsyncApexExecutions',
                    'DailyAsyncApexTests',
                    'DailyBulkApiBatches',
                    'DailyBulkV2QueryFileStorageMB',
                    'DailyBulkV2QueryJobs',
                    'HourlyPublishedPlatformEvents',
                    'HourlyPublishedStandardVolumePlatformEvents',
                    'DailyStandardVolumePlatformEvents',
                    'DailyDeliveredPlatformEvents',
                    //'MonthlyPlatformEvents',  
                    'MonthlyPlatformEventsUsageEntitlement',
                    'PrivateConnectOutboundCalloutHourlyLimitMB',
                    'HourlyLongTermIdMapping',
                    'HourlyODataCallout',
                    'HourlyShortTermIdMapping',
                    'ActiveScratchOrgs',
                    'DailyScratchOrgs',
                    'Package2VersionCreates',
                    'Package2VersionCreatesWithoutValidation',
                    'DailyFunctionsApiCallLimit',
                    'DataStorageMB',
                    'FileStorageMB',
                    'DailyDurableGenericStreamingApiEvents',
                    'DailyDurableStreamingApiEvents',
                    'DurableStreamingApiConcurrentClients',
                    'DailyGenericStreamingApiEvents',
                    'DailyStreamingApiEvents',
                    'DailyWorkflowEmails',
                    'HourlyTimeBasedWorkflow'};                     
                        
                        Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpResponse = new HttpResponse(); 
            
            httpReq.setMethod('GET');
            
            httpReq.setHeader('Content-Type', 'application/json');
            String actionsRestURL = 'callout:LimitsAppAPI_NC/services/data/v56.0/limits';
            
            httpReq.setEndpoint(actionsRestURL);
            httpResponse = http.send(httpReq);
            httpResponse.getStatusCode();            
            
            Map<String, Object> values = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());                    
            System.debug('*****values --- '+ httpResponse.getBody());
            Limit_LimitsApp__c lla = new Limit_LimitsApp__c(Latest__c = True);
            
            for(String currentLimit : limitsList){
                Map<String, Object> dailyLimits = (Map<String, Object>)values.get(currentLimit);
                System.debug('*****currentLimit --- '+ currentLimit);
                
                String maxField = currentLimit + '_Max__c';
                if(maxField.length() > 40 ){
                    maxField = maxField.substring(0, 40);
                    maxField += '__c';
                }         
                String remainingField = currentLimit + '_Remaining__c';
                if(remainingField.length() > 40 ){
                    remainingField = remainingField.substring(0, 40);
                    remainingField += '__c';
                } 
                //StreamingApiConcurrentClients_Remaining___c
                //DailyBulkV2QueryFileStorageMB_Remaining___c 
                //HourlyPublishedPlatformEvents_Remaining___c 
                if(currentLimit == 'HourlyPublishedPlatformEvents'){
                    maxField = 'HourlyPublishedPlatformEvents_Max__c'; 
                    remainingField = 'HourlyPublishedPlatformEvents_Remaining__c'; 
                }if(currentLimit == 'DailyBulkV2QueryFileStorageMB'){
                    maxField = 'DailyBulkV2QueryFileStorageMB_Max__c'; 
                    remainingField = 'DailyBulkV2QueryFileStorageMB_Remaining__c'; 
                }if(currentLimit == 'StreamingApiConcurrentClients'){
                    maxField = 'StreamingApiConcurrentClients_Max__c'; 
                    remainingField = 'StreamingApiConcurrentClients_Remaining__c'; 
                }
                // other use cases of remnaming the fields 
                if(currentLimit == 'HourlyPublishedStandardVolumePlatformEvents'){
                    maxField = 'HourlyPSVPlatformEvents_Max__c'; 
                    remainingField = 'HourlyPSVPlatformEvents_Rem__c'; 
                }
                if(currentLimit == 'PrivateConnectOutboundCalloutHourlyLimitMB'){
                    maxField = 'PrivateConnectOutboundCalloutHourly_Max__c';
                    remainingField = 'PrivateConnectOutboundCalloutHourly_Rem__c';
                }
                if(currentLimit == 'Package2VersionCreatesWithoutValidation'){
                    maxField = 'Package2VersionCreatesWOV_Max__c';
                    remainingField = 'Package2VersionCreatesWOV_Rem__c';
                }
                if(currentLimit == 'DailyDeliveredPlatformEvents'){
                    maxField = 'DailyDeliveredPlatformEvents_Max__c';
                    remainingField = 'DailyDeliveredPlatformEvents_Remaining__c';
                }
                try {
                    System.debug('*****dailyLimits.Max --- '+ dailyLimits.get('Max'));
                    String max = (String)lla.put(maxField, (Integer)dailyLimits.get('Max'));
                } catch (Exception e){
                    System.debug('***** ERROR Max ---  '+ e);
                }
                try {
                    System.debug('*****dailyLimits.Remaining --- '+ dailyLimits.get('Remaining'));
                    String remaining = (String)lla.put(remainingField,(Integer)dailyLimits.get('Remaining'));
                } catch (Exception e){
                    System.debug('***** ERROR Remaining ---  '+ e);
                }
            }
            if (objectFieldIsCreatablePermCheck()){
            insert lla;           
            }
            // Set all other limit values to latest = false
            try{
                for(List<Limit_LimitsApp__c> oldLimits : [SELECT Latest__c 
                                                          FROM Limit_LimitsApp__c
                                                          WHERE Id !=: lla.Id])
                {
                    for(Limit_LimitsApp__c oldLimit : oldLimits){
                        oldLimit.Latest__c = false;
                    }
                    if (objectFieldIsUpdatablePermCheck()){
                    update oldLimits;
                }
                }
            } catch(Exception e) {
                System.debug('***** ERROR Updating Existing Limits to Latest__c = False ---' + e);
            }
        }
        return results;
    }
    
    public class Results{
        
        @invocableVariable(label='Limit Created in Last Minute?' required=true)
        public Boolean limitCreatedInLastMinute;     
    }    
}
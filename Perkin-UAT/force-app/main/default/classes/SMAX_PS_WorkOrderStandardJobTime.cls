/**
 *  Apex Class for Work Order [SVMXC__Service_Order__c] Business Logic regarding Standard Job Time and related metrics.
 *  2021-01-21      b.s.salmans     created
 */

@SuppressWarnings('ApexDocValidation')
public with sharing class SMAX_PS_WorkOrderStandardJobTime {

    public static String WILDCARD = '(Empty)';

    /** 1/8/21 ITSVMX-225 Standard Job Time Automation
      * On creation of a Work Order, or when the Order Type or Installed Product are changed, the system should
      * automatically update the Service Duration and a new “Standard Job Time” field by finding a corresponding
      * record in the SVMX_PS_Standard_Job_Time__c object.
    */
    public static void updateStandardJobTime(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        List<SVMXC__Service_Order__c> woUpdateList = new List<SVMXC__Service_Order__c>();
        Set<String> externalIds = new Set<String>();
        Map<String, Decimal> externalIdToStandardJobTime = new Map<String, Decimal>();

        // 8/19/21 Tony - ITSVMX-573 Standard Job Time Default Schedule Duration
        // Added as the default for Service Duration is not working from ServiceMax after Long Job Scheduling was activated
        Decimal defaultDuration = 0;
        if(!Test.isRunningTest()){ // This ServiceMax code won't execute in Unit Test context
            SVMXC.COMM_Utils_ManageSettings commUtilSettings = new SVMXC.COMM_Utils_ManageSettings();
            Map<String, String> mySettings = commUtilSettings.SVMX_getSettingList('DCON001');
            String valSet002 = mySettings.get('SET002');
            System.debug('valSet002: ' + valSet002);
            if (!String.isEmpty(valSet002)) {
                defaultDuration = Decimal.valueOf(valSet002);
            }
        }

        //Get list of Work Orders to update and ExternalId Map
        for (SVMXC__Service_Order__c wo : woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            if (old == null || (old != null && wo.SVMXC__Order_Type__c != old.SVMXC__Order_Type__c)
                    || (old != null && wo.SVMXC__Component__c != old.SVMXC__Component__c)) {

                // ITSVMX-606: Changing Scheduled Duration field
                // 8/19/21 Tony - ITSVMX-573 Standard Job Time Default Schedule Duration
                // Added as the default for Service Duration is not working from ServiceMax after Long Job Scheduling was activated
                if (wo.SVMXC__Service_Duration__c == null || wo.SVMXC__Service_Duration__c == 0) {
                    wo.SVMXC__Service_Duration__c = defaultDuration * 60; // In seconds
                    wo.SVMXC__SM_Estimated_Duration__c = defaultDuration; // in minutes
                    wo.SMAX_PS_Scheduled_Duration_Hours__c = defaultDuration / 60; // in hours
                }

                woUpdateList.add(wo);
                // Need to lookup the exact match + Wildcard IF exact match NOT found
                externalIds.addAll(getSjtExternalIds(wo));
            }
        }
        System.debug('woUpdateList: ' + woUpdateList);

        if (woUpdateList.size() <= 0) return;

        // Get list of Standard Job Times for the Work Orders we are updating
        // ITSVMX-401 Filter only 'Active' records
        List<SVMX_PS_Standard_Job_Time__c> standardJobTimes = [
                SELECT Id, SVMX_PS_External_ID__c, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c,
                        SVMX_PS_Order_Type__c, SVMX_PS_Standard_Duration__c
                FROM SVMX_PS_Standard_Job_Time__c
                WHERE SVMX_PS_External_ID__c IN :externalIds AND SVMX_PS_Status__c = 'Active'];
        System.debug('externalIds: ' + externalIds);
        System.debug('standardJobTimes: ' + standardJobTimes);

        if (standardJobTimes.size() <= 0) {
            System.debug('No matching Standard Job Time record was found for External Ids: ' + externalIds);
            return;
        }

        // Get map of External Ids to Standard Job Time
        for (SVMX_PS_Standard_Job_Time__c standardJobTime : standardJobTimes) {

            externalIdToStandardJobTime.put(standardJobTime.SVMX_PS_External_ID__c, standardJobTime.SVMX_PS_Standard_Duration__c);
        }
        System.debug('externalIdToStandardJobTime: ' + externalIdToStandardJobTime);

        // Update the Standard Job Time and Service Duration
        for (SVMXC__Service_Order__c wo : woUpdateList) {
            List<String> woExtIds = getSjtExternalIds(wo); // Exact match + wildcard...
            for (String externalId : woExtIds) {
                Decimal standardJobTime = externalIdToStandardJobTime.get(externalId);
                if (standardJobTime != null) {
                    // ITSVMX-606: Changing Scheduled Duration field
                    // 8/10/21 Tony - ITSVMX-551 Need to make sure the Scheduled Duration is set also
                    wo.SVMXC__Service_Duration__c = standardJobTime * 60 * 60; // 2/2/21 tony - this needs to be in seconds
                    wo.SVMXC__SM_Estimated_Duration__c = standardJobTime * 60; // 2/2/21 tony - this needs to be in minutes
                    wo.SMAX_PS_Scheduled_Duration_Hours__c = standardJobTime;

                    wo.SVMX_PS_Standard_Job_Time__c = standardJobTime;
                    if (standardJobTime > 8) {
                        // 3/22/21 Tony - commented the following line because Long Job Scheduling is not working as expected and we have an open ticket with ServiceMax
                        // 5/26/21 Tony - re-added in per request from Andrew
                        wo.SVMXC__SM_Scheduling_Options__c = 'JDM and LJS Enabled';
                    }
                    break; // Stop the loop, don't try the next externalId
                }
            }
        }
        System.debug('Updated WOs: ' + woUpdateList);
    }

    private static List<String> getSjtExternalIds(SVMXC__Service_Order__c wo) {
        List<String> externalIds = new List<String>();
         if (wo.SMAX_PS_ModelSeries__c != null) {
            externalIds.add(wo.SVMXC__Order_Type__c + '-' + wo.SMAX_PS_IP_Product_Line__c + '-' + wo.SMAX_PS_ModelSeries__c);
        }
        externalIds.add(wo.SVMXC__Order_Type__c + '-' + wo.SMAX_PS_IP_Product_Line__c + '-' + WILDCARD);
        return externalIds;
    }

    /***************************************
     * LWC METHODS
     ***************************************/

    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> apexStatuses() {
        // ITSVMX-401
        List<comboBoxResult> statuses = new List<comboBoxResult>();
        Schema.DescribeFieldResult fieldResult = SVMX_PS_Standard_Job_Time__c.SVMX_PS_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            statuses.add(new comboBoxResult(pickListVal.getLabel(), pickListVal.getValue()));
        }
        return statuses;
    }

    /*******************************************************************************************************************
     * METHOD: apexOrderTypes
     * @description returns all order type values for picklist
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-20 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> apexOrderTypes(List<String> selectedTypes) {

        // variable declaration
        List<AggregateResult> jobs;
        List<comboBoxResult> orderTypes = new List<comboBoxResult>();
        if (selectedTypes == null) selectedTypes = new List<String>();

        // ...execute SOQL search query...
        jobs = [
                SELECT SVMX_PS_Order_Type__c, COUNT(Name)
                FROM SVMX_PS_Standard_Job_Time__c
                WHERE SVMX_PS_Order_Type__c NOT IN :selectedTypes
                GROUP BY SVMX_PS_Order_Type__c
        ];

        // ...place order type options in list...
        for (AggregateResult job : jobs) {
            orderTypes.add(new comboBoxResult((String) job.get('SVMX_PS_Order_Type__c'),
                    (String) job.get('SVMX_PS_Order_Type__c')));
        }

        // ...and return
        return orderTypes;
    }

    /*******************************************************************************************************************
     * METHOD: apexProductLines
     * @description returns all product line values for picklist
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-20 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> apexProductLines(List<String> includedTypes, List<String> selectedLines) {

        // variable declaration
        List<AggregateResult> jobs;
        List<comboBoxResult> productLines = new List<comboBoxResult>();
        if (selectedLines == null) selectedLines = new List<String>();

        // ...execute SOQL search query...
        if (includedTypes.isEmpty()) {
            jobs = [
                    SELECT SVMX_PS_Product_Line__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Product_Line__c NOT IN :selectedLines
                    GROUP BY SVMX_PS_Product_Line__c
            ];
        } else {
            jobs = [
                    SELECT SVMX_PS_Product_Line__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Order_Type__c IN :includedTypes
                    AND SVMX_PS_Product_Line__c NOT IN :selectedLines
                    GROUP BY SVMX_PS_Product_Line__c
            ];
        }

        // ...place product line options in a list...
        for (AggregateResult job : jobs) {
            productLines.add(new comboBoxResult((String) job.get('SVMX_PS_Product_Line__c'),
                    (String) job.get('SVMX_PS_Product_Line__c')));
        }

        // ...and return
        return productLines;
    }

    /*******************************************************************************************************************
     * METHOD: apexModelSeries
     * @description returns all model series values for picklist
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-20 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> apexModelSeries(List<String> includedTypes, List<String> includedLines, List<String> selectedModels) {

        // variable declaration
        List<AggregateResult> jobs;
        List<comboBoxResult> modelSeries = new List<comboBoxResult>();
        if (selectedModels == null) selectedModels = new List<String>();

        // ...execute SOQL search query...
        if (!includedTypes.isEmpty() && !includedLines.isEmpty()) {
            jobs = [
                    SELECT SVMX_PS_Model_Series__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Order_Type__c IN :includedTypes
                    AND SVMX_PS_Product_Line__c IN :includedLines
                    AND SVMX_PS_Model_Series__c NOT IN :selectedModels
                    GROUP BY SVMX_PS_Model_Series__c
            ];
        } else if (!includedTypes.isEmpty()) {
            jobs = [
                    SELECT SVMX_PS_Model_Series__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Order_Type__c IN :includedTypes
                    AND SVMX_PS_Model_Series__c NOT IN :selectedModels
                    GROUP BY SVMX_PS_Model_Series__c
            ];
        } else if (!includedLines.isEmpty()) {
            jobs = [
                    SELECT SVMX_PS_Model_Series__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Product_Line__c IN :includedLines
                    AND SVMX_PS_Model_Series__c NOT IN :selectedModels
                    GROUP BY SVMX_PS_Model_Series__c
            ];
        } else {
            jobs = [
                    SELECT SVMX_PS_Model_Series__c, COUNT(Name)
                    FROM SVMX_PS_Standard_Job_Time__c
                    WHERE SVMX_PS_Model_Series__c NOT IN :selectedModels
                    GROUP BY SVMX_PS_Model_Series__c
            ];
        }

        // ...place model series options in a list...
        for (AggregateResult job : jobs) {
            modelSeries.add(new comboBoxResult((String) job.get('SVMX_PS_Model_Series__c'),
                    (String) job.get('SVMX_PS_Model_Series__c')));
        }

        // ...and return
        return modelSeries;
    }

    /*******************************************************************************************************************
     * METHOD: searchJobs
     * @description returns all standard job time records that match order type, product line, model series,
     *              month horizon and delta slider value
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-20 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=false)
    public static List<jobSearchResult> searchJobs(List<String> statuses, List<String> types, List<String> lines, List<String> model, String horizon, Integer minDelta, Integer minCount) {

        if (statuses == null || statuses.isEmpty()) {
            statuses = new List<String> { 'Active' };
        }

        // variable declaration
        final Integer MAX_RESULTS = 1000;
        String queryString;
        List<SVMX_PS_Standard_Job_Time__c> jobList;

        System.debug(' --  horizon: ' + horizon);

        // create soql string...
        Integer negativeSlider = -1 * minDelta;
        String deltaField = 'SVMX_PS_' + horizon + 'MoDelta__c';
        String countField = 'SVMX_PS_' + horizon + 'MoRecCnt__c';
        queryString = 'SELECT Id, Name, SVMX_PS_Status__c, SVMX_PS_Order_Type__c, ' +
                ' SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c, SVMX_PS_Standard_Duration__c, SVMX_PS_12MoRecCnt__c, SVMX_PS_6MoRecCnt__c, \n' +
                ' SVMX_PS_1MoAvg__c, SVMX_PS_12MoAvg__c, SVMX_PS_1MoRecCnt__c, SVMX_PS_3MoAvg__c, SVMX_PS_6MoAvg__c, \n' +
                ' SVMX_PS_1MoDelta__c, SVMX_PS_12MoDelta__c, SVMX_PS_3MoDelta__c, SVMX_PS_3MoRecCnt__c, SVMX_PS_6MoDelta__c \n' +
                ' FROM SVMX_PS_Standard_Job_Time__c \n' +
                ' WHERE (' + deltaField + ' >= ' + minDelta + ' OR ' + deltaField + ' <= ' + negativeSlider + ') ' +
                ' AND (' + countField + ' >= ' + minCount + ') ' +
                ' AND (SVMX_PS_Status__c IN :statuses) '; // ITSVMX-401 Status filter
        if (!types.isEmpty()) queryString += '\n AND SVMX_PS_Order_Type__c IN :types ';
        if (!lines.isEmpty()) queryString += '\n AND SVMX_PS_Product_Line__c IN :lines ';
        if (!model.isEmpty()) queryString += '\n AND SVMX_PS_Model_Series__c IN :model ';
        queryString += '\n LIMIT ' + MAX_RESULTS;

        // ...execute soql query...
        jobList = Database.query(queryString);

        // ...prepare results...
        List<jobSearchResult> jobs = new List<jobSearchResult>();
        for (SVMX_PS_Standard_Job_Time__c job : jobList) {
            String duration = String.valueOf(job.SVMX_PS_Standard_Duration__c);
            String actual = String.valueOf(job.get('SVMX_PS_' + horizon + 'MoAvg__c'));
            String count = String.valueOf(job.get(countField));
            Decimal delta = ((Decimal)job.get(deltaField));
            if (delta == null) { delta = 0.0; }
            String diff = String.valueOf(delta / 100.00);
            jobs.add(new jobSearchResult(job.Id, job.Name, job.SVMX_PS_Status__c, job.SVMX_PS_Order_Type__c,
                job.SVMX_PS_Product_Line__c, job.SVMX_PS_Model_Series__c, duration, actual, diff, count));
        }

        // ...return results
        return jobs;
    }

    /*******************************************************************************************************************
     * METHOD: getSjtDetails
     * @description method to return relevant standard job detail information for detailed view
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-24 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static SVMX_PS_Standard_Job_Time__c getSjtDetails(String jobId) {

        System.debug(' -- job id: ' + jobId);

        // return standard job time details
        return [
                SELECT Id, Name, SVMX_PS_Status__c, SVMX_PS_Order_Type__c, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c, SVMX_PS_Standard_Duration__c,
                        SVMX_PS_1MoAvg__c, SVMX_PS_12MoAvg__c, SVMX_PS_3MoAvg__c, SVMX_PS_6MoAvg__c, SVMX_PS_1MoDelta__c, SVMX_PS_12MoDelta__c,
                        SVMX_PS_3MoDelta__c, SVMX_PS_6MoDelta__c, SVMX_PS_1MoRecCnt__c, SVMX_PS_3MoRecCnt__c, SVMX_PS_6MoRecCnt__c, SVMX_PS_12MoRecCnt__c,
                        SVMX_PS_1MoMin__c, SVMX_PS_3MoMin__c, SVMX_PS_6MoMin__c, SVMX_PS_12MoMin__c, SVMX_PS_1MoMax__c, SVMX_PS_3MoMax__c,
                        SVMX_PS_6MoMax__c, SVMX_PS_12MoMax__c
                FROM SVMX_PS_Standard_Job_Time__c
                WHERE Id = :jobId
        ];
    }

    /*******************************************************************************************************************
     * METHOD: getReportId
     * @description returns standard job time report id
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-24 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static Id getReportId(Boolean empty) {

        System.debug(' --  empty: ' + empty);

        // return the standard job time report id
        if (empty) {
            System.debug(' --  querying SMAX_PS_WO_by_SJT_Empty');
            return [SELECT Id FROM Report WHERE DeveloperName = 'SMAX_PS_WO_by_SJT'].Id;
        } else {
            System.debug(' --  querying SMAX_PS_WO_by_SJT');
            return [SELECT Id FROM Report WHERE DeveloperName = 'SMAX_PS_WO_by_SJT'].Id;
        }
    }

    public static List<String> getAllModelSeries(String orderType, String productLine) {
        // Get all non-empty standard job time records for the ordertype and productline pair...
        String empty = WILDCARD;
        List<SVMX_PS_Standard_Job_Time__c> sjts = [
                SELECT SVMX_PS_Model_Series__c
                FROM SVMX_PS_Standard_Job_Time__c
                WHERE SVMX_PS_Order_Type__c = :orderType
                AND SVMX_PS_Product_Line__c = :productLine
                AND SVMX_PS_Model_Series__c != :empty
        ];
        List<String> result = new List<String>();
        for (SVMX_PS_Standard_Job_Time__c sjt : sjts) {
            result.add(sjt.SVMX_PS_Model_Series__c);
        }
        return result;
    }

    /*******************************************************************************************************************
     * METHOD: getAllExtantModels
     * @description returns a list of
     * @author b.s. salmans
     * <-----CHANGE LOG----->
     * 2021-02-24 - Created method.
     *******************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static String getAllExtantModels(String orderType, String productLine) {
        List<String> modelSeries = getAllModelSeries(orderType, productLine);
        String result = '';  //  comma separated string of all non-empty model series
        for (String ms : modelSeries) result += ms + ',';
        return result.removeEnd(',');
    }

    /*************************/
    /**   UTILITY CLASSES   **/
    /*************************/

    // class for returning search results for filtered standard job times
    public class jobSearchResult {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String product { get; set; }
        @AuraEnabled public String model { get; set; }
        @AuraEnabled public String standard { get; set; }
        @AuraEnabled public String actual { get; set; }
        @AuraEnabled public String diff { get; set; }
        @AuraEnabled public String count { get; set; }
        @AuraEnabled public Boolean disableSplit { get; set; }

        public jobSearchResult() {} // Added for serialization of "createNewSJT"

        public jobSearchResult(String id, String name, String status, String type, String product, String model, String standard, String actual, String diff, String count) {
            this.id = id;
            this.name = name;
            this.status = status;
            this.type = type;
            this.product = product;
            this.model = model;
            this.standard = standard;
            this.actual = actual;
            this.diff = diff;
            this.count = count;
            this.disableSplit = (model != WILDCARD);
        }
    }

    // class for returning results for combobox options
    public class comboBoxResult {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public comboBoxResult(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    /**
     * -------  LWC "Add SJT" Dialog Methods
     */

    @AuraEnabled(Cacheable=true)
    public static List<comboBoxResult> allOrderTypes() {
        // ITSVMX-401
        List<comboBoxResult> statuses = new List<comboBoxResult>();
        Schema.DescribeFieldResult fieldResult = SVMXC__Service_Order__c.SVMXC__Order_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            statuses.add(new comboBoxResult(pickListVal.getLabel(), pickListVal.getValue()));
        }
        return statuses;
    }

    @AuraEnabled(Cacheable=false)
    public static List<jobSearchResult> findNewSJT(String orderType, String productLine) {

        List<jobSearchResult> results = new List<jobSearchResult>();
        Date lastYear = Date.today().addYears(-1);

        // Find existing SJT (Product Lines) for this Order Type
        Set<String> productLines = new Set<String> { '' };
        List<SVMX_PS_Standard_Job_Time__c> existingPL = [SELECT SVMX_PS_Product_Line__c
            FROM SVMX_PS_Standard_Job_Time__c WHERE SVMX_PS_Order_Type__c = :orderType];
        for (SVMX_PS_Standard_Job_Time__c sjt : existingPL) {
            productLines.add(sjt.SVMX_PS_Product_Line__c);
        }

        String empty = WILDCARD;
        if (productLine == null) {
            List<AggregateResult> arList = [SELECT COUNT(Id) counter, SMAX_PS_IP_Product_Line__c
                FROM SVMXC__Service_Order__c
                WHERE SVMXC__Completed_Date_Time__c > :lastYear
                    AND SVMXC__Order_Type__c = :orderType
                    AND SMAX_PS_IP_Product_Line__c NOT IN :productLines
                GROUP BY SMAX_PS_IP_Product_Line__c];
            for (AggregateResult ar : arList) {
                Integer count = Integer.valueOf(ar.get('counter'));
                String pl = (String) ar.get('SMAX_PS_IP_Product_Line__c');
                String key = orderType + '-' + pl + '-' + empty;
                jobSearchResult result = new jobSearchResult('', key, 'Draft', orderType, pl, empty,
                    '0', '0', '0', count+'');
                results.add(result);
            }
        } else {
            // Find existing SJT (Model Series) for this Order Type + Product Line
            Set<String> modelSeries = new Set<String> { '' };
            List<SVMX_PS_Standard_Job_Time__c> existingMS = [SELECT SVMX_PS_Model_Series__c
                FROM SVMX_PS_Standard_Job_Time__c WHERE SVMX_PS_Order_Type__c = :orderType
                AND SVMX_PS_Product_Line__c = :productLine AND SVMX_PS_Model_Series__c != :empty];
            for (SVMX_PS_Standard_Job_Time__c sjt : existingMS) {
                modelSeries.add(sjt.SVMX_PS_Model_Series__c);
            }

            List<AggregateResult> arList = [SELECT COUNT(Id) counter, SMAX_PS_ModelSeries__c
                FROM SVMXC__Service_Order__c
                WHERE SVMXC__Completed_Date_Time__c > :lastYear
                    AND SVMXC__Order_Type__c = :orderType
                    AND SMAX_PS_IP_Product_Line__c = :productLine
                    AND SMAX_PS_ModelSeries__c NOT IN :modelSeries
                GROUP BY SMAX_PS_ModelSeries__c];
            for (AggregateResult ar : arList) {
                Integer count = Integer.valueOf(ar.get('counter'));
                String model = (String) ar.get('SMAX_PS_ModelSeries__c');
                String key = orderType + '-' + productLine + '-' + model;
                jobSearchResult result = new jobSearchResult('', key, 'Draft', orderType, productLine, model,
                        '0', '0', '0', count+'');
                results.add(result);
            }
        }

        return results;
    }

    @AuraEnabled(Cacheable=false)
    public static String createNewSJT(List<jobSearchResult> jobTimes) {
        List<SVMX_PS_Standard_Job_Time__c> sjtList = new List<SVMX_PS_Standard_Job_Time__c>();
        for (jobSearchResult jobTime : jobTimes) {
            if (String.isNotBlank(jobTime.id)) {
                System.debug('Skipping job id = ' + jobTime.id);
                continue; // Skip this one.. it already exists
            }
            SVMX_PS_Standard_Job_Time__c sjt = new SVMX_PS_Standard_Job_Time__c();
            sjt.SVMX_PS_External_ID__c = jobTime.name;
            sjt.SVMX_PS_Status__c = jobTime.status;
            sjt.SVMX_PS_Order_Type__c = jobTime.type;
            sjt.SVMX_PS_Product_Line__c = jobTime.product;
            sjt.SVMX_PS_Model_Series__c = jobTime.model;
            //sjt.SVMX_PS_Standard_Duration__c = 0;
            sjtList.add(sjt);
        }

        upsert sjtList SVMX_PS_External_ID__c;

        return 'Successfully created ' + sjtList.size() + ' new "Draft" Standard Job Times';
    }

}
/**
 *  Apex Class for Chart lwc controller
 *  2021-03-05      b.s.salmans     created
 */

public with sharing class SMAX_PS_ChartController {

    /*******************************************************************************************************************
	 * METHOD: getSjtDataSets
	 * @description returns standard job time data for line graph (labor amount (y) over time (x))
	 * @author b.s. salmans
	 * <-----CHANGE LOG----->
	 * 2021-03-08 - Created method.
	 *******************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<DataSet> getSjtDataSets(Id sjtId, String horizon) {

        // variable declaration
        SVMX_PS_Standard_Job_Time__c sjt;  //  standard job time record selected from row
        String modelSeries;  //  dynamic model series variable to handle '(empty)'
//        List<SVMXC__Service_Order__c> result;  //  aggregate result of wo query
        AggregateResult[] result;  //  aggregate result of wo query
        List<DataSet> actualDataSet;  //  dataset of actual job times
        Datetime horizonDate;  //  date to end query results
        Boolean fakeData = false;  //  test value for creating fake data
        Integer horizonInt = Integer.valueOf(horizon);

        // get standard job time...
        sjt = [SELECT Name, SVMX_PS_Order_Type__c, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c, SVMX_PS_1MoAvg__c,
                      SVMX_PS_3MoAvg__c, SVMX_PS_6MoAvg__c, SVMX_PS_12MoAvg__c
                 FROM SVMX_PS_Standard_Job_Time__c WHERE Id = :sjtId];

        // calculate time frame
        actualDataSet = new List<DataSet>{ getBaseline(horizon, sjt) };
        horizonDate = getHorizonDate(horizon);

        // ...handle model series...
        modelSeries = sjt.SVMX_PS_Model_Series__c == '(Empty)' ? null : sjt.SVMX_PS_Model_Series__c;

        // ...get detailed work order data...
        try {
            if (modelSeries != null) {
                result = [
                        SELECT AVG(SMAX_PS_Sum_of_Labor__c) average, DAY_ONLY(SVMXC__Completed_Date_Time__c) dt
                        FROM SVMXC__Service_Order__c
                        WHERE SVMXC__Order_Type__c = :sjt.SVMX_PS_Order_Type__c
                        AND SMAX_PS_IP_Product_Line__c = :sjt.SVMX_PS_Product_Line__c
                        AND SMAX_PS_ModelSeries__c = :modelSeries
                        AND SVMXC__Completed_Date_Time__c > :horizonDate
                        GROUP BY DAY_ONLY(SVMXC__Completed_Date_Time__c)
                ];
            } else {
                List<String> modelSeriesExclusions = SMAX_PS_WorkOrderStandardJobTime.getAllModelSeries(
                        sjt.SVMX_PS_Order_Type__c, sjt.SVMX_PS_Product_Line__c);
                result = [
                        SELECT AVG(SMAX_PS_Sum_of_Labor__c) average, DAY_ONLY(SVMXC__Completed_Date_Time__c) dt
                        FROM SVMXC__Service_Order__c
                        WHERE SVMXC__Order_Type__c = :sjt.SVMX_PS_Order_Type__c
                        AND SMAX_PS_IP_Product_Line__c = :sjt.SVMX_PS_Product_Line__c
                        AND SMAX_PS_ModelSeries__c NOT IN :modelSeriesExclusions
                        AND SVMXC__Completed_Date_Time__c > :horizonDate
                        GROUP BY DAY_ONLY(SVMXC__Completed_Date_Time__c)
                ];
            }
        }
        catch (Exception e) {
            System.debug(' --  NO RECORDS FOUND  --   faking it...for now');
            fakeData = true;
        }
        if(result == null || result.size() == 0) fakeData = true;

        // ...put data points in line dataset...
        if (fakeData == false) {
            Map<Date, DataSet> resultMap = new Map<Date, DataSet>();
            for(AggregateResult ar:result) {
                Date dt = (Date) ar.get('dt');
                Decimal avg = (Decimal) ar.get('average');
                System.debug('dt = ' + dt + ', avg = ' + avg);
                resultMap.put(dt, new DataSet(String.valueOf(dt), avg));
            }

            // Add all the missing days.. only the non-zeros are returned in result
            Date iDate = horizonDate.date();
            while (iDate < Date.today()) {
                if (resultMap.containsKey(iDate)) {
                    actualDataSet.add(resultMap.get(iDate));
                } else {
                    actualDataSet.add(new DataSet(String.valueOf(iDate), 0));
                }
                iDate = iDate.addDays(1);
            }
        }
        else {
            for(Integer x = 1; x < 7; x++) {
                actualDataSet.add(new DataSet(String.valueOf(Datetime.now().addMonths(-x)), Long.valueOf((x+7)+'')));
            }
        }

        // ...return dataset
        System.debug(' -- line data: '+actualDataSet);
        return actualDataSet;
    }

    /*******************************************************************************************************************
	 * METHOD: getTechManDataSets
	 * @description returns work order average labor sum for each technician manager for the standard job time passed in
	 * @author b.s. salmans
	 * <-----CHANGE LOG----->
	 * 2021-03-10 - Created method.
	 *******************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<DataSet> getTechManDataSets(Id sjtId, String horizon) {

        // variable declaration
        SVMX_PS_Standard_Job_Time__c sjt;  //  standard job time record selected from row
        String modelSeries;  //  dynamic model series variable to handle '(empty)'
        AggregateResult[] result;  //  aggregate result of wo query
        List<DataSet> actualDataSet;  //  dataset of actual job times
        Datetime horizonDate;  //  date to end query results
        Boolean fakeData = false;  //  test value for creating fake data
        List<String> emails;  //  list of manager emails to query user records
        List<User> managers;  //  list of manager user records to get names from
        Map<String,String> emailToName;  //  map of technician manager email -> technician manager name

        // get standard job time...
        sjt = [SELECT Name, SVMX_PS_Order_Type__c, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c, SVMX_PS_1MoAvg__c,
                      SVMX_PS_3MoAvg__c, SVMX_PS_6MoAvg__c, SVMX_PS_12MoAvg__c
               FROM SVMX_PS_Standard_Job_Time__c WHERE Id = :sjtId];

        // calculate time frame
        actualDataSet = new List<DataSet>{ getBaseline(horizon, sjt) };
        horizonDate = getHorizonDate(horizon);

        // ...handle model series...
        modelSeries = sjt.SVMX_PS_Model_Series__c == '(Empty)' ? null : sjt.SVMX_PS_Model_Series__c;

        // ...get detailed work order data...
        try {
            if (modelSeries != null) {
                result = [
                        SELECT COUNT(Id) counter, AVG(SMAX_PS_Sum_of_Labor__c) average, SMAX_PS_Technician_Manager_Email__c techmanEmail
                        FROM SVMXC__Service_Order__c
                        WHERE SVMXC__Order_Type__c = :sjt.SVMX_PS_Order_Type__c
                        AND SMAX_PS_IP_Product_Line__c = :sjt.SVMX_PS_Product_Line__c
                        AND SMAX_PS_ModelSeries__c = :modelSeries
                        AND SVMXC__Completed_Date_Time__c > :horizonDate
                        GROUP BY SMAX_PS_Technician_Manager_Email__c
                ];
            } else {
                List<String> modelSeriesExclusions = SMAX_PS_WorkOrderStandardJobTime.getAllModelSeries(
                        sjt.SVMX_PS_Order_Type__c, sjt.SVMX_PS_Product_Line__c);
                result = [
                        SELECT COUNT(Id) counter, AVG(SMAX_PS_Sum_of_Labor__c) average, SMAX_PS_Technician_Manager_Email__c techmanEmail
                        FROM SVMXC__Service_Order__c
                        WHERE SVMXC__Order_Type__c = :sjt.SVMX_PS_Order_Type__c
                        AND SMAX_PS_IP_Product_Line__c = :sjt.SVMX_PS_Product_Line__c
                        AND SMAX_PS_ModelSeries__c NOT IN :modelSeriesExclusions
                        AND SVMXC__Completed_Date_Time__c > :horizonDate
                        GROUP BY SMAX_PS_Technician_Manager_Email__c
                ];
            }
        }
        catch (Exception e) {
            System.debug(' --  NO RECORDS FOUND  --   faking it...for now, or exception: '+e.getMessage());
            fakeData = true;
        }

        if(result.size() == 0) {
            fakeData = true;
        }
        else {
            // ..create a map from technician manager email to technician manager name...
            emails = new List<String>();
            for(AggregateResult ar:result) emails.add((String) ar.get('techmanEmail'));
            managers = [SELECT Name, Email FROM User WHERE Email IN :emails];
            emailToName = new Map<String,String>();
            for(User man:managers) emailToName.put((String) man.email, man.Name);
        }

        // ...put data points in line dataset
        if (fakeData == false) {
            for (AggregateResult ar:result) {
                actualDataSet.add(new DataSet(emailToName.get((String) ar.get('techmanEmail')), (Decimal) ar.get('average')));
            }
        }
        else {
            for(Integer x = 1; x < 7; x++) {
                actualDataSet.add(new DataSet('TECHMAN '+x , Long.valueOf(x+'')));
            }
        }
        // ...return dataset
        System.debug(' -- bar data: '+actualDataSet);
        return actualDataSet;
    }

    /*******************
     * UTILITY METHODS *
     *******************/

    /**
     * @param horizon string representing the number of months that are relevant
     * @param sjt the standard job time record in question
     *
     * @return dataset instance representing the baseline for the chart
     */
    private static DataSet getBaseline(String horizon, SVMX_PS_Standard_Job_Time__c sjt) {
        if (horizon == '1') {
            return new DataSet('base', Integer.valueOf(sjt.SVMX_PS_1MoAvg__c));
        }
        else if (horizon == '3') {
            return new DataSet('base', Integer.valueOf(sjt.SVMX_PS_3MoAvg__c));
        }
        else if (horizon == '6') {
            return new DataSet('base', Integer.valueOf(sjt.SVMX_PS_6MoAvg__c));
        }
        else {
            return new DataSet('base', Integer.valueOf(sjt.SVMX_PS_12MoAvg__c));
        }

    }

    /**
     * @param horizon string representing the number of months that are relevant
     *
     * @return datetime representing the first day of the relevant timeframe
     */
    private static Datetime getHorizonDate(String horizon) {
        if (horizon == '1') {
            return DateTime.now().addMonths(-1);
        }
        else if (horizon == '3') {
            return DateTime.now().addMonths(-3);
        }
        else if (horizon == '6') {
            return DateTime.now().addMonths(-6);
        }
        else {
            return DateTime.now().addMonths(-12);
        }

    }

    /*******************
     * UTILITY CLASSES *
     *******************/

    public class DataSet {
        public DataSet(String x, Decimal y) {
            this.x = x;
            this.y = y;
        }

        @AuraEnabled
        public String x {get;set;}
        @AuraEnabled
        public Decimal y {get;set;}
    }
}
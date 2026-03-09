/**
 *  Schedulable class for Work Order [SVMXC__Service_Order__c] Business Logic regarding Standard Job Time and related metrics.
 *  2021-01-21       b.s.salmans     created
 *  2021-03-31       frank           updated to include modelSeriesExclusions
 */

global with sharing class SMAX_PS_WorkOrderStandardJobTime_Batch implements Database.Batchable<SObject>, Schedulable {

    // NOTE: This batch job uses SOQL inside of Loops. The batch size MUST be kept small (e.g. 20)

    global void execute(SchedulableContext ctx)
    {
        SMAX_PS_WorkOrderStandardJobTime_Batch b = new SMAX_PS_WorkOrderStandardJobTime_Batch();
        Database.executeBatch(b, 20);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        // sjt query
        return Database.getQueryLocator([SELECT Id, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c, SVMX_PS_Order_Type__c FROM SVMX_PS_Standard_Job_Time__c]);
    }

    global void execute(Database.BatchableContext BC, List<SVMX_PS_Standard_Job_Time__c> sjts) {

        // variable declaration
        AggregateResult[] soqlResults;  //  soql results from aggregate query
        String qry;  //  query string
        String dummyQry;  //  query string
        String clause_1;  //  WHERE clause for query
        String clause_2;  //  WHERE clause for query
        Integer timeFrame;  //  number of months to include in query
        String innerQueryHaHa;

        // build query string
        qry = 'SELECT COUNT(Id) counter, AVG(SMAX_PS_Sum_of_Labor__c) average,\n' +
                ' MAX(SMAX_PS_Sum_of_Labor__c) maximum, MIN(SMAX_PS_Sum_of_Labor__c) minimum\n' +
                ' FROM SVMXC__Service_Order__c\n' +
                ' WHERE ';

        // for each sjt...
        for(SVMX_PS_Standard_Job_Time__c sjt:sjts) {

            List<String> modelSeriesExclusions = new List<String>();
            if (sjt.SVMX_PS_Model_Series__c == SMAX_PS_WorkOrderStandardJobTime.WILDCARD) {
                modelSeriesExclusions = SMAX_PS_WorkOrderStandardJobTime.getAllModelSeries(sjt.SVMX_PS_Order_Type__c, sjt.SVMX_PS_Product_Line__c);
            }

            // ...build soql WHERE clause (minus time frame)...
            dummyQry = qry;
            clause_1 = ' SVMXC__Order_Type__c = \''+sjt.SVMX_PS_Order_Type__c+'\' AND SMAX_PS_IP_Product_Line__c = \''+sjt.SVMX_PS_Product_Line__c+'\'';
            clause_2 = sjt.SVMX_PS_Model_Series__c == SMAX_PS_WorkOrderStandardJobTime.WILDCARD
                    ? ' AND SMAX_PS_ModelSeries__c NOT IN :modelSeriesExclusions'
                    : ' AND SMAX_PS_ModelSeries__c = \''+sjt.SVMX_PS_Model_Series__c+'\'';
            System.debug('qry: '+dummyQry);
            System.debug('clause_1: '+clause_1);
            System.debug('clause_2: '+clause_2);
            dummyQry += clause_1 + clause_2;
            System.debug('qry (pre date): '+dummyQry);

            // ...fetch metrics via aggregate SOQL for each time frame (1 mo, 3 mo, 6 mo, 12 mo)...
            for(Integer x = 0; x < 5; x++) {
                timeFrame = x == 0 ? 1 : x * 3;
                if(timeFrame == 9) continue;

                // add time frame to query
                Datetime dummyDT = Datetime.now().addMonths(-timeFrame);
                String theTimeFrame = dummyDT.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                innerQueryHaHa = dummyQry + ' AND SVMXC__Completed_Date_Time__c > '+theTimeFrame;

                System.debug('qry (post date): '+innerQueryHaHa);

                soqlResults = Database.query(innerQueryHaHa);

                // ...update sjt values...
                for(AggregateResult ar:soqlResults) {
                    sjt.put('SVMX_PS_' + timeFrame + 'MoRecCnt__c', Integer.valueOf(ar.get('counter')));
                    sjt.put('SVMX_PS_' + timeFrame + 'MoAvg__c', Double.valueOf(ar.get('average')));
                    sjt.put('SVMX_PS_' + timeFrame + 'MoMax__c', Double.valueOf(ar.get('maximum')));
                    sjt.put('SVMX_PS_' + timeFrame + 'MoMin__c', Double.valueOf(ar.get('minimum')));
                }
            }
        }

        // ...and update sjt records
        update sjts;
    }

    global void finish(Database.BatchableContext BC) { }
}
@isTest
private class TestscheduledeDeleteTrashCases{

static testMethod void TestscheduledeDeleteTrashCases() {

            Test.startTest();
            String CRON_EXP = '0 0 0 1 1 ? 2026';  
            String jobId = System.schedule('TestscheduledeDeleteTrashCases', CRON_EXP, new SchedulerClassToDeleteTrashCases() );

            CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];

            System.assertEquals(CRON_EXP, ct.CronExpression); 
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals('2026-01-01 00:00:00', String.valueOf(ct.NextFireTime));

            Test.stopTest();
            }
}
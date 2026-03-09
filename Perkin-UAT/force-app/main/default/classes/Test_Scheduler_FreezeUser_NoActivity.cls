/*
 Test class for the scheduler Scheduler_FreezeUser_NoActivity  
*/
@isTest
public class Test_Scheduler_FreezeUser_NoActivity {
    
    @isTest(seeAllData=true)
    public static void testScheduler()
    {
        Test.StartTest();
        Scheduler_FreezeUsers_NoActivity scheduler = new Scheduler_FreezeUsers_NoActivity();      
        String cronExpr = '0 0 0 ? * * *';
        system.schedule('Test Freeze Users Daily Schedule', cronExpr, scheduler);
        Test.stopTest();
    }
    
}
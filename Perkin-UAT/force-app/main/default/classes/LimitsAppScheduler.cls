public class LimitsAppScheduler implements Schedulable {
    
    public void execute(SchedulableContext context){ 
        // In this code, the LimitsApp class is instantiated and its getLimits() method 
        // is called before scheduling another instance of the LimitsAppScheduler class to run in an hour.
        //LimitsApp limitsApp = new LimitsApp();
        LimitsApp.getLimits(); 
    }
}
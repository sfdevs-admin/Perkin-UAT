public with sharing class SMAX_PS_PlatformEventController {

	private final SMAX_PS_Platform_Event_Log__c eventLog;
    public Boolean readyToResend { get { return this.results == null; }}
    public String results { get; set; }

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public SMAX_PS_PlatformEventController(ApexPages.StandardController stdController) {
        SMAX_PS_Platform_Event_Log__c temp = (SMAX_PS_Platform_Event_Log__c)stdController.getRecord();
        this.eventLog = [SELECT Id, Name FROM SMAX_PS_Platform_Event_Log__c WHERE Id = :temp.Id];
    }

    public void resendEvent()
    {
        String evtName = eventLog.Name;
        String retVal = SMAX_PS_PlatformEventUtility.resendEvent(evtName);
        this.results = (String.isBlank(retVal)) ? 'Success!' : retVal;
    }

}
/**************************************************************
 * 1. Ticket(s) that relates to this class -
 *    -
 *    INC0341178
 * 2. Description - 
 *    This is to update Type,Default Status and System Days Active value on Demo Log.
 *    Then Expiration Date will be extended, depending on the number of days set to System Days Active.
 * 
 * 3. Objects referenced - 
 *    Demo Log
 * 
 * 
 * 4. Callouts to additional Components (including their methods) or None - 
 *    None
 * 
 * 
 * 5. Dependant Class(es): 
 *    None
 * 
 * 6. Test Class Name - 
 *    DemoLogTestClass
 * 
 * 
 * 7. Is @Invocable (Yes or No): 
 *    No
 * 
 * 
 * 8. Author Name(s):  
 * -Michael Glassmaker 2019.11.14
 * -PwC Roshank Mehra 2023.06.12
 * 
 * *************************************************************/ 
public class DemoLogExpirationController {
    public String Did {get;set;}
    public String DemologName {get;set;}
    public String ActDays {get;set;}
    Public String Type {get;set;}
    Public String Status {get;set;}  
    Public Demo_Log__c d;
    public DemoLogExpirationController(){

        Did = ApexPages.currentPage().getparameters().get('Id');
        d = [Select id,Name,System_Days_Active__c,Default_Status__c,Type2__c From Demo_Log__c Where Id = :Did];
        DemologName = d.Name;
        ActDays = ApexPages.currentPage().getparameters().get('Days');
        Type = (ApexPages.currentPage().getparameters().get('typ') != 'null')?(ApexPages.currentPage().getparameters().get('typ')):d.Type2__c;
        Status = (ApexPages.currentPage().getparameters().get('Status') != 'null')?(ApexPages.currentPage().getparameters().get('Status')):d.Default_Status__c;

     }
    public PageReference submit(){
        /**************************************************************************
         	* We added condition to verify If newly selected value of System Days Active is same as prevous we will first make System Days Active as null/blank and will update newly passed value on System days active.
            * Incase newly selected value is not same as previous, we will directly update the value.
			* PWC Roshank Mehra(2023.06.12)
		***************************************************************************/
        if(D.System_Days_Active__c == ActDays){
			d.System_Days_Active__c = '';
			update d;
		}
        d.System_Days_Active__c = ActDays;
        d.Type2__c = Type;
        d.Default_Status__c = Status;
        update d;
        pageReference p = new PageReference('/' + d.id);
        p.setRedirect(true);
        return p;
    }
}
/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - INC0294925 - Used to show Field to complete Values on Community Portal for Dealers
*
* 2. Description - INC0294925 - Used to show Field to complete Values on Community Portal for Dealers 
*      becuase quick actions, field sets, and lighthning grid are not useable in Portal
*
*
* 3. Objects referenced
*    - Opportunity
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: none
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s): 
*    - (PwC Avinash Kumar) (2022.03.11)
*    - First Last & Updated Date(2022.03.11) 
*
*************************************************************/ 

public class OPP_FieldsToComplete_Controller {

    public Opportunity opp {get;set;}
    public List<Opportunity> opportunities {get;set;}
    public string opptyId {get;set;}
    
    public OPP_FieldsToComplete_Controller() {
        opp = new Opportunity();
        opportunities = new List<Opportunity>();
        opptyId =ApexPages.currentPage().getParameters().get('id');
    }
    
    public void showOpp() {
        //if(opp.StageName == 'Stage 1 - Create/Plan'){
            opportunities = [SELECT Id, 
                                    fxMissingFieldsstageCurrent__c
                                    ,fxMissingFieldsstageAll__c 
                                    FROM Opportunity where id=:opptyId];
        //}
        
    }
}
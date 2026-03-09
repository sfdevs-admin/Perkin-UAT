/**************************************************************
* 1. Jira Ticket(s)
*    - OM-334 Create SBX from index (This is asked by Brad to create a standard future proof Pause to initiate a different thread.)
*
* 2. Description - To create a standard future proof Pause to initiate a different thread.
*
* 3. Objects referenced
*    -C_SET_9998_SFDC_Log_Settings__c
*
* 4. Callouts to additional Components (including their methods) or None: NO
*    

* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: UTIL_PauseTest
* 
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav(PWC) & Created Date 7th March 2024
*    -
*    -
*************************************************************/ 
public class UTIL_Pause {
    @InvocableMethod
    public static void createNewtransaction(List<String> LeaveToggleOff_SelectStartNewTransaction){
        C_SET_9998_SFDC_Log_Settings__c mc = C_SET_9998_SFDC_Log_Settings__c.getOrgDefaults();
        mc.PauseTimestamp__c=system.now();
        String objJSONStr = Json.serialize(mc); 
        updateSobjectList( objJSONStr );
    }
    
    @future
    public static void updateSobjectList( String objstr ) {
        try{
            system.debug('@@objstr'+objstr);
            C_SET_9998_SFDC_Log_Settings__c obj=(C_SET_9998_SFDC_Log_Settings__c) Json.deserialize(objstr, System.Type.forName('C_SET_9998_SFDC_Log_Settings__c'));
            update obj; 
        }
        
        catch(exception ex) {
            system.debug('@@ex'+ex.getLineNumber());
            system.debug('@@ex'+ex.getMessage());
            
        }
    }
}
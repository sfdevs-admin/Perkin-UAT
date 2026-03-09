/*This scheduable class is used to update the ParentId field on the Account object
 * because the integration with SAP only brings over the Customer Base Number, and
 * does not populate the ParentId (the lookup field) on the Account.
 * 
 * Last Modified by Tony Tran on June 16, 2017
 */

global class UpdateParentAutomated implements Schedulable{
	List<Account>ListAccountsToUpdate = new List<Account>();
    integer i = 0;
    
    global void execute(SchedulableContext ctx) {     
        for(List<Account> ListAccounts : [SELECT Id, PKI_SAP_Customer_Base_Number__c FROM Account WHERE RecordType.Name = 'Customer' 
                                          AND PKI_SAP_Customer_Base_Number__c != '' AND ParentId = null 
                                          AND (Date_Parent_Last_Modified__c > LAST_N_DAYS:2 OR Date_Parent_Last_Modified__c = null)]){
        	List<String> ListAccountIds = new List<String>();
        
        	//Use this list to map the PKI SAP Customer Base Number into a list of IDs
        	if(!ListAccounts.isEmpty()) {
            	for(Account a: ListAccounts) {
                	ListAccountIds.add(a.PKI_SAP_Customer_Base_Number__c);
                	//System.debug('');
            	}
        
                //Then use the list to get a list of Account IDs where the Account's 'PKI SAP Customer Number' matches the 'PKI SAP Customer 
                //Base Number'               
            	List<Account> ListParentAccounts = [SELECT Id, PKI_SAP_Customer_Number__c FROM Account 
                                                    WHERE Account.PKI_SAP_Function__c = 'Hierarchy'];
            	Map<String, Id> MapParentAccounts = new Map<String, Id>();
            
            	if(!ListParentAccounts.isEmpty()) {
                	for(Account b: ListParentAccounts) {
                    	MapParentAccounts.put(b.PKI_SAP_Customer_Number__c, b.Id);
                    	//System.Debug('');
                	}        
            
            		//go through each account to see if it was in the list of ListAccountIds
                	for(Account c: ListAccounts){
                    	//If yes, update the ParentId
                    	if(MapParentAccounts.containsKey(c.PKI_SAP_Customer_Base_Number__c))
                        	c.ParentId = MapParentAccounts.get(c.PKI_SAP_Customer_Base_Number__c);
                        	//System.Debug('');
                    	else
                        	c.Date_Parent_Last_Modified__c = system.today();
                        	//System.Debug('');
                    	ListAccountsToUpdate.add(c);
                	}
                }
            }
                                              i++;
                                              if(i == 66)
                                                  break;
                                          }
            
                //Then update the ListAccountsToUpdate            
                if(!ListAccountsToUpdate.isEmpty())
                    update ListAccountsToUpdate;
                    //System.Debug('');	
    }
}
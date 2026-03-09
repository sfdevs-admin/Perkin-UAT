/*This scheduable class is used to update the lookup fields on the Function object
 * because the integration with SAP only brings over the Customer Number, and the
* Partner Site's SAP Number 
 * 
 * Last Modified by Tony Tran on June 16, 2017
 */

global class UpdateFunctionsAutomated implements Schedulable{

    List<Function__c> ListFunctionsToUpdate = new List<Function__c>();
    Integer i = 0;
    global void execute(SchedulableContext ctx) {
        for (List<Function__c> ListFunctions : [SELECT Id, PKI_SAP_Sold_To_Account_Number__c, PKI_SAP_Partner_Site_Number__c FROM Function__c 
                                                WHERE (Sold_To_Account__r.Name = 'Default for SAP Integration' OR Partner_Site__r.PKI_SAP_Name_1__c = 'Default for SAP Integration') 
                                                AND (Date_Lookups_Last_Modified__c > LAST_N_DAYS:2 OR Date_Lookups_Last_Modified__c = null)]){

        	List<String> ListSoldToIds = new List<String>();
        	List<String> ListPartnerIds = new List<String>();
        
        	//Use this list to map the PKI SAP Customer Base Number into a list of IDs
        	if(!ListFunctions.isEmpty()) {
            	for(Function__c a: ListFunctions) {
                	ListSoldToIds.add(a.PKI_SAP_Sold_To_Account_Number__c);
                	ListPartnerIds.add(a.PKI_SAP_Partner_Site_Number__c);
                	//System.debug('');
            	}
            
				List<Account> ListAccounts = [SELECT Id, PKI_SAP_Customer_Number__c 
                                              FROM Account WHERE PKI_SAP_Customer_Number__c IN :ListSoldToIds];
        
        		List<Partner_Site__c> ListPSs = [SELECT Id, PKI_SAP_Customer_Number__c 
                                                 FROM Partner_Site__c WHERE PKI_SAP_Customer_Number__c IN :ListPartnerIds];
            
            	Map<String, Id> MapAccounts = new Map<String, Id>();
        		Map<String, Id> MapPSs = new Map<String, Id>();
        
        		if(!ListAccounts.isEmpty()) {
            		for(Account b: ListAccounts) {
                		MapAccounts.put(b.PKI_SAP_Customer_Number__c, b.Id);
                		//System.Debug('');
            		}
        		}
            
            	if(!ListPSs.isEmpty()) {
            		for(Partner_Site__c c: ListPSs) {
                		MapPSs.put(c.PKI_SAP_Customer_Number__c, c.Id);
                		//System.Debug('');
            		}
        		}
                        	        
        		//go through each account to see if it was in the list of ListAccountIds
        		Integer j = 0;
        		for(Function__c d: ListFunctions){
                	//If yes, update the ParentId
                    if(MapAccounts.containsKey(d.PKI_SAP_Sold_To_Account_Number__c)){
                    	d.Sold_To_Account__c = MapAccounts.get(d.PKI_SAP_Sold_To_Account_Number__c);
                    	j++;
                        //System.Debug('');
                    }                   
                	
                    if(MapPSs.containsKey(d.PKI_SAP_Partner_Site_Number__c)){
                    	d.Partner_Site__c = MapPSs.get(d.PKI_SAP_Partner_Site_Number__c);
                    	j++;
                    }
                    
                    if(j != 2)
                    	d.Date_Lookups_Last_Modified__c = system.today();
                	
                    ListFunctionsToUpdate.add(d);
                    j = 0;
                }
            }
                                                    i++;
                                                    if (i == 33)
                                                        break;
        }
        //Then update the ListAccountsToUpdate            
        if(!ListFunctionsToUpdate.isEmpty())
            update ListFunctionsToUpdate;
        	//System.Debug('I updated the list of Accounts');        
    }    
}
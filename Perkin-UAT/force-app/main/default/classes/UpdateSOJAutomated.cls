/*This scheduable class is used to update the lookup fields on the Function object
 * because the integration with SAP only brings over the Customer Number, and the
* Partner Site's SAP Number 
 * 
 * Last Modified by Tony Tran on June 16, 2017
 */

global class UpdateSOJAutomated implements Schedulable{

    List<SalesOrgJunction__c> ListSOJsToUpdate = new List<SalesOrgJunction__c>();
    Integer i = 0;
    global void execute(SchedulableContext ctx) {
        for (List<SalesOrgJunction__c> ListSOJs : [SELECT Id, PKI_SAP_Customer_Number__c, PKI_SAP_Sales_Org__c FROM SalesOrgJunction__c 
                                                WHERE (Related_Accounts__r.Name = 'Default for SAP Integration' OR Related_Sales_Orgs__r.Name = 'Default') 
                                                AND (Date_Lookups_Last_Modified__c > LAST_N_DAYS:2 OR Date_Lookups_Last_Modified__c = null)]){

        	List<String> ListAccountIds = new List<String>();
        	List<String> ListSalesOrgIds = new List<String>();
        
        	//Use this list to map the PKI SAP Customer Base Number into a list of IDs
        	if(!ListSOJs.isEmpty()) {
            	for(SalesOrgJunction__c a: ListSOJs) {
                	ListAccountIds.add(a.PKI_SAP_Customer_Number__c);
                	ListSalesOrgIds.add(a.PKI_SAP_Sales_Org__c);
                	//System.debug('');
            	}
            
				List<Account> ListAccounts = [SELECT Id, PKI_SAP_Customer_Number__c 
                                              FROM Account WHERE PKI_SAP_Customer_Number__c IN :ListAccountIds];
        
        		List<SalesOrg__c> ListSOs = [SELECT Id, PKISAPSalesOrg__c 
                                                 FROM SalesOrg__c WHERE PKISAPSalesOrg__c IN :ListSalesOrgIds];
            
            	Map<String, Id> MapAccounts = new Map<String, Id>();
        		Map<String, Id> MapSOs = new Map<String, Id>();
        
        		if(!ListAccounts.isEmpty()) {
            		for(Account b: ListAccounts) {
                		MapAccounts.put(b.PKI_SAP_Customer_Number__c, b.Id);
                		//System.Debug('');
            		}
        		}
            
            	if(!ListSOs.isEmpty()) {
            		for(SalesOrg__c c: ListSOs) {
                		MapSOs.put(c.PKISAPSalesOrg__c, c.Id);
                		//System.Debug('');
            		}
        		}
                        	        
        		//go through each account to see if it was in the list of ListAccountIds
        		Integer j = 0;
        		for(SalesOrgJunction__c d: ListSOJs){
                	//If yes, update the ParentId
                    if(MapAccounts.containsKey(d.PKI_SAP_Customer_Number__c)){
                    	d.Related_Accounts__c = MapAccounts.get(d.PKI_SAP_Customer_Number__c);
                    	j++;
                        //System.Debug('');
                    }                   
                	
                    if(MapSOs.containsKey(d.PKI_SAP_Sales_Org__c)){
                    	d.Related_Sales_Orgs__c = MapSOs.get(d.PKI_SAP_Sales_Org__c);
                    	j++;
                    }
                    
                    if(j != 2)
                    	d.Date_Lookups_Last_Modified__c = system.today();
                	
                    ListSOJsToUpdate.add(d);
                    j = 0;
                }
            }
                                                    i++;
                                                    if (i == 33)
                                                        break;
        }
        //Then update the ListAccountsToUpdate            
        if(!ListSOJsToUpdate.isEmpty())
            update ListSOJsToUpdate;
        	//System.Debug('');        
    }    
}
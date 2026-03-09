public with sharing class SMAX_PS_ServiceContractController {

	public SVMXC__Service_Contract__c con;
	public Integer numDays { get; set; }
	public Boolean isRunning { get; set; }

	public SMAX_PS_ServiceContractController(ApexPages.StandardController stdController)
	{
    	con = [SELECT Id,Name,RecordType.name 
    		   	FROM SVMXC__Service_Contract__c
    		   	WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
	}
	


	// SVMXCFG-692 - Schedule work orders from service contract
	public void scheduleWorkOrder()
	{
		if(con.recordType.name == 'Service Contract'){
			this.isRunning = TRUE;
			Database.executeBatch(new SMAX_PS_CreateScheduledWorkOrdersBatch(null, con.id, numDays));
		}	
		else if (con.recordType.Name == 'Contract Item'){
			this.isRunning = TRUE;
			Database.executeBatch(new SMAX_PS_CreateScheduledWorkOrdersBatch(con.id, null, numDays));
		}


		// TEST CODE TO VERIFY PAGE INPUT WAS BEING PASSED SUCCESSFULLY

		//PageReference pageRef1 = new PageReference('https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/Florida_State_University_seal.svg/270px-Florida_State_University_seal.svg.png');		
		//PageReference pageRef2 = new PageReference('https://upload.wikimedia.org/wikipedia/en/thumb/9/9e/Florida_Internation_University_seal.svg/250px-Florida_Internation_University_seal.svg.png');
		
		//if(con.recordType.name == 'Service Contract'){
		//	if(numDays == 30){
		//		return pageRef1;
		//	}	
		//	else if(numDays == 60){
		//		return pageRef2;
		//	}
		//	else {
		//	return null;
		//	}
		//	}
			
		//else if (con.recordType.Name == 'Contract Item'){
		//	if(numDays == 90){
		//		return pageRef1;
		//	}	
		//	else if(numDays == 120){
		//		return pageRef2;
		//	}
		//	}
		//	else{
		//		return null;
		//	}	
				
		//	}
		//else{
		//	return null;
		//}	
	}


}
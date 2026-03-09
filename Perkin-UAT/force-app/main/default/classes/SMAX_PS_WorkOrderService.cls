@RestResource(urlMapping='/SMAX_PS_WorkOrderService/*')
global class SMAX_PS_WorkOrderService {

	/**
	 *  Invoked from SFW Buttons (off the main Page Layout toolbar).. using the "Sync Lite" or "SFM Sync"
	 */
	webservice static SVMXC.INTF_WebServicesDef.INTF_Response syncWorkOrder(SVMXC.INTF_WebServicesDef.INTF_Request request)
	{
		SVMXC.SFMTransactionSync sfmTxnSync = new SVMXC.SFMTransactionSync();
		SVMXC.INTF_WebServicesDef.INTF_Response result = new SVMXC.INTF_WebServicesDef.INTF_Response(); 
		try{
			result = sfmTxnSync.updateRecord(request, result);
			
			////////////////////////
			// CUSTOM CODE - START

			// Get the record ID of the header record.
			String woId; 
			String woAction;
			for(SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap : request.valueMap)
			{
				if(objSVXMMap.key == 'SVMX_RECORDID' || objSVXMMap.key == 'Work_Order_Id') {
					woId = objSVXMMap.value;
				}
				if(objSVXMMap.key == 'Work_Order_Action') {
					woAction = objSVXMMap.value;
				}
			}

			if (woAction == 'COMPLETE')
			{
				SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
				wo.Id = woId;
				wo.SVMXC__Order_Status__c = 'Work Complete';
				wo.SVMXC__Completed_Date_Time__c = Datetime.now();
				update wo;
				result.message = 'Work Order Completed';
			}
			else if (woAction == 'SUBMIT')
			{
				SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
				wo.Id = woId;
				wo.SMAX_PS_SubmitAllLines__c = TRUE;
				update wo;
				result.message = 'Work Order Submitted';
			}
			else// if (woAction == 'REFRESH')
			{
                //SMAX_PS_IntegrationError__c ie = new SMAX_PS_IntegrationError__c();
                //ie.SMAX_PS_RelatedElementType__c = 'WorkOrderId';
                //ie.SMAX_PS_RelatedElementIdentifier__c = woId;
                //ie.SMAX_PS_ErrorMessage__c = 'Test Error from Refresh';
                //insert ie;
                
				// No action needed.. 
				result.message = 'Work Order Retrieved';
			}

		 	List<SVMXC__Service_Order__c> woList = SMAX_PS_Utility.loadFullObjects('SVMXC__Service_Order__c', 'WHERE Id = \'' + woId + '\'', null);
		 	SVMXC__Service_Order__c wo = woList.get(0);

            SVMXC.INTF_WebServicesDef.SVMXMap sObj = new SVMXC.INTF_WebServicesDef.SVMXMap();
			sObj.record = wo;
            result.valueMap.add(sObj); 

		 	List<SVMXC__Service_Order_Line__c> updatedLines = SMAX_PS_Utility.loadFullObjects('SVMXC__Service_Order_Line__c', 'WHERE SVMXC__Service_Order__c = \'' + woId + '\'', null);
			for (SVMXC__Service_Order_Line__c line : updatedLines)
            {
                SVMXC.INTF_WebServicesDef.SVMXMap svmxLine = new SVMXC.INTF_WebServicesDef.SVMXMap();
                svmxLine.record = line;
                result.valueMap.add(svmxLine); 
            }
            
            List<SMAX_PS_IntegrationError__c> ieList = [SELECT Id, Name, SMAX_PS_ErrorMessage__c,
            	SMAX_PS_WorkOrder__c, SMAX_PS_WorkDetail__c FROM SMAX_PS_IntegrationError__c 
                WHERE SMAX_PS_WorkOrder__c = :woId];
			for (SMAX_PS_IntegrationError__c ie : ieList)
            {
                SVMXC.INTF_WebServicesDef.SVMXMap svmxIE = new SVMXC.INTF_WebServicesDef.SVMXMap();
                svmxIE.record = ie;
                result.valueMap.add(svmxIE); 
            }
            
            result = sfmTxnSync.getRecord(result);
			result.success = true;
			result.messageType = 'INFO'; 
			return result; // Return should be of INTF_Response type and 
		} 
		catch(Exception ex) 
		{ 
			// Construct Failure response, Update response object members 
			result.message = ex.getMessage(); 
			result.success = false; 
			result.messageType = 'ERROR'; 
			return result; 
		}
	}

}
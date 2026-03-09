@RestResource(urlMapping='/SMAX_PS_WorkOrderPricingService/*')
global class SMAX_PS_WorkOrderPricingService 
{
	/**
	 *  Invoked from the "Get Price" SFW Button (off the main Page Layout toolbar).. using the "Sync Lite" or "SFM Sync"
	 */
	webservice static SVMXC.INTF_WebServicesDef.INTF_Response getPriceWorkOrderSync(SVMXC.INTF_WebServicesDef.INTF_Request request)
	{
		SVMXC.SFMTransactionSync sfmTxnSync = new SVMXC.SFMTransactionSync();
		SVMXC.INTF_WebServicesDef.INTF_Response result = new SVMXC.INTF_WebServicesDef.INTF_Response(); 
		try{
			result = sfmTxnSync.updateRecord(request, result);
			
			////////////////////////
			// CUSTOM CODE - START

			// Get the record ID of the header record.
			String recordId; 
			for(SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap : request.valueMap){ 
				if(objSVXMMap.key == 'SVMX_RECORDID' || objSVXMMap.key == 'Work_Order_Id') {
					recordId = objSVXMMap.value;
					break;
				}
			}

			SVMXC__Service_Order__c wo = [Select  Id, Name, CurrencyIsoCode, SVMXC__Order_Status__c, SVMXC__Order_Type__c,
				SMAX_PS_ContractEntitlement__c, SMAX_PS_SAP_ActivityType__c, SVMXC__Problem_Description__c,
				(SELECT Id, Name, SVMXC__Line_Type__c, SVMXC__Actual_Quantity2__c, SVMXC__Billable_Quantity__c,
					SVMXC__Billable_Line_Price__c, SVMXC__Actual_Price2__c, SVMXC__Product__c, 
					SVMXC__Discount__c, SMAX_PS_ContractPercentDiscount__c, SMAX_PS_UnitOfMeasure__c, SVMXC__Line_Status__c,
					SMAX_PS_Use_Product_Sales_UOM__c, SMAX_PS_UOM_Code__c, CurrencyIsoCode, BD_Discount_Type__c
					FROM SVMXC__Service_Order_Line__r) 
				FROM SVMXC__Service_Order__c 
				WHERE Id=:recordId]; 
		 
            //wo.SVMXC__Problem_Description__c = 'GetPrice Sync ran at ' + System.now();

			List<SVMXC__Service_Order_Line__c> priceableLines = filterPriceableLines(wo.SVMXC__Service_Order_Line__r);
			// Call Web Service
			String errorMsg = invokeGetPriceService(wo, priceableLines);
			if (errorMsg != null)
			{
				// SVMXCFG-181: Create an Integration Error record
				SMAX_PS_IntegrationError__c intErr = new SMAX_PS_IntegrationError__c();
				intErr.SMAX_PS_WorkOrder__c = wo.Id;
				intErr.SMAX_PS_ErrorMessage__c = errorMsg;
				intErr.SMAX_PS_RelatedElementIdentifier__c = (String)wo.Id;
				intErr.SMAX_PS_RelatedElementType__c = 'WorkOrderId';
				insert intErr;

				result.message = errorMsg;
				result.success = false; 
				result.messageType = 'ERROR'; 
				return result; 
			}
			//stubGetPriceService(wo, priceableLines);
			updateCurrency(wo, priceableLines);
			applyContractDiscounts(wo, priceableLines);
			if (!priceableLines.isEmpty())
				update priceableLines;

			// Load a updated copy of the WO first... to get latest roll-up summaries
            List<SVMXC__Service_Order__c> updatedWO = 
                SMAX_PS_Utility.loadFullObjects('SVMXC__Service_Order__c', null, new Set<Id> { wo.Id });
            if (updatedWO != null && !updatedWO.isEmpty())
            	wo = updatedWO.get(0);

			// commented this out to follow sample from smax..
			//result.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>(); 
            SVMXC.INTF_WebServicesDef.SVMXMap sObj = new SVMXC.INTF_WebServicesDef.SVMXMap();
			sObj.record = wo;
            result.valueMap.add(sObj); 

            Set<Id> lineIds = new Set<Id>();
			for (SVMXC__Service_Order_Line__c line : priceableLines)
            {
                lineIds.add(line.Id);
            }            
            List<SVMXC__Service_Order_Line__c> updatedLines = 
                SMAX_PS_Utility.loadFullObjects('SVMXC__Service_Order_Line__c', null, lineIds);
			for (SVMXC__Service_Order_Line__c line : updatedLines)
            {
                SVMXC.INTF_WebServicesDef.SVMXMap svmxLine = new SVMXC.INTF_WebServicesDef.SVMXMap();
                svmxLine.record = line;
                result.valueMap.add(svmxLine); 
            }
            
            result = sfmTxnSync.getRecord(result);
			result.message = 'Work Order updated';
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

    /**
	 *  Invoked from the "Get Price" Button inside a Work Order Debrief SFM
	 *  @question: This approach is not visible in FSA. Do we want ot use this approach in browser, or use the "SFW" Approach below?
	 */
	webservice static SVMXC.SFM_WrapperDef.SFM_PageData priceWorkOrder(SVMXC.SFM_WrapperDef.SFM_TargetRecord request) 
	{
		SVMXC.SFM_ServicesDef servicesDef = new SVMXC.SFM_ServicesDef();
		Map<String, Schema.SObjectType> allObjMap = Schema.getGlobalDescribe();
		Sobject header = servicesDef.SFM_Page_GetHeaderRecord(request, allObjMap);
		Map<String, List<Sobject>> detailListMap = servicesDef.SFM_Page_GetDetailRecords(request, allObjMap);

		System.debug('~~~ GetPrice WO Header = ' + header);

		// PROBLEM: header has an invisible field named "attributes" that breaks web service serialization
		// NOTE: Clone doesn't work.. Clone copies the 'attributes' LinkedHashMap
		// NOTE: Creating a blank object, then copying fields is problematic.. all read only fields are not allowed to be set (including Name, Formulas, etc.)
		// FIX: Load full object from db, then overlay with values from request..
		SVMXC__Service_Order__c wo = (SVMXC__Service_Order__c) (SMAX_PS_Utility.loadFullObjects('SVMXC__Service_Order__c', 'WHERE Id = \'' + header.Id + '\'', null)[0]);
		Map<String, Schema.SObjectField> allWoFields = SMAX_PS_Utility.getFields('SVMXC__Service_Order__c');
		Map<String,Object> woFieldMap = header.getPopulatedFieldsAsMap();
		for (String fieldName : woFieldMap.keySet())
		{
			Schema.DescribeFieldResult field = allWoFields.get(fieldName).getDescribe();
			if (field.isUpdateable())
				wo.put(fieldName, header.get(fieldName));
		}

		System.debug('~~~ GetPrice WO = ' + wo);

		List<SVMXC__Service_Order_Line__c> priceableLines = new List<SVMXC__Service_Order_Line__c>();
		for (String key : detailListMap.keySet())
		{
			List<SVMXC__Service_Order_Line__c> lines = detailListMap.get(key);
			priceableLines.addAll(filterPriceableLines(lines));
		}

		// Call Web Service
		String errorMsg = invokeGetPriceService(wo, priceableLines);
		updateCurrency(wo, priceableLines);
		applyContractDiscounts(wo, priceableLines);

		SVMXC.SFM_WrapperDef.SFM_PageData pageData = new SVMXC.SFM_WrapperDef.SFM_PageData();
		pageData =  servicesDef.SFM_Page_BuildResponse(request, wo, detailListMap);
		if (errorMsg != null)
		{
			// How do we report this error???
			pageData.response.message = errorMsg;
			pageData.response.success = FALSE;
			//SVMXC.SFM_WrapperDef.SFM_Response .message  .success
		}
		System.debug('*****'+pageData);
		return pageData;
	}

	/**
	 *  Invoked from the "Get Price" SFW Button (off the main Page Layout toolbar)
	 */
	webservice static SVMXC.INTF_WebServicesDef.INTF_Response getPriceWorkOrder(SVMXC.INTF_WebServicesDef.INTF_Request request)
	{
		SVMXC.INTF_WebServicesDef.INTF_Response result = new SVMXC.INTF_WebServicesDef.INTF_Response(); 
		try 
		{
			String recordId; 
			for (SVMXC.INTF_WebServicesDef.SVMXMap objSVXMMap : request.valueMap) 
			{
				if(objSVXMMap.key == 'Work_Order_Id') // 'SVMX_RECORDID') 
				{ 
					recordId = objSVXMMap.value; 
				} 
			} 

			SVMXC__Service_Order__c wo = [Select  Id, Name, CurrencyIsoCode, SVMXC__Order_Status__c, SVMXC__Order_Type__c,
				SMAX_PS_ContractEntitlement__c, SMAX_PS_SAP_ActivityType__c,
				(SELECT Id, Name, SVMXC__Line_Type__c, SVMXC__Actual_Quantity2__c, SVMXC__Billable_Quantity__c,
					SVMXC__Billable_Line_Price__c, SVMXC__Actual_Price2__c, SVMXC__Product__c, 
					SVMXC__Discount__c, SMAX_PS_ContractPercentDiscount__c, SMAX_PS_UnitOfMeasure__c, SVMXC__Line_Status__c,
					SMAX_PS_Use_Product_Sales_UOM__c, SMAX_PS_UOM_Code__c, CurrencyIsoCode, BD_Discount_Type__c
					FROM SVMXC__Service_Order_Line__r) 
				FROM SVMXC__Service_Order__c 
				WHERE Id=:recordId]; 
		 
			SVMXC.INTF_WebServicesDef.SVMXMap sObj = new SVMXC.INTF_WebServicesDef.SVMXMap();
			sObj.record = wo;

			List<SVMXC__Service_Order_Line__c> priceableLines = filterPriceableLines(wo.SVMXC__Service_Order_Line__r);
			// Call Web Service
			String errorMsg = invokeGetPriceService(wo, priceableLines);
			if (errorMsg != null)
			{
				// SVMXCFG-181: Create an Integration Error record
				SMAX_PS_IntegrationError__c intErr = new SMAX_PS_IntegrationError__c();
				intErr.SMAX_PS_WorkOrder__c = wo.Id;
				intErr.SMAX_PS_ErrorMessage__c = errorMsg;
				intErr.SMAX_PS_RelatedElementIdentifier__c = (String)wo.Id;
				intErr.SMAX_PS_RelatedElementType__c = 'WorkOrderId';
				insert intErr;

				result.message = errorMsg;
				result.success = false; 
				result.messageType = 'ERROR'; 
				return result; 
			}
			//stubGetPriceService(wo, priceableLines);
			updateCurrency(wo, priceableLines);
			applyContractDiscounts(wo, priceableLines);
			if (!priceableLines.isEmpty())
				update priceableLines;

			result.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>(); 
			result.valueMap.add(sObj); 

			result.message = 'Work Order updated';
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

	private static Set<String> PRICEABLE_LINE_TYPES = new Set<String> { 'Parts', 'Labor', 'Travel', 'Expenses' };
	private static Set<String> PRICEABLE_LINE_STATUSES = new Set<String> { 'Open', 'Priced' };

	/**
	 *  Filter Lines to only return the "priceable" ones.
	 */
	private static List<SVMXC__Service_Order_Line__c> filterPriceableLines(List<SVMXC__Service_Order_Line__c> lines)
	{
		List<SVMXC__Service_Order_Line__c> priceableLines = new List<SVMXC__Service_Order_Line__c>();
		for (SVMXC__Service_Order_Line__c line : lines)
		{
			if (PRICEABLE_LINE_TYPES.contains(line.SVMXC__Line_Type__c) && PRICEABLE_LINE_STATUSES.contains(line.SVMXC__Line_Status__c))
			{	
				//Decimal qty = (line.SVMXC__Billable_Quantity__c == null) ? line.SVMXC__Actual_Quantity2__c : line.SVMXC__Billable_Quantity__c;
				Decimal qty = line.SVMXC__Actual_Quantity2__c;
				if (qty != null)
				{
					priceableLines.add(line);
				}
				else
				{
					System.debug('~~ Skipping NULL-Qty Line: ' + line.SVMXC__Line_Type__c + ' - ' + line);
				}
			}
			else
			{
				System.debug('~~ Skipping NON-Priceable Line: ' + line.SVMXC__Line_Type__c + ' - ' + line);
			}
		}
		return priceableLines;
	}

	/**
	 *  Fill in a random price for each line between 0.00 - 100.00.
	 */
	public static void stubGetPriceService(SVMXC__Service_Order__c wo, List<SVMXC__Service_Order_Line__c> lines)
	{
		System.debug('STUBBING GetPrice Amounts.. ');
		for (SVMXC__Service_Order_Line__c line : lines)
		{
			Decimal qty = (line.SVMXC__Billable_Quantity__c == null) ? line.SVMXC__Actual_Quantity2__c : line.SVMXC__Billable_Quantity__c;
			System.debug('STUBBING GetPrice Amounts and qty is' + qty);
			line.SVMXC__Actual_Price2__c = Math.random() * 100.00;
			line.SVMXC__Billable_Line_Price__c = line.SVMXC__Actual_Price2__c * qty;
			line.SVMXC__Line_Status__c = 'Priced';
		}
	}

	/**
	 *  Invoke the PKI "Get Price" Web Service using the SMAX Config: 'WORD009', 'GET_PRICE_URL'
	 *  The resulting price is populated into the Work Detail line price.
	 */
	public static String invokeGetPriceService(SVMXC__Service_Order__c wo, List<SVMXC__Service_Order_Line__c> lines)
	{
		SVMXC__Service_Order__c relatedData = [SELECT SVMXC__Company__r.PKI_SAP_Customer_Number__c,
			SMAX_PS_ShipTo__r.PKI_SAP_Customer_Number__c, SMAX_PS_Payer__r.PKI_SAP_Customer_Number__c,
			SVMXC__Component__r.SMAX_PS_SalesOrg__c, SVMXC__Site__c, SVMXC__Site__r.SMAX_PS_SalesOrg__c
			FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];		

		String salesOrg = relatedData.SVMXC__Site__r.SMAX_PS_SalesOrg__c;
		Set<Id> productIds = new Set<Id>();
		Map<String, SVMXC__Service_Order_Line__c> lineMap = new Map<String, SVMXC__Service_Order_Line__c>();
		Integer newLineCount = 0;
		for (SVMXC__Service_Order_Line__c line : lines)
		{
			if (line.SVMXC__Product__c == null)
				continue;

			productIds.add(line.SVMXC__Product__c);
			// If line hasn't been saved yet, use a temp value..
			String name = (line.Name == null) ? 'NEW-' + (++newLineCount) : line.Name;
			lineMap.put(name, line);
		}

		// SVMXINT-465 - Handle No-Lines Error
		if (lineMap.size() == 0)
		{
			return 'No Work Detail Lines are ready to price. Please ensure both Product and Qty has been entered.';
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>(
			[SELECT Id, Name, Partnum__c, QuantityUnitOfMeasure, PKI_Qty_UOM_Code__c,
				(SELECT Id, SMAX_PS_ExternalID__c, SMAX_PS_SalesOrg__c, SMAX_PS_SalesUnit__c, SMAX_PS_Sales_Unit_Code__c 
					FROM Product_Sales__r WHERE SMAX_PS_SalesOrg__c = :salesOrg)
				FROM Product2 WHERE Id IN :productIds]);

		XmlStreamWriter w = new XmlStreamWriter();
		w.writeStartDocument(null, '1.0');
		w.writeStartElement(null, 'Order', null);
			w.writeStartElement(null, 'Header', null);
				w.writeStartElement(null, 'SalesOrg', null);
				if (salesOrg == null)
					return 'Cannot price a Work Order without a valid SalesOrg. Please correct and retry.';
				w.writeCharacters(salesOrg);
				w.writeEndElement(); // SalesOrg

				if (wo.SMAX_PS_SAP_ActivityType__c != null)
				{
					w.writeStartElement(null, 'OrderType', null);
					w.writeCharacters(wo.SMAX_PS_SAP_ActivityType__c); //wo.SVMXC__Order_Type__c);
					w.writeEndElement(); // OrderType
				}
				w.writeStartElement(null, 'PartnerSystemOrderNo', null);
				w.writeCharacters(wo.Name);
				w.writeEndElement(); // PartnerSystemOrderNo
				w.writeStartElement(null, 'Partners', null);
					w.writeStartElement(null, 'Partner', null);
						w.writeStartElement(null, 'PartnerType', null);
						w.writeCharacters('SoldTo');
						w.writeEndElement(); // PartnerType
						w.writeStartElement(null, 'PartnerNumber', null);
						w.writeCharacters(relatedData.SVMXC__Company__r.PKI_SAP_Customer_Number__c);
						w.writeEndElement(); // PartnerNumber
					w.writeEndElement(); // Partner
					w.writeStartElement(null, 'Partner', null);
						w.writeStartElement(null, 'PartnerType', null);
						w.writeCharacters('ShipTo');
						w.writeEndElement(); // PartnerType
						w.writeStartElement(null, 'PartnerNumber', null);
						String shipToId = (relatedData.SMAX_PS_ShipTo__r == null || relatedData.SMAX_PS_ShipTo__r.PKI_SAP_Customer_Number__c == null) 
							? null : relatedData.SMAX_PS_ShipTo__r.PKI_SAP_Customer_Number__c;
						if (shipToId == null)
							return 'Cannot price a Work Order without a valid Ship-To Account. Please correct and retry.';
						w.writeCharacters(shipToId);
						w.writeEndElement(); // PartnerNumber
					w.writeEndElement(); // Partner
					w.writeStartElement(null, 'Partner', null);
						w.writeStartElement(null, 'PartnerType', null);
						w.writeCharacters('Payer');
						w.writeEndElement(); // PartnerType
						w.writeStartElement(null, 'PartnerNumber', null);
						String payerId = (relatedData.SMAX_PS_Payer__r == null || relatedData.SMAX_PS_Payer__r.PKI_SAP_Customer_Number__c == null) 
							? null : relatedData.SMAX_PS_Payer__r.PKI_SAP_Customer_Number__c;
						if (payerId == null)
							return 'Cannot price a Work Order without a valid Payer Account. Please correct and retry.';
						w.writeCharacters(payerId);
						w.writeEndElement(); // PartnerNumber
					w.writeEndElement(); // Partner
				w.writeEndElement(); // Partners
			w.writeEndElement(); // Header
			w.writeStartElement(null, 'Detail', null);
			Integer lineCount = 0;
			for (String lineName : lineMap.keySet())
			{
				SVMXC__Service_Order_Line__c line = lineMap.get(lineName);
				Product2 prod = productMap.get(line.SVMXC__Product__c);
				lineCount++;
				w.writeStartElement(null, 'LineItem', null);
					w.writeStartElement(null, 'Direction', null);
					w.writeCharacters('In');
					w.writeEndElement(); // Direction(In)

					w.writeStartElement(null, 'PartnerLineNumber', null);
					w.writeCharacters(lineName);
					w.writeEndElement(); // PartnerLineNumber
					w.writeStartElement(null, 'Material', null);
					w.writeCharacters(prod.Partnum__c + '');
					w.writeEndElement(); // Material
					w.writeStartElement(null, 'Quantity', null);
					w.writeCharacters(line.SVMXC__Actual_Quantity2__c + '');
					w.writeEndElement(); // Quantity
					if (line.SMAX_PS_Use_Product_Sales_UOM__c == TRUE)
					{
						SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(line, salesOrg, prod);
						w.writeStartElement(null, 'UnitOfMeasure', null);
						//w.writeCharacters(line.SMAX_PS_UnitOfMeasure__c + '');
						w.writeCharacters(line.SMAX_PS_UOM_Code__c + '');
						w.writeEndElement(); // UnitOfMeasure
					}
				w.writeEndElement(); // LineItem
			}
				w.writeStartElement(null, 'Summary', null);
					w.writeStartElement(null, 'TotalNoLines', null);
					w.writeCharacters(lineCount + '');
					w.writeEndElement(); // TotalNoLines
				w.writeEndElement(); // Summary
			w.writeEndElement(); // Detail
		w.writeEndElement(); // Order

		String xmlRQ = w.getXmlString();
		w.close();

		SVMXC.COMM_Utils_ManageSettings settings = new SVMXC.COMM_Utils_ManageSettings();
		// "Work Order" / "Calculate Price for Work Order Usage"
		Map<String, String> mySettings = settings.SVMX_getSettingList('WORD009', 'GET_PRICE_URL');
		System.debug('~ WORD009 Settings: ' + mySettings);
		String url = mySettings.get('GET_PRICE_URL');
		//url = 'https://qa.integrationplatform.perkinelmer.com/ws/rest/ServiceMax/Query/GetPrice;boomi_auth=U0ZEQ0BwZXJraW5lbG1lci1TMUxCNlk6YTgzNWE1ZjItMTdlNS00NDU4LWI1ODEtZjAxMWJiYjA1NGZm';
		//url = 'https://qa.integrationplatform.perkinelmer.com/ws/rest/ServiceMax/Query/GetPrice;boomi_auth=U0ZEQ0BwZXJraW5lbG1lci1TMUxCNlk6MzIzZmJkNzItM2U1OC00MjJmLTgxMzMtNjMyZWM1MzhmMjg2';
		//url = 'https://CORWALBOOMIDEV.PERKINELMER.NET/ws/rest/ServiceMax/Query/GetPrice;boomi_auth=dGVzdEBwZXJraW5lbG1lci1TMUxCNlk6ODgwYmY0YmItNjRiMS00NzM3LWIyOTMtNTYzZDZmOGQzYzdj';
		//url = 'https://34.232.166.9/ws/rest/ServiceMax/Query/GetPrice;boomi_auth=U0ZEQ0BwZXJraW5lbG1lci1TMUxCNlk6MzIzZmJkNzItM2U1OC00MjJmLTgxMzMtNjMyZWM1MzhmMjg2';
		//url = 'https://34.232.166.9/ws/rest/ServiceMax/Query/GetPrice;boomi_auth=dGVzdEBwZXJraW5lbG1lci1TMUxCNlk6ODgwYmY0YmItNjRiMS00NzM3LWIyOTMtNTYzZDZmOGQzYzdj';
		System.debug('~ GET_PRICE_URL = ' + url);

		HttpRequest req = new HttpRequest(); 
		req.setMethod('POST');
		req.setBody(xmlRQ);
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setHeader('Accept', 'application/xml');
		req.setTimeout(60000);

		String xmlRS = null;
		if (Test.isRunningTest())
		{
			stubGetPriceService(wo, lines);
			xmlRS = '<?xml version="1.0"?><WO>';
			for (String lineNumber : lineMap.keySet())
			{
				SVMXC__Service_Order_Line__c line = lineMap.get(lineNumber);
				xmlRS += '<Line><PartnerLineNumber>' + lineNumber + '</PartnerLineNumber><UnitPrice>' + line.SVMXC__Actual_Price2__c + '</UnitPrice></Line>';
			}
			xmlRS += '</WO>';
		}
		else
		{
			req.setEndpoint(url);
			Http http = new Http();
			HTTPResponse res = http.send(req);
			xmlRS = res.getBody();
			System.debug('STATUS:' + res.getStatus());
			System.debug('STATUS_CODE:' + res.getStatusCode());
			if (res.getStatusCode() != 200)
			{
				return 'Received HTTP Error Code: ' + res.getStatusCode() + ' - ' + res.getStatus();
			}
		}

		System.debug('PRICING RESPONSE XML: ' + xmlRS);

		//if (xmlRS == 'Success')
		//{
		//	// Temporary.. until Boomi returns actual RS XML
		//	stubGetPriceService(wo, lines);
		//	return null;
		//}

		String errorMsg = null;
		try
		{
			XmlStreamReader r = new XmlStreamReader(xmlRS);
			String currentElement = null;
			SVMXC__Service_Order_Line__c currentLine = null;
			while (r.hasNext())
			{
				r.next();
				if (r.getEventType() == XmlTag.START_ELEMENT)
				{
					currentElement = r.getLocalName();
				}
				else if (r.getEventType() == XmlTag.CHARACTERS)
				{
					if (currentElement == 'PartnerLineNumber')
					{
						String lineNumber = r.getText();
						currentLine = lineMap.get(lineNumber);
					}
					else if (currentElement == 'Currency' && currentLine != null)
					{
						String currencyCode = r.getText();
						currentLine.CurrencyIsoCode = currencyCode;
						System.debug('PRICING: Received Currency Code: ' + currencyCode + ' for line: ' + currentLine);
					}
					else if (currentElement == 'UnitPrice' && currentLine != null)
					{
						Decimal amount = Decimal.valueOf(r.getText());
						currentLine.SVMXC__Actual_Price2__c = amount / currentLine.SVMXC__Actual_Quantity2__c; // THIS IS TEMPORARY
						currentLine.SVMXC__Line_Status__c = 'Priced';
						System.debug('PRICING: Received price: ' + amount + ' for line: ' + currentLine);
					}
					else if (currentElement == 'error' || currentElement == 'errorMessage')
					{
						String msg = r.getText();
						if (String.isNotBlank(msg))
						{
							errorMsg = (errorMsg == null) ? 'Error returned from GetPrice Web Service: ' : errorMsg + ' : ';
							errorMsg += msg;
						}
					}
					currentElement = null; // Clear out this value, so only get 1st characters for each tag
				}
			}
		}
		catch(Exception ex) 
		{ 
			System.debug('PRICING: Error Parsing Result: ' + ex);
			return 'Error parsing result: ' + ex.getMessage();
		}

		return errorMsg;
	}

	// SVMXCFG-809 - Copy Currency to the WO header also
	public static void updateCurrency(SVMXC__Service_Order__c wo, List<SVMXC__Service_Order_Line__c> lines)
	{
		SVMXC__Service_Order_Line__c line = (lines.isEmpty()) ? null : lines.get(0);
		if (line != null && line.CurrencyIsoCode != null && line.CurrencyIsoCode != wo.CurrencyIsoCode)
		{
			wo.CurrencyIsoCode = line.CurrencyIsoCode;

			SVMXC__Service_Order__c tempWo = new SVMXC__Service_Order__c();
			tempWo.Id = wo.Id;
			tempWo.CurrencyIsoCode = wo.CurrencyIsoCode;
			update tempWo;
		}
	}

	/**
	 *  The following method looks up the Contract Discounts from the associated "Contract Entitlement" record,
	 *  and applies the correct Discount based on the Product Type (Labor, Travel, Parts, Consumables).
	 */
	public static void applyContractDiscounts(SVMXC__Service_Order__c wo, List<SVMXC__Service_Order_Line__c> lines)
	{
		// Use the Product2.SVMXC__Product_Type__c to determine the correct...
		// ...Contract Discount to apply [Labor, Parts, Travel, Consumables]
		Id entId = wo.SMAX_PS_ContractEntitlement__c;
		if (entId != null)
		{
			// ITSFDC-350 Lookup WO + Ent + Fields needed for CDE Filter
			SVMXC__Service_Order__c woDetails = [SELECT Id, Name,
					SMAX_PS_ContractEntitlement__r.SVMXC__Labor_Discount_Covered__c,
					SMAX_PS_ContractEntitlement__r.SVMXC__Parts_Discount_Covered__c,
					SMAX_PS_ContractEntitlement__r.SVMXC__Travel_Discount_Covered__c,
					SMAX_PS_ContractEntitlement__r.SMAX_PS_ConsumableDiscountCovered__c,
					SMAX_PS_ContractEntitlement__r.SMAX_PS_ServicePartsDiscountCovered__c,
					SVMXC__Component__c, SVMXC__Component__r.SVMXC__Product__c,
					SVMXC__Site__r.SMAX_PS_SalesOrg__c, SMAX_PS_SAP_ActivityType__c
				FROM SVMXC__Service_Order__c WHERE Id = :wo.Id];
//			SVMXC__Service_Contract_Services__c ent = [SELECT Id, Name,
//				SVMXC__Labor_Discount_Covered__c, SVMXC__Parts_Discount_Covered__c,
//				SVMXC__Travel_Discount_Covered__c, SMAX_PS_ConsumableDiscountCovered__c,
//				SMAX_PS_ServicePartsDiscountCovered__c
//				FROM SVMXC__Service_Contract_Services__c WHERE Id = :entId];
			SVMXC__Service_Contract_Services__c ent = woDetails.SMAX_PS_ContractEntitlement__r;

			Set<Id> productIds = new Set<Id>();
			for (SVMXC__Service_Order_Line__c line : lines)
			{
				if (line.SVMXC__Product__c != null) {
					productIds.add(line.SVMXC__Product__c);
				}
			}

			if (productIds.isEmpty()) {
				return;
			}

			// ITSFDC-350 Adding Contract Discount Exception (CDE) Filter logic...
			String salesOrg = woDetails.SVMXC__Site__r.SMAX_PS_SalesOrg__c;
			String activityType = woDetails.SMAX_PS_SAP_ActivityType__c;
			Id ipProduct = woDetails.SVMXC__Component__c == null ? null : woDetails.SVMXC__Component__r.SVMXC__Product__c;

			Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name,
					SVMXC__Product_Type__c, SMAX_PS_Discount_Type__c,
					(SELECT Id, BD_Discount_Type__c, BD_Instrument_Product__c, BD_Sales_Org__c, BD_SAP_Activity_Type__c
						FROM Parts_Contract_Discount_Exceptions__r
						WHERE BD_SAP_Activity_Type__c = :activityType
						AND (BD_Sales_Org__c = NULL OR BD_Sales_Org__c = :salesOrg)
						AND (BD_Instrument_Product__c = NULL OR BD_Instrument_Product__c = :ipProduct)
						ORDER BY BD_Sales_Org__c NULLS LAST, BD_Instrument_Product__c NULLS LAST)
				FROM Product2 WHERE Id IN :productIds]);
			for (SVMXC__Service_Order_Line__c line : lines)
			{
				Product2 prod = productMap.get(line.SVMXC__Product__c);
				// SVMXINT-621 Use new Discount Type field if it is populated
				String discountType = (prod != null) ?
					( String.isBlank(prod.SMAX_PS_Discount_Type__c) ?
						prod.SVMXC__Product_Type__c : prod.SMAX_PS_Discount_Type__c )
					: null;

				// ITSFDC-350 Adding Contract Discount Exception (CDE)
				if (prod != null && prod.Parts_Contract_Discount_Exceptions__r != null && !prod.Parts_Contract_Discount_Exceptions__r.isEmpty())
				{
					// NOTE: The above ORDER BY ensures we get the most relevant record first
					BD_Contract_Discount_Exception__c cde = prod.Parts_Contract_Discount_Exceptions__r[0];
					discountType = cde.BD_Discount_Type__c;
				}

				if (discountType != null)
				{
					Decimal discount = null;
					if (discountType == 'Labor')
						discount = ent.SVMXC__Labor_Discount_Covered__c;
					else if (discountType == 'Travel')
						discount = ent.SVMXC__Travel_Discount_Covered__c;
					else if (discountType == 'Parts' || discountType == 'Other Parts')
						discount = ent.SVMXC__Parts_Discount_Covered__c;
					else if (discountType == 'Service Parts')
						discount = ent.SMAX_PS_ServicePartsDiscountCovered__c;
					else if (discountType == 'Consumable')
						discount = ent.SMAX_PS_ConsumableDiscountCovered__c;

					line.BD_Discount_Type__c = discountType;
					line.SMAX_PS_ContractPercentDiscount__c = discount;
				}
			}

		}
	}

	//global class JsKeyValue
	//{
	//    webservice String key;
	//    webservice String value;
	//    webservice String value1;
	//}

	//global class JsRecord
	//{
	//    webservice String targetRecordId;
	//    webservice JsKeyValue[] targetRecordAsKeyValue;
	//}

	//global class JsRecordDef
	//{
	//    webservice String objName;
	//    webservice String pageLayoutId;
	//    webservice JsRecord[] records;

	//    // On Detail Records
	//    webservice String aliasName;
	//    webservice String parentColumnName;
	//}

	//global class JsContext
	//{
	//    webservice JsRecordDef headerRecord;
	//    webservice JsRecordDef[] detailRecords;
	//    webservice String eventType;
	//    webservice String sfmProcessId;

	//    webservice JsKeyValue[] stringMap;
	//}

	//global class JsResult
	//{   
	//    webservice JsResponse response;

	//}

	//global class JsResponse
	//{
	//    webservice JsKeyValue[] stringMap;
	//}

	//webservice static JsResult priceWorkOrderJs(JsContext context)
	//{
	//    System.debug('Received get price request: ' + context);
	//    //JsResponse rsp = new JsResponse();
	//    //rsp.stringMap = '[]';

	//    JsResult result = new JsResult();
	//    result.response = new JsResponse();
	//    result.response.stringMap = context.stringMap;

	//    return result;
	//}


}
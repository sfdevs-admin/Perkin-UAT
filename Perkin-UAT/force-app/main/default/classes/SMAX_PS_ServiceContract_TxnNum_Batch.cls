/**
 * Created by frankvanloon on 2019-03-15.
 * SVMXCFG-1076 BIG CONTRACTS
 */
global class SMAX_PS_ServiceContract_TxnNum_Batch implements Database.Batchable<SObject>, Schedulable
{
	global final static String STEP_1_ITEMS = 'Items';
	global final static String STEP_2_PRODUCTS = 'Products';
	global final static String STEP_3_ENTITLEMENTS = 'Entitlements';
	global final static String STEP_4_DATES = 'EntitlementDates';
	global final static String STEP_5_PARENTS = 'Parents';

	global final String stepName;
	global final Datetime lastModTime;
	global final Id serviceContractId;

	// For scheduling only
	global SMAX_PS_ServiceContract_TxnNum_Batch() {}

	global SMAX_PS_ServiceContract_TxnNum_Batch(String step, Datetime lastModifiedTime)
	{
		this.stepName = step;
		this.lastModTime = lastModifiedTime;
		this.serviceContractId = null;
	}

	global SMAX_PS_ServiceContract_TxnNum_Batch(String step, Datetime lastModifiedTime, Id serviceContractId)
	{
		this.stepName = step;
		this.lastModTime = lastModifiedTime;
		this.serviceContractId = serviceContractId;
	}

	/** Schedulable methods **/

	global void execute(SchedulableContext ctx)
	{
		Datetime dt = (Test.isRunningTest()) ? Datetime.now() : Datetime.now().addHours(-1);
		SMAX_PS_ServiceContract_TxnNum_Batch btch = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_1_ITEMS, dt);
		Database.executeBatch(btch);
	}

	/** Database.Batchable methods **/

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		System.debug('this.serviceContractId: ' + this.serviceContractId);
		if (this.serviceContractId == null)
		{
			if (this.stepName == STEP_1_ITEMS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SVMX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c,
						SMAX_PS_IsDeleted__c, SVMXC__Cancelation_Notes__c,
						SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract__c
				WHERE SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime]);
			}
			else if (this.stepName == STEP_2_PRODUCTS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c,
						SMAX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SMAX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract_Products__c
				WHERE SMAX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SMAX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime]);
			}
			else if (this.stepName == STEP_3_ENTITLEMENTS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c,
						SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c,
						SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract_Services__c
				WHERE SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime]);
			}
			else if (this.stepName == STEP_4_DATES)
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c,
						SMAX_PS_LastTxnNum__c, SMAX_PS_WorkOrder__c, SMAX_PS_IsDeleted__c,
						SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SMAX_PS_EntitlementDate__c
				WHERE SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime]);
			}
			else
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_LastTxnNum__c, SMAX_PS_CompletedTxnNum__c,
						SVMX_PS_External_ID__c, SVMXC__Active__c
				FROM SVMXC__Service_Contract__c
				WHERE SVMX_PS_Parent_Contract__c = NULL AND SMAX_PS_InconsistentTxnNum__c = TRUE
				AND LastModifiedDate <= :lastModTime]);
			}
		} else
		{
			if (this.stepName == STEP_1_ITEMS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SVMX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c,
						SMAX_PS_IsDeleted__c, SVMXC__Cancelation_Notes__c,
						SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract__c
				WHERE SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime
				AND SVMX_PS_Parent_Contract__c = :this.serviceContractId]);
			}
			else if (this.stepName == STEP_2_PRODUCTS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_Parent_Contract__c, SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c,
						SMAX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SMAX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract_Products__c
				WHERE SMAX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SMAX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime
				AND SMAX_PS_Parent_Contract__c = :this.serviceContractId]);
			}
			else if (this.stepName == STEP_3_ENTITLEMENTS)
			{
				return Database.getQueryLocator([SELECT Id, Name, SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c,
						SMAX_PS_LastTxnNum__c, SMAX_PS_IsDeleted__c,
						SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SVMXC__Service_Contract_Services__c
				WHERE SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime
				AND SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__c = :this.serviceContractId]);
			}
			else if (this.stepName == STEP_4_DATES)
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c,
						SMAX_PS_LastTxnNum__c, SMAX_PS_WorkOrder__c, SMAX_PS_IsDeleted__c,
						SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_LastTxnNum__c,
						SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_CompletedTxnNum__c
				FROM SMAX_PS_EntitlementDate__c
				WHERE SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.SMAX_PS_InconsistentTxnNum__c = TRUE
				AND SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r.LastModifiedDate <= :lastModTime
				AND SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__c = :this.serviceContractId]);
			}
			else
			{
				return Database.getQueryLocator([SELECT Id, Name, SMAX_PS_LastTxnNum__c, SMAX_PS_CompletedTxnNum__c,
						SVMX_PS_External_ID__c, SVMXC__Active__c
				FROM SVMXC__Service_Contract__c
				WHERE SVMX_PS_Parent_Contract__c = NULL AND SMAX_PS_InconsistentTxnNum__c = TRUE
				AND LastModifiedDate <= :lastModTime
				AND Id = :this.serviceContractId]);
			}
		}
	}

	global void execute(Database.BatchableContext BC, List<SObject> records)
	{
		if (this.stepName == STEP_1_ITEMS)
		{
			execute_Items((List<SVMXC__Service_Contract__c>)records);
		}
		else if (this.stepName == STEP_2_PRODUCTS)
		{
			execute_Products((List<SVMXC__Service_Contract_Products__c>)records);
		}
		else if (this.stepName == STEP_3_ENTITLEMENTS)
		{
			execute_Entitlements((List<SVMXC__Service_Contract_Services__c>)records);
		}
		else if (this.stepName == STEP_4_DATES)
		{
			execute_EntitlementDates((List<SMAX_PS_EntitlementDate__c>)records);
		}
		else
		{
			execute_Parents((List<SVMXC__Service_Contract__c>)records);
		}
	}

	global void execute_Items(List<SVMXC__Service_Contract__c> itemList)
	{
		List<SVMXC__Service_Contract__c> scUpdateList = new List<SVMXC__Service_Contract__c>();
		System.debug('SVC-CONTRACT Updating Items: ' + itemList.size());

		for ( SVMXC__Service_Contract__c item : itemList )
		{
			SVMXC__Service_Contract__c parentSc = item.SVMX_PS_Parent_Contract__r;
			//if ( item.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c)
			if ( item.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_LastTxnNum__c)
			{
				item.SMAX_PS_IsDeleted__c = true;
				scUpdateList.add(item);
			}
			else if (item.SMAX_PS_IsDeleted__c == true && String.isBlank(item.SVMXC__Cancelation_Notes__c))
			{
				item.SMAX_PS_IsDeleted__c = false;
				scUpdateList.add(item);
			}
		}

		if (!scUpdateList.isEmpty())
		{
			update scUpdateList;
		}
	}

	global void execute_Products(List<SVMXC__Service_Contract_Products__c> cpList)
	{
		List<SVMXC__Service_Contract_Products__c> cpUpdateList = new List<SVMXC__Service_Contract_Products__c>();

		System.debug('SVC-CONTRACT Updating CPs: ' + cpList.size());

		for (SVMXC__Service_Contract_Products__c cp : cpList)
		{
			SVMXC__Service_Contract__c parentSc = cp.SMAX_PS_Parent_Contract__r;
			//if (cp.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c)
			if (cp.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_LastTxnNum__c)
			{
				cp.SMAX_PS_IsDeleted__c = true;
				cpUpdateList.add(cp);
			}
			else if (cp.SMAX_PS_IsDeleted__c == true)
			{
				cp.SMAX_PS_IsDeleted__c = false;
				cpUpdateList.add(cp);
			}
		}

		if (!cpUpdateList.isEmpty())
		{
			update cpUpdateList;
		}
	}

	global void execute_Entitlements(List<SVMXC__Service_Contract_Services__c> entList)
	{
		List<SVMXC__Service_Contract_Services__c> entUpdateList = new List<SVMXC__Service_Contract_Services__c>();

		System.debug('SVC-CONTRACT Updating Entitlements: ' + entList.size());

		for (SVMXC__Service_Contract_Services__c ent : entList)
		{
			SVMXC__Service_Contract__c parentSc = ent.SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r;
			//if (ent.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c)
			if (ent.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_LastTxnNum__c)
			{
				ent.SMAX_PS_IsDeleted__c = true;
				entUpdateList.add(ent);
			}
			else if (ent.SMAX_PS_IsDeleted__c == true)
			{
				ent.SMAX_PS_IsDeleted__c = false;
				entUpdateList.add(ent);
			}
		}

		if (!entUpdateList.isEmpty())
		{
			update entUpdateList;
		}
	}

	global void execute_EntitlementDates(List<SMAX_PS_EntitlementDate__c> eDatesList)
	{
		List<SMAX_PS_EntitlementDate__c> edatesDeleteList = new List<SMAX_PS_EntitlementDate__c>();
		List<SMAX_PS_EntitlementDate__c> edatesUpdateList = new List<SMAX_PS_EntitlementDate__c>();

		System.debug('SVC-CONTRACT Checking EntDates: ' + eDatesList.size());

		for (SMAX_PS_EntitlementDate__c eDate : eDatesList)
		{
			SVMXC__Service_Contract__c parentSc = eDate.SMAX_PS_ContractItem__r.SVMX_PS_Parent_Contract__r;
			//if (eDate.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_CompletedTxnNum__c)
			if (eDate.SMAX_PS_LastTxnNum__c != parentSc.SMAX_PS_LastTxnNum__c)
			{
				// SVMXCFG-455: Dont delete EntDate if WorkOrder lookup populated
				if (eDate.SMAX_PS_WorkOrder__c != null)
				{
					eDate.SMAX_PS_IsDeleted__c = true;
					edatesUpdateList.add(eDate);
				}
				else
				{
					edatesDeleteList.add(eDate);
				}
			}
			else if (eDate.SMAX_PS_IsDeleted__c == true)
			{
				eDate.SMAX_PS_IsDeleted__c = false;
				edatesUpdateList.add(eDate);
			}
		}

		if (!edatesUpdateList.isEmpty())
		{
			update edatesUpdateList;
		}
		if (!edatesDeleteList.isEmpty())
		{
			delete edatesDeleteList;
		}
	}

	global void execute_Parents(List<SVMXC__Service_Contract__c> parentList)
	{
		List<SVMXC__Service_Contract__c> scUpdateList = new List<SVMXC__Service_Contract__c>();
		//Map<Id, SVMXC__Service_Contract__c> parentScMap = new Map<Id, SVMXC__Service_Contract__c>();
		System.debug('SVC-CONTRACT Updating Parents: ' + parentList.size());

		for (SVMXC__Service_Contract__c parent : parentList)
		{
			parent.SMAX_PS_CompletedTxnNum__c = parent.SMAX_PS_LastTxnNum__c;

			scUpdateList.add(parent);
			//parentScMap.put(parent.Id, parent);
		}

		if (!scUpdateList.isEmpty())
		{
			update scUpdateList;
			// NOTE: This should cause the trigger to run, including the sending of the SC Events
		}
	}

	global void finish(Database.BatchableContext BC)
	{
		if (this.serviceContractId == null)
		{
			if (this.stepName == STEP_1_ITEMS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_2_PRODUCTS, this.lastModTime);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_2_PRODUCTS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_3_ENTITLEMENTS, this.lastModTime);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_3_ENTITLEMENTS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_4_DATES, this.lastModTime);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_4_DATES)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_5_PARENTS, this.lastModTime);
				Database.executeBatch(b, 1);  // Run this one parent contract at a time, just in case..
			}
		} else
		{
			if (this.stepName == STEP_1_ITEMS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_2_PRODUCTS, this.lastModTime, this.serviceContractId);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_2_PRODUCTS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_3_ENTITLEMENTS, this.lastModTime, this.serviceContractId);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_3_ENTITLEMENTS)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_4_DATES, this.lastModTime, this.serviceContractId);
				Database.executeBatch(b);
			}
			else if (this.stepName == STEP_4_DATES)
			{
				SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch(STEP_5_PARENTS, this.lastModTime, this.serviceContractId);
				Database.executeBatch(b, 1);  // Run this one parent contract at a time, just in case..
			}
		}
	}
}
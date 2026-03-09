global class SMAX_PS_AutoEntitlementWoLoadFix implements Database.Batchable<sObject> {
    
    private List<String> workOrderNums;

    global SMAX_PS_AutoEntitlementWoLoadFix() {
    }

    global SMAX_PS_AutoEntitlementWoLoadFix(String workOrderNum) {
        this.workOrderNums = workOrderNum.split(',');
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        if (this.workOrderNums != null && !this.workOrderNums.isEmpty())
        {
            return Database.getQueryLocator([SELECT Id, Name, SVMX_PS_External_ID__c,
                SMAX_PS_SAP_ActivityType__c, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_ContractEntitlement__c,
                SMAX_PS_CoveredProduct__c, SVMXC__Component__c, SVMXC__Scheduled_Date__c,
                SVMXC__Is_Entitlement_Performed__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Entitlement_Type__c, 
                SVMXC__Entitlement_Notes__c, SVMXC__Perform_Auto_Entitlement__c, 
                SMAX_PS_SLA_Terms_Notes__c, SMAX_PS_IsEntitledWarranty__c,SMAX_PS_Customer_Required_Start_Date__c 
                FROM SVMXC__Service_Order__c WHERE Name IN :workOrderNums]);
        }

        return Database.getQueryLocator([SELECT Id, Name, SVMX_PS_External_ID__c,
            SMAX_PS_SAP_ActivityType__c, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SMAX_PS_ContractEntitlement__c,
            SMAX_PS_CoveredProduct__c, SVMXC__Component__c, SVMXC__Scheduled_Date__c,
            SVMXC__Is_Entitlement_Performed__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Entitlement_Type__c, 
            SVMXC__Entitlement_Notes__c, SVMXC__Perform_Auto_Entitlement__c, 
            SMAX_PS_SLA_Terms_Notes__c, SMAX_PS_IsEntitledWarranty__c,SMAX_PS_Customer_Required_Start_Date__c 
            FROM SVMXC__Service_Order__c WHERE SMAX_PS_ContractItem__c != null
                AND SMAX_PS_ContractEntitlement__c = null AND SVMXC__Is_Entitlement_Performed__c = FALSE]);
    }

    global void execute(Database.BatchableContext BC, List<SVMXC__Service_Order__c> scope) 
    {
        SMAX_PS_AutoEntitlement.completeEntitlement(scope, null);
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}
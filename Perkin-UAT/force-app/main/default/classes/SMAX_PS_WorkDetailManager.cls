/**
 *  Apex Class for Work Detail [SVMXC__Service_Order_Line__c] Business Logic.
 *  2017-09-21      Veerendra Moodbidri       Initial creation, for Work Detail Outbound Integration.
 *  1. Create Work Order Event when the Line is Submitted or Cancelled and update Integration to 'Pending.
 *  2. Before Update Work Detail Line to 'Confirmed' and Integration Status to 'Completed'.
 *  3. After Update Work Detail Line to 'Canceled' and Integration Status to 'Completed'.
 *  ITSVMX-705 - Created addsummaryAfter and updated addWorkSummary method to include HSN Code in the concatenate
 *  field for India Region
 *
 *  <--- Updates --->
 *  06/20/2022  Tony    ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
 *  08/04/2023  Tony    ITSVMX-1227 Update Work Order Plant and Work Center from either Technician or Additional Work Center
 */

public without sharing class SMAX_PS_WorkDetailManager {

    private SMAX_PS_WorkDetailManager() {
    }

    public static void copyRelatedData(List<SVMXC__Service_Order_Line__c> detailList)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Copy Related Data', 'Copy Work Order fields when Work Details are created.'))
            return;

        Set<Id> woIds = new Set<Id>();
        for (SVMXC__Service_Order_Line__c wd : detailList)
        {
            woIds.add(wd.SVMXC__Service_Order__c);
        }

        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, CurrencyIsoCode 
            FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
        for (SVMXC__Service_Order_Line__c wd : detailList)
        {
            SVMXC__Service_Order__c wo = woMap.get(wd.SVMXC__Service_Order__c);
            if (wo != null)
            {
                wd.CurrencyIsoCode = wo.CurrencyIsoCode;
            }
        }
    }

    public static void updateFieldValues(List<SVMXC__Service_Order_Line__c> detailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Update Field Values', 'Update Work Detail fields when Work Details are updated.'))
            return;

        for (SVMXC__Service_Order_Line__c wd : detailList)
        {
            // [SVMXCFG-436] Copy the Contract Discount to the OOTB Discount field
            wd.SVMXC__Discount__c = wd.SMAX_PS_ContractPercentDiscount__c;
            // [SVMXCFG-519] Round Labor and Travel to 1 decimal place
            if ((wd.SVMXC__Line_Type__c == 'Labor' || wd.SVMXC__Line_Type__c == 'Travel') && wd.SVMXC__Actual_Quantity2__c != null)
            {
                wd.SVMXC__Actual_Quantity2__c = wd.SVMXC__Actual_Quantity2__c.setScale(1, System.RoundingMode.DOWN);
            }

            // [ITSFDC-89] If Adjustment value, but no "Type", default to "Uplift"
            if (wd.SMAX_PS_ServiceAmountAdjustment__c != null && wd.SMAX_PS_ServiceAmountAdjustmentType__c == null)
            {
                wd.SMAX_PS_ServiceAmountAdjustmentType__c = 'Uplift';
            }
            if (wd.SMAX_PS_ServicePercentAdjustment__c != null && wd.SMAX_PS_ServicePercentAdjustmentType__c == null)
            {
                wd.SMAX_PS_ServicePercentAdjustmentType__c = 'Uplift';
            }
        }
    }

    public static void toggleIntegrationStatus(List<SVMXC__Service_Order_Line__c> wDetailNewList, Map<Id, SVMXC__Service_Order_Line__c> wDetailOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Toggle Int Status', 'Toggle Integration Status when Work Details are Submitted or Cancelled.'))
            return;

        // Update the Integration status in Work Detail
        if (!wDetailNewList.isEmpty()) {
            for (SVMXC__Service_Order_Line__c wd : wDetailNewList) {
                SVMXC__Service_Order_Line__c old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);
                if ( old != null && old.SVMXC__Line_Status__c != wd.SVMXC__Line_Status__c)
                {
                    if (wd.SVMXC__Line_Status__c == 'Submitted') {
                        wd.SMAX_PS_IntegrationStatus__c='Pending';
                    }
                    else if (wd.SVMXC__Line_Status__c == 'Canceled') {
                        // SVMXINT-512: Work Detail: Only Cancel if Confirmed
                        if (String.isNotBlank(wd.SMAX_PS_SAP_Confirmation__c)) {
                            wd.SMAX_PS_IntegrationStatus__c='Pending';
                        } else {
                            wd.SMAX_PS_IntegrationStatus__c = null;
                        }
                    }
                } 
            }
        }
    }

    /**
     *  DEPRECATED as part of One-Click Complete
     */
    //public static void createWorkOrderEvent(List<SVMXC__Service_Order_Line__c> wDetailNewList, Map<Id, SVMXC__Service_Order_Line__c> wDetailOldMap)
    //{
    //  if (!SMAX_PS_Utility.isActive('Work Detail Events', 'Create Work Order Platform Events when Work Details are Submitted or Cancelled.'))
    //      return;

    //  List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
    //  Map<Id, String> eventMap = new Map<Id, String>();
    //  Set<Id> submittedWoIds = new Set<Id>();
    //  Set<Id> cancelledWoIds = new Set<Id>();

    //  // Collect qualified Work Order Ids for which Events have to be created
    //  if (!wDetailNewList.isEmpty()) {
    //      for (SVMXC__Service_Order_Line__c wd : wDetailNewList) {
    //          SVMXC__Service_Order_Line__c old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);
    //          // SVMXINT-512: Adding the Pending Check.. 
    //          if ( old != null && old.SVMXC__Line_Status__c != wd.SVMXC__Line_Status__c && wd.SMAX_PS_IntegrationStatus__c == 'Pending')
    //          {
    //              if (wd.SVMXC__Line_Status__c == 'Submitted') {
    //                  submittedWoIds.add(wd.SVMXC__Service_Order__c);
    //              }
    //              else if (wd.SVMXC__Line_Status__c == 'Canceled') {
    //                  cancelledWoIds.add(wd.SVMXC__Service_Order__c);
    //              }
    //          }
    //      }
    //  }

    //  // Publish the Event(s)
    //  if (!submittedWoIds.isEmpty()) {
    //      for (Id wo : submittedWoIds) {
    //          SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
    //          iEvent.SMAX_PS_Action__c = 'SUBMIT';
    //          iEvent.SMAX_PS_WorkOrderId__c = wo;
    //          events.add(iEvent);
    //      }
    //  }
    //  if (!cancelledWoIds.isEmpty()) {
    //      for (Id wo : cancelledWoIds) {
    //          SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
    //          iEvent.SMAX_PS_Action__c = 'CANCEL';
    //          iEvent.SMAX_PS_WorkOrderId__c = wo;
    //          events.add(iEvent);
    //      }
    //  }

        //SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
    //}

    /**
     *  Replaces createWorkOrderEvent(...), removing the submit logic, and adding txnId
     *  Should be called from the before update (but after toggleIntegrationStatus(...))
     */
    public static void cancelLines(List<SVMXC__Service_Order_Line__c> wDetailNewList, Map<Id, SVMXC__Service_Order_Line__c> wDetailOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Cancel Lines', 'Create Work Order Platform Events when Work Details are Cancelled.'))
            return;

        Set<Id> cancelledWoIds = new Set<Id>();
        String txnId = String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));

        // Collect qualified Work Order Ids for which Events have to be created
        for (SVMXC__Service_Order_Line__c wd : wDetailNewList) {
            SVMXC__Service_Order_Line__c old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);
            // SVMXINT-512: Adding the Pending Check.. 
            if ( old != null && old.SVMXC__Line_Status__c != wd.SVMXC__Line_Status__c && wd.SMAX_PS_IntegrationStatus__c == 'Pending')
            {
                if (wd.SVMXC__Line_Status__c == 'Canceled') {
                    wd.SMAX_PS_SubmitTxnId__c = txnId;
                    cancelledWoIds.add(wd.SVMXC__Service_Order__c);
                }
            }
        }

        if (cancelledWoIds.isEmpty())
            return;

        // Publish the Event(s)
        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        for (Id woId : cancelledWoIds) {
            SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
            iEvent.SMAX_PS_Action__c = 'CANCEL';
            iEvent.SMAX_PS_SubmitTxnId__c = txnId;
            iEvent.SMAX_PS_WorkOrderId__c = woId;
            events.add(iEvent);
        }

        SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
    }

    private static Set<String> PRE_CONFIRMED = new Set<String> { 'Open', 'Submitted', 'Priced' };

    public static void updateDetailLineAndIntegrationStatus(List<SVMXC__Service_Order_Line__c> wDetailNewList, Map<Id, SVMXC__Service_Order_Line__c> wDetailOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Detail And Integration Status', 'Update the Line Status and the Integration Status in Work Detail when the SAP Confirmation and the Cancellation Number are changed.'))
            return;

        // Update Work Detail Line and Integration Status
        if (!wDetailNewList.isEmpty()) {
            for (SVMXC__Service_Order_Line__c wd : wDetailNewList) {
                SVMXC__Service_Order_Line__c old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.id);

                // SVMXCFG-494: PREVENT lost SAP Confirmation numbers
                if ( old != null && String.isBlank(wd.SMAX_PS_SAP_Confirmation__c) && String.isNotBlank(old.SMAX_PS_SAP_Confirmation__c))
                {
                    wd.SMAX_PS_SAP_Confirmation__c = old.SMAX_PS_SAP_Confirmation__c;
                    wd.SVMXC__Line_Status__c='Confirmed';
                    wd.SMAX_PS_IntegrationStatus__c='Completed';
                }
                // SVMXCFG-530: Work Detail: Prevent Status Rollback
                if ( old != null && old.SVMXC__Line_Status__c == 'Confirmed' && PRE_CONFIRMED.contains(wd.SVMXC__Line_Status__c))
                {
                    wd.SVMXC__Line_Status__c='Confirmed';
                }
                if ( old != null && wd.SMAX_PS_SAP_Confirmation__c != null && wd.SMAX_PS_SAP_Confirmation__c != old.SMAX_PS_SAP_Confirmation__c ) 
                {
                    wd.SVMXC__Line_Status__c='Confirmed';
                    wd.SMAX_PS_IntegrationStatus__c='Completed';
                }
                if ( old != null && wd.SVMXC__Line_Status__c == 'Confirmed' && wd.SVMXC__Line_Status__c != old.SVMXC__Line_Status__c ) 
                {
                    wd.SMAX_PS_IntegrationStatus__c='Completed';
                }
                if ( old != null && wd.SMAX_PS_CancellationNumber__c != null && wd.SMAX_PS_CancellationNumber__c != old.SMAX_PS_CancellationNumber__c ) 
                {
                    wd.SVMXC__Line_Status__c='Canceled';
                    wd.SMAX_PS_IntegrationStatus__c='Completed';
                }
            }
        }
    }

    public static void updateUnitOfMeasureCodes(List<SVMXC__Service_Order_Line__c> detailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Unit Of Measure Codes', 'Update the Unit of Measurement codes.'))
            return;

        // Based on this Checkbox.. SMAX_PS_Use_Product_Sales_UOM__c
        // Update this field:  SMAX_PS_UnitOfMeasure__c
        // And this field:  SMAX_PS_UOM_Code__c
        List<SVMXC__Service_Order_Line__c> detailsToUpdate = new List<SVMXC__Service_Order_Line__c>();
        Set<Id> woIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (SVMXC__Service_Order_Line__c detail : detailList)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
            if (detail.SMAX_PS_UnitOfMeasure__c == null || detail.SMAX_PS_UOM_Code__c == null
                || (old != null && (detail.SMAX_PS_Use_Product_Sales_UOM__c != old.SMAX_PS_Use_Product_Sales_UOM__c
                    || detail.SVMXC__Product__c != old.SVMXC__Product__c)))
            {
                detailsToUpdate.add(detail);
                woIds.add(detail.SVMXC__Service_Order__c);
                productIds.add(detail.SVMXC__Product__c);
            }
        }

        if (detailsToUpdate.isEmpty())
            return;

        // ProductSales below is based on SalesOrg from Location... SMAX_PS_SalesOrg__c
        Set<String> salesOrgs = new Set<String>();
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
            [SELECT Id, SVMXC__Site__c, SVMXC__Site__r.SMAX_PS_SalesOrg__c FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
        for (SVMXC__Service_Order__c wo : woMap.values())
        {
            if (wo.SVMXC__Site__c != null && wo.SVMXC__Site__r.SMAX_PS_SalesOrg__c != null)
            {   
                salesOrgs.add(wo.SVMXC__Site__r.SMAX_PS_SalesOrg__c);
            }
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, ProductCode, QuantityUnitOfMeasure, PKI_Qty_UOM_Code__c,
                (SELECT Id, SMAX_PS_ExternalID__c, SMAX_PS_SalesOrg__c, SMAX_PS_SalesUnit__c, SMAX_PS_Sales_Unit_Code__c 
                    FROM Product_Sales__r WHERE SMAX_PS_SalesOrg__c IN :salesOrgs)
                FROM Product2 WHERE Id IN :productIds]);

        // ... from either Product: (if false)   QuantityUnitOfMeasure , PKI_Qty_UOM_Code__c
        // OR from the SalesProduct [SMAX_PS_ProductSales__c]: (if true)  SMAX_PS_SalesUnit__c , SMAX_PS_Sales_Unit_Code__c
        for (SVMXC__Service_Order_Line__c detail : detailsToUpdate)
        {
            Product2 prod = productMap.get(detail.SVMXC__Product__c);
            SVMXC__Service_Order__c wo = woMap.get(detail.SVMXC__Service_Order__c);
            String salesOrg = wo.SVMXC__Site__r.SMAX_PS_SalesOrg__c;
            SMAX_PS_WorkDetailManager.updateUnitOfMeasureCodes(detail, salesOrg, prod);
        }
    }

    public static void updateUnitOfMeasureCodes(SVMXC__Service_Order_Line__c detail, String salesOrg, Product2 prod)
    {
        if (!SMAX_PS_Utility.isActive('Update Unit Of Measure Codes', 'Update Work detail Qty UOM from the Product.'))
            return;

        if (prod == null)
            return;
            
        if (detail.SMAX_PS_Use_Product_Sales_UOM__c == TRUE)
        {
            SMAX_PS_ProductSales__c productSales = null;
            for (SMAX_PS_ProductSales__c sales : prod.Product_Sales__r)
            {
                if (sales.SMAX_PS_SalesOrg__c == salesOrg)
                {
                    productSales = sales;
                    break;
                }
            }

            if (productSales == null)
            {
                String errorMsg = 'ProductSales for Product: ' + prod.ProductCode + ' and SalesOrg: ' 
                    + salesOrg + ' not found.  Cannot use "Sales UOM".';
                System.debug(errorMsg);
                //detail.addError(errorMsg);
                detail.SMAX_PS_Use_Product_Sales_UOM__c = FALSE;
            }
            else if (productSales.SMAX_PS_SalesUnit__c == null || productSales.SMAX_PS_Sales_Unit_Code__c == null)
            {
                String errorMsg = 'ProductSales: ' + productSales.SMAX_PS_ExternalID__c 
                    + ' does not have "Sales UOM" values.  Cannot use "Sales UOM".';
                System.debug(errorMsg);
                //detail.addError(errorMsg);
                detail.SMAX_PS_Use_Product_Sales_UOM__c = FALSE;
            }
            else
            {
                detail.SMAX_PS_UnitOfMeasure__c = productSales.SMAX_PS_SalesUnit__c;
                detail.SMAX_PS_UOM_Code__c = productSales.SMAX_PS_Sales_Unit_Code__c;
            }
        }

        if (detail.SMAX_PS_Use_Product_Sales_UOM__c == FALSE)
        {
            detail.SMAX_PS_UnitOfMeasure__c = prod.QuantityUnitOfMeasure;
            detail.SMAX_PS_UOM_Code__c = prod.PKI_Qty_UOM_Code__c;
        }
    }

    /**
     * Check if the newly created or updated WO Detail is a Fault code.  If so...
     * 1) fill in the field: SMAX_PS_Fault_Code_Complaint_Required__c based on if any of the related Fault Codes have Complaint Required values of 1.
     * 2) fill in the corresponding Picklists with their Description/Code values (temporary)
    */
    public static void updateFaultCodes(List<SVMXC__Service_Order_Line__c> detailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Update Fault Codes', 'Update the Fault Code Complaint Required field in Work Detail from the Fault Codes object.'))
            return;

        List<SVMXC__Service_Order_Line__c> faultCodeLines = new List<SVMXC__Service_Order_Line__c>();
        Set<Id> faultCodeIds = new Set<Id>();
        for (SVMXC__Service_Order_Line__c detail : detailList)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
            if (detail.SVMXC__Line_Type__c != 'Fault Code')
                continue;

            faultCodeLines.add(detail);
            if (detail.SMAX_PS_Fault_Code__c != null)
            {
                faultCodeIds.add(detail.SMAX_PS_Fault_Code__c);
            }
            if (detail.SMAX_PS_ActionFaultCode__c != null)// && (old == null || detail.SMAX_PS_ActionFaultCode__c != old.SMAX_PS_ActionFaultCode__c))
            {
                faultCodeIds.add(detail.SMAX_PS_ActionFaultCode__c);
            }
            if (detail.SMAX_PS_InstallationFaultCode__c != null)// && (old == null || detail.SMAX_PS_InstallationFaultCode__c != old.SMAX_PS_InstallationFaultCode__c))
            {
                faultCodeIds.add(detail.SMAX_PS_InstallationFaultCode__c);
            }
            if (detail.SMAX_PS_CompletionFaultCode__c != null)// && (old == null || detail.SMAX_PS_CompletionFaultCode__c != old.SMAX_PS_CompletionFaultCode__c))
            {
                faultCodeIds.add(detail.SMAX_PS_CompletionFaultCode__c);
            }
        }

        if (faultCodeLines.isEmpty())
            return;

        Map<Id, SMAX_PS_Fault_Code__c> faultCodeMap = new Map<Id, SMAX_PS_Fault_Code__c>(
            [SELECT Id, Name, SMAX_PS_Code_Description__c, SMAX_PS_Code__c, SMAX_PS_Complaint_Required__c 
                FROM SMAX_PS_Fault_Code__c WHERE Id IN :faultCodeIds]);
        for (SVMXC__Service_Order_Line__c detail : faultCodeLines)
        {
            Decimal complaintRequired = 0;
            if (detail.SMAX_PS_Fault_Code__c != null && faultCodeMap.containsKey(detail.SMAX_PS_Fault_Code__c))
            {
                SMAX_PS_Fault_Code__c fc = faultCodeMap.get(detail.SMAX_PS_Fault_Code__c);
                complaintRequired += (fc.SMAX_PS_Complaint_Required__c == null) ? 0 : fc.SMAX_PS_Complaint_Required__c;
            }
            if (detail.SMAX_PS_ActionFaultCode__c != null && faultCodeMap.containsKey(detail.SMAX_PS_ActionFaultCode__c))
            {
                SMAX_PS_Fault_Code__c fc = faultCodeMap.get(detail.SMAX_PS_ActionFaultCode__c);
                detail.SMAX_PS_Fault_Code_Action__c = fc.SMAX_PS_Code_Description__c + '~' + fc.SMAX_PS_Code__c;
                complaintRequired += (fc.SMAX_PS_Complaint_Required__c == null) ? 0 : fc.SMAX_PS_Complaint_Required__c;
            }
            if (detail.SMAX_PS_InstallationFaultCode__c != null && faultCodeMap.containsKey(detail.SMAX_PS_InstallationFaultCode__c))
            {
                SMAX_PS_Fault_Code__c fc = faultCodeMap.get(detail.SMAX_PS_InstallationFaultCode__c);
                detail.SMAX_PS_Installation_Code__c = fc.SMAX_PS_Code__c + ' ~ ' + fc.SMAX_PS_Code_Description__c;
                complaintRequired += (fc.SMAX_PS_Complaint_Required__c == null) ? 0 : fc.SMAX_PS_Complaint_Required__c;
            }
            if (detail.SMAX_PS_CompletionFaultCode__c != null && faultCodeMap.containsKey(detail.SMAX_PS_CompletionFaultCode__c))
            {
                SMAX_PS_Fault_Code__c fc = faultCodeMap.get(detail.SMAX_PS_CompletionFaultCode__c);
                detail.SMAX_PS_Completion_Code__c = fc.SMAX_PS_Code__c + ' ~ ' + fc.SMAX_PS_Code_Description__c;
                complaintRequired += (fc.SMAX_PS_Complaint_Required__c == null) ? 0 : fc.SMAX_PS_Complaint_Required__c;
            }
            detail.SMAX_PS_Fault_Code_Complaint_Required__c = complaintRequired;
        }
    }

    public static void updateTechOnDebriefLine(List<SVMXC__Service_Order_Line__c> newList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        // call to service register
        if (!SMAX_PS_Utility.isActive('updateTechOnDebriefLine','Places the ID of Technician working on a detail into the Technician field')) { return; }
        
        List<SVMXC__Service_Group_Members__c> debriefTechs = 
            [SELECT Id, Name FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c = :userinfo.getUserId()];  
        
        if (debriefTechs.size() > 0 )
        {
            // ITSFDC-1047 Run also for "Remote" Work Details
            Id remoteRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'SMAX_PS_Remote_Support').Id;
            Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
            for (SVMXC__Service_Order_Line__c wd : newList) 
            {
                // ITSFDC-1047 Include "Remote" Work Details
                //if (wd.SVMXC__Group_Member__c == null && wd.RecordTypeId == usageRecTypeId && debriefTechs[0] != null)
                if (wd.SVMXC__Group_Member__c == null && (wd.RecordTypeId == usageRecTypeId || wd.RecordTypeId == remoteRecTypeId) && debriefTechs[0] != null)
                {
                    wd.SVMXC__Group_Member__c = debriefTechs[0].Id;
                }
            }
        }
    }

    /**
     *  SVMXINT-502: Create Int Errors to detect duplicate processing
     *  Should be called from WorkDetail After Update trigger
     */
    public static void logDuplicateErrors(List<SVMXC__Service_Order_Line__c> wdList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Dulicate Errors', 'Create Integration Errors when SAP Confirmation Numbers are changed.'))
            return;

        List<SMAX_PS_IntegrationError__c> errorList = new List<SMAX_PS_IntegrationError__c>();
        for (SVMXC__Service_Order_Line__c detail : wdList)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
            if (old == null)
                continue;

            if (old.SMAX_PS_SAP_Confirmation__c != null && detail.SMAX_PS_SAP_Confirmation__c != old.SMAX_PS_SAP_Confirmation__c)
            {
                SMAX_PS_IntegrationError__c ie = new SMAX_PS_IntegrationError__c();
                ie.SMAX_PS_RelatedElementType__c = 'WorkDetailId';
                ie.SMAX_PS_RelatedElementIdentifier__c = detail.Id;
                ie.SMAX_PS_ErrorMessage__c = 'DUPLICATE PROCESSING: Work Detail posted as multiple SAP Confirmation Numbers: '
                    + old.SMAX_PS_SAP_Confirmation__c + ', ' + detail.SMAX_PS_SAP_Confirmation__c;
                errorList.add(ie);
            }
            if (old.SMAX_PS_CancellationNumber__c != null && detail.SMAX_PS_CancellationNumber__c != old.SMAX_PS_CancellationNumber__c)
            {
                SMAX_PS_IntegrationError__c ie = new SMAX_PS_IntegrationError__c();
                ie.SMAX_PS_RelatedElementType__c = 'WorkDetailId';
                ie.SMAX_PS_RelatedElementIdentifier__c = detail.Id;
                ie.SMAX_PS_ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Cancellation Numbers: '
                    + old.SMAX_PS_CancellationNumber__c + ', ' + detail.SMAX_PS_CancellationNumber__c;
                errorList.add(ie);
            }
        }

        if (!errorList.isEmpty())
            insert errorList;
    }
  
        //SVMXCFG-690 copy first 40 chars of Work Description to Work Summary
    //ITSVMX-705 Updated the code to copy the HSN Code for India Region
  public static void addWorkSummary(List<SVMXC__Service_Order_Line__c> wdList)
  {
  Map<String,SMAX_PS_HSN_Code_Setting__c> hsncodeIndia = SMAX_PS_HSN_Code_Setting__c.getAll();

    for(SVMXC__Service_Order_Line__c wd:wdList)
    {  
      if (wd.SVMXC__Work_Description__c != null)
      {
        String wdSum = (wd.SVMXC__Work_Description__c.length() > 40) ? 
          wd.SVMXC__Work_Description__c.substring(0,40) : wd.SVMXC__Work_Description__c;
        wd.SMAX_PS_WorkSummary__c = wdSum;
      }
   if (hsncodeIndia.keyset().contains(wd.CurrencyIsoCode) && wd.SMAX_PS_HSN_Code__c != null)
        {
            if (wd.SVMXC__Work_Description__c != null)
            {
        // SVMXCFG-1054 - Populate the "Concat Part Work Description"
    wd.SMAX_PS_Concat_Part_Work_Description__c = wd.SMAX_PS_Material_Part_Description__c + '<br/>' + wd.SVMXC__Work_Description__c + '<br/>' + 'HSN Code : ' + wd.SMAX_PS_HSN_Code__c;
            }
            else if (wd.SVMXC__Work_Description__c == null)
            {
    wd.SMAX_PS_Concat_Part_Work_Description__c = wd.SMAX_PS_Material_Part_Description__c + '<br/>' + 'HSN Code : ' + wd.SMAX_PS_HSN_Code__c;
            }
        }
    else if (wd.SVMXC__Work_Description__c != null)
        {
    wd.SMAX_PS_Concat_Part_Work_Description__c = wd.SMAX_PS_Material_Part_Description__c + '<br/>' + wd.SVMXC__Work_Description__c;
        }
    }
  }
  
 //ITSVMX-705 - This should be called After Insert
 //Created this method to copy the HSN code only for India Region
 public static void addsummaryAfter(List<SVMXC__Service_Order_Line__c> workDetailLines, Map<Id, SVMXC__Service_Order_Line__c> oldMap) {
        Map<String,SMAX_PS_HSN_Code_Setting__c> hsncodeIndia = SMAX_PS_HSN_Code_Setting__c.getAll();
        Set<Id> woIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> wdToProcess = new List<SVMXC__Service_Order_Line__c>();
         for (SVMXC__Service_Order_Line__c wd : workDetailLines)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(wd.Id);
                woIds.add(wd.SVMXC__Service_Order__c);
                wdToProcess.add(wd);
                System.debug('wdToProcess: ' + wdToProcess);
                System.debug('woIds: ' + woIds);
        }
             if (wdToProcess.isEmpty()) return;
        List<SVMXC__Service_Order_Line__c> linesToCreate = new List<SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c line : wdToProcess)
        {
          //SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(line.Id);
          //wdlines.add(new SVMXC__Service_Order_Line__c(Id = line.Id) );
            SVMXC__Service_Order_Line__c wdlines = new SVMXC__Service_Order_Line__c(Id = line.Id);
             if (line.SVMXC__Work_Description__c != null)
              {
                String wdSum = (line.SVMXC__Work_Description__c.length() > 40) ? 
                  line.SVMXC__Work_Description__c.substring(0,40) : line.SVMXC__Work_Description__c;
                wdlines.SMAX_PS_WorkSummary__c = wdSum;
              }
            if (hsncodeIndia.keyset().contains(line.CurrencyIsoCode) && line.SMAX_PS_HSN_Code__c != null)
                {
                    if (line.SVMXC__Work_Description__c != null)
                    {
                // SVMXCFG-1054 - Populate the "Concat Part Work Description"
            wdlines.SMAX_PS_Concat_Part_Work_Description__c = line.SMAX_PS_Material_Part_Description__c + '<br/>' + line.SVMXC__Work_Description__c + '<br/>' + 'HSN Code : ' + line.SMAX_PS_HSN_Code__c;
                    }
                    else if (line.SVMXC__Work_Description__c == null)
                    {
            wdlines.SMAX_PS_Concat_Part_Work_Description__c = line.SMAX_PS_Material_Part_Description__c + '<br/>' + 'HSN Code : ' + line.SMAX_PS_HSN_Code__c ;
                    }
                }
            else if (line.SVMXC__Work_Description__c != null)
                {
            wdlines.SMAX_PS_Concat_Part_Work_Description__c = line.SMAX_PS_Material_Part_Description__c + '<br/>' + line.SVMXC__Work_Description__c;
                }
            linesToCreate.add(wdlines);
            System.debug('linesToCreate: ' + linesToCreate);
        }
        if(linesToCreate.size() > 0)
        update linesToCreate;   
 }


    // ITSFDC-509 Lookup and copy data from ProductPlant for Parts lines
    // Should be called from the BEFORE-INSERT/UPDATE Triggers
    public static void lookupProductPlant(List<SVMXC__Service_Order_Line__c> wdList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Product Plant', 'Lookup the Product Plant for Parts lines.'))
            return;

        Set<Id> woIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> wdToUpdate = new List<SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c wd : wdList)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(wd.Id);
            if (wd.SVMXC__Line_Type__c == 'Parts' && wd.SVMXC__Product__c != null
                && (old == null || old.SVMXC__Product__c != wd.SVMXC__Product__c))
            {
                woIds.add(wd.SVMXC__Service_Order__c);
                prodIds.add(wd.SVMXC__Product__c);
                wdToUpdate.add(wd);
            }
        }

        if (wdToUpdate.isEmpty())
        {
            return;
        }

        Set<String> plants = new Set<String>();
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name,
                SVMXC__Site__c, SVMXC__Site__r.SMAX_PS_MaintenancePlant__c, BD_Any_Parts_Eligible_for_Return__c
            FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
        for (SVMXC__Service_Order__c wo : woMap.values())
        {
            if (wo.SVMXC__Site__c != null && wo.SVMXC__Site__r.SMAX_PS_MaintenancePlant__c != null)
            {
                plants.add(wo.SVMXC__Site__r.SMAX_PS_MaintenancePlant__c);
            }
        }

        if (plants.isEmpty())
        {
            return;
        }

        List<SMAX_PS_ProductPlant__c> allProductPlants = [SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_Plant__c,
                BD_Return_Part__c, BD_Return_Part_Number__c, BD_Credit_Relevant_Part__c
            FROM SMAX_PS_ProductPlant__c WHERE SMAX_PS_Product__c IN :prodIds AND SMAX_PS_Plant__c IN :plants];
        Map<String, SMAX_PS_ProductPlant__c> ppMap = new Map<String, SMAX_PS_ProductPlant__c>();
        for (SMAX_PS_ProductPlant__c pp : allProductPlants)
        {
            String key = pp.SMAX_PS_Product__c + '-' + pp.SMAX_PS_Plant__c;
            ppMap.put(key, pp);
        }

        Map<Id, SVMXC__Service_Order__c> woUpdateMap = new Map<Id, SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order_Line__c wd: wdToUpdate)
        {
            SVMXC__Service_Order__c wo = woMap.get(wd.SVMXC__Service_Order__c);
            String plant = (wo != null && wo.SVMXC__Site__c != null) ? wo.SVMXC__Site__r.SMAX_PS_MaintenancePlant__c : null;
            String key = wd.SVMXC__Product__c + '-' + plant;
            SMAX_PS_ProductPlant__c pp = ppMap.get(key);
            if (pp != null)
            {
                wd.BD_Product_Plant__c = pp.Id;
                wd.BD_Eligible_for_Return__c = (pp.BD_Return_Part__c != null || pp.BD_Return_Part_Number__c != null);
                wd.BD_Return_Part_Number__c = pp.BD_Return_Part_Number__c;
                wd.SVMX_PS_VS_Return_Part__c = pp.BD_Return_Part__c;

                // Update the WO also...
                Boolean newValue = wo.BD_Any_Parts_Eligible_for_Return__c || wd.BD_Eligible_for_Return__c;
                if (newValue != wo.BD_Any_Parts_Eligible_for_Return__c)
                {
                    wo.BD_Any_Parts_Eligible_for_Return__c = newValue;
                    woUpdateMap.put(wo.Id, wo);
                }
            }
        }

        if (!woUpdateMap.isEmpty())
        {
            // NOTE: might need to move this to a future call IF problematic
            update woUpdateMap.values();
        }
    }

    // ITSFDC-1047 Increment/Decrement the Remaining Hours on the Entitlement if Labor + Entitlement Type "PHN"
    // Should be called from the AFTER triggers
    public static void consumeRemoteHours(List<SVMXC__Service_Order_Line__c> lineList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Detail Consume Remote Hours', 'Consume Remote Support Hours for Remote Labor lines.')) {
            return;
        }

        Set<Id> woIds = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> laborLines = new List<SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c line : lineList)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(line.Id);
            if (line.SVMXC__Line_Type__c == 'Labor'
                    && (old == null || old.SVMXC__Actual_Quantity2__c != line.SVMXC__Actual_Quantity2__c || Trigger.isDelete
                    || (old.SVMXC__Line_Status__c != line.SVMXC__Line_Status__c && line.SVMXC__Line_Status__c == 'Canceled')))
            {
                laborLines.add(line);
                woIds.add(line.SVMXC__Service_Order__c);
            }
        }

        if (laborLines.isEmpty()) {
            return;
        }

        // NOTE: Use SMAX_PS_ContractEntitlement__c to find the Entitlement on the WO
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>(
        [SELECT Id, Name, SVMXC__Order_Status__c, SVMXC__Order_Type__c, RecordTypeId,
                SMAX_PS_ContractItem__r.Id, SMAX_PS_ContractItem__r.Name,
                SMAX_PS_ContractItem__r.BD_Remote_Hours_Remaining__c
        FROM SVMXC__Service_Order__c WHERE Id IN :woIds]);
        Map<Id, SVMXC__Service_Contract__c> itemMap = new Map<Id, SVMXC__Service_Contract__c>();
        for (SVMXC__Service_Order__c wo : woMap.values())
        {
            if (wo.SMAX_PS_ContractItem__r != null)
            {
                // This makes sure we only have 1 copy of each Contract Item.. if more than 1 line per each in trigger
                itemMap.put(wo.SMAX_PS_ContractItem__r.Id, wo.SMAX_PS_ContractItem__r);
            }
        }

        Boolean anyUpdates = false;
        for (SVMXC__Service_Order_Line__c line : laborLines)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(line.Id);
            // Do not care if WO is "Remote" vs. "Field_Service"... we should we always consume Labor hours if entitled
            SVMXC__Service_Order__c wo = woMap.get(line.SVMXC__Service_Order__c);
            if (wo.SMAX_PS_ContractItem__r != null)
            {
                SVMXC__Service_Contract__c item = itemMap.get(wo.SMAX_PS_ContractItem__r.Id);
                if (item != null && item.BD_Remote_Hours_Remaining__c != null)
                {
                    if (line.SVMXC__Product__c == null) {
                        line.addError('To consume Remote Support Hours you must specify a Labor Product');
                    }

                    Decimal newQty = (line.SVMXC__Actual_Quantity2__c == null) ? 0.0 : line.SVMXC__Actual_Quantity2__c;
                    Decimal oldQty = (old == null || old.SVMXC__Actual_Quantity2__c == null) ? 0.0 : old.SVMXC__Actual_Quantity2__c;
                    Decimal consumedHours = 0.0;
                    if (Trigger.isDelete || line.SVMXC__Line_Status__c == 'Canceled') {
                        consumedHours = -1 * newQty;
                    } else if (old == null) { // insert or undelete
                        consumedHours = newQty;
                    } else {
                        consumedHours = newQty - oldQty;
                    }

                    if (consumedHours != 0.0) {
                        anyUpdates = true;
                        item.BD_Remote_Hours_Remaining__c = item.BD_Remote_Hours_Remaining__c - consumedHours;
                        if (item.BD_Remote_Hours_Remaining__c < 0.0) {
                            line.addError('Not enough Remote Support Hours Remaining on ' + item.Name);
                        }
                    }
                }
            }
        }

        if (anyUpdates) {
            update itemMap.values();
        }
    }

    // 06/20/2022 ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
    // NOTE: Should be called by AfterUpdate event
    public static void deleteWorkDetailRecords(List<SVMXC__Service_Order_Line__c> workDetailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Delete Work Detail Records', 'Delete Work Detail records when they are marked for deletion.'))
            return;

        // Get the WDL Ids list of records that are marked for deletion
        Set<Id> workDetailIdsToDelete = new Set<Id>();
        for(SVMXC__Service_Order_Line__c workDetail :workDetailList) {

            if (workDetail.SMAX_PS_Delete_Line__c == true) {

                workDetailIdsToDelete.add(workDetail.Id);
            }
        }

        if (workDetailIdsToDelete.isEmpty())
            return;

        // Get the list of Work Detail records to delete
        List<SVMXC__Service_Order_Line__c> workDetailsToDelete = [SELECT Id, SMAX_PS_Delete_Line__c FROM SVMXC__Service_Order_Line__c WHERE Id IN: workDetailIdsToDelete];
        System.debug('Deleting Work Details: ' + workDetailsToDelete.size() + ' ' + workDetailsToDelete);
        delete workDetailsToDelete;
    }

    // 08/04/2023 ITSVMX-1227 Update Work Detail Plant and Work Center from either Technician or Additional Work Center
    // 08/24/2023 ITSVMX-1227 Only enable logic if Usage+Labor/Travel and either WO/WorkDetail Tech is populated.
    // NOTE: Should be called by BeforeInsert and BeforeUpdate
    public static void updateWorkDetailPlantAndWorkCenter(List<SVMXC__Service_Order_Line__c> workDetailList, Map<Id, SVMXC__Service_Order_Line__c> oldMap){

        System.debug('Entering SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter method');

        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;

        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> technicianIds = new Set<Id>();

        // Get the Word Detail records that we need to process
        Set<SVMXC__Service_Order_Line__c> workDetailsToProcess = new Set<SVMXC__Service_Order_Line__c>();
        for(SVMXC__Service_Order_Line__c workDetail :workDetailList) {
            // 08/24/2023: Only process Usage/Consumption + Labor/Travel lines
            Boolean isLaborTravel = (workDetail.RecordTypeId == usageRecTypeId &&
                    (workDetail.SVMXC__Line_Type__c == 'Labor' || workDetail.SVMXC__Line_Type__c == 'Travel'));
            if (!isLaborTravel) {
                continue;
            }

            SVMXC__Service_Order_Line__c old = oldMap == null ? null : oldMap.get(workDetail.Id);
            if ( old == null
                    || workDetail.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c
                    || workDetail.SMAX_PS_Plant__c == null
                    || workDetail.SMAX_PS_Work_Center__c == null) {

                workDetailsToProcess.add(workDetail);
                workOrderIds.add(workDetail.SVMXC__Service_Order__c);
                if (workDetail.SVMXC__Group_Member__c != null) {
                    technicianIds.add(workDetail.SVMXC__Group_Member__c);
                }
            }
        }
        System.debug('workDetailsToProcess: ' + workDetailsToProcess.size() + ' ' + workDetailsToProcess);
        System.debug('workOrderIds: ' + workOrderIds.size() + ' ' + workOrderIds);
        System.debug('technicianIds: ' + technicianIds.size() + ' ' + technicianIds);

        if (workDetailsToProcess.isEmpty()) return;

        // Create a Work Order Id to Work Order Map
        Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>([
                SELECT Id, SMAX_PS_SAP_Maintenance_Plant__c, SMAX_PS_SAP_Work_Center__c,
                        SVMXC__Group_Member__c, SMAX_PS_Owned_By_Company__c, SVMXC__Group_Member__r.SMAX_PS_Plant__c,
                        SMAX_PS_Is_Enterprise__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN: workOrderIds
        ]);
        // 08/24/2023 Collect the WO Technician Ids also...
        for (SVMXC__Service_Order__c wo : workOrderMap.values()) {
            if (wo.SVMXC__Group_Member__c != null) {
                technicianIds.add(wo.SVMXC__Group_Member__c);
            }
        }

        // Create a Technician Id to Technician Map
        Map<Id, SVMXC__Service_Group_Members__c> technicianMap = new Map<Id, SVMXC__Service_Group_Members__c>([
                SELECT Id, SMAX_PS_Plant__c, SMAX_PS_Work_Center__c
                FROM SVMXC__Service_Group_Members__c
                WHERE Id IN: technicianIds
        ]);
        System.debug('technicianMap: ' + technicianMap.size() + ' ' + technicianMap);

        // Get Additional Work Center External Ids
        Set<String> additionalWorkCenterIds = new Set<String>();
        for (SVMXC__Service_Order_Line__c workDetail : workDetailsToProcess) {
            SVMXC__Service_Order__c workOrder = workOrderMap.get(workDetail.SVMXC__Service_Order__c);
            Id techId = (workDetail.SVMXC__Group_Member__c != null) ? workDetail.SVMXC__Group_Member__c : workOrder.SVMXC__Group_Member__c;
            additionalWorkCenterIds.add(techId + '-' + workOrder.SMAX_PS_SAP_Maintenance_Plant__c);
        }
        System.debug('additionalWorkCenterIds: ' + additionalWorkCenterIds.size() + ' ' + additionalWorkCenterIds);

        // Get the Service Debrief Settings
        Map<String, SMAX_PS_Service_Debrief_Settings__mdt> serviceDebriefSettingsMap = SMAX_PS_Service_Debrief_Settings__mdt.getAll();

        // Get Technician Additional Work Centers
        Map<String, SMAX_PS_Additional_Work_Centers__c> externalIdToAdditionalWorkCentersMap = new Map<String, SMAX_PS_Additional_Work_Centers__c>();
        List<SMAX_PS_Additional_Work_Centers__c> additionalWorkCenters = [
                SELECT Id, SMAX_PS_External_ID__c, SMAX_PS_Technician_Equipment__c, SMAX_PS_Plant__c, SMAX_PS_Work_Center__c
                FROM SMAX_PS_Additional_Work_Centers__c
                WHERE SMAX_PS_External_ID__c IN :additionalWorkCenterIds
        ];
        for(SMAX_PS_Additional_Work_Centers__c additionalWorkCenter :additionalWorkCenters) {
            externalIdToAdditionalWorkCentersMap.put(additionalWorkCenter.SMAX_PS_External_ID__c, additionalWorkCenter);
        }
        System.debug('externalIdToAdditionalWorkCentersMap: ' + externalIdToAdditionalWorkCentersMap.size() + ' - ' + externalIdToAdditionalWorkCentersMap);

        for(SVMXC__Service_Order_Line__c woDetail :workDetailsToProcess){

            SVMXC__Service_Order__c workOrder = workOrderMap.get(woDetail.SVMXC__Service_Order__c);
            // 08/24/2023 Lookup Tech from EITHER WO or WorkDetail
            Id techId = (woDetail.SVMXC__Group_Member__c != null) ? woDetail.SVMXC__Group_Member__c : workOrder.SVMXC__Group_Member__c;
            SVMXC__Service_Group_Members__c tech = technicianMap.get(techId);
            if (tech == null) {
                System.debug('Skipping Work Detail because no Tech found on Work Detail or Work Order: ' + woDetail);
                continue;
            }
            System.debug('tech' + tech);
            // ITSVMX-1295 Fill in the Work Detail -> Technician lookup if blank
            if (woDetail.SVMXC__Group_Member__c == null) {
                woDetail.SVMXC__Group_Member__c = techId;
            }
            // ITSVMX-1227 If Tech's Plant is blank skip this logic
            if (String.isBlank(tech.SMAX_PS_Plant__c)) {
                System.debug('Skipping Work Detail because Tech has a blank Plant: ' + woDetail);
                continue;
            }
            // ITSVMX-1227/ITSVMX-1343 Exclude Enterprise WOs from Additional Work Center logic/error
            if (workOrder.SMAX_PS_Is_Enterprise__c == true) {
                System.debug('Skipping Work Detail because WO Is Enterprise: ' + woDetail);
                continue;
            }

            // If MDT Labor/Travel is enabled for the Work Order Company then use the Technician record values or the Additional Work Center record values
            if (workOrder.SMAX_PS_Owned_By_Company__c != null
                    && serviceDebriefSettingsMap.containsKey(workOrder.SMAX_PS_Owned_By_Company__c)
                    && serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c).SMAX_PS_Enable_Additional_LaborTravel__c == true) {

                // if the work order plant is equal to the technician plant then use the Technician record values
                if (workOrder.SMAX_PS_SAP_Maintenance_Plant__c == tech.SMAX_PS_Plant__c){
                    woDetail.SMAX_PS_Plant__c = tech.SMAX_PS_Plant__c;
                    woDetail.SMAX_PS_Work_Center__c = tech.SMAX_PS_Work_Center__c;
                    System.debug('Set the Work Detail Plant and Work Center to the Technician Plant and Work Center');
                } else {
                    // if the technician is not null and the work order plant is not equal to the technician plant then use the Additional Work Center record values
                    SMAX_PS_Additional_Work_Centers__c additionalWorkCenter = externalIdToAdditionalWorkCentersMap.get(tech.Id + '-' + workOrder.SMAX_PS_SAP_Maintenance_Plant__c);
                    if (additionalWorkCenter != null) {
                        woDetail.SMAX_PS_Plant__c = additionalWorkCenter.SMAX_PS_Plant__c;
                        woDetail.SMAX_PS_Work_Center__c = additionalWorkCenter.SMAX_PS_Work_Center__c;
                        System.debug('Set the Work Detail Plant and Work Center to the Additional Work Center Plant and Work Center');
                    } else {
                        System.debug('SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter() - Error: Technician or Additional Work Center is null');
                        woDetail.addError('You do not have access to debrief Labor or Travel for this Work Order\'s shared Work Centre.  Please contact your System Administrator for resolution.');
                    }
                }
            } else {
                // if the "Enable Additional LaborTravel" setting is disabled then use the Technician record values
                woDetail.SMAX_PS_Plant__c = tech.SMAX_PS_Plant__c;
                woDetail.SMAX_PS_Work_Center__c = tech.SMAX_PS_Work_Center__c;
                System.debug('Set the Work Detail Plant and Work Center to the Technician Plant and Work Center');
            }
        }
    }
}
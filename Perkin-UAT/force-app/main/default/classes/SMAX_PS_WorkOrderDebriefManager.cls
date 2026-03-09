/**
 *  Apex Class for Work Order One-Click Complete / Submit Logic
 *  Code Coverage for this class can be found in: SMAX_PS_WorkOrder_UT
 *
 *  2018-05-09       Frank VanLoon             Initial copy of One-Click Complete
 * 2021-11-03  ITSVMX-351 Allow CRC Profile user to cancel the estimate with consumption lines give error message to all other profiles
 * Created meta data type Service Max profile to maintain profile which require skipping validation
 * 2021-11-09 Tony ITSVMX-606 Scheduled Duration Redesign - we want to remove any calendar events even if the Technician is not set
 *
 */
public with sharing class SMAX_PS_WorkOrderDebriefManager {

    public static String WORK_COMPLETE = 'Work Complete';
    public static String WORK_COMPLETE_PENDING = 'Work Complete - Pending';
    public static String WORK_COMPLETE_ERROR = 'Work Complete - Error';
    public static String WORK_COMPLETE_MATERIAL_FOLLOW_UP = 'Work Complete - Material Follow Up';
    public static String CANCELED = 'Canceled';
    public static Set<String> NON_PRICED_WO_TYPES = new Set<String> { 'Installation', 'Internal' };

    public static Boolean IS_PROCESSING_DEBRIEF_RESPONSE = false;

    private SMAX_PS_WorkOrderDebriefManager() {}

    /**
     *  Update the child Work Detail lines Status to "Submitted" on "One-Click Complete" OR "Submit All Lines"
     *  NOTE: This method replaces both updateWorkDetailLineStatus(...) & addWorkCompleteError(...)
     *  Should be called in the "before" trigger(s)
     */
    public static void submitCompleteAll(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Submit Complete All', 'Update the child Work Detail lines Status to "Submitted" on "One-Click Complete" OR "Submit All Lines"'))
            return;

        if (IS_PROCESSING_DEBRIEF_RESPONSE)
            return;

        // Collect qualified Work Order Ids
        Map<Id, SVMXC__Service_Order__c> woRepReqMap = new Map<Id, SVMXC__Service_Order__c>(); // 11/16/20 tony - Advanced Replacement - Check Replacement Required records
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        Set<Id> submitIds = new Set<Id>();
        Set<Id> completeIds = new Set<Id>();
        for (SVMXC__Service_Order__c workOrder : woNewList)
        {
            SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);
            if ( old != null && old.SMAX_PS_SubmitAllLines__c != workOrder.SMAX_PS_SubmitAllLines__c && workOrder.SMAX_PS_SubmitAllLines__c == TRUE)
            {
                woMap.put(workOrder.Id, workOrder);
                workOrder.SMAX_PS_SubmitAllLines__c=false;
                submitIds.add(workOrder.Id);
            }
            if ( old != null && old.SVMXC__Order_Status__c != workOrder.SVMXC__Order_Status__c && workOrder.SVMXC__Order_Status__c == WORK_COMPLETE)
            {
                woMap.put(workOrder.Id, workOrder);
                completeIds.add(workOrder.Id);
                // 11/16/20 tony - Advanced Replacement - Check Replacement Required records
                if (workOrder.SVMX_PS_Replacement_Required__c == true) {
                    woRepReqMap.put(workOrder.Id, workOrder);
                }
            }
        }
        System.debug('woRepReqMap.keyset: ' + woRepReqMap.keySet());

        if (woMap.isEmpty())
            return;

        // 11/16/20 tony - Advanced Replacement - Get list of Work Detail Lines with Serials
        Map<Id, Set<String>> woIdToRecTypeMap = new Map<Id, Set<String>>();
        Set<String> validRecordTypes = new Set<String>{'RMA', 'Request', 'Delivery', 'Shipment'};
        Map<Id, List<SVMXC__Service_Order_Line__c>> woToDebriefListMap = new Map<Id, List<SVMXC__Service_Order_Line__c>>();
        List<SVMXC__Service_Order_Line__c> workDetailLines = new List<SVMXC__Service_Order_Line__c>();
        if (!woRepReqMap.isEmpty()) {
            workDetailLines = [
                    SELECT Id, Name, SVMXC__Product__c, SVMX_PS_VS_Consumed_Stocked_Serial__c, SVMXC__Service_Order__c, SVMXC__Line_Status__c
                    FROM SVMXC__Service_Order_Line__c
                    WHERE SVMXC__Service_Order__c IN :woRepReqMap.keySet()
                    AND SVMXC__Line_Status__c != 'Canceled'
                    AND SVMX_PS_VS_Consumed_Stocked_Serial__c != NULL
            ];
            System.debug('workDetailLines: ' + workDetailLines);

            // 11/16/20 tony - Advanced Replacement - Map of Work Order Ids to List of Debrief Lines
            for (SVMXC__Service_Order__c wo :woRepReqMap.values()) {
                for (SVMXC__Service_Order_Line__c wd :workDetailLines) {
                    if (wo.Id == wd.SVMXC__Service_Order__c && wo.SVMXC__Product__c == wd.SVMXC__Product__c) {

                        if (woToDebriefListMap.get(wo.Id) == null) {
                            woToDebriefListMap.put(wo.Id, new List<SVMXC__Service_Order_Line__c>());
                        }
                        woToDebriefListMap.get(wo.Id).add(wd);
                    }
                }
            }
            System.debug('woToDebriefListMap: ' + woToDebriefListMap);

            // Use header instead and don't worry about the serials for RMA, Parts Request, Delivery, and Shipment
            // ONLY worry about statuses NOT 'Error' or 'Canceled'
            List<SVMXC__RMA_Shipment_Order__c> rmaShipmentOrders = [
                    SELECT Id, Name, SVMXC__Service_Order__c, RecordType.DeveloperName
                    FROM SVMXC__RMA_Shipment_Order__c
                    WHERE SVMXC__Service_Order__c IN :woToDebriefListMap.keySet()
            ];
            System.debug('RMA Records found: ' + rmaShipmentOrders);

            for (SVMXC__RMA_Shipment_Order__c rma :rmaShipmentOrders) {

                if (woIdToRecTypeMap.get(rma.SVMXC__Service_Order__c) == null) {
                    woIdToRecTypeMap.put(rma.SVMXC__Service_Order__c, new Set<String>());
                }

                if (rma.RecordType.DeveloperName != 'Error' && rma.RecordType.DeveloperName != 'Canceled') {
                    woIdToRecTypeMap.get(rma.SVMXC__Service_Order__c).add(rma.RecordType.DeveloperName);
                }
            }
            System.debug('Parts Orders RecordTypes for Work Orders: ' + woIdToRecTypeMap);
        }




        String txnId = String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));

        // Get Record Type Id for Usage Consumption
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        // ITSFDC-1047 Also look for "Remote Support" Record Type
        Id remoteRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'SMAX_PS_Remote_Support').Id;
        // ITSFDC-893 Also look for "Tool" Record Type
        //Id toolRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'SMAX_PS_Tools').Id;

        System.debug('SUBMIT-COMPLETE ALL Starting');

        // Select the Work Detail lines which qualify for updating
        // SVMXCFG-943 Load the Consumed From Location field: SMAX_PS_Non_Consumable_Location__c
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>([SELECT Id, Name, RecordTypeId,
                SVMXC__Line_Status__c, SVMXC__Line_Type__c, SVMXC__Service_Order__c,
                SVMXC__Product__c, SMAX_PS_ContractPercentDiscount__c, SMAX_PS_IntegrationStatus__c,
                SVMXC__Consumed_From_Location__r.SMAX_PS_Non_Consumable_Location__c, RecordType.DeveloperName,
                // 11/16/20 tony - Advanced Replacement - query Serial Number
                SVMXC__Serial_Number__c, SVMXC__Serial_Number__r.SMAX_PS_Serial_Number__c, SVMXC__Service_Order__r.SVMX_PS_Replacement_Required__c
        FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c in :woMap.keySet()
        AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId) AND SVMXC__Line_Status__c!='Canceled']);
        System.debug('wdList: ' + wdList);
        // ITSFDC-893 if Calibrated Tool Used = "Registered MTE" then make sure that at least 1 Calibrated Tool line exists
        //AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId, :toolRecTypeId) AND SVMXC__Line_Status__c!='Canceled']);

        // Fill Debrief Map
        Map<Id, DebriefDetails> debriefMap = new Map<Id, DebriefDetails>();
        for (SVMXC__Service_Order_Line__c wd : wdList) {
            SVMXC__Service_Order__c wo = woMap.get(wd.SVMXC__Service_Order__c);
            // ITSFDC-1047 Send "Remote Support" lines, but only for "Remote Support Hours" WO's
            if (wd.RecordTypeId == remoteRecTypeId && !wo.BD_Is_Remote_Support_Hours__c) {
                continue;
            }

            if(!debriefMap.containskey(wd.SVMXC__Service_Order__c)) {
                debriefMap.put(wd.SVMXC__Service_Order__c, new DebriefDetails());
            }
            // SVMXCFG-380 - Fault Code "Required" Rule Changes... load more details
            DebriefDetails details = debriefMap.get(wd.SVMXC__Service_Order__c);
            details.allLines.add(wd);
            if (wd.SVMXC__Line_Type__c == 'Fault Code')
                details.faultCodeLines++;
            else
                    details.debriefLines++;
            if (wd.SVMXC__Line_Status__c == 'Submitted' && wd.SMAX_PS_IntegrationStatus__c != 'Error')
                details.stuckLines++;
            // ITSFDC-893 if Calibrated Tool Used = "Registered MTE" then make sure that at least 1 Calibrated Tool line exists
            //if (wd.RecordTypeId == toolRecTypeId) {
            //  details.toolLines++;
            //}

            // 11/16/20 tony - Advanced Replacement - Add error for missing records
            if (woToDebriefListMap.get(wd.SVMXC__Service_Order__c) == null && wd.SVMXC__Service_Order__r.SVMX_PS_Replacement_Required__c == true)
                details.advancedReplacementLines++;

            System.debug('woIdToRecTypeMap.get(wd.SVMXC__Service_Order__c): ' + woIdToRecTypeMap.get(wd.SVMXC__Service_Order__c));
            if ((woIdToRecTypeMap.get(wd.SVMXC__Service_Order__c) == null
                    || !woIdToRecTypeMap.get(wd.SVMXC__Service_Order__c).containsAll(validRecordTypes))
                    && wd.SVMXC__Service_Order__r.SVMX_PS_Replacement_Required__c == true)
                details.advancedReplacementLines++;

        }

        // Determine if there are any Errors to report (only for "Work Complete" WOs)
        for (Id woId : completeIds)
        {
            SVMXC__Service_Order__c wo = woMap.get(woId);
            wo.SMAX_PS_Completion_Errors__c = null;
            List<String> errorMsgs = new List<String>();
            DebriefDetails details = (debriefMap.containsKey(wo.Id)) ? debriefMap.get(wo.Id) : new DebriefDetails();

            // SVMXCFG-366 Complaints: WO Complete Requires Fault Code
            if (details.faultCodeLines == 0)
            {
                // ITSFDC-1047 Do NOT require Fault Codes for "Remote Support Hours" WO's
                // SVMXCFG-380: If 0 Confirmed Debrief Lines, Installation, or TPV skip this..
                if (details.debriefLines == 0 || wo.SMAX_PS_Is_TPV__c == true || wo.BD_Is_Remote_Support_Hours__c == true) // wo.SMAX_PS_Is_Install__c == TRUE ||
                {
                    System.debug('SKIPPING Fault Code Validation because NO Lines OR TPV OR REMOTE SUPPORT');
                }
                else
                {
                    errorMsgs.add('At least one Fault Code line must be entered when other Debrief lines are entered.');
                }
            }

            // ITSFDC-893 if Calibrated Tool Used = "Registered MTE" then make sure that at least 1 Calibrated Tool line exists
            //if (details.toolLines == 0 && wo.Calibrated_Tool__c == 'Registered MTE')
            //{
            //  errorMsgs.add('At least one Calibrated Tool line must be entered when the Calibrated Tool Used = "Registered MTE".');
            //}

            if (details.stuckLines > 0)
            {
                errorMsgs.add('Wait for the ' + details.stuckLines + ' Submitted Line(s) to finish processing.');
            }

            // 11/16/20 tony - Advanced Replacement - Check for Advanced Replacement errors
            if (details.advancedReplacementLines > 0 && woRepReqMap.get(woId) != null) {
                errorMsgs.add('Work orders for an Advanced Replacement must have a completed RMA for the instrument/part being returned, and, a Delivery and stock serial debrief line for the replacement instrument/part.');
            }

            if (!errorMsgs.isEmpty())
            {
                String errorMsg = 'For a Work Order to transition to "Work Complete", the following must be corrected: ' + errorMsgs;
                // SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
                //wo.addError(errorMsg);
                wo.SMAX_PS_Completion_Errors__c = errorMsg;
                wo.SVMXC__Order_Status__c = 'Work Complete - Error';
                // Remove from woMap so we don't process any more..
                woMap.remove(wo.Id);
            }
        }

        // SVMXCFG-335 WO Submit Lines: Skip Priced on 100% Discount Lines
        Map<Id, List<SVMXC__Service_Order_Line__c>> linesToDiscount = new Map<Id, List<SVMXC__Service_Order_Line__c>>();

        // Update Work Detail Lines Status
        //Set<Id> woIdsToSend = new Set<Id>(woMap.keySet());
        Set<Id> woIdsWithLinesToSend = new Set<Id>();
        Map<Id, List<String>> woProblems = new Map<Id, List<String>>();
        List<SVMXC__Service_Order_Line__c> wdToUpdate = new List<SVMXC__Service_Order_Line__c>();
        for (Id woId : woMap.keySet())
        {
            SVMXC__Service_Order__c wo = woMap.get(woId);
            DebriefDetails details = (debriefMap.containsKey(woId)) ? debriefMap.get(woId) : new DebriefDetails();
            for ( SVMXC__Service_Order_Line__c wd : details.allLines )
            {
                System.debug('SUBMIT-COMPLETE ALL WO: ' + wo);
                // SVMXCFG-943: Do not allow to complete if any "Non_Consumable" = TRUE
                if (wd.SVMXC__Consumed_From_Location__r != null &&
                        wd.SVMXC__Consumed_From_Location__r.SMAX_PS_Non_Consumable_Location__c == TRUE)
                {
                    if (!woProblems.containsKey(woId))
                    {
                        woProblems.put(woId, new List<String>());
                    }
                    woProblems.get(woId).add('Parts from Non-Consumable Location is not able to be Submitted: ' + wd.Name);
                }
                // ITSFDC-893 If this is a Calibrated Tool line then skip it.
                //else if (wd.RecordTypeId == toolRecTypeId)
                //{
                //  System.debug('Skipping Calibrated Tool Work Detail line');
                //}
                else if (wd.SVMXC__Line_Status__c == 'Priced'
                        // SVMXINT-469 Complaints: Fault Code Integration Changes (Send Fault Codes only if not Confirmed)
                        || (wd.SVMXC__Line_Type__c == 'Fault Code' && wd.SVMXC__Line_Status__c == 'Open')
                        // JIRA #392 - Internal / Installation - Skip Priced
                        || (NON_PRICED_WO_TYPES.contains(wo.SVMXC__Billing_Type__c) && wd.SVMXC__Line_Status__c == 'Open') )
                {
                    wd.SVMXC__Line_Status__c='Submitted';
                    wd.SMAX_PS_SubmitTxnId__c = txnId;
                    wdToUpdate.add(wd);
                    woIdsWithLinesToSend.add(woId);
                }
                else if (wd.SVMXC__Line_Status__c == 'Submitted' && wd.SMAX_PS_IntegrationStatus__c == 'Error')
                {
                    // How should they take the line from Submitted back to Open/Error/Priced and back?
                    // What do we do about lines already in Submitted?!?
                    wd.SMAX_PS_IntegrationStatus__c = 'Pending';
                    wd.SMAX_PS_SubmitTxnId__c = txnId;
                    wdToUpdate.add(wd);
                    woIdsWithLinesToSend.add(woId);
                }
                else if (wo.SMAX_PS_ContractEntitlement__c != null && wd.SVMXC__Line_Status__c == 'Open'
                        && wd.SMAX_PS_ContractPercentDiscount__c == null)
                {
                    if (!linesToDiscount.containsKey(wo.Id))
                        linesToDiscount.put(wo.Id, new List<SVMXC__Service_Order_Line__c>());
                    linesToDiscount.get(wo.Id).add(wd);
                }
                else if (wd.SVMXC__Line_Status__c != 'Confirmed')
                {
                    if (!woProblems.containsKey(woId))
                        woProblems.put(woId, new List<String>());
                    woProblems.get(woId).add('Non-Confirmed line is not able to be Submitted: ' + wd.Name);
                }
            }
        }

        for (Id woId : linesToDiscount.keySet())
        {
            SVMXC__Service_Order__c wo = woMap.get(woId);
            List<SVMXC__Service_Order_Line__c> lines = linesToDiscount.get(woId);
            // Call to lookup / apply Contract Discount to each line (contains SOQL.. not loop safe)
            SMAX_PS_WorkOrderPricingService.applyContractDiscounts(wo, lines);

            for (SVMXC__Service_Order_Line__c wd : lines)
            {
                // Check if a 100% Contract Discount and if so skip "Priced" status..
                if (wd.SMAX_PS_ContractPercentDiscount__c == 100.00)
                {
                    wd.SVMXC__Line_Status__c = 'Submitted';
                    wd.SMAX_PS_SubmitTxnId__c = txnId;
                    wdToUpdate.add(wd);
                    woIdsWithLinesToSend.add(woId);
                }
                else
                {
                    if (!woProblems.containsKey(woId))
                        woProblems.put(woId, new List<String>());
                    woProblems.get(woId).add('Non-Confirmed line is not able to be Submitted: ' + wd.Name);
                }
            }
        }

        if (!wdToUpdate.isEmpty())
            update wdToUpdate;

        // Send the appropriate Events..
        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        for (Id woId : woMap.keySet())
        {
            SVMXC__Service_Order__c wo = woMap.get(woId);
            Boolean anyLinesToSend = woIdsWithLinesToSend.contains(woId);
            List<String> problems = woProblems.get(woId);
            if (completeIds.contains(woId))
            {
                if (problems != null && !problems.isEmpty())
                {
                    String errorMsg = 'For a Work Order to transition to "Work Complete", the following must be corrected: ' + problems;
                    wo.SMAX_PS_Completion_Errors__c = errorMsg;
                    wo.SVMXC__Order_Status__c = WORK_COMPLETE_ERROR;
                    // SVMXCFG-943 - Redirect to "Work Complete - Material Follow Up" Status
                    if (errorMsg.contains('Non-Consumable Location'))
                    {
                        wo.SVMXC__Order_Status__c = WORK_COMPLETE_MATERIAL_FOLLOW_UP;
                    }
                    // Allow "Submit All Lines" to run at least..
                    submitIds.add(woId);
                }
                else if (anyLinesToSend)
                {
                    wo.SVMXC__Order_Status__c = WORK_COMPLETE_PENDING;

                    SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                    iEvent.SMAX_PS_Action__c = 'SUBMIT-COMPLETE';
                    iEvent.SMAX_PS_WorkOrderId__c = woId;
                    iEvent.SMAX_PS_SubmitTxnId__c = txnId;
                    events.add(iEvent);
                }
                else if (wo.SMAX_PS_SAP_SystemStatus__c != 'TECO')
                {
                    SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                    iEvent.SMAX_PS_Action__c = 'COMPLETE';
                    iEvent.SMAX_PS_WorkOrderId__c = woId;
                    events.add(iEvent);
                }
                else
                {
                    // JIRA #391 - Reissue Billing Request (after Rejecting)
                    if (SMAX_PS_WorkOrderManager.isBillable(wo))
                    {
                        SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                        iEvent.SMAX_PS_Action__c = 'BILLING REQUEST';
                        iEvent.SMAX_PS_WorkOrderId__c = wo.Id;
                        events.add(iEvent);
                    }
                    else
                    {
                        // WHAT NOW.. do we go straight to Closed?!?
                    }
                }
            }
            if (anyLinesToSend && submitIds.contains(woId))
            {
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                iEvent.SMAX_PS_Action__c = 'SUBMIT';
                iEvent.SMAX_PS_WorkOrderId__c = woId;
                iEvent.SMAX_PS_SubmitTxnId__c = txnId;
                events.add(iEvent);
            }
        }

        // SVMXCFG-648 Reusing this method to ensure only 1 Event is sent
        //SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
        SMAX_PS_WorkOrderManager.sendWorkOrderEvents(events);
    }

    public class DebriefDetails
    {
        public Integer debriefLines { get; set; }
        public Integer faultCodeLines { get; set; }
        // ITSFDC-893 if Calibrated Tool Used = "Registered MTE" then make sure that at least 1 Calibrated Tool line exists
        //public Integer toolLines { get; set; }
        public Integer stuckLines { get; set; }
        // 11/17/20 tony - Advanced Replacement - add new error
        public Integer advancedReplacementLines {get; set;}
        public List<SVMXC__Service_Order_Line__c> allLines = new List<SVMXC__Service_Order_Line__c>();

        public DebriefDetails()
        {
            this.debriefLines = 0;
            this.faultCodeLines = 0;
            // ITSFDC-893 if Calibrated Tool Used = "Registered MTE" then make sure that at least 1 Calibrated Tool line exists
            //this.toolLines = 0;
            this.stuckLines = 0;
            // 11/17/20 tony - Advanced Replacement - add new error
            this.advancedReplacementLines = 0;
        }
    }

    // SVMXCFG-603: Cancel Work Order
    // SVMXCFG-553: added criteria to only send 'COMPLETE' events if External Id exists
    public static void cancelWorkOrders(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Cancel', 'Cancel a Work Order and send a TECO to SAP'))
            return;

        // Collect qualified Work Order Ids
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        Set<Id> cancelledIds = new Set<Id>();
        for (SVMXC__Service_Order__c workOrder : woNewList)
        {
            SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);
            if ( old != null && old.SVMXC__Order_Status__c != workOrder.SVMXC__Order_Status__c && workOrder.SVMXC__Order_Status__c == CANCELED)
            {
                workOrder.SMAX_PS_Original_Work_Order_Order_Type__c = old.SVMXC__Order_Type__c;
                woMap.put(workOrder.Id, workOrder);
                cancelledIds.add(workOrder.Id);
            }
        }

        if (woMap.isEmpty())
            return;

        // Get Record Type Id for Usage Consumption 
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;

        System.debug('WO Cancel Starting');

        // Select the Work Detail lines which qualify for updation
        List<SVMXC__Service_Order_Line__c> lineList = new List<SVMXC__Service_Order_Line__c>([SELECT Id, Name,
                SVMXC__Line_Status__c, SVMXC__Line_Type__c, SVMXC__Service_Order__c,
                SVMXC__Product__c, SMAX_PS_ContractPercentDiscount__c, SMAX_PS_IntegrationStatus__c
        FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c in :woMap.keySet()
        AND RecordTypeId = :usageRecTypeId AND SVMXC__Line_Status__c != 'Canceled' AND SVMXC__Line_Type__c != 'Fault Code']);

        Map<Id, List<SVMXC__Service_Order_Line__c>> lineMap = new Map<Id, List<SVMXC__Service_Order_Line__c>>();
        for (SVMXC__Service_Order_Line__c line : lineList)
        {
            if (!lineMap.containsKey(line.SVMXC__Service_Order__c))
                lineMap.put(line.SVMXC__Service_Order__c, new List<SVMXC__Service_Order_Line__c>());
            lineMap.get(line.SVMXC__Service_Order__c).add(line);
        }
        // ITSVMX-351 Get custom metadata type for CRC profile for Service request cancellation      
         List<SMAX_PS_Service_Max_profile__mdt> Service_Max_profiles = [
            SELECT SMAX_PS_Profile_name__c
            FROM SMAX_PS_Service_Max_profile__mdt
    ];

    //If custom meta type is not maintained write in debug log
    if (Service_Max_profiles.size() < 1) {
        System.debug('Custom Metadata Type [Service Max profile] records need to be created.');
//      return;  // 12/15/2021 Tony - Removed this return as it mean we don't do any validation of there are no custom metadata records.  This breaks our unit test.
    }   
        // Send the appropriate Events.. (or throw an error)        
        Set<Id> whatIds = new Set<Id>();
        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        for (SVMXC__Service_Order__c wo : woMap.values())
        {
            //Check if current profile is maintained in meta data type(allowed profile to skip validation)
            Boolean profileExists = false;
            for(SMAX_PS_Service_Max_profile__mdt profile :Service_Max_profiles)     {
                String currUserProfile = String.valueOf(wo.BD_Current_User_Profile__c) ;
                String allowedProfile = String.valueOf(profile.SMAX_PS_Profile_name__c);
                if(currUserProfile == allowedProfile){
                    profileExists = true;
            }
        }   
            List<SVMXC__Service_Order_Line__c> lines = lineMap.get(wo.Id);                  
            String serviceRequest = String.valueOf(wo.BD_Record_Type_formula__c) ;
            Boolean doValidation = true;
            if(serviceRequest == 'Service Request' && profileExists ){
                doValidation = false;
            }
            //Skip the validation for CRC profile for service request objects 
            if (lines != null && lines.size() > 0 && doValidation  )
            {
                List<String> lineNames = new List<String>();
                for (SVMXC__Service_Order_Line__c line : lines)
                    lineNames.add(line.Name);
                wo.addError('Work Order cannot be Canceled because there are Non-Cancelled Work Detail lines: ' + lineNames);
            }else{
                if (wo.SMAX_PS_SAP_SystemStatus__c != 'TECO' && wo.SVMX_PS_External_Id__c != null)
                {
                    SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                    iEvent.SMAX_PS_Action__c = 'COMPLETE';
                    iEvent.SMAX_PS_WorkOrderId__c = wo.Id;
                    events.add(iEvent);
                }

                if (wo.SVMXC__Group_Member__c != null)
                {
                    // SVMXCFG-648 Unassign...
                    wo.SVMXC__Group_Member__c = null;
                    wo.SVMXC__Service_Group__c = null;
//                  //wo.OwnerId = ???;
//                  whatIds.add(wo.Id);
                }
                // 11/9/21 ITSVMX-606 Scheduled Duration Redesign - we want to remove any calendar events even if the Technician is not set
                //wo.OwnerId = ???;
                whatIds.add(wo.Id);
            }
        }

        if (!whatIds.isEmpty())
        {
            List<Event> eventsToDelete = [SELECT Id, Subject, WhatId FROM Event WHERE WhatId IN :whatIds];
            if (!eventsToDelete.isEmpty())
            {
                Database.delete(eventsToDelete, false); // At least we tried..
            }
        }

        // SVMXCFG-648 Reusing this method to ensure only 1 Event is sent
        //SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
        SMAX_PS_WorkOrderManager.sendWorkOrderEvents(events);
    }
}
/**
 *  This Custom VisualForce Page / Controller were built for the following JIRA item:
 *  ITSVMX-370 Need the ability to mass Change schedule dates and customer required dates for mutiple WO's.
 *  Created by: Sarala Lakkireddy on 08/15/2021
 * * 11/08/2021: Added Long job scheduleing flag -Do not show long job scheduling flag
 **  Test class to Run: SMAX_PS_WorkOrder_UT
 */ 
public with sharing class SMAX_PS_WOMassUpdateSchDateController  
{
    // List of Saved SMAX_PS_Work_Order_Assign_View__c, Selected (or New), Filter Logic, etc.
    public SMAX_PS_Work_Order_Assign_View__c view { get; set; }
    public Id selectedViewId { get; set; }
    public Map<Id, SMAX_PS_Work_Order_Assign_View__c> myViewMap { get; set; }
    public List<SelectOption> myViews { get; set; }
    public Boolean anonymousView { get { return this.view.Id == null; }}

    public SMAX_PS_Work_Order_Assign_Filter__c newFilter { get; set; }
    public List<SMAX_PS_Work_Order_Assign_Filter__c> filters { get; set; }
    public Integer filterIdxToRemove { get; set; }
    private List<SMAX_PS_Work_Order_Assign_Filter__c> filtersToDelete;

    public class WorkOrderWrapper
    {
        public SVMXC__Service_Order__c wo { get; set; }
        public Id techId { get; set; }

        public WorkOrderWrapper(SVMXC__Service_Order__c wo)
        {
            if (wo.SVMXC__Scheduled_Date__c == null)
                wo.SVMXC__Scheduled_Date__c = Date.today();

            this.wo = wo;
            this.techId = null;
        }

        public String techName { get { return wo.SVMXC__Group_Member__c == null ? 'N/A' : wo.SVMXC__Group_Member__r.Name; }}
        public String woType { get { return wo.SVMXC__Billing_Type__c + ' / ' + wo.SVMXC__Order_Type__c; }}
        public String entCore { get { return wo.SMAX_PS_Is_Enterprise__c ? 'ENTERPRISE' : 'CORE'; }}
        // Added so we can display the Record Type
        public String woRecordType { get { return wo.BD_Record_Type_formula__c; }}
    }

    public List<WorkOrderWrapper> woList { get; set; }
    public List<WorkOrderWrapper> woListOld { get; set; }
    public List<SVMXC__Service_Group_Members__c> techList { get; set; }

    public Boolean showGrid { get { return !this.woList.isEmpty(); } }

    public String assignStatus { get; set; }


    public SVMXC__Service_Order__c InpWO  { get; set; }


    public SMAX_PS_WOMassUpdateSchDateController() {

        this.woList = new List<WorkOrderWrapper>();
        this.woListOld = new List<WorkOrderWrapper>();
        this.InpWO = new SVMXC__Service_Order__c();
        this.techList = new List<SVMXC__Service_Group_Members__c>();

        this.newFilter = new SMAX_PS_Work_Order_Assign_Filter__c();
        this.filters = new List<SMAX_PS_Work_Order_Assign_Filter__c>();
        this.filtersToDelete = new List<SMAX_PS_Work_Order_Assign_Filter__c>();

        this.view = new SMAX_PS_Work_Order_Assign_View__c();
        this.view.Name = 'NEW VIEW';
        // this.loadViews();
    }
        private void loadViews()
    {
        // Load current User's saved views
        this.myViews = new List<SelectOption>();
        this.myViews.add(new SelectOption('', 'New View...'));
        this.myViewMap = new Map<Id, SMAX_PS_Work_Order_Assign_View__c>();
        //Id userId = UserInfo.getUserId();
        for(SMAX_PS_Work_Order_Assign_View__c view : [SELECT Id, Name
            FROM SMAX_PS_Work_Order_Assign_View__c ORDER BY Name LIMIT 1000])
        {
            this.myViews.add(new SelectOption(''+view.Id, view.Name));
            this.myViewMap.put(view.Id, view);
        }
    }

    public PageReference selectView()
    { 
        if (this.selectedViewId != null)
        {
            this.view = this.myViewMap.get(this.selectedViewId);
            this.filters = 
            [SELECT Id, Name, SMAX_PS_Filter_Label__c, SMAX_PS_Filter_On__c, SMAX_PS_Work_Order_Assign_View__c,
                SMAX_PS_Account__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Location__c, SMAX_PS_Order_Status__c,
                SMAX_PS_Service_Team__c, SMAX_PS_Technician__c, SMAX_PS_Third_Party__c,
                SMAX_PS_Customer_Number__c, SMAX_PS_Billing_Type__c, SMAX_PS_Account_City__c,
                SMAX_PS_Work_Order_Numbers__c
              FROM SMAX_PS_Work_Order_Assign_Filter__c WHERE SMAX_PS_Work_Order_Assign_View__c = :view.Id LIMIT 1000];
            this.filtersToDelete.clear();
            this.applyFilters();
            this.woList.clear();
            this.woListOld.clear();
            this.techList.clear();
            this.assignStatus = null;
            
        }
        else
        {
            this.reset();
        }

        return null;
    }

    public PageReference reset()
    {
        this.view = new SMAX_PS_Work_Order_Assign_View__c();
        this.view.Name = 'NEW VIEW';
        this.filters.clear();
        this.filtersToDelete.clear();
        this.newFilter = new SMAX_PS_Work_Order_Assign_Filter__c();
        this.woList.clear();
        this.woListOld.clear();
        this.techList.clear();
        this.assignStatus = null;
        return null;
    }

    public PageReference shareView()
    {
        if (this.view.Id != null)
        {
            //String baseUri = 'https://' + URL.getSalesforceBaseUrl().getHost();
            //baseUri = baseUri.replace('visual.force', 'my.salesforce').replace('--c.', '.');

            return new PageReference('/p/share/CustomObjectSharingDetail?parentId=' + this.view.Id);
        }

        return null;
    }

    public PageReference saveView()
    {
        upsert this.view;

        for (SMAX_PS_Work_Order_Assign_Filter__c filter : this.filters)
        {
            if (filter.SMAX_PS_Work_Order_Assign_View__c == null)
                filter.SMAX_PS_Work_Order_Assign_View__c = this.view.Id;
        }
        upsert this.filters;

        if (!this.filtersToDelete.isEmpty())
        {
            delete this.filtersToDelete;
        }

        this.selectedViewId = this.view.Id;
        loadViews();
        this.selectView();

        return null;
    }

    public PageReference deleteView()
    {
        // TODO: Delete the View and all Filters
        return null;
    }

    public void addFilters()
    {
        if (this.newFilter.SMAX_PS_Filter_On__c == null)
            return;

        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Number' 
            || this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: SAP Service Order Number')
        {
            Boolean isSAP = this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: SAP Service Order Number';
            System.debug('## Raw WO Numbers: ' + this.newFilter.SMAX_PS_Work_Order_Numbers__c);
            String[] woNums = this.newFilter.SMAX_PS_Work_Order_Numbers__c.split('[\\n\\r\\s]+');
            String formatted = null;
            for (String woNum : woNums)
            {
                if (isSAP)
                {
                    woNum = woNum.leftPad(12, '0');
                }
                formatted = (formatted == null) ? '' : formatted + ',';
                formatted = formatted + '\'' + woNum + '\'';
            }
            this.newFilter.SMAX_PS_Work_Order_Numbers__c = formatted;
            System.debug('## WO Numbers: ' + this.newFilter.SMAX_PS_Work_Order_Numbers__c);
            this.newFilter.SMAX_PS_Filter_Label__c = formatted;
            if (this.newFilter.SMAX_PS_Filter_Label__c.length() > 25)
            {
                this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Filter_Label__c.substring(0, 25) + '...';
            }
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Account')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = [SELECT Id, Name FROM Account WHERE Id = :this.newFilter.SMAX_PS_Account__c].Name;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Is Enterprise')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Is_Enterprise__c + '';
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Location')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = [SELECT Id, Name FROM SVMXC__Site__c WHERE Id = :this.newFilter.SMAX_PS_Location__c].Name;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Order Status')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Order_Status__c;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Technician' || this.newFilter.SMAX_PS_Filter_On__c == 'Technician: Name')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = [SELECT Id, Name FROM SVMXC__Service_Group_Members__c WHERE Id = :this.newFilter.SMAX_PS_Technician__c].Name;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Customer Number')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Customer_Number__c;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Billing Type')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Billing_Type__c;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Work Order: Account City')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Account_City__c;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Technician: Service Team')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = [SELECT Id, Name FROM SVMXC__Service_Group__c WHERE Id = :this.newFilter.SMAX_PS_Service_Team__c].Name;
        }
        if (this.newFilter.SMAX_PS_Filter_On__c == 'Technician: Third Party')
        {
            this.newFilter.SMAX_PS_Filter_Label__c = this.newFilter.SMAX_PS_Third_Party__c + '';
        }

        if (this.newFilter.SMAX_PS_Filter_Label__c != null)
            this.filters.add(this.newFilter);
        this.newFilter = new SMAX_PS_Work_Order_Assign_Filter__c();
    }

    // ITSFDC-1242 Removed 'On Hold - Credit' from list of ILLEGAL_WO_STATUS as we need to be able to assign it now.
    public static List<String> ILLEGAL_WO_STATUS = new List<String> { 'Initializing', 'HSI', 'On Hold - Cost',
        'Canceled', 'Work Complete', 'Ready for Review', 'Ready to Invoice', 'Work Complete - Pending', 'Waiting for Invoicing', 'Closed', 
        'DMR Rejected', 'DMR Released', 'Invoiced', 'Work Complete - Error' };

    public void applyFilters()
    {
        this.assignStatus = null;
        Map<String, List<SMAX_PS_Work_Order_Assign_Filter__c>> filterMap = getFilterMap();

        String woFilter = '';
        for (String filterOn : filterMap.keySet())
        {
            if (!filterOn.startsWith('Work Order'))
                continue;

            List<SMAX_PS_Work_Order_Assign_Filter__c> filterList = filterMap.get(filterOn);
            if (filterOn == 'Work Order: Number')
            {
                woFilter = woFilter + ' AND NAME IN (' + getValueList(filterList, 'SMAX_PS_Work_Order_Numbers__c') + ')';
            }
            else if (filterOn == 'Work Order: SAP Service Order Number')
            {
                woFilter = woFilter + ' AND SVMX_PS_External_ID__c IN (' + getValueList(filterList, 'SMAX_PS_Work_Order_Numbers__c') + ')';
            }
            else if (filterOn == 'Work Order: Account')
            {
                woFilter = woFilter + ' AND SVMXC__Company__c IN (' + getValueList(filterList, 'SMAX_PS_Account__c') + ')';
            }
            else if (filterOn == 'Work Order: Is Enterprise')
            {
                woFilter = woFilter + ' AND SMAX_PS_Is_Enterprise__c = ' + filterList[0].SMAX_PS_Is_Enterprise__c;
            }
            else if (filterOn == 'Work Order: Location')
            {
                woFilter = woFilter + ' AND SVMXC__Site__c IN (' + getValueList(filterList, 'SMAX_PS_Location__c') + ')';
            }
            else if (filterOn == 'Work Order: Order Status')
            {
                woFilter = woFilter + ' AND SVMXC__Order_Status__c IN (' + getValueList(filterList, 'SMAX_PS_Order_Status__c') + ')';
            }
            else if (filterOn == 'Work Order: Technician')
            {
                woFilter = woFilter + ' AND SVMXC__Group_Member__c IN (' + getValueList(filterList, 'SMAX_PS_Technician__c') + ')';
            }
            else if (filterOn == 'Work Order: Customer Number')
            {
                woFilter = woFilter + ' AND SVMXC__Company__r.PKI_SAP_Customer_Number__c IN (' + getValueList(filterList, 'SMAX_PS_Customer_Number__c') + ')';
            }
            else if (filterOn == 'Work Order: Billing Type')
            {
                woFilter = woFilter + ' AND SVMXC__Billing_Type__c IN (' + getValueList(filterList, 'SMAX_PS_Billing_Type__c') + ')';
            }
            else if (filterOn == 'Work Order: Account City')
            {
                woFilter = woFilter + ' AND SVMXC__Company__r.PKI_SAP_City__c IN (' + getValueList(filterList, 'SMAX_PS_Account_City__c') + ')';
                //woFilter = woFilter + ' AND SVMXC__Company__r.ShippingCity IN (' + getValueList(filterList, 'SMAX_PS_Account_City__c') + ')';
            }
        }
        // ITSVMX-606: Changing Scheduled Duration field
        //ITSVMX-745 : Added scheduling status field
        String woQuery = 'SELECT Id, Name, SMAX_PS_Is_Enterprise__c, SVMXC__Order_Status__c, SVMXC__Billing_Type__c, SVMXC__Order_Type__c, '
            + 'SVMXC__Scheduled_Date__c, SVMXC__Scheduled_Date_Time__c, SMAX_PS_Scheduled_Duration_Hours__c, SVMX_PS_External_ID__c, '
            + 'SVMXC__Company__c, SVMXC__Company__r.Name, '
            + 'SVMXC__Site__c, SVMXC__Site__r.Name, '
            + 'SVMXC__Group_Member__c, SVMXC__Group_Member__r.Name, SVMXC__Service_Group__c, '
            + 'SMAX_PS_Tech_Expertise__c, SVMX_PS_Problem_Summary__c, OwnerId, SMAX_PS_Depot_Plant__c, BD_Record_Type_formula__c , '
            + 'SMAX_PS_Customer_Required_Start_Date__c, SVMXC__Work_Order_Scheduling_Status__c, SVMX_PS_Work_Order_Priority_Reason__c '
            + 'FROM SVMXC__Service_Order__c WHERE SVMXC__Order_Status__c NOT IN :ILLEGAL_WO_STATUS ' 
            // 11/4/21 ITSMVX-606 Add filter for "Is Long Job"
            + 'AND SVMX_PS_Is_Long_Job__c = FALSE'
            + woFilter + ' ORDER BY Name LIMIT 250';
        System.debug('WO QUERY = ' + woQuery);
        this.woList.clear();
        this.woListOld.clear();
        List<SVMXC__Service_Order__c> woResults = (List<SVMXC__Service_Order__c>) Database.query(woQuery);
        for (SVMXC__Service_Order__c wo : woResults){
            this.woList.add(new WorkOrderWrapper(wo));
            this.woListOld.add(new WorkOrderWrapper(wo));
        }
        System.debug('** WO LIST = ' + woList);

        String techFilter = '';
        for (String filterOn : filterMap.keySet())
        {
            if (!filterOn.startsWith('Technician'))
                continue;

            List<SMAX_PS_Work_Order_Assign_Filter__c> filterList = filterMap.get(filterOn);
            if (filterOn == 'Technician: Name')
            {
                techFilter = techFilter + ' AND Id IN (' + getValueList(filterList, 'SMAX_PS_Technician__c') + ')';
            }
            if (filterOn == 'Technician: Service Team')
            {
                techFilter = techFilter + ' AND SVMXC__Service_Group__c IN (' + getValueList(filterList, 'SMAX_PS_Service_Team__c') + ')';
            }
            if (filterOn == 'Technician: Third Party')
            {
                techFilter = techFilter + ' AND SVMXC__Third_Party__c = ' + filterList[0].SMAX_PS_Third_Party__c;
            }
        }
        String techQuery = 'SELECT Id, Name FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Active__c = TRUE' 
            + techFilter + ' ORDER BY Name LIMIT 25';
        System.debug('** TECH QUERY = ' + techQuery);
        this.techList = (List<SVMXC__Service_Group_Members__c>) Database.query(techQuery);
        System.debug('** TECH LIST = ' + techList);
    }

    private Map<String, List<SMAX_PS_Work_Order_Assign_Filter__c>> getFilterMap()
    {
        Map<String, List<SMAX_PS_Work_Order_Assign_Filter__c>> result = new Map<String, List<SMAX_PS_Work_Order_Assign_Filter__c>>();
        for (SMAX_PS_Work_Order_Assign_Filter__c filter : this.filters)
        {
            String key = filter.SMAX_PS_Filter_On__c;
            if (!result.containsKey(key))
                result.put(key, new List<SMAX_PS_Work_Order_Assign_Filter__c>());
            result.get(key).add(filter);
        }
        return result;
    }

    private String getValueList(List<SMAX_PS_Work_Order_Assign_Filter__c> filterList, String fieldName)
    {
        String result = null;
        for (SMAX_PS_Work_Order_Assign_Filter__c filter : filterList)
        {
            result = (result == null) ? '' : result + ', ';
            String value = filter.get(fieldName) + '';
            if (!value.startsWith('\''))
                value = '\'' + value  + '\'';
            result = result + value;
        }
        return result;
    }

    public PageReference removeFilter()
    {
        if(this.filterIdxToRemove != null)
        {
            SMAX_PS_Work_Order_Assign_Filter__c f = this.filters.remove(this.filterIdxToRemove);
            if (f.Id != null)
            {
                this.filtersToDelete.add(f);
            }
        }
        return null;
    }

    public void updateschdate()
    {
        this.assignStatus = null;
        System.debug('** TRYING TO ASSIGN WOs...');
        Set<Id> techIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        for (WorkOrderWrapper wow : this.woList)
        {
                woIds.add(wow.wo.Id);
        }



        List<Event> eventList = new List<Event>();
        List<SVMXC__Service_Order__c> woUpdates = new List<SVMXC__Service_Order__c>();
        // List<SVMXC__Service_Order__c> oldWOs = [SELECT id, SVMXC__Scheduled_Date__c, SMAX_PS_Customer_Required_Start_Date__c 
        //                                      FROM SVMXC__Service_Order__c  WHERE id IN :woIds ];

        Map<Id,SVMXC__Service_Order__c> oldWOmap = new Map<Id,SVMXC__Service_Order__c>([SELECT id, SVMXC__Scheduled_Date_Time__c, SMAX_PS_Customer_Required_Start_Date__c,
                                                                                               SVMXC__Work_Order_Scheduling_Status__c,SVMX_PS_Work_Order_Priority_Reason__c  
                                                                                        FROM SVMXC__Service_Order__c  WHERE id IN :woIds]);
        for (WorkOrderWrapper wow : this.woList)
        {
            SVMXC__Service_Order__c wo_old = oldWOmap.get(wow.wo.id);
            if(( wo_old.SVMXC__Scheduled_Date_Time__c!= wow.wo.SVMXC__Scheduled_Date_Time__c ) || 
                (wo_old.SMAX_PS_Customer_Required_Start_Date__c != wow.wo.SMAX_PS_Customer_Required_Start_Date__c) ||
                (wo_old.SVMXC__Work_Order_Scheduling_Status__c != wow.wo.SVMXC__Work_Order_Scheduling_Status__c ) ||
                (wo_old.SVMX_PS_Work_Order_Priority_Reason__c != wow.wo.SVMX_PS_Work_Order_Priority_Reason__c ) ){                  

                woUpdates.add(wow.wo);
                System.debug('Dates Not Matached:'+wo_old.SMAX_PS_Customer_Required_Start_Date__c+'-'+wow.wo.SMAX_PS_Customer_Required_Start_Date__c);

            }
            
        }

        Integer successfulWoUpdateCount = 0;
        if (!woUpdates.isEmpty())
        {
            // ITSFDC-1242 Catch and report failed updates during Mass Update
            List<Database.SaveResult> saveResults = Database.update(woUpdates, false);

            // Go through each result
            String errorMessage;
            String successMessage;
            for (Integer i=0; i<saveResults.size(); i++)
            {
                if (saveResults.get(i).isSuccess())
                {
                    // Successfully updated Work Order
                    successfulWoUpdateCount = successfulWoUpdateCount + 1;
                    successMessage = 'Update succeeded for Work Order with ID ' + saveResults.get(i).getId();
                    System.debug(successMessage);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
                }
                else
                {
                    // Failed
                    Database.Error databaseError = saveResults.get(i).getErrors().get(0);
                    errorMessage = 'Update failed for Work Order with ID ' + woUpdates.get(i).Id + ' : ' + databaseError.getStatusCode() + ' - ' + databaseError.getMessage();
                    System.debug(errorMessage);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errorMessage));
                }
            }
        }

        // if (!eventList.isEmpty())
        // {
        //  insert eventList;
        // }

        this.woList.clear();
        this.woListOld.clear();
        this.techList.clear();

        this.assignStatus = 'Successfully Assigned ' + successfulWoUpdateCount + ' Work Orders.';
    }
    public void updateallschdate()
    {
        this.assignStatus = null;
        System.debug('** TRYING TO ASSIGN WOs...');
        Set<Id> techIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        for (WorkOrderWrapper wow : this.woList)
        {
                woIds.add(wow.wo.Id);
        }



        List<Event> eventList = new List<Event>();
        List<SVMXC__Service_Order__c> woUpdates = new List<SVMXC__Service_Order__c>();
        // List<SVMXC__Service_Order__c> oldWOs = [SELECT id, SVMXC__Scheduled_Date__c, SMAX_PS_Customer_Required_Start_Date__c 
        //                                      FROM SVMXC__Service_Order__c  WHERE id IN :woIds ];

        Map<Id,SVMXC__Service_Order__c> oldWOmap = new Map<Id,SVMXC__Service_Order__c>([SELECT id, SVMXC__Scheduled_Date_Time__c, 
                                                                                        SMAX_PS_Customer_Required_Start_Date__c,
                                                                                        SVMXC__Work_Order_Scheduling_Status__c,
                                                                                        SVMX_PS_Work_Order_Priority_Reason__c 
                                                                                        FROM SVMXC__Service_Order__c  WHERE id IN :woIds]);
        for (WorkOrderWrapper wow : this.woList)
        {
                
            if(InpWO.SMAX_PS_Customer_Required_Start_Date__c != null){
                wow.wo.SMAX_PS_Customer_Required_Start_Date__c = InpWO.SMAX_PS_Customer_Required_Start_Date__c;
            }   
            if(InpWO.SVMXC__Scheduled_Date_Time__c != null){
                wow.wo.SVMXC__Scheduled_Date_Time__c = InpWO.SVMXC__Scheduled_Date_Time__c;
            }
            if(InpWO.SVMXC__Work_Order_Scheduling_Status__c != null){
                wow.wo.SVMXC__Work_Order_Scheduling_Status__c = InpWO.SVMXC__Work_Order_Scheduling_Status__c;
            }
            if(InpWO.SVMX_PS_Work_Order_Priority_Reason__c != null)
            {wow.wo.SVMX_PS_Work_Order_Priority_Reason__c = InpWO.SVMX_PS_Work_Order_Priority_Reason__c;
            }

            if(InpWO.SMAX_PS_Customer_Required_Start_Date__c != null || InpWO.SVMXC__Scheduled_Date_Time__c != null || InpWO.SVMXC__Work_Order_Scheduling_Status__c != null){
                woUpdates.add(wow.wo);
                System.debug('CustomerRequireDate:'+InpWO.SMAX_PS_Customer_Required_Start_Date__c+'- ScheduleDateTime:'+InpWO.SVMXC__Scheduled_Date_Time__c
                +'- Schedulestatus:'+InpWO.SVMXC__Work_Order_Scheduling_Status__c+'- SchedulestatusNotes:'+InpWO.SVMX_PS_Work_Order_Priority_Reason__c);
            }

            
        }

        Integer successfulWoUpdateCount = 0;
        if (!woUpdates.isEmpty())
        {
            // ITSFDC-1242 Catch and report failed updates during Mass Update
            List<Database.SaveResult> saveResults = Database.update(woUpdates, false);

            // Go through each result
            String errorMessage;
            String successMessage;
            for (Integer i=0; i<saveResults.size(); i++)
            {
                if (saveResults.get(i).isSuccess())
                {
                    // Successfully updated Work Order
                    successfulWoUpdateCount = successfulWoUpdateCount + 1;
                    successMessage = 'Update succeeded for Work Order with ID ' + saveResults.get(i).getId();
                    System.debug(successMessage);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
                }
                else
                {
                    // Failed
                    Database.Error databaseError = saveResults.get(i).getErrors().get(0);
                    errorMessage = 'Update failed for Work Order with ID ' + woUpdates.get(i).Id + ' : ' + databaseError.getStatusCode() + ' - ' + databaseError.getMessage();
                    System.debug(errorMessage);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errorMessage));
                }
            }
        }

        // if (!eventList.isEmpty())
        // {
        //  insert eventList;
        // }

        this.woList.clear();
        this.woListOld.clear();
        this.techList.clear();

        this.assignStatus = 'Successfully Assigned ' + successfulWoUpdateCount + ' Work Orders.';
    }   
}
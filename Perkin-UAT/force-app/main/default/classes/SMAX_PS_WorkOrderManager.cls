/**
 *  Apex Class for Work Order [SVMXC__Service_Order__c] Business Logic.
 *  2017-09-21      Veerendra Moodbidri       Initial creation, for Work Order Outbound Integration.
 *  2017-2018       Frank VanLoon             Multiple additions: CopyRelatedData, UpdateMapedValues, SubmitLines, etc.
 *  2018-03-16.     MAPLES                    Added to copyRelatedDate method the mapping for Payer Address so it can be used in creation of Parts order JIRA 392
 *  2021-01-08      Tony                      ITSVMX-225
 *  2020-02-08      b.s.salmans               updateStandardJobTime removed and placed in SMAX_PS_WorkOrderStandardJobTime
 *  2021-11-03      Sarala Lakkireddy         ITSVMX-542 Populate contact mobile number into WO
 *  2021-11-12      Tony                      ITSVMX-607 Auto-entitle RWO, build in reporting capacity on SLA terms in connection to RWO
 *  2022-01-20      Tony                      ITSVMX-699 Don't roll back the Order Status of "Assigned" on Technicians with a Role of Depot Queue
 *  2022-02-15      Tony                      ITSVMX-767 Using Mass Assignment of Service Request to Depot Technician should NOT change the Order Type or the Record Type
 *  2022-01-16      Tony                      ITSVMX-276 (TAC) Need to change owner of escalated repair
 *  2022-03-31      Tony                      ITSVMX-801 Error when attempt to accept WO from queue - Need to add code to update the SMAX_PS_Scheduled_Duration_Hours__c field when the SVMXC__Service_Duration__c is updated
 *  2022-04-05      Tony                      ITSVMX-562 Modify the replenishment parts ordering process in SVMX to automatically change the ordered part from new to refurbished if a refurbished option is available IF the customer/contract allows
 *  2022-12-07      Shankar Nadar             ITSVMX-674 Updated the method updateWorkOrderStatus to capture old Order type to original order type field
 *  2022-10-04      Sarala Lakkireddy         ITSVMX-664 Replace model series field on IP with new custom field with SMAX_PS_ModelSeries_2__c field 
 *                                            Get the model series form product if not available get it from IP.
 *  2022-10-19      Tony                      ITSVMX-1029 Polaris Translation / Output Documents
 *  2023-08-10      Tony                      ITSVMX-1227 Update Work Order Default Consumed From Location from either Technician or Shared Location
 *  2023-09-01      Tony                      ITSVMX-1227 For LSDX it is not necessary for the Plant to be the same on the Work Order and Technician to use the Technician Location
 */

public with sharing class SMAX_PS_WorkOrderManager {

    private SMAX_PS_WorkOrderManager() {
    }

    private static String WORK_COMPLETE = 'Work Complete';

    /**
     * Use the AutoFieldMapping Custom Metadata Type to map fields.
     * Should be called in the "before" trigger(s)
     */
    public static void updateMappedValues(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Update Mapped Values', 'Use the AutoFieldMapping Custom Metadata Type to map fields.'))
            return;

        Profile prof = SMAX_PS_Utility.getCurrentUserProfile();
        if (oldMap == null && prof != null && prof.Name.containsIgnoreCase('Integration'))
        {
            // If created by Integration.. reverse map the values.
            SMAX_PS_Utility.updateMappedValues('SVMXC__Service_Order__c', woList, oldMap, true);
        }
        else
        {
            SMAX_PS_Utility.updateMappedValues('SVMXC__Service_Order__c', woList, oldMap, false);
        }
    }

    public static void syncScheduledDate(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Sched Date', 'Update the WO Scheduled Date from the updated Scheduled Datetime.'))
            return;

        if (oldMap == null) // INSERT
        {
            // SVMXINT-498: IF (INSERT by BOOMI) AND (ScheduledDate is in PAST) THEN change to TODAY
            Profile prof = SMAX_PS_Utility.getCurrentUserProfile();
            Boolean isIntegration = (prof != null && prof.Name.containsIgnoreCase('Integration'));
            if (isIntegration)
            {
                Date today = Date.today();
                for (SVMXC__Service_Order__c wo : woList)
                {
                    if (wo.SVMXC__Scheduled_Date__c != null && wo.SVMXC__Scheduled_Date__c < today)
                    {
                        wo.SVMXC__Scheduled_Date__c = today;
                    }
                }
            }
        }
        else // UPDATE
        {
            for (SVMXC__Service_Order__c wo : woList)
            {
                SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
                if (old != null && wo.SVMXC__Scheduled_Date_Time__c != null && wo.SVMXC__Scheduled_Date_Time__c != old.SVMXC__Scheduled_Date_Time__c)
                {
                    wo.SVMXC__Scheduled_Date__c = wo.SVMXC__Scheduled_Date_Time__c.date();
                }
            }
        }
    }
    public static void copyQuoteCurrencyDate(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {

        Date today = Date.today();
        if (oldMap == null) // INSERT
        {
            for (SVMXC__Service_Order__c wo : woList)
            {
                if(wo.SMAX_PS_Quote_Currency__c == null){
                    // wo.SMAX_PS_Quote_Accepted_Date__c = today;
                    wo.SMAX_PS_Quote_Currency__c = wo.CurrencyIsoCode;
                }else{
                    // wo.SMAX_PS_Quote_Accepted_Date__c = today;
                    wo.SMAX_PS_Quote_Currency__c = wo.SMAX_PS_Quote_Currency__c;
                }
            }

        }
        else // UPDATE
        {
            for (SVMXC__Service_Order__c wo : woList)
            {
                SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
                if (old != null && old.SMAX_PS_Quote_Currency__c == null && wo.SMAX_PS_Quote_Currency__c == null)
                {
                    if(wo.SMAX_PS_Quote_Currency__c == null){
                        // wo.SMAX_PS_Quote_Accepted_Date__c = today;
                        wo.SMAX_PS_Quote_Currency__c = wo.CurrencyIsoCode;
                    }else{
                        // wo.SMAX_PS_Quote_Accepted_Date__c = today;
                        wo.SMAX_PS_Quote_Currency__c = wo.SMAX_PS_Quote_Currency__c;
                    }

                    
                }
            }
        }
    }
    /**
     * Copy Related Lookups and fields when Work Orders are Created.
     * Should be called in the "before" trigger(s)
     * ADDED support for BEFORE UPDATE.. when the IP Lookup changes for SVMXCFG-682
     */
    public static void copyRelatedData(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Copy Related Data', 'Copy Related Lookups and fields when Work Orders are Created.'))
            return;

        // SVMXINT-536 WO Load: Do not recalculate Customer Master lookups
        Boolean isIntegration = SMAX_PS_Utility.isCurrentUserIntegrationProfile();

        // First pass.. IPs and Contacts
        Set<Id> ipIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();

        // ITSVMX-539 Also, get the OwnerId before it is changed for use later
        Set<Id> createdByIds = new Set<Id>();

        for (SVMXC__Service_Order__c wo : woNewList)
        {
            createdByIds.add(wo.OwnerId); // ITSVMX-539

            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            // ITSVMX-606: Changing Scheduled Duration field - Hopefully this won't be needed any longer
            // 7/22/21 Tony - Refactoring this from SMAX_PS_AutoAssignment.confirmScheduling() into SMAX_PS_WorkOrderManager.copyRelatedData()
            // as it is causing problems with ServiceMax managed package code
            // ITSVMX-801 Need to re-add this code to update the new SMAX_PS_Scheduled_Duration_Hours__c field when SVMXC__Service_Duration__c is updated
            if (old != null && wo.SVMXC__Service_Duration__c != old.SVMXC__Service_Duration__c
                    && wo.SVMXC__SM_Scheduling_Options__c == 'JDM and LJS Enabled')
            {
                Long seconds = wo.SVMXC__Service_Duration__c.longValue();
                Long minutes = seconds / 60;
                Decimal hours = (minutes / 60.00).setScale(2);
//              wo.SVMXC__SM_Scheduled_Duration__c = hours;
                wo.SMAX_PS_Scheduled_Duration_Hours__c = hours;
            }

            if (old == null || old.SVMXC__Component__c != wo.SVMXC__Component__c)
            {

                if (old != null)
                {
                    // SVMXCFG-682 Wipe out fields to make sure they get replaced from IP / Location..
                    wo.SVMXC__Site__c = null;
                    wo.SVMXC__Company__c = null;
                    wo.SMAX_PS_ShipTo__c = null;
                    wo.SMAX_PS_BillTo__c = null;
                    wo.SMAX_PS_Payer__c = null;
                    wo.SMAX_PS_Local_Language_Bill_To_Account__c = null;
                    wo.SMAX_PS_Local_Language_Ship_To_Account__c = null;
                }

                // SVMXINT-561 WO Basic Start Date - default to same vlaue
                if (wo.SVMXC__Scheduled_Date__c == null)
                    wo.SVMXC__Scheduled_Date__c = wo.SMAX_PS_Customer_Required_Start_Date__c;
                if (wo.SVMXC__Scheduled_Date__c == null)
                    wo.SVMXC__Scheduled_Date__c = Date.today();
                if (wo.SVMXC__Component__c != null)
                    ipIds.add(wo.SVMXC__Component__c);
                if (wo.SVMXC__Contact__c != null)
                    contactIds.add(wo.SVMXC__Contact__c);
                if (wo.SVMXC__Company__c != null && isIntegration)
                    acctIds.add(wo.SVMXC__Company__c);

                // SVMXINT-638 WO Local Language Cust Numbers
                if (wo.SMAX_PS_Local_Language_Bill_To_Account__c != null && isIntegration)
                    acctIds.add(wo.SMAX_PS_Local_Language_Bill_To_Account__c);
                if (wo.SMAX_PS_Local_Language_Ship_To_Account__c != null && isIntegration)
                    acctIds.add(wo.SMAX_PS_Local_Language_Ship_To_Account__c);

                // SVMXCFG-1057 Country without IP nor Location
                if (wo.SVMXC__Component__c == null && wo.SVMXC__Site__c == null && wo.SVMXC__Company__c != null)
                    acctIds.add(wo.SVMXC__Company__c);
            }
        }
        System.debug('createdByIds: ' + createdByIds);

        if (ipIds.isEmpty() && contactIds.isEmpty() && acctIds.isEmpty())
            return;

        Map<Id, SVMXC__Installed_Product__c> ipMap = null;
        if (!ipIds.isEmpty())
        {
            // SVMXCFG-794 Copy Payer E-Invoice Fields to WO
            // ITSVMX-218 Copy the IP Geo-Codes to the WO
            // ITSVMX-290 - Added additional selection from Installed Product Classification for populating certain charactaristics on WO
            //ITSVMX-664 - Added new field SMAX_PS_ModelSeries_2__c in select statement
            ipMap = new Map<Id, SVMXC__Installed_Product__c>([SELECT Id, Name, SMAX_PS_ModelSeries__c, SMAX_PS_ModelSeries_2__c,SVMXC__Site__c,
                    SVMXC__Preferred_Technician__c, SMAX_PS_CatalogProfile__c, SMAX_PS_ModelNumber__c, SMAX_PS_IsMedicalDevice__c,
                    SMAX_PS_Technical_ID_Number__c, SMAX_PS_ThirdPartyVendorName__c, SMAX_PS_Field_Notes__c,
                    SVMXC__Longitude__c, SVMXC__Latitude__c,
                    SVMXC__Product__c, SVMXC__Product__r.SMAX_PS_Super_Business_Unit__c, SVMXC__Product__r.SVMXC__Product_Line__c,
                    SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
                    SMAX_PS_SoldTo_Account__r.ShippingStreet, SMAX_PS_SoldTo_Account__r.ShippingCity, SMAX_PS_SoldTo_Account__r.ShippingState,
                    SMAX_PS_SoldTo_Account__r.ShippingPostalCode, SMAX_PS_SoldTo_Account__r.ShippingCountry,
                    SMAX_PS_System_ID__c, SVMXC__Asset_Tag__c, SMAX_PS_Equipment_ID__c,
                    SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Platform_Id__c, SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Customer_Id__c,
                    SMAX_PS_LL_BillTo_Account__c, SMAX_PS_LL_BillTo_Account__r.Name,
                    SMAX_PS_LL_BillTo_Account__r.ShippingStreet, SMAX_PS_LL_BillTo_Account__r.ShippingCity, SMAX_PS_LL_BillTo_Account__r.ShippingState,
                    SMAX_PS_LL_BillTo_Account__r.ShippingPostalCode, SMAX_PS_LL_BillTo_Account__r.ShippingCountry,
                    SMAX_PS_LL_ShipTo_Account__c, SMAX_PS_LL_ShipTo_Account__r.Name,
                    SMAX_PS_LL_ShipTo_Account__r.ShippingStreet, SMAX_PS_LL_ShipTo_Account__r.ShippingCity, SMAX_PS_LL_ShipTo_Account__r.ShippingState,
                    SMAX_PS_LL_ShipTo_Account__r.ShippingPostalCode, SMAX_PS_LL_ShipTo_Account__r.ShippingCountry,
            ( SELECT Id, Name, SMAX_PS_InstalledProduct__c, SMAX_PS_Characteristic__c,
                    SMAX_PS_Description__c, SMAX_PS_Value__c FROM Installed_Product_Classifications__r
            WHERE SMAX_PS_Characteristic__c = 'EQUIPMENT_CONTRACT_BASE_DATE' OR
            SMAX_PS_Characteristic__c = 'EQUIPMENT_SCHEDULING_RULE')
            FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds]);
        }

        Map<Id, Contact> contactMap = null;
        if (!contactIds.isEmpty())
        {
            contactMap = new Map<Id, Contact>([SELECT Id, Name, Phone, Email, MobilePhone
            FROM Contact WHERE Id IN :contactIds]);
        }

        Map<Id, Account> acctMap = new Map<Id, Account>();
        if (!acctIds.isEmpty())
        {
            acctMap = new Map<Id, Account>([SELECT Id, Name,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
            FROM Account WHERE Id IN :acctIds]);
        }

        // Load the Custom Setting for converting "Catalog Profile" to "Code Family"
        Map<String, String> profileFamilyMap = new Map<String, String>();
        for (SMAX_PS_Catalog_Profile__c catProf : SMAX_PS_Catalog_Profile__c.getall().values())
        {
            profileFamilyMap.put(catProf.SMAX_PS_Catalog_Profile__c, catProf.SMAX_PS_Code_Family__c);
        }

        // OBSOLETE Equipment Products for RMA/Loaner..
        Map<Id, Id> woProdMap = new Map<Id, Id>();

        // SVMXINT-516 : Use IP Customer Master Lookups first - SoldTo will be filled in SFM .. can't use basic null logic
        Map<Id, Account> woSoldToMap = new Map<Id, Account>();
        for (SVMXC__Service_Order__c wo : woNewList)
        {
            if (wo.SVMXC__Component__c != null)
            {
                SVMXC__Installed_Product__c ip = (ipMap == null) ? null : ipMap.get(wo.SVMXC__Component__c);
                if (ip != null)
                {
                    // begin of ITSVMX-290 populate the classification data
                    List<SMAX_PS_InstalledProductClassification__c> ipClassificationList = ip.Installed_Product_Classifications__r;
                    for(SMAX_PS_InstalledProductClassification__c ipClassObj:ipClassificationList){
                        system.debug('IP Classification Details:'+ipClassObj);
                        if(ipClassObj.SMAX_PS_Characteristic__c == 'EQUIPMENT_CONTRACT_BASE_DATE'){
                            wo.SMAX_PS_Previous_Requested_Date__c = ipClassObj.SMAX_PS_Value__c;
                        }
                        if(ipClassObj.SMAX_PS_Characteristic__c == 'EQUIPMENT_SCHEDULING_RULE'){
                            wo.SMAX_PS_Scheduling_Date_Rule__c =  ipClassObj.SMAX_PS_Value__c;
                        }

                    }
                    // end of ITSVMX-290 populate the classification data

                    wo.SVMXC__Preferred_Technician__c = ip.SVMXC__Preferred_Technician__c;
                    // ITSVMX-664 Replace with new model series field
                    wo.SMAX_PS_ModelSeries__c = ip.SMAX_PS_ModelSeries_2__c; 
                    wo.SMAX_PS_Model_Number__c = ip.SMAX_PS_ModelNumber__c;
                    wo.SMAX_PS_IsMedicalDevice__c = ip.SMAX_PS_IsMedicalDevice__c;
                    wo.SMAX_PS_Technical_ID_Number__c = ip.SMAX_PS_Technical_ID_Number__c;
                    wo.SMAX_PS_Vendor__c = ip.SMAX_PS_ThirdPartyVendorName__c;

                    //SVMXCFG-687 - Add Installed Product System ID to WO
                    wo.SMAX_PS_System_ID__c = ip.SMAX_PS_System_ID__c;
                    // SVMXCFG-763 - System ID, Equipment ID from IP
                    wo.SMAX_PS_Asset_ID__c = ip.SVMXC__Asset_Tag__c;
                    wo.SMAX_PS_Equipment_ID__c = ip.SMAX_PS_Equipment_ID__c;

                    // ITSVMX-218 Copy the IP Geo-Codes to the WO
                    wo.SVMXC__Longitude__c = ip.SVMXC__Longitude__c;
                    wo.SVMXC__Latitude__c = ip.SVMXC__Latitude__c;

                    // Copy Location from IP if blank on WO
                    if (wo.SVMXC__Site__c == null)
                    {
                        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
                    }
                    // JIRA #395 - Fault Code Debrief
                    if (ip.SMAX_PS_CatalogProfile__c != null)
                    {
                        wo.SMAX_PS_Fault_Code_Family__c = profileFamilyMap.get(ip.SMAX_PS_CatalogProfile__c);
                    }
                    // JIRA SVMXCFG-357 - Copy Super Business Unit from IP's Product
                    if (ip.SVMXC__Product__c != null)
                    {
                        wo.SMAX_PS_Super_Business_Unit__c = ip.SVMXC__Product__r.SMAX_PS_Super_Business_Unit__c;
                        // SVMXCFG-1137 Copy the IP Product Line to the Work Order
                        wo.SMAX_PS_IP_Product_Line__c = ip.SVMXC__Product__r.SVMXC__Product_Line__c;
                        // OBSOLETE Equipment Products for RMA/Loaner..
                        woProdMap.put(wo.Id, ip.SVMXC__Product__c);
                    }
                    // SVMXCFG-610 - Notes fields from IP/Location
                    wo.SMAX_PS_Field_Notes__c = ip.SMAX_PS_Field_Notes__c;

                    if (!isIntegration)
                    {
                        // SVMXINT-516 : Use IP Customer Master Lookups first
                        if (ip.SMAX_PS_SoldTo_Account__c != null)
                        {
                            woSoldToMap.put(wo.Id, ip.SMAX_PS_SoldTo_Account__r);
                            wo.SVMXC__Company__c = ip.SMAX_PS_SoldTo_Account__c;
                        }
                        if (ip.SMAX_PS_ShipTo_Account__c != null)
                        {
                            wo.SMAX_PS_ShipTo__c = ip.SMAX_PS_ShipTo_Account__c;
                        }
                        if (ip.SMAX_PS_BillTo_Account__c != null)
                        {
                            wo.SMAX_PS_BillTo__c = ip.SMAX_PS_BillTo_Account__c;
                        }
                        if (ip.SMAX_PS_Payer_Account__c != null)
                        {
                            wo.SMAX_PS_Payer__c = ip.SMAX_PS_Payer_Account__c;
                            // SVMXCFG-794 Copy Payer E-Invoice Fields to WO
                            wo.SMAX_PS_EInvoice_Platform_Id__c = ip.SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Platform_Id__c;
                            wo.SMAX_PS_EInvoice_Customer_Id__c = ip.SMAX_PS_Payer_Account__r.PKI_SAP_EInvoice_Customer_Id__c;
                        }
                        // SVMXCFG-903 Copy Local Language Accounts to WO
                        if (ip.SMAX_PS_LL_BillTo_Account__c != null)
                        {
                            wo.SMAX_PS_Local_Language_Bill_To_Account__c = ip.SMAX_PS_LL_BillTo_Account__c;
                            wo.SMAX_PS_LocalLanguageBillTo__c = ip.SMAX_PS_LL_BillTo_Account__r.Name;
                            // SVMXCFG-993 Copy Local Lang address too
                            wo.SMAX_PS_Local_Language_Bill_To_Street__c = ip.SMAX_PS_LL_BillTo_Account__r.ShippingStreet;
                            wo.SMAX_PS_Local_Lang_Bill_To_Addr_Long__c = ip.SMAX_PS_LL_BillTo_Account__r.ShippingCity
                                    + ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingState
                                    + ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingPostalCode
                                    + ' ' + ip.SMAX_PS_LL_BillTo_Account__r.ShippingCountry;
                        }
                        if (ip.SMAX_PS_LL_ShipTo_Account__c != null)
                        {
                            wo.SMAX_PS_Local_Language_Ship_To_Account__c = ip.SMAX_PS_LL_ShipTo_Account__c;
                            wo.SMAX_PS_LocalLanguageShipTo__c = ip.SMAX_PS_LL_ShipTo_Account__r.Name;
                            // SVMXCFG-993 Copy Local Lang address too
                            wo.SMAX_PS_Local_Language_Ship_To_Street__c = ip.SMAX_PS_LL_ShipTo_Account__r.ShippingStreet;
                            wo.SMAX_PS_Local_Lang_Ship_To_Addr_Long__c = ip.SMAX_PS_LL_ShipTo_Account__r.ShippingCity
                                    + ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingState
                                    + ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingPostalCode
                                    + ' ' + ip.SMAX_PS_LL_ShipTo_Account__r.ShippingCountry;
                        }
                    }
                }
            }
            if (wo.SVMXC__Contact__c != null)
            {
                Contact c = (contactMap == null) ? null : contactMap.get(wo.SVMXC__Contact__c);
                if (c != null)
                {
                    wo.SVMX_PS_Contact_Email__c = c.Email;
                    wo.SMAX_PS_ContactName__c = c.Name;
                    wo.SVMX_PS_Contact_Phone__c = c.Phone;
                    // ITSVMX-542 Populate contact mobile number
                    wo.SVMX_PS_Mobile_Number__c = c.MobilePhone;
                }
            }

            // SVMXINT-638 WO Local Language Cust Numbers
            if (wo.SMAX_PS_Local_Language_Bill_To_Account__c != null && isIntegration)
            {
                Account acct = acctMap.get(wo.SMAX_PS_Local_Language_Bill_To_Account__c);
                if (acct != null)
                {
                    wo.SMAX_PS_LocalLanguageBillTo__c = acct.Name;
                    // SVMXCFG-993 Copy Local Lang address too
                    wo.SMAX_PS_Local_Language_Bill_To_Street__c = acct.ShippingStreet;
                    wo.SMAX_PS_Local_Lang_Bill_To_Addr_Long__c = acct.ShippingCity
                            + ' ' + acct.ShippingState
                            + ' ' + acct.ShippingPostalCode
                            + ' ' + acct.ShippingCountry;

                }
            }
            if (wo.SMAX_PS_Local_Language_Ship_To_Account__c != null && isIntegration)
            {
                Account acct = acctMap.get(wo.SMAX_PS_Local_Language_Ship_To_Account__c);
                if (acct != null)
                {
                    wo.SMAX_PS_LocalLanguageShipTo__c = acct.Name;
                    // SVMXCFG-993 Copy Local Lang address too
                    wo.SMAX_PS_Local_Language_Ship_To_Street__c = acct.ShippingStreet;
                    wo.SMAX_PS_Local_Lang_Ship_To_Addr_Long__c = acct.ShippingCity
                            + ' ' + acct.ShippingState
                            + ' ' + acct.ShippingPostalCode
                            + ' ' + acct.ShippingCountry;
                }
            }

            // SVMXCFG-1057 Country without IP nor Location
            if (wo.SVMXC__Component__c == null && wo.SVMXC__Site__c == null && wo.SVMXC__Company__c != null)
            {
                Account acct = acctMap.get(wo.SVMXC__Company__c);
                System.debug('Is Here>');
                if (acct != null)
                {
                    wo.SVMXC__Country__c = acct.ShippingCountry;
                    wo.SMAX_PS_Account_Street__c = acct.ShippingStreet;
                    wo.SMAX_PS_Account_City__c = acct.ShippingCity;
                    wo.SMAX_PS_Account_State__c = acct.ShippingState;
                    wo.SMAX_PS_Account_Zip_Code__c = acct.ShippingPostalCode;
                    wo.SMAX_PS_Account_Country__c = acct.ShippingCountry;
                }
            }
        }

        // Second pass.. Locations (might have been filled in during first pass)
        Set<Id> locIds = new Set<Id>();
        for (SVMXC__Service_Order__c wo : woNewList)
        {
            if (wo.SVMXC__Site__c != null)
                locIds.add(wo.SVMXC__Site__c);
        }

        Map<Id, SVMXC__Site__c> locMap = null;
        if (!locIds.isEmpty())
        {
            // 2018-03-16 MAPLES - Added the new fields for Payer address so we can map to WO and then use in creation of Parts Order
            // SVMXCFG-794 Copy Payer E-Invoice Fields to WO
            locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name, SMAX_PS_LocationCode__c, SMAX_PS_Geography__r.Name,
                    SVMXC__Account__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c, SMAX_PS_MaintenancePlant__c,
                    SMAX_PS_SalesOrg__c, CurrencyIsoCode, SVMX_PS_Location_Notes__c,
                    SVMXC__Account__r.ShippingStreet, SVMXC__Account__r.ShippingCity, SVMXC__Account__r.ShippingState,
                    SVMXC__Account__r.ShippingPostalCode, SVMXC__Account__r.ShippingCountry,
                    SVMXC__Street__c, SVMXC__City__c, SVMXC__State__c, SVMXC__Country__c, SVMXC__Zip__c,
                    SMAX_PS_Payer__r.PKI_SAP_EInvoice_Platform_Id__c, SMAX_PS_Payer__r.PKI_SAP_EInvoice_Customer_Id__c,
                    SMAX_PS_LL_BillTo__c, SMAX_PS_LL_BillTo__r.Name,
                    SMAX_PS_LL_BillTo__r.ShippingStreet, SMAX_PS_LL_BillTo__r.ShippingCity, SMAX_PS_LL_BillTo__r.ShippingState,
                    SMAX_PS_LL_BillTo__r.ShippingPostalCode, SMAX_PS_LL_BillTo__r.ShippingCountry,
                    SMAX_PS_LL_ShipTo__c, SMAX_PS_LL_ShipTo__r.Name,
                    SMAX_PS_LL_ShipTo__r.ShippingStreet, SMAX_PS_LL_ShipTo__r.ShippingCity, SMAX_PS_LL_ShipTo__r.ShippingState,
                    SMAX_PS_LL_ShipTo__r.ShippingPostalCode, SMAX_PS_LL_ShipTo__r.ShippingCountry
            FROM SVMXC__Site__c WHERE Id IN :locIds]);
        }

        // OBSOLETE Equipment Products for RMA/Loaner..
        Map<Id, String> woPlantMap = new Map<Id, String>();
        // ITSVMX-253 Sales Orgs for each WO
        Map<Id, String> woSalesMap = new Map<Id, String>();

        // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
        Map<String,List<String>> dependentPicklistValuesMap = SMAX_PS_Utility.getDependentPicklistValues(SVMXC__Service_Order__c.BD_Global_From_State__c);
        System.debug('dependentPicklistValuesMap: ' + dependentPicklistValuesMap);

        Set<String> locExtIds = new Set<String>();
        for (SVMXC__Service_Order__c wo : woNewList)
        {
            if (wo.SVMXC__Site__c != null)
            {
                SVMXC__Site__c loc = (locMap == null) ? null : locMap.get(wo.SVMXC__Site__c);
                if (loc != null)
                {
                    if (!isIntegration)
                    {
                        // SVMXINT-516 : Use IP Customer Master Lookups first
                        if (!woSoldToMap.containsKey(wo.Id))
                        {
                            woSoldToMap.put(wo.Id, loc.SVMXC__Account__r);
                            wo.SVMXC__Company__c = loc.SVMXC__Account__c;
                        }
                        if (wo.SMAX_PS_BillTo__c == null)
                        {
                            wo.SMAX_PS_BillTo__c = loc.SMAX_PS_BillTo__c;
                        }
                        if (wo.SMAX_PS_Payer__c == null)
                        {
                            wo.SMAX_PS_Payer__c = loc.SMAX_PS_Payer__c;
                            // SVMXCFG-794 Copy Payer E-Invoice Fields to WO
                            wo.SMAX_PS_EInvoice_Platform_Id__c = loc.SMAX_PS_Payer__r.PKI_SAP_EInvoice_Platform_Id__c;
                            wo.SMAX_PS_EInvoice_Customer_Id__c = loc.SMAX_PS_Payer__r.PKI_SAP_EInvoice_Customer_Id__c;
                        }
                        if (wo.SMAX_PS_ShipTo__c == null)
                        {
                            wo.SMAX_PS_ShipTo__c = loc.SMAX_PS_ShipTo__c;
                        }
                        // SVMXCFG-903 Copy Local Language Accounts to WO
                        if (wo.SMAX_PS_Local_Language_Bill_To_Account__c == null && loc.SMAX_PS_LL_BillTo__c != null)
                        {
                            wo.SMAX_PS_Local_Language_Bill_To_Account__c = loc.SMAX_PS_LL_BillTo__c;
                            wo.SMAX_PS_LocalLanguageBillTo__c = loc.SMAX_PS_LL_BillTo__r.Name;
                            // SVMXCFG-993 Copy Local Lang address too
                            wo.SMAX_PS_Local_Language_Bill_To_Street__c = loc.SMAX_PS_LL_BillTo__r.ShippingStreet;
                            wo.SMAX_PS_Local_Lang_Bill_To_Addr_Long__c = loc.SMAX_PS_LL_BillTo__r.ShippingCity
                                    + ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingState
                                    + ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingPostalCode
                                    + ' ' + loc.SMAX_PS_LL_BillTo__r.ShippingCountry;
                        }
                        if (wo.SMAX_PS_Local_Language_Ship_To_Account__c == null && loc.SMAX_PS_LL_ShipTo__c != null)
                        {
                            wo.SMAX_PS_Local_Language_Ship_To_Account__c = loc.SMAX_PS_LL_ShipTo__c;
                            wo.SMAX_PS_LocalLanguageShipTo__c = loc.SMAX_PS_LL_ShipTo__r.Name;
                            // SVMXCFG-993 Copy Local Lang address too
                            wo.SMAX_PS_Local_Language_Ship_To_Street__c = loc.SMAX_PS_LL_ShipTo__r.ShippingStreet;
                            wo.SMAX_PS_Local_Lang_Ship_To_Addr_Long__c = loc.SMAX_PS_LL_ShipTo__r.ShippingCity
                                    + ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingState
                                    + ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingPostalCode
                                    + ' ' + loc.SMAX_PS_LL_ShipTo__r.ShippingCountry;
                        }
                    }

                    // 2018-03-16 MAPLES - added Address mapping for use on create of Parts Order **JIRA 392
                    // 2018-05-09 Frank - Refactored for SVMXINT-516 and SVMXINT-536
                    Account soldToAccount = (isIntegration) ? acctMap.get(wo.SVMXC__Company__c) : woSoldToMap.get(wo.Id);
                    System.debug('Is Here>>');
                    if (soldToAccount != null)
                    {
                        System.debug('Is Here>>>');
                        wo.SMAX_PS_Account_Street__c = soldToAccount.ShippingStreet;
                        wo.SMAX_PS_Account_City__c = soldToAccount.ShippingCity;
                        wo.SMAX_PS_Account_State__c = soldToAccount.ShippingState;
                        wo.SMAX_PS_Account_Zip_Code__c = soldToAccount.ShippingPostalCode;
                        wo.SMAX_PS_Account_Country__c = soldToAccount.ShippingCountry;
                    }

                    // SVMXCFG-329 - Copy Currency from Payer
                    //if (loc.SMAX_PS_Payer__c != null) { wo.CurrencyIsoCode = loc.SMAX_PS_Payer__r.CurrencyIsoCode; }
                    // SVMXINT-475 - Copy the Currency Code from the Functional Location instead
                    wo.CurrencyIsoCode = loc.CurrencyIsoCode;
                    wo.SMAX_PS_LocationCode__c = loc.SMAX_PS_LocationCode__c;
                    wo.SMAX_PS_Geography__c = (loc.SMAX_PS_Geography__r != null) ? loc.SMAX_PS_Geography__r.Name : null;
                    wo.SMAX_PS_SalesOrg__c = loc.SMAX_PS_SalesOrg__c;
                    woSalesMap.put(wo.Id, wo.SMAX_PS_SalesOrg__c);

                    // SVMXCFG-483 - Blank "Service Location" on WO
                    if (String.isBlank(wo.SVMXC__Street__c))
                    {
                        wo.SVMXC__Street__c = loc.SVMXC__Street__c;
                        wo.SVMXC__City__c = loc.SVMXC__City__c;
                        wo.SVMXC__State__c = loc.SVMXC__State__c;
                        wo.SVMXC__Zip__c = loc.SVMXC__Zip__c;
                    }
                    wo.SVMXC__Country__c = loc.SVMXC__Country__c;
                    if (loc.SMAX_PS_MaintenancePlant__c != null)
                    {
                        wo.SMAX_PS_ExpenseLocationNumber__c = loc.SMAX_PS_MaintenancePlant__c + 'F000';
                        locExtIds.add(wo.SMAX_PS_ExpenseLocationNumber__c);
                        woPlantMap.put(wo.Id, loc.SMAX_PS_MaintenancePlant__c);
                    }
                    // SVMXCFG-610 - Notes fields from IP/Location
                    wo.SMAX_PS_Location_Notes__c = loc.SVMX_PS_Location_Notes__c;
                }
            }

            // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
            // If there is an error trying to set the BD_Global_From_Country__c OR BD_Global_From_State__c ignore it and continue the loop
            try {
                // ITSVMX-580 9/2/21 Tony - changed to look up "From Country Code" using Schema instead of the keyset from SMAX_PS_Utility.getDependentPicklistValues
                // Get the Country Code picklist values
                List<String> countryCodePickListValues = new List<String>();
                Schema.DescribeFieldResult fieldResult = SVMXC__Service_Order__c.BD_Global_From_Country__c.getDescribe();
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

                for( Schema.PicklistEntry pickListVal : picklistEntries){
                    countryCodePickListValues.add(pickListVal.getLabel());
                }
                System.debug('countryCodePickListValues: ' + countryCodePickListValues);

                // Set the From Country Code:
                System.debug('Checking for a Country Match');
                String tempCountry = '';

                // 6/18/21 Tony - Changed this to only populate the the BD_Global_From_Country__c if it does not have a value
                if (wo.BD_Global_From_Country__c == null || wo.BD_Global_From_Country__c == '') {
                    for (String country :countryCodePickListValues) {
                        // System.debug('country: ' + country);
                        if (country.startsWith(wo.SVMXC__Country__c + '-')) {
                            // Woo hoo! Found a match...
                            System.debug('Found a match for Country: ' + wo.SVMXC__Country__c + ' = ' + country);
                            wo.BD_Global_From_Country__c = country;
                            tempCountry = country;
                            break;
                        }
                    }
                }

                // Set the From State Code
                // 6/18/21 Tony - Changed this to only populate the the BD_Global_From_State__c if it does not have a value
                if (wo.BD_Global_From_State__c == null || wo.BD_Global_From_State__c == '') {
                    System.debug('Checking for a State Match for tempCountry: ' + tempCountry);
                    // Added Null protection
                    List<String> states = dependentPicklistValuesMap.get(tempCountry);
                    if (states != null) {
                        System.debug('states list is not null');
                        for (String state :states) {
                            if (state.startsWith(wo.SVMXC__State__c)) {
                                // Woo hoo! Found a match...
                                System.debug('Found a match for State: ' + wo.SVMXC__State__c + ' = ' + state);
                                wo.BD_Global_From_State__c = state;
                                break;
                            }
                        }
                    }
                }

                // 8/25/21 Tony - ITSVMX-580 - Display an error message when creating a Depot Repair Work Order that doesn't match on a Country Code
                if (    wo.BD_Escalate_to_Depot__c == true
                        && (wo.BD_Global_From_State__c == null || wo.BD_Global_From_State__c == '')
                        && (wo.BD_Global_From_Country__c == null || wo.BD_Global_From_Country__c == '')) {

                    System.debug('ERROR: System could not auto-populate From State Code [' + wo.SVMXC__State__c + '] and From Country Code [' + wo.SVMXC__Country__c + '].');
                    wo.addError('ERROR: System could not auto-populate From State Code [' + wo.SVMXC__State__c + '] and From Country Code [' + wo.SVMXC__Country__c + '].' + ' Please select below.');
                }

            } catch(Exception e) {
                if (wo.BD_Escalate_to_Depot__c == true) {
                    wo.addError('ERROR: System could not auto-populate From State Code [' + wo.SVMXC__State__c + '] and From Country Code [' + wo.SVMXC__Country__c + '].' + ' Please select below.');
                }

                System.debug('Exception was ignored when trying to set the BD_Global_From_Country__c and BD_Global_From_State__c: ' + e.getMessage());
            }
        }

        // TODO: Merge the following into the SMAX_PS_AutoAssignment.autoAssignServiceEstimates() method
        // ITSVMX-539 Auto assignment of estimates for profiles: CRC profile, Technical Support & Hybrid
        System.debug('ITSVMX-539 Auto assignment of estimates for profiles: CRC profile, Technical Support & Hybrid');
        Map<Id, SVMXC__Service_Group_Members__c> technicianMap = new Map<Id, SVMXC__Service_Group_Members__c>([
                SELECT Id, SVMXC__Salesforce_User__c, SMAX_PS_Work_Center__c, SVMXC__Service_Group__c
                FROM SVMXC__Service_Group_Members__c
                WHERE SVMXC__Salesforce_User__c IN :createdByIds
                ORDER BY CreatedDate DESC
        ]);
        System.debug('technicianMap: ' + technicianMap);

        // Get a Map of the User Id to the newest Technician record associated to it
        Map<Id, SVMXC__Service_Group_Members__c> userIdToTechnicianMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c tech :technicianMap.values())
        {
            userIdToTechnicianMap.put(tech.SVMXC__Salesforce_User__c, tech);
        }
        System.debug('userIdToTechnicianMap: ' + userIdToTechnicianMap);

        // Query creating user profiles and map them to user Id
        Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, ProfileId
                FROM User
                WHERE Id IN :createdByIds
        ]);
        System.debug('userMap: ' + userMap);

        // If the Record Type = 'Service Request'(Estimate) and their is a Work Center associated to the Technician of the Creating User,
        // then auto-assign the technician to the WO for these Profiles: CRC profile, Technician Support, Hybrid
        RecordType estimateRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');

        List<String> profileNames = new List<String>{'SVMX PS - Customer Care', 'SVMX - CRC TS FS Hybrid', 'SVMX PS - Technical Support', 'SVMX PS - Tech Support/FSE Profile'};
        System.debug('profileNames: ' + profileNames);
        Map<Id, Profile> profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name IN :profileNames]);
        System.debug('profileMap: ' + profileMap);

        List<Event> events = new List<Event>();
        for (SVMXC__Service_Order__c wo : woNewList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            // Also, only do this assignment on a new record created
            SVMXC__Service_Group_Members__c tech = userIdToTechnicianMap.get(wo.OwnerId);
            System.debug('tech: ' + tech);
            String techWorkCenter = tech?.SMAX_PS_Work_Center__c;
            System.debug('techWorkCenter: ' + techWorkCenter);
            Id profileId = userMap.get(wo.OwnerId)?.ProfileId;
            System.debug('profileId: ' + profileId);

            if (old == null  && wo.RecordTypeId == estimateRT.Id && techWorkCenter != null && profileMap.get(profileId) != null )
            {
                System.debug('Attempting to assigning Technician. See Auto Assignment Notes for details.');
                Event evt = SMAX_PS_AutoAssignment.assignTechnician(wo, tech, wo.SVMXC__Scheduled_Date__c, null);
                if (evt != null)
                {
                    events.add(evt);
                    wo.SMAX_PS_AutoAssignmentNotes__c += ' Assigned to Creators Technician with Work Center.';
                }
            }
        }

        if (!events.isEmpty())
        {
            insert events;
            System.debug('events inserted: ' + events);
        }

        // Third pass.. Expense Locations
        // JIRA #383 - Expense Debrief Tab
        // SVMXCFG-903 Disabling the Expense Storage Location code
//      if (!locExtIds.isEmpty())
//      {
//          // Fill in Lookup: SMAX_PS_ExpenseStorageLocation__c
//          Map<String, SVMXC__Site__c> expLocMap = new Map<String, SVMXC__Site__c>();
//          for (SVMXC__Site__c loc : [SELECT Id, Name, SVMX_PS_External_ID__c FROM SVMXC__Site__c WHERE SVMX_PS_External_ID__c IN :locExtIds])
//          {
//              expLocMap.put(loc.SVMX_PS_External_ID__c, loc);
//          }
//
//          for (SVMXC__Service_Order__c wo : woNewList)
//          {
//              if (wo.SMAX_PS_ExpenseLocationNumber__c != null && wo.SMAX_PS_ExpenseStorageLocation__c == null)
//              {
//                  SVMXC__Site__c loc = expLocMap.get(wo.SMAX_PS_ExpenseLocationNumber__c);
//                  if (loc != null)
//                      wo.SMAX_PS_ExpenseStorageLocation__c = loc.Id;
//              }
//          }
//      }

        // OBSOLETE Equipment Products for RMA/Loaner..
        Set<String> plants = new Set<String>(woPlantMap.values());
        Set<Id> prodIds = new Set<Id>(woProdMap.values());

        if (!plants.isEmpty() && !prodIds.isEmpty())
        {
            List<SMAX_PS_ProductPlant__c> allProductPlants = [SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_Plant__c,
                    BD_Return_Part__c, BD_Return_Part_Number__c, BD_Credit_Relevant_Part__c,
                    SMAX_PS_Product__r.Partnum__c
            FROM SMAX_PS_ProductPlant__c WHERE SMAX_PS_Product__c IN :prodIds AND SMAX_PS_Plant__c IN :plants];
            Map<String, SMAX_PS_ProductPlant__c> ppMap = new Map<String, SMAX_PS_ProductPlant__c>();
            for (SMAX_PS_ProductPlant__c pp : allProductPlants)
            {
                String key = pp.SMAX_PS_Product__c + '-' + pp.SMAX_PS_Plant__c;
                ppMap.put(key, pp);
            }

            for (SVMXC__Service_Order__c wo : woNewList)
            {
                Id productId = woProdMap.get(wo.Id);
                String plant = woPlantMap.get(wo.Id);

                String key = productId + '-' + plant;
                SMAX_PS_ProductPlant__c pp = ppMap.get(key);
                if (pp != null)
                {
                    wo.BD_Equipment_Part_Return_Number__c = (pp.BD_Return_Part_Number__c == null) ?
                            pp.SMAX_PS_Product__r.Partnum__c : pp.BD_Return_Part_Number__c;
                }
            }
        }

        // ITSVMX-253 Copy the "Item Category Group" to the WO from the Product Sales
        Set<String> salesOrgs = new Set<String>(woSalesMap.values());
        if (!salesOrgs.isEmpty() && !prodIds.isEmpty())
        {
            List<SMAX_PS_ProductSales__c> allProductSales = [SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_SalesOrg__c,
                    SMAX_PS_ItemCategoryGroup__c, SMAX_PS_Product__r.Partnum__c
            FROM SMAX_PS_ProductSales__c WHERE SMAX_PS_Product__c IN :prodIds AND SMAX_PS_SalesOrg__c IN :salesOrgs];
            Map<String, SMAX_PS_ProductSales__c> psMap = new Map<String, SMAX_PS_ProductSales__c>();
            for (SMAX_PS_ProductSales__c ps : allProductSales)
            {
                String key = ps.SMAX_PS_Product__c + '-' + ps.SMAX_PS_SalesOrg__c;
                psMap.put(key, ps);
            }

            for (SVMXC__Service_Order__c wo : woNewList)
            {
                Id productId = woProdMap.get(wo.Id);
                String salesOrg = woSalesMap.get(wo.Id);

                String key = productId + '-' + salesOrg;
                SMAX_PS_ProductSales__c ps = psMap.get(key);
                if (ps != null)
                {
                    // Set Item Category
                    wo.SMAX_PS_Item_Category_Group__c = ps.SMAX_PS_ItemCategoryGroup__c;
                }
            }
        }
    }

    /**
     * Update the WO TechnicianSalesOrg field from the Tech Storage Location.
     * Should be called in the "before" trigger(s)
     */
    public static void updateTechnicianDetails(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Tech Details', 'Update the WO SalesOrg, Tech Email, Owner and other details from the Technician and related records.'))
            return;

        Set<Id> techIds = new Set<Id>();
        List<SVMXC__Service_Order__c> woTechUpdates = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> woPrevTechUpdates = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (wo.SVMXC__Group_Member__c != null && (old == null || wo.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c))
            {
                techIds.add(wo.SVMXC__Group_Member__c);
                woTechUpdates.add(wo);
            }
            // SVMXCFG-529 - Collect "Previous" Tech Ids
            if (old != null && old.SVMXC__Group_Member__c != null && wo.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c)
            {
                techIds.add(old.SVMXC__Group_Member__c);
                woPrevTechUpdates.add(wo);
            }
        }

        if (!techIds.isEmpty())
        {
            // SVMXCFG-1092 Lookup the "TPV Queue"
            SMAX_PS_Assignment_Settings__c assignmentSettings = SMAX_PS_Assignment_Settings__c.getInstance();
            String tpvQueueName = (assignmentSettings == null) ? null : assignmentSettings.SMAX_PS_TPV_Queue__c;
            if (tpvQueueName == null && Test.isRunningTest())
            {
                tpvQueueName = 'SMAX_PS_TPV_Work_Orders';
            }
            Group tpvQueue = (tpvQueueName == null) ? null :
                    [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :tpvQueueName LIMIT 1];

            Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>([SELECT Id, Name,
                    SVMXC__Inventory_Location__c, SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c, SVMXC__Email__c,
                    SVMXC__Third_Party__c, SVMXC__Salesforce_User__c, BD_Depot_Queue_Id__c, SVMXC__Role__c, SMAX_PS_Technician_Manager_Email__c
            FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);
            // SVMXCFG-297 -- Fill in the "Technician Sales Org"
            for (SVMXC__Service_Order__c wo : woTechUpdates)
            {
                SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
                Id techId = wo.SVMXC__Group_Member__c;
                if (techMap.containsKey(techId))
                {
                    SVMXC__Service_Group_Members__c tech = techMap.get(techId);

                    // Begin of change for ITSVMX-345 reset Technician Manager Email on Work Order Reassignment to Billable Queue
                    if (tech.SMAX_PS_Technician_Manager_Email__c != null)
                    {
                        wo.SMAX_PS_Technician_Manager_Email__c = tech.SMAX_PS_Technician_Manager_Email__c;
                    }else{
                        wo.SMAX_PS_Technician_Manager_Email__c = null ;
                    }
                    // End of change for Technician Manager Email on Work Order Reassignment to Billable Queue

                    if (tech.SVMXC__Inventory_Location__c != null)
                    {
                        System.debug('Current wo.SMAX_PS_TechnicianSalesOrg__c is: ' + wo.SMAX_PS_TechnicianSalesOrg__c);
                        System.debug('Setting wo.SMAX_PS_TechnicianSalesOrg__c to: ' + tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c);
                        wo.SMAX_PS_TechnicianSalesOrg__c = tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c;
                    }
                    // SVMXCFG-824 Fill in the Member Email when Tech changes
                    wo.SVMXC__Member_Email__c = tech.SVMXC__Email__c;

                    // SVMXCFG-1092 If assigned to TPV, change Owner to "TPV Queue"
                    if (tech.SVMXC__Third_Party__c == true && tech.SVMXC__Salesforce_User__c == null
                            && tpvQueue != null)
                    {
                        wo.OwnerId = tpvQueue.Id;
                    }

                    // ITSFDC-509 If assigned to a "Depot Work Center", update Owner & RT = Depot
                    if (tech.BD_Depot_Queue_Id__c != null && tech.SVMXC__Salesforce_User__c == null)
                    {
                        wo.OwnerId = tech.BD_Depot_Queue_Id__c;
                        // ITSVMX-35 Do not change to "Assigned" if assigned to a Queue (e.g. Estimates in the "Billable Services Queue")
                        if (old != null && wo.SVMXC__Order_Status__c == 'Assigned' && old.SVMXC__Order_Status__c != wo.SVMXC__Order_Status__c)
                        {
                            // ITSVMX-699 1/20/22 Tony - Don't roll back the Order Status of "Assigned" on Technicians with a Role of Depot Queue
                            if (tech.SVMXC__Role__c != 'Depot Queue') {
                                System.debug('Rolling back Order Status from [' + wo.SVMXC__Order_Status__c + '] to [' + old.SVMXC__Order_Status__c + ']');
                                wo.SVMXC__Order_Status__c = old.SVMXC__Order_Status__c;
                            }

                            // ITSVMX-500 Don't roll back to "On Hold..."
                            if ((wo.SVMXC__Order_Status__c.startsWith('On Hold') || wo.SVMXC__Order_Status__c == 'Initializing')
                                    && wo.SMAX_PS_SAP_SystemStatus__c == 'REL' && wo.SMAX_PS_CreditHold__c == false)
                            {
                                wo.SVMXC__Order_Status__c = 'Open'; // Shouldn't be "Assigned", so default to "Open"
                            }
                        }

                        // ITSVMX-35 If "Estimate" is assigned to Queue, check the box...
                        RecordType estimateRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');
                        if (wo.RecordTypeId == estimateRT.Id)
                        {
                            wo.BD_Estimate_Queue_Originated__c = true;
                        }

                        // ITSVMX-35 Only change the Record Type is the Role is "Depot Queue". The new "Work Order Queue" will not change the Record Type.
                        // if (tech.SVMXC__Role__c == 'Depot Queue')
                        // ITSVMX-767 2/15/22 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
                        if (tech.SVMXC__Role__c == 'Depot Queue' && wo.RecordTypeId != estimateRT.Id)
                        {
                            RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');
                            if (depotRT != null)
                            {
                                wo.RecordTypeId = depotRT.Id;
                            }
                        }
                    }
                }
            }

            // SVMXCFG-529 - Fill in "Previous" Tech email
            for (SVMXC__Service_Order__c wo : woPrevTechUpdates)
            {
                SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
                if (old != null && old.SVMXC__Group_Member__c != null)
                {
                    SVMXC__Service_Group_Members__c previous = techMap.get(old.SVMXC__Group_Member__c);
                    if (previous != null)
                    {
                        //wo.SMAX_PS_Previous_Technician__c = previous.Id;
                        wo.SMAX_PS_Previous_Technician_Email__c = previous.SVMXC__Email__c;
                        // SVMXCFG-694 : Copy Previous Tech Name and a datestamp for reassign email
                        wo.SMAX_PS_Previous_Technician_Name__c = previous.Name;
                        wo.SMAX_PS_Technician_Reassignment_DateTime__c = System.now();
                    }
                }
            }
        }
    }

    /**
     * Update the WO TechnicianSalesOrg field from the Tech Storage Location.
     * Should be called in the "before" trigger(s)
     */
    public static void forceWorkOrderEvents(List<SVMXC__Service_Order__c> woNewList)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Force Events', 'Create Work Order Platform Events when Work Orders are Created.'))
            return;

        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();

        Datetime twoMinAgo = Datetime.now().addMinutes(-2);
        if (Test.isRunningTest())
            twoMinAgo = Datetime.now();
        for (SVMXC__Service_Order__c workOrder : woNewList)
        {
            if (workOrder.SMAX_PS_ForceIntegration__c == false)
                continue;

            System.debug('FORCE WO Event for WO->'+workOrder);
            Datetime lastForceDate = (workOrder.SMAX_PS_LastForceIntegration__c == null)
                    ? workOrder.CreatedDate : workOrder.SMAX_PS_LastForceIntegration__c;
            if (lastForceDate < twoMinAgo)
            {
                Boolean existsSAP = String.isNotEmpty(workOrder.SVMX_PS_External_ID__c);
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                if (!existsSAP)
                {
                    iEvent.SMAX_PS_Action__c = 'CREATE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                else if (existsSAP && workOrder.SMAX_PS_SAP_SystemStatus__c != 'TECO')
                {
                    iEvent.SMAX_PS_Action__c = 'UPDATE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                else if (existsSAP && workOrder.SMAX_PS_SAP_SystemStatus__c == 'TECO')
                {
                    iEvent.SMAX_PS_Action__c = 'BILLING REQUEST';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                workOrder.SMAX_PS_LastForceIntegration__c = Datetime.now();
            }
            workOrder.SMAX_PS_ForceIntegration__c = false;
        }
        System.debug('FORCED WO Events->'+events);

        sendWorkOrderEvents(events);
    }

    /**
     * Create Work Order Platform Events when Work Orders are Created.
     * Should be called in the "after" trigger(s)
     */
    public static void createWorkOrderEvents(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Create Events', 'Create Work Order Platform Events when Work Orders are Created.'))
            return;

        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        system.debug('woNewList->'+woNewList);

        if (!woNewList.isEmpty()){

            Boolean isIntegrationUser = SMAX_PS_Utility.isCurrentUserIntegrationProfile();
            for (SVMXC__Service_Order__c workOrder : woNewList)
            {
                Boolean existsSAP = String.isNotEmpty(workOrder.SVMX_PS_External_ID__c);
                SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                // ITSVMX-231 Added SettlementReceiver to CREATE logic
                if ((!existsSAP) && workOrder.SVMXC__Order_Status__c == 'Initializing'
                        && (old == null || old.SVMXC__Order_Status__c != workOrder.SVMXC__Order_Status__c
                        || old.SMAX_PS_SettlementReciever__c != workOrder.SMAX_PS_SettlementReciever__c))
                {
                    iEvent.SMAX_PS_Action__c = 'CREATE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                else if (existsSAP && old != null
                        && ((workOrder.SVMXC__Order_Status__c == 'DMR Released' && workOrder.SVMXC__Order_Status__c != old.SVMXC__Order_Status__c)
                        || (workOrder.SMAX_PS_SAP_SystemStatus__c == 'TECO' && workOrder.SMAX_PS_SAP_SystemStatus__c != old.SMAX_PS_SAP_SystemStatus__c)) )
                {
                    // SVMXINT-499 - Re-Order WO Event Logic - Moved this BEFORE the update below
                    if (isBillable(workOrder))
                    {
                        iEvent.SMAX_PS_Action__c = 'BILLING REQUEST';
                        iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                        events.add(iEvent);
                    }
                    else
                    {
                        // No other action needed..
                    }
                }
                else if ( existsSAP && old != null &&
                        (old.SVMXC__Group_Member__c != workOrder.SVMXC__Group_Member__c ||
                                old.SVMXC__Scheduled_Date__c != workOrder.SVMXC__Scheduled_Date__c ||
                                old.SVMXC__Scheduled_Date_Time__c != workOrder.SVMXC__Scheduled_Date_Time__c ||
                                old.SVMXC__Service_Contract__c != workOrder.SVMXC__Service_Contract__c ||
                                old.SMAX_PS_ContractItem__c != workOrder.SMAX_PS_ContractItem__c ||
                                //old.SVMXC__Canceled_Date_Time__c != workOrder.SVMXC__Canceled_Date_Time__c ||
                                old.SMAX_PS_SettlementReciever__c != workOrder.SMAX_PS_SettlementReciever__c ||
                                old.SMAX_PS_HSI1_Answer__c != workOrder.SMAX_PS_HSI1_Answer__c ||
                                old.SMAX_PS_HSI2_Answer__c != workOrder.SMAX_PS_HSI2_Answer__c ||
                                old.SMAX_PS_HSI3_Answer__c != workOrder.SMAX_PS_HSI3_Answer__c ||
                                old.SVMXC__Priority__c != workOrder.SVMXC__Priority__c ||
                                old.SVMXC__Contact__c != workOrder.SVMXC__Contact__c ||
                                old.SMAX_PS_CustomerPO__c != workOrder.SMAX_PS_CustomerPO__c ||
                                old.SMAX_PS_SAP_Activity_Status__c != workOrder.SMAX_PS_SAP_Activity_Status__c ||
                                old.SMAX_PS_SAP_Order_Status__c != workOrder.SMAX_PS_SAP_Order_Status__c ||
                                old.SVMX_PS_Problem_Summary__c != workOrder.SVMX_PS_Problem_Summary__c ||
                                old.SVMXC__Problem_Description__c != workOrder.SVMXC__Problem_Description__c ||
                                old.SVMX_PS_Internal_Notes__c != workOrder.SVMX_PS_Internal_Notes__c ||
                                old.SMAX_PS_Internal_Description__c != workOrder.SMAX_PS_Internal_Description__c ||
                                old.SMAX_PS_Q1_Response__c != workOrder.SMAX_PS_Q1_Response__c ||
                                old.SMAX_PS_Q2_Response__c != workOrder.SMAX_PS_Q2_Response__c ||
                                old.SMAX_PS_Q3_Response__c != workOrder.SMAX_PS_Q3_Response__c ||
                                old.SMAX_PS_Q4_Response__c != workOrder.SMAX_PS_Q4_Response__c ||
                                old.SMAX_PS_Q5_Response__c != workOrder.SMAX_PS_Q5_Response__c ||
                                old.SMAX_PS_Customer_Order_Id__c != workOrder.SMAX_PS_Customer_Order_Id__c ||
                                old.SMAX_PS_Customer_Required_Start_Date__c != workOrder.SMAX_PS_Customer_Required_Start_Date__c ||
                                old.SVMXC__Company__c != workOrder.SVMXC__Company__c ||
                                old.SMAX_PS_BillTo__c != workOrder.SMAX_PS_BillTo__c ||
                                old.SMAX_PS_Payer__c != workOrder.SMAX_PS_Payer__c ||
                                old.SMAX_PS_ShipTo__c != workOrder.SMAX_PS_ShipTo__c ||
                                old.SMAX_PS_Local_Language_Bill_To_Account__c != workOrder.SMAX_PS_Local_Language_Bill_To_Account__c ||
                                old.SMAX_PS_Local_Language_Ship_To_Account__c != workOrder.SMAX_PS_Local_Language_Ship_To_Account__c ||
                                old.SVMXC__Order_Type__c != workOrder.SVMXC__Order_Type__c ||
                                old.SVMXC__Billing_Type__c != workOrder.SVMXC__Billing_Type__c ||
                                old.SMAX_PS_Override_Malfunction_Start_Date__c != workOrder.SMAX_PS_Override_Malfunction_Start_Date__c ||
                                old.SVMXC__Site__c != workOrder.SVMXC__Site__c ||
                                old.SMAX_PS_Quote_Number__c != workOrder.SMAX_PS_Quote_Number__c ||                     
                                old.SMAX_PS_Quote_Accepted_Date__c != workOrder.SMAX_PS_Quote_Accepted_Date__c ||
                                old.SMAX_PS_Customer_PO_Billable__c != workOrder.SMAX_PS_Customer_PO_Billable__c ||
                                old.SVMXC__Preferred_Technician__c != workOrder.SVMXC__Preferred_Technician__c
                         

                        ))
                {
                    // SVMXINT-589 Added Account Lookup fields (above)
                    // SVMXINT-615 Added the Order / Billing Types (above)
                    // SVMXCFG-896 Added Override Malfunction Start Date (above)
                    // SVMXCFG-903 Added Local Language BillTo and ShipTo lookups (above)
                    //ITSVMX-665   Added update funcational location at WO level
                    //ITSVMX-534   Enterprise Quote fields
                    iEvent.SMAX_PS_Action__c = 'UPDATE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                else if ( existsSAP && old != null && (
                        old.SMAX_PS_Q1_Answer__c != workOrder.SMAX_PS_Q1_Answer__c ||
                                old.SMAX_PS_Q2_Answer__c != workOrder.SMAX_PS_Q2_Answer__c ||
                                old.SMAX_PS_Q3_Answer__c != workOrder.SMAX_PS_Q3_Answer__c ||
                                old.SMAX_PS_Q4_Answer__c != workOrder.SMAX_PS_Q4_Answer__c ||
                                old.SMAX_PS_Q5_Answer__c != workOrder.SMAX_PS_Q5_Answer__c
                ))
                {
                    // SVMXINT-651 When the "Guidance" (aka "Additional Info") Answers change, send new event
                    iEvent.SMAX_PS_Action__c = 'GUIDANCE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
                else if (existsSAP && old != null
                        && isIntegrationUser && workOrder.CreatedById == UserInfo.getUserId()
                        && old.SMAX_PS_SAP_SystemStatus__c == null && workOrder.SMAX_PS_SAP_SystemStatus__c != null)
                {
                    // SVMXINT-605 End of WO Load, send UPDATE even if above logic didnt fire
                    iEvent.SMAX_PS_Action__c = 'UPDATE';
                    iEvent.SMAX_PS_WorkOrderId__c = workOrder.Id;
                    events.add(iEvent);
                }
            }
            System.debug('Events->'+events);
        }

        sendWorkOrderEvents(events);
    }

    // JIRA #387 - Dispatch Console - Duplicate WO Platform Events
    private static Set<Id> WO_EVENT_IDS = new Set<Id>();
    // SVMXCFG-648 Changing to public so we can reuse from Debrief Manager
    public static void sendWorkOrderEvents(List<SMAX_PS_WorkOrder_Event__e> events)
    {
        List<SMAX_PS_WorkOrder_Event__e> filteredEvents = new List<SMAX_PS_WorkOrder_Event__e>();
        for (SMAX_PS_WorkOrder_Event__e evt : events)
        {
            if (!WO_EVENT_IDS.contains(evt.SMAX_PS_WorkOrderId__c))
            {
                filteredEvents.add(evt);
                // Hold on to WO Ids to make sure only 1 Event sent for each
                WO_EVENT_IDS.add(evt.SMAX_PS_WorkOrderId__c);
            }
        }

        SMAX_PS_PlatformEventUtility.publishEvents(filteredEvents, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
    }

    private static Set<String> PRE_OPEN_STATUS = new Set<String> { 'Initializing', 'On Hold - Cost', 'On Hold - Credit' };
    private static Set<String> NON_DISPATCH_STATUS = new Set<String> { 'Ready for Review', 'Closed', 'Canceled',
            'Technician Enroute', 'Technician Onsite', 'Ready to Invoice', 'Work Complete', 'Work Complete - Error',
            'DMR Rejected', 'DMR Released', 'Approved', 'HSI', 'Estimate Approved', 'Estimate Rejected', 'Invoiced', 'Submit WO for Approval' };

    /**
     * Based on updates from SAP, auto-update the WO Order Status.
     * Should be called in the "before" trigger(s)
     */
    public static void updateWorkOrderStatus(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Update Status', 'Based on updates from SAP, auto-update the WO Order Status.'))
            return;

        RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');
        List<Id> tecoWoIds = new List<Id>();
        if (!woNewList.isEmpty()) {
            for (SVMXC__Service_Order__c workOrder : woNewList)
            {
                System.debug('!! ' + workOrder.Name + ' DISPATCH STATUS = ' + workOrder.SVMXC__Dispatch_Status__c);
                SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);

                if (old != null
                        && workOrder.SVMXC__Order_Status__c != old.SVMXC__Order_Status__c
                        && workOrder.SVMXC__Order_Status__c == 'Initializing'
                        && workOrder.SMAX_PS_SAP_SystemStatus__c != null)
                {
                    // Don't allow WO to go back to Initializing if they already have a SAP System Status
                    workOrder.SVMXC__Order_Status__c = old.SVMXC__Order_Status__c;
                }
                
                //ITSVMX-674 Store the old value of Order type to Original Order type field
                if (old != null && workorder.SVMXC__Order_Type__c != old.SVMXC__Order_Type__c && workorder.SMAX_PS_Original_Work_Order_Order_Type__c == null){
                workorder.SMAX_PS_Original_Work_Order_Order_Type__c = old.SVMXC__Order_Type__c;}
                if (old!=null && workorder.BD_Record_Type_formula__c != old.BD_Record_Type_formula__c && workorder.SMAX_PS_Original_Work_Order_Type__c == null){
                workorder.SMAX_PS_Original_Work_Order_Type__c = old.BD_Record_Type_formula__c;}
                
                
                if ( old != null && (old.SMAX_PS_CreditHold__c != workOrder.SMAX_PS_CreditHold__c
                        || old.SMAX_PS_SAP_SystemStatus__c != workOrder.SMAX_PS_SAP_SystemStatus__c) )
                {
                    // SVMXCFG-409 - Only Update Order Status if NOT past "Open" status
                    if (PRE_OPEN_STATUS.contains(workOrder.SVMXC__Order_Status__c))
                    {
                        if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'CRTD')
                            workOrder.SVMXC__Order_Status__c = 'On Hold - Cost';
                        if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'REL' && workOrder.SMAX_PS_CreditHold__c == true)
                            workOrder.SVMXC__Order_Status__c = 'On Hold - Credit';
                        if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'REL' && workOrder.SMAX_PS_CreditHold__c == false)
                        {
                            // SVMXCFG-682 - If Tech already populated, change to 'Assigned' instead
                            if (workOrder.SVMXC__Group_Member__c == null)
                            {
                                workOrder.SVMXC__Order_Status__c = 'Open';
                            }
                            else
                            {
                                workOrder.SVMXC__Order_Status__c = 'Assigned';
                            }
                        }
                    }
                    if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'TECO')
                    {
                        tecoWoIds.add(workOrder.Id);
                    }
                    if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'CLSD' && workOrder.SVMXC__Order_Status__c != 'Canceled')
                    {
                        workOrder.SVMXC__Order_Status__c = 'Closed';
                    }
                }
                else if (old != null && (old.SMAX_PS_DMR_Number__c != workOrder.SMAX_PS_DMR_Number__c))
                {
                    workOrder.SVMXC__Order_Status__c = 'Ready for Review';
                }
                // RE-FACTORED WF Rule: SVMX_PS - Set WO to Assigned
//              else if (old != null && old.SVMXC__Dispatch_Status__c != workOrder.SVMXC__Dispatch_Status__c
//                      && workOrder.SVMXC__Dispatch_Status__c == 'Assigned'
//                      && (!NON_DISPATCH_STATUS.contains(workOrder.SVMXC__Order_Status__c)))
                // ITSVMX-117 Updated to detect changes to the Technician lookup instead
                else if (old != null && workOrder.SVMXC__Group_Member__c != null
                        && old.SVMXC__Group_Member__c != workOrder.SVMXC__Group_Member__c
                        && (!NON_DISPATCH_STATUS.contains(workOrder.SVMXC__Order_Status__c)))
                {
                    // SVMXCFG-932 - Allow Assignment while "On-Hold - XXX", but do not change to "Assigned"
                    if (workOrder.SMAX_PS_SAP_SystemStatus__c == 'CRTD' || workOrder.SMAX_PS_CreditHold__c == true)
                    {
                        // No action.. do not move to "Assigned"
                    }
                    else if (workOrder.SMAX_PS_SAP_SystemStatus__c == null && workOrder.RecordTypeId == depotRT.Id)
                    {
                        // No action... to not move to "Assigned"
                    }
                    // 2020-01-28 commented out if clause to make sure estimates change to 'Assigned'
                    else //if (workOrder.SMAX_PS_SAP_SystemStatus__c != null)
                    {
                        workOrder.SVMXC__Order_Status__c = 'Assigned';
                    }
                }
                // ITSVMX-134 tony - Updated to detect changes to Scheduled Date Time when status = Technician Rejected
                // and set the Order Status back to Assigned
                else if (old != null && workOrder.SVMXC__Group_Member__c != null
                        && workOrder.SVMXC__Order_Status__c == 'Technician Rejected'
                        && old.SVMXC__Scheduled_Date_Time__c != workOrder.SVMXC__Scheduled_Date_Time__c)
                {
                    workOrder.SVMXC__Order_Status__c = 'Assigned';
                }
            }
        }

        if (!tecoWoIds.isEmpty())
        {
            if (!SMAX_PS_Utility.isActive('Update IP Last WO Details', 'Update the Last Work Order Details field on the IP when WO Status changes to Work Complete.'))
                return;

            updateInstalledProductDetails(tecoWoIds);
        }
        
    }

//    public static Set<String> NON_PRICED_WO_TYPES = new Set<String> { 'Installation', 'Internal' };

    /**
     *  Update the child Work Detail lines Status to "Submitted" if the "Submit All Lines" field is checked
     *  Should be called in the "before" trigger(s)
     *  DEPRECATED as part of One-Click Complete
     */
/*
    public static void updateWorkDetailLineStatus(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Submit All Lines', 'Update the child Work Detail lines Status to "Submitted" if the "Submit All Lines" field is checked'))
            return;

        // Get Record Type Id for Usage Consumption
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;

        // Collect qualified Work Order Ids
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c workOrder : woNewList)
        {
            SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);
            if ( old != null && old.SMAX_PS_SubmitAllLines__c != workOrder.SMAX_PS_SubmitAllLines__c && workOrder.SMAX_PS_SubmitAllLines__c == TRUE)
            {
                woMap.put(workOrder.Id, workOrder);
                workOrder.SMAX_PS_SubmitAllLines__c=false;
            }
        }
        if (woMap.isEmpty())
            return;
        System.debug('SUBMIT_ALL_LINES Starting');

        // Select the Work Detail lines which qualify for updation
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>([SELECT Id, Name,
            SVMXC__Line_Status__c, SVMXC__Line_Type__c, SVMXC__Service_Order__c,
            SVMXC__Product__c, SMAX_PS_ContractPercentDiscount__c
            FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c in :woMap.keySet() AND RecordTypeId = :usageRecTypeId ]);
            //AND SVMXC__Line_Status__c='Priced']);

        // SVMXCFG-335 WO Submit Lines: Skip Priced on 100% Discount Lines
        Map<Id, List<SVMXC__Service_Order_Line__c>> linesToDiscount = new Map<Id, List<SVMXC__Service_Order_Line__c>>();

        // Update Work Detail Lines Status
        Set<Id> woIdsToSend = new Set<Id>(woMap.keySet());
        List<SVMXC__Service_Order_Line__c> wdToUpdate = new List<SVMXC__Service_Order_Line__c>();
        for ( SVMXC__Service_Order_Line__c wd : wdList ) {
            SVMXC__Service_Order__c wo = woMap.get(wd.SVMXC__Service_Order__c);
            System.debug('SUBMIT_ALL_LINES WO: ' + wo);
            if (wd.SVMXC__Line_Status__c == 'Priced'
                // SVMXINT-469 Complaints: Fault Code Integration Changes (Send Fault Codes only if not Confirmed)
                || (wd.SVMXC__Line_Type__c == 'Fault Code' && wd.SVMXC__Line_Status__c == 'Open')
                // JIRA #392 - Internal / Installation - Skip Priced
                || (NON_PRICED_WO_TYPES.contains(wo.SVMXC__Billing_Type__c) && wd.SVMXC__Line_Status__c == 'Open') )
            {
                // SVMXINT-461 - If line is already Submitted, this won't fire the event.. check first
                if (wd.SVMXC__Line_Status__c != 'Submitted')
                {
                    wd.SVMXC__Line_Status__c='Submitted';
                    wdToUpdate.add(wd);
                    if (woIdsToSend.contains(wd.SVMXC__Service_Order__c))
                    {
                        woIdsToSend.remove(wd.SVMXC__Service_Order__c);
                    }
                }
            }
            else if (wo.SMAX_PS_ContractEntitlement__c != null && wd.SVMXC__Line_Status__c == 'Open'
                && wd.SMAX_PS_ContractPercentDiscount__c == null)
            {
                if (!linesToDiscount.containsKey(wo.Id))
                    linesToDiscount.put(wo.Id, new List<SVMXC__Service_Order_Line__c>());
                linesToDiscount.get(wo.Id).add(wd);
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
                    wdToUpdate.add(wd);
                    if (woIdsToSend.contains(wd.SVMXC__Service_Order__c))
                    {
                        woIdsToSend.remove(wd.SVMXC__Service_Order__c);
                    }
                }
            }
        }

        if (!wdToUpdate.isEmpty())
            update wdToUpdate;

        // Send SUBMIT event if no lines for each woIds...
        if (!woIdsToSend.isEmpty()) {
            List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
            for (Id woId : woIdsToSend) {
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                iEvent.SMAX_PS_Action__c = 'SUBMIT';
                iEvent.SMAX_PS_WorkOrderId__c = woId;
                events.add(iEvent);
            }

            SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
        }
    }
*/

    /**
     *  Validate that the Work Order is allowed to transition to Work Complete.
     *  Should be called in the "before" trigger(s)
     *  DEPRECATED as part of One-Click Complete
     */
/*
    public static void addWorkCompleteError(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> woOldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Complete Validations', 'Validate that the Work Order is allowed to transition to Work Complete.'))
            return;

        // Collect qualified Work Order Ids
        Set<Id> woIds = new Set<Id>();
        // SVMXCFG-515: WO "COMPLETE" Event Bug - Only process WOs in "woToUpdate"
        List<SVMXC__Service_Order__c> woToUpdate = new List<SVMXC__Service_Order__c>();
        if (!woNewList.isEmpty()) {
            for (SVMXC__Service_Order__c workOrder : woNewList)
            {
                SVMXC__Service_Order__c old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);
                if ( old != null && old.SVMXC__Order_Status__c != workOrder.SVMXC__Order_Status__c && workOrder.SVMXC__Order_Status__c == WORK_COMPLETE)
                {
                    woIds.add(workOrder.Id);
                    woToUpdate.add(workOrder);
                }
            }
        }
        if (woIds.isEmpty())
            return;

        RecordType usageRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption');

        // Select the Work Detail lines which are not Confirmed or Canceled
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>([SELECT Id, Name, SVMXC__Service_Order__c,
            SVMXC__Line_Type__c, SVMXC__Line_Status__c
            FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c in :woIds
            AND RecordTypeId = :usageRecType.Id AND SVMXC__Line_Status__c!='Canceled']);
        Map<Id, DebriefStats> woMap = new Map<Id, DebriefStats>();

        // Fill Work Order Detail Map
        for (SVMXC__Service_Order_Line__c wd : wdList) {
            if(!woMap.containskey(wd.SVMXC__Service_Order__c)) {
                woMap.put(wd.SVMXC__Service_Order__c, new DebriefStats());
            }
            // SVMXCFG-380 - Fault Code "Required" Rule Changes... load more stats
            DebriefStats stats = woMap.get(wd.SVMXC__Service_Order__c);
            if (wd.SVMXC__Line_Status__c == 'Confirmed')
            {
                if (wd.SVMXC__Line_Type__c == 'Fault Code')
                {
                    stats.confirmedFaultCodeLines++;
                }
                else
                {
                    stats.confirmedDebriefLines++;
                }
            }
            else
            {
                stats.unconfirmedLines++;
            }
        }

        // SVMXCFG-330 - Ignore Attachments (for now)..
        Boolean verifyAttachments = !SMAX_PS_Utility.isActive('Work Complete - Ignore Attachments', 'Indicates if Attachments should be ignored during the Work Complete rules.');
        // Verify Attachments have been submitted also
        Map<Id, List<Attachment>> woAttachMap = new Map<Id, List<Attachment>>();

        // Fill Work Order Attachment Map
        if (verifyAttachments == TRUE)
        {
            List<Attachment> attachList = new List<Attachment>([SELECT Id, Name, Description, ParentId
                FROM Attachment WHERE ParentId in :woIds AND (Description='' OR Description=null)]);
            for (Attachment attach : attachList) {
                if(!woAttachMap.containskey(attach.ParentId)) {
                    woAttachMap.put(attach.ParentId, new List<Attachment>());
                }
                woAttachMap.get(attach.ParentId).add(attach);
            }
        }

        // Main Process - Display the exception error or send events
        List<Id> woIdList = new List<Id>();
        List<SMAX_PS_WorkOrder_Event__e> events = new List<SMAX_PS_WorkOrder_Event__e>();
        for (SVMXC__Service_Order__c wo : woToUpdate)
        {
            wo.SMAX_PS_Completion_Errors__c = null;
            List<String> errorMsgs = new List<String>();
            DebriefStats stats = (woMap.containsKey(wo.Id)) ? woMap.get(wo.Id) : new DebriefStats();
            Integer wdCount = stats.unconfirmedLines;
            if (wdCount > 0)
            {
                errorMsgs.add('All Work Details must first be successfully submitted and confirmed to SAP. There are currently '
                    + wdCount + ' Work Detail(s) that need to be submitted and confirmed.');
            }
            Integer attachCount = (woAttachMap.containsKey(wo.Id)) ? woAttachMap.get(wo.Id).size() : 0;
            if (attachCount > 0)
            {
                errorMsgs.add('All Attachments must first be successfully submitted and confirmed to SAP. There are currently '
                    + attachCount + ' Attachment(s) that need to be submitted and confirmed.');
            }

            // SVMXCFG-366 Complaints: WO Complete Requires Fault Code
            Integer faultCodeCount = stats.confirmedFaultCodeLines;
            if (faultCodeCount == 0)
            {
                // SVMXCFG-380: If 0 Confirmed Debrief Lines, Installation, or TPV skip this..
                if (stats.confirmedDebriefLines == 0 || wo.SMAX_PS_Is_TPV__c == TRUE) // wo.SMAX_PS_Is_Install__c == TRUE ||
                {
                    System.debug('SKIPPING Fault Code Validation because NO Confirmed Lines OR TPV');
                }
                else
                {
                    errorMsgs.add('At least one Fault Code line must be submitted and confirmed when other Debrief lines are confirmed.');
                }
            }

            if (!errorMsgs.isEmpty())
            {
                String errorMsg = 'For a Work Order to transition to "Work Complete", the following must be corrected: ' + errorMsgs;
                // SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
                //wo.addError(errorMsg);
                wo.SMAX_PS_Completion_Errors__c = errorMsg;
                wo.SVMXC__Order_Status__c = 'Work Complete - Error';
            }
            else if (wo.SMAX_PS_SAP_SystemStatus__c != 'TECO')
            {
                SMAX_PS_WorkOrder_Event__e iEvent = new SMAX_PS_WorkOrder_Event__e();
                iEvent.SMAX_PS_Action__c = 'COMPLETE';
                iEvent.SMAX_PS_WorkOrderId__c = wo.Id;
                events.add(iEvent);

                woIdList.add(wo.Id);
            }
            else
            {
                // JIRA #391 - Reissue Billing Request (after Rejecting)
                if (isBillable(wo))
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

        SMAX_PS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_WorkOrderId__c', 'SMAX_PS_Action__c');
    }
*/

    /**
     *  DEPRECATED as part of One-Click Complete
     */
/*
    public class DebriefStats
    {
        public Integer confirmedDebriefLines { get; set; }
        public Integer confirmedFaultCodeLines { get; set; }
        public Integer unconfirmedLines { get; set; }

        public DebriefStats()
        {
            this.confirmedDebriefLines = 0;
            this.confirmedFaultCodeLines = 0;
            this.unconfirmedLines = 0;
        }
    }
*/

    // JIRA #390 - Don't send Billing Request is Total = $0
    public static Boolean isBillable(SVMXC__Service_Order__c wo)
    {
        // JIRA # 513 (2018-04-23 Maples) Changed to new Rollup Summary Field below - return wo.SMAX_PS_Is_Billable__c == TRUE && wo.SVMXC__Total_Work_Order_Cost__c > 0.00;
        //return wo.SMAX_PS_Is_Billable__c == TRUE && wo.SMAX_PS_Work_Order_Amount__c > 0.00;
        // SVMXCFG-576 - Changed (again) to now include EITHER total cost with OR without adjustments > 0
        return wo.SMAX_PS_Is_Billable__c == true &&
                (wo.SMAX_PS_Work_Order_Amount__c > 0.00 || wo.SMAX_PS_TotalCalculatedAmount__c > 0.00);
    }

    public static void updateInstalledProductDetails(List<Id> woIds)
    {
        List<SVMXC__Service_Order__c> woList = [SELECT Id, Name, SVMXC__Component__c, SVMXC__Group_Member__r.Name, SVMXC__Order_Type__c, SVMXC__Completed_Date_Time__c
        FROM SVMXC__Service_Order__c WHERE Id IN :woIds];
        Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            if (wo.SVMXC__Component__c != null)
            {
                SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
                ip.Id = wo.SVMXC__Component__c;
                ip.SMAX_PS_Last_Work_Order_Details__c = wo.Name + ', '
                        + wo.SVMXC__Group_Member__r.Name + ', '
                        + wo.SVMXC__Order_Type__c + ', '
                        + wo.SVMXC__Completed_Date_Time__c;
                if (ip.SMAX_PS_Last_Work_Order_Details__c.length() > 255)
                    ip.SMAX_PS_Last_Work_Order_Details__c = ip.SMAX_PS_Last_Work_Order_Details__c.substring(0, 252) + '...';
                ipMap.put(ip.Id, ip);
            }
        }
        if (!ipMap.isEmpty())
            update ipMap.values();
    }

    /**
     *  Work Orders must have a Location, Product or Installed Product.
     *  Should be called in the "before" trigger(s)
     */
    public static void preventInvalidWorkOrders(List<SVMXC__Service_Order__c> woNewList)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Prevent Invalid', 'Work Orders must have a Location, Product or Installed Product.'))
            return;

        RecordType fsRecType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Field_Service');

        // JIRA #385 - Prevent Invalid WO
        for (SVMXC__Service_Order__c wo : woNewList)
        {
            if (wo.SVMXC__Component__c == null && wo.SVMXC__Site__c == null && wo.SVMXC__Product__c == null
                    && (fsRecType != null && fsRecType.Id == wo.RecordTypeId))
            {
                // If all 3 of these are blank, this is an invalid WO.. add an error
                wo.addError('Work Orders must have a Location, Product or Installed Product.');
            }
        }
    }

    /**
     *  SVMXINT-502: Create Int Errors to detect duplicate processing
     *  Should be called from WO After Update trigger
     */
    public static void logDuplicateErrors(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Dulicate Errors', 'Create Integration Errors when SAP Confirmation Numbers are changed.'))
            return;

        List<SMAX_PS_IntegrationError__c> errorList = new List<SMAX_PS_IntegrationError__c>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (old == null)
                continue;

            if (old.SVMX_PS_External_ID__c != null && wo.SVMX_PS_External_ID__c != old.SVMX_PS_External_ID__c)
            {
                SMAX_PS_IntegrationError__c ie = new SMAX_PS_IntegrationError__c();
                ie.SMAX_PS_RelatedElementType__c = 'WorkOrderId';
                ie.SMAX_PS_RelatedElementIdentifier__c = wo.Id;
                ie.SMAX_PS_ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Service Order Numbers: '
                        + old.SVMX_PS_External_ID__c + ', ' + wo.SVMX_PS_External_ID__c;
                errorList.add(ie);
            }
            if (old.SMAX_PS_SAP_Notification_ID__c != null && wo.SMAX_PS_SAP_Notification_ID__c != old.SMAX_PS_SAP_Notification_ID__c)
            {
                SMAX_PS_IntegrationError__c ie = new SMAX_PS_IntegrationError__c();
                ie.SMAX_PS_RelatedElementType__c = 'WorkOrderId';
                ie.SMAX_PS_RelatedElementIdentifier__c = wo.Id;
                ie.SMAX_PS_ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Notification Numbers: '
                        + old.SMAX_PS_SAP_Notification_ID__c + ', ' + wo.SMAX_PS_SAP_Notification_ID__c;
                errorList.add(ie);
            }
        }

        if (!errorList.isEmpty())
            insert errorList;
    }

    // Added for [SVMXCFG-777] - Auto-Fill the Translation lookup based ont he WO Country
    // 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
    public static void lookupTranslation(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Lookup Translation',
                'Lookup a Translation record based on the WO Country and Owned By Company.'))
            return;

        List<SVMXC__Service_Order__c> woToLookup = new List<SVMXC__Service_Order__c>();
        Set<String> countryCodes = new Set<String>();
        Set<String> ownedByCompanies = new Set<String>();
        for (SVMXC__Service_Order__c wo : woList)
        {
            //if (wo.SVMXC__Country__c != null && wo.SMAX_PS_Translation__c == null)
            if (wo.SVMXC__Country__c != null && wo.SMAX_PS_Owned_By_Company__c != null && wo.SMAX_PS_Translation__c == null)
            {
                woToLookup.add(wo);
                countryCodes.add(wo.SVMXC__Country__c);
                ownedByCompanies.add(wo.SMAX_PS_Owned_By_Company__c);
            }
        }

        if (countryCodes.isEmpty() || ownedByCompanies.isEmpty())
            return;

        Map<String, SMAX_PS_Translation__c> translationMap = new Map<String, SMAX_PS_Translation__c>();
        for (SMAX_PS_Translation__c translation : [SELECT Id, Name, SMAX_PS_Country__c, SMAX_PS_Owned_By_Company__c
            FROM SMAX_PS_Translation__c WHERE SMAX_PS_Country__c IN :countryCodes AND SMAX_PS_Owned_By_Company__c IN :ownedByCompanies
            ORDER BY SMAX_PS_Is_Default__c DESC]) // ITSVMX-1337 Added ORDER BY to sort the TRUE values first
        {
            // ITSVMX-1337 Added "containsKey" to ensure the Defaults are not overwritten
            String key = translation.SMAX_PS_Country__c + '-' + translation.SMAX_PS_Owned_By_Company__c;
            if (!translationMap.containsKey(key)) {
                translationMap.put(key, translation);
            }
        }

        for (SVMXC__Service_Order__c wo : woToLookup)
        {
            //SMAX_PS_Translation__c translation = translationMap.get(wo.SVMXC__Country__c);
            SMAX_PS_Translation__c translation = translationMap.get(wo.SVMXC__Country__c + '-' + wo.SMAX_PS_Owned_By_Company__c);
            if (translation != null)
            {
                wo.SMAX_PS_Translation__c = translation.Id;
            }
        }
    }

    // Added for [SVMXCFG-837] - Change OrderStatus to 'Open' when Tech is unassigned (and not already complete)
    public static void unassignWO(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            // TODO: We could add logic here to detect a "Rejected" Work Order, and UNASSIGN the Lookup(Technician)

            if (old != null && wo.SVMXC__Group_Member__c == null && old.SVMXC__Group_Member__c != null)
            {
                // UNASSIGN detected...
                if (wo.SVMXC__Order_Status__c == 'Assigned' || wo.SVMXC__Order_Status__c.startsWith('Technician'))
                {
                    wo.SVMXC__Order_Status__c = 'Open';
                }
            }
        }
    }

    // NOTE: Moved autoCreateRMA() to the SMAX_PS_InventoryManager class for ITSVMX-200

    // ITSFDC-1047 - Auto-Map the Depot Record Type when "Escalate to Depot"
/*  public static void escalateToDepot(List<SVMXC__Service_Order__c> woNewList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        for (SVMXC__Service_Order__c wo : woNewList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (wo.BD_Escalate_to_Depot__c == true && old.BD_Escalate_to_Depot__c != wo.BD_Escalate_to_Depot__c) {
                RecordType depotRT = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Depot_Repair');
                wo.RecordTypeId = depotRT.Id;
            }
        }
    }
*/

    // ITSFDC-509 When WO is changed to "Depot" OR is "Depot" and gets a SAP Id... auto-create RMA
    public static void updateRollups(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Rollups', 'Update the WO header with child counts / details'))
            return;

        Map<Id, SVMXC__Service_Order__c> woDetails = new Map<Id, SVMXC__Service_Order__c>([SELECT Id, Name,
                //(SELECT Id, Name, BD_Eligible_for_Return__c FROM SVMXC__Service_Order_Line__r WHERE BD_Eligible_for_Return__c = TRUE)
        (SELECT Id, Name, BD_Covered_Until__c FROM Extended_Warranty_Coverages__r
        WHERE BD_Covered_Until__c > TODAY AND BD_Warranty_Work_Order__c = NULL)
        FROM SVMXC__Service_Order__c WHERE Id IN :woList]);

        for (SVMXC__Service_Order__c wo : woList)
        {
            // Number of Extended Warranty Parts
            SVMXC__Service_Order__c woDetail = woDetails.get(wo.Id);
            Integer numEWP = (woDetail == null || woDetail.Extended_Warranty_Coverages__r == null)
                    ? 0 : woDetail.Extended_Warranty_Coverages__r.size();
            wo.BD_Number_of_Extended_Warranty_Parts__c = numEWP;
        }
    }

    // ITSVMX-134 10/1/20 - tony Remove the calendar event when the WO status changes to 'Technician Rejected'
    // Should be called from After Update WO trigger
    public static void removeRejectedCalendarEvents(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        System.debug('Entered SMAX_PS_WorkOrderManager.removeRejectedCalendarEvents');

        List<Event> calEvents = [
                SELECT Id, Subject, WhatId, OwnerId
                FROM Event
                WHERE WhatId IN :woList
        ];

        List<Event> deleteCalendarEventList = new List<Event>();

        for (SVMXC__Service_Order__c wo : woList)
        {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            System.debug('[' + wo.SVMXC__Order_Status__c + ']  [' + old.SVMXC__Order_Status__c + ']');
            if (wo.SVMXC__Order_Status__c == 'Technician Rejected' && (old != null && old.SVMXC__Order_Status__c != 'Technician Rejected'))
            {
                System.debug('Loop over Calendar Events');
                for (Event calEvent :calEvents)
                {
                    System.debug('Calendar Event: ' + calEvent);
                    if (calEvent.WhatId == wo.Id)
                    {
                        System.debug('Adding Calendar Event to delete list: ' + calEvent);
                        deleteCalendarEventList.add(calEvent);
                    }
                }
            }
        }

        if (deleteCalendarEventList.size() > 0)
        {
            // 11/30/20 tony - ITSVMX-206 moved deletion of Event records outside this class as this class uses "With Sharing"
            // and will not allow the Service Managers to delete records
            System.debug('Calling SMAX_PS_EventManager.deleteEventsNoSharingRules() to delete Calendar Events:' + deleteCalendarEventList);
            SMAX_PS_EventManager.deleteEventsNoSharingRules(deleteCalendarEventList);
            //delete deleteCalendarEventList;
        }
    }

    // TODO - add unit test for removeRejectedCalendarEvents()

    /** 1/8/21 ITSVMX-233 TAC: RWO/WO - need a field Escalated By to track who converted RWO to WO
      * Automatically capture the User who escalated the WO from “Remote” to “Field Service” Record Type.
      * Recommend you capture this as a Text Field, instead of a Lookup (so you don’t use up one of the
      * last Lookup fields available).
      * NOTE: Should be called by BeforeUpdate trigger handler event.
    */
    public static void updateEscalatedBy(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.updateEscalatedBy()');

        Id remoteRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        // 10/29/21 ITSVMX-608 - Added check for Service Request
        Id serviceRequestRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();

        // Get the list of WO that need the Escalated By updated
        List<SVMXC__Service_Order__c> woUpdateList = new List<SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo :woList) {

            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            // 10/29/21 ITSVMX-608 - Added check for Service Request also
            // if (old != null && wo.RecordTypeId == fieldServiceRTId && old.RecordTypeId == remoteRTId) {
            if (old != null && old.RecordTypeId == remoteRTId && (wo.RecordTypeId == fieldServiceRTId || wo.RecordTypeId == serviceRequestRTId)) {
                woUpdateList.add(wo);
            }
        }

        if (woUpdateList.size() < 1) return;
        System.debug('How many WOs found to update Escalated By: ' + woUpdateList.size());

        // 2/16/22 ITSVMX-276 Get SMAX_PS_Escalated_to_Field_Service_Queue__c Custom Setting
        SMAX_PS_Assignment_Settings__c assignmentSettings = SMAX_PS_Assignment_Settings__c.getOrgDefaults();
        String queueStr = assignmentSettings.SMAX_PS_Escalated_to_Field_Service_Queue__c;
        System.debug('Custom Setting SMAX_PS_Assignment_Settings__c.SMAX_PS_Escalated_to_Field_Service_Queue__c: ' + queueStr);
        List<Group> groups = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName = :queueStr AND Type = 'Queue'];
        Id queueId = null;

        if (!groups.isEmpty()) {
            queueId = groups[0]?.Id;
            System.debug('Queue ' + queueStr + ' Found.');
        } else {
            System.debug(LoggingLevel.ERROR, 'No Queue found for DeveloperName = ' + queueStr + '  Please check the Custom Setting: SMAX_PS_Assignment_Settings__c.SMAX_PS_Escalated_to_Field_Service_Queue__c');
        }
        System.debug('queueId: ' + queueId);

        // Update the Escalated By to the Current User
        for (SVMXC__Service_Order__c wo :woUpdateList) {
            wo.SMAX_PS_Escalated_By__c = UserInfo.getName();

            // 2/16/22 ITSVMX-276 If Custom Setting queue is valid, set Owner to queue
            if (wo.RecordTypeId == fieldServiceRTId && queueId != null) {
                wo.OwnerId = queueId;
            }
        }
        System.debug('WOs updated with Escalated By: ' + woUpdateList);
    }

    // NOTE: Moved updateStandardJobTime() to the SMAX_PS_WorkOrderStandardJobTime class

//  /** 1/8/21 ITSVMX-225 Standard Job Time Automation
//    * On creation of a Work Order, or when the Order Type or Installed Product are changed, the system should
//    * automatically update the Service Duration and a new “Standard Job Time” field by finding a corresponding
//    * record in the SVMX_PS_Standard_Job_Time__c object.
//  */
//  public static void updateStandardJobTime(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {
//
//      List<SVMXC__Service_Order__c> woUpdateList = new List<SVMXC__Service_Order__c>();
//      Map<Id, String> externalIdMap = new Map<Id, String>();
//      Map<String, Decimal> externalIdToStandardJobTime = new Map<String, Decimal>();
//
//      //Get list of Work Orders to update and ExternalId Map
//      for (SVMXC__Service_Order__c wo :woList) {
//          SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
//
//          if (old == null || (old != null && wo.SVMXC__Order_Type__c != old.SVMXC__Order_Type__c)
//                  || (old != null && wo.SVMXC__Component__c != old.SVMXC__Component__c)) {
//
//              woUpdateList.add(wo);
//              // 3/8/21 Tony - If Model Series is NULL set it to '(Empty)' so it will match the Standard Job Times
//              String modelSeries = (wo.SMAX_PS_ModelSeries__c == null) ? '(Empty)' : wo.SMAX_PS_ModelSeries__c;
//              externalIdMap.put(wo.Id, wo.SVMXC__Order_Type__c + '-' + wo.SMAX_PS_IP_Product_Line__c + '-' + modelSeries);
//          }
//      }
//      System.debug('woUpdateList: ' + woUpdateList);
//
//      if (woUpdateList.size() <=0 ) return;
//
//      // Get list of Standard Job Times for the Work Orders we are updating
//      List<SVMX_PS_Standard_Job_Time__c> standardJobTimes = [
//              SELECT  Id, SVMX_PS_External_ID__c, SVMX_PS_Product_Line__c, SVMX_PS_Model_Series__c,
//                      SVMX_PS_Order_Type__c, SVMX_PS_Standard_Duration__c
//              FROM SVMX_PS_Standard_Job_Time__c
//              WHERE SVMX_PS_External_ID__c IN :externalIdMap.values()
//      ];
//      System.debug('externalIdMap.values(): ' + externalIdMap.values());
//      System.debug('standardJobTimes: ' + standardJobTimes);
//
//      if (standardJobTimes.size() <= 0) {
//          System.debug('No matching Standard Job Time record was found for External Id: ' + externalIdMap.values());
//          return;
//      }
//
//      // Get map of External Ids to Standard Job Time
//      for (SVMX_PS_Standard_Job_Time__c standardJobTime :standardJobTimes) {
//
//          externalIdToStandardJobTime.put(standardJobTime.SVMX_PS_External_ID__c, standardJobTime.SVMX_PS_Standard_Duration__c);
//      }
//      System.debug('externalIdToStandardJobTime: ' + externalIdToStandardJobTime);
//
//      // Update the Standard Job Time and Service Duration
//      for (SVMXC__Service_Order__c wo :woUpdateList) {
//
//          String externalId = externalIdMap.get(wo.Id);
//          Decimal standardJobTime = externalIdToStandardJobTime.get(externalId);
//
//          if (externalId != null && standardJobTime != null) {
//              wo.SVMXC__Service_Duration__c = standardJobTime * 60 * 60; // 2/2/21 tony - this needs to be in seconds
//              wo.SVMXC__SM_Estimated_Duration__c = standardJobTime * 60; // 2/2/21 tony - this needs to be in minutes
//              wo.SVMX_PS_Standard_Job_Time__c = standardJobTime;
//              if (standardJobTime > 8) {
//                  // 3/22/21 Tony - commented the following line because Long Job Scheduling is not working as expected and we have an open ticket with ServiceMax
//                  //wo.SVMXC__SM_Scheduling_Options__c = 'JDM and LJS Enabled';
//              }
//          }
//      }
//      System.debug('Updated WOs: ' + woUpdateList);
//  }

    /** 5/21/21 ITSVMX-461 Trigger to cancel RMA when Depot Repair Work Order is Canceled
      * Cancel any RMA associated to a Work Order with a Record Type of “Depot Repair”.
      * NOTE: Should be called by BeforeUpdate trigger handler event.
    */
    public static void cancelDepotRepairRMA(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.cancelDepotRepairRMA method');
        if (!SMAX_PS_Utility.isActive('Cancel Depot Repair RMA', 'When a Depot Repair Work Order is canceled then cancel the RMA Parts Orders and there Parts Order Lines.'))
            return;

        // Check for Canceled Depot Repair Work Orders and create a set of Ids
        Set<Id> canceledWoIds = new Set<Id>();
        Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair').getRecordTypeId();
        for (SVMXC__Service_Order__c wo :woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (wo.SVMXC__Order_Status__c == 'Canceled'
                    && (old == null || wo.SVMXC__Order_Status__c != old.SVMXC__Order_Status__c)
                    && wo.RecordTypeId == depotRepairRTId) {
                canceledWoIds.add(wo.Id);
            }
        }
        System.debug('canceledWoIds: ' + canceledWoIds);

        if (canceledWoIds.size() == 0) return;

        // 7/30/21 Tony - Refactored this code into a separate method as it's used by more than one method
        cancelRMAPartsOrdersAndLines(canceledWoIds);

    }

    // 7/30/21 Tony - Refactored this code into a separate method as it's used by more than one method
    // Cancel RMA Parts Orders and Parts Lines
    public static void cancelRMAPartsOrdersAndLines(Set<Id> canceledWoIds) {

        // Get the RMA Parts Orders for the canceled Work Orders
        Id rmaPartsOrderRTId = Schema.SObjectType.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByDeveloperName().get('RMA').getRecordTypeId();
        List<SVMXC__RMA_Shipment_Order__c> rmaPartsOrders = [
                SELECT Id, SVMXC__Order_Status__c, SVMXC__Service_Order__c, RecordTypeId
                FROM SVMXC__RMA_Shipment_Order__c
                WHERE SVMXC__Service_Order__c IN :canceledWoIds
                AND RecordTypeId = :rmaPartsOrderRTId
        ];
        System.debug('rmaPartsOrders: ' + rmaPartsOrders);

        // Set the RMA Parts Orders to canceled
        Set<Id> rmaPartsOrderIds = new Set<Id>();
        for (SVMXC__RMA_Shipment_Order__c rmaPartsOrder :rmaPartsOrders) {
            rmaPartsOrder.SVMXC__Order_Status__c = 'Canceled';
            rmaPartsOrderIds.add(rmaPartsOrder.Id);
        }
        update rmaPartsOrders;

        // Get the RMA Parts Order Lines for the canceled RMA Parts Orders
        Id rmaPartsOrderLineRTId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByDeveloperName().get('RMA').getRecordTypeId();
        List<SVMXC__RMA_Shipment_Line__c> rmaPartsOrderLines = [
                SELECT Id, SVMXC__Line_Status__c, SVMXC__RMA_Shipment_Order__c, RecordTypeId
                FROM SVMXC__RMA_Shipment_Line__c
                WHERE SVMXC__RMA_Shipment_Order__c IN :rmaPartsOrderIds
                AND RecordTypeId = :rmaPartsOrderLineRTId
        ];
        System.debug('rmaPartsOrderLines: ' + rmaPartsOrderLines);

        // Set the RMA Parts Orders Lines to canceled
        for (SVMXC__RMA_Shipment_Line__c rmaPartsOrderLine :rmaPartsOrderLines) {
            rmaPartsOrderLine.SVMXC__Line_Status__c = 'Canceled';
        }
        update rmaPartsOrderLines;
    }

    /** 5/26/21 ITSVMX-443 Create WO trigger to update Parent work order to Assigned when Child work order changes to Field Service record type
      * When the Child work order has been assigned to the technician and is ready for repair, that the Parent work order
       * is also assigned to the same technician.
      * NOTE: Should be called by BeforeUpdate trigger handler event.
    */
    public static void assignTechToParentWO(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.dispatchParentFieldServiceWO method');
        if (!SMAX_PS_Utility.isActive('Assign Technician to Parent WO', 'When a Child Field Service WO is Assigned to a Technician we also need to Assign the Parent WO.'))
            return;

        // Check for Assigned Field Service Work Orders and create a set of Ids
        Set<Id> parentWOIds = new Set<Id>();
        List<SVMXC__Service_Order__c> childWOs = new List<SVMXC__Service_Order__c>();
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        for (SVMXC__Service_Order__c wo :woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);
            // 6/3/21 Tony added 'Initializing' as this is what the automation changes it to.
            // if (wo.SVMXC__Order_Status__c == 'Assigned'
            if ((wo.SVMXC__Order_Status__c == 'Assigned' || wo.SVMXC__Order_Status__c == 'Initializing')
                    && wo.RecordTypeId == fieldServiceRTId
                    && (old == null || wo.RecordTypeId != old.RecordTypeId)
                    && wo.SVMX_PS_Parent_Work_Order__c != null) {

                parentWOIds.add(wo.SVMX_PS_Parent_Work_Order__c);
                childWOs.add(wo);
            }
        }
        System.debug('parentWOIds: ' + parentWOIds);

        if (parentWOIds.size() == 0) return;

        // Get the Parent WOs for the Assigned Child Field Service WOs
        List<SVMXC__Service_Order__c> parentWOs = [
                SELECT  Id, OwnerId, SVMXC__Order_Status__c, SVMXC__Group_Member__c, SVMXC__Dispatch_Status__c,
                        SVMXC__Scheduled_Date__c, SVMXC__Scheduled_Date_Time__c, SMAX_PS_TechnicianSalesOrg__c,
                        BD_Service_Time_Hours__c, RecordTypeId, SVMXC__Service_Group__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :parentWOIds
        ];
        System.debug('parentWOs: ' + parentWOs);

        // Set the Parent WO fields so that it is Assigned
        for (SVMXC__Service_Order__c childWO :childWOs) {
            for (SVMXC__Service_Order__c parentWO :parentWOs) {
                if (childWO.SVMX_PS_Parent_Work_Order__c == parentWO.Id) {
                    parentWO.SVMXC__Order_Status__c = 'Assigned';
//                  parentWO.SVMXC__Scheduled_Date_Time__c = childWO.SVMXC__Scheduled_Date_Time__c;
                    parentWO.OwnerId = childWO.OwnerId;
                    parentWO.SVMXC__Group_Member__c = childWO.SVMXC__Group_Member__c;
                    parentWO.SVMXC__Service_Group__c = childWO.SVMXC__Service_Group__c;
                }
            }
        }
        update parentWOs;
    }


    /** 7/30/21 ITSVMX-507 Perten 2.0 Phase 2 Escalate from Depot to regular WO
      * When a work order record type changes from Depot Repair to Field Service then we cancel all the RMA's associated to the work order
      * NOTE: Should be called by AfterUpdate trigger handler event.
    */
    public static void cancelRMAsOnFieldServiceWOs(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.cancelRMAsOnFieldServiceWOs method');
        if (!SMAX_PS_Utility.isActive('Cancel RMAs on Field Service WO', 'Cancel RMAs when WO record type changes from Depot Repair to Field Service.'))
            return;

        // Check for work orders where record type has changed from Depot Repair to Field Service and create a set of Ids
        Set<Id> woIds = new Set<Id>();
        Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair')?.getRecordTypeId();
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service')?.getRecordTypeId();
        Id badRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Bad_RT')?.getRecordTypeId();
        System.debug('depotRepairRTId: ' + depotRepairRTId + '    fieldServiceRTId: ' + fieldServiceRTId + '    badRTId: ' + badRTId);

        for (SVMXC__Service_Order__c wo :woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            if (old != null && old.RecordTypeId == depotRepairRTId && wo.RecordTypeId == fieldServiceRTId) {

                woIds.add(wo.Id);
            }
        }
        System.debug('Work Order Ids that need RMAs canceled: ' + woIds);

        if (woIds.size() == 0) return;

        // Cancel the RMA records for the work orders
        System.debug('Cancel the RMA records');
        cancelRMAPartsOrdersAndLines(woIds);

    }

    /** 10/4/21 ITSVMX-624 Suggested Parts Automation
      * When a work order is created with a record type of Estimate, Field Service, or Depot Repair OR a work order is
      * updated and the record type changes to Estimate, Field Service, or Depot Repair then we add the suggested lines
      * from the Installed Product's Product.
      * NOTE: Should be called by AfterUpdate trigger handler event.
    */
    public static void addSuggestedParts(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.addSuggestedParts method');
        if (!SMAX_PS_Utility.isActive('Add Suggested Parts to WO', 'Add Suggested Parts to WO when record type changes from Remote to Estimated, Field Service, or Depot Repair.'))
            return;

        System.debug('woList: ' + woList);

        // Check for work orders where record type has changed from Remote to Estimate, Depot Repair, or Field Service and create a set of Ids
        Set<Id> woIds = new Set<Id>();
        Map<Id, String> woIdToOrderType = new Map<Id, String>();
        Id remoteRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote')?.getRecordTypeId();
        Id estimateRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Service_Request')?.getRecordTypeId();
        Id depotRepairRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Depot_Repair')?.getRecordTypeId();
        Id fieldServiceRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service')?.getRecordTypeId();
        System.debug('remoteRTId: ' + remoteRTId + '    estimateRTId: ' + estimateRTId + '    depotRepairRTId: ' + depotRepairRTId + '    fieldServiceRTId: ' + fieldServiceRTId);

        for (SVMXC__Service_Order__c wo :woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            System.debug('wo.RecordTypeId: ' + wo.RecordTypeId);

            // Only run once per transaction for a record type
            if (!SMAX_PS_Utility.isFirstRun('addSuggestedParts' + '-' + wo.Id + '-' + wo.RecordTypeId)) {
                System.debug('Already executed addSuggestedParts ' + wo.Id + '-' + wo.RecordTypeId + ' for this transaction');
                continue;
            }

            //10/19/21 Batch process will create PM Work Orders that will also need to be processed along with any manually created ones
            if ((old == null && (wo.RecordTypeId == estimateRTId || wo.RecordTypeId == depotRepairRTId || wo.RecordTypeId == fieldServiceRTId)) ||
                    ((old != null && old.RecordTypeId != wo.RecordTypeId) && (wo.RecordTypeId == estimateRTId || wo.RecordTypeId == depotRepairRTId || wo.RecordTypeId == fieldServiceRTId))) {

                woIds.add(wo.Id);
                woIdToOrderType.put(wo.Id, wo.SVMXC__Order_Type__c);
            }
        }
        System.debug('Work Order Ids that need Suggested Parts added: ' + woIds);

        if (woIds.isEmpty()) return;

        // Query work orders along with the Order Type and Product
        List<SVMXC__Service_Order__c> woIdsWithOrderTypeAndProduct = [
                SELECT Id, SVMXC__Order_Type__c, SVMXC__Component__r.SVMXC__Product__c, SVMXC__Product__c, SMAX_PS_SalesOrg__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :woIds
        ];

        // Get the set of Products and Order Types
        Set<Id> prodIds = new Set<Id>();
        Set<String> orderTypes = new Set<String>();
        Set<String> salesOrgs = new Set<String>();
        for (SVMXC__Service_Order__c wo :woIdsWithOrderTypeAndProduct) {
            prodIds.add(wo.SVMXC__Component__r.SVMXC__Product__c);
            orderTypes.add(wo.SVMXC__Order_Type__c);
            salesOrgs.add(wo.SMAX_PS_SalesOrg__c);
        }
        System.debug('prodIds: ' + prodIds);
        System.debug('orderTypes: ' + orderTypes);
        System.debug('salesOrgs: ' + salesOrgs);

        // Get the Suggested Parts
        Set<Id> partIds = new Set<Id>();
        List<BD_Suggested_Part__c> suggestedParts = [
                SELECT Id, BD_Product__c, BD_Order_Type__c, BD_Is_Kit__c, BD_Order_Qty__c, BD_Suggested_Part__c, BD_Is_Essential__c,
                        // 1/10/22 ITSVMX-624 Tony - Added Part Number and Description per request
                        BD_Suggested_Part__r.Partnum__c, BD_Suggested_Part__r.Description
                FROM BD_Suggested_Part__c
                WHERE BD_Product__c IN :prodIds
                AND BD_Order_Type__c IN :orderTypes
        ];
        System.debug('suggestedParts: ' + suggestedParts);

        for (BD_Suggested_Part__c suggestion : suggestedParts) {
            partIds.add(suggestion.BD_Suggested_Part__c);
        }

        // Get the Product Sales (Sales Orgs) for the suggested parts
        // FRANK: Limit by Sales Orgs AND Suggested Parts Ids
        List<SMAX_PS_ProductSales__c> productSales = [
                SELECT Id, SMAX_PS_Product__c, SMAX_PS_SalesOrg__c
                FROM SMAX_PS_ProductSales__c
                WHERE SMAX_PS_Product__c IN :partIds AND SMAX_PS_SalesOrg__c IN :salesOrgs
        ];
        System.debug('productSales: ' + productSales);

        Set<String> productSalesOrgs = new Set<String>();
        for (SMAX_PS_ProductSales__c productSale :productSales) {
            productSalesOrgs.add(productSale.SMAX_PS_Product__c + '-' + productSale.SMAX_PS_SalesOrg__c);
        }
        System.debug('productSalesOrgs: ' + productSalesOrgs);

        // Get the current list of Suggested Parts for these work orders so we can exclude them when we create our new lines
        Id suggestedRTId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Suggested')?.getRecordTypeId();
        System.debug('suggestedRTId: ' + suggestedRTId);
        List<SVMXC__Service_Order_Line__c> existingSuggestedPartsWDLs = [
                SELECT  Id, SVMXC__Service_Order__c, SVMXC__Product__c, SVMXC__Actual_Quantity2__c,
                        SVMX_PS_Order_Qty__c, SVMX_PS_Order_Type__c
                FROM SVMXC__Service_Order_Line__c
                WHERE SVMXC__Service_Order__c IN :woIds
                AND RecordTypeId = :suggestedRTId
        ];
        System.debug('existingSuggestedPartsWDLs: ' + existingSuggestedPartsWDLs);

        // Create a Set of existing suggested parts WDLs keys.  eg. 'part' + '-' + 'order type' + '-' + 'work order Id'
        Set<String> existingSuggestedPartsWDLsKeys = new Set<String>();
        for (SVMXC__Service_Order_Line__c existingSuggestedPartsWDL :existingSuggestedPartsWDLs) {
            String key = existingSuggestedPartsWDL.SVMXC__Product__c + '-' + existingSuggestedPartsWDL.SVMX_PS_Order_Type__c + '-' + existingSuggestedPartsWDL.SVMXC__Service_Order__c;
            existingSuggestedPartsWDLsKeys.add(key);
        }

        // Create new Work Detail Lines for the valid Suggested Parts
        List<SVMXC__Service_Order_Line__c> suggestedPartsWDLs = new List<SVMXC__Service_Order_Line__c>();
        for (BD_Suggested_Part__c suggestedPart :suggestedParts) {

            for (SVMXC__Service_Order__c wo :woIdsWithOrderTypeAndProduct) {

                // 10/27/21 Added a check to see if the suggested part should be included for this Sales Org by looking at the Product Sales orgs
                System.debug('suggestedPart.BD_Suggested_Part__c: ' + suggestedPart.BD_Suggested_Part__c + '    wo.SMAX_PS_SalesOrg__c: ' + wo.SMAX_PS_SalesOrg__c);
                if (suggestedPart.BD_Product__c == wo.SVMXC__Component__r.SVMXC__Product__c
                        && suggestedPart.BD_Order_Type__c == wo.SVMXC__Order_Type__c
                        && productSalesOrgs.contains(suggestedPart.BD_Suggested_Part__c + '-' + wo.SMAX_PS_SalesOrg__c)) {

                    // If this suggested part has already been added to the Work Order then don't create a new one
                    String key = suggestedPart.BD_Suggested_Part__c + '-' + suggestedPart.BD_Order_Type__c + '-' + wo.Id;
                    System.debug('key: ' + key);
                    if (existingSuggestedPartsWDLsKeys.contains(key)) {
                        System.debug('Suggested Part already exists on the Work Order: ' + suggestedPart);
                        continue;
                    }

                    // FRANK: We should not limit this to non-kits
                    //if (suggestedPart.BD_Is_Kit__c == false) {
                        SVMXC__Service_Order_Line__c suggestedPartsWDL = new SVMXC__Service_Order_Line__c();
                        suggestedPartsWDL.RecordTypeId = suggestedRTId;
                        suggestedPartsWDL.SVMXC__Product__c = suggestedPart.BD_Suggested_Part__c;
                        suggestedPartsWDL.SVMX_PS_Suggested_Part__c = suggestedPart.Id;
                        suggestedPartsWDL.SVMXC__Service_Order__c = wo.Id;
                        suggestedPartsWDL.SVMXC__Actual_Quantity2__c = suggestedPart.BD_Order_Qty__c;
                        suggestedPartsWDL.SVMX_PS_Order_Type__c = suggestedPart.BD_Order_Type__c;
                        suggestedPartsWDL.SVMX_PS_Is_Essential__c = suggestedPart.BD_Is_Essential__c;

                        // 1/10/22 ITSVMX-624 Tony - Per request adding the Part Number and Part Description
                        suggestedPartsWDL.SMAX_PS_Part_Number__c = suggestedPart.BD_Suggested_Part__r.Partnum__c;
                        suggestedPartsWDL.SMAX_PS_Material_Part_Description__c = suggestedPart.BD_Suggested_Part__r.Description;

                        suggestedPartsWDLs.add(suggestedPartsWDL);
                    //}
                }
            }
        }

        System.debug('Inserting Suggested Parts Work Detail Lines: ' + suggestedPartsWDLs);
        insert suggestedPartsWDLs;

        System.debug('Exiting SMAX_PS_WorkOrderManager.addSuggestedParts method');
    }


    /** 10/4/21 ITSVMX-624 Suggested Parts Automation
      * When a work order Check Stock flag is changed to True then we get the Technician's Trunk Stock and all
      * Technician's Truck Stock for the same Maintenance Plant.  We then populate these values into the Technician Trunk
      * Stock QTY and Plant QTY fields respectively in the "suggested" work detail lines. Finally, we set the Check Stock flag back to false.
      * NOTE: Should be called by BeforeUpdate trigger handler event.
    */
    public static void checkStockForSuggestedParts(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.checkStockForSuggestedParts method');
        if (!SMAX_PS_Utility.isActive('Check Stock for Suggested Parts', 'Check Technician Trunk Stock and Plant Stock for Suggested Parts.'))
            return;

        // Get Work Orders that have the Check Stock flag set to TRUE
        Map<Id, SVMXC__Service_Order__c> checkStockMap = new Map<Id, SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo :woList) {
            if (wo.SVMX_PS_Check_Stock__c == true) {
                checkStockMap.put(wo.Id, wo);
            }
        }
        System.debug('checkStockMap: ' + checkStockMap);

        if (checkStockMap.isEmpty()) {
            System.debug('Exiting SMAX_PS_WorkOrderManager.checkStockForSuggestedParts method as there are no work orders with Check Stock set to true');
            return;
        }

        // Get the Location Ids for the list of work orders that have Check Stock set to TRUE
        List<SVMXC__Service_Order__c> checkStockList = [
                SELECT  Id, SVMXC__Group_Member__c, SVMXC__Group_Member__r.SVMXC__Inventory_Location__c,
                        SVMXC__Group_Member__r.SMAX_PS_Plant__c, SMAX_PS_SAP_Maintenance_Plant__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :checkStockMap.keySet()
        ];
        System.debug('checkStockMap.keySet(): ' + checkStockMap.keySet());
        System.debug('checkStockList: ' + checkStockList);

        // Get Maps of the Technician to their Location, Technician Id to Work Order Id, and Work Order Id to Plant
        Map<Id, Id> techIdToLocationIdMap = new Map<Id, Id>();
        Map<Id, Id> techIdToWoIdMap = new Map<Id, Id>();
        Map<Id, String> woIdToPlantMap = new Map<Id, String>();
        for (SVMXC__Service_Order__c wo :checkStockList) {
            Id techId = wo.SVMXC__Group_Member__c;
            Id locId = wo.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c;
            if (techId != null && locId != null) {
                techIdToLocationIdMap.put(techId, locId);
                woIdToPlantMap.put(wo.Id, wo.SVMXC__Group_Member__r.SMAX_PS_Plant__c);
                techIdToWoIdMap.put(wo.SVMXC__Group_Member__c, wo.Id);
            }
        }
        System.debug('techIdToLocationIdMap: ' + techIdToLocationIdMap);
        if (techIdToLocationIdMap.isEmpty()) {
            System.debug('Exiting SMAX_PS_WorkOrderManager.checkStockForSuggestedParts method as there are no technicians with a location');
            return;
        }

        // Get the Suggested Parts for the Work Orders with the Check Stock set to TRUE
        Id suggestedRTId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Suggested')?.getRecordTypeId();
        List<SVMXC__Service_Order_Line__c> suggestedParts = [
                SELECT  Id, RecordTypeId, SVMXC__Service_Order__c, SVMXC__Product__c, SVMX_PS_Order_Type__c,
                        SVMXC__Actual_Quantity2__c, SVMX_PS_Technician_Trunk_Stock_Qty__c, SVMX_PS_Plant_Qty__c
                FROM SVMXC__Service_Order_Line__c
                WHERE RecordTypeId = :suggestedRTId
                AND SVMXC__Service_Order__c IN :checkStockMap.keySet()
        ];
        System.debug('suggestedRTId: ' + suggestedRTId);
        System.debug('suggestedParts: ' + suggestedParts);

        // Create Map of Work Order Id to Suggested Part
        Map<Id, SVMXC__Service_Order_Line__c> woIdToSuggestedPartMap = new Map<Id, SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c suggestedPart :suggestedParts) {
            woIdToSuggestedPartMap.put(suggestedPart.SVMXC__Service_Order__c, suggestedPart);
        }

        // Get ProductIds
        Set<Id> productIds = new Set<Id>();
        for (SVMXC__Service_Order_Line__c suggestedPart :suggestedParts) {
            productIds.add(suggestedPart.SVMXC__Product__c);
        }
        System.debug('productIds: ' + productIds);
        System.debug('techIdToLocationIdMap.values(): ' + techIdToLocationIdMap.values());

        // Get the Technician's Trunk Stock for the Suggested Parts
        List<SVMXC__Product_Stock__c> techTrunkStockList = [
                SELECT Id, SVMXC__Product__c, SVMXC__Location__c, SVMXC__Status__c, SVMX_PS_Location_Code__c, SVMXC__Available_Qty__c
                FROM SVMXC__Product_Stock__c
                WHERE SVMXC__Product__c IN :productIds
                AND SVMXC__Location__c IN:techIdToLocationIdMap.values()
                AND SVMXC__Status__c = 'Available'
        ];
        System.debug('techTrunkStockList: ' + techTrunkStockList);

        // Get all Technician's Trunk Stock in the Plant for the Suggested Parts
        List<SVMXC__Product_Stock__c> techLocStockList = [
                SELECT Id, SVMXC__Product__c, SVMXC__Location__c, SMAX_PS_Maintenance_Plant__c, SVMXC__Status__c, SVMX_PS_Location_Code__c, SVMXC__Available_Qty__c
                FROM SVMXC__Product_Stock__c
                WHERE SVMXC__Product__c IN :productIds
                AND SMAX_PS_Maintenance_Plant__c IN:woIdToPlantMap.values()
                AND SVMXC__Status__c = 'Available'
        ];
        System.debug('techLocStockList: ' + techLocStockList);


        // Clear any existing Technician Trunk Stock QTY or Plant QTY from the Suggested Parts before adding new values to them
        for (SVMXC__Service_Order_Line__c suggestedPart :suggestedParts) {
            suggestedPart.SVMX_PS_Technician_Trunk_Stock_Qty__c = 0;
            suggestedPart.SVMX_PS_Plant_Qty__c = 0;
        }

        // Populate the Technician Trunk Stock QTY and Plant QTY on the Suggested Parts records
        for (SVMXC__Service_Order__c wo :checkStockList) {
            for (SVMXC__Service_Order_Line__c suggestedPart :suggestedParts) {

                System.debug('Work Order: [' + wo.Id + ']  Suggested Part: [' + suggestedPart.SVMXC__Product__c +']  Plant: [' + wo.SVMXC__Group_Member__r.SMAX_PS_Plant__c + ']');

                for (SVMXC__Product_Stock__c techTrunkStock :techTrunkStockList) {

                    if (wo.Id == suggestedPart.SVMXC__Service_Order__c && techTrunkStock.SVMXC__Location__c == techIdToLocationIdMap.get(wo.SVMXC__Group_Member__c)
                            && suggestedPart.SVMXC__Product__c == techTrunkStock.SVMXC__Product__c) {

                        System.debug('techTrunkStock.SVMXC__Available_Qty__c: ' + techTrunkStock.SVMXC__Available_Qty__c);
                        suggestedPart.SVMX_PS_Technician_Trunk_Stock_Qty__c += techTrunkStock.SVMXC__Available_Qty__c;
                    }
                }

                for (SVMXC__Product_Stock__c techLocStock :techLocStockList) {

                    if (wo.Id == suggestedPart.SVMXC__Service_Order__c && techLocStock.SMAX_PS_Maintenance_Plant__c == wo.SVMXC__Group_Member__r.SMAX_PS_Plant__c
                            && suggestedPart.SVMXC__Product__c == techLocStock.SVMXC__Product__c) {

                        System.debug('techLocStock.SVMXC__Available_Qty__c: ' + techLocStock.SVMXC__Available_Qty__c);
                        suggestedPart.SVMX_PS_Plant_Qty__c += techLocStock.SVMXC__Available_Qty__c;
                    }
                }

                System.debug('Total Technician Trunk Stock QTY: ' + suggestedPart.SVMX_PS_Technician_Trunk_Stock_Qty__c);
                System.debug('Total Plant Stock QTY: ' + suggestedPart.SVMX_PS_Plant_Qty__c);
            }
        }
        System.debug('Updating suggestedParts: ' + suggestedParts);
        update suggestedParts;

        // Set the Check Stock flag to FALSE for the processed Work Order records
        for (SVMXC__Service_Order__c updateCheckStockWOs :checkStockMap.values()) {
            updateCheckStockWOs.SVMX_PS_Check_Stock__c = false;
        }

        System.debug('Exiting SMAX_PS_WorkOrderManager.checkStockForSuggestedParts method');
    }


    /** 12/11/2021 Tony ITSVMX-607 Auto-entitle RWO, build in reporting capacity on SLA terms in connection to RWO
      * When a Remote work order is created, update the Potential Entitlement field.
      * The Potential Entitlement field will be populated by finding all active (defined by Start and End Dates) contract entitlements
      * for the Installed Product on the Remote Work Order.  The code will concatenate all active contract entitlements
      * as a comma-separated list and populate the new Potential Entitlement field.
      * NOTE: Should be called by BeforeInsert trigger handler event.
    */
    public static void updatePotentialEntitlement(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap) {

        System.debug('Entering SMAX_PS_WorkOrderManager.updatePotentialEntitlement method');
        if (!SMAX_PS_Utility.isActive('Update Potential Entitlement', 'Get the active contract entitlements from the Installed Product and put then in the Potential Entitlement field.'))
            return;

        // Get the Remote Work Orders that have Installed Products
        Id remoteRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();
        Set<Id> ipIds = new Set<Id>();
        Map<Id, SVMXC__Service_Order__c> woToProcessMap = new Map<Id, SVMXC__Service_Order__c>();
        for (SVMXC__Service_Order__c wo : woList) {
            if (wo.RecordTypeId == remoteRTId && wo.SVMXC__Component__c != null) {
                woToProcessMap.put(wo.Id, wo);
                ipIds.add(wo.SVMXC__Component__c);
            }
        }
        System.debug('woToProcessMap: ' + woToProcessMap);

        if (woToProcessMap.isEmpty()) {
            System.debug('Exiting SMAX_PS_WorkOrderManager.updatePotentialEntitlement method as there are no Remote work orders with an IP');
            return;
        }

        // Get the Installed Products for these work orders
        List<SVMXC__Installed_Product__c> ips = [
                SELECT Id, Name, SVMXC__Service_Contract__c, SVMXC__Service_Contract_Line__c
                FROM SVMXC__Installed_Product__c
                WHERE Id IN :ipIds
        ];
        System.debug('ips: ' + ips);

        // Use the Contract Products to get the Contract Item info associated to this Installed Product
        List<SVMXC__Service_Contract_Products__c> contractProducts = [
                SELECT Id, Name, SMAX_PS_SLA_Terms_Notes__c, SVMXC__Service_Contract__c, SVMX_PS_Contract_Active__c,
                        SVMXC__Service_Contract__r.BD_Item_Qty__c, SVMXC__Service_Contract__r.BD_Item_Qty_Remaining__c,
                        SVMXC__Installed_Product__r.Name, SVMXC__Service_Contract__r.SVMXC__Start_Date__c,
                        SVMXC__Service_Contract__r.SVMXC__End_Date__c, SVMXC__Service_Contract__r.Name,
                        SVMXC__Service_Contract__r.BD_Remote_Hours_Remaining__c, SVMXC__Installed_Product__c,
                        SVMXC__Installed_Product__r.SMAX_PS_SalesOrg__c
                FROM SVMXC__Service_Contract_Products__c
                WHERE SVMXC__Installed_Product__c IN :ipIds
        ];
        System.debug('contractProducts: ' + contractProducts);

        // Get the active contract entitlements from the contract products
        Date today = Date.today();
        for (SVMXC__Service_Contract_Products__c contractProduct :contractProducts) {
            for (SVMXC__Installed_Product__c ip :ips) {
                for (SVMXC__Service_Order__c wo :woToProcessMap.values()) {

                    // Only do this when current date is in the active range
                    if (contractProduct.SVMXC__Service_Contract__r.SVMXC__Start_Date__c <= today
                            && contractProduct.SVMXC__Service_Contract__r.SVMXC__End_Date__c >= today
                            && contractProduct.SVMXC__Installed_Product__c == ip.Id
                            && wo.SVMXC__Component__c == ip.Id) {
                        
                        if (wo.SMAX_PS_Potential_Entitlement__c == null) {
                            wo.SMAX_PS_Potential_Entitlement__c = '';
                        }

                        String newPotentialEntitlement = wo.SMAX_PS_Potential_Entitlement__c + contractProduct.SMAX_PS_SLA_Terms_Notes__c + ',';

                        if (newPotentialEntitlement.length() > 255) {
                            newPotentialEntitlement = newPotentialEntitlement.left(252) + '...';
                        }

                        // Update the Potential Entitlement with this additional SLA Term Notes
                        wo.SMAX_PS_Potential_Entitlement__c = newPotentialEntitlement;
                    }
                }
            }
        }

        System.debug('Exiting SMAX_PS_WorkOrderManager.updatePotentialEntitlement method');
    }

    // 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
    // NOTE: Should be called on before insert and before update
    public static void refurbishedPartsAllowed(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        if (!SMAX_PS_Utility.isActive('Work Order Refurbished Parts Allowed', 'If Refurbished Parts are allowed then set the checkbox fields.'))
            return;

        System.debug('Entering SMAX_PS_WorkOrderManager.refurbishedPartsAllowed');

        Set<Id> refurbishIpIds = new Set<Id>();
        Set<Id> allServiceContractIds = new Set<Id>();
        Set<Id> contractEntitlementIds = new Set<Id>();
        List<SVMXC__Service_Order__c> refurbishWorkOrders = new List<SVMXC__Service_Order__c>();

        // Get the list of work orders that might qualify for Refurbished Parts
        for (SVMXC__Service_Order__c wo :woList) {
            SVMXC__Service_Order__c old = (oldMap == null) ? null : oldMap.get(wo.Id);

            System.debug('wo.SMAX_PS_ContractItem__c: ' + wo.SMAX_PS_ContractItem__c);

            if (wo.BD_Refurbished_Parts_Allowed__c == false
                    && ((old == null && wo.SVMXC__Component__c != null && wo.SVMXC__Billing_Type__c == 'Internal')
                    || (old == null && wo.SVMXC__Component__c != null && wo.SVMXC__Billing_Type__c != 'Internal' && wo.SMAX_PS_ContractItem__c != null)
                    || (old != null && (wo.SVMXC__Component__c != old.SVMXC__Component__c || wo.SVMXC__Billing_Type__c != old.SVMXC__Billing_Type__c || wo.SMAX_PS_ContractItem__c != old.SMAX_PS_ContractItem__c)))) {

                System.debug('Found a Work Order that might qualify to use Refurbished Parts: ' + wo);
                refurbishWorkOrders.add(wo);
                refurbishIpIds.add(wo.SVMXC__Component__c);
                allServiceContractIds.add(wo.SMAX_PS_ContractItem__c);
                contractEntitlementIds.add(wo.SMAX_PS_ContractEntitlement__c);
            }
        }
        System.debug('allServiceContractIds: ' + allServiceContractIds.size() + ' ' + allServiceContractIds);

        if (refurbishWorkOrders.isEmpty()) return;

        // Get the Service Contract Start and End Dates
        List<SVMXC__Service_Contract__c> activeServiceContracts = [
                SELECT Id, SVMXC__Start_Date__c, SVMXC__End_Date__c
                FROM SVMXC__Service_Contract__c
                WHERE Id IN: allServiceContractIds
                AND SVMXC__Start_Date__c <= :Date.today()
                AND SVMXC__End_Date__c >= :Date.today()
        ];
        System.debug('activeServiceContracts: ' + activeServiceContracts.size() + ' ' + activeServiceContracts);

        // Get a list of active Service Contract Ids
        Set<Id> activeServiceContractIds = new Set<Id>();
        for (SVMXC__Service_Contract__c activeServiceContract :activeServiceContracts) {

            activeServiceContractIds.add(activeServiceContract.Id);
        }
        System.debug('activeServiceContractIds: ' + activeServiceContractIds.size() + ' ' + activeServiceContractIds);

        // Get Installed Products with their Medical Device checkbox
        List<SVMXC__Installed_Product__c> installedProductMedDeviceList = [
                SELECT Id, SMAX_PS_IsMedicalDevice__c
                FROM SVMXC__Installed_Product__c
                WHERE Id IN :refurbishIpIds
        ];

        // Create Installed Product Id to Medical Device mapping
        Map<Id, Boolean> IpIdToMedDeviceMap = new Map<Id, Boolean>();
        for (SVMXC__Installed_Product__c ip :installedProductMedDeviceList) {
            IpIdToMedDeviceMap.put(ip.Id, ip.SMAX_PS_IsMedicalDevice__c);
        }

        // Get the Service Contract services Parts Discount Covered
        List<SVMXC__Service_Contract_Services__c> serviceContractServicesList = [
                SELECT Id, Name, SVMXC__Service_Contract__c, SVMXC__Parts_Discount_Covered__c, SMAX_PS_ServicePartsDiscountCovered__c
                FROM SVMXC__Service_Contract_Services__c
                WHERE SVMXC__Service_Contract__c IN :activeServiceContractIds
//              AND SVMXC__Parts_Discount_Covered__c = 100.00 //TODO Which one should we use?
                AND SMAX_PS_ServicePartsDiscountCovered__c = 100.00
                AND Id IN :contractEntitlementIds
        ];
        System.debug('serviceContractServicesList: ' + serviceContractServicesList.size() + ' ' + serviceContractServicesList);

        // Create the Contract Entitlement Id to Service Parts Discount Covered mapping
        Map<Id, Decimal> contractEntitlementIdToPartsDiscountMap = new Map<Id, Decimal>();
        for (SVMXC__Service_Contract_Services__c serviceContractServices :serviceContractServicesList) {
            contractEntitlementIdToPartsDiscountMap.put(serviceContractServices.Id, serviceContractServices.SMAX_PS_ServicePartsDiscountCovered__c);
        }

        // Update work orders that qualify to use refurbished parts
        for (SVMXC__Service_Order__c wo :refurbishWorkOrders) {

            System.debug('wo.SVMXC__Component__c: ' + wo.SVMXC__Component__c);
            System.debug('contractEntitlementIdToPartsDiscountMap: ' + contractEntitlementIdToPartsDiscountMap.get(wo.SMAX_PS_ContractEntitlement__c));

            if (IpIdToMedDeviceMap.get(wo.SVMXC__Component__c) == false
                    && (wo.SVMXC__Billing_Type__c == 'Internal' || contractEntitlementIdToPartsDiscountMap.get(wo.SMAX_PS_ContractEntitlement__c) == 100.00)) {

                wo.BD_Refurbished_Parts_Allowed__c = true;
                wo.BD_Use_Refurbished_Parts__c = true;
                System.debug('Updated BD_Refurbished_Parts_Allowed__c and BD_Use_Refurbished_Parts__c to TRUE');
            }
        }
        System.debug('refurbishWorkOrders after updates: ' + refurbishWorkOrders.size() + ' ' + refurbishWorkOrders);

        System.debug('Exiting SMAX_PS_WorkOrderManager.refurbishedPartsAllowed');
    }

    // 08/10/2023 ITSVMX-1227 Update Work Order Default Consumed From Location from either Technician or Shared Location
    // NOTE: Should be called by BeforeInsert and BeforeUpdate
    public static void updateWorkOrderDefaultConsumedFromLocation(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap){

        System.debug('Entering SMAX_PS_WorkOrderManager.updateWorkOrderDefaultConsumedFromLocation method');

        Set<Id> workOrderIds = new Set<Id>();

        // Get the Word Order records that we need to process
        Set<SVMXC__Service_Order__c> workOrdersToProcess = new Set<SVMXC__Service_Order__c>();
        Map<Id, Id> workOrderIdToNewTechIdMap = new Map<Id, Id>();
        for(SVMXC__Service_Order__c workOrder :woList) {

            SVMXC__Service_Order__c old = oldMap == null ? null : oldMap.get(workOrder.Id);
            // 2023-09-14 Only run this logic if Tech is NOT null
            if (workOrder.SVMXC__Group_Member__c != null &&
                (old == null
                    || workOrder.SVMXC__Group_Member__c != old.SVMXC__Group_Member__c
                    || workOrder.SMAX_PS_Default_Consumed_From_Location__c == null)) {

                workOrdersToProcess.add(workOrder);
                workOrderIds.add(workOrder.Id);
                workOrderIdToNewTechIdMap.put(workOrder.Id, workOrder.SVMXC__Group_Member__c);

            }
        }
        System.debug('workOrdersToProcess: ' + workOrdersToProcess.size() + ' ' + workOrdersToProcess);
        System.debug('workOrderIds: ' + workOrderIds.size() + ' ' + workOrderIds);
        System.debug('workOrderIdToNewTechIdMap: ' + workOrderIdToNewTechIdMap.size() + ' ' + workOrderIdToNewTechIdMap);

        if (workOrdersToProcess.isEmpty()) return;

        // Get Technician Map
        Map<Id, SVMXC__Service_Group_Members__c> technicianMap = new Map<Id, SVMXC__Service_Group_Members__c>([
                SELECT Id, SMAX_PS_Plant__c, SMAX_PS_Work_Center__c, SVMXC__Inventory_Location__c
                FROM SVMXC__Service_Group_Members__c
                WHERE Id IN :workOrderIdToNewTechIdMap.values()
        ]);
        System.debug('technicianMap: ' + technicianMap.size() + ' ' + technicianMap);

        // Create a Work Order Id to Technician Map
        Map<Id, SVMXC__Service_Group_Members__c> workOrderIdToTechnicianMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        for(Id workOrderId :workOrderIdToNewTechIdMap.keySet()) {

            workOrderIdToTechnicianMap.put(workOrderId, technicianMap.get(workOrderIdToNewTechIdMap.get(workOrderId)));

        }
        System.debug('workOrderIdToTechnicianMap: ' + workOrderIdToTechnicianMap.size() + ' ' + workOrderIdToTechnicianMap);

        // Get the Service Debrief Settings
        Map<String, SMAX_PS_Service_Debrief_Settings__mdt> serviceDebriefSettingsMap = SMAX_PS_Service_Debrief_Settings__mdt.getAll();

        // Get Shared Location External Ids
        Set<String> sharedLocationExternalIds = new Set<String>();
        for(SVMXC__Service_Order__c workOrder :workOrdersToProcess) {

            System.debug('workOrderIdToTechnicianMap.get(workOrder.Id)?.SMAX_PS_Plant__c: ' + workOrderIdToTechnicianMap.get(workOrder.Id)?.SMAX_PS_Plant__c);
            System.debug('workOrder?.SMAX_PS_SAP_Maintenance_Plant__c: ' + workOrder?.SMAX_PS_SAP_Maintenance_Plant__c);

            if(workOrderIdToTechnicianMap.containsKey(workOrder.Id)
                    && workOrderIdToTechnicianMap.get(workOrder.Id)?.SMAX_PS_Plant__c != null
                    && workOrder?.SMAX_PS_SAP_Maintenance_Plant__c != null){

                SMAX_PS_Service_Debrief_Settings__mdt debriefMDT = serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c);
                if (debriefMDT != null) {
                    String locationCodeFromMDT = debriefMDT.SMAX_PS_Shared_Location_Code__c;
                    System.debug('locationCodeFromMDT: ' + locationCodeFromMDT);
                    System.debug('workOrder.SMAX_PS_SAP_Maintenance_Plant__c: ' + workOrder.SMAX_PS_SAP_Maintenance_Plant__c);
                    sharedLocationExternalIds.add(workOrder.SMAX_PS_SAP_Maintenance_Plant__c + locationCodeFromMDT);
                }
            }
        }
        System.debug('sharedLocationExternalIds: ' + sharedLocationExternalIds.size() + ' ' + sharedLocationExternalIds);
        // 2023-09-14 Added to avoid null errors when not configured
        if (sharedLocationExternalIds.isEmpty()) {
            return;
        }

        // Get Shared Locations
        List<SVMXC__Site__c> sharedLocations = [
                SELECT Id, SVMX_PS_External_ID__c
                FROM SVMXC__Site__c
                WHERE SVMX_PS_External_ID__c IN :sharedLocationExternalIds
        ];
        System.debug('sharedLocations: ' + sharedLocations.size() + ' ' + sharedLocations);

        // Get External Id to Shared Location Map
        Map<String, SVMXC__Site__c> externalIdToSharedLocationMap = new Map<String, SVMXC__Site__c>();
        for(SVMXC__Site__c sharedLocation :sharedLocations) {

            externalIdToSharedLocationMap.put(sharedLocation.SVMX_PS_External_ID__c, sharedLocation);
        }
        System.debug('externalIdToSharedLocationMap: ' + externalIdToSharedLocationMap.size() + ' ' + externalIdToSharedLocationMap);

        for(SVMXC__Service_Order__c workOrder :workOrdersToProcess){

            SVMXC__Service_Group_Members__c technician = workOrderIdToTechnicianMap.get(workOrder.Id);
            System.debug('technician: ' + technician);
            System.debug('workOrder.SMAX_PS_Owned_By_Company__c: ' + workOrder.SMAX_PS_Owned_By_Company__c);

            // If MDT Shared Parts is enabled for the Work Order Owned By Company then use the Technician record values or the Shared Location record values
            if(workOrder.SMAX_PS_Owned_By_Company__c != null
                    && serviceDebriefSettingsMap.containsKey(workOrder.SMAX_PS_Owned_By_Company__c)
                    && serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c).SMAX_PS_Enable_Shared_Parts__c == true) {

                Id techId = workOrder.SVMXC__Group_Member__c;
                System.debug('techId: ' + techId);

                System.debug('Checking for Enable Shared Parts = true');

                // if the technician is not null and the work order plant is equal to the technician plant then use the Technician record values
                if(techId != null && workOrder.SMAX_PS_SAP_Maintenance_Plant__c == technician?.SMAX_PS_Plant__c){

                    System.debug('technician.SVMXC__Inventory_Location__c: ' + technician?.SVMXC__Inventory_Location__c);
                    workOrder.SMAX_PS_Default_Consumed_From_Location__c = technician?.SVMXC__Inventory_Location__c;
                    System.debug('Set the Work Order Default Consumed From Location to the Technician Inventory Location');

                } else {

                    // if the technician is not null and the work order plant is not equal to the technician plant then use the Shared Location record values
                    System.debug('tech Id: ' + techId);
                    System.debug('workOrder.SVMXC__Group_Member__r.SMAX_PS_Plant__c: ' + workOrder.SVMXC__Group_Member__r.SMAX_PS_Plant__c);
                    System.debug('technician.SMAX_PS_Plant__c: ' + technician?.SMAX_PS_Plant__c);
                    String locationCodeFromMDT = serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c).SMAX_PS_Shared_Location_Code__c;
                    SVMXC__Site__c sharedLocation = externalIdToSharedLocationMap.get(workOrder.SMAX_PS_SAP_Maintenance_Plant__c + locationCodeFromMDT);

                    if(techId != null && sharedLocation != null && workOrder.SMAX_PS_SAP_Maintenance_Plant__c != technician?.SMAX_PS_Plant__c){

                        workOrder.SMAX_PS_Default_Consumed_From_Location__c = sharedLocation.Id;
                        System.debug('Set the Work Order Default Consumed From Location to the Shared Location');

                    }

                    if(techId == null || sharedLocation == null){

                        System.debug('SMAX_PS_WorkOrderManager.updateWorkOrderDefaultConsumedFromLocation() - Error: Technician and/or Shared Location is null');

                    }

                }

            }

            System.debug('Check to see if there is no Service Debrief Setting for this Owned by Company: ' + workOrder.SMAX_PS_Owned_By_Company__c);
            // If MDT Shared Parts is disabled for the Work Order Owned By Company then use the Technician record values
            if(workOrder.SMAX_PS_Owned_By_Company__c != null
                    && (!serviceDebriefSettingsMap.containsKey(workOrder.SMAX_PS_Owned_By_Company__c)
                    || ((serviceDebriefSettingsMap.containsKey(workOrder.SMAX_PS_Owned_By_Company__c) && serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c).SMAX_PS_Enable_Shared_Parts__c == false)
            ))){

                System.debug('There was not Service Debrief Setting or the Enable Shared Parts was set to false');

                Id techId = workOrder.SVMXC__Group_Member__c;
                System.debug('techId: ' + techId);
                System.debug('technician: ' + technician);

                // if the technician is not null and the work order plant is equal to the technician plant then use the Technician record values
                //09/01/2023 It is not necessary for the Plant to be the same on the Work Order and Technician
                //if(techId != null && workOrder.SMAX_PS_SAP_Maintenance_Plant__c == technician.SMAX_PS_Plant__c){
                if(techId != null){

                    workOrder.SMAX_PS_Default_Consumed_From_Location__c = technician.SVMXC__Inventory_Location__c;
                    System.debug('serviceDebriefSettingsMap for this OwnedByCompany does not exit or is False');
                    System.debug('Set the Work Order Default Consumed Location to the Technician Inventory Location');

                }

                if(techId == null){

                    System.debug('SMAX_PS_WorkOrderManager.updateWorkOrderDefaultConsumedFromLocation() - Error: Technician is null');

                }
            }
        }
    }
    
    //Send Email Notification to Contact & CC members
    public static void sendServiceReportWhenWOClosed(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap){
        set<id> woIdSet = new set<id>();
        Map<id,SVMXC__Service_Order__c> woMap = new Map<id,SVMXC__Service_Order__c>();
        list<string> toAddress = new list<String>();
        list<string> ccEmailAddress = new list<String>();
        for(SVMXC__Service_Order__c wo: woList){
            if(oldMap.get(wo.id).SVMXC__Order_Status__c != wo.SVMXC__Order_Status__c && wo.SVMXC__Order_Status__c == 'Closed'){
                if((wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c && wo.SVMX_PS_Contact_Email__c!=null) || (wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c && wo.SVMX_PS_ES_Email_To_Customer__c!=null)){
                    woIdSet.add(wo.id);
                    woMap.put(wo.id, wo);
                    
                    if(wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c && wo.SVMX_PS_Contact_Email__c!=null){
                        toAddress.add(wo.SVMX_PS_Contact_Email__c);
                    }
                    
                    if(wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c && wo.SVMX_PS_ES_Email_To_Customer__c != null){
                        toAddress.add(wo.SVMX_PS_ES_Email_To_Customer__c);
                    }

                    if(wo.SVMX_PS_ES_Cc_Additional_People__c && wo.SVMX_PS_ES_Cc_Email_Additional_People__c !=null){
                        ccEmailAddress.add(wo.SVMX_PS_ES_Cc_Email_Additional_People__c);
                    }

                    if(wo.SVMX_PS_ES_Cc_Current_User__c){
                        ccEmailAddress.add(UserInfo.getUserEmail());
                    }
                }
            }
        }

        if(woIdSet.size()>0){ 
            Map<id,SVMXC__Service_Order__c> cdlMap = new Map<id, SVMXC__Service_Order__c>();
            for(ContentDocumentLink cdl: [SELECT id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: woIdSet order by SystemModstamp desc limit 1]){
                cdlMap.put(cdl.ContentDocumentId, woMap.get(cdl.LinkedEntityId));
            }

            
            if(cdlMap.size()>0){
                for(ContentVersion cv : [ SELECT Id, Title, VersionData, ContentDocumentId, FileExtension FROM ContentVersion WHERE ContentDocumentId IN:cdlMap.keySet() AND IsLatest = true]){
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAddress);
                    if(ccEmailAddress.size()>0){
                        mail.setccAddresses(ccEmailAddress);
                    }
                    mail.setSubject('Service Report');
                    mail.setPlainTextBody('Please find the attached Service Report file for Work Order: '+cdlMap.get(cv.ContentDocumentId).name+'.');

                    // Create attachment
                    Messaging.EmailFileAttachment attachment =
                        new Messaging.EmailFileAttachment();

                    attachment.setFileName(cv.Title + '.' + cv.FileExtension);
                    attachment.setBody(cv.VersionData);

                    mail.setFileAttachments(
                        new Messaging.EmailFileAttachment[] { attachment }
                    );

                    Messaging.sendEmail(
                        new Messaging.SingleEmailMessage[] { mail }
                    );
                }  
            }
        }
    }//End of Method
}
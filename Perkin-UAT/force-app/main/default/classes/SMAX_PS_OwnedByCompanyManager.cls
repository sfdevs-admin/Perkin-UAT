/**
 *  Apex Class for Owned By Company field(s) on identified objects relative to Field Service business Logic.
 *  2022-10-21      Bolt Data - E. Ross       Initial creation for Polaris project implementation.
 *
 *  Updates:
 *  12/02/2022  tony    Switched updateSobjectOwnedByCompany from using Object Label to Object API Name as foreign
 *                      languages were causing issues
 *  01/10/2023  tony    Added clear of variables in updateServiceAlertObject so we don't put the last values into the
 *                      next service alert processed
 *  03/10/2023  tony    Added updateWorkOrderFromUser method for Remote work orders that didn't find a match on IP or Technician
 */
public with sharing class SMAX_PS_OwnedByCompanyManager {
    
    private SMAX_PS_OwnedByCompanyManager() {
    }

    // Calibration Event | Calibration_Event__c
    // Parent: Installed Product
    public static void updateCalibrationEventObject(List<Calibration_Event__c> newList, Map<Id, Calibration_Event__c> oldMap){

        Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>();
        Set<Id> ipIds = new Set<Id>();

        for(Calibration_Event__c ce : newList){

            // Add valid Installed Product Ids (Calibrated_Tool__c) to Id Set for Installed Product Map population
            if(String.IsNotBlank(ce.Calibrated_Tool__c)){
                ipIds.add(ce.Calibrated_Tool__c);
            }
        }

        if(ipIds.size() > 0){

            // populate Installed Product Map
            for(SVMXC__Installed_Product__c ip :
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Installed_Product__c
                  WHERE Id IN :ipIds]){
                ipMap.put(ip.Id, ip);
            }

            for(Calibration_Event__c ce : newList){

                // Populate Owned by Company values from parent (Installed Project) related record through Map if the values are not the same
                if(String.IsNotBlank(ce.Calibrated_Tool__c) && ipMap.keyset().contains(ce.Calibrated_Tool__c) && (ce.SMAX_PS_Owned_By_Company__c != ipMap.get(ce.Calibrated_Tool__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(ipMap.get(ce.Calibrated_Tool__c).SMAX_PS_Owned_By_Company__c))){
                    ce.SMAX_PS_Owned_By_Company__c = ipMap.get(ce.Calibrated_Tool__c).SMAX_PS_Owned_By_Company__c;
                    ce.SMAX_PS_Owned_By_Company_Decided_By__c = ipMap.get(ce.Calibrated_Tool__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
            }
        }
    }

    // Event | Event (Field Service Order related only)
    // Parent: Work Order
    public static void updateEventObject(List<Event> newList, Map<Id, Event> oldMap){

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get('SVMXC__Service_Order__c');
        String objPrefix = sObjType.getDescribe().getKeyPrefix();
        Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>();
        Set<Id> woIds = new Set<Id>();
        
        for(Event evt : newList){

            String whatIdStr = String.valueOf(evt.WhatId);
            
            // only access records that are Field Service types and related to Work Orders
            if(String.IsNotBlank(evt.WhatId) && evt.SMAX_PS_Work_Order_Record_Type__c == 'Field Service' && whatIdStr.startsWith(objPrefix)){
                woIds.add(evt.WhatId);
            }
        }

        if(woIds.size() > 0){

            // only get Work Orders that already have Owned by Company populated
            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                workOrderMap.put(wo.Id, wo);
            }

            for(Event evt : newList){

                // update Event records if the Owned By Company does not match
                if(workOrderMap.keySet().contains(evt.WhatId) && evt.SMAX_PS_Owned_By_Company__c != workOrderMap.get(evt.WhatId).SMAX_PS_Owned_By_Company__c){
                    evt.SMAX_PS_Owned_By_Company__c = workOrderMap.get(evt.WhatId).SMAX_PS_Owned_By_Company__c;
                    //evt.SMAX_PS_Owned_By_Company_Decided_By__c = workOrderMap.get(evt.WhatId).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
            }
        }
    }

    // Parts Request | SVMXC_Parts_Request__c
    // Parent: Work Order
    public static void updatePartsRequestObject(List<SVMXC__Parts_Request__c> newList, Map<Id, SVMXC__Parts_Request__c> oldMap){
        
        Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>();
        Set<Id> woIds = new Set<Id>();

        for(SVMXC__Parts_Request__c pr : newList){

            if(String.IsNotBlank(pr.SVMX_PS_Work_Order__c)){
                woIds.add(pr.SVMX_PS_Work_Order__c);
            }
        }

        if(woIds.size() > 0){

            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                workOrderMap.put(wo.Id, wo);
            }

            for(SVMXC__Parts_Request__c pr : newList){

                // update Parts Request record if Owned By Comapny field does not match
                if(workOrderMap.keySet().contains(pr.SVMX_PS_Work_Order__c) && (pr.SMAX_PS_Owned_By_Company__c != workOrderMap.get(pr.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(workOrderMap.get(pr.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c))){
                    pr.SMAX_PS_Owned_By_Company__c = workOrderMap.get(pr.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c;
                    pr.SMAX_PS_Owned_By_Company_Decided_By__c = workOrderMap.get(pr.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
            }
        }
    }

    // Proforma Invoice | SVMXC_Proforma_Invoice__c
    // Parent: Work Order
    public static void updateProformaInvObject(List<SVMXC__Proforma_Invoice__c> newList, Map<Id, SVMXC__Proforma_Invoice__c> oldMap){

        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        Set<Id> woIds = new Set<Id>();

        for(SVMXC__Proforma_Invoice__c pi : newList){

            // Add valid Work Order Ids to Set to populate Map
            if(String.IsNotBlank(pi.SMAX_PS_Work_Order__c)){
                woIds.add(pi.SMAX_PS_Work_Order__c);
            }
        }

        if(woIds.size() > 0){

            // populate Work Order Map
            for(SVMXC__Service_Order__c wo :
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                woMap.put(wo.Id, wo);
            }

            for(SVMXC__Proforma_Invoice__c pi : newList){

                // Populate Owned by Company values from parent (Work Order) if the Owned By Company values do not match
                if(String.IsNotBlank(pi.SMAX_PS_Work_Order__c) && woMap.keyset().contains(pi.SMAX_PS_Work_Order__c) && 
                    (pi.SMAX_PS_Owned_By_Company__c != woMap.get(pi.SMAX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(woMap.get(pi.SMAX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c))){

                    pi.SMAX_PS_Owned_By_Company__c = woMap.get(pi.SMAX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c;
                    pi.SMAX_PS_Owned_By_Company_Decided_By__c = woMap.get(pi.SMAX_PS_Work_Order__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
            }
        }
    }

    // Service Alert | SVMX_PS_Service_Alert__c
    // Parent(s): Installed Product [OR] Location [OR] Work Order [OR] Technician
    public static void updateServiceAlertObject(List<SVMX_PS_Service_Alert__c> newList, Map<Id, SVMX_PS_Service_Alert__c> oldMap){

        Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>();
        Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>();
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        Set<Id> ipIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>(); 
        Set<Id> woIds = new Set<Id>();
        Set<Id> techIds = new Set<Id>();
        String decisionString = 'Not Found';
        String companyString = '';

        // Add valid Ids to Sets for Map population
        for(SVMX_PS_Service_Alert__c sa : newList){
            // add related Installed Product Ids if valid
            if(String.IsNotBlank(sa.SVMX_PS_Installed_Product__c)){
                ipIds.add(sa.SVMX_PS_Installed_Product__c);
            }
            // add related Location Ids if valid
            if(String.IsNotBlank(sa.SVMX_PS_Location__c)){
                locIds.add(sa.SVMX_PS_Location__c);
            }
            // add related Work Order Ids if valid
            if(String.IsNotBlank(sa.SVMX_PS_Work_Order__c)){
                woIds.add(sa.SVMX_PS_Work_Order__c);
            }
            // add related Technician Ids if valid
            if(String.IsNotBlank(sa.SVMX_PS_Technician__c)){
                techIds.add(sa.SVMX_PS_Technician__c);
            }
        }

        // validate and populate Installed Product Map
        if(ipIds.size() > 0){
            for(SVMXC__Installed_Product__c ip : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Installed_Product__c
                  WHERE Id IN :ipIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                ipMap.put(ip.Id, ip);
            }
        }
        // validate and populate Location Map
        if(locIds.size() > 0){
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                locMap.put(loc.Id, loc);
            }
        }
        // validate and populate Work Order Map
        if(woIds.size() > 0){
            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                woMap.put(wo.Id, wo);
            }
        }
        // validate and populate Technician Map
        if(techIds.size() > 0){
            for(SVMXC__Service_Group_Members__c tech : 
                [SELECT Id,
                        SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c
                   FROM SVMXC__Service_Group_Members__c
                  WHERE Id IN :techIds]){
                techMap.put(tech.Id, tech);
            }
        }

        // update Service Alert records based on Parent records and mismatch Owned by Company values
        for(SVMX_PS_Service_Alert__c sa : newList){

            if(String.IsBlank(sa.SMAX_PS_Owned_By_Company__c)){

                // 01/10/2023 tony - Added clear of variables so we don't put the last values into the next service alert
                companyString = null;
                decisionString = null;

                // check to update by Installed Product
                if(String.IsNotBlank(sa.SVMX_PS_Installed_Product__c) && ipMap.keySet().contains(sa.SVMX_PS_Installed_Product__c) && (sa.SMAX_PS_Owned_By_Company__c != ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Location
                else if(String.IsNotBlank(sa.SVMX_PS_Location__c) && locMap.keySet().contains(sa.SVMX_PS_Location__c) && (sa.SMAX_PS_Owned_By_Company__c != locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Work Order
                else if(String.IsNotBlank(sa.SVMX_PS_Work_Order__c) && woMap.keySet().contains(sa.SVMX_PS_Work_Order__c) && (sa.SMAX_PS_Owned_By_Company__c != woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Technician
                else if(String.IsNotBlank(sa.SVMX_PS_Technician__c) && techMap.keySet().contains(sa.SVMX_PS_Technician__c) && (sa.SMAX_PS_Owned_By_Company__c != techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c || String.IsBlank(techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c))){
                    companyString = techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c;
                    decisionString = 'By Service Team Record';
                }

                sa.SMAX_PS_Owned_By_Company__c = companyString;
                sa.SMAX_PS_Owned_By_Company_Decided_By__c = decisionString;
            }
        }
    }

    // Drop Ship Locations | SMAX_PS_Drop_Ship_Locations__c
    // Parent(s): Technician
    public static void updateDropShipLocObject(List<SMAX_PS_Drop_Ship_Locations__c> newList, Map<Id, SMAX_PS_Drop_Ship_Locations__c> oldMap){

        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        Set<Id> techIds = new Set<Id>();
        Set<Id> srvcGroupIds = new Set<Id>();

        for(SMAX_PS_Drop_Ship_Locations__c dsl : newList){

            // Add valid Technician Ids to populate Map
            if(String.IsNotBlank(dsl.SMAX_PS_Technician_Equipment__c)){
                techIds.add(dsl.SMAX_PS_Technician_Equipment__c);
            }
        }

        if(techIds.size() > 0){

            // Add valid Service Teams (parent) to Set to populate Map
            for(SVMXC__Service_Group_Members__c sgm :
                [SELECT Id,
                        SVMXC__Service_Group__c,
                        SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c
                   FROM SVMXC__Service_Group_Members__c
                  WHERE Id IN :techIds]){
                    techMap.put(sgm.Id, sgm);
            }

            for(SMAX_PS_Drop_Ship_Locations__c dsl : newList){

                // Populate Owned by Company values from parent (Service Group) if the Owned By Company values do not match
                if(String.IsNotBlank(dsl.SMAX_PS_Technician_Equipment__c) && techMap.keyset().contains(dsl.SMAX_PS_Technician_Equipment__c) && 
                    (dsl.SMAX_PS_Owned_By_Company__c != techMap.get(dsl.SMAX_PS_Technician_Equipment__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c || String.IsBlank(techMap.get(dsl.SMAX_PS_Technician_Equipment__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c))){

                    dsl.SMAX_PS_Owned_By_Company__c = techMap.get(dsl.SMAX_PS_Technician_Equipment__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c;
                }
            }
        }
    }

    // Method uses "Reflection" code to work on any Salesforce object. This method is used primarily as default for assigning the Owned By Company field 
    // for Service related objects identified.
    public static void updateSobjectOwnedByCompany(List<SObject> newList, Map<Id, SObject> oldMap){

        if (!SMAX_PS_Utility.isActive('Update Sobject Owned By Company', 'Assign the Owned By Company field for Service related objects'))
        { return; }

        SObjectType sType = newList[0].getSObjectType();

        // 12/02/2022 Switched from using Object Label to Object API Name as foreign languages cause issues
        String sObjApiStr = String.valueOf(sType);
        //String sObjLblStrUnparsed = Schema.getGlobalDescribe().get(sObjApiStr).getDescribe().getLabel();
        //Pattern regExPattern = Pattern.compile('[^a-zA-Z0-9]');
        //Matcher regExMatcher = regExPattern.matcher(sObjLblStrUnparsed);
        //String sObjLblStr = regExMatcher.replaceAll('');
        //String sObjApiName = Schema.getGlobalDescribe().get(sObjApiStr).getDescribe().getName();

        System.Debug('*** sObject API: ' + sObjApiStr);
        //System.Debug('*** Object Mapping Record Name: ' + sObjApiName);
        
        // when using Metadata Relationships (Entity or Field) CMDT methods cannot be used. SOQL must be leveraged.
        // 12/02/2022 Use List instead of individual object as assignment of empty list of object causes error
        //SMAX_PS_OwnedByCompanyObjMapping__mdt objMap =
        List<SMAX_PS_OwnedByCompanyObjMapping__mdt> objMapList =
            [SELECT Id, 
                    DeveloperName, 
                    SMAX_PS_SObject__c, 
                    SMAX_PS_SObject__r.QualifiedApiName, 
                    SMAX_PS_Primary_Field_Type__c, 
                    SMAX_PS_Primary_Field__r.QualifiedApiName, 
                    SMAX_PS_Secondary_Field_Type__c, 
                    SMAX_PS_Secondary_Field__r.QualifiedApiName 
               FROM SMAX_PS_OwnedByCompanyObjMapping__mdt
               WHERE SMAX_PS_SObject__r.QualifiedApiName = :sObjApiStr AND
                //WHERE DeveloperName = :sObjLblStr AND
               SMAX_PS_Is_Active__c = TRUE];

        System.debug('objMapList: ' + objMapList);

        SMAX_PS_OwnedByCompanyObjMapping__mdt objMap = null;
        if (!objMapList.isEmpty()) {
            objMap = objMapList[0];
        } else {
            System.debug('No Custom Metadata Type found for sObjApiStr: ' + sObjApiStr);
            return;
        }

        String objectAPI = objMap.SMAX_PS_SObject__r.QualifiedApiName;
        String pFieldType = objMap.SMAX_PS_Primary_Field_Type__c;
        String pField = objMap.SMAX_PS_Primary_Field__r.QualifiedApiName;
        String sFieldType = objMap.SMAX_PS_Secondary_Field_Type__c;
        String sField = objMap.SMAX_PS_Secondary_Field__r.QualifiedApiName;
        Boolean hasMultipleOptions = (String.IsNotBlank(sFieldType) ? true : false);
        Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> obcPrimaryMap = getOwnedByCompanyMappings(pFieldType);
        Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> obcSecondaryMap = getOwnedByCompanyMappings(sFieldType);

        // TH 12/02/2022 Switched from using object label to object name as foreign languages cause issues
        
        // if the Object type is Service Maintenance Contract (Parent or Child)
        if (sObjApiStr == 'SVMXC__Service_Contract__c') {
            updateContractItemsFromParent((List<SVMXC__Service_Contract__c>)newList);
        }
        // if the Object type is Work Order (Previous Owned By Company, Maintenance Plant and Sales Org population)
        if(sObjApiStr == 'SVMXC__Service_Order__c'){
            updateWorkOrderFromIP((List<SVMXC__Service_Order__c>)newList);
            updateWorkOrderFromTech((List<SVMXC__Service_Order__c>)newList);
            // 03/10/2023 Added updateWorkOrderFromUser method for Remote work orders that didn't find a match on IP or Technician
            System.debug('Calling updateWorkOrderFromUser method');
            updateWorkOrderFromUser((List<SVMXC__Service_Order__c>)newList);
        }
        // if the Object type is Parts Order (Parent or Child)
        if(sObjApiStr == 'SVMXC__RMA_Shipment_Order__c'){
            updatePartsOrderFromMaster((List<SVMXC__RMA_Shipment_Order__c>)newList);
        }
        // if the Object type is Installed Product (mainly for Calibrated Tools RT)
        if(sObjApiStr == 'SVMXC__Installed_Product__c'){
            updateInstalledProductFromLocation((List<SVMXC__Installed_Product__c>)newList);
        }
        // if the Object type is Complaint (Plant from related Installed Product or Work Order)
        if(sObjApiStr == 'SMAX_PS_Complaint__c'){
            updateComplaintFromIPorWO((List<SMAX_PS_Complaint__c>)newList);
        }

        // sObject List loop START
        for(SObject sobj : newList){

            String companyString = null;
            String decisionString = 'Not Found';
            String ownedByCo = (String) sobj.get('SMAX_PS_Owned_By_Company__c');
            System.debug('ownedByCo: ' + ownedByCo);
            // 12/02/2022 Switched from using object label to object name as foreign languages cause issues
            //String prevOwnedByCo = (sObjLblStr == 'WorkOrder' ? (String) sobj.get('SMAX_PS_Previous_Owned_by_Company__c') : null);
            //String prevOwnedByCo = (sObjApiStr == 'SVMXC__Service_Order__c' ? (String) sobj.get('SMAX_PS_Previous_Owned_by_Company__c') : null);
            String value = (String) sobj.get(pField);
            String sValue = (hasMultipleOptions ? (String) sobj.get(sField) : null);
            Id sobjRecId = (Id) sobj.get('Id');
            SObject old = oldMap?.get(sobjRecId);

            if(String.IsBlank(ownedByCo) || old == null || old.get(pField) != sobj.get(pField)) { // || String.IsBlank(prevOwnedByCo)){

                if(String.IsNotBlank(value) && obcPrimaryMap.keySet().contains(value)){
                    companyString = obcPrimaryMap.get(value).SMAX_PS_Owned_By_Company__c;
                    decisionString = 'By ' + pFieldType + ' [' + pField + ']';
                    System.Debug('*** OBC Found by Primary Field: [' + sobjRecId + '] ' + pFieldType + ' [' + pField + ']');
                }
                else if(String.IsNotBlank(sFieldType) && String.IsNotBlank(sValue)){
                    System.Debug('*** OBC NOT Found by Primary Field... Checking Secondary Field');
                    if(obcSecondaryMap.keySet().contains(sValue)){
                        companyString = obcSecondaryMap.get(sValue).SMAX_PS_Owned_By_Company__c;
                        decisionString = 'By ' + sFieldType + ' [' + sField + ']';
                        System.Debug('*** OBC Found by Secondary Field: [' + sobjRecId + '] ' + sFieldType + ' [' + sField + ']');
                    }
                }
                // 03/13/2023 If the Owned By Company has already been set by User Owned By Company then keep it
                else if(String.isNotBlank(ownedByCo)) {
                    String decidedBy = (String) sobj.get('SMAX_PS_Owned_By_Company_Decided_By__c');
                    if(decidedBy != null && decidedBy.contains('User')) {
                        decisionString = decidedBy;
                        companyString = ownedByCo;
                    }

                }

                if(String.IsBlank(companyString)){ System.Debug('*** OBC NOT Found at all by Engine for [' + sobjRecId + ']'); }
                sobj.put('SMAX_PS_Owned_By_Company__c', companyString);
                sobj.put('SMAX_PS_Owned_By_Company_Decided_By__c', decisionString.left(50)); // 01/16/2024 Sometimes the values exceeded the field size
            }
        }
        // sObject List loop END
    }

    // updates trigger list for Complaints from related Installed Product or Work Order (Plant) through the engine
    private static void updateComplaintFromIPorWO(List<SMAX_PS_Complaint__c> complaints){

        Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
        Map<String, SVMXC__Service_Order__c> woMap = new Map<String, SVMXC__Service_Order__c>();
        Set<Id> ipIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();

        for(SMAX_PS_Complaint__c cp : complaints){
            if(String.IsNotBlank(cp.SMAX_PS_InstalledProduct__c)){
                ipIds.add(cp.SMAX_PS_InstalledProduct__c);
            }
            if(String.IsNotBlank(cp.SMAX_PS_WorkOrder__c)){
                woIds.add(cp.SMAX_PS_WorkOrder__c);
            }
        }

        if(ipIds.size() > 0){

            // populate Installed Products Map
            for(SVMXC__Installed_Product__c ip : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Previous_Plant__c
                   FROM SVMXC__Installed_Product__c
                  WHERE Id IN :ipIds]){
                    ipMap.put(ip.Id, ip);          
            }
        }
        if(woIds.size() > 0){

            // populate Work Orders Map
            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_SAP_Maintenance_Plant__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds]){
                    woMap.put(wo.Id, wo);          
            }
        }

        for(SMAX_PS_Complaint__c cp : complaints){
            if(String.IsBlank(cp.SMAX_PS_Plant__c)){
                if(ipMap.keySet().contains(cp.SMAX_PS_InstalledProduct__c) && String.IsNotBlank(ipMap.get(cp.SMAX_PS_InstalledProduct__c).SMAX_PS_MaintenancePlant__c)){
                    cp.SMAX_PS_Plant__c = ipMap.get(cp.SMAX_PS_InstalledProduct__c).SMAX_PS_MaintenancePlant__c;
                }
                else if(woMap.keySet().contains(cp.SMAX_PS_WorkOrder__c) && String.IsNotBlank(woMap.get(cp.SMAX_PS_WorkOrder__c).SMAX_PS_SAP_Maintenance_Plant__c)){
                    cp.SMAX_PS_Plant__c = woMap.get(cp.SMAX_PS_WorkOrder__c).SMAX_PS_SAP_Maintenance_Plant__c;
                }
            }
        }
    }

    // updates trigger list for Service Contracts to account for the parent-child relationship through the engine
    private static void updateContractItemsFromParent(List<SVMXC__Service_Contract__c> contracts) {
        Map<Id, List<SVMXC__Service_Contract__c>> parentChildMap = new Map<Id, List<SVMXC__Service_Contract__c>>();
        for (SVMXC__Service_Contract__c contract : contracts) {
            if (contract.SVMX_PS_Parent_Contract__c != null) {
                if (!parentChildMap.containsKey(contract.SVMX_PS_Parent_Contract__c)) {
                    parentChildMap.put(contract.SVMX_PS_Parent_Contract__c, new List<SVMXC__Service_Contract__c>());
                }
                parentChildMap.get(contract.SVMX_PS_Parent_Contract__c).add(contract);
            }
        }

        if (!parentChildMap.isEmpty()) {
            Map<Id, SVMXC__Service_Contract__c> parentMap = new Map<Id, SVMXC__Service_Contract__c>([SELECT Id,
                Name, SMAX_PS_SalesOrg__c FROM SVMXC__Service_Contract__c WHERE Id IN :parentChildMap.keySet()]);
            for (Id parentId : parentChildMap.keySet()) {
                SVMXC__Service_Contract__c parent = parentMap.get(parentId);
                List<SVMXC__Service_Contract__c> children = parentChildMap.get(parentId);
                for (SVMXC__Service_Contract__c child : children) {
                    // Sales Org (primary). No secondary field for this object
                    child.SMAX_PS_SalesOrg__c = parent.SMAX_PS_SalesOrg__c;
                }
            }
        }
    }

    // updates trigger list for Work Orders from related Installed Product (Prev OBC, Maintenance Plant and Sales Org) through the engine
    private static void updateWorkOrderFromIP(List<SVMXC__Service_Order__c> workOrders){

        Map<String, SVMXC__Installed_Product__c> ipMap = new Map<String, SVMXC__Installed_Product__c>();
        Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> obcCodesMap = new Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt>();
        Set<Id> ipIds = new Set<Id>();

        for(SVMXC__Service_Order__c wo : workOrders){
            if(String.IsNotBlank(wo.SVMXC__Component__c)){
                ipIds.add(wo.SVMXC__Component__c);
            }
        }

        if(ipIds.size() > 0){

            // populate Owned by Company Codes Mapping
            for(SMAX_PS_OwnedByCompany_Mapping__mdt obcMapping :
                [SELECT Id,
                        Label,
                        SMAX_PS_Company_Code__c, 
                        SMAX_PS_Country__c, 
                        SMAX_PS_Mapping_Key__c, 
                        SMAX_PS_Owned_By_Company__c, 
                        SMAX_PS_Sales_Org__c, 
                        SMAX_PS_Service_Plant__c 
                FROM SMAX_PS_OwnedByCompany_Mapping__mdt]){
                    obcCodesMap.put(obcMapping.SMAX_PS_Service_Plant__c, obcMapping);
            }

            // populate Installed Products Map
            for(SVMXC__Installed_Product__c ip : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_Previous_Plant__c
                   FROM SVMXC__Installed_Product__c
                  WHERE Id IN :ipIds]){
                    ipMap.put(ip.Id, ip);          
            }

            if(ipMap.size() > 0){
                for(SVMXC__Service_Order__c wo : workOrders){
                    
                    if(String.IsBlank(wo.SMAX_PS_Owned_by_Company__c) && ipMap.keyset().contains(wo.SVMXC__Component__c)){
                        // update Sales Org and SAP Maintenance Plant if blank
                        wo.SMAX_PS_SalesOrg__c = (String.IsBlank(wo.SMAX_PS_SalesOrg__c) ? ipMap.get(wo.SVMXC__Component__c).SMAX_PS_SalesOrg__c : wo.SMAX_PS_SalesOrg__c);
                        wo.SMAX_PS_SAP_Maintenance_Plant__c = (String.IsBlank(wo.SMAX_PS_SAP_Maintenance_Plant__c) ? ipMap.get(wo.SVMXC__Component__c).SMAX_PS_MaintenancePlant__c : wo.SMAX_PS_SAP_Maintenance_Plant__c);
                    }

                    // ITSVMX-1155 Disabling the Previous OwnedBy now that we're live
//                    if(String.IsBlank(wo.SMAX_PS_Previous_Owned_by_Company__c) && ipMap.keyset().contains(wo.SVMXC__Component__c)){
//                        // check for installed product Previous Plant... if blank use Maintenance Plant to find Previous Company
//                        if(obcCodesMap.keySet().contains(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_Previous_Plant__c) || obcCodesMap.keySet().contains(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_MaintenancePlant__c)){
//                            wo.SMAX_PS_Previous_Owned_by_Company__c = (String.IsNotBlank(obcCodesMap.get(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_Previous_Plant__c).SMAX_PS_Owned_By_Company__c) ? obcCodesMap.get(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_Previous_Plant__c).SMAX_PS_Owned_By_Company__c : obcCodesMap.get(ipMap.get(wo.SVMXC__Component__c).SMAX_PS_MaintenancePlant__c).SMAX_PS_Owned_By_Company__c);
//                        }
//                    }
                }
            }
        }
    }

    private static void updateWorkOrderFromTech(List<SVMXC__Service_Order__c> workOrders){

        Map<Id, SVMXC__Service_Group_Members__c> techMap = new Map<Id, SVMXC__Service_Group_Members__c>();
        Set<Id> techIds = new Set<Id>();

        for(SVMXC__Service_Order__c wo : workOrders){
            if (wo.SVMXC__Component__c == null && wo.SVMXC__Group_Member__c != null){
                techIds.add(wo.SVMXC__Group_Member__c);
            }
        }

        if(techIds.size() > 0){

            techMap = new Map<Id, SVMXC__Service_Group_Members__c>([SELECT Id, SMAX_PS_Plant__c
                FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds]);

            for(SVMXC__Service_Order__c wo : workOrders){
                if (wo.SVMXC__Component__c == null && wo.SVMXC__Group_Member__c != null){
                    SVMXC__Service_Group_Members__c tech = techMap.get(wo.SVMXC__Group_Member__c);
                    if (tech != null) {
                        wo.SMAX_PS_SAP_Maintenance_Plant__c = tech.SMAX_PS_Plant__c;
                    }
                }
            }
        }
    }

    // 03/10/2023 Added updateWorkOrderFromUser method for Remote work orders that didn't find a match on IP or Technician
    private static void updateWorkOrderFromUser(List<SVMXC__Service_Order__c> workOrders){

        System.debug('Entering SMAX_PS_OwnedByCompanyManager.updateWorkOrderFromUser method');

        Map<Id, User> userMap = new Map<Id, User>();
        Set<Id> userIds = new Set<Id>();
        List<SVMXC__Service_Order__c> woToUpdate = new List<SVMXC__Service_Order__c>();
        Id remoteRTId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();

        // get the list of remote work orders that need to be updated and their user ids
        for(SVMXC__Service_Order__c wo : workOrders){
            if (wo.RecordTypeId == remoteRTId
                    && wo.SVMXC__Component__c == null
                    && wo.SVMXC__Group_Member__c == null
                    && wo.SVMXC__Site__c == null
                    && wo.SMAX_PS_SalesOrg__c == null
                    && wo.SMAX_PS_SAP_Maintenance_Plant__c == null)
            {

                woToUpdate.add(wo);

                // On BeforeInsert CreatedById will be null so use the current user
                if(wo.CreatedById != null) {
                    userIds.add(wo.CreatedById);
                }
                else {
                    userIds.add(System.UserInfo.getUserId());
                }

            }
        }
        System.debug('woToUpdate: ' + woToUpdate.size() + ' ' + woToUpdate);
        System.debug('userIds: ' + userIds.size() + ' ' + userIds);

        if(userIds.isEmpty()) return; // nothing to process so exit

        // get the users with their owned by company
        userMap = new Map<Id, User>([SELECT Id, Owned_by_Company__c FROM User WHERE Id IN :userIds]);
        System.debug('userMap: ' + userMap.size() + ' ' + userMap);

        for(SVMXC__Service_Order__c wo : woToUpdate){

            User woCreatedByUser = userMap?.get(wo.CreatedById);
            // On BeforeInsert CreatedById will be null so use the current user
            if(woCreatedByUser == null) woCreatedByUser = userMap?.get(System.UserInfo.getUserId());
            System.debug('woCreatedByUser: ' + woCreatedByUser);

            if (woCreatedByUser != null) {

                wo.SMAX_PS_Owned_By_Company__c = woCreatedByUser.Owned_by_Company__c;
                wo.SMAX_PS_Owned_By_Company_Decided_By__c = 'By User [Owned_by_Company__c]';
            }
        }

        System.debug('Exiting SMAX_PS_OwnedByCompanyManager.updateWorkOrderFromUser method');
    }

    // updates trigger list for Parts Orders to account for the parent-child relationship through the engine
    private static void updatePartsOrderFromMaster(List<SVMXC__RMA_Shipment_Order__c> pOrders) {
        Map<Id, List<SVMXC__RMA_Shipment_Order__c>> parentChildMap = new Map<Id, List<SVMXC__RMA_Shipment_Order__c>>();
        Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>();
        Set<Id> locIds = new Set<Id>();
        
        for (SVMXC__RMA_Shipment_Order__c ord : pOrders) {
            // get children records and append to list
            if (ord.SVMXC__Master_Order__c != null) {
                if (!parentChildMap.containsKey(ord.SVMXC__Master_Order__c)) {
                    parentChildMap.put(ord.SVMXC__Master_Order__c, new List<SVMXC__RMA_Shipment_Order__c>());
                }
                parentChildMap.get(ord.SVMXC__Master_Order__c).add(ord);
            }
            // get To/Destination Location Id for Master records
            if(String.IsNotBlank(ord.SVMXC__Destination_Location__c) && ord.SVMXC__Master_Order__c == null){
                locIds.add(ord.SVMXC__Destination_Location__c);
            }
        }

        // update relavant Master records first
        if(locIds.size() > 0){

            // populate Locations Map
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_SalesOrg__c,
                        SMAX_PS_MaintenancePlant__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds]){
                    locMap.put(loc.Id, loc);
            }
            // populate Master records with updated Sales Org from To Location
            for(SVMXC__RMA_Shipment_Order__c ord : pOrders){
                if(String.IsNotBlank(ord.SVMXC__Destination_Location__c) && locMap.keySet().contains(ord.SVMXC__Destination_Location__c)){
                    // update Sales Org if blank from Location
                    ord.SMAX_PS_SalesOrg__c = (String.IsBlank(ord.SMAX_PS_SalesOrg__c) ? locMap.get(ord.SVMXC__Destination_Location__c).SMAX_PS_SalesOrg__c : ord.SMAX_PS_SalesOrg__c);
                    ord.BD_Maintenance_Plant__c = (String.IsBlank(ord.BD_Maintenance_Plant__c) ? locMap.get(ord.SVMXC__Destination_Location__c).SMAX_PS_MaintenancePlant__c : ord.BD_Maintenance_Plant__c);
                }
            }
        }
        // update children records from Master second
        if (!parentChildMap.isEmpty()) {
            Map<Id, SVMXC__RMA_Shipment_Order__c> parentMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>([SELECT Id,
                Name, SMAX_PS_SalesOrg__c, BD_Maintenance_Plant__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id IN :parentChildMap.keySet()]);
            for (Id parentId : parentChildMap.keySet()) {
                SVMXC__RMA_Shipment_Order__c parent = parentMap.get(parentId);
                List<SVMXC__RMA_Shipment_Order__c> children = parentChildMap.get(parentId);
                for (SVMXC__RMA_Shipment_Order__c child : children) {
                    // Sales Org (primary) | Maintenance Plant (secondary)
                    child.SMAX_PS_SalesOrg__c = parent.SMAX_PS_SalesOrg__c;
                    child.BD_Maintenance_Plant__c = parent.BD_Maintenance_Plant__c;
                }
            }
        }
    }

    // update trigger list for Installed Products (Calibrated Tools RT) to update Maintenance Plant and Sales Org from related Location
    private static void updateInstalledProductFromLocation(List<SVMXC__Installed_Product__c> installedProds){

        Map<String, SVMXC__Site__c> locMap = new Map<String, SVMXC__Site__c>();
        Set<Id> locIds = new Set<Id>();

        for(SVMXC__Installed_Product__c ip : installedProds){
            if(String.IsNotBlank(ip.SVMXC__Site__c)){
                locIds.add(ip.SVMXC__Site__c);
            }
        }

        if(locIds.size() > 0){

            // populate Locations Map
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_MaintenancePlant__c,
                        SMAX_PS_SalesOrg__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds]){
                    locMap.put(loc.Id, loc);          
            }

            if(locMap.size() > 0){
                for(SVMXC__Installed_Product__c ip : installedProds){
                    // check for Location Maintenance Plant and Sales Org
                    if(locMap.keyset().contains(ip.SVMXC__Site__c)){
                        ip.SMAX_PS_MaintenancePlant__c = (String.IsBlank(ip.SMAX_PS_MaintenancePlant__c) ? locMap.get(ip.SVMXC__Site__c).SMAX_PS_MaintenancePlant__c : ip.SMAX_PS_MaintenancePlant__c);
                        ip.SMAX_PS_SalesOrg__c = (String.IsBlank(ip.SMAX_PS_SalesOrg__c) ? locMap.get(ip.SVMXC__Site__c).SMAX_PS_SalesOrg__c : ip.SMAX_PS_SalesOrg__c);
                    }
                }
            }
        }
    }

    // returns Owned By Company Mapping records based on Primary Field Type for keyset
    private static Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> getOwnedByCompanyMappings(String primaryFieldType){

        Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt> returnMap = new Map<String, SMAX_PS_OwnedByCompany_Mapping__mdt>();
        for(SMAX_PS_OwnedByCompany_Mapping__mdt obcMapping:
            [SELECT Id,
                    Label,
                    SMAX_PS_Company_Code__c, 
                    SMAX_PS_Country__c, 
                    SMAX_PS_Mapping_Key__c, 
                    SMAX_PS_Owned_By_Company__c, 
                    SMAX_PS_Sales_Org__c, 
                    SMAX_PS_Service_Plant__c 
               FROM SMAX_PS_OwnedByCompany_Mapping__mdt]){
            
            if(primaryFieldType == 'Sales Org'){
                returnMap.put(obcMapping.SMAX_PS_Sales_Org__c, obcMapping);
            }
            else{
                returnMap.put(obcMapping.SMAX_PS_Service_Plant__c, obcMapping);
            }
        }

        return returnMap;
    }
}
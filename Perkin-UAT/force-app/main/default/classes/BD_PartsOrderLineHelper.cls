/**
 * @class BD_PartsOrderLineHelper
 * @author Prashant Kumar, Bolt Data Consulting Group
 * @description Helper class for Parts Order Line Object
 * 
 * @changelog
 * 23 January 2025 - Prashant Kumar - Created
*/
public without sharing class BD_PartsOrderLineHelper {
    /**
     * @method updateMasterPOLs
     * @author Prashant Kumar, Bolt Data Consulting Group
     * @description Updates Master Parts Order Lines values 
     *      based on Shipment/Delivery Parts Order Lines
     * 
     * @changelog
     * 23 January 2025 - Prashant Kumar - Created
    */
    public static void updateMasterPOLs(List<SVMXC__RMA_Shipment_Line__c> detailPOLs){
        Set<Id> detailPOIdSet = new Set<Id>();
        for(SVMXC__RMA_Shipment_Line__c detailPOL: detailPOLs){
            if(detailPOL.SVMXC__RMA_Shipment_Order__c != null){
                detailPOIdSet.add(detailPOL.SVMXC__RMA_Shipment_Order__c);
            }
        }

        // Query Detail POs
        Set<Id> masterPOIdSet = new Set<Id>();
        Map<Id, SVMXC__RMA_Shipment_Order__c> 
            shipmentPOIdRecordMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
        Map<Id, SVMXC__RMA_Shipment_Order__c> 
            deliveryPOIdRecordMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
        for(SVMXC__RMA_Shipment_Order__c detailPO: [
            SELECT Id, RecordType.DeveloperName, RecordType.NamespacePrefix, SVMXC__Master_Order__c,
            SVMXC__Tracking_Number__c, SMAX_PS_CourierCode__c, SVMX_PS_Courier__c
            FROM SVMXC__RMA_Shipment_Order__c
            WHERE Id in :detailPOIdSet
        ]){
            // Collect Master PO Ids
            if(detailPO.SVMXC__Master_Order__c != null){
                masterPOIdSet.add(detailPO.SVMXC__Master_Order__c);

                if(detailPO.RecordType.NamespacePrefix == 'SVMXC'
                    && detailPO.RecordType.DeveloperName == 'Shipment'
                ){
                    shipmentPOIdRecordMap.put(detailPO.Id, detailPO);
                }else if(detailPO.RecordType.NamespacePrefix == null
                    && detailPO.RecordType.DeveloperName == 'Delivery'
                ){
                    deliveryPOIdRecordMap.put(detailPO.Id, detailPO);
                }
            }

            
        }

        // Query Master POLs
        // Map<Master PO Id, Map<Product Id-Part Number, Master POL Record>>
        Map<Id, Map<String, SVMXC__RMA_Shipment_Line__c>> masterPOIdPNPORecMapMap
            = new Map<Id, Map<String, SVMXC__RMA_Shipment_Line__c>>();
        for(SVMXC__RMA_Shipment_Line__c masterPOL: [
            SELECT Id, SMAX_PS_Part_Number__c, SVMXC__RMA_Shipment_Order__c, SVMXC__Product__c
            FROM SVMXC__RMA_Shipment_Line__c
            WHERE SVMXC__RMA_Shipment_Order__c in :masterPOIdSet
        ]){
            if(!masterPOIdPNPORecMapMap.containsKey(masterPOL.SVMXC__RMA_Shipment_Order__c)){
                masterPOIdPNPORecMapMap.put(
                    masterPOL.SVMXC__RMA_Shipment_Order__c, 
                    new Map<String, SVMXC__RMA_Shipment_Line__c>()
                );
            }

            Map<String, SVMXC__RMA_Shipment_Line__c> partNumberPORecMap 
                = masterPOIdPNPORecMapMap.get(masterPOL.SVMXC__RMA_Shipment_Order__c);
            partNumberPORecMap.put(
                masterPOL.SVMXC__Product__c + '-' + masterPOL.SMAX_PS_Part_Number__c, masterPOL);

        }

        // Update Maste POL
        List<SVMXC__RMA_Shipment_Line__c> 
            updatedMasterPOLs = new List<SVMXC__RMA_Shipment_Line__c>();
        for(SVMXC__RMA_Shipment_Line__c detailPOL: detailPOLs){
            // Get detail PO Id
            Id detailPOId = detailPOL.SVMXC__RMA_Shipment_Order__c;
            if(detailPOId == null){
                continue;
            }
            
            // Get Mater POL 
            SVMXC__RMA_Shipment_Line__c  updatedMasterPOL;
            if(shipmentPOIdRecordMap.containsKey(detailPOId)){
                SVMXC__RMA_Shipment_Order__c detailPO 
                    = shipmentPOIdRecordMap.get(detailPOId);

                SVMXC__RMA_Shipment_Line__c masterPOL = getMastePOL(
                    detailPO.SVMXC__Master_Order__c, masterPOIdPNPORecMapMap, detailPOL
                );

                if(masterPOL == null){
                    continue;
                }

                updatedMasterPOL = new SVMXC__RMA_Shipment_Line__c();
                updatedMasterPOL.Id = masterPOL.Id;
                if(detailPOL.SMAX_PS_ExternalId__c != null){
                    updatedMasterPOL.BD_SAP_Shipment_Number__c = detailPOL.SMAX_PS_ExternalId__c;
                }
                if(!deliveryPOIdRecordMap.containsKey(detailPOId)){
                    // prevents again setting status to received
                    // if delivery records in same transaction appear before shipment in the list
                    updatedMasterPOL.SVMXC__Line_Status__c = 'Received';
                }
                updatedMasterPOL.SVMXC__Received__c = True;
                updatedMasterPOL.SVMXC__Actual_Quantity2__c = detailPOL.SVMXC__Actual_Quantity2__c;
                updatedMasterPOL.SVMXC__Expected_Ship_Date__c = detailPOL.SVMXC__Expected_Ship_Date__c;
            }else if(deliveryPOIdRecordMap.containsKey(detailPOId)){
                SVMXC__RMA_Shipment_Order__c detailPO 
                    = deliveryPOIdRecordMap.get(detailPOId);

                SVMXC__RMA_Shipment_Line__c masterPOL = getMastePOL(
                    detailPO.SVMXC__Master_Order__c, masterPOIdPNPORecMapMap, detailPOL
                );

                if(masterPOL == null){
                    continue;
                }
                
                updatedMasterPOL = new SVMXC__RMA_Shipment_Line__c();
                updatedMasterPOL.Id = masterPOL.Id;
                if(detailPOL.SMAX_PS_ExternalId__c != null){
                    updatedMasterPOL.BD_SAP_Delivery_Number__c = detailPOL.SMAX_PS_ExternalId__c;
                }
                updatedMasterPOL.SVMXC__Line_Status__c = 'Picked';
                updatedMasterPOL.SVMXC__Picked__c = True;
                updatedMasterPOL.SVMXC__Actual_Quantity2__c = detailPOL.SVMXC__Actual_Quantity2__c;
                updatedMasterPOL.SVMXC__Expected_Receipt_Date__c = detailPOL.SVMXC__Expected_Receipt_Date__c;
                updatedMasterPOL.BD_Courier__c = detailPO.SVMX_PS_Courier__c;
                updatedMasterPOL.BD_Courier_Code__c = detailPO.SMAX_PS_CourierCode__c;
                updatedMasterPOL.BD_Tracking_Number__c = detailPO.SVMXC__Tracking_Number__c;
            }

            // Collect Updated Mster POLs
            if(updatedMasterPOL != null){
                updatedMasterPOLs.add(updatedMasterPOL);
            }
        }

        if(updatedMasterPOLs.size() > 0){

            try {
                Database.SaveResult[] updateResults = Database.update(updatedMasterPOLs, false);
                
                List<SMAX_PS_ErrorLog__c> errorLogs = new List<SMAX_PS_ErrorLog__c>();
                for(Database.SaveResult updateResult: updateResults){
                    if(updateResult.isSuccess()){
                        continue;
                    }

                    SMAX_PS_ErrorLog__c errorLog = new SMAX_PS_ErrorLog__c();
                    errorLog.SMAX_PS_Link__c = Url.getOrgDomainUrl().toExternalForm() + '/' + updateResult.getId();
                    errorLog.SMAX_PS_Message__c = JSON.serializePretty(updateResult.getErrors());
                    errorLog.SMAX_PS_Method__c = 'BD_PartsOrderLineHelper.updateMasterPOLs';
                    errorLog.SMAX_PS_Type__c = 'Error';

                    errorLogs.add(errorLog);
                }

                insert errorLogs;
            }catch (Exception e){
                System.debug(e.getMessage() + '\n' + e.getStackTraceString() + '\n' + e.getCause());
            }
        }

    }

    private static SVMXC__RMA_Shipment_Line__c getMastePOL(
        Id masterPOId,
        Map<Id, Map<String, SVMXC__RMA_Shipment_Line__c>> masterPOIdPNPORecMapMap,
        SVMXC__RMA_Shipment_Line__c detailPOL
    ){
        if(masterPOId == null){
            return null;
        }

        Map<String, SVMXC__RMA_Shipment_Line__c> partNumberPORecMap
            = masterPOIdPNPORecMapMap.get(masterPOId);
        if(partNumberPORecMap == null){
            return null;
        }

        SVMXC__RMA_Shipment_Line__c  masterPOL = partNumberPORecMap.get(
            detailPOL.SVMXC__Product__c + '-' + detailPOL.SMAX_PS_Part_Number__c
        );

        return masterPOL;
    }

}
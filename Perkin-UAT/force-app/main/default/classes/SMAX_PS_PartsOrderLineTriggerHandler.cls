/**
 * Created by frankvanloon on 11/16/20.
 *
 * Updates
 * 2022-04-05   Tony    ITSVMX-562 Modify the replenishment parts ordering process in SVMX to automatically change the ordered part from new to refurbished if a refurbished option is available IF the customer/contract allows
 */

public with sharing class SMAX_PS_PartsOrderLineTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {

    public void beforeInsert() {
        List<SVMXC__RMA_Shipment_Line__c> newList = Trigger.new;

        // 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
        SMAX_PS_InventoryManager.useRefurbishedParts(newList, null);
        
        //ITSVMX-480 Lookup Product Distribution Chain Status
        lookupProductSales(newList, null);
    }

    public void afterInsert() {
        List<SVMXC__RMA_Shipment_Line__c> newList = Trigger.new;

        SMAX_PS_InventoryManager.deliveryLineReplacements(newList);

        // 11/23/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts(newList, null);

        // 23 January 2025 - Prashant Kumar, Bolt Data Consulting Group
        // Update Master POL with Shipment/Delivery Info
        BD_PartsOrderLineHelper.updateMasterPOLs(newList);
    }

    public void beforeUpdate() {
        List<SVMXC__RMA_Shipment_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__RMA_Shipment_Line__c> oldMap = (Map<Id, SVMXC__RMA_Shipment_Line__c>) Trigger.oldMap;

        // 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
        SMAX_PS_InventoryManager.useRefurbishedParts(newList, oldMap);
        
        //ITSVMX-480 Lookup Product Distribution Chain Status
        lookupProductSales(newList, oldMap);
    }

    public void afterUpdate() {
        List<SVMXC__RMA_Shipment_Line__c> newList = Trigger.new;
        Map<Id, SVMXC__RMA_Shipment_Line__c> oldMap = (Map<Id, SVMXC__RMA_Shipment_Line__c>) Trigger.oldMap;

        // 11/23/21 ITSVMX-624 Suggested Parts Automation
        SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts(newList, oldMap);
    }

    public void beforeDelete() {
    }

    public void afterDelete() {
    }

    public void afterUndelete() {
    }

    // ITSVMX-480 Lookup Product Plant for Distribution chain status
    // ITSVMX-1494 Changing from ProductPlant to ProductSales for Distribution chain status
    // Should be called from the BEFORE-INSERT/UPDATE Triggers
    public static void lookupProductSales(List<SVMXC__RMA_Shipment_Line__c> partsOrderLines, Map<Id, SVMXC__RMA_Shipment_Line__c> oldMap){
        if (!SMAX_PS_Utility.isActive('PartsLine Lookup ProductSales', 'Lookup ProductSales for DChainStatus')) {
            return;
        }

        Set<Id> poIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        List<SVMXC__RMA_Shipment_Line__c> linesToCheck = new List<SVMXC__RMA_Shipment_Line__c>();
        for (SVMXC__RMA_Shipment_Line__c line : partsOrderLines)
        {
            SVMXC__RMA_Shipment_Line__c old = (oldMap == null) ? null : oldMap.get(line.Id);
            if (line.SVMXC__Product__c != null
                    && (old == null || old.SVMXC__Product__c != line.SVMXC__Product__c))
            {
                poIds.add(line.SVMXC__RMA_Shipment_Order__c);
                prodIds.add(line.SVMXC__Product__c);
                linesToCheck.add(line);
            }
        }
        // Exit if there is nothing to process
        if (linesToCheck.isEmpty()) {
            return;
        }

        Set<String> salesOrgs = new Set<String>();
        Map<Id, SVMXC__RMA_Shipment_Order__c> poMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>([SELECT Id, Name, SMAX_PS_SalesOrg__c
        FROM SVMXC__RMA_Shipment_Order__c WHERE Id IN :poIds]);
        for (SVMXC__RMA_Shipment_Order__c po : poMap.values()) {
            if (po.SMAX_PS_SalesOrg__c != null) {
                salesOrgs.add(po.SMAX_PS_SalesOrg__c);
            }
        }

        if (salesOrgs.isEmpty()) {
            return;
        }

        List<SMAX_PS_ProductSales__c> allProductSales = [SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_SalesOrg__c
            FROM SMAX_PS_ProductSales__c WHERE SMAX_PS_Product__c IN :prodIds AND SMAX_PS_SalesOrg__c IN :salesOrgs
            AND SMAX_PS_DistributionChannel__c != '02'];
        Map<String, SMAX_PS_ProductSales__c> psMap = new Map<String, SMAX_PS_ProductSales__c>();
        for (SMAX_PS_ProductSales__c ps : allProductSales) {
            String key = ps.SMAX_PS_Product__c + '-' + ps.SMAX_PS_SalesOrg__c;
            psMap.put(key, ps);
        }

        for (SVMXC__RMA_Shipment_Line__c line: linesToCheck) {
            SVMXC__RMA_Shipment_Order__c po = poMap.get(line.SVMXC__RMA_Shipment_Order__c);
            String key = line.SVMXC__Product__c + '-' + po.SMAX_PS_SalesOrg__c;
            SMAX_PS_ProductSales__c ps = psMap.get(key);
            if (ps != null) {
                //line.SMAX_PS_Product_Plant__c = pp.Id;
                line.SMAX_PS_Product_Sales__c = ps.Id;
            }
        }
    }


}
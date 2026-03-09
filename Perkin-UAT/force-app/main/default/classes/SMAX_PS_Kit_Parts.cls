/**
 * 10/4/21 ITSVMX-624 Suggested Parts Automation
 * This is a Kit Parts utility class using the SVMX_PS_Kit_Part__c object
 * Created by tony on 11/16/21.
 * The Unit Tests for this code is in: SMAX_PS_Kit_Parts_UT
 */

public without sharing class SMAX_PS_Kit_Parts {

    // Explode Kit Part WDLs and then remove the Kit Part WDLs
    // NOTE: This is called by the AfterInsert & AfterUpdate events of the SMAX_PS_WorkDetailTriggerHandler
    public static void explodeWorkDetailKitParts(List<SVMXC__Service_Order_Line__c> workDetailLines, Map<Id, SVMXC__Service_Order_Line__c> oldMap) {

        System.debug('Entering SMAX_PS_Kit_Parts.explodeWorkDetailKitParts method');
        if (!SMAX_PS_Utility.isActive('Explode Work Detail Part Kits', 'Explode Work Detail Part Kits using SVMX_PS_Kit_Part__c.')) {
            return;
        }

        System.debug('workDetailLines: ' + workDetailLines);

        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        Set<Id> woIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> wdToProcess = new List<SVMXC__Service_Order_Line__c>();

        // Get Work Detail Lines that have Record Type of Usage/Consumption and a Line Type of Parts
        for (SVMXC__Service_Order_Line__c wd : workDetailLines)
        {
            SVMXC__Service_Order_Line__c old = (oldMap == null) ? null : oldMap.get(wd.Id);
            if (wd.RecordTypeId == usageRecTypeId && wd.SVMXC__Line_Type__c == 'Parts'
                    && (old == null || old.SVMXC__Product__c != wd.SVMXC__Product__c))
            {
                // Only run once per transaction for a record type
                if (!SMAX_PS_Utility.isFirstRun('explodeWorkDetailKitParts' + '-' + wd.Id)) {
                    System.debug('Already executed explodeWorkDetailKitParts ' + wd.Id + ' for this transaction');
                    continue;
                }

                woIds.add(wd.SVMXC__Service_Order__c);
                prodIds.add(wd.SVMXC__Product__c);
                wdToProcess.add(wd);
            }
        }

        // Exit if there is nothing to process
        if (wdToProcess.isEmpty()) return;

        // Get Sales Org from the Work Order
        List<SVMXC__Service_Order__c> workOrders = [
                SELECT Id, SMAX_PS_SalesOrg__c
                FROM SVMXC__Service_Order__c
                WHERE Id IN :woIds
        ];
        System.debug('workOrders: ' + workOrders);

        // Get a Map of the Work Order Ids to the Sales Orgs
        Map<Id, String> workOrderIdToSalesOrg = new Map<Id, String>();
        for (SVMXC__Service_Order__c wo :workOrders) {
            workOrderIdToSalesOrg.put(wo.Id, wo.SMAX_PS_SalesOrg__c);
        }
        System.debug('workOrderIdToSalesOrg: ' + workOrderIdToSalesOrg);

        Set<String> salesOrgs = new Set<String>(workOrderIdToSalesOrg.values());
        KitPartHelper helper = new KitPartHelper(prodIds, salesOrgs);

        // Create new Work Detail Lines for the Kit Parts and Remove the parent Part Kit
        List<SVMXC__Service_Order_Line__c> linesToDelete = new List<SVMXC__Service_Order_Line__c>();
        List<SVMXC__Service_Order_Line__c> linesToCreate = new List<SVMXC__Service_Order_Line__c>();
        for (SVMXC__Service_Order_Line__c line :wdToProcess) {
            String salesOrg = workOrderIdToSalesOrg.get(line.SVMXC__Service_Order__c);
            List<SVMX_PS_Kit_Part__c> kitParts = helper.getKitParts(line.SVMXC__Product__c, salesOrg);
            if (kitParts != null && !kitParts.isEmpty()) {
                // These are the parent Part Kit records we want to delete (create new with id to allow delete)
                linesToDelete.add(new SVMXC__Service_Order_Line__c(Id = line.Id) );

                for (SVMX_PS_Kit_Part__c kitPart : kitParts) {
                    SVMXC__Service_Order_Line__c kitPartWDL = new SVMXC__Service_Order_Line__c();
                    kitPartWDL.RecordTypeId = line.RecordTypeId;
                    kitPartWDL.SVMXC__Product__c = kitPart.SVMX_PS_Part__c;
                    kitPartWDL.SMAX_PS_Parts_Kit__c = kitPart.SVMX_PS_Kit__c;
                    kitPartWDL.SVMXC__Service_Order__c = line.SVMXC__Service_Order__c;
                    kitPartWDL.SVMXC__Actual_Quantity2__c = kitPart.SVMX_PS_Qty__c;
                    kitPartWDL.SVMX_PS_Order_Type__c = line.SVMX_PS_Order_Type__c;
                    kitPartWDL.SVMX_PS_Is_Essential__c = line.SVMX_PS_Is_Essential__c;
                    kitPartWDL.SVMXC__Line_Type__c = line.SVMXC__Line_Type__c;
                    linesToCreate.add(kitPartWDL);
                }
            }
        }

        System.debug('Creating linesToCreate: ' + linesToCreate);
        insert linesToCreate;

        System.debug('Deleting linesToDelete: ' + linesToDelete);
        delete linesToDelete;

        System.debug('Exiting SMAX_PS_Kit_Parts.explodeWorkDetailKitParts method');
    }

    // Explode Kit Part POLs and then remove the Kit Part POLs
    // NOTE: This is called by the AfterInsert & AfterUpdate events of the SMAX_PS_PartsOrderLineTriggerHandler
    public static void explodePartsOrderLineKitParts(List<SVMXC__RMA_Shipment_Line__c> partsOrderLines, Map<Id, SVMXC__RMA_Shipment_Line__c> oldMap) {

        System.debug('Entering SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts method');
        if (!SMAX_PS_Utility.isActive('Explode Parts Line Part Kits', 'Explode Parts Order Line Part Kits using SVMX_PS_Kit_Part__c.')) {
            return;
        }

        System.debug('partsOrderLines: ' + partsOrderLines);

        Id reqRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__RMA_Shipment_Order__c', 'Request').Id;
        Set<Id> poIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        List<SVMXC__RMA_Shipment_Line__c> linesToCheck = new List<SVMXC__RMA_Shipment_Line__c>();

        // Get Parts Order Lines that have been updated to have a Record Type of Usage/Consumption and/or a Line Type of Parts
        for (SVMXC__RMA_Shipment_Line__c line : partsOrderLines)
        {
            SVMXC__RMA_Shipment_Line__c old = (oldMap == null) ? null : oldMap.get(line.Id);
            if (line.SVMXC__Product__c != null
                    && (old == null || old.SVMXC__Product__c != line.SVMXC__Product__c))
            {
                // Only run once per transaction for a record type
                if (!SMAX_PS_Utility.isFirstRun('explodePartsOrderLineKitParts' + '-' + line.Id)) {
                    System.debug('Already executed explodePartsOrderLineKitParts ' + line.Id + ' for this transaction');
                    continue;
                }

                poIds.add(line.SVMXC__RMA_Shipment_Order__c);
                prodIds.add(line.SVMXC__Product__c);
                linesToCheck.add(line);
            }
        }

        // Exit if there is nothing to process
        if (linesToCheck.isEmpty()) return;

        // Get Sales Org from the Parts Orders
        List<SVMXC__RMA_Shipment_Order__c> partsOrders = [
                SELECT Id, SMAX_PS_SalesOrg__c, RecordTypeId
                FROM SVMXC__RMA_Shipment_Order__c
                WHERE Id IN :poIds AND RecordTypeId = :reqRecTypeId
        ];
        System.debug('partsOrders: ' + partsOrders);

        // Get a Map of the Work Order Ids to the Sales Orgs
        Map<Id, String> partsOrderIdToSalesOrg = new Map<Id, String>();
        for (SVMXC__RMA_Shipment_Order__c po :partsOrders) {
            partsOrderIdToSalesOrg.put(po.Id, po.SMAX_PS_SalesOrg__c);
        }
        System.debug('partsOrderIdToSalesOrg: ' + partsOrderIdToSalesOrg);

        // This allows to filter only the lines on "Request" RecordType Parts Orders
        List<SVMXC__RMA_Shipment_Line__c> linesToProcess = new List<SVMXC__RMA_Shipment_Line__c>();
        for (SVMXC__RMA_Shipment_Line__c line : linesToCheck) {
            if (partsOrderIdToSalesOrg.containsKey(line.SVMXC__RMA_Shipment_Order__c)) {
                linesToProcess.add(line);
            }
        }

        // Exit if there is nothing to process
        if (linesToProcess.isEmpty()) return;

        Set<String> salesOrgs = new Set<String>(partsOrderIdToSalesOrg.values());
        KitPartHelper helper = new KitPartHelper(prodIds, salesOrgs);

        // Create new Work Detail Lines for the Kit Parts and Remove the parent Part Kit
        List<SVMXC__RMA_Shipment_Line__c> linesToDelete = new List<SVMXC__RMA_Shipment_Line__c>();
        List<SVMXC__RMA_Shipment_Line__c> linesToCreate = new List<SVMXC__RMA_Shipment_Line__c>();
        for (SVMXC__RMA_Shipment_Line__c line :linesToProcess) {
            String salesOrg = partsOrderIdToSalesOrg.get(line.SVMXC__RMA_Shipment_Order__c);
            List<SVMX_PS_Kit_Part__c> kitParts = helper.getKitParts(line.SVMXC__Product__c, salesOrg);
            if (kitParts != null && !kitParts.isEmpty()) {
                // These are the parent Part Kit records we want to delete (create new with id to allow delete)
                linesToDelete.add(new SVMXC__RMA_Shipment_Line__c(Id = line.Id) );

                for (SVMX_PS_Kit_Part__c kitPart : kitParts) {
                    SVMXC__RMA_Shipment_Line__c kitPartLine = new SVMXC__RMA_Shipment_Line__c();
                    kitPartLine.RecordTypeId = line.RecordTypeId;
                    kitPartLine.SVMXC__RMA_Shipment_Order__c = line.SVMXC__RMA_Shipment_Order__c;
                    kitPartLine.SVMXC__Product__c = kitPart.SVMX_PS_Part__c;
                    kitPartLine.SMAX_PS_Parts_Kit__c = kitPart.SVMX_PS_Kit__c;
                    kitPartLine.Partnum__c = kitPart.SVMX_PS_Part__r.Partnum__c;
                    kitPartLine.SVMXC__Service_Order__c = line.SVMXC__Service_Order__c;
                    kitPartLine.SVMXC__Expected_Quantity2__c = kitPart.SVMX_PS_Qty__c;
                    kitPartLine.SVMX_PS_Is_Essential__c = line.SVMX_PS_Is_Essential__c;
                    linesToCreate.add(kitPartLine);
                }
            }
        }

        System.debug('Creating linesToCreate: ' + linesToCreate);
        insert linesToCreate;

        System.debug('Deleting linesToDelete: ' + linesToDelete);
        delete linesToDelete;

        System.debug('Exiting SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts method');
    }

    public class KitPartHelper {
        public Set<Id> prodIds { get; set; }
        public Set<String> salesOrgs { get; set; }
        public Map<String, String> deliveringPlantMap { get; set; }
        public Map<String, List<SVMX_PS_Kit_Part__c>> kitPartMap { get; set; }

        public KitPartHelper(Set<Id> prodIds, Set<String> salesOrgs) {
            this.prodIds = prodIds;
            this.salesOrgs = salesOrgs;
            this.deliveringPlantMap = new Map<String, String>();
            this.kitPartMap = new Map<String, List<SVMX_PS_Kit_Part__c>>();
            this.lookupKitParts();
        }

        private void lookupKitParts() {
            // Get the Product Sales (Sales Orgs)
            System.debug('Looking for prodIds: ' + this.prodIds + ' and salesOrgs: ' + this.salesOrgs);
            List<SMAX_PS_ProductSales__c> productSales = [
                    SELECT Id, SMAX_PS_Product__c, SMAX_PS_SalesOrg__c, SMAX_PS_DeliveringPlant__c
                    FROM SMAX_PS_ProductSales__c
                    WHERE SMAX_PS_Product__c IN :this.prodIds
                    AND SMAX_PS_SalesOrg__c IN :this.salesOrgs
            ];
            System.debug('productSales: ' + productSales);

            // Get only the Product Sales records that match BOTH the Product and Sales Org
            for (SMAX_PS_ProductSales__c productSale :productSales) {
                String productSalesOrgKey = productSale.SMAX_PS_Product__c + '-' + productSale.SMAX_PS_SalesOrg__c;
                this.deliveringPlantMap.put(productSalesOrgKey, productSale.SMAX_PS_DeliveringPlant__c);
            }

            Set<String> deliveringPlants = new Set<String>(this.deliveringPlantMap.values());
            List<SVMX_PS_Kit_Part__c> allKitParts = [SELECT Id, SVMX_PS_Kit__c, SVMX_PS_Part__c,
                    SVMX_PS_Delivering_Plant__c, SVMX_PS_Qty__c, SVMX_PS_Part__r.Partnum__c
                FROM SVMX_PS_Kit_Part__c
                WHERE SVMX_PS_Kit__c IN :prodIds AND SVMX_PS_Delivering_Plant__c IN :deliveringPlants];
            for (SVMX_PS_Kit_Part__c kitPart : allKitParts) {
                String productPlantKey = kitPart.SVMX_PS_Kit__c + '-' + kitPart.SVMX_PS_Delivering_Plant__c;
                if (!this.kitPartMap.containsKey(productPlantKey)) {
                    this.kitPartMap.put(productPlantKey, new List<SVMX_PS_Kit_Part__c>());
                }
                this.kitPartMap.get(productPlantKey).add(kitPart);
            }
        }

        public List<SVMX_PS_Kit_Part__c> getKitParts(Id productId, String salesOrg) {
            String productSalesOrgKey = productId + '-' + salesOrg;
            String deliveringPlant = this.deliveringPlantMap.get(productSalesOrgKey);
            String productPlantKey = productId + '-' + deliveringPlant;
            return this.kitPartMap.get(productPlantKey);
        }
    }

}
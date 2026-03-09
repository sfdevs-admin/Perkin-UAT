public with sharing class B2B_LinkProductsWithResourcesBatch implements Database.Batchable<sObject>{

    public final String QueryStr;

    //SELECT B2B_Links__c, B2B_Product_Resources_Links__c, B2B_Default_image__c, B2B_Product_Resources_PDFs__c, B2B_Product_Resources_Videos__c, B2B_Videos__c FROM product2 where Is_B2B_Product__c = true
    public B2B_LinkProductsWithResourcesBatch( String query ) {
        QueryStr = query;
        System.debug('B2B_LinkProductsWithResourcesBatch Query-- '+QueryStr);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('B2B_LinkProductsWithResourcesBatch start Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }

    public void execute(Database.BatchableContext bc, List<Product2> scope){
        try {
            // Create a map to store Product ID → Combined List of Values
            Map<Id, List<String>> productToResourcesMap = new Map<Id, List<String>>();
            List<B2B_Product_Related_Resources__c> productRelatedResourcesToInsert = new List<B2B_Product_Related_Resources__c>();
            for (Product2 product : scope) {
                List<String> combinedResources = new List<String>();

                if (String.isNotBlank(product.B2B_Product_Resources_PDFs__c)) {
                    combinedResources.addAll(product.B2B_Product_Resources_PDFs__c.split(','));
                }

                if (String.isNotBlank(product.B2B_Product_Resources_Videos__c)) {
                    combinedResources.addAll(product.B2B_Product_Resources_Videos__c.split(','));
                }

                if (String.isNotBlank(product.B2B_Links__c)) {
                    combinedResources.addAll(product.B2B_Links__c.split(','));
                }

                if (String.isNotBlank(product.B2B_Product_Resources_Links__c)) {
                    combinedResources.addAll(product.B2B_Product_Resources_Links__c.split(','));
                }

                if (String.isNotBlank(product.B2B_Default_image__c)) {
                    combinedResources.addAll(product.B2B_Default_image__c.split(','));
                }

                if (String.isNotBlank(product.B2B_Videos__c)) {
                    combinedResources.addAll(product.B2B_Videos__c.split(','));
                }

                // Store the combined list in the map
                productToResourcesMap.put(product.Id, combinedResources);
            }

            // for (Id productId : productToResourcesMap.keySet()) {
            //     System.debug('Product ID: ' + productId + ' → Combined Resources: ' + productToResourcesMap.get(productId));
            // }

            List<B2B_Product_Resources__c> resourceRecords = [SELECT Id, Link_ID__c, Active__c FROM B2B_Product_Resources__c WHERE Link_ID__c != '' AND Resource_Type__c != 'PI - Product Image' AND Active__c = true];

            for (Id productId : productToResourcesMap.keySet()) {
                List<String> combinedResources = productToResourcesMap.get(productId);
            
                for (B2B_Product_Resources__c resource : resourceRecords) {
                    // String linkIdStr = String.valueOf(resource.Link_ID__c);
                    
                    if (combinedResources.contains(resource.Link_ID__c.trim())) {
                        // Link the Product to the Resource
                        // resource.Product__c = productId;
                        B2B_Product_Related_Resources__c productRelatedResources = new B2B_Product_Related_Resources__c();
                        productRelatedResources.Product__c = productId;
                        productRelatedResources.B2B_Product_Resources__c = resource.Id;
                        productRelatedResourcesToInsert.add(productRelatedResources);
                    }
                }
            }

            if (!productRelatedResourcesToInsert.isEmpty()) {
                // insert productRelatedResourcesToInsert;
                Database.insert(productRelatedResourcesToInsert, false);
                System.debug('Inserted Records: ' + productRelatedResourcesToInsert);
            } else {
                System.debug('No records found for insert.');
                createCustomExceptionRecord('No records found for insert.');
            }

        } catch (Exception e) {
            System.debug('Exception-- '+e.getMessage());
            createCustomExceptionRecord(e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc){

    }

    public void createCustomExceptionRecord(String message){
        Custom_Exception__c customException = new Custom_Exception__c();
        customException.Name = 'B2B_LinkProductsWithResourcesBatch Exception';
        customException.Exception_Messages__c = message;
        insert customException;
    }
}
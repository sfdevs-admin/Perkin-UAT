public with sharing class B2B_CreateCMSForProductResourcesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    public final String QueryStr;
    private Id prodId;
    private String productImgUrl;
    private String prodName;

    public B2B_CreateCMSForProductResourcesBatch(String query) {
        QueryStr = query;
        System.debug('B2B_CreateCMSForProductResourcesBatch Query-- '+QueryStr);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('B2B_LinkProductsWithResourcesBatch start Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }

    public void execute(Database.BatchableContext bc, List<B2B_Product_Resources__c> scope){

        try {
            List<ImageProcessingResult> processingResults = new List<ImageProcessingResult>();
            List<B2B_Product_Resources__c> resourceToUpdate = new List<B2B_Product_Resources__c>();
            B2B_Product_Resources__c resource = scope[0];

            List<Product2> products = [SELECT Id, Name, B2B_Part_Number__c FROM Product2 WHERE B2B_Part_Number__c =:resource.Part_Number__c];

            if (products.isEmpty()) {
                resource.Active__c = false;
                resourceToUpdate.add(resource);
                update resourceToUpdate;
                System.debug('No matching product found for part number: ' + resource.Part_Number__c);
                return;
            }

            Product2 product = products[0];
            productImgUrl = resource.Image_URL__c;
            prodId = product.Id;
            prodName = product.Name;
            System.debug('products-- '+products);

            // Process productImgUrl for listImage (only one allowed)
            if ( !String.isBlank( productImgUrl ) ) {
                Boolean hasExistingListImage = [ SELECT Id FROM ProductMedia WHERE ProductId = :prodId AND ElectronicMediaGroup.DeveloperName = 'productListImage' LIMIT 1].size() > 0;

                if (!hasExistingListImage) {
                    processingResults.add(processImageCallout(productImgUrl, 'productListImage'));
                    System.debug('processingResults first one'+processingResults);
                } else {
                    System.debug('List image already exists for this product. Skipping creation.');
                }
            }

            // Process detail images
            if (!String.isBlank( productImgUrl ) && !hasExistingDetailImage( productImgUrl )) {
                List<ProductMedia> existingImages = [SELECT Id FROM ProductMedia WHERE ProductId = :prodId AND ElectronicMediaGroup.DeveloperName = 'productDetailImage'];
                Boolean morePDPImagesAllowed = existingImages.size() < 8;
                //max 8 images allowed
                if( morePDPImagesAllowed ){
                    processingResults.add(processImageCallout( productImgUrl, 'productDetailImage'));
                    System.debug('processingResults second one'+processingResults);
                }else{
                    System.debug('Detail images already exists for this product. Skipping creation.');
                }
            }

            Boolean hasSuccessfulResult = false;

            // Perform DML operations for successfully processed images
            for (ImageProcessingResult result : processingResults) {
                if (result.isSuccess) {
                    processImageDML(result);
                    hasSuccessfulResult = true;
                }
            }

            if ( hasSuccessfulResult ) {
                B2B_Product_Resources__c resource1 = new B2B_Product_Resources__c();
                resource1.Id = resource.Id;
                resource1.Product__c = prodId;
                resource1.Active__c = false;
                resourceToUpdate.add( resource1 );
                system.debug( 'resourceToUpdate'+resourceToUpdate );
                update resourceToUpdate;
            } else {
                B2B_Product_Resources__c resource1 = new B2B_Product_Resources__c();
                resource1.Id = resource.Id;
                resource1.Active__c = false;
                resourceToUpdate.add( resource1 );
                system.debug( 'resourceToUpdate failure-- '+resourceToUpdate );
                update resourceToUpdate;
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            B2B_Product_Resources__c resource = scope[0];
            resource.Active__c = false;
            update resource;
            createCustomExceptionRecord('Error: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc){

    }

    private Boolean hasExistingDetailImage(String imageUrl) {
        // Step 1: Extract the file name from the image URL
        String[] urlSegments = imageUrl.split('/');
        String fileName = urlSegments[urlSegments.size() - 1]; // Get the last segment (file name)
    
        // Step 2: Find the ContentVersion associated with the file name
        List<ContentVersion> contentVersions = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE PathOnClient LIKE :('%' + fileName + '%') // Match the file name
            LIMIT 1
        ];
    
        if (contentVersions.isEmpty()) {
            return false; // No matching ContentVersion found
        }
    
        // Step 3: Check if a ProductMedia record exists for this ContentDocumentId
        List<ProductMedia> productMediaRecords = [
            SELECT Id 
            FROM ProductMedia 
            WHERE ProductId = :prodId 
            AND ElectronicMediaGroup.DeveloperName = 'productDetailImage'
            AND ElectronicMediaId = :contentVersions[0].ContentDocumentId
            LIMIT 1
        ];
    
        return !productMediaRecords.isEmpty();
    }
    
    private ImageProcessingResult processImageCallout(String imageUrl, String mediaGroup) {
        ImageProcessingResult result = new ImageProcessingResult();
        result.mediaGroup = mediaGroup;
        System.debug('entered in method ');
        System.debug('imageUrl'+imageUrl);
        System.debug('mediaGroup'+mediaGroup);
        try {
            if (String.isBlank(imageUrl)) return result;

            // Convert Dropbox public link to direct download link
            //http://www.perkinelmer.com/lab-solutions/resources/images_for_resize/FT_9700_FT_NIR_Analyzer_700x700.jpg
            // if (imageUrl.contains('https://perkinelmer.widen.net')) {
            //     imageUrl = imageUrl.replace('https://perkinelmer.widen.net', 'https://cf-store.widencdn.net');
            // }
            // imageUrl = imageUrl.replace(' ', '%20');
            // System.debug('Image URL:---- ' + imageUrl);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint(imageUrl);

            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200) {
                result.isSuccess = true;
                result.imageBlob = response.getBodyAsBlob();
                result.mimeType = response.getHeader('Content-Type');
                result.imageUrl = imageUrl;
                System.debug('result++++ ' + result);
            } 
            else if(statusCode == 301 || statusCode == 302 || statusCode == 303 || statusCode == 307 || statusCode == 308){
                System.debug('statusCode++++ ' + statusCode);
                String locationHeader = response.getHeader('Location');
                if (String.isNotBlank(locationHeader)){
                    result = processImageCallout(locationHeader, mediaGroup); 
                }
            }
            else {
                throw new CalloutException('Failed to fetch image. Status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error during callout for ' + mediaGroup + ': ' + e.getMessage());
            // throw new CalloutException('Failed to fetch image. Status code: ' + response.getStatusCode());
            // createCustomExceptionRecord('Error during callout for ' + mediaGroup + ': ' + e.getMessage());
        }
        System.debug('result---- ' + result);
        return result;
    }

    private void processImageDML(ImageProcessingResult result) {
        try {
            if (result.imageBlob == null) return;

            ContentVersion createCV = new ContentVersion();
            createCV.Title = prodName + '_' + Datetime.now().getTime(); // Add unique suffix for title
            createCV.PathOnClient = prodName + '.' + result.mimeType.split('/')[1]; // e.g., .jpeg
            createCV.VersionData = result.imageBlob;
            insert createCV;

            ContentVersion cv = [
                SELECT Id, ContentDocumentId, ContentDocument.Title 
                FROM ContentVersion 
                WHERE Id = :createCV.Id
            ];
            ManagedContentSpace mcs;
            If( ! Test.isRunningTest() ){
                mcs = [SELECT Id FROM ManagedContentSpace WHERE Name LIKE 'PerkinElmer%' LIMIT 1];   
            }

            ConnectApi.BinaryInput contentData = new ConnectApi.BinaryInput(result.imageBlob, result.mimeType, cv.ContentDocument.Title + '.' + result.mimeType.split('/')[1]);

            ConnectApi.ManagedContentDocumentInput managedContentInput = new ConnectApi.ManagedContentDocumentInput();
            managedContentInput.title = cv.ContentDocument.Title;
            managedContentInput.contentBody = new ConnectApi.ManagedContentBodyInput();
            managedContentInput.contentBody.nodeMap = new Map<String, Object>{
                'sfdc_cms:media' => new Map<String, Object>{
                    'source' => new Map<String, String>{ 'type' => 'file', 'mimeType' => result.mimeType }
                }
            };
            managedContentInput.contentType = 'sfdc_cms__image';
            If( ! Test.isRunningTest() ){
                managedContentInput.contentSpaceOrFolderId = mcs.Id;   
            }
    
            ConnectApi.ManagedContentDocument resultContent;
            ManagedContentVariant mcv;
            List<String> publishContentIds = new List<String>();
            If( ! Test.isRunningTest() ){
                resultContent = ConnectApi.ManagedContent.createManagedContentWithMedia(managedContentInput, contentData);   
                mcv = [ SELECT Id, ManagedContentId FROM ManagedContentVariant WHERE Name = :cv.ContentDocument.Title ORDER BY CreatedDate DESC LIMIT 1];
                publishContentIds = new List<String>{ mcv.ManagedContentId };
            }
            ConnectApi.ManagedContentPublishInput publishInput = new ConnectApi.ManagedContentPublishInput();
            publishInput.contentIds = publishContentIds;
            If( ! Test.isRunningTest() ){
                ConnectApi.ManagedContent.publish(publishInput);
            }

            List<ElectronicMediaGroup> mediaGroups = [
                SELECT Id FROM ElectronicMediaGroup WHERE DeveloperName = :result.mediaGroup
            ];

            List<ProductMedia> prodMediaListToInsert = new List<ProductMedia>();
            for (ElectronicMediaGroup media : mediaGroups) {
                ProductMedia prodMedia = new ProductMedia();
                prodMedia.ElectronicMediaGroupId = media.Id;
                prodMedia.ProductId = prodId;
                prodMedia.ElectronicMediaId = mcv.ManagedContentId;
                prodMediaListToInsert.add( prodMedia );
            }
            insert prodMediaListToInsert;
        } catch (Exception e) {
            System.debug('Error processing DML for ' + result.mediaGroup + ': ' + e.getMessage());
            // createCustomExceptionRecord('Error processing DML for ' + result.mediaGroup + ': ' + e.getMessage());
        }
    }
    
    public void createCustomExceptionRecord(String message){
        Custom_Exception__c customException = new Custom_Exception__c();
        customException.Name = 'B2B_CreateCMSForProductResourcesBatch Exception';
        customException.Exception_Messages__c = message;
        insert customException;
    }

    public class ImageProcessingResult {
        public Boolean isSuccess = false;
        public Blob imageBlob;
        public String mimeType;
        public String imageUrl;
        public String mediaGroup;
    }
}
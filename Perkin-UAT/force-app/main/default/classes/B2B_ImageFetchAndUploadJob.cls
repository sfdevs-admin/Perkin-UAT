/**
 * test class- B2B_ImageFetchAndUploadJobTest
*/
public class B2B_ImageFetchAndUploadJob implements Queueable, Database.AllowsCallouts {
    private Id prodId;
    private String prodName;
    private String productImgUrl;

    public B2B_ImageFetchAndUploadJob(Id prodId, String prodName, String productImgUrl) {
        this.prodId = prodId;
		prodName = prodName.replaceAll('[^a-zA-Z0-9]', '');
        prodName = prodName.left(8);
        this.prodName = String.valueOf(prodName);
        this.productImgUrl = productImgUrl;
    }

    public void execute(QueueableContext context) {
        try {
            List<ImageProcessingResult> processingResults = new List<ImageProcessingResult>();

            // Process productImgUrl for listImage (only one allowed)
            if ( !String.isBlank( productImgUrl ) ) {
                Boolean hasExistingListImage = [ SELECT Id FROM ProductMedia WHERE ProductId = :prodId AND ElectronicMediaGroup.DeveloperName = 'productListImage' LIMIT 1].size() > 0;

                if (!hasExistingListImage) {
                    processingResults.add(processImageCallout(productImgUrl, 'productListImage'));
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
                }
            }

            // Perform DML operations for successfully processed images
            for (ImageProcessingResult result : processingResults) {
                if (result.isSuccess) {
                    processImageDML(result);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
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

        try {
            if (String.isBlank(imageUrl)) return result;

            // Convert Dropbox public link to direct download link
            //http://www.perkinelmer.com/lab-solutions/resources/images_for_resize/FT_9700_FT_NIR_Analyzer_700x700.jpg
            if (imageUrl.contains('http://www.perkinelmer.com')) {
                imageUrl = imageUrl.replace('http://www.perkinelmer.com', 'https://resources.perkinelmer.com');
            }
            imageUrl = imageUrl.replace(' ', '%20');
            System.debug('Image URL:---- ' + imageUrl);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint(imageUrl);

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                result.isSuccess = true;
                result.imageBlob = response.getBodyAsBlob();
                result.mimeType = response.getHeader('Content-Type');
                result.imageUrl = imageUrl;
            } else {
                throw new CalloutException('Failed to fetch image. Status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error during callout for ' + mediaGroup + ': ' + e.getMessage());
        }

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
        }
    }

    private class ImageProcessingResult {
        public Boolean isSuccess = false;
        public Blob imageBlob;
        public String mimeType;
        public String imageUrl;
        public String mediaGroup;
    }
}
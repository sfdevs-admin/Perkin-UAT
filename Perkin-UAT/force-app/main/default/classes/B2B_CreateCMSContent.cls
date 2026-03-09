/**
 * test class- B2B_ImageFetchAndUploadJobTest
*/
public with sharing class B2B_CreateCMSContent {
    public B2B_CreateCMSContent() {

    }

    @InvocableMethod(Label='B2B Create Product Media' Description='Create Product Media')
    public static void createCMSContent(List<Id> productIds) {
        List<Product2> products = [
            SELECT Id, Name, B2B_Large_Image_URL__c, B2B_50X50_Thumb_Image_URL__c, B2B_320X320_Large_Image_URL__c, 
            B2B_220X220_Thumb_Image_URL__c, B2B_100X100_Thumb_Image_URL__c, B2B_Part_Number__c
            FROM Product2 
            WHERE Id IN :productIds
        ];

        for (Product2 prodData : products) {
            // Check if any image URL fields are populated
            //if ( !String.isBlank(prodData.B2B_Large_Image_URL__c) ) {
            if ( !String.isBlank(prodData.B2B_320X320_Large_Image_URL__c) ) {

                // Enqueue the job with appropriate fields
                System.enqueueJob(new B2B_ImageFetchAndUploadJob(
                    prodData.Id, 
                    prodData.B2B_Part_Number__c, 
                    prodData.B2B_320X320_Large_Image_URL__c
                ));
            }
        }
    }
}
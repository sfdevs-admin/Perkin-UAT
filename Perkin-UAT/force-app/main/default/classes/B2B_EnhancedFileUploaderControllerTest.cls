@isTest
public class B2B_EnhancedFileUploaderControllerTest {
    
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String CUSTOMER_EMAIL = 'customer@testing.cust';
    private static final String GUEST_CUSTOMER_EMAIL = 'guest_customer@testing.cust';
    private static final String LOCATION_NAME = 'Test';
    
    @TestSetup
    static void makeData(){
        Contact con = new Contact(
            LastName = 'Test'
        );
        insert con;
        
        ContentVersion cv = new ContentVersion(
        	Title = 'Test',
            PathOnClient = 'Test',
            VersionData = EncodingUtil.base64Decode('Test'),
            IsMajorVersion = FALSE
        );
        insert cv;
        
        Account userAccount = B2B_TestDataFactory.createAccount('TestAccount', true);
        Contact userContact = B2B_TestDataFactory.createContact('TestContact', userAccount.Id, true);
        User customerUser = B2B_TestDataFactory.createUser('Customer', CUSTOMER_EMAIL, userContact.Id, true); 

        B2B_TestDataFactory.createOrderDeliveryMethod(true);
        Product2 prod = B2B_TestDataFactory.createProduct(PRODUCT_NAME,true);
        WebStore store = B2B_TestDataFactory.createWebstore('Store',true);
        ContactPointAddress cpa = B2B_TestDataFactory.createShippingCPA(userAccount,true);
        WebCart currentCart  = B2B_TestDataFactory.createCart(userAccount.Id, customerUser.id , store.Id, cpa.Id ,true);
	
        B2B_Attachment__c attach = new B2B_Attachment__c(
        	Cart__c = currentCart.Id
        );
        insert attach;
    }

	@isTest
    public static void encrypted_test(){
        String key = B2B_EnhancedFileUploaderController.getKey();
        Account userAccount = getAccTest();
        WebCart currentCart  = getWebCartTest( userAccount.Id );
        B2B_Attachment__c attach = getB2BAttachmentTest( currentCart.Id );
        Contact con = getCon();
        ContentVersion cv = getCV();
        // cv.Guest_Record_fileupload__c = B2B_EnhancedFileUploaderController.encrypt(con.Id,key);
        update cv;
        
        system.test.startTest();
            B2B_EnhancedFileUploaderController.createContentDocLink(new List<String>{cv.Id},currentCart.Id,true);
        system.test.stopTest();


        List<ContentDocumentLink> cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];
        system.assertNotEquals(1, cdl.size());
    }

    @isTest
    public static void get_existing_files(){
        String key = B2B_EnhancedFileUploaderController.getKey();
        Account userAccount = getAccTest();
        WebCart currentCart  = getWebCartTest( userAccount.Id );
        B2B_Attachment__c attach = getB2BAttachmentTest( currentCart.Id );
        Contact con = getCon();
        ContentVersion cv = getCV();
        // cv.Guest_Record_fileupload__c = B2B_EnhancedFileUploaderController.encrypt(con.Id,key);
        update cv;
        
        system.test.startTest();
            B2B_EnhancedFileUploaderController.createContentDocLink(new List<String>{cv.Id},currentCart.Id,false);
            List<B2B_EnhancedFileUploaderController.objFiles> objFiles = B2B_EnhancedFileUploaderController.getExistingFiles(attach.Id); 
        system.test.stopTest();

        system.assertNotEquals(1, objFiles.size());
    }

    @isTest
    public static void change_file_name(){
        ContentVersion cv = getCV();
        String fileName = 'https://www.linkedin.com/in/rygramer/';

        system.test.startTest();
        B2B_EnhancedFileUploaderController.updateFileName(new List<String>{cv.Id}, fileName);
        system.test.stopTest();

        cv = getCV();
        system.assertEquals(fileName, cv.ContentDocument.Title);
    }

    @isTest
    public static void delete_test(){
        ContentVersion cv = getCV();

        system.test.startTest();
            B2B_EnhancedFileUploaderController.deleteContentDoc(cv.Id);
        system.test.stopTest();
        
    }

    @isTest
    public static void invocable_test_create_link(){
        ContentVersion cv = getCV();
        Contact con = getCon();

        B2B_EnhancedFileUploaderController.Input input = new B2B_EnhancedFileUploaderController.Input();
        input.versIds = new List<Id>{cv.Id};
        input.recordId = con.Id;
        input.visibleToAllUsers = TRUE;

        system.test.startTest();
            B2B_EnhancedFileUploaderController.createContentDocumentLinkDownstream(new List<B2B_EnhancedFileUploaderController.Input>{input});
        system.test.stopTest();

        ContentDocumentLink link = [SELECT Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];

        system.assert(link.Visibility == 'AllUsers');
    }

    @isTest
    public static void invocable_test_link_already_exists(){
        ContentVersion cv = getCV();
        Contact con = getCon();

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = con.Id,
            Visibility = 'AllUsers'
        );
        insert link;

        B2B_EnhancedFileUploaderController.Input input = new B2B_EnhancedFileUploaderController.Input();
        input.versIds = new List<Id>{cv.Id};
        input.recordId = con.Id;
        input.visibleToAllUsers = TRUE;

        system.test.startTest();
            B2B_EnhancedFileUploaderController.createContentDocumentLinkDownstream(new List<B2B_EnhancedFileUploaderController.Input>{input});
        system.test.stopTest();

        link = [SELECT Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];

        system.assert(link.Visibility == 'AllUsers');
    }

    @isTest
    public static void invocable_test_with_empty_list(){

        B2B_EnhancedFileUploaderController.Input input = new B2B_EnhancedFileUploaderController.Input();
        input.versIds = new List<Id>();

        system.test.startTest();
            B2B_EnhancedFileUploaderController.createContentDocumentLinkDownstream(new List<B2B_EnhancedFileUploaderController.Input>{input});
        system.test.stopTest();

    }

    @isTest
    public static void create_contentversion(){
        String encodedKey = B2B_EnhancedFileUploaderController.getKey();
        String encodedRecordId = B2B_EnhancedFileUploaderController.encrypt(getCon().Id, encodedKey);

        String beforeString = 'File Upload Improved';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);

        List<String> fileNames = new List<String>{'FileUploadImproved.txt'};
        List<Id> versIds = new List<Id>();
        system.test.startTest();   
            List<B2B_EnhancedFileUploaderController.objFiles> objFiles = B2B_EnhancedFileUploaderController.createContentVers(fileNames, encodedRecordId);

            for(B2B_EnhancedFileUploaderController.objFiles objFile : objFiles){
                versIds.add(objFile.contentVersionId);
                B2B_EnhancedFileUploaderController.appendDataToContentVersion(objFile.contentVersionId, newVersionData);
            }
        system.test.stopTest();

        // for(ContentVersion vers : [SELECT VersionData, Guest_Record_fileupload__c FROM ContentVersion WHERE Id IN :versIds]){
        //     system.assertEquals(encodedRecordId, vers.Guest_Record_fileupload__c);

        //     // I'm stumped on this one, I'd expect this to return this way, but it doesn't.
        //     // Perhaps there's a bug in Salesforce tests that make it so you can't update ContentVersions?
        //     // system.assertEquals(newVersionData, EncodingUtil.base64Encode(vers.VersionData));
        // }
    }

    @isTest
    public static void append_to_contentversion_version_has_data(){
        ContentVersion cv = getCV();

        String currentVersionData = EncodingUtil.base64Encode(cv.VersionData);

        String beforeString = 'File Upload Improved';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);

        system.test.startTest();
            B2B_EnhancedFileUploaderController.appendDataToContentVersion(cv.Id, newVersionData);
        system.test.stopTest();

        // Stumped here too.
        // system.assertEquals(currentVersionData + newVersionData, EncodingUtil.base64Encode(getCV().VersionData));
    }
    
    @isTest
    public static void getAttachmentIdOnCartTest(){
        Account userAccount = getAccTest();
        WebCart currentCart  = getWebCartTest( userAccount.Id );
        B2B_Attachment__c attach = getB2BAttachmentTest( currentCart.Id );
        system.test.startTest();   
        String response = B2B_EnhancedFileUploaderController.getAttachmentIdOnCart( currentCart.Id );
        system.test.stopTest();
        system.assertNotEquals(null, response);
    }

    private static ContentVersion getCV(){
        // return [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
        return [SELECT Id, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
    }

    private static Contact getCon(){
        return [SELECT Id FROM Contact LIMIT 1];
    }
    
    private static Account getAccTest(){
        return [SELECT Id FROM Account WHERE Name = 'TestAccount' LIMIT 1];
    }
    
    private static WebCart getWebCartTest( String accId ){
        return [SELECT Id FROM WebCart WHERE AccountId =: accId LIMIT 1];
    }
    
    private static B2B_Attachment__c getB2BAttachmentTest( String cartId ){
        return [SELECT Id FROM B2B_Attachment__c WHERE Cart__c =: cartId LIMIT 1];
    }
}
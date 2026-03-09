// Changes:
// 08/16/2022   tony    Added the PKI_SAP_Contact_ID__c as this was throwing a validation rule error

@isTest
public class SVMX_PS_TestUtil {

    /* Test Lock */

    static {
        // Per the apex documentation it shouldn't be possible to call methods in this class outside of
        // test context, but as of 6/2/12 that wasn't being enforced in sandboxes.
        system.assert(Test.isRunningTest(), 'TestUtil methods may only be called from test methods');
    }

    /* Quick Test Values */

    public static Decimal DEFAULT_PRICE = 1;
    public static Decimal DEFAULT_QUANTITY = 1;
    public static Date TEST_DATE = System.today();
    public static Decimal TEST_PORTFOLIO_NEW_ASSETS = 1000;
    public static Decimal TEST_PORTFOLIO_VALUE = 2000;
    public static String TEST_STRING = generateRandomString(16);

    public static final Id WDL_USAGE_RT = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('UsageConsumption').getRecordTypeId();

    /* Standard Object Functions */

    //Record Type Helper
    // Usage: getRecordTypeId('[SobjectType].[DeveloperName]') || getRecordTypeId('[SobjectType].[Namespace].[DeveloperName]'):
    private static Map<string, RecordType> RecordTypeIdsByName;

    public static Id getRecordTypeId(string recordTypePath) {
        Id RecordTypeId = null;

        if (RecordTypeIdsByName == null) {
            RecordTypeIdsByName = new Map<string, RecordType>();

            for (RecordType rt : [SELECT Id, Name, DeveloperName, SObjectType, NamespacePrefix FROM RecordType]) {
                string path = rt.SobjectType + (String.IsNotBlank(rt.NamespacePrefix) ? '.' + rt.NamespacePrefix : '') + '.' + rt.DeveloperName;
                RecordTypeIdsByName.put(path, rt);
            }
        }

        if (String.isNotBlank(recordTypePath) && RecordTypeIdsByName.containsKey(recordTypePath)) {
            recordTypeId = RecordTypeIdsByName.get(recordTypePath).Id;
        }

        return recordTypeId;
    }

    //User Creation Methods
    private static Map<string, Profile> ProfilesByName;

    public static Id getProfileId(string profileName) {
        Id profileId = null;

        if (ProfilesByName == null) {
            ProfilesByName = new Map<string, Profile>();

            for (Profile p : [SELECT Id, Name FROM Profile]) {
                ProfilesByName.put(p.Name, p);
            }
        }

        if (String.isNotBlank(profileName) && ProfilesByName.containsKey(profileName)) {
            profileId = ProfilesByName.get(profileName).Id;
        }

        return profileId;
    }

    public static User generateSystemAdminUser() {
        User sysAdminUser = new User();
        sysAdminUser.Alias = generateRandomString(6);
        sysAdminUser.Email = generateRandomEmail();
        sysAdminUser.EmailEncodingKey = 'UTF-8';
        sysAdminUser.FirstName = generateRandomString(5);
        sysAdminUser.LastName = 'Testing';
        sysAdminUser.LanguageLocaleKey = 'en_US';
        sysAdminUser.LocalesIdKey = 'en_US';
        sysAdminUser.ProfileId = getProfileId('System Administrator');
        sysAdminUser.TimeZoneSidKey = 'America/Los_Angeles';
        sysAdminUser.Username = sysAdminUser.Email;

        return sysAdminUser;
    }

    public static User createSystemAdminUser() {
        User sysAdminUser = generateSystemAdminUser();
        insert sysAdminUser;
        return sysAdminUser;
    }

    public static User generateUserWithProfileName(string profileName) {
        User testUser = new User();
        testUser.Alias = SVMX_PS_TestUtil.generateRandomString(6);
        testUser.Email = SVMX_PS_TestUtil.generateRandomEmail();
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.FirstName = SVMX_PS_TestUtil.generateRandomString(5);
        testUser.LastName = SVMX_PS_TestUtil.generateRandomString(10);
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocalesIdKey = 'en_US';
        testUser.ProfileId = getProfileId(profileName);
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        testUser.Username = testUser.Email;

        return testUser;
    }

    public static User createUserWithProfileName(string profileName) {
        User testUser = generateUserWithProfileName(profileName);
        insert testUser;
        return testUser;
    }

    // Accounts
    public static Account createAccount(Boolean isInsert) {
        Account account = generateAccount();
        account.ShippingStreet = generateAddress().get('Street');
        account.ShippingCity =  generateAddress().get('City');
        account.ShippingState = generateAddress().get('State');
        account.ShippingCountry = generateAddress().get('Country');
        account.ShippingPostalCode = generateAddress().get('PostalCode');
        account.SVMXC__Latitude__c = 37.693488;
        account.SVMXC__Longitude__c = -121.8831987;
        if(isInsert)
            insert account;
        return account;
    }

    public static Account generateAccount() {
        // always use long random string for name to avoid issues with de-duping packages
        return new Account(name = generateRandomString(16));
    }

    // Attachments
    public static Attachment createAttachment(Id parentId) {
        Attachment attachment = generateAttachment(parentId);
        insert attachment;
        return attachment;
    }
    public static Attachment generateAttachment(Id parentId) {
        return new Attachment(
                parentId = parentId
                , name = TEST_STRING
                , body = Blob.valueOf(TEST_STRING)
        );
    }

    // Salesforce Files
    public static ContentVersion generateFile(Id linkedEntityId, String title, String fileName) {
        // Setup the ContentVersion record
        ContentVersion contentVer = new ContentVersion(
                Title = title,
                PathOnClient = fileName,
                ContentLocation = 'S'
        );
        contentVer.VersionData = Blob.valueOf(generateRandomString(255));
        insert ContentVer;

        // Get the ContentDocumentId. Oddly, contentVer is not updated with this upon insert
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVer.Id].ContentDocumentId;

        ContentDocumentLink contentDocLink = new ContentDocumentLink (
                LinkedEntityId = linkedEntityId,
                ContentDocumentId = contentDocId
        );
        insert contentDocLink;

        return ContentVer;
    }


    // Campaigns
    public static Campaign createCampaign() {
        Campaign campaign = generateCampaign();
        insert campaign;
        return campaign;
    }
    public static Campaign generateCampaign() {
        return new Campaign(
                name = TEST_STRING
                , isActive = true
        );
    }

    // Case
    public static Case createCase() {
        Case testCase = generateCase();
        insert testCase;
        return testCase;
    }
    public static Case generateCase() {
        return new Case(subject = TEST_STRING, description = TEST_STRING);
    }

    // Contacts
    public static Contact createContact(Id accountId) {
        Contact contact = generateContact(accountId);
        insert contact;
        return contact;
    }
    public static Contact generateContact(Id accountId) {
        // use long random string for names and email address to avoid issues with de-duping packages
        // 08/16/2022 tony Added the PKI_SAP_Contact_ID__c as this was throwing a validation rule error
        return new Contact(lastName = generateRandomString(16), firstname= generateRandomString(16),
                email= generateRandomEmail('example.com'), accountId = accountId, PKI_SAP_Contact_ID__c = 'SAP' + generateRandomString(7));
    }

    // Events
    public static Event createEvent() {
        Event testEvent = generateEvent();
        insert testEvent;
        return testEvent;
    }
    public static Event generateEvent() {
        return new Event(startDateTime = system.now(), endDateTime = system.now());
    }

    // Leads
    public static Lead createLead() {
        Lead lead = generateLead();
        insert lead;
        return lead;
    }
    public static Lead generateLead() {
        // use long random string for lastName/companyName to avoid issues with de-duping packages
        return new Lead(lastName = generateRandomString(16), company = generateRandomString(16), Email = generateRandomEmail());
    }

    // Opportunity
    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunity = generateOpportunity(accountId);
        insert opportunity;
        return opportunity;
    }
    public static Opportunity generateOpportunity(Id accountId) {
        return new Opportunity(name = TEST_STRING, closeDate = TEST_DATE, stageName = TEST_STRING, accountId = accountId);
    }

    // Opportunity Line Items
    public static OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id pricebookEntryId) {
        OpportunityLineItem lineItem = generateOpportunityLineItem(opportunityId, pricebookEntryId);
        insert lineItem;
        return lineItem;
    }
    public static OpportunityLineItem generateOpportunityLineItem(Id opportunityId, Id pricebookEntryId) {
        return new OpportunityLineItem(
                opportunityId = opportunityId
                , pricebookEntryId = pricebookEntryId
                , quantity = DEFAULT_QUANTITY
                , totalPrice = DEFAULT_PRICE
        );
    }

    // Pricebook
    public static Pricebook2 createPricebook() {
        Pricebook2 pricebook = generatePricebook();
        insert pricebook;
        return pricebook;
    }
    public static Pricebook2 generatePricebook() {
        return new Pricebook2(
                name = TEST_STRING
                , isActive = true
        );
    }

    // Pricebook Entries
    // fails if seeAllDate=true not set for api version 24+
    public static PricebookEntry createPricebookEntry(Id productId, Id pricebookId) {
        return createPricebookEntries(new Id[] { productId }, pricebookId)[0];
    }
    public static List<PricebookEntry> createPricebookEntries(List<Id> productIds, Id pricebookId) {
        Set<Id> haveStandardPrice = new Set<Id>();
        for(PricebookEntry pbe : [
                select product2Id
                from PricebookEntry
                where pricebook2.isStandard = true
                and product2Id in :productIds
        ]) {
            haveStandardPrice.add(pbe.product2Id);
        }
        List<PricebookEntry> standardPBEs = new List<PricebookEntry>();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Id productId : productIds) {
            if(!haveStandardPrice.contains(productId)) {
                standardPBEs.add(generatePricebookEntry(productId, STANDARD_PRICEBOOK.id));
            }
            pricebookEntries.add(generatePricebookEntry(productId, pricebookId));
        }
        if(!standardPBEs.isEmpty())
            insert standardPBEs;
        insert pricebookEntries;
        return pricebookEntries;
    }
    private static PricebookEntry generatePricebookEntry(Id productId, Id pricebookId) {
        return new PricebookEntry(
                product2Id = productId
                , pricebook2Id = pricebookId
                , isActive = true
                , unitPrice = DEFAULT_PRICE
        );
    }

    // Products
    public static Product2 createProduct() {
        Product2 product = generateProduct();
        insert product;
        return product;
    }
    public static Product2 generateProduct() {
        return new Product2(name = TEST_STRING, isActive = true);
    }

    // Task
    public static Task createTask() {
        Task task = generateTask();
        insert task;
        return task;
    }
    public static Task generateTask() {
        return new Task();
    }

    // User
    public static User createUser() {
        User testUser = generateUser();
        insert testUser;
        return testUser;
    }
    public static User generateUser() {
        String testString = generateRandomString(8); // can't be longer than eight so we can use for alias
        String testDomain = generateRandomString(12) + '.com'; // use a long domain to avoid potential duplicate usernames
        String testEmail = generateRandomEmail(testDomain);
        return new User(lastName = testString,
                userName = testEmail,
                profileId = SYSADMIN_PROFILE_ID,
                alias = testString,
                email = testEmail,
                emailEncodingKey = 'ISO-8859-1',
                languageLocaleKey = 'en_US',
                localeSidKey = 'en_US',
                timeZoneSidKey = 'America/Los_Angeles'
        );
    }

    /* Custom Objects */

    public static SVMXC__Service_Contract__c createContract(Id accountId, Boolean isInsert) {
        SVMXC__Service_Contract__c contract = new SVMXC__Service_Contract__c();
        contract.SVMXC__Company__c = accountId;

        if(isInsert) insert contract;
        return contract;
    }

    public static SVMXC__Service_Contract_Products__c createCoveredProducts(Id contractId, Id lineId, Id instProdId, Boolean isInsert) {
        SVMXC__Service_Contract_Products__c cp = new SVMXC__Service_Contract_Products__c();

        if (isInsert) insert cp;
        return cp;
    }

    public static SVMXC__Site__c createCustomerLocation(Id accountId, Boolean isInsert){
        SVMXC__Site__c loc = new SVMXC__Site__c();
        loc.Name = generateRandomString(8);
        loc.SVMXC__Street__c = generateAddress().get('Street');
        loc.SVMXC__City__c =  generateAddress().get('City');
        loc.SVMXC__State__c = generateAddress().get('State');
        loc.SVMXC__Country__c = generateAddress().get('Country');
        loc.SVMXC__Zip__c = generateAddress().get('PostalCode');
        loc.SVMXC__Account__c = accountId;
        loc.SVMXC__Latitude__c = 37.693488;
        loc.SVMXC__Longitude__c = -121.8831987;
        if(isInsert) insert loc;
        return loc;
    }

    public static SVMXC__Service_Group__c createServiceTeam(Boolean isInsert){
        SVMXC__Service_Group__c servTeam = new SVMXC__Service_Group__c();
        servTeam.Name = generateRandomString(6);
        if(isInsert)
            insert servTeam;
        return servTeam;
    }

    public static SVMXC__Service_Group_Members__c createTechnician(Boolean isInsert, Id serviceTeamId){
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.Name = generateRandomString(3)+' '+generateRandomString(3)+' '+generateRandomString(3);
        tech.SVMXC__Service_Group__c = serviceTeamId;
        tech.SVMXC__Email__c = 'tech@test.com';
        tech.SVMXC__Street__c = generateAddress().get('Street');
        tech.SVMXC__City__c =  generateAddress().get('City');
        tech.SVMXC__State__c = generateAddress().get('State');
        tech.SVMXC__Country__c = generateAddress().get('Country');
        tech.SVMXC__Zip__c = generateAddress().get('PostalCode');
        if(isInsert) insert tech;
        return tech;
    }

    public static SVMXC__Site__c createSite(String recordTypeId, Boolean isInsert) {
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.RecordTypeId = RecordTypeId;
        if (isInsert) insert site1;
        return site1;
    }

    public static SVMXC__Service_Order__c createWorkOrder(Id accId, String orderStatus, Boolean isInsert){
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = accId;
        wo.SVMXC__City__c = generateAddress().get('City');
        wo.SVMXC__State__c = generateAddress().get('State');
        wo.SVMXC__Street__c = generateAddress().get('Street');
        wo.SVMXC__Zip__c = generateAddress().get('PostalCode');
        wo.SVMXC__Country__c = generateAddress().get('Country');
        wo.SVMXC__Order_Status__c = orderStatus;
        if(isInsert) insert wo;
        return wo;
    }

    public static SVMXC__Service_Order_Line__c createWorkDetailLine(Id woId, Id techId, Id recordTypeId, Boolean isInsert){
        SVMXC__Service_Order_Line__c workDetail = new SVMXC__Service_Order_Line__c();
        if(woId!=null)
            workDetail.SVMXC__Service_Order__c = woId;
        else
                workDetail.SVMXC__Service_Order__c = createWorkOrder(createAccount(true).Id,'Open',true).Id;
        workDetail.SVMXC__Group_Member__c = techId;
        workDetail.RecordTypeId = recordTypeId;
        if(isInsert) insert workDetail;
        return workDetail;
    }

    public static SVMXC__Product_Stock__c createProductStock(String locationId, String prodId, Boolean isInsert) {
        SVMXC__Product_Stock__c prodStock = new SVMXC__Product_Stock__c();
        prodStock.SVMXC__Product__c = prodId;
        prodStock.SVMXC__Location__c = locationId;

        if(isInsert) insert prodStock;
        return prodStock;

    }

    public static SVMXC__RMA_Shipment_Order__c createPartsOrder(Boolean isInsert) {
        SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c();

        if(isInsert) insert partsOrder;
        return partsOrder;
    }

    public static SVMXC__RMA_Shipment_Line__c createPartsOrderLine(Id partsOrderId, Boolean isInsert) {
        SVMXC__RMA_Shipment_Line__c partsOrderLine = new SVMXC__RMA_Shipment_Line__c();
        partsOrderLine.SVMXC__RMA_Shipment_Order__c = partsOrderId;

        if(isInsert) insert partsOrderLine;
        return partsOrderLine;
    }

    public static SVMXC__Installed_Product__c createInstalledProduct(Id prodId, Boolean isInsert) {
        SVMXC__Installed_Product__c installedProduct = new SVMXC__Installed_Product__c();
        installedProduct.SVMXC__Product__c = prodId;

        if(isInsert) insert installedProduct;
        return installedProduct;
    }

    public static SVMXC__Skill__c createSkill(String skillName, Boolean isInsert) {
        SVMXC__Skill__c skill = new SVMXC__Skill__c();
        skill.Name = skillName;
        skill.SVMXC__Skill_Level_High__c = 7;
        skill.SVMXC__Skill_Level_Medium__c = 3;
        skill.SVMXC__Skill_Level_Low__c = 1;

        if(isInsert) insert skill;
        return skill;
    }

    public static SVMXC__Task_Template__c createTaskTemplate(Decimal pmFrequency, Boolean isInsert) {
        SVMXC__Task_Template__c template = new SVMXC__Task_Template__c();

        if(isInsert) insert template;
        return template;

    }

    public static SVMXC__Required_Part__c createRequiredParts(String appVisit, Id prodId, Decimal quantity, Id templateId,
            String subLineType, Boolean isInsert) {
        SVMXC__Required_Part__c reqpart = new SVMXC__Required_Part__c();

        reqpart.SVMXC__Product__c = prodId;
        reqpart.SVMXC__Quantity__c = quantity;
        reqpart.SVMXC__Work_Order_Purpose__c = templateId;

        if(isInsert) insert reqpart;
        return reqpart;

    }

    public static SVMXC__Service_Group_Skills__c createExpertise(Id techId, Id skillId, Id servTeamId, Boolean isInsert) {
        SVMXC__Service_Group_Skills__c expertise = new SVMXC__Service_Group_Skills__c();
        expertise.SVMXC__Group_Member__c = techId;
        expertise.SVMXC__Skill__c = skillId;
        expertise.SVMXC__Service_Group__c = servTeamId;

        if(isInsert) insert expertise;
        return expertise;
    }

    /* Memoized Properties */

    public static String CLOSED_CASE_STATUS {
        get {
            if(null == CLOSED_CASE_STATUS) {
                CLOSED_CASE_STATUS = [select masterLabel from CaseStatus where isClosed = true limit 1][0].masterLabel;
            }
            return CLOSED_CASE_STATUS;
        }
        private set;
    }

    public static String CONVERTED_LEAD_STATUS {
        get {
            if(null == CONVERTED_LEAD_STATUS) {
                CONVERTED_LEAD_STATUS = [select masterLabel from LeadStatus where isConverted = true limit 1][0].masterLabel;
            }
            return CONVERTED_LEAD_STATUS;
        }
        private set;
    }

    public static String OPPTY_CLOSED_LOST_STAGE {
        get {
            if(null == OPPTY_CLOSED_LOST_STAGE) {
                OpportunityStage opptyStage = [select masterLabel from OpportunityStage where isWon = false and isClosed = true limit 1];
                OPPTY_CLOSED_LOST_STAGE = opptyStage.masterLabel;
            }
            return OPPTY_CLOSED_LOST_STAGE;
        }
        private set;
    }

    public static String OPPTY_CLOSED_WON_STAGE
    {
        get {
            if(null == OPPTY_CLOSED_WON_STAGE) {
                OpportunityStage opptyStage = [select masterLabel from OpportunityStage where isWon = true limit 1];
                OPPTY_CLOSED_WON_STAGE = opptyStage.masterLabel;
            }
            return OPPTY_CLOSED_WON_STAGE;
        }
        private set;
    }

    // fails if @seeAllData=true is not specified for api version 24+
    public static Pricebook2 STANDARD_PRICEBOOK {
        get {
            if(STANDARD_PRICEBOOK == null) {
                STANDARD_PRICEBOOK = [select name, isActive from Pricebook2 where isStandard = true];
            }
            return STANDARD_PRICEBOOK;
        }
        private set;
    }

    public static Id SYSADMIN_PROFILE_ID
    {
        get {
            if(null == SYSADMIN_PROFILE_ID) {
                SYSADMIN_PROFILE_ID = [select id from Profile where name = 'System Administrator'][0].id;
            }
            return SYSADMIN_PROFILE_ID;
        }
        set;
    }

    /* Random Functions */

    private static Set<String> priorRandoms;
    public static String generateRandomString(){return generateRandomString(null);}
    public static String generateRandomString(Integer length){
        if(priorRandoms == null)
            priorRandoms = new Set<String>();

        if(length == null) length = 1+Math.round( Math.random() * 8 );
        String characters = 'abcdefghijklmnopqrstuvwxyz1234567890';
        String returnString = '';
        while(returnString.length() < length){
            Integer charpos = Math.round( Math.random() * (characters.length()-1) );
            returnString += characters.substring( charpos , charpos+1 );
        }
        if(priorRandoms.contains(returnString)) {
            return generateRandomString(length);
        } else {
            priorRandoms.add(returnString);
            return returnString;
        }
    }

    public static Map<String,String> generateAddress(){
        Map<String,String> addressMap = new Map<String,String>();
        addressMap.put('Street', 'Test Account Street');
        addressMap.put('State', 'CA');
        addressMap.put('City', 'Pleasanton');
        addressMap.put('Country', 'USA');
        addressMap.put('PostalCode', '94588');
        return addressMap;
    }


    public static String generateRandomEmail(){return generateRandomEmail(null);}
    public static String generateRandomEmail(String domain){
        if(domain == null || domain == '')
            domain = generateRandomString(8) + '.com';
        return generateRandomString(3) + System.now().getTime() + '@' + domain; // use timestamp to ensure usernames are unique
    }

    public static String generateRandomUrl() {
        return 'http://' + generateRandomString() + '.com';
    }

    @isTest
    private static void testStandardObjectCreators() {
        assertIdNotNull(createUser());
        Case testTempCase = createCase();
        assertIdNotNull(testTempCase);
        Account testAccount = createAccount(true);
        assertIdNotNull(testAccount);
        assertIdNotNull(createContact(testAccount.id));
        assertIdNotNull(createAttachment(testAccount.id));
        assertIdNotNull(generateFile(testTempCase.Id, 'testTempFile', 'testTempFile.txt'));
        assertIdNotNull(createTask());
        assertIdNotNull(createEvent());

        // Since ServiceMax and the Email Handler do not use Lead, Opportunity or Campgain, and many Orgs have data
        // integrity restriuctions (Validation Rules) on these objects, they are commented out.
        //assertIdNotNull(createLead());
        //assertIdNotNull(createOpportunity(testAccount.id));
        //assertIdNotNull(createCampaign());
    }

    /* Test Helpers */

    private static void assertIdNotNull(SObject obj) {
        system.assertNotEquals(null, obj.id);
    }
}
/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
@isTest
public class B2B_CountrySwitcherControllerTest {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String CONTACT_NAME = 'Test Contact';
    private static final String Community_Nickname = 'testuser';
    private static final String EMAIL = 'test@user.com';

    @TestSetup
    static void makeData(){
        Account acc = B2B_TestDataFactory.createAccount(ACCOUNT_NAME,true);
        Contact con = B2B_TestDataFactory.createContact(CONTACT_NAME,acc.Id,true);
        User custUser = B2B_TestDataFactory.createUser(Community_Nickname,EMAIL,con.Id,true);
        BuyerAccount ba = B2B_TestDataFactory.createBuyerAccount('Test BA', acc.Id, true);
        BuyerGroup usBG = B2B_TestDataFactory.createBuyerGroup('Test BG', 'US', true);
        BuyerGroup auBG = B2B_TestDataFactory.createBuyerGroup('Test AU BG', 'AU', true);
        B2B_TestDataFactory.createBuyerGroupMember(acc.Id, usBG.Id, true);
    }
	
    @isTest
    static void getGuestLocaleMetadataRecordsTest(){
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('country','BE');

        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getGuestLocaleMetadataRecords(mapParams);
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }
	
    @isTest
    static void getGuestLocaleMetadataRecordsNegativeTest(){
        Map<String,Object> mapNegParams = new Map<String,Object>();

        Test.startTest();
        //Map<String,Object> result = B2B_CountrySwitcherController.getGuestLocaleMetadataRecords(mapNegParams);
		Map<String,Object> result = B2B_CountrySwitcherController.getGuestLocaleMetadataRecords(null);
        Test.stopTest();
        System.assertEquals(false, result.get('isSuccess'));
    }

    @isTest
    static void getCountrySelectorMetadataRecordsTest(){
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getCountrySelectorMetadataRecords();
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }

    @isTest
    static void updateLoggedInUserDetailsTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@user.com' LIMIT 1];
        Map<String,Object> metadataRecord = new Map<String,Object>();
        metadataRecord.put('Country_Code__c','AU');
        metadataRecord.put('Currency_Code__c','AUD');
        metadataRecord.put('Locale__c','en-AU');
        
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId',u.Id);
        mapParams.put('deleteCurrentCart',true);
        mapParams.put('metadataRecord',metadataRecord);
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.updateLoggedInUserDetails(mapParams);
        Test.stopTest();
        //System.assertEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void updateLoggedInUserDetailsNegativeTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@user.com' LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId',u.Id);
        mapParams.put('sdfsd','qwrgg');
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.updateLoggedInUserDetails(mapParams);
        Test.stopTest();
        System.assertEquals(false, result.get('isSuccess'));
    }
    
    @isTest
    static void getLoggedInUserBGTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@user.com' LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId',u.Id);
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getLoggedInUserBG(mapParams);
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void getLoggedInUserBGNegativeTest(){
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId','u.Id');
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getLoggedInUserBG(mapParams);
        Test.stopTest();
        System.assertNotEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void getPromotionBGInfoTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@user.com' LIMIT 1];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId',u.Id);
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getPromotionBGInfo(mapParams);
        Test.stopTest();
        System.assertEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void getPromotionBGInfoNegativeTest(){
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId','u.Id');
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.getPromotionBGInfo(mapParams);
        Test.stopTest();
        System.assertNotEquals(true, result.get('isSuccess'));
    }
    
    @isTest
    static void updateLoggedInUserDetailsNegavtiveTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@user.com' LIMIT 1];
        Map<String,Object> metadataRecord = new Map<String,Object>();
        metadataRecord.put('Country_Code__c',null);
        metadataRecord.put('Currency_Code__c',null);
        metadataRecord.put('Locale__c',null);
        
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('userId',u.Id);
        mapParams.put('deleteCurrentCart',true);
        mapParams.put('metadataRecord',metadataRecord);
        Test.startTest();
        Map<String,Object> result = B2B_CountrySwitcherController.updateLoggedInUserDetails(mapParams);
        Test.stopTest();
    }
}
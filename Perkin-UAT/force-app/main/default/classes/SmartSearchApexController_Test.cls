@isTest
private class SmartSearchApexController_Test {
  @testSetup
  static void createTestData() {
    Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Prospect')
      .getRecordTypeId();

    Account acc = (Account) PKI_Data_Factory.createSObject(
      new Account(
        fxSearchCity__c = 'São Paulo',
        PKI_SAP_Customer_Number__c = '123456',
        RecordTypeId = accountRecordTypeId,
        PKI_SAP_Account_Group__c = 'SFDC',
        fxSearchName__c = 'TEST PKI Account',
        fxSearchStreet__c = '123 TEST street'
      ),
      true
    );
  }

  @isTest
  static void test_fetchAccount() {
    List<Account> account_Obj = [SELECT Id FROM ACCOUNT LIMIT 1];
    SmartSearchApexController.Inputs inputs = new SmartSearchApexController.Inputs();
    inputs.searchStreet = '123 TEST street';
    inputs.maxResults = 3;
    inputs.searchKeyWord = 'TEST PKI Account';
    inputs.searchCity = 'São Paulo';
    inputs.searchCountry = 'BR';
    inputs.searchSAP = '123456';

    Test.startTest();
    String res = SmartSearchApexController.retrieveSearchResults(
      JSON.serialize(inputs)
    );
    SmartSearchApexController.result results = (SmartSearchApexController.result) JSON.deserialize(
      res,
      SmartSearchApexController.result.class
    );
    Test.stopTest();
    System.assertEquals(
      false,
      results.isMore,
      'should have  been false as no more results than returned'
    );
    System.assert(String.isBlank(results.message));
    System.assertEquals(1, results.accounts.size());
  }
}
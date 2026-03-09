@isTest
private class CharacterReplaceFunction_Test {
  @testSetup
  static void createTestData() {
    Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Prospect')
      .getRecordTypeId();

    Account acc = (Account) PKI_Data_Factory.createSObject(
      new Account(RecordTypeId = accountRecordTypeId),
      true
    );
  }

  @isTest
  static void getRecordsTestCity() {
    Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];

    Test.startTest();
    CharacterReplaceFunction.Inputs attr = new CharacterReplaceFunction.Inputs();
    attr.input = 'São Paulo';
    attr.objectName = 'Account';
    attr.field = 'fxSearchCity__c';
    attr.isCapitalise = true;
    attr.recordId = acc.Id;
    CharacterReplaceFunction.character_replace_update(
      new List<CharacterReplaceFunction.Inputs>{ attr }
    );
    Test.stopTest();

    String cityName = [
      SELECT Id, fxSearchCity__c
      FROM ACCOUNT
      WHERE Id = :acc.Id
    ]
    .fxSearchCity__c;
    System.assertEquals('SAO PAULO', cityName);
  }

  @isTest
  static void getRecordsTestNameSuccess() {
    Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];

    Test.startTest();
    List<CharacterReplaceFunction.Inputs> attr_all = new  List<CharacterReplaceFunction.Inputs>();
    CharacterReplaceFunction.Inputs attr = new CharacterReplaceFunction.Inputs();
    attr.input = 'Test ÚÁÉ';
    attr.objectName = 'Account';
    attr.field = 'fxSearchName__c';
    attr.isCapitalise = true;
    attr.recordId = acc.Id;
    attr_all.add(attr);
    CharacterReplaceFunction.Inputs attr1 = new CharacterReplaceFunction.Inputs();
    attr1.input = 'Test ÚÁÉ';
    attr1.objectName = 'Account';
    attr1.field = 'fxSearchName__c';
    attr1.isCapitalise = true;
    attr1.recordId = acc.Id;
    attr_all.add(attr1);
    CharacterReplaceFunction.character_replace_update(attr_all);
    Test.stopTest();

    String accountName = [
      SELECT Id, fxSearchName__c
      FROM ACCOUNT
      WHERE Id = :acc.Id
    ]
    .fxSearchName__c;
    System.assertEquals('TEST UAE', accountName);
  }

  @isTest
  static void getRecordsTestNameFaliure() {
    Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];

    Test.startTest();
    CharacterReplaceFunction.Inputs attr = new CharacterReplaceFunction.Inputs();
    attr.input = 'Test ÚÁÉ';
    attr.objectName = 'Account';
    attr.field = 'fxSearchName__c';
    attr.isCapitalise = true;
    CharacterReplaceFunction.character_replace_update(
      new List<CharacterReplaceFunction.Inputs>{ attr }
    );
    Test.stopTest(); 

    Integer count = [
      SELECT COUNT()
      FROM SFDC_LOG__c
      WHERE Source_Name__c = 'A.CLS CharacterReplaceFunction'
    ];
    System.assertEquals(1, count);
  }
}
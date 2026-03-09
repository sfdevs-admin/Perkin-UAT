/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 11-20-2025
 * @last modified by  : Swati Chilap
**/
@isTest
public with sharing class B2B_ProductSpecificationControllerTest {
  @TestSetup
  static void createTestData() {
    Product2 testProduct = new Product2();
    testProduct.Name = 'Test Product';
    testProduct.isActive = true;
    testProduct.B2B_Product_Group__c = 'Test Group';
    testProduct.B2B_Brand_Name__c = 'Test Brand';
    insert testProduct;

    // Create test Product Resources
    B2B_Product_Resources__c resource1 = new B2B_Product_Resources__c(
      Resource_Type__c = 'Application Brief',
      PDF_Name__c = 'Brief1.pdf',
      Product__c = testProduct.Id,
      Active__c = true
    );
    B2B_Product_Resources__c resource2 = new B2B_Product_Resources__c(
      Resource_Type__c = 'Application Brief',
      PDF_Name__c = 'Brief2.pdf',
      Product__c = testProduct.Id,
      Active__c = true
    );
    B2B_Product_Resources__c resource3 = new B2B_Product_Resources__c(
      Resource_Type__c = 'Application Note',
      PDF_Name__c = 'Note1.pdf',
      Product__c = testProduct.Id,
      Active__c = true
    );
    B2B_Product_Resources__c resource4 = new B2B_Product_Resources__c(
      Resource_Type__c = 'Brief',
      PDF_Name__c = 'Brief3.pdf',
      Product__c = testProduct.Id,
      Active__c = true
    );
    insert new List<B2B_Product_Resources__c>{
      resource1,
      resource2,
      resource3,
      resource4
    };

    // Create junction object records to link Product and Resources
    B2B_Product_Related_Resources__c rel1 = new B2B_Product_Related_Resources__c(
      Product__c = testProduct.Id,
      B2B_Product_Resources__c = resource1.Id
    );
    B2B_Product_Related_Resources__c rel2 = new B2B_Product_Related_Resources__c(
      Product__c = testProduct.Id,
      B2B_Product_Resources__c = resource2.Id
    );
    B2B_Product_Related_Resources__c rel3 = new B2B_Product_Related_Resources__c(
      Product__c = testProduct.Id,
      B2B_Product_Resources__c = resource3.Id
    );
    B2B_Product_Related_Resources__c rel4 = new B2B_Product_Related_Resources__c(
      Product__c = testProduct.Id,
      B2B_Product_Resources__c = resource4.Id
    );
    insert new List<B2B_Product_Related_Resources__c>{ rel1, rel2, rel3, rel4 };
  }

  @isTest
  static void getProductWithFieldSetTest() {
    Product2 product = [
      SELECT Id, Name, B2B_Product_Group__c, B2B_Brand_Name__c
      FROM Product2
      LIMIT 1
    ];
    Map<String, String> inputMap = new Map<String, String>();
    inputMap.put('Name', product.Name);
    inputMap.put('B2B_Product_Group__c', product.B2B_Product_Group__c);
    inputMap.put('B2B_Brand_Name__c', product.B2B_Brand_Name__c);

    Map<String, Object> mapParams = new Map<String, Object>{
      'fields' => inputMap
    };

    Test.startTest();
    Map<String, Object> result = B2B_ProductSpecificationController.getProductWithFieldSet(
      mapParams
    );
    Test.stopTest();
    System.assertEquals(true, result.get('isSuccess'));
  }

  @isTest
  static void getProductWithFieldSetNegativeTest() {
    Product2 product = [SELECT Id FROM Product2 LIMIT 1];
    Map<String, String> inputMap = new Map<String, String>();
    List<Map<String, String>> listOfMap = new List<Map<String, String>>();

    Map<String, Object> mapParams = new Map<String, Object>{
      'fields' => listOfMap
    };

    Test.startTest();
    Map<String, Object> result = B2B_ProductSpecificationController.getProductWithFieldSet(
      mapParams
    );
    Test.stopTest();
    System.assertNotEquals(true, result.get('isSuccess'));
  }

  @IsTest
  static void testGetProductResourcesByProductId() {
    Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

    Test.startTest();
    Map<String, Object> result = B2B_ProductSpecificationController.getProductResourcesByProductId(
      testProduct.Id
    );
    Test.stopTest();
    System.assertEquals(true, result.get('isSuccess'));
  }
    
  @IsTest
  static void testGetProductResourcesByProductIdNegavtive() {
    Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

    Test.startTest();
    Map<String, Object> result = B2B_ProductSpecificationController.getProductResourcesByProductId(
      null
    );
    Test.stopTest();
    System.assertEquals(true, result.get('isSuccess'));
  }
}
/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 03-05-2026
 * @last modified by  : Suhail Ahmed T 
**/
public without sharing class B2B_ProductSpecificationHelper {
  public static Map<String, Object> getProductData(
    Map<String, Object> mapParams
  ) {
    Boolean isSuccess = false;
    String message = '';
    Object inputFieldsMapping = mapParams.get('fields');

    Map<String, String> inputMap = (Map<String, String>) JSON.deserialize(
      JSON.serialize(inputFieldsMapping),
      Map<String, String>.class
    );

    if (!inputMap.isEmpty()) {
      Map<String, String> APILabelMap = new Map<String, String>();
      for (
        Schema.FieldSetMember fieldset : SObjectType.Product2.FieldSets.B2B_Product_Specification.getFields()
      ) {
        APILabelMap.put(fieldset.getFieldPath(), fieldset.getLabel());
      }

      Map<String, String> labelAndValueMap = new Map<String, String>();
      for (String s : APILabelMap.keyset()) {
        if (inputMap.get(s) != null) {
          labelAndValueMap.put(APILabelMap.get(s), inputMap.get(s));
        }
      }
      system.debug('labelAndValueMap: ' + labelAndValueMap);

      mapParams.put('labelAndValueMap', labelAndValueMap);
      isSuccess = true;
    } else {
      message = System.Label.B2B_Error_Product_Spec;
    }
    mapParams.put('isSuccess', isSuccess);
    mapParams.put('message', message);
    return mapParams;
  }

  public static Map<String, List<B2B_Product_Resources__c>> getProductResourcesByProductId(
      String productId
  ) {
      Map<String, List<B2B_Product_Resources__c>> resourceTypeMap = new Map<String, List<B2B_Product_Resources__c>>();
      
      // STEP 1: Fetch junction records ordered by sorting field
      List<B2B_Product_Related_Resources__c> relatedResources = [
          SELECT B2B_Product_Resources__c, B2B_Sequence__c
          FROM B2B_Product_Related_Resources__c
          WHERE Product__c = :productId
          ORDER BY B2B_Sequence__c ASC NULLS LAST
      ];

      // Maintain order using a List
      List<Id> sortedResourceIds = new List<Id>();
      for (B2B_Product_Related_Resources__c rel : relatedResources) {
          if (rel.B2B_Product_Resources__c != null) {
              sortedResourceIds.add(rel.B2B_Product_Resources__c);
          }
      }

      if (sortedResourceIds.isEmpty()) {
          return resourceTypeMap;
      }

      // STEP 2: Fetch product resources (unordered)
      Map<Id, B2B_Product_Resources__c> resourcesById = new Map<Id, B2B_Product_Resources__c>(
          [
              SELECT Id, Application__c, Resource_Type__c, PDF_Resource_Type__c,
                    Summary__c, PDF_Name__c, Product__c, Page_Title__c,
                    Title__c, URL__c
              FROM B2B_Product_Resources__c
              WHERE Id IN :sortedResourceIds
                AND Active__c = TRUE
          ]
      );

      // STEP 3: Push the records into the map *in sorted order*
      for (Id resourceId : sortedResourceIds) {
          if (resourcesById.containsKey(resourceId)) {
              B2B_Product_Resources__c resource = resourcesById.get(resourceId);
              String resourceType = resource.Resource_Type__c;

              if (!resourceTypeMap.containsKey(resourceType)) {
                  resourceTypeMap.put(resourceType, new List<B2B_Product_Resources__c>());
              }
              resourceTypeMap.get(resourceType).add(resource);
          }
      }

      return resourceTypeMap;
  }

}
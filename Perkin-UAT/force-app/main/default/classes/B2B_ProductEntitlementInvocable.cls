/**
 * test class- B2B_CreateProductEntitlementJobTest
*/
public with sharing class B2B_ProductEntitlementInvocable {
    public B2B_ProductEntitlementInvocable() {

    }

    @InvocableMethod(Label='B2B Create Commerce Entittlement Policy Product' Description='Create Commerce Entittlement Policy Product')
    public static void createCommerceEntittlement(List<Id> productIds) {
        List<Product2> products = [
            SELECT Id, Name, B2B_Sales_Org_And_Sales_Status__c
            FROM Product2 
            WHERE Id IN :productIds
        ];

        for (Product2 prodData : products) {
            if ( !String.isBlank(prodData.B2B_Sales_Org_And_Sales_Status__c) ) {
                prodData.B2B_Sales_Org_And_Sales_Status__c = formatSalesOrgSalesStatus( prodData.B2B_Sales_Org_And_Sales_Status__c );
                List<String> salesOrgList = prodData.B2B_Sales_Org_And_Sales_Status__c.split(',');
                System.enqueueJob(new B2B_CreateProductEntitlementJob(
                    prodData.Id, 
                    salesOrgList
                ));
            }
        }
    }
    
    public static String formatSalesOrgSalesStatus( String salesOrgSalesStatus ){
        String target = ';';
		String replacement = ',';
        salesOrgSalesStatus = salesOrgSalesStatus.replace(target, replacement);
        return salesOrgSalesStatus;
    }
}
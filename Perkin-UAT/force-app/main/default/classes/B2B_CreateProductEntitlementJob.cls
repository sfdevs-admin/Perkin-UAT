/**
 * test class- B2B_CreateProductEntitlementJobTest
*/
public with sharing class B2B_CreateProductEntitlementJob implements Queueable, Database.AllowsCallouts {

    private Id prodId;
    private String prodName;
    private List<String> salesOrgList;

    public B2B_CreateProductEntitlementJob( Id prodId, List<String> salesOrgList ) {
        this.prodId = prodId;
        this.salesOrgList = salesOrgList;
    }

    public void execute(QueueableContext context) {
        try {
            //get all existing entitlements for the product, if any delete them.
            getExistingPolicyId( prodId );
            if( ! salesOrgList.isEmpty() ) {
                System.debug('salesOrgList---- ' + JSON.serialize( salesOrgList ) );
                Map<String,Object> salesOrgVsEntitlementMap = new Map<String,Object>();
                List<CommerceEntitlementProduct> commEntProductsToInsert = new List<CommerceEntitlementProduct>();
                salesOrgVsEntitlementMap = getAllSalesOrgVsEntitlementMap();
                System.debug('salesOrgVsEntitlementMap---- ' + JSON.serialize( salesOrgVsEntitlementMap ) );
                CommerceEntitlementPolicy salesOrgSpecificPolicy = new CommerceEntitlementPolicy();
                for( String salesOrgStr : salesOrgList ) {
                    //get the entitlement policy for the sales org, added the trim() method

                    salesOrgStr = salesOrgStr.trim();
                    if( salesOrgVsEntitlementMap.containsKey( salesOrgStr ) ){
                        salesOrgSpecificPolicy = (CommerceEntitlementPolicy) salesOrgVsEntitlementMap.get( salesOrgStr );
                        //create entitlement policy product
                        CommerceEntitlementProduct newCommEntProd = createCommerceEntitlementProduct( prodId, salesOrgSpecificPolicy );
                        commEntProductsToInsert.add( newCommEntProd );
                    }
                }
                if( ! commEntProductsToInsert.isEmpty() ){
                    Database.insert( commEntProductsToInsert, false );
                }
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    private CommerceEntitlementProduct createCommerceEntitlementProduct( String prodId, CommerceEntitlementPolicy salesOrgSpecificPolicy ){
        CommerceEntitlementProduct cep = new CommerceEntitlementProduct();
        cep.ProductId = prodId;
        cep.PolicyId = salesOrgSpecificPolicy.Id;
        return cep;
    }

    private Map<String,Object> getAllSalesOrgVsEntitlementMap(){
        Map<String,Object> returnMap = new Map<String,Object>();
        List<CommerceEntitlementPolicy> allPolicies = [SELECT Id, Name, CurrencyIsoCode, Description, CanViewProduct, CanViewPrice, IsActive, B2B_Sales_Org_And_Sales_Status__c 
                                                        FROM CommerceEntitlementPolicy 
                                                        WHERE IsActive = true AND B2B_Sales_Org_And_Sales_Status__c != null ];
        if( ! allPolicies.isEmpty() ){
            for( CommerceEntitlementPolicy policy : allPolicies ) {
                returnMap.put( policy.B2B_Sales_Org_And_Sales_Status__c, policy );
            }
        }
        return returnMap;
    }

    private void getExistingPolicyId( String prodId ){
        List<Id> policyIds = new List<Id>();
        List<CommerceEntitlementProduct> commerceEntitlementList = [SELECT Id, PolicyId, ProductId FROM CommerceEntitlementProduct  WHERE ProductId =: prodId];
        for( CommerceEntitlementProduct cep : commerceEntitlementList){
            policyIds.add( cep.Id );
        }
        if( ! policyIds.isEmpty() ){
            deleteExistingPolicies( policyIds );
        }
    }

    private void deleteExistingPolicies( List<Id> recordIds ){
        if( ! recordIds.isEmpty() ){
            Database.delete( recordIds, false );
        }
    }
}
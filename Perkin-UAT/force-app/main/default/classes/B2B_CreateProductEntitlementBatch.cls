/**
 * test class- B2B_CreateProductEntitlementJobTest
*/
public class B2B_CreateProductEntitlementBatch implements Database.Batchable<sObject>{
    
    public final String QueryStr;
    
    public B2B_CreateProductEntitlementBatch( String query ){
        QueryStr = query;
        System.debug('B2B_CreateProductEntitlementBatch Query-- '+QueryStr);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope){
        List<Id> productIds = new List<Id>();
        System.debug('scope-- '+scope);
        for(Product2 prod : scope){
            String salesOrgAndSalesStatus = prod.B2B_Sales_Org_And_Sales_Status__c;
            if( String.isNotBlank( salesOrgAndSalesStatus ) ){
                productIds.add( prod.Id );   
            }
        }
        if( !productIds.isEmpty() ){
            B2B_ProductEntitlementInvocable.createCommerceEntittlement(productIds);   
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}
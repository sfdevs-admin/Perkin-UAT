/**
 * test class- B2B_CreateProductEntitlementJobTest
*/
public class B2B_DeleteExistingProductEntitlement implements Database.Batchable<sObject>{
    
    public final String QueryStr;
    
    public B2B_DeleteExistingProductEntitlement( String query ){
        QueryStr = query;
        System.debug('B2B_DeleteExistingProductEntitlement Query-- '+QueryStr);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }
    
    public void execute(Database.BatchableContext bc, List<CommerceEntitlementProduct> scope){
        List<Id> recordIds = new List<Id>();
        for(CommerceEntitlementProduct record : scope){
            recordIds.add( record.Id );
        }
        if( ! recordIds.isEmpty() ){
            Database.delete( recordIds, false );
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}
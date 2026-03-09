/**
 * test class- B2B_ImageFetchAndUploadJobTest
*/
public class B2B_CreateProductMediaBatch implements Database.Batchable<sObject>{
    
    public final String QueryStr;
    public final String Entity;
    public final String Field;
    public final String Value;
    
    public B2B_CreateProductMediaBatch( String query ){
        QueryStr = query;
        System.debug('B2B_CreateProductMediaBatch Query-- '+QueryStr);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('Query-- '+QueryStr);
        return Database.getQueryLocator( QueryStr );
    }
    
    public void execute(Database.BatchableContext bc, List<Product2> scope){
        List<Id> productIds = new List<Id>();
        System.debug('scope-- '+scope);
        for(Product2 prod : scope){
            if( prod.ProductMedias.isEmpty() ){
                productIds.add( prod.Id );   
            }
        }
        if( !productIds.isEmpty() ){
            B2B_CreateCMSContent.createCMSContent(productIds);   
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}
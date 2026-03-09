/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 11-20-2025
 * @last modified by  : Swati Chilap
**/

/** SOQL to run the batch class
    String q = 'SELECT Id, Product__c, B2B_Product_Resources__c, B2B_Sequence__c ' +
        'FROM B2B_Product_Related_Resources__c ' +
        'WHERE B2B_Product_Resources__r.Active__c = TRUE ' +
        'ORDER BY Product__c, B2B_Product_Resources__r.Resource_Type__c';

    Database.executeBatch(new B2BProductResourceSortBatch(q), 200);
*/
public class B2BProductResourceSortBatch implements Database.Batchable<SObject> {
    private String queryStr;

    public B2BProductResourceSortBatch(String q) {
        this.queryStr = q;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(queryStr);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<B2B_Product_Related_Resources__c> records =
            (List<B2B_Product_Related_Resources__c>) scope;

        Map<Id, List<B2B_Product_Related_Resources__c>> productMap =
            new Map<Id, List<B2B_Product_Related_Resources__c>>();

        for (B2B_Product_Related_Resources__c rec : records) {
            if (!productMap.containsKey(rec.Product__c)) {
                productMap.put(rec.Product__c, new List<B2B_Product_Related_Resources__c>());
            }
            productMap.get(rec.Product__c).add(rec);
        }

        List<B2B_Product_Related_Resources__c> toUpdate = new List<B2B_Product_Related_Resources__c>();

        // sort: 100, 200, 300..
        for (Id prodId : productMap.keySet()) {
            Integer sortNum = 100;
            for (B2B_Product_Related_Resources__c rec : productMap.get(prodId)) {
                rec.B2B_Sequence__c = sortNum;
                sortNum += 100;
                toUpdate.add(rec);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Sorting completed for batch run.');
    }
}
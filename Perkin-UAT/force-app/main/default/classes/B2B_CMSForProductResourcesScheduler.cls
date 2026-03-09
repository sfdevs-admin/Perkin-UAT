global class B2B_CMSForProductResourcesScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        String query = 'SELECT Id, Product__c, Part_Number__c, Active__c, Image_URL__c ' +
                       'FROM B2B_Product_Resources__c ' +
                       'WHERE Part_Number__c != null AND Product__c = null AND Active__c = true ' +
                       'AND Resource_Type__c = \'PI - Product Image\' LIMIT 400';

        B2B_CreateCMSForProductResourcesBatch batch = new B2B_CreateCMSForProductResourcesBatch(query);
        Database.executeBatch(batch, 1);
    }
}
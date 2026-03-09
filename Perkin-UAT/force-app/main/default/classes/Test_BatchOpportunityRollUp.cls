/*
 To test the batch classes created to update opportunity rollup for the existing records
*/
@isTest
public class Test_BatchOpportunityRollUp {
    
    @isTest(SeeAllData=true)
    public static void testOpprtunityChildCount()
    {
        Test.startTest();
        Database.executeBatch(new Batch_UpdateOpprtunityChildCount());
        Test.stopTest();
    }
    @isTest(SeeAllData=true)
    public static void testOpprtunityContractCount()
    {
        Test.startTest();
        //Database.executeBatch(new Batch_UpdateOpprtunityContractCount());
        Test.stopTest();
    }
    @isTest(SeeAllData=true)
    public static void testOpprtunityOrderCount()
    {
        Test.startTest();
        Database.executeBatch(new Batch_UpdateOpprtunityOrderCount());
        Test.stopTest();
    }
    @isTest(SeeAllData=true)
    public static void testOpportunityQuoteCount()
    {
        Test.startTest();
        //Database.executeBatch(new Batch_UpdateOpportunityQuoteCount());
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    public static void testOpprtunityLineItemRollup()
    {
        Test.startTest();
        Database.executeBatch(new Batch_OpprtunityLineItemRollup());
        Test.stopTest();
    }
    
}
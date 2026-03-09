@isTest
public class MetricsThatMatterControllerTest {
    
    @isTest
    public static void testMethod1() {
        MetricsThatMatterController.getUsersInRegion('AMERICAS');

        MetricsThatMatterController.getUsersInRegion('APAC');

        MetricsThatMatterController.getUsersInRegion('EMEA');

        MetricsThatMatterController.getFieldMetadata('Opportunity','');
        
        MetricsThatMatterController.getFieldMetadata('OpportunityLineItem','');
        
        MetricsThatMatterController.getFieldMetadata('Product2','');

        MetricsThatMatterController.getFieldMetadata('OpportunityHistory','');
    }

}
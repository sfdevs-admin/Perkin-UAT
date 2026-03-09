@IsTest
public class B2B_BillingControllerTest {
    @IsTest(SeeAllData=true)
    static void setup() {
        Product2 product = B2B_TestDataFactory.createProduct('Test Product', true);
        Account acc = B2B_TestDataFactory.createAccount('Test Account', true);
        OrderDeliveryMethod ordDelMed = B2B_TestDataFactory.createOrderDeliveryMethod(true);
        Order ord = B2B_TestDataFactory.createOrder('Test Order - ShippingHelper', acc.Id, Test.getStandardPricebookId(), true);
        OrderDeliveryGroup ordDelGrp = B2B_TestDataFactory.createOrderDeliveryGroup('Test ODG', ordDelMed.Id, ord.Id, true);
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id LIMIT 1];
        OrderItem orderItem = B2B_TestDataFactory.createOrderItem(ord.Id, pbEntry.Id, ordDelGrp.Id, true);
        B2B_TestDataFactory.createProductShipping(product.Id, true);

        ordDelGrp.DeliverToCountry = 'US';
        update ordDelGrp;

        ord.Status = 'Activated';
        update ord;
 
        ConnectApi.OrderSummaryInputRepresentation inputRepresentation = new ConnectApi.OrderSummaryInputRepresentation();
        inputRepresentation.orderId = ord.Id;
        ConnectApi.OrderSummaryOutputRepresentation outputRepresentation = ConnectApi.OrderSummaryCreation.createOrderSummary(inputRepresentation);
    }

    @IsTest(SeeAllData = true)
    static void testGetShippingDetails() {
        setup();
        OrderSummary ordSum = [SELECT Id, OrderNumber FROM OrderSummary WHERE OriginalOrder.Name = 'Test Order - ShippingHelper' LIMIT 1];

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('orderNumber', ordSum.OrderNumber);

        Test.startTest();
            Map<String, Object> result = B2B_BillingController.getBillingDetails(mapParams);
        Test.stopTest();

        System.assertEquals(true, result.get('isSuccess'), 'Response should be true as proper parameter are passed.');
    }
    
    @IsTest(SeeAllData = true)
    static void testGetShippingDetailsNegavtive() {
        setup();
        OrderSummary ordSum = [SELECT Id, OrderNumber FROM OrderSummary WHERE OriginalOrder.Name = 'Test Order - ShippingHelper' LIMIT 1];

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('orderNumber', null);

        Test.startTest();
            Map<String, Object> result = B2B_BillingController.getBillingDetails(mapParams);
        Test.stopTest();

    }
}
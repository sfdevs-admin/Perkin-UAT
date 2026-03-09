/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 07-09-2025
 * @last modified by  : Gaurav Setia
**/
@IsTest
class B2B_ShippingControllerTest {

    //To create order summary in test class, we need to use connect api which enforces the use of SeeAllData=true
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
        OrderSummary ordSum = [SELECT Id FROM OrderSummary WHERE OriginalOrder.Name = 'Test Order - ShippingHelper' LIMIT 1];

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('recordId', ordSum.Id);

        Test.startTest();
            Map<String, Object> result = B2B_ShippingController.getShippingDetails(mapParams);
        Test.stopTest();

        System.assertEquals(true, result.get('isSuccess'), 'Response should be true as proper parameter are passed.');
    }
    
    @IsTest
    static void testGetShippingDetails_Exception() {
        Test.startTest();
            Map<String, Object> result = B2B_ShippingController.getShippingDetails(null);
        Test.stopTest();
        System.assertEquals(false, result.get('isSuccess'), 'Response should be false as null parameter is passed.');
    }

}
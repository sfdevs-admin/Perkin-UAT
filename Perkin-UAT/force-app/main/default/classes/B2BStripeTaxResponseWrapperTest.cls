@IsTest
private class B2BStripeTaxResponseWrapperTest {

    @IsTest
    static void testWrapperMethods() {
        // Create mock line item data
        B2BStripeTaxResponseWrapper.LineItemData lineItem1 = new B2BStripeTaxResponseWrapper.LineItemData();
        lineItem1.id = 'li_001';
        lineItem1.reference = 'cartItem001';
        lineItem1.amount = 1000;
        lineItem1.amount_tax = 80;
        lineItem1.tax_behavior = 'exclusive';
        lineItem1.tax_code = 'txcd_12345678';

        // Add line item to list
        List<B2BStripeTaxResponseWrapper.LineItemData> lineItems = new List<B2BStripeTaxResponseWrapper.LineItemData>{ lineItem1 };

        // Wrap in LineItems
        B2BStripeTaxResponseWrapper.LineItems lineItemWrapper = new B2BStripeTaxResponseWrapper.LineItems();
        lineItemWrapper.data = lineItems;

        // Create mock tax rate details
        B2BStripeTaxResponseWrapper.TaxRateDetails rateDetails = new B2BStripeTaxResponseWrapper.TaxRateDetails();
        rateDetails.percentage_decimal = '8.00';
        rateDetails.country = 'US';
        rateDetails.state = 'OH';
        rateDetails.tax_type = 'sales_tax';

        // Create tax breakdown
        B2BStripeTaxResponseWrapper.TaxBreakdown taxBreakdown = new B2BStripeTaxResponseWrapper.TaxBreakdown();
        taxBreakdown.amount = 80;
        taxBreakdown.inclusive = false;
        taxBreakdown.taxable_amount = 1000;
        taxBreakdown.tax_rate_details = rateDetails;

        // Add to wrapper
        B2BStripeTaxResponseWrapper wrapper = new B2BStripeTaxResponseWrapper();
        wrapper.line_items = lineItemWrapper;
        wrapper.tax_breakdown = new List<B2BStripeTaxResponseWrapper.TaxBreakdown>{ taxBreakdown };

        // Call and assert getLineItemsByReference
        Map<String, B2BStripeTaxResponseWrapper.LineItemData> mapRef = wrapper.getLineItemsByReference();
        System.assertEquals(1, mapRef.size());
        System.assertEquals('li_001', mapRef.get('cartItem001').id);

        // Call and assert getEstimatedTaxRate
        String estimatedRate = wrapper.getEstimatedTaxRate();
        System.assertEquals('8.00', estimatedRate);
    }
}
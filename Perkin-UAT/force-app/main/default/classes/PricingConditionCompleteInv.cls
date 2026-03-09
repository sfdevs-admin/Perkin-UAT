public with sharing class PricingConditionCompleteInv {

    @InvocableMethod(
        Label = 'Pricing Conditions Complete'
        Description = 'Based on Quote Lines products and discounts populates Conditional Pricing Condition records for Quote'
        Category = 'Pricing')
    public static void completePricingConditions(List<FlowInput> inputs) {
        // Validate inputs
        if (inputs == null || inputs.isEmpty()) {
            return;
        }
        Id quoteId = inputs[0].quoteId;
        if (String.isBlank(quoteId)) {
            return;
        }

        // Execute recalculation
        try {
            PricingConditionService.completeConditionalCodesForQuote(quoteId);
        } catch (DmlException e) {
            throw new AuraHandledException('Error rollup Pricing Conditions: ' + e.getMessage());
        }
    }

    // Inner class for Flow input
    public class FlowInput {
        @InvocableVariable(
            Label = 'Quote ID'
            Description = 'The ID of the Quote record'
            Required = true
        )
        public Id quoteId;
    }
}
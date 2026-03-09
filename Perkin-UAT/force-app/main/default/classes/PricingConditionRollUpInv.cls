public with sharing class PricingConditionRollUpInv {

    @InvocableMethod(
        Label = 'Pricing Conditions RollUp'
        Description = 'Sum up amounts populated by SAP integration in Default Pricing Condition records for Quote'
        Category = 'Pricing')
    public static void rollUpPricingConditions(List<FlowInput> inputs) {
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
            PricingConditionRollUp.processQuoteRollUp(quoteId);
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
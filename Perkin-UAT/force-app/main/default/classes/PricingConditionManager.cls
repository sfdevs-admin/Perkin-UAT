public class PricingConditionManager {

    @InvocableMethod(label='Sync Pricing Conditions'
                     description='Adds missing and removes extra Pricing Condition records for a Quote Line based on input codes'
                     category='Pricing')
    public static void syncPricingConditions(List<FlowInput> inputs) {
        
        if (inputs == null || inputs.isEmpty()) {
            return;
        }
        
        FlowInput input = inputs[0];
        String codeString = input.codes;
        Id quoteLineId = input.quoteLineId;
        
        // Validate inputs
        if (String.isBlank(codeString) || quoteLineId == null) {
            return;
        }
        
        // Parse input codes
        Set<String> inputCodes = new Set<String>();
        for (String code : codeString.split('[;,]')) {
            String trimmedCode = code.trim();
            if (String.isNotBlank(trimmedCode)) {
                inputCodes.add(trimmedCode);
            }
        }
        
        // Query existing Pricing Condition records for this Quote Line
        List<Pricing_Condition__c> existingRecords = [
            SELECT Id, SAP_Pricing_Condition__c 
            FROM Pricing_Condition__c
            WHERE Quote_Line__c = :quoteLineId
            AND Condition_Type__c = :PricingConditionConstants.TYPE_USER_DEFINED
        ];
        
        // Build sets for comparison
        Set<String> existingCodes = new Set<String>();
        Map<String, Pricing_Condition__c> codeToRecordMap = new Map<String, Pricing_Condition__c>();
        
        for (Pricing_Condition__c pc : existingRecords) {
            if (String.isNotBlank(pc.SAP_Pricing_Condition__c)) {
                existingCodes.add(pc.SAP_Pricing_Condition__c);
                codeToRecordMap.put(pc.SAP_Pricing_Condition__c, pc);
            }
        }
        
        // Find codes to add and delete
        Set<String> codesToAdd = new Set<String>();
        Set<String> codesToDelete = new Set<String>();
        
        // Codes to add: in input but not in existing
        for (String code : inputCodes) {
            if (!existingCodes.contains(code)) {
                codesToAdd.add(code);
            }
        }
        
        // Codes to delete: in existing but not in input
        for (String code : existingCodes) {
            if (!inputCodes.contains(code)) {
                codesToDelete.add(code);
            }
        }
        
        // Create new records
        List<Pricing_Condition__c> recordsToInsert = new List<Pricing_Condition__c>();
        for (String code : codesToAdd) {
            Pricing_Condition__c newRecord = new Pricing_Condition__c(
                SAP_Pricing_Condition__c = code,
                Source__c = PricingConditionConstants.SOURCE_SALESFORCE,
                Quote_Line__c = quoteLineId,
                SAP_CALCTYPON__c = PricingConditionConstants.CALCTYPON_M,
                Condition_Type__c = PricingConditionConstants.TYPE_USER_DEFINED
                // Add other required fields here if needed
            );
            recordsToInsert.add(newRecord);
        }
        
        // Collect records to delete
        List<Pricing_Condition__c> recordsToDelete = new List<Pricing_Condition__c>();
        for (String code : codesToDelete) {
            if (codeToRecordMap.containsKey(code)) {
                recordsToDelete.add(codeToRecordMap.get(code));
            }
        }
        
        // Execute DML operations
        try {
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error syncing Pricing Conditions: ' + e.getMessage());
        }
    }
    
    // Inner class for Flow input with two separate variables
    public class FlowInput {
        @InvocableVariable(
            label='Codes' 
            description='Pricing condition codes separated by comma or semicolon (e.g., ZAU1,ZAU3,ZEP2,ZEW3)'
            required=true
        )
        public String codes;
        
        @InvocableVariable(
            label='Quote Line ID' 
            description='The ID of the Quote Line record'
            required=true
        )
        public Id quoteLineId;
    }
}
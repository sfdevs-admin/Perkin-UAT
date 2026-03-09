public with sharing class SAPPricingConditionController {

    @AuraEnabled(cacheable=true)
    public static List<ConditionWrapper> getAllConditions() {
        List<ConditionWrapper> conditions = new List<ConditionWrapper>();
        
        try {
            List<SAP_Pricing_Condition__mdt> records = [
                SELECT Id, Label, DeveloperName, Code__c, Is_Primary__c, Description__c 
                FROM SAP_Pricing_Condition__mdt 
                WHERE Code__c != null
                ORDER BY Is_Primary__c DESC NULLS LAST, Code__c ASC
            ];
            
            System.debug('Loaded ' + records.size() + ' total conditions');
            
            for(SAP_Pricing_Condition__mdt record : records) {
                conditions.add(new ConditionWrapper(
                    record.Code__c,
                    record.Label,
                    record.DeveloperName,
                    record.Is_Primary__c != null ? record.Is_Primary__c : false,
                    record.Description__c
                ));
            }
            
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching conditions: ' + e.getMessage());
        }
        
        return conditions;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<String> getPreSelectedCodes(Id quoteLineId) {
        List<String> selectedCodes = new List<String>();
        
        if(quoteLineId == null) {
            return selectedCodes;
        }
        
        try {
            List<Pricing_Condition__c> pricingConditions = [
                SELECT Id, SAP_Pricing_Condition__c
                FROM Pricing_Condition__c
                WHERE Quote_Line__c = :quoteLineId
                AND SAP_Pricing_Condition__c != null
                AND Condition_Type__c = :PricingConditionConstants.TYPE_USER_DEFINED
            ];
            
            for(Pricing_Condition__c pc : pricingConditions) {
                if(String.isNotBlank(pc.SAP_Pricing_Condition__c)) {
                    selectedCodes.add(pc.SAP_Pricing_Condition__c);
                }
            }
            
            
        } catch(Exception e) {
            throw new AuraHandledException('Error fetching pre-selected codes: ' + e.getMessage());
        }
        
        return selectedCodes;
    }
    
    // Wrapper class for clean data structure
   	public class ConditionWrapper {
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public Boolean isPrimary { get; set; }
        @AuraEnabled public String description { get; set; }
    
        public ConditionWrapper(String code, String label, String developerName, Boolean isPrimary, String description) {
            this.code = code;
            this.label = label;
            this.developerName = developerName;
            this.isPrimary = isPrimary;
            this.description = description;
        }
    }
}
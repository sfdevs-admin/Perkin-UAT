/**
 * Batch class to fix Pricing_Condition__c on exiting Production quotes
 */
public class PricingConditionBatch implements Database.Batchable<sObject> {

    /**
     * Start method - Query Pricing_Condition__c for fix
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Condition_Type__c, SAP_CALCTYPON__c, SAP_Percentage__c, SAP_Unit_Price__c, SAP_Net_Price__c, CurrencyIsoCode,
                SAP_Pricing_Condition__c, Quote_Line__r.SBQQ__Quantity__c, Quote_Line__r.SBQQ__Bundled__c,
                Quote_Line__r.SBQQ__ListPrice__c, Quote_Line__r.Rep_Total_Unit_Discount__c, Quote_Line__r.SBQQ__NetPrice__c
            FROM Pricing_Condition__c
            WHERE SAP_Net_Price__c = NULL
            AND (SAP_Unit_Price__c != NULL OR SAP_Percentage__c != NULL)
        ]);
    }

    /**
     * Execute method - Process each batch of Pricing_Condition__c
     */
    public void execute(Database.BatchableContext bc, List<Pricing_Condition__c> scope) {

        System.debug('=== EXECUTE METHOD START ===');
        System.debug('Scope size: ' + scope.size());

        List<Pricing_Condition__c> conditionsToUpdate = new List<Pricing_Condition__c>();
        for (Pricing_Condition__c condition : scope) {
            if (condition.Condition_Type__c == PricingConditionConstants.TYPE_USER_DEFINED
                || condition.Condition_Type__c == PricingConditionConstants.TYPE_DEFAULT) {
                condition.SAP_Net_Price__c = condition.SAP_Unit_Price__c;
                condition.SAP_Unit_Price__c = condition.SAP_Percentage__c;
                conditionsToUpdate.add(condition);
            } else if (condition.Condition_Type__c == PricingConditionConstants.TYPE_CONDITIONAL) {
                if (condition.SAP_Pricing_Condition__c == PricingConditionConstants.ZSLS) {
                    condition.SAP_Net_Price__c = condition.SAP_Unit_Price__c;
                    if (condition.Quote_Line__r.SBQQ__Quantity__c != 1) {
                        if (condition.Quote_Line__r.Rep_Total_Unit_Discount__c > 0) {
                            condition.SAP_Unit_Price__c = - condition.Quote_Line__r.Rep_Total_Unit_Discount__c;
                        } else if (condition.Quote_Line__r.SBQQ__Bundled__c) {
                            condition.SAP_Unit_Price__c = - condition.Quote_Line__r.SBQQ__ListPrice__c;
                        }
                    }
                    conditionsToUpdate.add(condition);
                } else if (condition.SAP_Pricing_Condition__c == PricingConditionConstants.ZSPC) {
                    condition.SAP_Net_Price__c = condition.SAP_Unit_Price__c;
                    if (condition.Quote_Line__r.SBQQ__Quantity__c != 1) {
                        condition.SAP_Unit_Price__c = condition.Quote_Line__r.SBQQ__NetPrice__c;
                    }
                    conditionsToUpdate.add(condition);
                }
            }
        }
        update conditionsToUpdate;

        System.debug('=== EXECUTE METHOD END ===');
    }

    /**
     * Finish method
     */
    public void finish(Database.BatchableContext bc) {
    }
}
@IsTest
public class TestDataFactory {

    /**
     * @description Helper method to create custom Pricebook2
     */
    public static Pricebook2 createPricebook() {
        // Create Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        return customPricebook;
    }

    /**
     * @description Helper method to create PricebookEntry
     */
    public static PricebookEntry createPricebookEntry(String pricebookId, String productId) {
        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        return pbe;
    }

    /**
     * @description Helper method to create Pricing_Condition__c
     */
    public static Pricing_Condition__c createPricingCondition(
        String quoteLineId, String code, String type, Decimal price, Decimal amount) {
        // Create Pricing Condition
        String calc = (type == PricingConditionConstants.TYPE_DEFAULT)
            ? PricingConditionConstants.CALCTYPON_C
            : (type == PricingConditionConstants.TYPE_USER_DEFINED)
                ? PricingConditionConstants.CALCTYPON_M
                : (type == PricingConditionConstants.TYPE_CONDITIONAL && code == PricingConditionConstants.ZVDI)
                    ? PricingConditionConstants.CALCTYPON_M
                    : PricingConditionConstants.CALCTYPON_B;
        Pricing_Condition__c pricingCondition = new Pricing_Condition__c();
        pricingCondition.Quote_Line__c = quoteLineId;
        pricingCondition.SAP_Pricing_Condition__c = code;
        pricingCondition.SAP_CALCTYPON__c = calc;
        pricingCondition.Condition_Type__c = type;
        pricingCondition.SAP_Unit_Price__c = price;
        pricingCondition.SAP_Net_Price__c = amount;
        return pricingCondition;
    }
}
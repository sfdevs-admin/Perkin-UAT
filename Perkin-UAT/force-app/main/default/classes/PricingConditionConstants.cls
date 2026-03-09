public with sharing class PricingConditionConstants {

    public static final String SALES_TYPE_POS = 'POS';
    public static final String SALES_TYPE_CONSUMABLES = 'Consumables';
    public static final String SALES_TYPE_SERVICE_CONTRACTS = 'Service Contracts';

    public static final String TYPE_USER_DEFINED = 'User Defined';
    public static final String TYPE_DEFAULT = 'Default';
    public static final String TYPE_CONDITIONAL = 'Conditional';

    public static final String SOURCE_SAP = 'SAP';
    public static final String SOURCE_SALESFORCE = 'Salesforce';

    public static final String CONDITIONAL_FREIGHT = 'Conditional Freight';
    public static final String CONDITIONAL_DISCOUNT = 'Conditional Discount';
    public static final String CONDITIONAL_BUNDLED = 'Conditional Bundled';
    public static final String CONDITIONAL_SERVICE_FREIGHT = 'Conditional Service Freight';
    public static final String CONDITIONAL_SERVICE_DISCOUNT = 'Conditional Service Discount';
    public static final String CONDITIONAL_SERVICE_BUNDLED = 'Conditional Service Bundled';
    public static final String CONDITIONAL_SERVICE_PRO_RATED = 'Conditional Service Pro Rated';
    public static final String CONDITIONAL_SERVICE_PRO_RATED_DISCOUNT = 'Conditional Service Pro Rated Discount';

    public static final String CALCTYPON_B = 'B';
    public static final String CALCTYPON_C = 'C';
    public static final String CALCTYPON_M = 'M';

    public static final String ZSPC = 'ZSPC';
    public static final String ZSLS = 'ZSLS';
    public static final String ZVDI = 'ZVDI';

    public static final String PR00 = 'PR00';
    public static final String KA01 = 'KA01';
    public static final String ZGRS = 'ZGRS';
    public static final String ZCMD = 'ZCMD';
    public static final String NETP = 'NETP';
    public static final String ZD96 = 'ZD96';
    public static final String ZBS1 = 'ZBS1';
    public static final String ZBS2 = 'ZBS2';
    public static final String ZBS3 = 'ZBS3';
    public static final String ZBS4 = 'ZBS4';
    public static final String MWST = 'MWST';
    public static final String GRWR = 'GRWR';
    public static final String ZTOL = 'ZTOL';
    public static final String PNTP = 'PNTP';
   	public static final String IPVA = 'IPVA';
    public static final String ZOIG = 'ZOIG';
    public static final String ZAIG = 'ZAIG';
    public static final String ZUBP = 'ZUBP';
    public static final String ZDUU = 'ZDUU';
    public static final String ZDEL = 'ZDEL';
    public static final String ZSPB = 'ZSPB';

    public static final String ZAG1 = 'ZAG1';
   
    public static final String BX13 = 'BX13';
    public static final String BX23 = 'BX23';
    public static final String BX51 = 'BX51';
    public static final String BX72 = 'BX72';
    public static final String BX82 = 'BX82';
        
    public static final String XR1 = 'XR1';
    public static final String XR2 = 'XR2';
    public static final String XR3 = 'XR3';
    public static final String XR4 = 'XR4';
    public static final String XR5 = 'XR5';
    public static final String XR6 = 'XR6';

    /**
     * @description Helper method to check freight or special ProductCode
     */
    public static Boolean isFreightOrSpecialProductCode(String productCode) {
        if (productCode == null) {
            return false;
        }
        // Conditions for Freight or Special SBQQ__QuoteLine__c.SBQQ__ProductCode__c
        // Contains SPECIAL or REGDEL or exactly 5 consumable freight codes
        final String PRODUCT_CODE_SPECIAL = 'SPECIAL';
        final String PRODUCT_CODE_REGDEL = 'REGDEL';
        final Set<String> PRODUCT_CODES_CONSUMABLES_FREIGHT = new Set<String>{
            'SV000301', 'SV000302', 'SV000303', 'SV000304', 'SV000305'
        };
        return (productCode.contains(PRODUCT_CODE_SPECIAL)
            || productCode.contains(PRODUCT_CODE_REGDEL)
            || PRODUCT_CODES_CONSUMABLES_FREIGHT.contains(productCode));
    }

}
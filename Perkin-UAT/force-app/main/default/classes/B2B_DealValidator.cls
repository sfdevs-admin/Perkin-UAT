public without sharing class B2B_DealValidator {
    /**
     * Checks if an account has any active deals.
     * Expects `mapParams` with key `effectiveAccountId` (Id).
     * Adds a key `hasDeals` => true/false in `mapParams`.
     * Returns the updated mapParams.
     */
    @AuraEnabled
    public static Map<String, Object> validateDealsOnAccount(Map<String, Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';

        if (mapParams == null) {
            mapParams = new Map<String, Object>();
        }

        Id effectiveAccountId = (Id) mapParams.get('effectiveAccountId');

        Boolean hasDeals = false;

        if (effectiveAccountId != null) {
            String accountCurrency = [
                SELECT CurrencyIsoCode
                FROM Account
                WHERE Id = :effectiveAccountId
            ].CurrencyIsoCode;

            Set<Id> dealDiscountIds = new Set<Id>();
            List<B2B_Deals__c> accDeals = [SELECT Id, B2B_Account__c, B2B_Deal_Discount__c FROM B2B_Deals__c 
                WHERE B2B_Account__c = :effectiveAccountId 
                AND B2B_Deal_Discount__c != null 
                AND CurrencyIsoCode = :accountCurrency];
            if( !accDeals.isEmpty() ){
                for(B2B_Deals__c accDeal : accDeals){
                    dealDiscountIds.add(accDeal.B2B_Deal_Discount__c);
                }
            }
            Date today = Date.today();
            Integer dealCount = [
                SELECT COUNT()
                FROM B2B_Deal_Discount_Line__c
                WHERE B2B_Deal_Discount__c IN :dealDiscountIds
                AND B2B_Start_Date__c <= :today
                AND B2B_End_Date__c >= :today
            ];

            hasDeals = (dealCount > 0);
            isSuccess = true;
        }

        mapParams.put('hasDeals', hasDeals);
        mapParams.put('isSuccess', isSuccess);

        return mapParams;
    }
}
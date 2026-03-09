public without sharing class B2BUtils {
    @TestVisible private static Id testWebStoreId;
    
    public static Id getWebstoreId(String communityId) {
         if (Test.isRunningTest()) {
            return testWebStoreId;
        }
        
        Id webstoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId LIMIT 1].WebStoreId;
        return webstoreId;
    }

    public static String getCurrencyIsoCode(Id effectiveAccountId) {
        String accountCurrency = [
                SELECT CurrencyIsoCode
                FROM Account
                WHERE Id = :effectiveAccountId
            ].CurrencyIsoCode;

        return accountCurrency;
    }

    public static Id getUserAccountID() {
        String userId = UserInfo.getUserId();
        String contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
        return Test.isRunningTest() ? [SELECT Id FROM Account WHERE CurrencyIsoCode != null LIMIT 1]?.Id : [SELECT AccountId FROM Contact WHERE Id = :contactId]?.AccountId;
    }

}
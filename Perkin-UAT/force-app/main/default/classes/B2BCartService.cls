public with sharing class B2BCartService {
    public static String getSpecialInstruction(String webCartId) {
        try {
            WebCart webCart = [SELECT B2B_Special_Instruction__c FROM WebCart WHERE Id = :webCartId LIMIT 1];

            if (String.isBlank(webCart.B2B_Special_Instruction__c)) {
                return null;
            }

            return webCart.B2B_Special_Instruction__c;
        } catch (Exception e) {
            B2BLogCustomException.LogException(e, '', '');
            return null;
       }
    }

    public static void updateSpecialInstruction(String webCartId, String specialInstruction) {
        try {
            WebCart webCart = [SELECT Id, B2B_Special_Instruction__c FROM WebCart WHERE Id = :webCartId LIMIT 1];

            webCart.B2B_Special_Instruction__c = specialInstruction;

            update webCart;
        } catch (Exception e) {
            B2BLogCustomException.LogException(e, '', '');
        }
    }
}
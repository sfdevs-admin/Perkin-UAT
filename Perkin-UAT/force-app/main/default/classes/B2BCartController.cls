public with sharing class B2BCartController {
  @AuraEnabled(cacheable=true)
  public static String getSpecialInstruction(String webCartId) {
      String specialInstruction = B2BCartService.getSpecialInstruction(
        webCartId
      );
      return specialInstruction;
   /* try {
      String specialInstruction = B2BCartService.getSpecialInstruction(
        webCartId
      );
      return specialInstruction;
    } catch (Exception e) {
      B2BLogCustomException.LogException(e, '', '');
      return null;
    }*/
  }

  @AuraEnabled
  public static void updateSpecialInstruction(
    String webCartId,
    String specialInstruction
  ) {
      B2BCartService.updateSpecialInstruction(webCartId, specialInstruction);
    /*try {
      B2BCartService.updateSpecialInstruction(webCartId, specialInstruction);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }*/
  }
}
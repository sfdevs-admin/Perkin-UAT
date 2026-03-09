/**
  * @description This sample is for the situations where Promotion Calculation needs to be extended or overridden via the
  * extension point for the Promotion Calculator. You are expected to refer this and write your own implementation.
  * This class must extend the CartExtension.PromotionsCartCalculator class to be processed.
  */
public without sharing class B2B_CustomPromotionCalculator extends CartExtension.PromotionsCartCalculator {

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        cartextension.Cart cart = request.getCart();
        CartExtension.CartValidationOutputList cartValidationOutputList = cleanUpCVO(cart);
        Boolean hasDeals = false;

        Id effectiveAccountId = cart.getAccountId();
        String sObjName = effectiveAccountId.getSObjectType().getDescribe().getName();
        Boolean isCartSubscription = (Boolean)cart.getCustomField('B2B_Is_Subscription__c');

        if (isValidAccount(sObjName)) {
            if(!validateDealsOnAccount(effectiveAccountId)) {
                if (isCartSubscription == null || isCartSubscription == false) {
                    handleDefaultPricing(request);
                }
                // handleDefaultPricing(request);
            } 
            else {
                // System.debug('###Promotion getTotalPromoAdjustmentAmount:::: '+ cart.getTotalPromoAdjustmentAmount());
                CartExtension.CartAdjustmentBasisList adjustmentBases = cart?.getCartAdjustmentBases();
                // System.debug('###adjustmentBases size::: ' + adjustmentBases.size());

                if (adjustmentBases != null && adjustmentBases.size() > 0) {
                    CartExtension.CartAdjustmentBasis cartAdjustmentBasis = adjustmentBases.get(0);
                    System.debug('###adjustmentBases cartAdjustmentBasis details::: ' + cartAdjustmentBasis.getAdjustmentBasisDetail());
                    addCartValidationOutput(cartValidationOutputList);
                }
            }
        } else {
            handleDefaultPricing(request);
        }
        
    }

    private void handleDefaultPricing(CartExtension.CartCalculateCalculatorRequest request) {
        if(!Test.isRunningTest()){
            super.calculate(request);
        }   
    }

    private Boolean isValidAccount(String sObjName) {
        return String.isNotBlank(sObjName) && sObjName.equals('Account');
    }

    //check for available deals on the account
    private Boolean validateDealsOnAccount( Id effectiveAccountId ) {

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('effectiveAccountId', effectiveAccountId);

        mapParams = B2B_DealValidator.validateDealsOnAccount(mapParams);

        Boolean hasDeals = (Boolean) mapParams.get('hasDeals');
        return hasDeals;
    }

    private static CartExtension.CartValidationOutputList cleanUpCVO(CartExtension.Cart cart) {
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

        for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
            CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
            if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.PROMOTIONS) {
                cartValidationOutputList.remove(cvo);
            }
        }
        return cartValidationOutputList;
    }

    private static void addCartValidationOutput(CartExtension.CartValidationOutputList cartValidationOutputList) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
            CartExtension.CartValidationOutputTypeEnum.PROMOTIONS,
            CartExtension.CartValidationOutputLevelEnum.ERROR
        );
        cvo.setMessage(System.Label.B2B_Cart_CVO_Error_Message);
        cartValidationOutputList.add(cvo);
    }
}
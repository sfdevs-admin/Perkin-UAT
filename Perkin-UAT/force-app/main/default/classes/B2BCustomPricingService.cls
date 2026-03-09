/**
 * @description       : 
 * @author            : S.T
 * @group             : 
 * @last modified on  : 07-11-2025
 * @last modified by  : S.T
**/
// This sample is for the situation when the pricing behavior needs to be extended or overriden via
// the extension point for Salesorce Internal Pricing Api. For Salesforce Internal Price
// calculation, please see the corresponding documentation.

// This must implement the commercestorepricing.PricingService class in order to be processed by the
// pricing flow.
public virtual without sharing class B2BCustomPricingService extends commercestorepricing.PricingService {
  
    // Override processPrice method in order to change behavior of the pricing of single product

    public virtual override commercestorepricing.PricingResponse processPrice( commercestorepricing.PricingRequest request ) {
        Id effectiveAccountId = request.getEffectiveAccountId();
        String sObjName = effectiveAccountId.getSObjectType().getDescribe().getName();

        if (isValidAccount(sObjName)) {
            return handleAccountPricing(request, effectiveAccountId);
        } else {
            return handleDefaultPricing(request);
        }        
        
    }

    // Override processTransactionalPrice method in order to change behavior of the pricing of multiple
    // products within a transaction
    //
    // Fields that can be overriden are: Header level - currency, error, total list price, total product
    // amount, total adjustment amount and total amount. Item level - line id, product id, unit price,
    // list price, unit pricebook entry id, unit adjustment amount, total line amount, total adjustment
    // amount, total price, and total list price.
    public override commercestorepricing.TransactionalPricingResponse processTransactionalPrice( commercestorepricing.TransactionalPricingRequest txnRequest ) {
        // System.debug('B2BCustomPricingService.processTransactionalPrice called with txnRequest: ' + txnRequest);
        Id effectiveAccountId = txnRequest.getEffectiveAccountId();
        String sObjName = effectiveAccountId.getSObjectType().getDescribe().getName();
        commercestorepricing.TransactionalPricingResponse txnResponse ;

        if(Test.isRunningTest()){
            txnResponse = createMockTransactionalPricingResponse(txnRequest);
        } else {
            txnResponse = super.processTransactionalPrice( txnRequest );
        }


        if (isValidAccount( sObjName )) {
            return handleAccountTransactionalPricing(txnRequest, effectiveAccountId);
        } else {
            return txnResponse;
        }
    }

    public Boolean isValidAccount(String sObjName) {
        return String.isNotBlank(sObjName) && sObjName.equals('Account');
    }

    private commercestorepricing.PricingResponse handleAccountPricing(commercestorepricing.PricingRequest request, Id accountId) {
        // commercestorepricing.PricingResponse response = super.processPrice(request);
        commercestorepricing.PricingResponse response ;
        if(!Test.isRunningTest()){
            response = super.processPrice(request);
        } else {
            response = createMockPricingResponse(request);
        }
        
        if (validateDealsOnAccount(accountId)) {
            return processDealPricing(request, response, accountId);
        }else{
            return response;
        }
    }

    private commercestorepricing.PricingResponse createMockPricingResponse(commercestorepricing.PricingRequest request) {
        // Create the response object with a currency (e.g., USD)
        commercestorepricing.PricingResponse mockResponse = new commercestorepricing.PricingResponse('USD');

        for (Integer i = 0; i < request.getPricingRequestItems().size(); i++) {
            commercestorepricing.PricingRequestItem reqItem = request.getPricingRequestItems().get(i);

            // Use constructor instead of setters
            commercestorepricing.PricingResponseItem respItem = new commercestorepricing.PricingResponseItem(
                reqItem.getProductId(),   // productId
                null,                     // UoM (optional)
                null,                     // Currency (optional, already on response)
                100,                      // List Price
                90                        // Negotiated Price
            );

            // Add item to response
            mockResponse.addPricingResponseItem(respItem);
        }

        return mockResponse;
    }


    private commercestorepricing.PricingResponse handleDefaultPricing(commercestorepricing.PricingRequest request) {
        if(Test.isRunningTest()){
            return createMockPricingResponse(request);
        }
        return super.processPrice(request);
    }

    private commercestorepricing.PricingResponse processDealPricing(
        commercestorepricing.PricingRequest request,
        commercestorepricing.PricingResponse response,
        Id accountId
    ) {
        if (accountId == null) return response;

        Set<Id> productIds = extractProductIds(request);
        Map<Id, Product2> productMap = fetchProducts(productIds);

        Map<String, Id> keyToProductIdMap = buildKeyToProductIdMap(productMap);
        Set<String> lineClassKeys = keyToProductIdMap.keySet();

        List<B2B_Deal_Discount_Line__c> dealLines = fetchActiveDeals(accountId);
        Map<String, Decimal> discountMap = buildDiscountMap(dealLines, lineClassKeys);

        applyDiscountsToResponse(response, request, productMap, discountMap);

        return response;
    }

    private Set<Id> extractProductIds(commercestorepricing.PricingRequest request) {
        Set<Id> productIds = new Set<Id>();
        commercestorepricing.PricingRequestItemCollection items = request.getPricingRequestItems();

        for (Integer i = 0; i < items.size(); i++) {
            commercestorepricing.PricingRequestItem item = items.get(i);
            productIds.add(item.getProductId());
        }

        return productIds;
    }


    public Map<Id, Product2> fetchProducts(Set<Id> productIds) {
        return new Map<Id, Product2>(
            [SELECT Id, product_line__c, Item_Class__c FROM Product2 WHERE Id IN :productIds]
        );
    }

    public Map<String, Id> buildKeyToProductIdMap(Map<Id, Product2> productMap) {
        Map<String, Id> keyMap = new Map<String, Id>();
        for (Product2 prod : productMap.values()) {
            String key = prod.product_line__c + '|' + prod.Item_Class__c;
            keyMap.put(key, prod.Id);
        }
        return keyMap;
    }

    public List<B2B_Deal_Discount_Line__c> fetchActiveDeals(Id accountId) {
        Date today = Date.today();
        Set<Id> dealDiscountIds = new Set<Id>();
        List<B2B_Deals__c> accDeals = [SELECT Id, B2B_Account__c, B2B_Deal_Discount__c FROM B2B_Deals__c WHERE B2B_Account__c = :accountId AND B2B_Deal_Discount__c != null];
        if( !accDeals.isEmpty() ){
            for(B2B_Deals__c accDeal : accDeals){
                dealDiscountIds.add(accDeal.B2B_Deal_Discount__c);
            }
        }
        return [
            SELECT Id, B2B_Discount__c, B2B_Start_Date__c, B2B_End_Date__c,
                B2B_Item_Class__c, B2B_Product_Line__c, LastModifiedDate
            FROM B2B_Deal_Discount_Line__c
            WHERE B2B_Deal_Discount__c IN :dealDiscountIds
            AND B2B_Start_Date__c <= :today
            AND B2B_End_Date__c >= :today
        ];
    }

    // when Single account have multiple deals then take disocunt as per start date is closest to today
    public Map<String, Decimal> buildDiscountMap(
        List<B2B_Deal_Discount_Line__c> dealLines,
        Set<String> lineClassKeys
    ) {
        Date today = Date.today();
        Map<String, B2B_Deal_Discount_Line__c> bestDealMap = new Map<String, B2B_Deal_Discount_Line__c>();

        for (B2B_Deal_Discount_Line__c line : dealLines) {
            String key = line.B2B_Product_Line__c + '|' + line.B2B_Item_Class__c;

            if (!lineClassKeys.contains(key)) continue;

            if (!bestDealMap.containsKey(key)) {
                bestDealMap.put(key, line);
            } else {
                B2B_Deal_Discount_Line__c currentBest = bestDealMap.get(key);

                // compare: latest start date wins
                if (line.B2B_Start_Date__c > currentBest.B2B_Start_Date__c) {
                    bestDealMap.put(key, line);
                }
                // if same start date → use latest created/updated
                else if (line.B2B_Start_Date__c == currentBest.B2B_Start_Date__c) {
                    if (line.LastModifiedDate > currentBest.LastModifiedDate) {
                        bestDealMap.put(key, line);
                    }
                }
            }
        }

        // discountMap
        Map<String, Decimal> discountMap = new Map<String, Decimal>();
        for (String key : bestDealMap.keySet()) {
            discountMap.put(key, bestDealMap.get(key).B2B_Discount__c);
        }

        return discountMap;
    }


    private void applyDiscountsToResponse(
        commercestorepricing.PricingResponse response,
        commercestorepricing.PricingRequest request,
        Map<Id, Product2> productMap,
        Map<String, Decimal> discountMap
    ) {
        commercestorepricing.PricingRequestItemCollection items = request.getPricingRequestItems();
        commercestorepricing.PricingResponseItemCollection respItems = response.getPricingResponseItems();

        for (Integer i = 0; i < items.size(); i++) {
            commercestorepricing.PricingRequestItem item = items.get(i);
            commercestorepricing.PricingResponseItem respItem = respItems.get(i);

            Product2 prod = productMap.get(item.getProductId());
            String key = prod.product_line__c + '|' + prod.Item_Class__c;

            if (discountMap.containsKey(key)) {
                Decimal discountPercent = discountMap.get(key);

                // Decimal originalPrice = respItem.getListPrice();
                // if (originalPrice == null) originalPrice = respItem.getNegotiatedPrice();

                Decimal originalPrice = respItem.getNegotiatedPrice();
                if (originalPrice != null) {
                    Decimal discountedPrice = (originalPrice * (1 - (discountPercent / 100))).setScale(2, RoundingMode.HALF_UP);
                    respItem.setListPrice(respItem.getNegotiatedPrice());
                    respItem.setNegotiatedPrice(discountedPrice);
                }
            } else {
                respItem.setListPrice(respItem.getListPrice());
                respItem.setNegotiatedPrice(respItem.getNegotiatedPrice());
            }
        }
    }



    //check for available deals on the account
    public Boolean validateDealsOnAccount( Id effectiveAccountId ) {
        if (effectiveAccountId == null) {
            return false;
        }

        Map<String, Object> mapParams = new Map<String, Object>();
        mapParams.put('effectiveAccountId', effectiveAccountId);

        mapParams = B2B_DealValidator.validateDealsOnAccount(mapParams);

        Boolean hasDeals = (Boolean) mapParams.get('hasDeals');
        return hasDeals;
    }

    //Transactional service methods
    private commercestorepricing.TransactionalPricingResponse handleAccountTransactionalPricing(commercestorepricing.TransactionalPricingRequest txnRequest, Id accountId) {
        // commercestorepricing.TransactionalPricingResponse txnResponse = super.processTransactionalPrice(txnRequest);
        commercestorepricing.TransactionalPricingResponse txnResponse;

        if(Test.isRunningTest()){
            txnResponse = createMockTransactionalPricingResponse(txnRequest);
        } else {
            txnResponse = super.processTransactionalPrice( txnRequest );
        }


        if (validateDealsOnAccount(accountId)) {
            return processTransactionalDealPricing(txnRequest, txnResponse, accountId);
        }else{
            return txnResponse;
        }
    }

    
    private commercestorepricing.TransactionalPricingResponse processTransactionalDealPricing(
        commercestorepricing.TransactionalPricingRequest txnRequest,
        commercestorepricing.TransactionalPricingResponse txnResponse,
        Id accountId
    ) {
        if (accountId == null) return txnResponse;

        Set<Id> productIds = extractTransactionalProductIds(txnRequest);
        Map<Id, Product2> productMap = fetchProducts(productIds);

        Map<String, Id> keyToProductIdMap = buildKeyToProductIdMap(productMap);
        Set<String> lineClassKeys = keyToProductIdMap.keySet();

        List<B2B_Deal_Discount_Line__c> dealLines = fetchActiveDeals(accountId);
        Map<String, Decimal> discountMap = buildDiscountMap(dealLines, lineClassKeys);

        applyDiscountsToTxnResponse(txnResponse, txnRequest, productMap, discountMap);

        return txnResponse;
    }

    private Set<Id> extractTransactionalProductIds(commercestorepricing.TransactionalPricingRequest txnRequest) {
        Set<Id> productIds = new Set<Id>();
        commercestorepricing.TxnPricingRequestItemCollection items = txnRequest.getTxnPricingRequestItems();

        for (Integer i = 0; i < items.size(); i++) {
            commercestorepricing.TransactionalPricingRequestItem item = items.get(i);
            productIds.add(item.getProductId());
        }

        return productIds;
    }

    private void applyDiscountsToTxnResponse(
        commercestorepricing.TransactionalPricingResponse txnResponse,
        commercestorepricing.TransactionalPricingRequest txnRequest,
        Map<Id, Product2> productMap,
        Map<String, Decimal> discountMap
    ) {

        commercestorepricing.TxnPricingRequestItemCollection items = txnRequest.getTxnPricingRequestItems();
        commercestorepricing.TxnPricingResponseItemCollection respItems = txnResponse.getTxnPricingResponseItems();

        for (Integer i = 0; i < items.size(); i++) {
            commercestorepricing.TransactionalPricingRequestItem item = items.get(i);
            commercestorepricing.TransactionalPricingResponseItem respItem = respItems.get(i);

            Product2 prod = productMap.get(item.getProductId());
            String key = prod.product_line__c + '|' + prod.Item_Class__c;

            Decimal originalUnitPrice = respItem.getUnitPrice();  // or getNegotiatedPrice()
            if (originalUnitPrice == null) originalUnitPrice = respItem.getListPrice();

            Decimal quantity = respItem.getQuantity();
            Decimal discountedUnitPrice = originalUnitPrice;
            Decimal discountPercent = 0;

            if (discountMap.containsKey(key)) {
                discountPercent = discountMap.get(key);

                discountedUnitPrice =
                    (originalUnitPrice * (1 - (discountPercent / 100)))
                    .setScale(2, RoundingMode.HALF_UP);

                // update cart item prices
                respItem.setUnitPrice(discountedUnitPrice);
                // respItem.setListPrice(discountedUnitPrice);
                // respItem.setListPrice(respItem.getListPrice());
                respItem.setListPrice(originalUnitPrice);

                Decimal totalLineAmount = (discountedUnitPrice * quantity).setScale(2, RoundingMode.HALF_UP);
                respItem.setTotalLineAmount(totalLineAmount);
                respItem.setTotalListPrice(totalLineAmount);
                respItem.setTotalPrice(totalLineAmount);

            } else {
                respItem.setTotalLineAmount(respItem.gettotalLineAmount());
                respItem.setTotalListPrice(respItem.getTotalListPrice());
                respItem.setTotalPrice(respItem.getTotalPrice());
                respItem.setUnitPrice(respItem.getUnitPrice());
                respItem.setListPrice(respItem.getListPrice());
            }
        }


    }

    public static commercestorepricing.TransactionalPricingResponse createMockTransactionalPricingResponse(
        commercestorepricing.TransactionalPricingRequest request
    ) {
        String currencyCode = 'USD';
        Decimal totalListPrice = 0;
        Decimal totalProductAmount = 0;
        Decimal totalAdjustmentAmount = 0;
        Decimal totalAmount = 0;

        commercestorepricing.TransactionalPricingResponse txnResponse = new commercestorepricing.TransactionalPricingResponse(
            0, 0, 0, 0, currencyCode
        );

        commercestorepricing.TxnPricingRequestItemCollection items = request.getTxnPricingRequestItems();
        for (Integer i = 0; i < items.size(); i++) {
            commercestorepricing.TransactionalPricingRequestItem reqItem = items.get(i);

            Decimal listPrice = 100;
            Decimal unitPrice = 90;
            Integer quantity = reqItem.getQuantity() != null ? reqItem.getQuantity().intValue() : 1;
            Decimal totalList = listPrice * quantity;
            Decimal totalLine = unitPrice * quantity;
            Decimal adjustment = totalList - totalLine;

            commercestorepricing.TransactionalPricingResponseItem txnItem = new commercestorepricing.TransactionalPricingResponseItem(
                reqItem.getLineId(),
                reqItem.getProductId(),
                'PBE-001',
                listPrice,
                unitPrice,
                totalList,
                totalLine,
                adjustment,
                listPrice - unitPrice,
                totalLine,
                quantity,
                currencyCode
            );

            txnItem.setError('Mock error message', 'Fehlermeldung auf Deutsch');
            txnResponse.addTxnPricingResponseItem(txnItem);

            // Totals aggregation
            totalListPrice += totalList;
            totalProductAmount += totalLine;
            totalAdjustmentAmount += adjustment;
            totalAmount += totalLine;
        }


        // Set the updated totals on response
        txnResponse.setTotalListPrice(totalListPrice);
        txnResponse.setTotalProductAmount(totalProductAmount);
        txnResponse.setTotalAdjustmentAmount(totalAdjustmentAmount);
        txnResponse.setTotalAmount(totalAmount);

        return txnResponse;
    }



}
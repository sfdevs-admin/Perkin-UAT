@IsTest
public class B2BTaxCalcMock implements HttpCalloutMock {
    private CartExtension.Cart cartObject;

    public B2BTaxCalcMock(CartExtension.Cart cartObject) {
        this.cartObject = cartObject;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        String jsonResponse = buildMockTaxResponse(cartObject);
        response.setBody(jsonResponse);
        
        return response;
    }

    private static String buildMockTaxResponse(CartExtension.Cart cartObject) {
        Map<String, Object> jsonResponse = new Map<String, Object>();
        jsonResponse.put('trnDocNum', 'SalesTest11');
        jsonResponse.put('txwTrnDocId', '80021604');
        jsonResponse.put('txAmt', '40.25');

        List<Map<String, Object>> lineResults = new List<Map<String, Object>>();
        CartExtension.CartItemList cartItems = cartObject.getCartItems();
        
        for (Integer i = 0; i < cartItems.size(); i++) {
            CartExtension.CartItem item = cartItems.get(i);
            Map<String, Object> lineItem = new Map<String, Object>();

            lineItem.put('lnId', item.getId());
            lineItem.put('txwLnId', '8001666' + i);
            lineItem.put('txAmt', (Math.random() * 10).format());
            lineItem.put('grossAmt', item.getTotalLineGrossAmount().format());
            lineItem.put('txRate', (Math.random() * 0.1).format());

            List<Map<String, Object>> jurResults = new List<Map<String, Object>>();
            Map<String, Object> jurTax = new Map<String, Object>();
            jurTax.put('txAmt', (Math.random() * 5 + 1).format());
            jurTax.put('txRate', (Math.random() * 0.1).format());
            jurTax.put('txName', 'Local Tax');
            jurTax.put('txNameID', 'LT001');
            jurTax.put('txJurUIDStatePrv', 'CA');

            jurResults.add(jurTax);
            lineItem.put('jurRslts', jurResults);

            lineResults.add(lineItem);
        }

        jsonResponse.put('lnRslts', lineResults);
        System.debug('Mock Tax Response JSON: ' + JSON.serialize(jsonResponse));
        return JSON.serialize(jsonResponse);
    }
}